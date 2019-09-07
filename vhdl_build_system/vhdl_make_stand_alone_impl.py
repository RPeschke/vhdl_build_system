import binascii
import socket


import os,sys,inspect
currentdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
parentdir = os.path.dirname(currentdir)
sys.path.insert(0,parentdir) 


print("vhdl_make_stand_alone_impl", currentdir)
from  vhdl_build_system.vhdl_make_test_bench   import *
from  vhdl_build_system.vhdl_parser            import *
from  vhdl_build_system.vhdl_make_test_bench_names                 import *




def make_stand_alone_impl(entityDef, suffix, ipAddr = '192.168.1.33', Port=2001, path="."):
  et_name = entityDef.name()
  et_name_top = et_name+"_top"
  stand_alone_file = path+"/"+et_name +"_" + suffix +"_top.vhd"

  ip = binascii.hexlify(socket.inet_aton(ipAddr)).upper()

  write_pgk = get_writer_pgk_name(entityDef)
  reader_pgk = get_reader_pgk_name(entityDef)


  ports = entityDef.ports(RemoveClock=True)
     
  dut = "DUT :  entity work." + et_name + " port map(\n  clk => ethClk62"
  for x in ports:
    dut += ",\n  " + x["name"] +" => data_out." + x["name"] 
  dut += "\n);"

  data_out_converter = ""
  ports_ex = entityDef.ports(RemoveClock=True, ExpandTypes=True)
  index = 0
  for x in ports_ex:
    data_out_converter += x["type_shorthand"] + '_to_slv(data_out.' + x["name"] + ', i_data_out(' +str(index) +') );\n'
    index+=1 

  ports_ex = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock=True, ExpandTypes=True)

  data_in_converter = ""
  index = 0
  for x in ports_ex:
    data_in_converter += "slv_to_" + x["type_shorthand"] + '(i_data(' +str(index) +'), data_in.' + x["name"] + ');\n'
    index+=1 


  ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock=True)

  connect_input_output =""
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
  use work.Imp_test_bench_pgk.all;
  
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
  
  constant Throttel_max_counter : integer  := 10;
  constant Throttel_wait_time : integer := 100000;

  signal fabClk       : sl := '0';
  -- User Data interfaces

  signal  TxDataChannels1 :  DWORD := (others => '0');
  signal  TxDataValids1   :  sl := '0';
  signal  TxDataLasts1    :  sl := '0';
  signal  TxDataReadys1   :  sl := '0';

  signal  TxDataChannels :  DWORD := (others => '0');
  signal  TxDataValids   :  sl := '0';
  signal  TxDataLasts    :  sl := '0';
  signal  TxDataReadys   :  sl := '0';
  signal  RxDataChannels :  DWORD := (others => '0');
  signal  RxDataValids   :  sl := '0';
  signal  RxDataLasts    :  sl := '0';
  signal  RxDataReadys   :  sl := '0';
  constant FIFO_DEPTH : integer := {FIFO_DEPTH};
  constant COLNum : integer := {inputChannels};
  signal i_data :  Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
  signal i_controls_out    : Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
  signal i_valid      : sl := '0';
   
  constant COLNum_out : integer := {outputChannel};
  signal i_data_out :  Word32Array(COLNum_out -1 downto 0) := (others => (others => '0'));
   

  signal data_in  : {reader_record} := {reader_record}_null;
  signal data_out : {writer_record} := {writer_record}_null;
  
  signal test_data   : slv(31  downto 0);
  constant NUM_IP_G        : integer := 2;
     

  
  --signal ethClk125    : sl;
  signal ethClk62    : sl;
     
  signal ethCoreMacAddr : MacAddrType := MAC_ADDR_DEFAULT_C;
     
  signal userRst     : sl;
  signal ethCoreIpAddr  : IpAddrType  := IP_ADDR_DEFAULT_C;
  constant ethCoreIpAddr1 : IpAddrType  := (3 => x"{ip3}", 2 => x"{ip2}", 1 => x"{ip1}", 0 => x"{ip0}");
  constant udpPort        :  slv(15 downto 0):=  x"07D1" ;  -- {Port}
  signal tpData      : slv(31 downto 0);
  signal tpDataValid : sl;
  signal tpDataLast  : sl;
  signal tpDataReady : sl;
     
  -- Test registers
  -- Default is to send 1000 counter words once per second.
  signal waitCyclesHigh : slv(15 downto 0) := x"0773";
  signal waitCyclesLow  : slv(15 downto 0) := x"5940";
  signal numWords       : slv(15 downto 0) := x"02E9";
     
     
  -- User Data interfaces
  signal userTxDataChannels : Word32Array(NUM_IP_G-1 downto 0);
  signal userTxDataValids   : slv(NUM_IP_G-1 downto 0);
  signal userTxDataLasts    : slv(NUM_IP_G-1 downto 0);
  signal userTxDataReadys   : slv(NUM_IP_G-1 downto 0);
  signal userRxDataChannels : Word32Array(NUM_IP_G-1 downto 0);
  signal userRxDataValids   : slv(NUM_IP_G-1 downto 0);
  signal userRxDataLasts    : slv(NUM_IP_G-1 downto 0);
  signal userRxDataReadys   : slv(NUM_IP_G-1 downto 0);
    
begin
  
  U_IBUFGDS : IBUFGDS port map ( I => fabClkP, IB => fabClkN, O => fabClk);

  --------------------------------
  -- Gigabit Ethernet Interface --
  --------------------------------
  U_S6EthTop : entity work.S6EthTop
    generic map (
      NUM_IP_G     => NUM_IP_G
    )
    port map (
      -- Direct GT connections
      gtTxP           => gtTxP,
      gtTxN           => gtTxN,
      gtRxP           => gtRxP,
      gtRxN           => gtRxN,
      gtClkP          => gtClkP,
      gtClkN          => gtClkN,
      -- Alternative clock input from fabric
      fabClkIn        => fabClk,
      -- SFP transceiver disable pin
      txDisable       => txDisable,
      -- Clocks out from Ethernet core
      ethUsrClk62     => ethClk62,
      ethUsrClk125    => open,
      -- Status and diagnostics out
      ethSync         => open,
      ethReady        => open,
      led             => open,
      -- Core settings in 
      macAddr         => ethCoreMacAddr,
      ipAddrs         => (0 => ethCoreIpAddr, 1 => ethCoreIpAddr1),
      udpPorts        => (0 => x"07D0",       1 => udpPort), --x7D0 = 2000,
      -- User clock inputs
      userClk         => ethClk62,
      userRstIn       => '0',
      userRstOut      => userRst,
      -- User data interfaces
      userTxData      => userTxDataChannels,
      userTxDataValid => userTxDataValids,
      userTxDataLast  => userTxDataLasts,
      userTxDataReady => userTxDataReadys,
      userRxData      => userRxDataChannels,
      userRxDataValid => userRxDataValids,
      userRxDataLast  => userRxDataLasts,
      userRxDataReady => userRxDataReadys
    );
  
  userTxDataChannels(0) <= tpData;
  userTxDataValids(0)   <= tpDataValid;
  userTxDataLasts(0)    <= tpDataLast;
  tpDataReady           <= userTxDataReadys(0);
  -- Note that the Channel 0 RX channels are unused here
  --userRxDataChannels;
  --userRxDataValids;
  --userRxDataLasts;
  userRxDataReadys(0) <= '1';
  
  
  U_TpGenTx : entity work.TpGenTx
    port map (
      -- User clock and reset
      userClk         => ethClk62,
      userRst         => userRst,
      -- Configuration
      waitCycles      => waitCyclesHigh & waitCyclesLow,
      numWords        => x"0000" & numWords,
      -- Connection to user logic
      userTxData      => tpData,
      userTxDataValid => tpDataValid,
      userTxDataLast  => tpDataLast,
      userTxDataReady => tpDataReady
    );
  
  userTxDataChannels(1) <=  TxDataChannels ;
  userTxDataValids(1)   <=  TxDataValids;
  userTxDataLasts(1)    <=  TxDataLasts;
  TxDataReadys          <=  userTxDataReadys(1);
  
  RxDataChannels        <=  userRxDataChannels(1);
  RxDataValids          <=  userRxDataValids(1);
  RxDataLasts           <=  userRxDataLasts(1);
  userRxDataReadys(1)   <=  RxDataReadys;          
  
  
  
  u_reader : entity work.Imp_test_bench_reader
    generic map (
      COLNum => COLNum ,
      FIFO_DEPTH => FIFO_DEPTH
    ) port map (
      Clk       => ethClk62,
      -- Incoming data
      rxData      => RxDataChannels,
      rxDataValid => RxDataValids,
      rxDataLast  => RxDataLasts,
      rxDataReady => RxDataReadys,
      data_out    => i_data,
      valid => i_valid,
      controls_out => i_controls_out
    );

  u_writer : entity work.Imp_test_bench_writer 
    generic map (
      COLNum => COLNum_out,
      FIFO_DEPTH => FIFO_DEPTH
    ) port map (
      Clk      => ethClk62,
      -- Incoming data
      tXData      =>  TxDataChannels1,
      txDataValid =>  TxDataValids1,
      txDataLast  =>  TxDataLasts1,
      txDataReady =>  TxDataReadys1,
      data_in    => i_data_out,
      controls_in => i_controls_out,
      Valid      => i_valid
    );
throttel : entity work.axiStreamThrottle 
    generic map (
        max_counter => Throttel_max_counter,
        wait_time   => Throttel_wait_time
    ) port map (
        clk           => ethClk62,

        rxData         =>  TxDataChannels1,
        rxDataValid    =>  TxDataValids1,
        rxDataLast     =>  TxDataLasts1,
        rxDataReady    =>  TxDataReadys1,

        tXData          => TxDataChannels,
        txDataValid     => TxDataValids,
        txDataLast      => TxDataLasts,
        txDataReady    =>  TxDataReadys
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
    connect_input_output = connect_input_output,
    FIFO_DEPTH = 10
)
  with open(stand_alone_file,"w",newline="\n") as f:
    f.write(body)



