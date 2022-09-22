
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_base_pkg.all;


package fifo_cc_pgk_32 is


-- Starting Pseudo class FIFO_nativ_write_32_connection
 
type FIFO_nativ_write_32_m2s is record 
data : std_logic_vector(31 downto 0); 
write_enable : std_logic; 

end record FIFO_nativ_write_32_m2s; 

constant  FIFO_nativ_write_32_m2s_null: FIFO_nativ_write_32_m2s := (data => (others=>'0'),
write_enable => '0');

 
type FIFO_nativ_write_32_s2m is record 
full : std_logic; 

end record FIFO_nativ_write_32_s2m; 

constant  FIFO_nativ_write_32_s2m_null: FIFO_nativ_write_32_s2m := (full => '0');

 
-- End Pseudo class FIFO_nativ_write_32_connection



-- Starting Pseudo class FIFO_nativ_write_32_master
 
type FIFO_nativ_write_32_master is record 
data : std_logic_vector(31 downto 0); 
full : std_logic; 
write_enable : std_logic; 

end record FIFO_nativ_write_32_master; 

constant  FIFO_nativ_write_32_master_null: FIFO_nativ_write_32_master := (data => (others=>'0'),
full => '0',
write_enable => '0');

 function  ready_to_send( this :   FIFO_nativ_write_32_master) return boolean;
 procedure write_data( this : inout FIFO_nativ_write_32_master; datain :in std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_write_32_master( this : inout FIFO_nativ_write_32_master; signal DataIn : in  FIFO_nativ_write_32_s2m);
 procedure push_FIFO_nativ_write_32_master( this : inout FIFO_nativ_write_32_master; signal DataOut : out  FIFO_nativ_write_32_m2s);
 
-- End Pseudo class FIFO_nativ_write_32_master



-- Starting Pseudo class FIFO_nativ_write_32_slave
 
type FIFO_nativ_write_32_slave is record 
data : std_logic_vector(31 downto 0); 
data_was_read : std_logic; 
errorState : fifo_error_states_t; 
full : std_logic; 
write_enable : std_logic; 

end record FIFO_nativ_write_32_slave; 

constant  FIFO_nativ_write_32_slave_null: FIFO_nativ_write_32_slave := (data => (others=>'0'),
data_was_read => '0',
errorState => fifo_error_states_t_null,
full => '0',
write_enable => '0');

 procedure enable_reading( this : inout FIFO_nativ_write_32_slave);
 function  isReceivingData( this :   FIFO_nativ_write_32_slave) return boolean;
 procedure read_data( this : inout FIFO_nativ_write_32_slave; datain :out std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_write_32_slave( this : inout FIFO_nativ_write_32_slave; signal DataIn : in  FIFO_nativ_write_32_m2s);
 procedure push_FIFO_nativ_write_32_slave( this : inout FIFO_nativ_write_32_slave; signal DataOut : out  FIFO_nativ_write_32_s2m);
 
-- End Pseudo class FIFO_nativ_write_32_slave



-- Starting Pseudo class FIFO_nativ_reader_32_connection
 
type FIFO_nativ_reader_32_m2s is record 
data : std_logic_vector(31 downto 0); 
empty : std_logic; 

end record FIFO_nativ_reader_32_m2s; 

constant  FIFO_nativ_reader_32_m2s_null: FIFO_nativ_reader_32_m2s := (data => (others=>'0'),
empty => '0');

 
type FIFO_nativ_reader_32_s2m is record 
read_enable : std_logic; 

end record FIFO_nativ_reader_32_s2m; 

constant  FIFO_nativ_reader_32_s2m_null: FIFO_nativ_reader_32_s2m := (read_enable => '0');

 
-- End Pseudo class FIFO_nativ_reader_32_connection



-- Starting Pseudo class FIFO_nativ_reader_32_master
 
type FIFO_nativ_reader_32_master is record 
data : std_logic_vector(31 downto 0); 
empty : std_logic; 
read_enable : std_logic; 

end record FIFO_nativ_reader_32_master; 

constant  FIFO_nativ_reader_32_master_null: FIFO_nativ_reader_32_master := (data => (others=>'0'),
empty => '0',
read_enable => '0');

 function  ready_to_send( this :   FIFO_nativ_reader_32_master) return boolean;
 procedure write_data( this : inout FIFO_nativ_reader_32_master; datain :in std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_reader_32_master( this : inout FIFO_nativ_reader_32_master; signal DataIn : in  FIFO_nativ_reader_32_s2m);
 procedure push_FIFO_nativ_reader_32_master( this : inout FIFO_nativ_reader_32_master; signal DataOut : out  FIFO_nativ_reader_32_m2s);
 
-- End Pseudo class FIFO_nativ_reader_32_master



-- Starting Pseudo class FIFO_nativ_reader_32_slave
 
type FIFO_nativ_reader_32_slave is record 
data : std_logic_vector(31 downto 0); 
data_was_read : std_logic; 
empty : std_logic; 
error_state : fifo_error_states_t; 
read_enable : std_logic; 
read_enable1 : std_logic; 
reciving_data : std_logic; 

end record FIFO_nativ_reader_32_slave; 

constant  FIFO_nativ_reader_32_slave_null: FIFO_nativ_reader_32_slave := (data => (others=>'0'),
data_was_read => '0',
empty => '0',
error_state => fifo_error_states_t_null,
read_enable => '0',
read_enable1 => '0',
reciving_data => '0');

 procedure enable_reading( this : inout FIFO_nativ_reader_32_slave);
 function  isReceivingData( this :   FIFO_nativ_reader_32_slave) return boolean;
 procedure read_data( this : inout FIFO_nativ_reader_32_slave; datain :out std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_reader_32_slave( this : inout FIFO_nativ_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s);
 procedure push_FIFO_nativ_reader_32_slave( this : inout FIFO_nativ_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m);
 procedure FIFO_nativ_reader_32_slave_push_comb(signal DataOut : out  FIFO_nativ_reader_32_s2m ; signal proto_data_out : in FIFO_nativ_reader_32_s2m; signal data_in: FIFO_nativ_reader_32_m2s);
 
-- End Pseudo class FIFO_nativ_reader_32_slave



-- Starting Pseudo class FIFO_nativ_step_by_step_reader_32_slave
 
type FIFO_nativ_step_by_step_reader_32_slave is record 
data : std_logic_vector(31 downto 0); 
data_was_read : std_logic; 
empty : std_logic; 
error_state : fifo_error_states_t; 
read_enable : std_logic; 
read_enable1 : std_logic; 
reciving_data : std_logic; 

end record FIFO_nativ_step_by_step_reader_32_slave; 

constant  FIFO_nativ_step_by_step_reader_32_slave_null: FIFO_nativ_step_by_step_reader_32_slave := (data => (others=>'0'),
data_was_read => '0',
empty => '0',
error_state => fifo_error_states_t_null,
read_enable => '0',
read_enable1 => '0',
reciving_data => '0');

 function  isReceivingData( this :   FIFO_nativ_step_by_step_reader_32_slave) return boolean;
 procedure read_data( this : inout FIFO_nativ_step_by_step_reader_32_slave; datain :out std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_step_by_step_reader_32_slave( this : inout FIFO_nativ_step_by_step_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s);
 procedure push_FIFO_nativ_step_by_step_reader_32_slave( this : inout FIFO_nativ_step_by_step_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m);
 
-- End Pseudo class FIFO_nativ_step_by_step_reader_32_slave



-- Starting Pseudo class FIFO_nativ_stream_reader_32_slave
 
type FIFO_nativ_stream_reader_32_slave is record 
data : std_logic_vector(31 downto 0); 
data_internal : std_logic_vector(31 downto 0); 
data_internal2 : std_logic_vector(31 downto 0); 
data_internal_isvalid : std_logic; 
data_internal_isvalid2 : std_logic; 
data_internal_was_read : std_logic; 
data_internal_was_read2 : std_logic; 
data_isvalid : std_logic; 
data_was_read : std_logic; 
empty : std_logic; 
error_state : fifo_error_states_t; 
read_enable : std_logic; 
read_enable1 : std_logic; 
reciving_data : std_logic; 

end record FIFO_nativ_stream_reader_32_slave; 

constant  FIFO_nativ_stream_reader_32_slave_null: FIFO_nativ_stream_reader_32_slave := (data => (others=>'0'),
data_internal => (others=>'0'),
data_internal2 => (others=>'0'),
data_internal_isvalid => '0',
data_internal_isvalid2 => '0',
data_internal_was_read => '0',
data_internal_was_read2 => '0',
data_isvalid => '0',
data_was_read => '0',
empty => '0',
error_state => fifo_error_states_t_null,
read_enable => '0',
read_enable1 => '0',
reciving_data => '0');

 function  isReceivingData( this :   FIFO_nativ_stream_reader_32_slave) return boolean;
 procedure read_data( this : inout FIFO_nativ_stream_reader_32_slave; datain :out std_logic_vector(31 downto 0));
 procedure pull_FIFO_nativ_stream_reader_32_slave( this : inout FIFO_nativ_stream_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s);
 procedure push_FIFO_nativ_stream_reader_32_slave( this : inout FIFO_nativ_stream_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m);
 procedure FIFO_nativ_stream_reader_32_slave_push_comb(signal DataOut : out  FIFO_nativ_reader_32_s2m ; signal proto_data_out : in FIFO_nativ_reader_32_s2m; signal data_in: FIFO_nativ_reader_32_m2s);
 
-- End Pseudo class FIFO_nativ_stream_reader_32_slave

end fifo_cc_pgk_32;


package body fifo_cc_pgk_32 is
   

-- Starting Pseudo class FIFO_nativ_write_32_master
  function  ready_to_send( this :   FIFO_nativ_write_32_master) return boolean is begin 

    return this.full = '0';
 
end function ready_to_send; 

 procedure write_data( this : inout FIFO_nativ_write_32_master; datain :in std_logic_vector(31 downto 0)) is begin 

   this.write_enable   := '1';
   this.data           := datain; 
 
end procedure write_data; 

 procedure pull_FIFO_nativ_write_32_master( this : inout FIFO_nativ_write_32_master; signal DataIn : in  FIFO_nativ_write_32_s2m) is begin 
this.write_enable   := '0';
this.full := DataIn.full;

 
end procedure pull_FIFO_nativ_write_32_master; 

 procedure push_FIFO_nativ_write_32_master( this : inout FIFO_nativ_write_32_master; signal DataOut : out  FIFO_nativ_write_32_m2s) is begin 

DataOut.data <= this.data;
DataOut.write_enable <= this.write_enable;

 
end procedure push_FIFO_nativ_write_32_master; 

 
-- End Pseudo class FIFO_nativ_write_32_master



-- Starting Pseudo class FIFO_nativ_write_32_slave
  procedure enable_reading( this : inout FIFO_nativ_write_32_slave) is begin 

    this.full := '0';
 
end procedure enable_reading; 

 function  isReceivingData( this :   FIFO_nativ_write_32_slave) return boolean is begin 

    return this.write_enable = '1';
 
end function isReceivingData; 

 procedure read_data( this : inout FIFO_nativ_write_32_slave; datain :out std_logic_vector(31 downto 0)) is begin 

    datain := this.data;
    this.data_was_read := '1';
 
end procedure read_data; 

 procedure pull_FIFO_nativ_write_32_slave( this : inout FIFO_nativ_write_32_slave; signal DataIn : in  FIFO_nativ_write_32_m2s) is begin 

    this.full   := '1';
    this.errorState := (others => '0');
    
this.data := DataIn.data;
this.write_enable := DataIn.write_enable;

 
end procedure pull_FIFO_nativ_write_32_slave; 

 procedure push_FIFO_nativ_write_32_slave( this : inout FIFO_nativ_write_32_slave; signal DataOut : out  FIFO_nativ_write_32_s2m) is begin 

    if (this.write_enable = '1' and this.data_was_read = '0') then
     this.errorState := this.errorState or fifo_not_reading_data;
    end if;
    
DataOut.full <= this.full;

 
end procedure push_FIFO_nativ_write_32_slave; 

 
-- End Pseudo class FIFO_nativ_write_32_slave

   

-- Starting Pseudo class FIFO_nativ_reader_32_master
  function  ready_to_send( this :   FIFO_nativ_reader_32_master) return boolean is begin 

    return this.empty = '1';
 
end function ready_to_send; 

 procedure write_data( this : inout FIFO_nativ_reader_32_master; datain :in std_logic_vector(31 downto 0)) is begin 

   this.empty   := '0';
   this.data           := datain; 
 
end procedure write_data; 

 procedure pull_FIFO_nativ_reader_32_master( this : inout FIFO_nativ_reader_32_master; signal DataIn : in  FIFO_nativ_reader_32_s2m) is begin 

    if (this.read_enable ='1') then
        this.empty   := '1';
    end if;

    
this.read_enable := DataIn.read_enable;

 
end procedure pull_FIFO_nativ_reader_32_master; 

 procedure push_FIFO_nativ_reader_32_master( this : inout FIFO_nativ_reader_32_master; signal DataOut : out  FIFO_nativ_reader_32_m2s) is begin 

DataOut.data <= this.data;
DataOut.empty <= this.empty;

 
end procedure push_FIFO_nativ_reader_32_master; 

 
-- End Pseudo class FIFO_nativ_reader_32_master



-- Starting Pseudo class FIFO_nativ_reader_32_slave
  procedure enable_reading( this : inout FIFO_nativ_reader_32_slave) is begin 

   if (this.empty = '0') then 
        this.read_enable := '1';
   end if;
  
 
end procedure enable_reading; 

 function  isReceivingData( this :   FIFO_nativ_reader_32_slave) return boolean is begin 

    return this.reciving_data = '1';
 
end function isReceivingData; 

 procedure read_data( this : inout FIFO_nativ_reader_32_slave; datain :out std_logic_vector(31 downto 0)) is begin 

    datain := this.data;
    this.data_was_read := '1';
 
end procedure read_data; 

 procedure pull_FIFO_nativ_reader_32_slave( this : inout FIFO_nativ_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s) is begin 

    if( this.read_enable1 = '1'  and this.empty ='0') then 
        this.reciving_data := '1';
    end if;
    this.read_enable1 := this.read_enable;
    this.data_was_read := '0';
    this.error_state := (others => '0');
    this.read_enable :='0';
    
this.data := DataIn.data;
this.empty := DataIn.empty;

 
end procedure pull_FIFO_nativ_reader_32_slave; 

 procedure push_FIFO_nativ_reader_32_slave( this : inout FIFO_nativ_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m) is begin 

    if (this.reciving_data = '1' and this.data_was_read = '0') then
     --this.errorState := this.errorState or fifo_not_reading_data;
    end if;
    
    if (this.reciving_data ='1' and this.data_was_read = '1'   ) then
      this.reciving_data := '0';
    end if;
    
DataOut.read_enable <= this.read_enable;

 
end procedure push_FIFO_nativ_reader_32_slave; 

 procedure FIFO_nativ_reader_32_slave_push_comb(signal DataOut : out  FIFO_nativ_reader_32_s2m ; signal proto_data_out : in FIFO_nativ_reader_32_s2m; signal data_in: FIFO_nativ_reader_32_m2s) is begin 

    if ( data_in.empty = '0') then
      DataOut.read_enable <= proto_data_out.read_enable;
    else 
      DataOut.read_enable <='0';
    end if; 
end procedure FIFO_nativ_reader_32_slave_push_comb; 

 
-- End Pseudo class FIFO_nativ_reader_32_slave



-- Starting Pseudo class FIFO_nativ_step_by_step_reader_32_slave
  function  isReceivingData( this :   FIFO_nativ_step_by_step_reader_32_slave) return boolean is begin 

    return this.reciving_data = '1';
 
end function isReceivingData; 

 procedure read_data( this : inout FIFO_nativ_step_by_step_reader_32_slave; datain :out std_logic_vector(31 downto 0)) is begin 

    datain := this.data;
    this.data_was_read := '1';
    this.read_enable := '1';
 
end procedure read_data; 

 procedure pull_FIFO_nativ_step_by_step_reader_32_slave( this : inout FIFO_nativ_step_by_step_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s) is begin 

    if( DataIn.empty = '0' and this.read_enable1 ='0' and this.read_enable ='0' ) then 
        this.reciving_data := '1';
    end if;
    this.read_enable1 := this.read_enable;
    this.data_was_read := '0';
    this.error_state := (others => '0');
    this.read_enable :='0';
    
this.data := DataIn.data;
this.empty := DataIn.empty;

 
end procedure pull_FIFO_nativ_step_by_step_reader_32_slave; 

 procedure push_FIFO_nativ_step_by_step_reader_32_slave( this : inout FIFO_nativ_step_by_step_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m) is begin 

    if (this.reciving_data = '1' and this.data_was_read = '0') then
     --this.errorState := this.errorState or fifo_not_reading_data;
    end if;

    if (this.reciving_data ='1' and this.data_was_read = '1'   ) then
      this.reciving_data := '0';
    end if;
    
DataOut.read_enable <= this.read_enable;

 
end procedure push_FIFO_nativ_step_by_step_reader_32_slave; 

 
-- End Pseudo class FIFO_nativ_step_by_step_reader_32_slave



-- Starting Pseudo class FIFO_nativ_stream_reader_32_slave
  function  isReceivingData( this :   FIFO_nativ_stream_reader_32_slave) return boolean is begin 

    return  this.data_internal_isvalid2 = '1' ;
 
end function isReceivingData; 

 procedure read_data( this : inout FIFO_nativ_stream_reader_32_slave; datain :out std_logic_vector(31 downto 0)) is begin 




    if(this.data_internal_isvalid2 = '1') then
        datain := this.data_internal2;
        this.data_internal_was_read2 :='1';
  --  elsif (this.data_internal_isvalid = '1') then
  --      datain := this.data_internal;
  --      this.data_internal_was_read := '1';
  --  elsif(this.data_isvalid = '1') then
  --      datain := this.data;
  --      this.data_was_read := '1';

    end if;
 
end procedure read_data; 

 procedure pull_FIFO_nativ_stream_reader_32_slave( this : inout FIFO_nativ_stream_reader_32_slave; signal DataIn : in  FIFO_nativ_reader_32_m2s) is begin 

    if( this.read_enable1 = '1'  and this.empty ='0') then 


       
        this.data_isvalid := '1';
    end if;


    if (this.reciving_data ='1' and  this.data_internal_isvalid = '1') then
        this.data_internal2:= this.data_internal ;
        this.data_internal_isvalid2 := '1';
    end if;
    if (this.reciving_data ='1' and this.data_isvalid = '0') then
      this.data_isvalid := '0';
      this.data_internal :=  this.data;
      this.data_internal_isvalid := '1';
    end if;





    this.read_enable1 := this.read_enable;
    this.data_was_read := '0';
    this.data_internal_was_read := '0';
    this.data_internal_was_read2 := '0';
    this.error_state := (others => '0');
    this.read_enable :='0';
    
this.data := DataIn.data;
this.empty := DataIn.empty;

    
    if (this.data_internal_isvalid ='1' and  this.data_internal_isvalid2 = '0') then
        this.data_internal2:= this.data_internal ;
        this.data_internal_isvalid2 := this.data_internal_isvalid;
        this.data_internal_isvalid:='0';
    end if;

    if (this.data_isvalid ='1' and  this.data_internal_isvalid2 = '0') then
        this.data_internal2:= this.data ;
        this.data_internal_isvalid2 := this.data_isvalid;
        this.data_isvalid:='0';
    elsif(this.data_isvalid ='1' and  this.data_internal_isvalid = '0') then
        this.data_internal:= this.data ;
        this.data_internal_isvalid := this.data_isvalid;
        this.data_isvalid:='0';
    end if;


    
 
end procedure pull_FIFO_nativ_stream_reader_32_slave; 

 procedure push_FIFO_nativ_stream_reader_32_slave( this : inout FIFO_nativ_stream_reader_32_slave; signal DataOut : out  FIFO_nativ_reader_32_s2m) is begin 

   if (this.reciving_data = '1' and this.data_was_read = '0') then
     --this.errorState := this.errorState or fifo_not_reading_data;
    end if;
    
    if (this.data_was_read = '1'   ) then
      this.data_isvalid := '0';
    end if;
    
    if (this.data_internal_was_read = '1'   ) then
      this.data_internal_isvalid := '0';
    end if;

    if (this.data_internal_was_read2 = '1'   ) then
      this.data_internal_isvalid2 := '0';
    end if;




    

    if (this.empty = '0' and this.data_isvalid = '0'   and  this.data_internal_isvalid = '0' and this.data_internal_isvalid2 = '0' ) then 
        this.read_enable := '1';
    end if;
    
DataOut.read_enable <= this.read_enable;

 
end procedure push_FIFO_nativ_stream_reader_32_slave; 

 procedure FIFO_nativ_stream_reader_32_slave_push_comb(signal DataOut : out  FIFO_nativ_reader_32_s2m ; signal proto_data_out : in FIFO_nativ_reader_32_s2m; signal data_in: FIFO_nativ_reader_32_m2s) is begin 

    if ( data_in.empty = '0') then
      DataOut.read_enable <= proto_data_out.read_enable;
    else 
      DataOut.read_enable <='0';
    end if;
     
end procedure FIFO_nativ_stream_reader_32_slave_push_comb; 

 
-- End Pseudo class FIFO_nativ_stream_reader_32_slave

end package body fifo_cc_pgk_32;

