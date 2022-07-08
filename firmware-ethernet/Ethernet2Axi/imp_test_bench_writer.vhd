library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.numeric_std.all;

  use work.UtilityPkg.all;
  use work.axiDWORDbi_p.all;
  use work.fifo_cc_pgk_32.all;
  use work.type_conversions_pgk.all;
  use work.xgen_axistream_32.all;

  use work.Imp_test_bench_pgk.all;
  use work.roling_register_p.all;


entity Imp_test_bench_writer is 
  generic ( 
    COLNum : integer := 10;
    FIFO_DEPTH : integer := 10
  );
  port(
    Clk      : in  sl;
    -- Incoming data
    tXData      : out  slv(31 downto 0);
    txDataValid : out sl;
    txDataLast  : out  sl;
    txDataReady : in sl;
    data_in     : in Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
    controls_in : in Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
    Valid      : in sl
  );
end entity;

architecture Behavioral of Imp_test_bench_writer is 
     constant BOS       : std_logic_vector(31 downto 0) := "00001111111111111111111111111111";
     constant FIFO_FULL  : std_logic_vector(31 downto 0) := "00000000111111111111111111110000";
     constant EOS       : std_logic_vector(31 downto 0) := "00001111111111111111111111111110";

     signal Nr_of_streams : std_logic_vector(31 downto 0) := (others => '0');
     signal i_data_in     : Word32Array(COLNum -1 + Imp_test_bench_reader_Control_t_length downto 0) := (others => (others => '0'));
     signal i_controls_in : Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
     signal in_buffer_readEnablde : sl := '0';
     signal in_buffer_empty_v : slv (COLNum -1 + Imp_test_bench_reader_Control_t_length downto 0) := (others =>  '0');
     signal in_buffer_empty : sl  := '0';
	  signal in_buffer_reset : sl  := '0';
     signal  i_fifo_out_m2s :  axisStream_32_m2s := axisStream_32_m2s_null;
     signal  i_fifo_out_s2m :  axisStream_32_s2m := axisStream_32_s2m_null;
     
     signal  i_fifo_out_m2s_out : axisStream_32_m2s := axisStream_32_m2s_null;
     signal  i_fifo_out_s2m_out : axisStream_32_s2m := axisStream_32_s2m_null;

     signal in_buffer_full_v : slv (COLNum -1 + Imp_test_bench_reader_Control_t_length downto 0) := (others =>  '0');
     signal in_buffer_full : sl  := '0';

     function and_reduct(slv : in std_logic_vector) return std_logic is
       variable res_v : std_logic := '1';  -- Null slv vector will also return '1'
     begin
       for i in slv'range loop
         res_v := res_v and slv(i);
       end loop;
       return res_v;
     end function;


     function or_reduce( V: std_logic_vector ) return std_ulogic is
      variable result: std_ulogic;
    begin
      for i in V'range loop
        if i = V'left then
          result := V(i);
        else
          result := result OR V(i);
        end if;
        exit when result = '1';
      end loop;
      return result;
    end or_reduce;

   begin
     
     
    outDeley : entity work.axiStreamDelayBuffer 
       generic map(
         Depth => 5
       ) port map (
         globals.clk => clk,
          globals.rst  => '0',
          
          globals.reg  => registerT_null,
         data_in_m2s => i_fifo_out_m2s,
         data_in_s2m => i_fifo_out_s2m,

         data_out_m2s => i_fifo_out_m2s_out,
         data_out_s2m => i_fifo_out_s2m_out

       );
    
     
     tXData <= i_fifo_out_m2s_out.data;
     txDataValid <= i_fifo_out_m2s_out.valid;
     txDataLast <= i_fifo_out_m2s_out.last;
     i_fifo_out_s2m_out.ready <= txDataReady;
  


  seq_out : process (Clk) is
    variable  fifo :  FIFO_nativ_stream_reader_32_slave := FIFO_nativ_stream_reader_32_slave_null;
    variable index : integer := i_data_in'length +1;
    variable  dummy_data :  slv(31 downto 0) := (others => '0');
    variable out_fifo :  axisStream_32_master:= axisStream_32_master_null;
    variable send_Nr_of_streams : boolean := True;
    variable send_BOS : boolean := True;
	 variable v_EOS  : std_logic_vector(31 downto 0) := EOS;
  begin
    if rising_edge(clk) then 
	    



        pull(out_fifo , i_fifo_out_s2m);
        in_buffer_readEnablde <= '0';
		    in_buffer_reset <= '0';
        
        if in_buffer_full = '1' then 
			    v_EOS := FIFO_FULL;
        end if;
        
        if ready_to_send(out_fifo)  and send_BOS and index <= (i_data_in'length -1) then 
          send_data(out_fifo, BOS);
          send_BOS := false;
        elsif ready_to_send(out_fifo)  and send_Nr_of_streams and index <= (i_data_in'length -1) then 
           send_data(out_fifo,Nr_of_streams);
           send_Nr_of_streams := false;
        elsif ready_to_send(out_fifo)  and index <= (i_data_in'length -1) then 
          send_data(out_fifo,i_data_in(index));

          index := index + 1;
        elsif  ready_to_send(out_fifo)  and index = (i_data_in'length) then 
          send_data(out_fifo, v_EOS);
          Send_end_Of_Stream(out_fifo,true);
          Nr_of_streams <= Nr_of_streams+1;
          send_Nr_of_streams := True;
          send_BOS := true;
          index := index + 1;
			    v_EOS := EOS;
        end if;
        
        if in_buffer_empty = '0' and index > (i_data_in'length ) then
          index :=0;
        end if ;

        if in_buffer_empty = '0' and index = i_data_in'length-1 then
          in_buffer_readEnablde <= '1';
          
        end if ;
        


        
      push(out_fifo, i_fifo_out_m2s);
    
    end if;
  end process;

  
  gen_DAC_CONTROL: for i in 0 to (COLNum -1)  generate

    fifo_i : entity work.fifo_cc generic map (
      DATA_WIDTH => 32,
      DEPTH => FIFO_DEPTH

    ) port map (
      clk   => clk,
      rst   => in_buffer_reset,
      din   => data_in(i),
      wen   =>  valid,
      full  => in_buffer_full_v(i+Imp_test_bench_reader_Control_t_length),
      ren   => in_buffer_readEnablde,
      dout  => i_data_in(i+Imp_test_bench_reader_Control_t_length),
      empty => in_buffer_empty_v(i+Imp_test_bench_reader_Control_t_length)
    );

  end generate gen_DAC_CONTROL;
  

  timestamp_recorded_fifo : entity work.fifo_cc generic map (
    DATA_WIDTH => 32,
    DEPTH => FIFO_DEPTH

  ) port map (
    clk   => clk,
    rst   => in_buffer_reset,
    din   => controls_in.timestampRec,
    wen   =>  valid,
    full  => in_buffer_full_v(0),
    ren   => in_buffer_readEnablde,
    dout  => i_data_in(0),
    empty => in_buffer_empty_v(0)
  );

  timestamp_send_fifo : entity work.fifo_cc generic map (
    DATA_WIDTH => 32,
    DEPTH => FIFO_DEPTH

  ) port map (
    clk   => clk,
    rst   => in_buffer_reset,
    din   => controls_in.timestampSend,
    wen   =>  valid,
    full  => in_buffer_full_v(4),
    ren   => in_buffer_readEnablde,
    dout  => i_data_in(4),
    empty => in_buffer_empty_v(4)
  );

  max_Packet_nr_fifo : entity work.fifo_cc generic map (
    DATA_WIDTH => 32,
    DEPTH => FIFO_DEPTH

  ) port map (
    clk   => clk,
    rst   => in_buffer_reset,
    din   => controls_in.maxPacketNr,
    wen   =>  valid,
    full  => in_buffer_full_v(2),
    ren   => in_buffer_readEnablde,
    dout  => i_data_in(2),
    empty => in_buffer_empty_v(2)
  );

  numStream_nr_fifo : entity work.fifo_cc generic map (
    DATA_WIDTH => 32,
    DEPTH => FIFO_DEPTH

  ) port map (
    clk   => clk,
    rst   => in_buffer_reset,
    din   => controls_in.numStream,
    wen   =>  valid,
    full  => in_buffer_full_v(3),
    ren   => in_buffer_readEnablde,
    dout  => i_data_in(3),
    empty => in_buffer_empty_v(3)
  );
  Operation_fifo : entity work.fifo_cc generic map (
    DATA_WIDTH => 32,
    DEPTH => FIFO_DEPTH

  ) port map (
    clk   => clk,
    rst   => in_buffer_reset,
    din   => controls_in.Operation,
    wen   =>  valid,
    full  => in_buffer_full_v( 1 ),
    ren   => in_buffer_readEnablde,
    dout  => i_data_in(1),
    empty => in_buffer_empty_v(1)
  );
  in_buffer_empty <= and_reduct(in_buffer_empty_v);
  in_buffer_full  <= or_reduce(in_buffer_full_v);
end architecture;