
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use work.CSV_UtilityPkg.all;  
  
  



package tb_CommandInterpreter_writer_pgk is

type tb_CommandInterpreter_writer_rec is record 
usrRst : sl; 
rxData : slv(31 downto 0); 
rxDataValid : sl; 
rxDataLast : sl; 
rxDataReady : sl; 
txData : slv(31 downto 0); 
txDataValid : sl; 
txDataLast : sl; 
txDataReady : sl; 
myId : slv(15 downto 0); 
regAddr : slv(15 downto 0); 
regWrData : slv(15 downto 0); 
regRdData : slv(15 downto 0); 
regReq : sl; 
regOp : sl; 
regAck : sl; 

end record tb_CommandInterpreter_writer_rec; 

constant  tb_CommandInterpreter_writer_rec_null: tb_CommandInterpreter_writer_rec := (usrRst => sl_null,
rxData => (others => '0'),
rxDataValid => sl_null,
rxDataLast => sl_null,
rxDataReady => sl_null,
txData => (others => '0'),
txDataValid => sl_null,
txDataLast => sl_null,
txDataReady => sl_null,
myId => (others => '0'),
regAddr => (others => '0'),
regWrData => (others => '0'),
regRdData => (others => '0'),
regReq => sl_null,
regOp => sl_null,
regAck => sl_null);

end tb_CommandInterpreter_writer_pgk;


package body tb_CommandInterpreter_writer_pgk is
end package body tb_CommandInterpreter_writer_pgk;

