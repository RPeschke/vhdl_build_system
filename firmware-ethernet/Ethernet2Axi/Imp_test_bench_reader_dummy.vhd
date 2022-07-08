
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
use work.Imp_test_bench_pgk.all;


entity Imp_test_bench_reader_dummy is 
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


architecture rtl of Imp_test_bench_reader_dummy is


type state_t is (idle,make_packet, send,wait_for_idle);

signal reader_state : state_t := idle;


signal  packetNr       : slv(31 downto 0) := (others => '0');
signal  operation      : slv(31 downto 0) := (others => '0');

signal  timestamp_signal      : slv(31 downto 0) := (others => '0');
signal reset : sl := '0';

signal axi_in_m2s : axi_stream_32_m2s := axi_stream_32_m2s_null;
signal axi_in_s2m : axi_stream_32_s2m := axi_stream_32_s2m_null;





signal fifo_r_m2s : FIFO_nativ_reader_32_m2s := FIFO_nativ_reader_32_m2s_null;
signal fifo_r_s2m : FIFO_nativ_reader_32_s2m := FIFO_nativ_reader_32_s2m_null;
signal i_data_out    :  Word32Array((COLNum -1) downto 0) := (others => (others => '0'));
signal we          : sl := '0';
signal Max_word : integer := 400;

begin
axi_in_m2s.data <= rxData;
axi_in_m2s.last <=rxDataLast;
axi_in_m2s.valid <= rxDataValid;
rxDataReady <= axi_in_s2m.ready;


seq : process (Clk) is
  variable axi_in : axi_stream_32_slave_stream := axi_stream_32_slave_stream_null;
  variable int_buffer : integer :=0;
  variable Index : integer :=0;
  variable packetCounter : integer :=0;
  variable rxbuffer      : slv(31 downto 0) := (others => '0');
begin
  if (rising_edge(Clk)) then

    pull_axi_stream_32_slave_stream(axi_in, axi_in_m2s);
    we <= '0';
    reset <= '0';
    fifo_r_s2m.read_enable <='0';
    valid <= '0';
    operation <= (others => '0');
    timestamp_signal <= timestamp_signal +1;

    if reader_state = idle then 
        i_data_out  <= (others => (others => '0'));
        if isReceivingData(axi_in)  then 
            reader_state <= make_packet;
            timestamp_signal <= (others => '0');
            Index := 0;
            packetCounter := 0;
            packetNr <= packetNr +1;
        end if;

    elsif reader_state = make_packet then
        int_buffer := (packetCounter * 1024 ) +  Index + 100;
        i_data_out(Index) <=  std_logic_vector(to_unsigned(int_buffer, 32)); 
        Index := Index + 1;
       
        if Index >= COLNum then 
            index := 0;
            packetCounter :=packetCounter +1;
            we <=  '1';
        end if ;

        if packetCounter >= Max_word then 
            packetCounter := 0;
            reader_state <= send;
            operation(0) <= '1';
            
        end if;
    elsif reader_state = send then
        if fifo_r_s2m.read_enable ='1' then 
          valid <= '1';
        end if;
        fifo_r_s2m.read_enable <='1';
        
    
        packetCounter := packetCounter +1;
        if packetCounter >= Max_word +1 then 
            packetCounter := 0;
            reader_state <= wait_for_idle;
            reset <= '1';
        end if;
    elsif reader_state = wait_for_idle then
        
        if timestamp_signal > 10 then 
            reader_state <= idle;


        end if;

    end if;

    
    -- flush input
    if isReceivingData(axi_in) then 
        read_data(axi_in,rxbuffer);
    end if;

    push_axi_stream_32_slave_stream(axi_in,axi_in_s2m);
  
    
  end if;
end process seq;


gen_DAC_CONTROL: for i in 1 to (COLNum -1) generate

fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => i_data_out(i),
  wen   =>  we,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => data_out(i),
  empty => open
);

end generate gen_DAC_CONTROL;

fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 

) port map (
  clk   => clk,
  rst   => reset,
  din   => i_data_out(0),
  wen   =>  we,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => fifo_r_m2s.data,
  empty => fifo_r_m2s.empty
);

data_out(0) <=  fifo_r_m2s.data;


timestamp_fifo_i : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH 
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => timestamp_signal,
  wen   =>  we,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => controls_out.timestampRec,
  empty => open
);


op_fifo : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => operation,
  wen   =>  we,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => controls_out.Operation,
  empty => open
);

packetNr_fifo : entity work.fifo_cc generic map (
  DATA_WIDTH => 32,
  DEPTH => FIFO_DEPTH
  
) port map (
  clk   => clk,
  rst   => reset,
  din   => packetNr,
  wen   =>  we,
  full  => open,
  ren   => fifo_r_s2m.read_enable,
  dout  => controls_out.numStream ,
  empty => open
);

controls_out.timestampSend <= timestamp_signal;

controls_out.maxPacketNr    <= std_logic_vector(to_signed(Max_word, controls_out.maxPacketNr'length)); --  Max_word;  -- controls_out(2)
--controls_out.numStream      <= packetNr;-- numStream_signal; -- controls_out(3)
end architecture;
