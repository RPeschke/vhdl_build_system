
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use work.CSV_UtilityPkg.all;  
  
  



package tb_CommandInterpreter_reader_pgk is

type tb_CommandInterpreter_reader_rec is record 
usrRst : sl; 
rxData : slv(31 downto 0); 
rxDataValid : sl; 
rxDataLast : sl; 
txDataReady : sl; 
myId : slv(15 downto 0); 
regRdData : slv(15 downto 0); 
regAck : sl; 

end record tb_CommandInterpreter_reader_rec; 

constant  tb_CommandInterpreter_reader_rec_null: tb_CommandInterpreter_reader_rec := (usrRst => sl_null,
rxData => (others => '0'),
rxDataValid => sl_null,
rxDataLast => sl_null,
txDataReady => sl_null,
myId => (others => '0'),
regRdData => (others => '0'),
regAck => sl_null);

end tb_CommandInterpreter_reader_pgk;


package body tb_CommandInterpreter_reader_pgk is
end package body tb_CommandInterpreter_reader_pgk;

