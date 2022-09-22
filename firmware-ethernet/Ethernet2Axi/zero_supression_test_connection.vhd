
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;



-- Start Include user packages --
  use work.utilitypkg.all;
  use work.axidwordbi_p.all;
  use work.type_conversions_pgk.all;
  use work.imp_test_bench_pgk.all;
  use work.xgen_axistream_zerosupression.all;
  use work.xgen_rollingcounter.all;
  use work.zerosupression_p.all;

entity zero_supression_test_connection is
  generic(
    COLNum : integer := 10;
    MaxChanges  : integer := 3;
    DEPTH : natural := 10 
  );
  port (
    clk: in  std_logic;
    rst: in  std_logic;
    
    data_in     : in Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
    valid_in    : in std_logic;
    ToManyChangesError_a2z : out std_logic;
    
    data_out     : out  Word32Array(COLNum - 1 downto 0) := (others => (others => '0'));
    valid_out    : out  std_logic;
    ready_out    : in std_logic :='1';
    ToManyChangesError_z2a : out std_logic
  );
end entity;

architecture rtl of zero_supression_test_connection is
 signal zs_data_out_m2s :   axisStream_zerosupression_m2s_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_m2s_null);
 signal zs_data_out_s2m :   axisStream_zerosupression_s2m_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_s2m_null);
 
 signal zs_data_in_m2s :   axisStream_zerosupression_m2s_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_m2s_null);
 signal zs_data_in_s2m :   axisStream_zerosupression_s2m_a(MaxChanges - 1 downto 0) := (others =>axisStream_zerosupression_s2m_null);
 signal i_ready_out    : std_logic :='1';
 signal max_packet_nr : slv(15 downto 0) := (others => '0');
begin
  process(clk) is
    
  begin
    if rising_edge(clk) then

		i_ready_out <= not i_ready_out;
    end if;
  end process;
      
  
 a2z : entity  work.array2zero_suprresed generic map(
      COLNum => COLNum,
      MaxChanges  => MaxChanges
    ) port map (
      clk => clk,
      rst => rst,
      data_in => data_in,
      valid   => valid_in,
      ToManyChangesError => ToManyChangesError_a2z,
      zs_data_out_m2s => zs_data_out_m2s,
      zs_data_out_s2m => zs_data_out_s2m,
      max_packet_nr => max_packet_nr
    );
 fifogen: for i in 0 to (MaxChanges -1) generate
fifo :  entity work.fifo_cc_axi generic map(
     DATA_WIDTH => 64,
     DEPTH => DEPTH
   ) port map (
     clk       => clk,
     rst       => rst,
     RX_Data(63 downto 48)   => zs_data_out_m2s(i).data.time_index,
     RX_Data(47 downto 32)   => zs_data_out_m2s(i).data.array_index,
     RX_Data(31 downto 0)   => zs_data_out_m2s(i).data.data,
     RX_Valid  => zs_data_out_m2s(i).valid,
     RX_Last   => zs_data_out_m2s(i).last,
     RX_Ready  => zs_data_out_s2m(i).ready,
     
     TX_Data(63 downto 48)   => zs_data_in_m2s(i).data.time_index,
     TX_Data(47 downto 32)   => zs_data_in_m2s(i).data.array_index,
     TX_Data(31 downto 0)   => zs_data_in_m2s(i).data.data,
     TX_Valid  => zs_data_in_m2s(i).valid,
     TX_Last   => zs_data_in_m2s(i).last,
     TX_Ready  => zs_data_in_s2m(i).ready
   );
 end generate fifogen;
 z2a :  entity work.zero_suppressed2array generic map(
      COLNum =>COLNum,
      MaxChanges  => MaxChanges
    ) port map (
      clk => clk,
      rst => rst, 
      zs_data_out_m2s => zs_data_in_m2s,
      zs_data_out_s2m => zs_data_in_s2m,
      ToManyChangesError => ToManyChangesError_z2a,
      data_out => data_out,
      valid    => valid_out,
      ready_out => ready_out,
      max_packet_nr => max_packet_nr
    );

end architecture;