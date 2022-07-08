--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:32:20 09/25/2015
-- Design Name:   
-- Module Name:   /home/kurtisn/mtc/Scrod_mTC_Firmware/src/firmware-general/General/sim/RstSim.vhd
-- Project Name:  scrodMtc
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: InitRst
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY RstSim IS
END RstSim;
 
ARCHITECTURE behavior OF RstSim IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT InitRst
    PORT(
         clk : IN  std_logic;
         asyncRst : IN  std_logic;
         syncRst : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal fabClk       : std_logic;
   signal fabClkRst    : std_logic;
   signal ethClk62     : std_logic;
   signal ethClk62Rst  : std_logic;
   signal ethClk125    : std_logic;
   signal ethClk125Rst : std_logic;
   signal userRst      : std_logic;
   
   -- Clock period definitions
   constant clk125_period : time :=  8 ns;
   constant clk62_period  : time := 16 ns;
   constant fabclk_period : time :=  4 ns;
 
BEGIN

   ---------------------------------------------------------------------------
   -- Resets
   ---------------------------------------------------------------------------
   -- Generate stable reset signal
   U_PwrUpRst : entity work.InitRst
      generic map (
         RST_CNT_G    => 12500,
         GATE_DELAY_G => 0 ns
      )
      port map (
         clk     => fabClk,
         syncRst => fabClkRst
      );
   -- Synchronize the reset to the 125 MHz domain
   U_RstSync125 : entity work.SyncBit
      generic map (
         INIT_STATE_G => '1',
         GATE_DELAY_G => 0 ns
      )
      port map (
         clk      => ethClk125,
         rst      => '0',
         asyncBit => ethClk62Rst,
         syncBit  => ethClk125Rst
      );
   -- Synchronize the reset to the 62 MHz domain
   U_RstSync62 : entity work.SyncBit
      generic map (
         INIT_STATE_G => '1',
         GATE_DELAY_G => 0 ns
      )
      port map (
         clk      => ethClk125,
         rst      => '0',
         asyncBit => fabClkRst,
         syncBit  => ethClk62Rst
      );
   -- User reset
   U_RstSyncUser : entity work.SyncBit
      generic map (
         INIT_STATE_G => '1',
         GATE_DELAY_G => 0 ns
      )
      port map (
         clk      => ethClk125,
         rst      => '0',
         asyncBit => ethClk62Rst,
         syncBit  => userRst
      );


   -- Clock process definitions
   clk125_process :process
   begin
		ethClk125 <= '0';
		wait for clk125_period/2;
		ethClk125 <= '1';
		wait for clk125_period/2;
   end process;
   -- Clock process definitions
   clk62_process :process
   begin
		ethClk62 <= '0';
		wait for clk62_period/2;
		ethClk62 <= '1';
		wait for clk62_period/2;
   end process;
   -- Clock process definitions
   fabclk_process :process
   begin
		fabclk <= '0';
		wait for fabclk_period/2;
		fabclk <= '1';
		wait for fabclk_period/2;
   end process;


   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      -- insert stimulus here 

      wait;
   end process;

END;
