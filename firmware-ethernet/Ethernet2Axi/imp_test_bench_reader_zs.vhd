
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.numeric_std.all;

  use work.UtilityPkg.all;
  use work.axiDWORDbi_p.all;

  use work.type_conversions_pgk.all;

  use work.Imp_test_bench_pgk.all;

  use work.xgen_axiStream_64.all;
  use work.type_conversions_pgk.all;
  use work.xgen_rollingCounter.all;

entity imp_test_bench_reader_zs is
  generic ( 
    COLNum : integer := 10;
    FIFO_DEPTH : integer := 10;
    MaxChanges  : integer := 10
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

architecture rtl of imp_test_bench_reader_zs is
  signal  timestamp_signal      : slv(31 downto 0) := (others => '0');
  signal  max_Packet_nr_signal      : slv(31 downto 0) := (others => '0');
  signal  numStream_signal          : slv(31 downto 0) := (others => '0');
  
  signal  rst : sl := '0';
  signal i_data_in       :  Word32Array((COLNum -1)+2 downto 0) := (others => (others => '0'));
  signal i_data_in_valid : sl := '0';
  
  signal i_data_out       :  Word32Array((COLNum -1)+2 downto 0) := (others => (others => '0'));
  signal i_valid : std_logic := '0';
  signal i_ready : std_logic := '0';

  signal i_ToManyChangesError_a2z : std_logic := '0';
  signal i_ToManyChangesError_z2a : std_logic :='0';

  
begin

  des : entity work.StreamDeserializer generic map (
    COLNum => COLNum + 2
  ) port map ( 
    Clk    => Clk,
    -- Incoming data
    rxData      => rxData,
    rxDataValid => rxDataValid,
    rxDataLast  => rxDataLast,
    rxDataReady => rxDataReady,
    data_out    => i_data_in,
    valid       => i_data_in_valid
  );


  send_data_from_fifo: process(clk) is


  begin 
    if (rising_edge(Clk)) then
      rst <= '0';
    if    i_data_in_valid = '1' and data_out(0) > 0 then 
      i_ready <= '1';
    elsif i_valid ='0' and i_ready = '1' then
      i_ready <= '0';
      rst <= '1';
    end if;

    if i_ToManyChangesError_z2a ='1' or i_ToManyChangesError_a2z ='1' then
      rst <= '1';
    end if;
    end if;
  end process;



 zs_fifo :  entity  work.zero_supression_test_connection generic map(
      COLNum =>  COLNum + 2,
      MaxChanges => MaxChanges,
      DEPTH => FIFO_DEPTH
    ) port map (
      clk => clk,
      rst => rst,

      data_in    => i_data_in,
      valid_in   => i_data_in_valid,
      ToManyChangesError_a2z => i_ToManyChangesError_a2z,

      data_out    => i_data_out,
      valid_out   => i_valid,
      ready_out   => i_ready,
      ToManyChangesError_z2a =>i_ToManyChangesError_z2a
    );
    valid <= i_valid;
    controls_out.timestampSend  <= timestamp_signal; -- controls_out(1)
    controls_out.maxPacketNr    <= max_Packet_nr_signal;  -- controls_out(2)
    controls_out.numStream      <= numStream_signal; -- controls_out(3)
    controls_out.Operation  <= i_data_out(0);
    data_out <= i_data_out;
end architecture;