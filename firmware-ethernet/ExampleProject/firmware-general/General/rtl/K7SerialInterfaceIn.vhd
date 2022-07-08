library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;
library UNISIM;
use UNISIM.VComponents.all;

entity K7SerialInterfaceIn is
   Generic (
      GATE_DELAY_G   : time    := 1 ns;
      BITSLIP_WAIT_G : integer := 25*8
   );
   Port ( 
      -- Parallel clock and reset
      sstClk    : in  sl;
      sstRst    : in  sl := '0';
      -- Aligned indicator
      aligned   : in  sl;
      -- Parallel data out
      dataOut   : out slv(9 downto 0);
      -- Serial clock in
      sstX5Clk  : in  sl;
      sstX5Rst  : in  sl := '0';
      -- Serial data in
      dataIn    : in  sl
   );
end K7SerialInterfaceIn;

architecture Behavioral of K7SerialInterfaceIn is

   type StateType is (RESET_S, READ_WORD_S, BITSLIP_S);
   
   type RegType is record
      state     : StateType;
      dataWord  : slv(9 downto 0);
      dataWrite : sl;
      bitCount  : slv(3 downto 0);
      slipCount : slv(15 downto 0);
      flip      : sl;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state     => RESET_S,
      dataWord  => (others => '0'),
      dataWrite => '0',
      bitCount  => (others => '0'),
      slipCount => (others => '0'),
      flip      => '0'
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal serialDataInRising  : sl;
   signal serialDataInFalling : sl;

   signal risingWord      : slv(4 downto 0);
   signal fallingWord     : slv(4 downto 0);
   signal dataWord        : slv(9 downto 0);
   signal dataWordFlipped : slv(9 downto 0);

   signal fifoEmpty : sl;
   signal fifoFull  : sl;

begin

   -- IDDR to grab the serial data
   -- Template here: http://www.xilinx.com/support/documentation/sw_manuals/xilinx14_7/7series_hdl.pdf
   -- Documentation here: http://www.xilinx.com/support/documentation/user_guides/ug471_7Series_SelectIO.pdf
   IDDR_inst : IDDR
      generic map(
         DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", 
                                                -- "SAME_EDGE"
                                                -- or "SAME_EDGE_PIPELINED"
         INIT_Q1 => '0',  -- Initial value of Q1: '0' or '1'
         INIT_Q2 => '0',  -- Initial value of Q2: '0' or '1'
         SRTYPE => "SYNC" -- Set/Reset type: "SYNC" or "ASYNC"
      )
      port map (
         Q1 => serialDataInRising,  -- 1-bit output for positive edge of clock
         Q2 => serialDataInFalling, -- 1-bit output for negative edge of clock
         C  => sstX5Clk,            -- 1-bit clock input
         CE => '1',                 -- 1-bit clock enable input
         D  => dataIn,              -- 1-bit DDR data input
         R  => '0',                 -- 1-bit reset
         S  => '0'                  -- 1-bit set
      );

   -- Shift register for the rising and falling words
   process(sstX5Clk) begin
      if rising_edge(sstX5Clk) then
         if sstX5Rst = '1' then
            risingWord <= (others => '0');
            fallingWord <= (others => '0');
         else
            risingWord(0)  <= serialDataInRising;
            fallingWord(0) <= serialDataInFalling;
            for i in 1 to risingWord'left loop
               risingWord(i)  <= risingWord(i-1);
               fallingWord(i) <= fallingWord(i-1);
            end loop;
         end if;
      end if;
   end process;
   -- Create data word and flipped data word
   process(sstX5Clk) begin
      if rising_edge(sstX5Clk) then
         for i in 0 to risingWord'left loop
            dataWord(i*2)          <= risingWord(i);
            dataWord(i*2+1)        <= fallingWord(i);
            dataWordFlipped(i*2)   <= fallingWord(i);
            dataWordFlipped(i*2+1) <= risingWord(i);
         end loop;
      end if;
   end process;

   -- State machine to grab 10 bits and write them into a FIFO
   -- Master state machine (combinatorial)   
   comb : process(r, serialDataInRising, serialDataInFalling,
                  aligned, dataWord,dataWordFlipped, sstX5Rst) is
      variable v : RegType;
   begin
      v := r;

      -- Resets for pulsed outputs
      v.dataWrite := '0';
      
      -- State machine 
      case(r.state) is 
         when RESET_S =>
            v.bitCount := (others => '0');
            v.flip     := '0';
            v.state    := READ_WORD_S;
         when READ_WORD_S =>
            v.bitCount := r.bitCount + 2;
--            if r.flip = '0' then
--               v.dataWord(conv_integer(r.bitCount))   := serialDataInRising;
--               v.dataWord(conv_integer(r.bitCount+1)) := serialDataInFalling;
--            else
--               v.dataWord(conv_integer(r.bitCount+1)) := serialDataInRising;
--               v.dataWord(conv_integer(r.bitCount))   := serialDataInFalling;
--            end if;
            if r.bitCount = 8 then
               v.bitCount  := (others => '0');
               v.dataWrite := '1';
               if r.flip = '0' then
                  v.dataWord := dataWord;
               else
                  v.dataWord := dataWordFlipped;
               end if;
               if aligned = '0' then
                  if r.slipCount < BITSLIP_WAIT_G then
                     v.slipCount := r.slipCount + 1;
                  else
                     v.slipCount := (others => '0');
                     if r.flip = '0' then
                        v.flip := '1';
                     else
                        v.flip      := '0';
                        v.state := BITSLIP_S;
                     end if;
                  end if;
               end if;
            end if;
         when BITSLIP_S =>
            v.bitCount := (others => '0');
            v.state    := READ_WORD_S;
         when others =>
            v.state    := RESET_S;
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
   
   
   -- Read FIFO out to the top level
   U_SerializationFifo : entity work.SerializationFifo
      PORT MAP (
         rst    => sstRst,
         wr_clk => sstX5Clk,
         rd_clk => sstClk,
         din    => r.dataWord,
         wr_en  => r.dataWrite,
         rd_en  => not(fifoEmpty),
         dout   => dataOut,
         full   => fifoFull,
         empty  => fifoEmpty,
         valid  => open
      );   

end Behavioral;

