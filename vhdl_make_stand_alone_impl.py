import binascii
import socket


import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 

from  vhdl_build_system.vhdl_make_test_bench   import *
from  vhdl_build_system.vhdl_parser            import *



def make_stand_alone_impl(entityDef, suffix, ipAddr = '192.168.1.33', Port=2001, path="."):
  et_name = entityDef[0]["name"]
  et_name_top = et_name+"_top"
  stand_alone_file = path+"/"+et_name +"_" + suffix +"_top.vhd"

  ip = binascii.hexlify(socket.inet_aton(ipAddr)).upper()

  write_pgk = get_writer_pgk_name(entityDef)
  reader_pgk = get_reader_pgk_name(entityDef)


  ports = entityDef[0]["port"]
  ports = remove_clock_from_ports(ports)    
  dut = "DUT :  entity work." + et_name + " port map(\n  clk => fabClk"
  for x in ports:
    dut += ",\n  " + x["name"] +" => data_out." + x["name"] 
  dut += "\n);"

  data_out_converter = ""
  ports_ex = expand_types(ports)  
  index = 0
  for x in ports_ex:
    data_out_converter += get_shortend_typename(x) + '_to_slv(data_out.' + x["name"] + ', i_data_out(' +str(index) +') );\n'
    index+=1 

  ports = entityDef[0]["port"]
  ports = [x for x in ports if x["InOut"] == "in"]
  ports = remove_clock_from_ports(ports)
  ports_ex = expand_types(ports)

  data_in_converter = ""
  ports_ex = expand_types(ports)  
  index = 0
  for x in ports_ex:
    data_in_converter += "slv_to_" + get_shortend_typename(x) + '(i_data(' +str(index) +'), data_in.' + x["name"] + ');\n'
    index+=1 


  connect_input_output =""
  ports = entityDef[0]["port"]
  ports = [x for x in ports if x["InOut"] == "in"]
  ports = remove_clock_from_ports(ports)

  for x in ports:
    connect_input_output += 'data_out.' + x['name'] + " <= data_in." + x['name'] +";\n"

  body = """
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library UNISIM;
  use UNISIM.VComponents.all;

  use work.UtilityPkg.all;
  use work.Eth1000BaseXPkg.all;
  use work.GigabitEthPkg.all;

  use work.{write_pgk}.all;
  use work.{reader_pgk}.all;
  use work.type_conversions_pgk.all;
  
  
entity {EntityName} is
  port (
    -- Direct GT connections
    gtTxP        : out sl;
    gtTxN        : out sl;
    gtRxP        :  in sl;
    gtRxN        :  in sl;
    gtClkP       :  in sl;
    gtClkN       :  in sl;
    -- Alternative clock input
    fabClkP      :  in sl;
    fabClkN      :  in sl;
    -- SFP transceiver disable pin
    txDisable    : out sl
  );
end entity;

architecture rtl of {EntityName} is
  
  signal fabClk       : sl := '0';
  -- User Data interfaces
  signal  TxDataChannels :  DWORD := (others => '0');
  signal  TxDataValids   :  sl := '0';
  signal  TxDataLasts    :  sl := '0';
  signal  TxDataReadys   :  sl := '0';
  signal  RxDataChannels :  DWORD := (others => '0');
  signal  RxDataValids   :  sl := '0';
  signal  RxDataLasts    :  sl := '0';
  signal  RxDataReadys   :  sl := '0';
  
   constant COLNum : integer := {inputChannels};
   signal i_data :  Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
   signal i_valid      : sl := '0';
   
   constant COLNum_out : integer := {outputChannel};
   signal i_data_out :  Word32Array(COLNum_out -1 downto 0) := (others => (others => '0'));
   

   signal data_in  : {reader_record} := {reader_record}_null;
   signal data_out : {writer_record} := {writer_record}_null;
begin
  
  U_IBUFGDS : IBUFGDS port map ( I => fabClkP, IB => fabClkN, O => fabClk);

  e2a : entity work.ethernet2axistream port map(
    clk => fabClk,
    
    -- Direct GT connections
    gtTxP        => gtTxP,
    gtTxN        => gtTxN,
    gtRxP        => gtRxP,
    gtRxN        => gtRxN,
    gtClkP       => gtClkP, 
    gtClkN       => gtClkN,
    
    

    -- SFP transceiver disable pin
    txDisable    => txDisable,
    -- axi stream output

    -- User Data interfaces
    TxDataChannels => TxDataChannels,
    TxDataValids   => TxDataValids,
    TxDataLasts    => TxDataLasts,
    TxDataReadys   => TxDataReadys,
    RxDataChannels => RxDataChannels,
    RxDataValids   => RxDataValids,
    RxDataLasts    => RxDataLasts,
    RxDataReadys   => RxDataReadys,

    EthernetIpAddr  => (3 => x"{ip3}", 2 => x"{ip2}", 1 => x"{ip1}", 0 => x"{ip0}"),
    udpPort        =>    x"07d1"  --  x"{Port}" 
    
  );
  
  
  u_reader : entity work.Imp_test_bench_reader 
    generic map (
      COLNum => COLNum 
    ) port map (
      Clk       => fabClk,
      -- Incoming data
      rxData      => RxDataChannels,
      rxDataValid => RxDataValids,
      rxDataLast  => RxDataLasts,
      rxDataReady => RxDataReadys,
      data_out    => i_data,
      valid => i_valid
    );

  u_writer : entity work.Imp_test_bench_writer 
    generic map (
      COLNum => COLNum_out 
    ) port map (
      Clk      => fabClk,
      -- Incoming data
      tXData      =>  TxDataChannels,
      txDataValid =>  TxDataValids,
      txDataLast  =>  TxDataLasts,
      txDataReady =>  TxDataReadys,
      data_in    => i_data_out,
      Valid      => i_valid
    );



-- <DUT>
    {DUT}
-- </DUT>

--  <data_out_converter>

{data_out_converter}
--  </data_out_converter>

-- <data_in_converter> 

{data_in_converter}
--</data_in_converter>

-- <connect_input_output>

{connect_input_output}
-- </connect_input_output>


end architecture;
""".format(
    EntityName=et_name_top,
    inputChannels=11,
    outputChannel=13,
    ip3 = ip[0:2].decode("utf-8"),
    ip2 = ip[2:4].decode("utf-8"),
    ip1 = ip[4:6].decode("utf-8"),
    ip0 = ip[6:8].decode("utf-8"),
    Port = hex(Port),
    write_pgk = write_pgk,
    reader_pgk = reader_pgk,
    reader_record = get_reader_record_name(entityDef),
    writer_record = get_writer_record_name(entityDef),
    DUT = dut,
    data_out_converter = data_out_converter,
    data_in_converter = data_in_converter,
    connect_input_output = connect_input_output
)
  with open(stand_alone_file,"w",newline="\n") as f:
    f.write(body)



