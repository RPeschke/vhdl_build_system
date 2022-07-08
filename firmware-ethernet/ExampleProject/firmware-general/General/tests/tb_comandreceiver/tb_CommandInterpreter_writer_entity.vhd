library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.csv_utilitypkg.all;
use work.tb_commandinterpreter_writer_pgk.all;
use work.type_conversions_pgk.all;

entity tb_CommandInterpreter_writer is 
generic (
FileName : string := ".\tb_commandreceiver.csv"
);
port (
clk : in std_logic ;
data : in tb_CommandInterpreter_writer_rec 
);
end entity;

architecture Behavioral of tb_CommandInterpreter_writer is 

constant  NUM_COL : integer := 15;
signal data_int : t_integer_array(NUM_COL downto 0)  := (others=>0)  ;
begin

csv_w : entity  work.csv_write_file 
    generic map (
         FileName => FileName,
         HeaderLines=> "usrRst;rxData;rxDataValid;rxDataLast;rxDataReady;txData;txDataValid;txDataLast;txDataReady;myId;regAddr;regWrData;regRdData;regReq;regOp;regAck",
         NUM_COL =>   NUM_COL ) 
    port map(
         clk => clk, 
         Rows => data_int
    );


sl_to_integer(data.usrRst, data_int(0) );
slv_to_integer(data.rxData, data_int(1) );
sl_to_integer(data.rxDataValid, data_int(2) );
sl_to_integer(data.rxDataLast, data_int(3) );
sl_to_integer(data.rxDataReady, data_int(4) );
slv_to_integer(data.txData, data_int(5) );
sl_to_integer(data.txDataValid, data_int(6) );
sl_to_integer(data.txDataLast, data_int(7) );
sl_to_integer(data.txDataReady, data_int(8) );
slv_to_integer(data.myId, data_int(9) );
slv_to_integer(data.regAddr, data_int(10) );
slv_to_integer(data.regWrData, data_int(11) );
slv_to_integer(data.regRdData, data_int(12) );
sl_to_integer(data.regReq, data_int(13) );
sl_to_integer(data.regOp, data_int(14) );
sl_to_integer(data.regAck, data_int(15) );
end Behavioral;

