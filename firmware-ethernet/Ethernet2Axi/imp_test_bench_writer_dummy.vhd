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
  use work.axi_stream_pgk_32.all;

entity Imp_test_bench_writer_dummy is 
  generic ( 
    COLNum : integer := 10

  );
  port(
    Clk      : in  sl;
    -- Incoming data
    tXData      : out  slv(31 downto 0);
    txDataValid : out sl;
    txDataLast  : out  sl;
    txDataReady : in sl;
    data_in     : in Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
    Valid      : in sl
  );
end entity;

architecture Behavioral of Imp_test_bench_writer_dummy is 
     constant BOS : std_logic_vector(31 downto 0) := "00001111111111111111111111111111";
     constant EOS : std_logic_vector(31 downto 0) := "00001111111111111111111111111110";

     signal Nr_of_streams : std_logic_vector(31 downto 0) := (others => '0');
     signal  i_data_in     : Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
     signal in_buffer_readEnablde : sl := '0';
     signal in_buffer_empty_v : slv (COLNum -1 downto 0) := (others =>  '0');
     signal in_buffer_empty : sl  := '0';
     signal  i_fifo_out_m2s :  axi_stream_32_m2s := axi_stream_32_m2s_null;
     signal  i_fifo_out_s2m :  axi_stream_32_s2m := axi_stream_32_s2m_null;
     signal valid_old :sl := '0';
     function and_reduct(slv : in std_logic_vector) return std_logic is
       variable res_v : std_logic := '1';  -- Null slv vector will also return '1'
     begin
       for i in slv'range loop
         res_v := res_v and slv(i);
       end loop;
       return res_v;
     end function;
   begin
     
     tXData <= i_fifo_out_m2s.data;
     txDataValid <= i_fifo_out_m2s.valid;
     txDataLast <= i_fifo_out_m2s.last;
     i_fifo_out_s2m.ready <= txDataReady;
  


  seq_out : process (Clk) is
    variable  fifo :  FIFO_nativ_stream_reader_32_slave := FIFO_nativ_stream_reader_32_slave_null;
    variable index : integer := COLNum;
    variable timer : integer := 0;
    variable  dummy_data :  slv(31 downto 0) := (others => '0');
    variable out_fifo : axi_stream_32_master_stream := axi_stream_32_master_stream_null;

    variable send_Nr_of_streams : boolean := True;
    variable send_BOS : boolean := True;
  begin
    if rising_edge(clk) then 
	    valid_old <= valid;
      if timer > 1000000 then 
        timer := 0;
        Nr_of_streams <= (others => '0');
      end if;
      timer := timer +1;

      pull_axi_stream_32_master_stream(out_fifo , i_fifo_out_s2m);
      in_buffer_readEnablde <= '0';
        
        if ready_to_send(out_fifo)  and send_BOS and index <= (COLNum -1) then 
          send_data(out_fifo,BOS);
          send_BOS := false;
        elsif ready_to_send(out_fifo)  and send_Nr_of_streams and index <= (COLNum -1) then 
           send_data(out_fifo,Nr_of_streams);
           send_Nr_of_streams := false;
        elsif ready_to_send(out_fifo)  and index <= (COLNum -1) then 
          send_data(out_fifo,i_data_in(index));

          index := index + 1;
          timer := 0;
        elsif  ready_to_send(out_fifo)  and index = (COLNum) then 
          send_data(out_fifo,EOS);
          Send_end_Of_Stream(out_fifo);
          Nr_of_streams <= Nr_of_streams+1;
          send_Nr_of_streams := True;
          send_BOS := true;
          index := index + 1;
        end if;
        
        if in_buffer_empty = '0' and index > (COLNum ) then
          index :=0;
        end if ;

        if in_buffer_empty = '0' and index = COLNum-1 then
          in_buffer_readEnablde <= '1';
          
        end if ;
        
      push_axi_stream_32_master_stream(out_fifo, i_fifo_out_m2s);
    
    end if;
  end process;
  
    dummy_filler : process (Clk) is
    
    begin 
        if rising_edge(clk) then 
    
        end if;
    end process;


  
  gen_DAC_CONTROL: for i in 0 to (COLNum -1) generate

    fifo_i : entity work.fifo_cc generic map (
      DATA_WIDTH => 32,
      DEPTH => 5 

    ) port map (
      clk   => clk,
      rst   => '0',
      din   => data_in(i),
      wen   =>  valid or valid_old,
      full  => open,
      ren   => in_buffer_readEnablde,
      dout  => i_data_in(i),
      empty => in_buffer_empty_v(i)
    );

  end generate gen_DAC_CONTROL;
  
  in_buffer_empty <= and_reduct(in_buffer_empty_v);

end architecture;