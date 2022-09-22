---------------------------------------------------------------------------------
-- Title         : Startup Reset
-- Project       : General Purpose Core
---------------------------------------------------------------------------------
-- File          : InitRst.vhd
-- Author        : Kurtis Nishimura
---------------------------------------------------------------------------------
-- Description:
-- Simple one-bit synchronizer.
---------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.UtilityPkg.all;

entity InitRst is 
   generic (
      SYNC_STAGES_G  : integer := 2;
      RST_POL_G      : sl := '1';
      RST_CNT_G      : integer := 125000000;
      GATE_DELAY_G   : time := 1 ns
   );
   port ( 
      -- Clock and reset
      clk      : in  sl;
      -- Incoming reset, asynchronous
      asyncRst : in sl := '0';
      -- Outgoing reset, synced to clk
      syncRst  : out sl
   ); 
end InitRst;

-- Define architecture
architecture rtl of InitRst is

   type StateType     is (IN_RESET_S, DONE_S);
   
   type RegType is record
      state       : StateType;
      count       : slv(31 downto 0);
      syncRst     : sl;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state       => IN_RESET_S,
      count       => (others => '0'),
      syncRst     => '0'
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
   
   signal internalRst : sl := '1';
   
begin

   U_RstSync : entity work.SyncBit
      generic map (
         RST_POL_G    => RST_POL_G,
         GATE_DELAY_G => GATE_DELAY_G
      )
      port map (
         clk      => clk,
         rst      => asyncRst,
         asyncBit => not(RST_POL_G),
         syncBit  => internalRst
      );

   comb : process(internalRst,r) is
      variable v : RegType;
   begin
      v := r;

      -- Resets for pulsed outputs
      
      -- State machine 
      case(r.state) is 
         when IN_RESET_S =>
            v.syncRst := RST_POL_G;
            v.count   := r.count + 1;
            if r.count = RST_CNT_G then
               v.state := DONE_S;
            end if;
         when DONE_S =>
            v.syncRst := not(RST_POL_G);
         when others =>
      end case;
      
      -- Reset logic
      if (internalRst = RST_POL_G) then
         v := REG_INIT_C;
      end if;

      -- Outputs to ports
      syncRst     <= r.syncRst;
      
      -- Assignment of combinatorial variable to signal
      rin <= v;

   end process;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after GATE_DELAY_G;
      end if;
   end process seq;

end rtl;

