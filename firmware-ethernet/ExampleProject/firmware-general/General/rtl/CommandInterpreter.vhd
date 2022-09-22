---------------------------------------------------------------------------------
-- Title         : Command Interpreter
-- Project       : General Purpose Core
---------------------------------------------------------------------------------
-- File          : CommandInterpreter.vhd
-- Author        : Kurtis Nishimura
---------------------------------------------------------------------------------
-- Description:
-- Packet parser for old Belle II format.
-- See: http://www.phys.hawaii.edu/~kurtisn/doku.php?id=itop:documentation:data_format
---------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;

entity CommandInterpreter is 
   generic (
      REG_ADDR_BITS_G : integer := 16;
      REG_DATA_BITS_G : integer := 16;
      TIMEOUT_G       : integer := 125000;
      GATE_DELAY_G    : time := 1 ns
   );
   port ( 
      -- User clock and reset
      usrClk      : in  sl;
      usrRst      : in  sl := '0';
      -- Incoming data
      rxData      : in  slv(31 downto 0);
      rxDataValid : in  sl;
      rxDataLast  : in  sl;
      rxDataReady : out sl;
      -- Outgoing response
      txData      : out slv(31 downto 0);
      txDataValid : out sl;
      txDataLast  : out sl;
      txDataReady : in  sl;
      -- This board ID
      myId        : in  slv(15 downto 0);
      -- Register interfaces
      regAddr     : out slv(REG_ADDR_BITS_G-1 downto 0);
      regWrData   : out slv(REG_DATA_BITS_G-1 downto 0);
      regRdData   : in  slv(REG_DATA_BITS_G-1 downto 0);
      regReq      : out sl;
      regOp       : out sl;
      regAck      : in  sl
		
   ); 
end CommandInterpreter;



-- Define architecture
architecture rtl of CommandInterpreter is

   type StateType     is (IDLE_S,PACKET_SIZE_S,PACKET_TYPE_S,
                          COMMAND_TARGET_S,COMMAND_ID_S,COMMAND_TYPE_S,
                          COMMAND_DATA_S,COMMAND_CHECKSUM_S,
                          PING_S,READ_S,WRITE_S,
                          READ_RESPONSE_S,WRITE_RESPONSE_S,PING_RESPONSE_S,
                          ERR_RESPONSE_S,
                          CHECK_MORE_S,PACKET_CHECKSUM_S,DUMP_S);
   
   type RegType is record
      state       : StateType;
      regAddr     : slv(REG_ADDR_BITS_G-1 downto 0);
      regWrData   : slv(REG_DATA_BITS_G-1 downto 0);
      regRdData   : slv(REG_DATA_BITS_G-1 downto 0);
      regReq      : sl;
      regOp       : sl;
      sendResp    : sl;
      rxDataReady : sl;
      txData      : slv(31 downto 0);
      txDataValid : sl;
      txDataLast  : sl;
      wordsLeft   : slv(31 downto 0);
      wordOutCnt  : slv( 7 downto 0);
      checksum    : slv(31 downto 0);
      command     : slv(31 downto 0);
      commandId   : slv(23 downto 0);
      noResponse  : sl;
      errFlags    : slv(31 downto 0);
      timeoutCnt  : slv(31 downto 0);
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state       => IDLE_S,
      regAddr     => (others => '0'),
      regWrData   => (others => '0'),
      regRdData   => (others => '0'),
      regReq      => '0',
      regOp       => '0',
      sendResp    => '0',
      rxDataReady => '0',
      txData      => (others => '0'),
      txDataValid => '0',
      txDataLast  => '0',
      wordsLeft   => (others => '0'),
      wordOutCnt  => (others => '0'),
      checksum    => (others => '0'),
      command     => (others => '0'),
      commandId   => (others => '0'),
      noResponse  => '0',
      errFlags    => (others => '0'),
      timeoutCnt  => (others => '0')
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
   
   constant WORD_HEADER_C    : slv(31 downto 0) := x"00BE11E2";
   constant WORD_COMMAND_C   : slv(31 downto 0) := x"646F6974";
   constant WORD_PING_C      : slv(31 downto 0) := x"70696E67";
   constant WORD_READ_C      : slv(31 downto 0) := x"72656164";
   constant WORD_WRITE_C     : slv(31 downto 0) := x"72697465";
   constant WORD_ACK_C       : slv(31 downto 0) := x"6F6B6179";
   constant WORD_ERR_C       : slv(31 downto 0) := x"7768613f";

   constant ERR_BIT_SIZE_C    : slv(31 downto 0) := x"00000001";
	constant ERR_BIT_SIZE_C_1  : slv(31 downto 0) := x"10000001";
	constant ERR_BIT_SIZE_C_2  : slv(31 downto 0) := x"20000001";
	constant ERR_BIT_SIZE_C_3  : slv(31 downto 0) := x"30000001";
	constant ERR_BIT_SIZE_C_4  : slv(31 downto 0) := x"40000001";
	constant ERR_BIT_SIZE_C_5  : slv(31 downto 0) := x"50000001";
	constant ERR_BIT_SIZE_C_6  : slv(31 downto 0) := x"60000001";
	constant ERR_BIT_SIZE_C_7  : slv(31 downto 0) := x"70000001";
	constant ERR_BIT_SIZE_C_8  : slv(31 downto 0) := x"80000001";
	
   constant ERR_BIT_TYPE_C    : slv(31 downto 0) := x"00000002";
   constant ERR_BIT_DEST_C    : slv(31 downto 0) := x"00000004";
   constant ERR_BIT_COMM_TY_C : slv(31 downto 0) := x"00000008";
   constant ERR_BIT_COMM_CS_C : slv(31 downto 0) := x"00000010";
   constant ERR_BIT_CS_C      : slv(31 downto 0) := x"00000020";
   constant ERR_BIT_TIMEOUT_C : slv(31 downto 0) := x"00000040";
   
   signal wordScrodRevC      : slv(31 downto 0) := X"00A20000";
   
   signal stateNum : slv(4 downto 0);

   -- attribute keep : string;
   -- attribute keep of stateNum : signal is "true";

   
begin

   stateNum <= "00000" when r.state = IDLE_S else             -- 0 x00
               "00001" when r.state = PACKET_SIZE_S else      -- 1 x01
               "00010" when r.state = PACKET_TYPE_S else      -- 2 x02
               "00011" when r.state = COMMAND_TARGET_S else   -- 3 x03
               "00100" when r.state = COMMAND_ID_S else       -- 4 x04
               "00101" when r.state = COMMAND_TYPE_S else     -- 5 x05
               "00110" when r.state = COMMAND_DATA_S else     -- 6 x06
               "00111" when r.state = COMMAND_CHECKSUM_S else -- 7 x07
               "01000" when r.state = PING_S else             -- 8 x08
               "01001" when r.state = READ_S else             -- 9 x09
               "01010" when r.state = WRITE_S else            -- 10 x0A
               "01011" when r.state = READ_RESPONSE_S else    -- 11 x0B
               "01100" when r.state = WRITE_RESPONSE_S else   -- 12 x0C
               "01101" when r.state = PING_RESPONSE_S else    -- 13 x0D
               "01110" when r.state = ERR_RESPONSE_S else     -- 14 x0E
               "01111" when r.state = CHECK_MORE_S else       -- 15 x0F
               "10000" when r.state = PACKET_CHECKSUM_S else  -- 16 x10
               "10001" when r.state = DUMP_S else             -- 17 x11
               "10010" when r.state = IDLE_S else             -- 18 x12
               "11111";                                       -- 19 x1F
   

   wordScrodRevC(31 downto 0) <= x"00A2" & myId;



   comb : process(r,usrRst,rxData,rxDataValid,rxDataLast,
                  txDataReady,regRdData,regAck,wordScrodRevC) is
      variable v : RegType;
   begin
      v := r;

      -- Resets for pulsed outputs
      v.regReq      := '0';
      v.txDataValid := '0';
      v.txDataLast  := '0';
      rxDataReady   <= '0';
      
      -- State machine 
      case(r.state) is 
         when IDLE_S =>
			
				--numWord <=  max_slv(x"03f0",numWord);
            v.errFlags := (others => '0');
            v.checksum := (others => '0');
            if rxDataValid = '1' then
               rxDataReady <= '1';
               -- Possible errors:
               -- This is last, stay here
               if rxDataLast = '1' then
                  v.state := IDLE_S;
               -- Header doesn't match format
               elsif rxData /= WORD_HEADER_C then
                  v.state := DUMP_S;
               -- Otherwise, move on
               else
                  v.state := PACKET_SIZE_S;
               end if;
            end if;
         when PACKET_SIZE_S => 
	
            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.wordsLeft := rxData;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then 
						v.errFlags := r.errFlags + ERR_BIT_SIZE_C_2; 
                  v.state    := ERR_RESPONSE_S;
					elsif	rxData > 300 then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_1; 
                  v.state    := ERR_RESPONSE_S;
               -- Otherwise, move on
               else
                  v.state := PACKET_TYPE_S;
               end if;
            end if;
         when PACKET_TYPE_S => 

            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.wordsLeft := r.wordsLeft - 1;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_3; 
                  v.state := ERR_RESPONSE_S;
               -- Packet type isn't understood
               elsif rxData /= WORD_COMMAND_C then
                  v.errFlags := r.errFlags + ERR_BIT_TYPE_C; 
                  v.state    := ERR_RESPONSE_S;
               -- Otherwise, move on
               else
                  v.state := COMMAND_TARGET_S;
               end if;
            end if;
         when COMMAND_TARGET_S => 

            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.wordsLeft := r.wordsLeft - 1;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_4; 
                  v.state    := ERR_RESPONSE_S;
               -- Target doesn't match this SCROD or broadcast
               elsif rxData /= wordScrodRevC and 
                     rxData /= x"00000000" then
                  v.errFlags := r.errFlags + ERR_BIT_DEST_C;
                  v.state    := ERR_RESPONSE_S;
               -- Otherwise, move on
               else
                  v.state := COMMAND_ID_S;
               end if;
            end if;
         when COMMAND_ID_S => 
				
            v.wordOutCnt  := (others => '0');
            v.timeoutCnt  := (others => '0');
            if rxDataValid = '1' then
               rxDataReady   <= '1';
               -- Checksum calculation starts here
               v.checksum   := rxData;
               v.wordsLeft  := r.wordsLeft - 1;
               v.commandId  := rxData(23 downto 0);
               v.noResponse := rxData(31);
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_5; 
                  v.state    := ERR_RESPONSE_S;
               -- Otherwise, move on
               else
                  v.state := COMMAND_TYPE_S;
               end if;
            end if;
         when COMMAND_TYPE_S => 
	
            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.checksum  := r.checksum + rxData;
               v.command   := rxData;
               v.wordsLeft := r.wordsLeft - 1;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_6; 
                  v.state    := ERR_RESPONSE_S;
               -- Move on for recognized commands
               elsif rxData = WORD_PING_C then
                  v.state := COMMAND_CHECKSUM_S;
               elsif rxData = WORD_READ_C or rxData = WORD_WRITE_C then
                  v.state := COMMAND_DATA_S;
               -- Unrecognized command, dump
               else
                  v.errFlags := r.errFlags + ERR_BIT_COMM_TY_C; 
                  v.state    := ERR_RESPONSE_S;
               end if;
            end if;
         when COMMAND_DATA_S => 
				
            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.checksum  := r.checksum + rxData;
               v.regAddr   := rxData(15 downto 0);
               v.regWrData := rxData(31 downto 16);
               v.wordsLeft := r.wordsLeft - 1;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_7; 
                  v.state    := ERR_RESPONSE_S;
               -- Move on for recognized commands
               else 
                  v.state := COMMAND_CHECKSUM_S;
               end if;
            end if;
         when COMMAND_CHECKSUM_S => 

            if rxDataValid = '1' then
               rxDataReady <= '1';
               v.wordsLeft := r.wordsLeft - 1;
               -- Possible errors:
               -- This is last, go back to IDLE
               if rxDataLast = '1' then
                  v.errFlags := r.errFlags + ERR_BIT_SIZE_C_8; 
                  v.state    := ERR_RESPONSE_S;
               -- Bad checksum
               elsif r.checksum /= rxData then
                  v.errFlags := r.errFlags + ERR_BIT_COMM_CS_C; 
                  v.state    := ERR_RESPONSE_S;
               -- Command accepted, move to execute state
               elsif r.command = WORD_PING_C then
                  v.state := PING_S;
               elsif r.command = WORD_WRITE_C then
                  v.state := WRITE_S;
               elsif r.command = WORD_READ_C then
                  v.state := READ_S;
               -- Unrecognized command
               else
                  v.errFlags := r.errFlags + ERR_BIT_COMM_TY_C; 
                  v.state    := ERR_RESPONSE_S;
               end if;
            end if;
         when PING_S =>
				
            if r.noResponse = '1' then
               v.state := CHECK_MORE_S;
            else
               v.checksum := (others => '0');
               v.state    := PING_RESPONSE_S;
            end if;            
         when READ_S => 
			
            v.regOp      := '0';
            v.regReq     := '1';
            v.timeoutCnt := r.timeoutCnt + 1;
            if (regAck = '1') then
               v.regRdData := regRdData;
               v.regReq    := '0';
               if r.noResponse = '1' then
                  v.state := CHECK_MORE_S;
               else
                  v.checksum := (others => '0');
                  v.state    := READ_RESPONSE_S;
               end if;
            elsif r.timeoutCnt = TIMEOUT_G then
               v.errFlags := r.errFlags + ERR_BIT_TIMEOUT_C;
               v.state    := ERR_RESPONSE_S;
            end if;
         when WRITE_S => 

            v.regOp      := '1';
            v.regReq     := '1';
            v.timeoutCnt := r.timeoutCnt + 1;
            if (regAck = '1') then
               v.regReq    := '0';
               if r.noResponse = '1' then
                  v.state := CHECK_MORE_S;
               else
                  v.checksum := (others => '0');
                  v.state    := WRITE_RESPONSE_S;
               end if;
            elsif r.timeoutCnt = TIMEOUT_G then
               v.errFlags := r.errFlags + ERR_BIT_TIMEOUT_C;
               v.state    := ERR_RESPONSE_S;
            end if;
         when READ_RESPONSE_S => 

            if regAck = '0' and r.regReq = '0' then
               v.txDataValid := '1';
               case conv_integer(r.wordOutCnt) is
                  when 0 => v.txData := WORD_HEADER_C;
                  when 1 => v.txData := x"00000006";
                  when 2 => v.txData := WORD_ACK_C;
                  when 3 => v.txData := wordScrodRevC;
                  when 4 => v.txData := x"00" & r.commandId;
                  when 5 => v.txData := WORD_READ_C;
                  when 6 => v.txData := r.regRdData & r.regAddr;
                  when 7 => v.txData     := r.checksum;
                            v.txDataLast := '1';
                            v.state      := CHECK_MORE_S;
                  when others => v.txData := (others => '1');
               end case;
               if txDataReady = '1' then
                  v.checksum   := r.checksum + v.txData;
                  v.wordOutCnt := r.wordOutCnt + 1;
               end if;
            end if;
         when WRITE_RESPONSE_S => 
				
            if regAck = '0' and r.regReq = '0' then
               v.txDataValid := '1';
               case conv_integer(r.wordOutCnt) is
                  when 0 => v.txData := WORD_HEADER_C;
                  when 1 => v.txData := x"00000006";
                  when 2 => v.txData := WORD_ACK_C;
                  when 3 => v.txData := wordScrodRevC;
                  when 4 => v.txData := x"00" & r.commandId;
                  when 5 => v.txData := WORD_WRITE_C;
                  when 6 => v.txData := r.regWrData & r.regAddr;
                  when 7 => v.txData     := v.checksum;
                            v.txDataLast := '1';
                            v.state      := CHECK_MORE_S;
                  when others => v.txData := (others => '1');
               end case;
               if txDataReady = '1' then
                  v.checksum   := r.checksum + v.txData;
                  v.wordOutCnt := r.wordOutCnt + 1;
               end if;
            end if;
         when PING_RESPONSE_S => 
			
            v.txDataValid := '1';
            case conv_integer(r.wordOutCnt) is
               when 0 => v.txData := WORD_HEADER_C;
               when 1 => v.txData := x"00000005";
               when 2 => v.txData := WORD_ACK_C;
               when 3 => v.txData := wordScrodRevC;
               when 4 => v.txData := x"00" & r.commandId;
               when 5 => v.txData := WORD_PING_C;
               when 6 => v.txData     := v.checksum;
                         v.txDataLast := '1';
                         v.state      := CHECK_MORE_S;
               when others => v.txData := (others => '1');
            end case;
            if txDataReady = '1' then
               v.checksum   := r.checksum + v.txData;
               v.wordOutCnt := r.wordOutCnt + 1;
            end if;
         when ERR_RESPONSE_S => 
            if txDataReady = '1' then
               v.checksum   := r.checksum + r.txData;
               v.wordOutCnt := r.wordOutCnt + 1;
            end if;
            v.txDataValid := '1';
            case conv_integer(r.wordOutCnt) is
               when 0 => v.txData := WORD_HEADER_C;
               when 1 => v.txData := x"00000005";
               when 2 => v.txData := WORD_ERR_C;
               when 3 => v.txData := wordScrodRevC;
               when 4 => v.txData := x"00" & r.commandId;
               when 5 => v.txData := r.errFlags;
               when 6 => v.txData     := r.checksum;
                         v.txDataLast := '1';
                         v.state      := DUMP_S;
               when others => v.txData := (others => '1');
            end case;
         when CHECK_MORE_S =>
            if r.wordsLeft /= 1 then
               v.state := COMMAND_ID_S;
            else
               v.state := PACKET_CHECKSUM_S;
            end if;
         when PACKET_CHECKSUM_S =>
            -- Not checking this for now...
            v.state := DUMP_S;
         when DUMP_S =>
            rxDataReady <= '1';
            if rxDataLast = '1' then
               v.state := IDLE_S;
            end if;
         when others =>
            v.state := IDLE_S;
      end case;

      -- Reset logic
      if (usrRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs to ports
      txData      <= r.txData;
      txDataValid <= r.txDataValid;
      txDataLast  <= r.txDataLast;
      -- Register interfaces
      regAddr     <= r.regAddr;
      regWrData   <= r.regWrData;
      regReq      <= r.regReq;
      regOp       <= r.regOp;
      
      -- Assignment of combinatorial variable to signal
      rin <= v;

   end process;

   seq : process (usrClk) is
   begin
      if (rising_edge(usrClk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;

end rtl;

