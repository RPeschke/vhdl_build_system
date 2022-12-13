
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package axi_stream_s32 is


-- Starting Pseudo class axi_stream_32_connection
 
type axi_stream_32_m2s is record 
  data : std_logic_vector(31 downto 0); 
  last : std_logic; 
  valid : std_logic; 

end record axi_stream_32_m2s; 

constant  axi_stream_32_m2s_null: axi_stream_32_m2s := 
  ( 
    data => (others=>'0'),
    last => '0',
    valid => '0'
  );

constant  axi_stream_32_m2s_Z: axi_stream_32_m2s := 
  ( 
    data => (others=>'Z'),
    last => 'Z',
    valid => 'Z'
  );
 
type axi_stream_32_s2m is record 
  ready : std_logic; 
end record axi_stream_32_s2m; 

constant  axi_stream_32_s2m_null: axi_stream_32_s2m := (ready => '0');
constant  axi_stream_32_s2m_Z: axi_stream_32_s2m := (ready => 'Z');
 
-- End Pseudo class axi_stream_32_connection



-- Starting Pseudo class axi_stream_32_master
 
type axi_stream_32_master is record 
  m2s : axi_stream_32_m2s;
  s2m : axi_stream_32_s2m;
end record; 

constant  axi_stream_32_master_null: axi_stream_32_master := 
(
  m2s => axi_stream_32_m2s_null,
  s2m => axi_stream_32_s2m_null
  );

 procedure pull(signal  self : inout axi_stream_32_master);
 function  ready_to_send( self :   axi_stream_32_master) return boolean;
 procedure send_data(signal  self : inout axi_stream_32_master; datain :in std_logic_vector(31 downto 0));
 procedure Send_end_Of_Stream(signal  self : inout axi_stream_32_master);
 
-- End Pseudo class axi_stream_32_master



-- Starting Pseudo class axi_stream_32_slave
 
type axi_stream_32_data_t is record 
  data : std_logic_vector(31 downto 0); 
  isLast : std_logic; 
  isvalid : std_logic; 
end record ; 

constant axi_stream_32_data_t_null : axi_stream_32_data_t:=(
  data     => (others=>'0'),
  isLast   =>'0',
  isvalid  =>'0'
);


type axi_stream_32_slave is record 
  m2s : axi_stream_32_m2s;
  s2m : axi_stream_32_s2m;

  data_internal : axi_stream_32_data_t;
  


end record ; 



constant  axi_stream_32_slave_null : axi_stream_32_slave := (
    m2s =>  axi_stream_32_m2s_null,
    s2m =>  axi_stream_32_s2m_null,
    data_internal => axi_stream_32_data_t_null
  );

 function  IsEndOfStream( self :   axi_stream_32_slave) return boolean;
 function  isReceivingData( self :   axi_stream_32_slave) return boolean;
 procedure read_data( signal self  : inout axi_stream_32_slave; data_out :out std_logic_vector(31 downto 0));
 procedure read_data_s( signal self  : inout axi_stream_32_slave;signal  data_out :out std_logic_vector(31 downto 0));
 procedure pull( signal self  : inout axi_stream_32_slave);
 
 
-- End Pseudo class axi_stream_32_slave

type AXis_send_type_32 is ( 
  normal,
  endOfStream
 );
end package;


package body axi_stream_s32 is
   

  procedure pull(signal  self : inout axi_stream_32_master) is 
  begin 
    self.s2m <= axi_stream_32_s2m_Z;
    if (self.s2m.ready ='1' and self.m2s.valid = '1' ) then 
      self.m2s <=  axi_stream_32_m2s_null;
    end if;



  end procedure;


  function  ready_to_send( self :   axi_stream_32_master) return boolean is 
  begin 
    return  (self.s2m.ready ='1' and self.m2s.valid = '1' )  or self.m2s.valid = '0'; 
  end function;


  procedure send_data(signal  self : inout axi_stream_32_master; datain :in std_logic_vector(31 downto 0)) is 
  begin 
    self.s2m <= axi_stream_32_s2m_Z;
    self.m2s.data <= datain;
    self.m2s.valid <= '1';
  end procedure;


  procedure Send_end_Of_Stream(signal  self : inout axi_stream_32_master) is 
  begin 
    self.s2m <= axi_stream_32_s2m_Z;
    self.m2s.last <= '1';
  end procedure;






-- Starting Pseudo class axi_stream_32_slave

  procedure pull( signal self  : inout axi_stream_32_slave) is 
  begin 
    self.m2s <= axi_stream_32_m2s_Z;
    self.s2m.ready <= '1';
    if self.m2s.valid = '1' and self.s2m.ready = '1' then 
      self.s2m.ready <= '0';
      self.data_internal.data <= self.m2s.data;
      self.data_internal.isLast <= self.m2s.last;
      self.data_internal.isvalid <= self.m2s.valid;
    end if;

    if self.data_internal.isvalid = '1' then 
      self.s2m.ready <= '0';
    end if;

  end procedure;


  function  IsEndOfStream( self :   axi_stream_32_slave) return boolean is 
  begin 
    return  (self.data_internal.isvalid = '1' and self.data_internal.isLast = '1' ) or (self.m2s.valid = '1' and self.s2m.ready ='1' and self.m2s.last ='1') ;
  end function;


  function  isReceivingData( self :   axi_stream_32_slave) return boolean is 
  begin 
    return self.data_internal.isvalid = '1'  or (self.m2s.valid = '1' and self.s2m.ready ='1');
  end function;

  procedure read_data( signal self  : inout axi_stream_32_slave; data_out :out std_logic_vector(31 downto 0)) is
  begin 
    self.m2s <= axi_stream_32_m2s_Z;
    if self.data_internal.isvalid = '1' then 
      data_out := self.data_internal.data;

    elsif self.s2m.ready ='1' and self.m2s.valid = '1' then 
      data_out := self.m2s.data;
      self.s2m.ready <= '1';
    end if;

    self.data_internal <= axi_stream_32_data_t_null;

  end procedure;
  
  procedure read_data_s( signal self  : inout axi_stream_32_slave;signal  data_out :out std_logic_vector(31 downto 0)) is 
    variable  v_data_out : std_logic_vector(31 downto 0) := (others => '0');
  begin 
  
    read_data(self, v_data_out);
    data_out <= v_data_out;
  end procedure;


-- End Pseudo class axi_stream_32_slave_stream

end package body;

