
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

use work.Imp_test_bench_pgk.all;
  use work.xgen_axistream_32.all;
  use work.roling_register_p.all;


entity Imp_test_bench_reader is 
generic ( 
  COLNum : integer := 10;
  FIFO_DEPTH : integer := 10
        
);
port(
Clk      : in  sl := '0';
-- Incoming data
rxData          : in  slv(31 downto 0) := (others => '0');
rxDataValid     : in  sl := '0';
rxDataLast      : in  sl := '0';
rxDataReady     : out sl := '0';
data_out        : out Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
controls_out    : out Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
valid : out sl := '0'
);
end entity;


architecture rtl of Imp_test_bench_reader is

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

type state_t is (
  fillFifo,
  send,
  wait_for_idle,
  FIFO_FULL
);


signal s_reader_state : state_t := fillFifo;


signal  timestamp_signal      : slv(31 downto 0) := (others => '0');


-- packet counter 
signal  max_Packet_nr_signal      : slv(31 downto 0) := (others => '0');
signal  packet_fifo_we            : sl := '0';
signal  numStream_signal          : slv(31 downto 0) := (others => '0');
signal packet_counter_w_m2s : FIFO_nativ_write_32_m2s  := FIFO_nativ_write_32_m2s_null;
signal packet_counter_w_s2m : FIFO_nativ_write_32_s2m  := FIFO_nativ_write_32_s2m_null;
signal packet_counter_r_m2s : FIFO_nativ_reader_32_m2s := FIFO_nativ_reader_32_m2s_null;
signal packet_counter_r_s2m : FIFO_nativ_reader_32_s2m := FIFO_nativ_reader_32_s2m_null;
-- end packet counter

signal  reset : sl := '0';


signal  i_fifo_inBuffer_m2s :  axisStream_32_m2s := axisStream_32_m2s_null;
signal  i_fifo_inBuffer_s2m :  axisStream_32_s2m := axisStream_32_s2m_null;




signal fifo_r_m2s : FIFO_nativ_reader_32_m2s := FIFO_nativ_reader_32_m2s_null;
signal fifo_r_s2m : FIFO_nativ_reader_32_s2m := FIFO_nativ_reader_32_s2m_null;


signal i_data_out       :  Word32Array((COLNum -1)+2 downto 0) := (others => (others => '0'));
signal i_data_out_valid : sl := '0';

signal i_fifo_full            :  slv((COLNum -1) downto 0) := (others => '0');
signal i_fifo_full_or_reduce  :  sl := '0';

signal i_fifo_write_enable  :  sl := '0';
begin

  
  inDeley : entity work.axiStreamDelayBuffer 
    generic map(
      Depth => 5
    ) port map (
      globals.clk => clk,
      globals.rst  => '0',

      globals.reg  => registerT_null,
      data_in_m2s.data  => rxData,
      data_in_m2s.valid => rxDataValid,
      data_in_m2s.last  => rxDataLast,
      data_in_s2m.ready => rxDataReady,

      data_out_m2s =>  i_fifo_inBuffer_m2s,
      data_out_s2m => i_fifo_inBuffer_s2m

    );

  
des : entity work.StreamDeserializer generic map (
  COLNum => COLNum + 2
) port map ( 
  Clk    => Clk,
-- Incoming data
  rxData      => i_fifo_inBuffer_m2s.data,
  rxDataValid => i_fifo_inBuffer_m2s.valid,
  rxDataLast  => i_fifo_inBuffer_m2s.last,
  rxDataReady => i_fifo_inBuffer_s2m.ready,
  data_out    => i_data_out,
  valid       => i_data_out_valid
);

Fill_FIFO_p : process (Clk) is
  variable v_reader_state : state_t := fillFifo;
  variable packet_nr : slv(31 downto 0) := (others => '0');
  variable packet_nr_fifo : FIFO_nativ_write_32_master := FIFO_nativ_write_32_master_null;
begin
  if (rising_edge(Clk)) then
    pull_FIFO_nativ_write_32_master(packet_nr_fifo, packet_counter_w_s2m);
    reset <= '0';

    timestamp_signal <= timestamp_signal + 1;
    if v_reader_state = fillFifo then
      if i_data_out_valid = '1' then
        packet_nr := packet_nr +1;
       
        if i_data_out(0) > 0 then 
          v_reader_state := send;
        end if;
      end if;

    end if;
    if v_reader_state = send then

      if ready_to_send(packet_nr_fifo) then 
        write_data(packet_nr_fifo,packet_nr);
        packet_nr := (others => '0');
        v_reader_state := fillFifo;
      end if;


    elsif v_reader_state = FIFO_FULL then
      reset <= '1';
      v_reader_state := fillFifo;
      packet_nr := (others => '0');
    end if;
    
    if i_fifo_full_or_reduce = '1'  then 
      v_reader_state := FIFO_FULL;
      reset <= '1';
    end if;
    s_reader_state <= v_reader_state;
    push_FIFO_nativ_write_32_master(packet_nr_fifo, packet_counter_w_m2s);
  end if;
end process;


read_fifo_p : process(clk) is
  variable packet_nr_fifo : FIFO_nativ_step_by_step_reader_32_slave := FIFO_nativ_step_by_step_reader_32_slave_null; 
  variable packet_nr : slv(31 downto 0) := (others => '0');
  variable has_data : boolean := false;
begin
  if (rising_edge(Clk)) then
    pull_FIFO_nativ_step_by_step_reader_32_slave(packet_nr_fifo, packet_counter_r_m2s);
    valid <= '0';

    fifo_r_s2m.read_enable <='0';

    if has_data = false then 
      if isReceivingData(packet_nr_fifo) then 
        read_data(packet_nr_fifo, packet_nr);
        max_Packet_nr_signal <= packet_nr;
        has_data := true;
        
        fifo_r_s2m.read_enable <= '1';
        
      end if;
    else 
      packet_nr := packet_nr - 1;
      

      if packet_nr > 0 then
        fifo_r_s2m.read_enable <= '1';
        valid <= '1' ;
      else 
        valid <= '1' ;
        has_data := false;
      
      end if;
      
    end if;


    push_FIFO_nativ_step_by_step_reader_32_slave(packet_nr_fifo, packet_counter_r_s2m);

  end if;
end process;


i_fifo_write_enable <= i_data_out_valid when s_reader_state =  fillFifo 
                       else '0';




gen_DAC_CONTROL: for i in 2 to (COLNum -1)+2 generate

fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => i_data_out(i),
  wen   =>  i_fifo_write_enable,
  full  => i_fifo_full(i-2),
  ren   => fifo_r_s2m.read_enable,
  dout  => data_out(i-2),
  empty => open
);

end generate gen_DAC_CONTROL;

i_fifo_full_or_reduce <= or_reduce(i_fifo_full);

OP_fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 

) port map (
  clk   => clk,
  rst   => reset,
  din   => i_data_out(0),
  wen   => i_fifo_write_enable,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => controls_out.Operation, -- controls_out(4)
  empty => fifo_r_m2s.empty
);


PacketNr_fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 

) port map (
  clk   => clk,
  rst   => reset,
  din   => i_data_out(1),
  wen   => i_fifo_write_enable,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => numStream_signal,
  empty => open
);




timestamp_fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => timestamp_signal,
  wen   =>  i_fifo_write_enable,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => controls_out.timestampRec, -- controls_out(0)
  empty => open
);

packet_counter_fifo : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => packet_counter_w_m2s.data,
  wen   =>  packet_counter_w_m2s.write_enable,
  full  => packet_counter_w_s2m.full,
  ren   => packet_counter_r_s2m.read_enable,
  dout  => packet_counter_r_m2s.data,
  empty => packet_counter_r_m2s.empty
);

controls_out.timestampSend  <= timestamp_signal; -- controls_out(1)
controls_out.maxPacketNr    <= max_Packet_nr_signal;  -- controls_out(2)
controls_out.numStream      <= numStream_signal; -- controls_out(3)
end architecture;
