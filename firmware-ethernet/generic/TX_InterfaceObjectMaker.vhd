library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use work.xgen_klm_scrod_bus.all;

entity TX_InterfaceObjectMaker is
  

  port (
      

    BUSA_CLR            : out std_logic := '0';
    BUSA_RAMP           :out std_logic := '0';
    BUSA_WR_ADDRCLR     :out std_logic := '0'; 
    BUSA_DO             : in std_logic_vector(15 downto 0) := (others =>'0');
    BUSA_RD_COLSEL_S    : out std_logic_vector(5 downto 0) := (others =>'0');
    BUSA_RD_ENA         : out std_logic := '0';
    BUSA_RD_ROWSEL_S    : out std_logic_vector(2 downto 0) := (others =>'0');
    BUSA_SAMPLESEL_S    : out std_logic_vector(4 downto 0) := (others =>'0');
    BUSA_SR_CLEAR       : out std_logic := '0';
    BUSA_SR_SEL         : out std_logic := '0';

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

    BUS_REGCLR      : out std_logic := '0' ; -- not connected
    SAMPLESEL_ANY   : out std_logic_vector(9 downto 0)  := (others => '0') ;
    SR_CLOCK        : out std_logic_vector(9 downto 0)  := (others => '0') ; 
    WR1_ENA         : out std_logic_vector(9 downto 0)  := (others => '0')  ;
    WR2_ENA         : out std_logic_vector(9 downto 0)  := (others => '0')  ;
    
    TXBus_m2s : out DataBus_m2s_a(1 downto 0) := (others => DataBus_m2s_null);
    TXBus_s2m : in  DataBus_s2m_a(1 downto 0) := (others => DataBus_s2m_null)
  );
end entity;

architecture rtl of TX_InterfaceObjectMaker is
begin
  

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

  BUSB_WR_ADDRCLR               <= TXBus_s2m(1).WriteSignals.clear;  
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
end architecture;