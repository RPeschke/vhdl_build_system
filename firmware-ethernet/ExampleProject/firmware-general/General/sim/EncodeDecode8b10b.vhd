--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:46:53 12/30/2015
-- Design Name:   
-- Module Name:   C:/Users/Kurtis/Desktop/mtcSvn/temp/LucaIRS3D_Ethernet_firmware/src/firmware-general/General/sim/EncodeDecode8b10b.vhd
-- Project Name:  scrodMtc
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Encode8b10b
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
LIBRARY std;
use std.textio.all;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types
use work.utilitypkg.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY EncodeDecode8b10b IS
END EncodeDecode8b10b;
 
ARCHITECTURE behavior OF EncodeDecode8b10b IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Encode8b10b
    PORT(
         clk : IN  std_logic;
         clkEn : IN  std_logic;
         rst : IN  std_logic;
         dataIn : IN  std_logic_vector(7 downto 0);
         dataKIn : IN  std_logic;
         dispIn : IN  std_logic;
         dataOut : OUT  std_logic_vector(9 downto 0);
         dispOut : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk           : std_logic := '0';
   signal clkEn         : std_logic := '0';
   signal rst           : std_logic := '0';
   signal encodeDataIn  : std_logic_vector(7 downto 0) := (others => '0');
   signal encodeDataKIn : std_logic := '0';

 	--Outputs
   signal encodeDataOut  : std_logic_vector(9 downto 0);
   signal encodeDispOut  : std_logic;
   signal decodeDispOut  : std_logic;
   signal decodeDataOut  : std_logic_vector(7 downto 0) := (others => '0');
   signal decodeDataKOut : std_logic;
   signal decodeCodeErr  : std_logic;
   signal decodeDispErr  : std_logic;

   signal encodeVDataOut  : std_logic_vector(9 downto 0);
   signal encodeVDispIn   : std_logic := '0';
   signal encodeVDispOut  : std_logic := '0';
   signal decodeVDispIn   : std_logic := '0';
   signal decodeVDispOut  : std_logic := '0';
   signal decodeVDataOut  : std_logic_vector(7 downto 0) := (others => '0');
   signal decodeVDataKOut : std_logic;
   signal decodeVCodeErr  : std_logic;
   signal decodeVDispErr  : std_logic;
   
   signal encodeDataInPipe  : Word8Array(1 downto 0) := (others => (others => '0'));
   signal encodeDataKInPipe : std_logic_vector(1 downto 0) := (others => '0');

   signal counter : integer range 0 to 255 := 0;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant clkEn_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Units Under Test (UUTs)
   U_Encode8b10b : entity work.Encode8b10b 
      PORT MAP (
         clk     => clk,
         clkEn   => clkEn,
         rst     => rst,
         dataIn  => encodeDataIn,
         dataKIn => encodeDataKIn,
         dispIn  => encodeDispOut,
         dataOut => encodeDataOut,
         dispOut => encodeDispOut
      );
   U_Decode8b10b : entity work.Decode8b10b
      PORT MAP (
         clk      => clk,
         clkEn    => clkEn,
         rst      => rst,
         dataIn   => encodeDataOut,
         dispIn   => decodeDispOut,
         dataOut  => decodeDataOut,
         dataKOut => decodeDataKOut,
         dispOut  => decodeDispOut,
         codeErr  => decodeCodeErr,
         dispErr  => decodeDispErr
      );

	-- Comparisons to original verilog
   U_VEncode8b10b : entity work.encode 
      PORT MAP (
         dataIn(8)          => encodeDataKInPipe(1),
         dataIn(7 downto 0) => encodeDataInPipe(1),
         dispIn             => encodeVDispIn,
         dataOut            => encodeVDataOut,
         dispOut            => encodeVDispOut
      );
   U_VDecode8b10b : entity work.decode
      PORT MAP (
         dataIn              => encodeVDataOut,
         dispIn              => decodeVDispIn,
         dataOut(8)          => decodeVDataKOut,
         dataOut(7 downto 0) => decodeVDataOut,
         dispOut             => decodeVDispOut,
         code_err            => decodeVCodeErr,
         disp_err            => decodeVDispErr
      );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   clkEn_process :process
   begin
		clkEn <= '0';
		wait for clkEn_period/2;
		clkEn <= '1';
		wait for clkEn_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';

      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
      rst <= '0';
      -- insert stimulus here 

      wait;
   end process;

   process(clk) 
      variable my_line : line;
      variable counter : integer range 0 to 255;
      variable kValue  : std_logic := '0';
   begin
      if rising_edge(clk) then
         if rst = '1' then
            encodeDataIn  <= (others => '0');
            encodeDataKIn <= '0';
         else
            encodeDataInPipe(0) <= encodeDataIn;
            encodeDataInPipe(1) <= encodeDataInPipe(0);
            encodeDataKInPipe(0) <= encodeDataKIn;
            encodeDataKInPipe(1) <= encodeDataKInPipe(0);
            encodeDataKIn <= kValue;            
            if kValue = '0' then
               encodeDataIn  <= conv_std_logic_vector(255-counter, 8);
            else
               case(counter) is
                  when  0 => encodeDataIn <= conv_std_logic_vector( 28, 8);
                  when  1 => encodeDataIn <= conv_std_logic_vector( 60, 8);
                  when  2 => encodeDataIn <= conv_std_logic_vector( 92, 8);
                  when  3 => encodeDataIn <= conv_std_logic_vector(124, 8);
                  when  4 => encodeDataIn <= conv_std_logic_vector(156, 8);
                  when  5 => encodeDataIn <= conv_std_logic_vector(188, 8);
                  when  6 => encodeDataIn <= conv_std_logic_vector(220, 8);
                  when  7 => encodeDataIn <= conv_std_logic_vector(252, 8);
                  when  8 => encodeDataIn <= conv_std_logic_vector(247, 8);
                  when  9 => encodeDataIn <= conv_std_logic_vector(251, 8);
                  when 10 => encodeDataIn <= conv_std_logic_vector(253, 8);
                  when 11 => encodeDataIn <= conv_std_logic_vector(254, 8);
                  when others => encodeDataIn <= x"BC";
               end case;
            end if;

            if kValue = '0' then
               if (counter < 255) then
                  counter := counter + 1;
               else
                  counter := 0;
                  kValue  := '1';
               end if;
            else
               if (counter < 255) then
--               if (counter < 11) then
                  counter := counter + 1;
               else
                  counter := 0;
                  kValue  := '0';
               end if;            
            end if;

            write(my_line, string'("IN: "));
            hwrite(my_line, encodeDataInPipe(1));
            write(my_line, string'(","));
            write(my_line, encodeDataKInPipe(1));
            
            write(my_line, string'(" OUT: "));
            hwrite(my_line, decodeDataOut);
            write(my_line, string'(","));
            write(my_line, decodeDataKOut);

            if encodeDataInPipe(1) /= decodeDataOut then
               write(my_line, string'(" <-- ERROR"));
            end if;

            writeline(output, my_line);
                        
         end if;
      end if;
   end process;

   process(clk) begin
      if rising_edge(clk) then
         encodeVDispIn <= encodeVDispOut;
         decodeVDispIn <= decodeVDispOut;
      end if;
   end process;


END;
