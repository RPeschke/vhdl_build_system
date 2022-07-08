library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;
library UNISIM;
use UNISIM.VComponents.all;

entity K7SerialInterfaceOut is
   Generic (
      GATE_DELAY_G : time := 1 ns
   );
   Port (
      -- Parallel clock and reset
      sstClk    : in  sl;
      sstRst    : in  sl := '0';
      -- Parallel data in
      data10bIn : in  slv(9 downto 0);
      -- Serial clock
      sstX5Clk  : in  sl;
      sstX5Rst  : in  sl := '0';
      -- Serial data out
      dataOut   : out sl
   );
end K7SerialInterfaceOut;

architecture Behavioral of K7SerialInterfaceOut is

   type StateType is (RESET_S, SEND_AND_READ_S);
   
   type RegType is record
      state                : StateType;
      dataWord             : slv(9 downto 0);
      bitCount             : slv(3 downto 0);
      serialDataOutRising  : sl;
      serialDataOutFalling : sl;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state                => RESET_S,
      dataWord             => (others => '0'),
      bitCount             => (others => '0'),
      serialDataOutRising  => '0',
      serialDataOutFalling => '0'
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal fifoEmpty   : sl;
   signal fifoRdData  : slv(9 downto 0);
   signal fifoRdValid : sl;

begin

   -- Instantiate 10 bit FIFO, written on sstClk, read on sstX5Clk
   U_SerializationFifo : entity work.SerializationFifo
      PORT MAP (
         rst    => sstRst,
         wr_clk => sstClk,
         rd_clk => sstX5Clk,
         din    => data10bIn,
         wr_en  => '1',
         rd_en  => not(fifoEmpty),
         dout   => fifoRdData,
         full   => open,
         empty  => fifoEmpty,
         valid  => fifoRdValid
      );   
   
   -- Master state machine (combinatorial)   
   comb : process(r, fifoRdValid, fifoRdData, sstX5Rst) is
      variable v : RegType;
   begin
      v := r;

      -- Resets for pulsed outputs
      -- None for now
      
      -- State machine 
      case(r.state) is 
         when RESET_S =>
            v.bitCount := (others => '0');
            if (fifoRdValid = '1') then
               v.dataWord := fifoRdData;
               v.state    := SEND_AND_READ_S;
            end if;
         when SEND_AND_READ_S => 
            v.serialDataOutRising  := r.dataWord(r.dataWord'left - conv_integer(r.bitCount));
            v.serialDataOutFalling := r.dataWord(r.dataWord'left - conv_integer(r.bitCount)-1);
            if (r.bitCount = 8) then
               v.bitCount := (others => '0');
               v.dataWord := fifoRdData;
            else
               v.bitCount := r.bitCount + 2;
            end if;
         when others =>
            v.state := RESET_S;
      end case;

      -- Reset logic
      if (sstX5Rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Assignment of combinatorial variable to signal
      rin <= v;

   end process;

   -- Master state machine (sequential)
   seq : process (sstX5Clk) is
   begin
      if (rising_edge(sstX5Clk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;

   -- ODDR to grab the serial data
   -- Template here: http://www.xilinx.com/support/documentation/sw_manuals/xilinx14_7/7series_hdl.pdf
   -- Documentation here: http://www.xilinx.com/support/documentation/user_guides/ug471_7Series_SelectIO.pdf
	gclk_to_output : ODDR 
      generic map(
         DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
         INIT         => '0',             -- Initial value for Q port ('1' or '0')
         SRTYPE       => "ASYNC"          -- Reset Type ("ASYNC" or "SYNC")
      )
      port map (
         Q  => dataOut,                -- 1-bit DDR output
         C  => sstX5Clk,               -- 1-bit clock input
         CE => '1',                    -- 1-bit clock enable input
         D1 => r.serialDataOutRising,  -- 1-bit data input (positive edge)
         D2 => r.serialDataOutFalling, -- 1-bit data input (negative edge)
         R  => '0',                    -- 1-bit reset input
         S  => '0'                     -- 1-bit set input
      );   

end Behavioral;

