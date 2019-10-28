import binascii
import socket


import os,sys,inspect




from  .vhdl_make_test_bench   import *
from  .vhdl_parser            import *
from  .vhdl_make_test_bench_names                 import *

def make_stand_alone_entity_get_DUT(entityDef):
  ports = entityDef.ports(RemoveClock=True)
  et_name = entityDef.name()
  dut = "DUT :  entity work." + et_name + " port map(\n  clk => clk"
  for x in ports:
    dut += ",\n  " + x["name"] +" => data_out." + x["name"] 
  dut += "\n);"
  return dut

def make_stand_alone_entity_get_data_out_converter(entityDef):
  data_out_converter = ""
  ports_ex_all = entityDef.ports(RemoveClock=True, ExpandTypes=True)
  index = 0
  for x in ports_ex_all:
    data_out_converter += x["type_shorthand"] + '_to_slv(data_out.' + x["name"] + ', i_data_out(' +str(index) +') );\n'
    index+=1 
  return  data_out_converter, len(ports_ex_all)

def make_stand_alone_entity_get_connect_input_output(entityDef):
  ports = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock=True)

  connect_input_output =""
  for x in ports:
    connect_input_output += 'data_out.' + x['name'] + " <= data_in." + x['name'] +";\n"
  return connect_input_output

def make_stand_alone_entity_get_data_in_converter(entityDef):
  ports_ex_input = entityDef.ports(Filter= lambda a : a["InOut"] == "in", RemoveClock=True, ExpandTypes=True)

  data_in_converter = ""
  index = 0
  for x in ports_ex_input:
    data_in_converter += "slv_to_" + x["type_shorthand"] + '(i_data(' +str(index) +'), data_in.' + x["name"] + ');\n'
    index+=1 

  return data_in_converter, len(ports_ex_input)


def make_stand_alone_entity(entityDef , suffix,path):
  et_name = entityDef.name()
  et_name_eth = et_name+"_eth"  

  stand_alone_file = path+"/"+et_name +"_" + suffix +"_eth.vhd"

  
  ports = entityDef.ports(RemoveClock=True)
 
  dut =make_stand_alone_entity_get_DUT(entityDef)

  data_out_converter,ports_ex_output_len =make_stand_alone_entity_get_data_out_converter(entityDef)
  
  data_in_converter,ports_ex_input_len = make_stand_alone_entity_get_data_in_converter(entityDef)

  connect_input_output = make_stand_alone_entity_get_connect_input_output(entityDef)


  body = """

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library UNISIM;
  use UNISIM.VComponents.all;
  use work.UtilityPkg.all;

  use work.{write_pgk}.all;
  use work.{reader_pgk}.all;
  use work.type_conversions_pgk.all;
  use work.Imp_test_bench_pgk.all;
  
entity {EntityName} is
  port (
    clk : in std_logic;
    TxDataChannel : out  DWORD := (others => '0');
    TxDataValid   : out  sl := '0';
    TxDataLast    : out  sl := '0';
    TxDataReady   : in   sl := '0';
    RxDataChannel : in   DWORD := (others => '0');
    RxDataValid   : in   sl := '0';
    RxDataLast    : in   sl := '0';
    RxDataReady   : out  sl := '0'
  );
end entity;

architecture rtl of {EntityName} is
  
  constant Throttel_max_counter : integer  := 10;
  constant Throttel_wait_time : integer := 100000;

  -- User Data interfaces



  signal  i_TxDataChannels :  DWORD := (others => '0');
  signal  i_TxDataValids   :  sl := '0';
  signal  i_TxDataLasts    :  sl := '0';
  signal  i_TxDataReadys   :  sl := '0';

  constant FIFO_DEPTH : integer := {FIFO_DEPTH};
  constant COLNum : integer := {inputChannels};
  signal i_data :  Word32Array(COLNum -1 downto 0) := (others => (others => '0'));
  signal i_controls_out    : Imp_test_bench_reader_Control_t  := Imp_test_bench_reader_Control_t_null;
  signal i_valid      : sl := '0';
   
  constant COLNum_out : integer := {outputChannel};
  signal i_data_out :  Word32Array(COLNum_out -1 downto 0) := (others => (others => '0'));
   

  signal data_in  : {reader_record} := {reader_record}_null;
  signal data_out : {writer_record} := {writer_record}_null;
  
begin
  
  
  
  u_reader : entity work.Imp_test_bench_reader
    generic map (
      COLNum => COLNum ,
      FIFO_DEPTH => FIFO_DEPTH
    ) port map (
      Clk          => clk,
      -- Incoming data
      rxData       => RxDataChannel,
      rxDataValid  => RxDataValid,
      rxDataLast   => RxDataLast,
      rxDataReady  => RxDataReady,
      -- outgoing data
      data_out     => i_data,
      valid        => i_valid,
      controls_out => i_controls_out
    );

  u_writer : entity work.Imp_test_bench_writer 
    generic map (
      COLNum => COLNum_out,
      FIFO_DEPTH => FIFO_DEPTH
    ) port map (
      Clk      => clk,
      -- Outgoing  data
      tXData      =>  i_TxDataChannels,
      txDataValid =>  i_TxDataValids,
      txDataLast  =>  i_TxDataLasts,
      txDataReady =>  i_TxDataReadys,
      -- incomming data 
      data_in    => i_data_out,
      controls_in => i_controls_out,
      Valid      => i_valid
    );
throttel : entity work.axiStreamThrottle 
    generic map (
        max_counter => Throttel_max_counter,
        wait_time   => Throttel_wait_time
    ) port map (
        clk           => clk,

        rxData         =>  i_TxDataChannels,
        rxDataValid    =>  i_TxDataValids,
        rxDataLast     =>  i_TxDataLasts,
        rxDataReady    =>  i_TxDataReadys,

        tXData          => TxDataChannel,
        txDataValid     => TxDataValid,
        txDataLast      => TxDataLast,
        txDataReady     =>  TxDataReady
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
    EntityName    = et_name_eth,
    inputChannels = ports_ex_input_len,
    outputChannel = ports_ex_output_len,
 
    write_pgk = get_writer_pgk_name(entityDef),
    reader_pgk =  get_reader_pgk_name(entityDef),
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
  return et_name_eth





def make_stand_alone_impl(entityDef, suffix, ipAddr = '192.168.1.33', Port=2001, path="."):
  
  eth_et_name = make_stand_alone_entity(entityDef,suffix,path)
  et_name = entityDef.name()
  et_name_top = et_name+"_top"
  stand_alone_file = path+"/"+et_name +"_" + suffix +"_top.vhd"

  ip = binascii.hexlify(socket.inet_aton(ipAddr)).upper()



  body = """

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library UNISIM;
  use UNISIM.VComponents.all;

  use work.UtilityPkg.all;
  use work.Eth1000BaseXPkg.all;
  use work.GigabitEthPkg.all;


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
    txDisable    : out sl;

    SCLK         : out std_logic_vector(9 downto 0) := (others =>'0');
    SHOUT        : in std_logic_vector(9 downto 0) := (others =>'0');
    SIN          : out std_logic_vector(9 downto 0) := (others =>'0');
    PCLK         : out std_logic_vector(9 downto 0) := (others =>'0');
 
    BUSA_CLR            : out sl := '0';
    BUSA_RAMP           :out sl := '0';
    BUSA_WR_ADDRCLR     :out sl := '0'; 
    BUSA_DO             : in std_logic_vector(15 downto 0) := (others =>'0');
    BUSA_RD_COLSEL_S    : out std_logic_vector(5 downto 0) := (others =>'0');
    BUSA_RD_ENA         : out sl := '0';
    BUSA_RD_ROWSEL_S    : out std_logic_vector(2 downto 0) := (others =>'0');
    BUSA_SAMPLESEL_S    : out std_logic_vector(4 downto 0) := (others =>'0');
    BUSA_SR_CLEAR       : out sl := '0';
    BUSA_SR_SEL         : out sl := '0';
    
    --Bus B Specific Signals
    BUSB_WR_ADDRCLR          : out std_logic := '0';
    BUSB_RD_ENA              : out std_logic := '0';
    BUSB_RD_ROWSEL_S         : out std_logic_vector(2 downto 0) := (others =>'0');
    BUSB_RD_COLSEL_S         : out std_logic_vector(5 downto 0) := (others =>'0');
    BUSB_CLR                 : out std_logic := '0';
    BUSB_RAMP                : out std_logic := '0';
    BUSB_SAMPLESEL_S         : out std_logic_vector(4 downto 0):= (others =>'0');
    BUSB_SR_CLEAR            : out std_logic := '0';
    BUSB_SR_SEL              : out std_logic := '0';
    BUSB_DO                  : in  std_logic_vector(15 downto 0):= (others =>'0');

    BUS_REGCLR      : out sl := '0' ; -- not connected
    SAMPLESEL_ANY   : out std_logic_vector(9 downto 0)  := (others => '0') ;
    SR_CLOCK        : out std_logic_vector(9 downto 0)  := (others => '0') ; 
    WR1_ENA         : out std_logic_vector(9 downto 0)  := (others => '0')  ;
    WR2_ENA         : out std_logic_vector(9 downto 0)  := (others => '0')  ;

    
       -- MPPC HV DAC
   BUSA_SCK_DAC		       : out std_logic := '0';
   BUSA_DIN_DAC		       : out std_logic := '0';
   BUSB_SCK_DAC		       : out std_logic := '0';
   BUSB_DIN_DAC		       : out std_logic := '0';
   --
   -- TRIGGER SIGNALS
   TARGET_TB                : in tb_vec_type;
   
   TDC_DONE                 : in STD_LOGIC_VECTOR(9 downto 0) := (others => '0')  ; -- move to readout signals
   TDC_MON_TIMING           : in STD_LOGIC_VECTOR(9 downto 0) := (others => '0')  ;  -- add the ref to the programming of the TX chip
   
    WL_CLK_N : out STD_LOGIC_VECTOR (9 downto 0) := (others => '0')  ;
    WL_CLK_P  : out STD_LOGIC_VECTOR (9 downto 0) := (others => '0')  ;
    SSTIN_N :  out STD_LOGIC_VECTOR (9 downto 0) := (others => '0')  ;
    SSTIN_P :  out STD_LOGIC_VECTOR (9 downto 0) := (others => '0')  
  );
end entity;

architecture rtl of {EntityName} is

  signal TXBus_m2s : DataBus_m2s_a(1 downto 0) := (others => DataBus_m2s_null);
  signal TXBus_s2m : DataBus_s2m_a(1 downto 0) := (others => DataBus_s2m_null);


  signal fabClk       : sl := '0';
  -- User Data interfaces

  signal  TxDataChannel :  DWORD := (others => '0');
  signal  TxDataValid   :  sl := '0';
  signal  TxDataLast    :  sl := '0';
  signal  TxDataReady   :  sl := '0';
  signal  RxDataChannel :  DWORD := (others => '0');
  signal  RxDataValid   :  sl := '0';
  signal  RxDataLast    :  sl := '0';
  signal  RxDataReady   :  sl := '0';


  constant NUM_IP_G        : integer := 2;
     

  
  signal ethClk125    : sl;
  --signal ethClk62    : sl;
     
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




-- <Connecting the BUS to the pseudo class>
  
  TXBus_m2s(0).ShiftRegister.data_out  <= BUSA_DO;
           
  BUSA_WR_ADDRCLR               <= TXBus_s2m(0).WriteSignals.clear;  
  WR1_ENA(4 downto 0)           <= TXBus_s2m(0).WriteSignals.writeEnable_1;  
  WR2_ENA(4 downto 0)           <= TXBus_s2m(0).WriteSignals.writeEnable_2;  
  
  BUSA_CLR                      <= TXBus_s2m(0).SamplingSignals.clr; 
  BUSA_RAMP                     <= TXBus_s2m(0).SamplingSignals.ramp;
  BUSA_RD_COLSEL_S              <= TXBus_s2m(0).SamplingSignals.read_column_select_s;  
  BUSA_RD_ENA                   <= TXBus_s2m(0).SamplingSignals.read_enable;
  BUSA_RD_ROWSEL_S              <= TXBus_s2m(0).SamplingSignals.read_row_select_s; 
 
  BUSA_SAMPLESEL_S              <= TXBus_s2m(0).ShiftRegister.SampleSelect;
  BUSA_SR_CLEAR                 <= TXBus_s2m(0).ShiftRegister.sr_clear;
  BUSA_SR_SEL                   <= TXBus_s2m(0).ShiftRegister.sr_select ;
  SAMPLESEL_ANY(4 downto 0)     <= TXBus_s2m(0).ShiftRegister.SampleSelectAny;
  SR_CLOCK(4 downto 0)          <= TXBus_s2m(0).ShiftRegister.sr_Clock;

  
  
  TXBus_m2s(1).ShiftRegister.data_out  <= BUSB_DO;
  
  BUSA_WR_ADDRCLR               <= TXBus_s2m(1).WriteSignals.clear;  
  WR1_ENA(9 downto 5)           <= TXBus_s2m(1).WriteSignals.writeEnable_1;  
  WR2_ENA(9 downto 5)           <= TXBus_s2m(1).WriteSignals.writeEnable_2;  

  BUSB_CLR                      <= TXBus_s2m(1).SamplingSignals.clr; 
  BUSB_RAMP                     <= TXBus_s2m(1).SamplingSignals.ramp;
  BUSB_RD_COLSEL_S              <= TXBus_s2m(1).SamplingSignals.read_column_select_s;  
  BUSB_RD_ENA                   <= TXBus_s2m(1).SamplingSignals.read_enable;
  BUSB_RD_ROWSEL_S              <= TXBus_s2m(1).SamplingSignals.read_row_select_s; 
                               
  BUSB_SAMPLESEL_S              <= TXBus_s2m(1).ShiftRegister.SampleSelect;
  BUSB_SR_CLEAR                 <= TXBus_s2m(1).ShiftRegister.sr_clear;
  BUSB_SR_SEL                   <= TXBus_s2m(1).ShiftRegister.sr_select ;
  SAMPLESEL_ANY(9 downto 5)     <= TXBus_s2m(1).ShiftRegister.SampleSelectAny;
  SR_CLOCK(9 downto 5)          <= TXBus_s2m(1).ShiftRegister.sr_Clock;
  
-- </Connecting the BUS to the pseudo class>


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
      ethUsrClk62     => open,
      ethUsrClk125    => ethClk125,
      -- Status and diagnostics out
      ethSync         => open,
      ethReady        => open,
      led             => open,
      -- Core settings in 
      macAddr         => ethCoreMacAddr,
      ipAddrs         => (0 => ethCoreIpAddr, 1 => ethCoreIpAddr1),
      udpPorts        => (0 => x"07D0",       1 => udpPort), --x7D0 = 2000,
      -- User clock inputs
      userClk         => ethClk125,
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
      userClk         => ethClk125,
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
  
  userTxDataChannels(1) <=  TxDataChannel ;
  userTxDataValids(1)   <=  TxDataValid;
  userTxDataLasts(1)    <=  TxDataLast;
  TxDataReady           <=  userTxDataReadys(1);
  
  RxDataChannel        <=  userRxDataChannels(1);
  RxDataValid          <=  userRxDataValids(1);
  RxDataLast           <=  userRxDataLasts(1);
  userRxDataReadys(1)   <=  RxDataReady;     
  
  
  
  u_dut  : entity work.{eth_entity}
    port map (
      Clk       => ethClk125,
      -- Incoming data
      RxDataChannel => RxDataChannel,
      rxDataValid   => RxDataValid,
      rxDataLast    => RxDataLast,
      rxDataReady   => RxDataReady,
      -- outgoing data  
      TxDataChannel   => TxDataChannel,
      TxDataValid     => TxDataValid,
      txDataLast      => TxDataLast,
      TxDataReady     =>  TxDataReady
    );

end architecture;

""".format(
    EntityName=et_name_top,
    ip3 = ip[0:2].decode("utf-8"),
    ip2 = ip[2:4].decode("utf-8"),
    ip1 = ip[4:6].decode("utf-8"),
    ip0 = ip[6:8].decode("utf-8"),
    Port = hex(Port),
    eth_entity = eth_et_name
)
  with open(stand_alone_file,"w",newline="\n") as f:
    f.write(body)




