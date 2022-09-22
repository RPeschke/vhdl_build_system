--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:38:54 09/09/2015
-- Design Name:   
-- Module Name:   C:/Users/Kurtis/Google Drive/mTC/svn/src/General/sim/CommandInterpreterTest.vhd
-- Project Name:  ethernet
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CommandInterpreter
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY CommandInterpreterTest IS
END CommandInterpreterTest;
 
ARCHITECTURE behavior OF CommandInterpreterTest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT CommandInterpreter
    PORT(
         usrClk : IN  std_logic;
         usrRst : IN  std_logic;
         rxData : IN  std_logic_vector(31 downto 0);
         rxDataValid : IN  std_logic;
         rxDataLast : IN  std_logic;
         rxDataReady : OUT  std_logic;
         txData : OUT  std_logic_vector(31 downto 0);
         txDataValid : OUT  std_logic;
         txDataLast : OUT  std_logic;
         txDataReady : IN  std_logic;
         myId : IN  std_logic_vector(15 downto 0);
         regAddr : OUT  std_logic_vector(15 downto 0);
         regWrData : OUT  std_logic_vector(15 downto 0);
         regRdData : IN  std_logic_vector(15 downto 0);
         regReq : OUT  std_logic;
         regOp : OUT  std_logic;
         regAck : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal usrClk : std_logic := '0';
   signal usrRst : std_logic := '0';
   signal rxData : std_logic_vector(31 downto 0) := (others => '0');
   signal rxDataValid : std_logic := '0';
   signal rxDataLast : std_logic := '0';
   signal txDataReady : std_logic := '0';
   signal myId : std_logic_vector(15 downto 0) := (others => '0');
   signal regRdData : std_logic_vector(15 downto 0) := (others => '0');
   signal regAck : std_logic := '0';

 	--Outputs
   signal rxDataReady : std_logic;
   signal txData : std_logic_vector(31 downto 0);
   signal txDataValid : std_logic;
   signal txDataLast : std_logic;
   signal regAddr : std_logic_vector(15 downto 0);
   signal regWrData : std_logic_vector(15 downto 0);
   signal regReq : std_logic;
   signal regOp : std_logic;

   signal packetCount : std_logic_vector(15 downto 0) := (others => '0');

   signal targetAddr : std_logic_vector(15 downto 0) := x"00A5";
   signal targetData : std_logic_vector(15 downto 0) := x"0120";

   signal thisCommand           : std_logic_vector(31 downto 0);
   signal thisCommandId         : std_logic_vector(23 downto 0);
   signal thisCommandNoResponse : std_logic;
   signal thisCommandIdWord     : std_logic_vector(31 downto 0);
   signal thisCommandDataWord   : std_logic_vector(31 downto 0);
   signal commandChecksum       : std_logic_vector(31 downto 0);
   signal packetChecksum        : std_logic_vector(31 downto 0);
   signal scrodRev              : std_logic_vector(7 downto 0);
   signal scrodId               : std_logic_Vector(15 downto 0);
   signal scrodIdWord           : std_logic_vector(31 downto 0);
   signal packetLength          : std_logic_vector(31 downto 0);
   
   signal myReg                 : std_logic_vector(15 downto 0);
   constant MY_REG_ADDR_C       : std_logic_Vector(15 downto 0) := x"00A5";
   
   constant WORD_HEADER_C    : std_logic_vector(31 downto 0) := x"00BE11E2";
   constant WORD_COMMAND_C   : std_logic_vector(31 downto 0) := x"646F6974";
   constant WORD_PING_C      : std_logic_vector(31 downto 0) := x"70696E67";
   constant WORD_READ_C      : std_logic_vector(31 downto 0) := x"72656164";
   constant WORD_WRITE_C     : std_logic_vector(31 downto 0) := x"72697465";
   constant WORD_ACK_C       : std_logic_vector(31 downto 0) := x"6F6B6179";
   constant WORD_ERR_C       : std_logic_vector(31 downto 0) := x"7768613f";
   
   -- Clock period definitions
   constant usrClk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: CommandInterpreter PORT MAP (
          usrClk => usrClk,
          usrRst => usrRst,
          rxData => rxData,
          rxDataValid => rxDataValid,
          rxDataLast => rxDataLast,
          rxDataReady => rxDataReady,
          txData => txData,
          txDataValid => txDataValid,
          txDataLast => txDataLast,
          txDataReady => txDataReady,
          myId => myId,
          regAddr => regAddr,
          regWrData => regWrData,
          regRdData => regRdData,
          regReq => regReq,
          regOp => regOp,
          regAck => regAck
        );

   -- Clock process definitions
   usrClk_process :process
   begin
		usrClk <= '0';
		wait for usrClk_period/2;
		usrClk <= '1';
		wait for usrClk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      usrRst <= '1';
      wait for 100 ns;	
      usrRst <= '0';
      wait for usrClk_period*10;

      -- insert stimulus here 

      wait;
   end process;
   
   scrodRev              <= x"00";
   scrodId               <= x"0000";
   thisCommand           <= WORD_READ_C;
   thisCommandId         <= x"009900";
   thisCommandNoResponse <= '0';
   targetAddr            <= x"00A6";
   targetData            <= x"0120";
   
   thisCommandIdWord     <= thisCommandNoResponse & "0000000" & thisCommandId;
   thisCommandDataWord   <= targetData & targetAddr;
   scrodIdWord           <= x"00" & scrodRev & scrodId;
   
   packetLength <= x"00000007" when thisCommand /= WORD_PING_C else x"00000006";
   
   commandChecksum <= thisCommandIdWord + thisCommand + thisCommandDataWord;
   packetChecksum  <= WORD_HEADER_C + packetLength + WORD_COMMAND_C + 
                      scrodIdWord + thisCommandIdWord + thisCommand + 
                      thisCommandDataWord + commandChecksum;
   
   process(usrClk) begin
      if rising_edge(usrClk) then
         if usrRst = '1' then
            rxDataValid <= '0';
            rxDataLast  <= '0';
            rxData      <= (others => '0');
         else 
            if rxDataReady = '1' then
               packetCount <= packetCount + 1;
            end if;
            rxDataValid <= '1';
            rxDataLast  <= '0';
            case conv_integer(packetCount) is
               when 0 => rxData <= WORD_HEADER_C;
               when 1 => rxData <= packetLength;
               when 2 => rxData <= WORD_COMMAND_C;
               when 3 => rxData <= scrodIdWord;
               when 4 => rxData <= thisCommandIdWord;
               when 5 => rxData <= thisCommand;
               when 6 => rxData <= thisCommandDataWord;
               when 7 => rxData <= commandChecksum;
               when 8 => rxData <= packetChecksum;
                         rxDataLast <= '1';
               when others => rxDataValid <= '0';
            end case;
         end if;
      end if;
   end process;


   process(usrClk) begin
      if rising_edge(usrClk) then
         if usrRst = '1' then
            myReg <= x"AAAA";
         elsif regReq = '1' then
            regAck <= regReq;
            case regAddr is
               when MY_REG_ADDR_C => 
                  regRdData <= myReg;
                  if regOp = '1' then
                     myReg <= regWrData;
                  end if;
               when others  =>
                  regRdData <= (others => '0');
            end case;
         else
            regAck <= '0';
         end if;
      end if;
   end process;
   
   txDataReady <= '1';
   
END;
