library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.tb_commandinterpreter_reader_pgk.all;
use work.tb_commandinterpreter_writer_pgk.all;

entity tb_CommandInterpreter is 
end entity;

architecture Behavioral of tb_CommandInterpreter is 

signal clk : std_logic  := '0'  ;
signal reader_data : tb_CommandInterpreter_reader_rec  := tb_CommandInterpreter_reader_rec_null  ;
signal writer_data : tb_CommandInterpreter_writer_rec  := tb_CommandInterpreter_writer_rec_null  ;
begin


clk_gen :entity  work.ClockGenerator
   generic map (
    CLOCK_period=> 10 ns) 
   port map( 
    clk => clk
   );



reader :entity  work.tb_CommandInterpreter_reader  
    generic map (
         FileName => "tb_CommandInterpreter.csv"
       ) 
       port map(
         clk => clk,
         data => reader_data
       );



writer :entity  work.tb_CommandInterpreter_writer 
    generic map (
         FileName => "tb_CommandInterpreter_out.csv"
       ) 
       port map(
         clk => clk,
         data => writer_data
       );

writer_data.myId <= reader_data.myId;
writer_data.regAck <= reader_data.regAck;
writer_data.regRdData <= reader_data.regRdData;
writer_data.rxData <= reader_data.rxData;
writer_data.rxDataLast <= reader_data.rxDataLast;
writer_data.rxDataValid <= reader_data.rxDataValid;
writer_data.txDataReady <= reader_data.txDataReady;
writer_data.usrRst <= reader_data.usrRst;

dut : entity work.CommandInterpreter port map (
  usrCLK => clk,
myId => writer_data.myId, 
 regAck => writer_data.regAck, 
 regAddr => writer_data.regAddr, 
 regOp => writer_data.regOp, 
 regRdData => writer_data.regRdData, 
 regReq => writer_data.regReq, 
 regWrData => writer_data.regWrData, 
 rxData => writer_data.rxData, 
 rxDataLast => writer_data.rxDataLast, 
 rxDataReady => writer_data.rxDataReady, 
 rxDataValid => writer_data.rxDataValid, 
 txData => writer_data.txData, 
 txDataLast => writer_data.txDataLast, 
 txDataReady => writer_data.txDataReady, 
 txDataValid => writer_data.txDataValid, 
 usrRst => writer_data.usrRst


);


end Behavioral;

