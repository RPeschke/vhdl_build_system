---------------------------------------------------------------------------------
-- Title         : 1-bit synchronizer
-- Project       : General Purpose Core
---------------------------------------------------------------------------------
-- File          : SyncBit.vhd
-- Author        : Kurtis Nishimura
---------------------------------------------------------------------------------
-- Description:
-- Simple one-bit synchronizer.
---------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;

entity SyncBit is 
   generic (
      SYNC_STAGES_G  : integer := 2;
      RST_POL_G      : sl := '1';
      INIT_STATE_G   : sl := '0';
      GATE_DELAY_G   : time := 1 ns
   );
   port ( 
      -- Clock and reset
      clk         : in  sl;
      rst         : in  sl;
      -- Incoming bit, asynchronous
      asyncBit    : in  sl;
      -- Outgoing bit, synced to clk
      syncBit     : out sl
   ); 
end SyncBit;

-- Define architecture
architecture rtl of SyncBit is

   signal clockDomainCrossingReg     : slv(SYNC_STAGES_G-1 downto 0) := (others => '0');
   signal clockDomainCrossingRegNext : slv(SYNC_STAGES_G-1 downto 0) := (others => '0');
   
   -- Make sure the register doesn't get trimmed out
   attribute shreg_extract : string;
   attribute shreg_extract of clockDomainCrossingReg : signal is "no";
   -- And no logic allowed between stages
   attribute register_balancing : string;
   attribute register_balancing of clockDomainCrossingReg : signal is "no";
   -- No messages about timing errors for this register (we know we're crossing a clock domain)
   attribute msgon : string;
   attribute msgon of clockDomainCrossingReg : signal is "no";
   
begin

   comb : process (clockDomainCrossingReg, rst, asyncBit) begin
      if rst = '1' then
         clockDomainCrossingRegNext <= (others => INIT_STATE_G);
      else
         clockDomainCrossingRegNext <= clockDomainCrossingReg(SYNC_STAGES_G - 2 downto 0) & asyncBit;
      end if;
      syncBit <= clockDomainCrossingReg(SYNC_STAGES_G - 1);
   end process;
   
   seq : process(clk) begin
      if rising_edge(clk) then
         clockDomainCrossingReg <= clockDomainCrossingRegNext;
      end if;
   end process;

end rtl;

