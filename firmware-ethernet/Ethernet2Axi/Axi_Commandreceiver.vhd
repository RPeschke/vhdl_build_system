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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use work.UtilityPkg.all;
  use work.axiDWORDbi_p.all;
entity Axi_CommandInterpreter is 
  port ( 
    -- User clock and reset
    usrClk      : in  sl;
    -- Incoming data
    rxData      : in  DWORD;
    rxDataValid : in  sl;
    rxDataLast  : in  sl;
    rxDataReady : out sl;
    -- Outgoing response
    txData      : out DWORD;
    txDataValid : out sl;
    txDataLast  : out sl;
    txDataReady : in  sl
  ); 
end Axi_CommandInterpreter;

-- Define architecture
architecture rtl of Axi_CommandInterpreter is
  type StateType     is (IDLE_S,RECEIVING,SENDING);

  signal state : StateType := IDLE_S;
  
begin



  seq : process (usrClk) is
    variable RXTX : AxiRXTXMaster_axiDWordBi := AxiRXTXMaster_axiDWordBi_null;
	 variable Bufer1 : Word32Array(10 downto 0);  
    variable Index : integer :=0;
	 variable Max_Index : integer :=0;
	 variable b1 : DWORD := (others => '0');
  begin
    if (rising_edge(usrClk)) then
     
		AxiPullData(RXTX, txDataReady , rxData ,rxDataValid ,rxDataLast);
      
      if IsValid(RXTX.rx) and  state /= SENDING then 
		  --b1  :=b1+ rxGetData(RXTX);
		  Bufer1(Index) := rxGetData(RXTX);
        Index := Index + 1;
        state <= RECEIVING;
        if rxIsLast(RXTX) then 
          state <= SENDING;
			 Max_Index := index;
          Index := 0;
        end if;
      end if;
      

      
      if state = SENDING and txIsReady(RXTX) then 
			
        
		 -- txSetData(RXTX,b1);
		 b1:= Bufer1(Index);
		   txSetData(RXTX, b1);
        Index := Index + 1;
        if Index  = Max_Index then 
		    txSetLast(RXTX);

          state <= IDLE_S;
			 
			 Index := 0;
        end if;
        
      end if;
      
      
      
      if state/= SENDING then 
			rxSetReady(RXTX);        
      end if;
      
 
		AxiPushData(RXTX , rxDataReady, txData , txDataValid,txDataLast);
		
		--txData <=   b1;
    end if;
  end process seq;

end rtl;
