---------------------------------------------------------------------------------
-- Title         : 1-bit synchronizer
-- Project       : General Purpose Core
---------------------------------------------------------------------------------
-- File          : SyncEdge.vhd
-- Author        : Kurtis Nishimura
---------------------------------------------------------------------------------
-- Description:
-- Simple one-bit synchronizer with edge detect.
---------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;
library unisim;
use unisim.vcomponents.all;


entity SyncEdge is 
   generic (
      SYNC_STAGES_G  : integer := 2;
      CLK_POL_G      : sl := '1';
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
      syncBit     : out sl;
      syncREdge   : out sl;
      syncFEdge   : out sl
   ); 
end SyncEdge;

-- Define architecture
architecture structural of SyncEdge is

   signal iSyncBit    : sl;
   signal syncBitPipe : slv(1 downto 0);

begin

   syncBit <= iSyncBit;

   U_SyncBit : entity work.SyncBit
   generic map ( 
      SYNC_STAGES_G => SYNC_STAGES_G,
      CLK_POL_G     => CLK_POL_G,
      RST_POL_G     => RST_POL_G,
      INIT_STATE_G  => INIT_STATE_G,
      GATE_DELAY_G  => GATE_DELAY_G
   )
   port map (
      clk      => clk,
      rst      => rst,
      asyncBit => asyncBit,
      syncBit  => iSyncBit
   );   

   G_RISING : if CLK_POL_G = '1' generate
      process (clk) begin
         if rising_edge(clk) then
            if rst = '1' then
               syncREdge   <= '0' after GATE_DELAY_G;
               syncFEdge   <= '0' after GATE_DELAY_G;
               syncBitPipe <= (others => '0') after GATE_DELAY_G;
            else
               syncBitPipe(1) <= syncBitPipe(0) after GATE_DELAY_G;
               syncBitPipe(0) <= iSyncBit       after GATE_DELAY_G;
               if syncBitPipe = "01" then
                  syncREdge <= '1' after GATE_DELAY_G;
               else
                  syncREdge <= '0' after GATE_DELAY_G;
               end if;
               if syncBitPipe = "10" then
                  syncFEdge <= '1' after GATE_DELAY_G;
               else
                  syncFEdge <= '0' after GATE_DELAY_G;
               end if;
            end if;
         end if;
      end process;
   end generate;

   G_FALLING : if CLK_POL_G = '0' generate
      process (clk) begin
         if falling_edge(clk) then
            if rst = '1' then
               syncREdge   <= '0' after GATE_DELAY_G;
               syncFEdge   <= '0' after GATE_DELAY_G;
               syncBitPipe <= (others => '0') after GATE_DELAY_G;
            else
               syncBitPipe(1) <= syncBitPipe(0) after GATE_DELAY_G;
               syncBitPipe(0) <= iSyncBit       after GATE_DELAY_G;
               if syncBitPipe = "01" then
                  syncREdge <= '1' after GATE_DELAY_G;
               else
                  syncREdge <= '0' after GATE_DELAY_G;
               end if;
               if syncBitPipe = "10" then
                  syncFEdge <= '1' after GATE_DELAY_G;
               else
                  syncFEdge <= '0' after GATE_DELAY_G;
               end if;
            end if;
         end if;   
      end process;
   end generate;

end structural;

