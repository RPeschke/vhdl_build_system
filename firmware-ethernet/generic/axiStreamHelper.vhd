library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
  use work.UtilityPkg.all;

package axiStreamHelper is

  subtype data_t is integer;
  subtype data_t1 is integer;
  subtype data_t2 is integer;
 -- subtype size_t is integer ;

  type AxiCtrl is record
    DataValid : sl;
    DataLast  : sl;
  end record AxiCtrl;
  
  constant axiCtrl_null : AxiCtrl := (DataValid=> '0', DataLast => '0');
  
  subtype AxiDataReady_t is std_logic;  
  constant AxiDataReady_t_null : AxiDataReady_t := '0';
  
  type AxiStream is record
    ctrl  : AxiCtrl;
    Ready : AxiDataReady_t;
	  Ready0 : AxiDataReady_t;
    Ready1 : AxiDataReady_t;
    position   :  size_t ;
    call_pos :  size_t;
	 data : data_t;
  end record AxiStream;
  
  constant c_axiStream : AxiStream := (
    ctrl=> axiCtrl_null, 
    Ready => '0',
    Ready0 =>'0',
    Ready1 => '0',  
    position => 0, 
	 data => 0,
    call_pos => 0);
end axiStreamHelper;