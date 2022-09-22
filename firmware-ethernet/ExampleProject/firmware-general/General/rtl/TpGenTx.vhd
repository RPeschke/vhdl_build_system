----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:57:00 09/02/2015 
-- Design Name: 
-- Module Name:    TpGenTx - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TpGenTx is
   generic (
--      NUM_WORDS_G   : integer := 1000;
--      WAIT_CYCLES_G : integer := 125000000;
      GATE_DELAY_G  : time := 1 ns
   );
   port (
      -- User clock and reset
      userClk         : in  sl;
      userRst         : in  sl;
      -- Configuration
      waitCycles      : in  slv(31 downto 0);
      numWords        : in  slv(31 downto 0);
      -- Connection to user logic
      userTxData      : out slv(31 downto 0);
      userTxDataValid : out sl;
      userTxDataLast  : out sl;
      userTxDataReady : in  sl
   );
end TpGenTx;

architecture Behavioral of TpGenTx is

   type StateType is (IDLE_S, HEADER_S, DATA_S, LAST_S, WAIT_S);
   
   type RegType is record
      state          : StateType;
      eventNum       : slv(31 downto 0);
      eventData      : slv(31 downto 0);
      eventDataValid : sl;
      eventDataLast  : sl;
      dataCount      : slv(31 downto 0);
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state          => IDLE_S,
      eventNum       => (others => '0'),
      eventData      => (others => '0'),
      eventDataValid => '0',
      eventDataLast  => '0',
      dataCount      => (others => '0')
   );
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   -- ISE attributes to keep signals for debugging
   -- attribute keep : string;
   -- attribute keep of r : signal is "true";
   -- attribute keep of crcOut : signal is "true";      
   
   -- Vivado attributes to keep signals for debugging
   -- attribute dont_touch : string;
   -- attribute dont_touch of r : signal is "true";
   -- attribute dont_touch of crcOut : signal is "true";   

begin

   comb : process(r,userRst,userTxDataReady) is
      variable v : RegType;
   begin
      v := r;

      -- Set defaults / reset any pulsed signals
      v.eventDataValid := '0';
      
      -- State machine
      case(r.state) is 
         when IDLE_S =>
            v.eventDataLast := '0';
            v.eventData     := (others => '0');
            if userTxDataReady = '1' then
               v.dataCount      := numWords;
--               v.dataCount      := conv_std_logic_vector(NUM_WORDS_G-1,32);
               v.eventData      := r.eventNum;
               v.eventDataValid := '1';
               v.state          := HEADER_S;
            end if;
         when HEADER_S =>
            v.eventDataValid := '1';
            if userTxDataReady = '1' then
               v.eventData := r.eventNum(15 downto 0) & v.dataCount(15 downto 0);
               v.state     := DATA_S;
            end if;
         when DATA_S =>
            v.eventDataValid := '1';
            if userTxDataReady = '1' then
               v.dataCount := r.dataCount - 1;
               v.eventData := r.eventNum(15 downto 0) & v.dataCount(15 downto 0);
               if v.dataCount = 0 then
                  v.eventDataLast  := '1';
                  v.state          := LAST_S;
               end if;
            end if;
         when LAST_S =>
            v.eventDataValid := '1';
            if userTxDataReady = '1' then
               v.eventDataValid := '0';
               v.eventDataLast  := '0';
               v.dataCount      := waitCycles;
--               v.dataCount      := conv_std_logic_vector(WAIT_CYCLES_G-1,32);
               v.state          := WAIT_S;
            end if;
         when WAIT_S =>
            v.dataCount := r.dataCount - 1;
            if r.dataCount = 0 then
               v.eventNum := r.eventNum + 1;
               v.state := IDLE_S;
            end if;
         when others =>
            v.state := IDLE_S;
      end case;
         
      -- Reset logic
      if (userRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs to ports
      userTxData      <= r.eventData;
      userTxDataValid <= r.eventDataValid;
      userTxDataLast  <= r.eventDataLast;
      
      -- Assign variable to signal
      rin <= v;

   end process;

   seq : process (userClk) is
   begin
      if (rising_edge(userClk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;   

end Behavioral;

