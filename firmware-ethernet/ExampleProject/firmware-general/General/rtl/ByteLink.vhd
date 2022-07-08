---------------------------------------------------------------------------------
-- Title         : Byte Link
-- Project       : General Purpose Core
---------------------------------------------------------------------------------
-- File          : ByteLink.vhd
-- Author        : Kurtis Nishimura
---------------------------------------------------------------------------------
-- Description:
-- Basic 1-byte interface link, using 8b10b protocol
---------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;

entity ByteLink is 
   generic (
      ALIGN_CYCLES_G  : integer := 20;
      GATE_DELAY_G    : time := 1 ns
   );
   port ( 
      -- User clock and reset
      clk           : in  sl;
      rst           : in  sl := '0';
      -- Incoming encoded data
      rxData10b     : in  slv(9 downto 0);
      -- Received true data
      rxData8b      : out slv(7 downto 0);
      rxData8bValid : out sl;
      -- Align signal
      aligned       : out sl;
      -- Outgoing true data
      txData8b      : in  slv(7 downto 0);
      txData8bValid : in  sl;
      -- Transmitted encoded data
      txData10b     : out slv(9 downto 0)
   ); 
end ByteLink;

-- Define architecture
architecture rtl of ByteLink is

   type StateType is (RESET_S, TRAINING_S, LOCKED_S);
   
   type RegType is record
      state         : StateType;
      aligned       : sl;
      rxData10b     : slv(9 downto 0);
      rxData8b      : slv(7 downto 0);
      rxData8bValid : sl;
      txData8b      : slv(7 downto 0);
      txDataK       : sl;
      txData10b     : slv(9 downto 0);
      alignCnt      : slv(31 downto 0);
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state         => RESET_S,
      aligned       => '0',
      rxData10b     => (others => '0'),
      rxData8b      => (others => '0'),
      rxData8bValid => '0',
      txData8b      => (others => '0'),
      txDataK       => '0',
      txData10b     => (others => '0'),
      alignCnt      => (others => '0')
   );

   signal rxDataByte : slv(7 downto 0);
   signal rxDataK    : sl;
   signal rxDisp     : sl;
   signal rxCodeErr  : sl;
   signal rxDispErr  : sl;
   
   signal txData10   : slv(9 downto 0);
   signal txDisp     : sl;


   signal inputTxData8b      : slv(7 downto 0);
   signal inputTxData8bValid : sl;
   signal inputRxData10b     : slv(9 downto 0);
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- ISE attributes to keep signals for debugging
   -- attribute keep : string;
   -- attribute keep of r : signal is "true";    
   
   -- Vivado attributes to keep signals for debugging
   -- attribute dont_touch : string;
   -- attribute dont_touch of r : signal is "true";
   
   -- Comma character definitions
   constant K_COM_ALIGN_C : slv(7 downto 0) := x"3C"; --(K28.1)
   constant K_COM_ZERO_C : slv(7 downto 0) := x"BC"; -- (K28.5)
--   constant K28_7_C : slv(7 downto 0) := x"FC";
   constant K_CHAR : sl := '1';
   constant D_CHAR : sl := '0';
   
begin

   -- Register inputs
   process(clk) begin
      if rising_edge(clk) then
         inputRxData10b     <= rxData10b;
         inputTxData8b      <= txData8b;
         inputTxData8bValid <= txData8bValid;
      end if;
   end process;

   -- Instantiate 8b10b encoder and decoder
   U_Encode8b10b : entity work.Encode8b10b
      generic map (
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         clk     => clk,
         rst     => rst,
         dataIn  => r.txData8b,
         dataKIn => r.txDataK,
         dispIn  => txDisp,
         dataOut => txData10,
         dispOut => txDisp
      );
   U_Decode8b10b : entity work.Decode8b10b 
      generic map (
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         clk      => clk,
         rst      => rst,
         dataIn   => inputRxData10b,
         dispIn   => rxDisp,
         dataOut  => rxDataByte,
         dataKOut => rxDataK,
         dispOut  => rxDisp,
         codeErr  => rxCodeErr,
         dispErr  => rxDispErr
      );


   -- Master state machine (combinatorial)
   comb : process(rst,r,
                  rxDataByte,rxCodeErr,rxDispErr,rxDataK,
                  txData10,inputTxData8bValid,inputTxData8b) is
      variable v : RegType;
   begin
      v := r;

      -- Pipeline txData10b
      v.txData10b := txData10;

      -- Resets for pulsed outputs
      v.rxData8bValid := '0';
      
      -- State machine 
      case(r.state) is 
         when RESET_S =>
            v.alignCnt := (others => '0');
            v.txData8b := K_COM_ALIGN_C;
            v.txDataK  := K_CHAR;
            v.aligned  := '0';
            v.state    := TRAINING_S;
         when TRAINING_S => 
            v.txData8b := K_COM_ALIGN_C;
            v.txDataK  := K_CHAR;
            if rxDataK = '0' or (rxDataByte /= K_COM_ALIGN_C and rxDataByte /= K_COM_ZERO_C) or
               rxCodeErr = '1' or rxDispErr = '1' then
               v.alignCnt := (others => '0');
            else
               v.alignCnt := r.alignCnt + 1;
            end if;
            if r.alignCnt = ALIGN_CYCLES_G then
               v.alignCnt := (others => '0');
               v.state    := LOCKED_S;
            end if;
         when LOCKED_S =>
            v.aligned := '1';
            -- Start over if we see an undefined K_CHAR or code/disparity errors
            if (rxDataK = '1' and (rxDataByte /= K_COM_ALIGN_C and rxDataByte /= K_COM_ZERO_C)) or
               rxCodeErr = '1' or rxDispErr = '1' then
               v.state := RESET_S;
            end if;
            -- Otherwise, send data if we have it, or K_ZERO_C otherwise
            if inputTxData8bValid = '0' then
               v.txData8b := K_COM_ZERO_C;
               v.txDataK  := K_CHAR;
            else
               v.txData8b := inputTxData8b;
               v.txDataK  := D_CHAR;
            end if;
            -- Handle received data
            v.rxData8bValid := not(rxDataK);
            v.rxData8b      := rxDataByte;
         when others =>
            v.state := RESET_S;
      end case;

      -- Reset logic
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Assignment of combinatorial variable to signal
      rin <= v;

      -- Outputs to ports
      rxData8b      <= r.rxData8b;
      rxData8bValid <= r.rxData8bValid;
      aligned       <= r.aligned;
      txData10b     <= r.txData10b;

   end process;

   -- Master state machine (sequential)
   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;

end rtl;

