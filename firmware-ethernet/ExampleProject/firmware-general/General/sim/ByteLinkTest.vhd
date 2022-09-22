--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:04:53 01/02/2016
-- Design Name:   
-- Module Name:   C:/Users/Kurtis/Desktop/mtcSvn/temp/LucaIRS3D_Ethernet_firmware/src/firmware-general/General/sim/ByteLinkTest.vhd
-- Project Name:  scrodMtc
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ByteLink
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
 
ENTITY ByteLinkTest IS
END ByteLinkTest;
 
ARCHITECTURE behavior OF ByteLinkTest IS 
 
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

   signal rxData8bA      : std_logic_vector(7 downto 0);
   signal rxData8bValidA : std_logic;
   signal rxData8bB      : std_logic_vector(7 downto 0);
   signal rxData8bValidB : std_logic;
   signal alignedA       : std_logic;
   signal alignedB       : std_logic;
   signal txData10bA     : std_logic_vector(9 downto 0);
   signal txData10bB     : std_logic_vector(9 downto 0);

   signal txData8bA      : std_logic_vector(7 downto 0) := (others => '0');
   signal txData8bValidA : std_logic := '0';
   signal txData8bB      : std_logic_vector(7 downto 0) := (others => '0');
   signal txData8bValidB : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   U_ByteLinkA : entity work.ByteLink PORT MAP (
      clk           => clk,
      rst           => rst,
      rxData10b     => txData10bB,
      rxData8b      => rxData8bA,
      rxData8bValid => rxData8bValidA,
      aligned       => alignedA,
      txData8b      => txData8bA,
      txData8bValid => txData8bValidA,
      txData10b     => txData10bA
   );
   U_ByteLinkB : entity work.ByteLink PORT MAP (
      clk           => clk,
      rst           => rst,
      rxData10b     => txData10bA,
      rxData8b      => rxData8bB,
      rxData8bValid => rxData8bValidB,
      aligned       => alignedB,
      txData8b      => txData8bB,
      txData8bValid => txData8bValidB,
      txData10b     => txData10bB
   );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      rst <= '1';
      wait for 100 ns;	

      wait for clk_period*10;
      rst <= '0';
      -- insert stimulus here 

      wait;
   end process;

END;
