library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
  use ieee.numeric_std.all;

package AXI4LITE_pac is 

constant AXI4LITE_ADDR_WIDTH : integer := 32;
constant AXI4LITE_RDATA_WIDTH : integer := 32;
constant AXI4LITE_ADDR_IN_WIDTH : integer := 16;


constant AXI4LITE_steering_signals_m2s_length : integer := 8;
constant AXI4LITE_steering_signals_s2m_length : integer := 8;

type AXI4_lite_Read_Address_Channel_m2s is record
    -- Address bus from AXI interconnect to slave peripheral
    S_AXI_ARADDR : std_logic_vector(AXI4LITE_ADDR_WIDTH - 1 downto 0);
    -- Valid signal, asserting that the S_AXI_AWADDR can be sampled by the slave peripheral.
    S_AXI_ARVALID : std_logic;
end record;

constant AXI4_lite_Read_Address_Channel_m2s_null : AXI4_lite_Read_Address_Channel_m2s := (
    S_AXI_ARADDR => (others => '0'),
    S_AXI_ARVALID => '0'
);

subtype AXI4_lite_Read_Address_Channel_m2s_serial is std_logic_vector( AXI4LITE_ADDR_WIDTH + 1 - 1  downto 0);



type AXI4_lite_Read_Address_Channel_s2m is record
    -- Ready signal, indicating that the slave is ready to accept the value on S_AXI_AWADDR.
    S_AXI_ARREADY : std_logic;
end record;

constant AXI4_lite_Read_Address_Channel_s2m_null : AXI4_lite_Read_Address_Channel_s2m := (
    S_AXI_ARREADY => '0'
);

subtype AXI4_lite_Read_Address_Channel_s2m_serial is std_logic_vector(1 - 1  downto 0);

type AXI4_lite_Read_Data_Channel_s2m is record
    -- Data bus from the slave peripheral to the AXI interconnect.
    S_AXI_RDATA : std_logic_vector(AXI4LITE_RDATA_WIDTH -1  downto 0);
    -- Valid signal, asserting that the
    -- S_AXI_RDATA can be sampled by the Master
    S_AXI_RVALID : std_logic;
    -- A "Response" status signal showing whether
    -- the transaction completed successfully or
    -- whether there was an error.
    S_AXI_RRESP : std_logic_vector(1 downto 0);
end record;

constant AXI4_lite_Read_Data_Channel_s2m_null : AXI4_lite_Read_Data_Channel_s2m := (
    S_AXI_RDATA => (others => '0'),
    S_AXI_RVALID => '0',
    S_AXI_RRESP => (others => '0')
);

subtype AXI4_lite_Read_Data_Channel_s2m_serial is std_logic_vector(AXI4LITE_RDATA_WIDTH + 1 + 2 - 1  downto 0);

type AXI4_lite_Read_Data_Channel_m2s is record
    -- Ready signal, indicating that the Master is
    -- ready to accept the value on the other signals.
    S_AXI_RREADY : std_logic;
end record;

constant AXI4_lite_Read_Data_Channel_m2s_null : AXI4_lite_Read_Data_Channel_m2s := (
    S_AXI_RREADY => '0'
);

subtype AXI4_lite_Read_Data_Channel_m2s_serial is std_logic_vector(1 - 1  downto 0);


type AXI4_lite_write_Address_Channel_m2s is record
    -- Address bus from AXI interconnect to slave peripheral
    S_AXI_AWADDR : std_logic_vector(AXI4LITE_ADDR_WIDTH - 1 downto 0);
    -- Valid signal, asserting that the S_AXI_AWADDR can be sampled by the slave peripheral.
    S_AXI_AWVALID : std_logic;
end record;

constant AXI4_lite_write_Address_Channel_m2s_null : AXI4_lite_write_Address_Channel_m2s := (
    S_AXI_AWADDR => (others => '0'),
    S_AXI_AWVALID => '0'
);

subtype AXI4_lite_write_Address_Channel_m2s_serial is std_logic_vector(AXI4LITE_ADDR_WIDTH + 1 - 1  downto 0);

type AXI4_lite_write_Address_Channel_s2m is record
    -- Ready signal, indicating that the slave is ready to accept the value on S_AXI_AWADDR.
    S_AXI_AWREADY : std_logic;
end record;

constant AXI4_lite_write_Address_Channel_s2m_null : AXI4_lite_write_Address_Channel_s2m := (
    S_AXI_AWREADY => '0'
);

subtype AXI4_lite_write_Address_Channel_s2m_serial is std_logic_vector(1 - 1  downto 0);

type AXI4_lite_Write_Response_Channel_m2s is record 
    -- Ready signal, indicating that the Master is
    -- ready to accept the "BRESP" response signal
    -- from the slave
    S_AXI_BREADY : std_logic;
end record;

constant AXI4_lite_Write_Response_Channel_m2s_null : AXI4_lite_Write_Response_Channel_m2s := (
    S_AXI_BREADY => '0'
);

subtype AXI4_lite_Write_Response_Channel_m2s_serial is std_logic_vector(1 - 1  downto 0);

type AXI4_lite_Write_Response_Channel_s2m is record 
    -- A "Response" status signal showing whether
    -- the transaction completed successfully or
    -- whether there was an error.
    S_AXI_BRESP : std_logic_vector(1 downto 0);
    -- Valid signal, asserting that the S_AXI_BRESP
    -- can be sampled by the Master.
    S_AXI_BVALID : std_logic;
end record;

constant AXI4_lite_Write_Response_Channel_s2m_null : AXI4_lite_Write_Response_Channel_s2m := (
    S_AXI_BRESP => (others => '0'),
    S_AXI_BVALID => '0'
);

subtype AXI4_lite_Write_Response_Channel_s2m_serial is std_logic_vector(2 + 1 - 1  downto 0);


type AXI4_lite_Write_Data_Channel_m2s is record
    -- Data bus from the Master / AXI interconnect to the Slave peripheral.
    S_AXI_WDATA  : std_logic_vector(AXI4LITE_RDATA_WIDTH - 1 downto 0);
    -- Valid signal, asserting that the S_AXI_RDATA can be sampled by the Master.
    S_AXI_WVALID : std_logic;
    -- A "Strobe" status signal showing which bytes
    -- of the data bus are valid and should be read by the Slave. 
    S_AXI_WSTRB  : std_logic_vector(3 downto 0);
end record;

constant AXI4_lite_Write_Data_Channel_m2s_null : AXI4_lite_Write_Data_Channel_m2s := (
    S_AXI_WDATA => (others => '0'),
    S_AXI_WVALID => '0',
    S_AXI_WSTRB => (others => '0')
);
subtype AXI4_lite_Write_Data_Channel_m2s_serial is std_logic_vector(AXI4LITE_RDATA_WIDTH + 1 + 4 - 1  downto 0);


type AXI4_lite_Write_Data_Channel_s2m is record
    -- Ready signal, indicating that t he Master is ready to accept the value on the other signals.
    S_AXI_WREADY  : std_logic;
end record;


constant AXI4_lite_Write_Data_Channel_s2m_null : AXI4_lite_Write_Data_Channel_s2m := (
    S_AXI_WREADY => '0'
);


subtype AXI4_lite_Write_Data_Channel_s2m_serial is std_logic_vector( 1  - 1  downto 0);



type AXI4LITE_m2s is record
  S_AXI_AR : AXI4_lite_Read_Address_Channel_m2s;
  S_AXI_R : AXI4_lite_Read_Data_Channel_m2s;
  
  
  S_AXI_AW : AXI4_lite_write_Address_Channel_m2s;
  S_AXI_W : AXI4_lite_Write_Data_Channel_m2s;

  
  S_AXI_B : AXI4_lite_Write_Response_Channel_m2s;
end record;

constant AXI4LITE_m2s_null : AXI4LITE_m2s := (
  S_AXI_AR => AXI4_lite_Read_Address_Channel_m2s_null,
  S_AXI_R => AXI4_lite_Read_Data_Channel_m2s_null,
  
  S_AXI_AW => AXI4_lite_write_Address_Channel_m2s_null,
  S_AXI_W => AXI4_lite_Write_Data_Channel_m2s_null,

  
  S_AXI_B => AXI4_lite_Write_Response_Channel_m2s_null
);

 type AXI4LITE_m2s_a is array (natural range <>) of AXI4LITE_m2s;

subtype AXI4LITE_m2s_serialize_t is std_logic_vector( 
    AXI4LITE_ADDR_WIDTH 
    + 1
    + 1
    + AXI4LITE_ADDR_WIDTH
    + 1
    + AXI4LITE_RDATA_WIDTH
    + 1  
    + 4 
    + 1  
    - 1  downto 0);

constant AXI4LITE_m2s_serialize_length : integer :=    AXI4LITE_ADDR_WIDTH 
    + 1
    + 1
    + AXI4LITE_ADDR_WIDTH
    + 1
    + AXI4LITE_RDATA_WIDTH
    + 1  
    + 4 
    + 1;

type AXI4LITE_s2m is record
  S_AXI_AR : AXI4_lite_Read_Address_Channel_s2m;
  S_AXI_R : AXI4_lite_Read_Data_Channel_s2m;
  
  
  S_AXI_AW: AXI4_lite_write_Address_Channel_s2m;
  S_AXI_W : AXI4_lite_Write_Data_Channel_s2m;


  S_AXI_B : AXI4_lite_Write_Response_Channel_s2m;
end record;

constant AXI4LITE_s2m_null : AXI4LITE_s2m := (
  S_AXI_AR => AXI4_lite_Read_Address_Channel_s2m_null,
  S_AXI_R => AXI4_lite_Read_Data_Channel_s2m_null,
  
  S_AXI_AW => AXI4_lite_write_Address_Channel_s2m_null,
  S_AXI_W => AXI4_lite_Write_Data_Channel_s2m_null,

  
  S_AXI_B => AXI4_lite_Write_Response_Channel_s2m_null
);

type AXI4LITE_s2m_a is array (natural range <>) of AXI4LITE_s2m;


function AXI4LITE_s2m_length(AXI4LITE_RDATA_WIDTH : integer) return integer; 
function AXI4LITE_m2s_length(AXI4LITE_RDATA_WIDTH : integer; AXI4LITE_ADDR_WIDTH : integer ) return integer; 

subtype AXI4LITE_s2m_serialize_t is std_logic_vector(
    1
    +  AXI4LITE_RDATA_WIDTH 
    + 1 
    + 2 
    + 1 
    + 1 
    + 2 
    + 1 
    - 1  downto 0);

constant AXI4LITE_s2m_serialize_length : integer :=       1
    +  AXI4LITE_RDATA_WIDTH 
    + 1 
    + 2 
    + 1 
    + 1 
    + 2 
    + 1 ;

function AXI4LITE_m2s_serialize(self : AXI4LITE_m2s) return std_logic_vector;
function AXI4LITE_s2m_serialize(self : AXI4LITE_s2m) return std_logic_vector;

function AXI4LITE_m2s_deserialize(self : std_logic_vector) return AXI4LITE_m2s ;
function AXI4LITE_s2m_deserialize(self : std_logic_vector) return AXI4LITE_s2m ;

type AXI4LITE is record
  S_AXI_AR_m2s : AXI4_lite_Read_Address_Channel_m2s;
  S_AXI_AR_s2m : AXI4_lite_Read_Address_Channel_s2m;
  
  S_AXI_R_m2s : AXI4_lite_Read_Data_Channel_m2s;
  S_AXI_R_s2m : AXI4_lite_Read_Data_Channel_s2m;

  S_AXI_AW_m2s : AXI4_lite_write_Address_Channel_m2s;
  S_AXI_AW_s2m : AXI4_lite_write_Address_Channel_s2m;


  S_AXI_W_m2s : AXI4_lite_Write_Data_Channel_m2s;
  S_AXI_W_s2m : AXI4_lite_Write_Data_Channel_s2m;


  S_AXI_B_m2s : AXI4_lite_Write_Response_Channel_m2s;
  S_AXI_B_s2m : AXI4_lite_Write_Response_Channel_s2m;
end record;

constant AXI4LITE_null : AXI4LITE := (
  S_AXI_AR_m2s => AXI4_lite_Read_Address_Channel_m2s_null,
  S_AXI_AR_s2m => AXI4_lite_Read_Address_Channel_s2m_null,
  
  S_AXI_R_m2s => AXI4_lite_Read_Data_Channel_m2s_null,
  S_AXI_R_s2m => AXI4_lite_Read_Data_Channel_s2m_null,

  S_AXI_AW_m2s => AXI4_lite_write_Address_Channel_m2s_null,
  S_AXI_AW_s2m => AXI4_lite_write_Address_Channel_s2m_null,
  
  S_AXI_W_m2s => AXI4_lite_Write_Data_Channel_m2s_null,
  S_AXI_W_s2m => AXI4_lite_Write_Data_Channel_s2m_null,

  S_AXI_B_m2s => AXI4_lite_Write_Response_Channel_m2s_null,
  S_AXI_B_s2m => AXI4_lite_Write_Response_Channel_s2m_null
);


type AXI4_lite_Response_Signalling_T is record
    -- 00 OKAY "OKAY" The data was received 
    -- successfully, and there were no errors.
    OKAY   : std_logic_vector(1 downto 0);
    -- 01 EXOKAY "Exclusive Access OK" This state 
    -- is only used in the full implementation of 
    -- AXI4, and therefore cannot occur when using 
    -- AXI4-Lite.
    EXOKAY : std_logic_vector(1 downto 0);
    -- 10 SLVERR "Slave Error" The slave has received 
    -- the address phase of the transaction correctly,  
    -- but needs to signal an error condition to the master. 
    -- This often results in a retry condition occurring.
    SLVERR : std_logic_vector(1 downto 0);

    -- 11 DECERR "Decode Error" This condition is not normally 
    -- asserted by a peripheral, but can be asserted by the AXI 
    -- interconnect logic which sits between the slave and the master. 
    -- This condition is usually used to indicate that the address 
    -- provided doesn't exist in the address space of the AXI interconnect.
    DECERR : std_logic_vector(1 downto 0);
end record;

constant AXI4_lite_Response_Signalling : AXI4_lite_Response_Signalling_T := (
    OKAY => "00",
    EXOKAY => "01",
    SLVERR => "10",
    DECERR => "11"
);


type S_AXI_WSTRB_T is record 
    -- 11111111111111111111111111111111 All bits active
    All_bits_active : std_logic_vector(3 downto 0);
    -- 00000000000000001111111111111111 Least significant 16 bits active
    Least_significant_16_bits_active : std_logic_vector(3 downto 0);
    -- 00000000000000000000000011111111 Least significant byte (8 bits) active
    Least_significant_byte_8_bits_active : std_logic_vector(3 downto 0);
    -- 11111111111111110000000000000000 Most significant 16 bits active
    Most_significant_16_bits_active : std_logic_vector(3 downto 0);
end record;

constant s_axi_wstrb : S_AXI_WSTRB_T := (
    All_bits_active => "1111",
    Least_significant_16_bits_active => "0011",
    Least_significant_byte_8_bits_active => "0001",
    Most_significant_16_bits_active => "1100"
);

type s_axi_DWORD_ARRAY is array (natural range <>) of std_logic_vector(31 downto 0);
constant s_axi_wstrb_to_mask : s_axi_DWORD_ARRAY(0 to  15 ) := (
    0  => x"00000000",
    1  => x"000000FF",
    2  => x"0000FF00",
    3  => x"0000FFFF",
    4  => x"00FF0000",
    5  => x"00FF00FF",
    6  => x"00FFFF00",
    7  => x"00FFFFFF",
    8  => x"FF000000",
    9  => x"FF0000FF",
    10 => x"FF00FF00",
    11 => x"FF00FFFF",
    12 => x"FFFF0000",
    13 => x"FFFF00FF",
    14 => x"FFFFFF00",
    15 => x"FFFFFFFF"
);


type optional_slv_32 is record
    data : std_logic_vector(31 downto 0);
    valid : std_logic;
end record;

constant optional_slv_32_null : optional_slv_32 := (
    data => (others => '0' ),
    valid => '0'
);

type AXI4LITE_slave is record
   rx : AXI4LITE;
   read_addr : optional_slv_32;


   write_addr : optional_slv_32;
   write_data : optional_slv_32;
end record;

    constant AXI4LITE_slave_null : AXI4LITE_slave := (
        rx => AXI4LITE_null,
        read_addr => optional_slv_32_null,
        write_addr => optional_slv_32_null,
        write_data => optional_slv_32_null

    );


    procedure pull(self: inout AXI4LITE_slave ; signal  m2s : in  AXI4LITE_m2s);
    procedure push(self: inout AXI4LITE_slave ; signal  s2m : out AXI4LITE_s2m);

    function  is_requesting_data(self:  AXI4LITE_slave) return boolean;
    procedure get_read_address(self: inout AXI4LITE_slave ; address : out std_logic_vector(31 downto 0));
    procedure get_read_address_s(self: inout AXI4LITE_slave ;signal address : out std_logic_vector(31 downto 0));
    procedure set_read_data(self: inout AXI4LITE_slave ; data :  in std_logic_vector(31 downto 0));

    function  is_receiving_data(self:  AXI4LITE_slave ) return boolean;
    procedure get_write_data(self: inout AXI4LITE_slave ; addr :  out std_logic_vector(31 downto 0);  data :  out std_logic_vector(31 downto 0));
    
    procedure get_write_data_s(
        self: inout AXI4LITE_slave ; 
        signal addr :  out std_logic_vector(31 downto 0);  
        signal data :  out std_logic_vector(31 downto 0)
        );

end package;

package body AXI4LITE_pac is

    function AXI4LITE_m2s_serialize(self : AXI4LITE_m2s) return std_logic_vector is 
        variable S_AXI_AR : AXI4_lite_Read_Address_Channel_m2s_serial := (others => '0');
        variable S_AXI_AW : AXI4_lite_write_Address_Channel_m2s_serial := (others => '0');
        variable S_AXI_B  : AXI4_lite_Write_Response_Channel_m2s_serial := (others => '0');
        variable S_AXI_R  : AXI4_lite_Read_Data_Channel_m2s_serial := (others => '0');
        variable S_AXI_W  : AXI4_lite_Write_Data_Channel_m2s_serial := (others => '0');
    begin 
        S_AXI_AR    := self.S_AXI_AR.S_AXI_ARVALID & self.S_AXI_AR.S_AXI_ARADDR;
        S_AXI_AW    := self.S_AXI_AW.S_AXI_AWVALID & self.S_AXI_AW.S_AXI_AWADDR ;
        S_AXI_B(0)  := self.S_AXI_B.S_AXI_BREADY;
        S_AXI_R(0)  := self.S_AXI_R.S_AXI_RREADY;
        S_AXI_W     := self.S_AXI_W.S_AXI_WVALID & self.S_AXI_W.S_AXI_WSTRB & self.S_AXI_W.S_AXI_WDATA; 
        return S_AXI_AR & S_AXI_AW & S_AXI_B & S_AXI_R & S_AXI_W;
    
    end function;

    function AXI4LITE_s2m_serialize(self : AXI4LITE_s2m) return std_logic_vector is 
        variable  S_AXI_AR :  AXI4_lite_Read_Address_Channel_s2m_serial := (others => '0');
        variable  S_AXI_AW :  AXI4_lite_write_Address_Channel_s2m_serial := (others => '0');
        variable  S_AXI_B  :  AXI4_lite_Write_Response_Channel_s2m_serial := (others => '0');
        variable  S_AXI_R  :  AXI4_lite_Read_Data_Channel_s2m_serial := (others => '0');
        variable  S_AXI_W  :  AXI4_lite_Write_Data_Channel_s2m_serial := (others => '0');
    begin 
        S_AXI_AR(0) := self.S_AXI_AR.S_AXI_ARREADY;
        S_AXI_AW(0) := self.S_AXI_AW.S_AXI_AWREADY;
        S_AXI_B     := self.S_AXI_B.S_AXI_BVALID & self.S_AXI_B.S_AXI_BRESP;
        S_AXI_R     := self.S_AXI_R.S_AXI_RVALID & self.S_AXI_R.S_AXI_RRESP &  self.S_AXI_R.S_AXI_RDATA;
        S_AXI_W(0)  := self.S_AXI_W.S_AXI_WREADY;
        return S_AXI_AR & S_AXI_AW & S_AXI_B & S_AXI_R & S_AXI_W;

    end function;


    function AXI4LITE_m2s_deserialize(self : std_logic_vector) return AXI4LITE_m2s is 
        variable ret: AXI4LITE_m2s := AXI4LITE_m2s_null;
        variable S_AXI_AR : AXI4_lite_Read_Address_Channel_m2s_serial := (others => '0');
        variable S_AXI_AW : AXI4_lite_write_Address_Channel_m2s_serial := (others => '0');
        variable S_AXI_B  : AXI4_lite_Write_Response_Channel_m2s_serial := (others => '0');
        variable S_AXI_R  : AXI4_lite_Read_Data_Channel_m2s_serial := (others => '0');
        variable S_AXI_W  : AXI4_lite_Write_Data_Channel_m2s_serial := (others => '0');
    begin 
        S_AXI_W  := self(                                                                       S_AXI_W'length - 1 downto                                                                   0);
        S_AXI_R  := self(                                                     S_AXI_R'length +  S_AXI_W'length - 1 downto                                                      S_AXI_W'length);
        S_AXI_B  := self(                                    S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto                                     S_AXI_R'length + S_AXI_W'length);
        S_AXI_AW := self(                  S_AXI_AW'length + S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto                   S_AXI_B'length +  S_AXI_R'length + S_AXI_W'length);
        S_AXI_AR := self(S_AXI_AR'length + S_AXI_AW'length + S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto S_AXI_AW'length + S_AXI_B'length +  S_AXI_R'length + S_AXI_W'length);

        ret.S_AXI_W.S_AXI_WDATA  := S_AXI_W(                                                                    ret.S_AXI_W.S_AXI_WDATA'length - 1 downto                                                                0);
        ret.S_AXI_W.S_AXI_WSTRB  := S_AXI_W(                                   ret.S_AXI_W.S_AXI_WSTRB'length + ret.S_AXI_W.S_AXI_WDATA'length - 1 downto                                   ret.S_AXI_W.S_AXI_WDATA'length);
        ret.S_AXI_W.S_AXI_WVALID := S_AXI_W(                              1 +  ret.S_AXI_W.S_AXI_WSTRB'length + ret.S_AXI_W.S_AXI_WDATA'length - 1);

        ret.S_AXI_R.S_AXI_RREADY  := S_AXI_R(0);

        ret.S_AXI_B.S_AXI_BREADY  := S_AXI_B(0);

        ret.S_AXI_AW.S_AXI_AWADDR  := S_AXI_AW(ret.S_AXI_AW.S_AXI_AWADDR'length - 1 downto 0);
        ret.S_AXI_AW.S_AXI_AWVALID := S_AXI_AW(ret.S_AXI_AW.S_AXI_AWADDR'length);

        ret.S_AXI_AR.S_AXI_ARADDR  := S_AXI_AR(ret.S_AXI_AR.S_AXI_ARADDR'length - 1 downto 0);
        ret.S_AXI_AR.S_AXI_ARVALID := S_AXI_AR(ret.S_AXI_AR.S_AXI_ARADDR'length);
        
        return ret;
    end function;

    function AXI4LITE_s2m_deserialize(self : std_logic_vector) return AXI4LITE_s2m is 
        variable ret: AXI4LITE_s2m := AXI4LITE_s2m_null;
        variable S_AXI_AR : AXI4_lite_Read_Address_Channel_s2m_serial := (others => '0');
        variable S_AXI_AW : AXI4_lite_write_Address_Channel_s2m_serial := (others => '0');
        variable S_AXI_B  : AXI4_lite_Write_Response_Channel_s2m_serial := (others => '0');
        variable S_AXI_R  : AXI4_lite_Read_Data_Channel_s2m_serial := (others => '0');
        variable S_AXI_W  : AXI4_lite_Write_Data_Channel_s2m_serial := (others => '0');
    begin 
        S_AXI_W  := self(                                                                       S_AXI_W'length - 1 downto                                                                   0);
        S_AXI_R  := self(                                                     S_AXI_R'length +  S_AXI_W'length - 1 downto                                                      S_AXI_W'length);
        S_AXI_B  := self(                                    S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto                                     S_AXI_R'length + S_AXI_W'length);
        S_AXI_AW := self(                  S_AXI_AW'length + S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto                   S_AXI_B'length +  S_AXI_R'length + S_AXI_W'length);
        S_AXI_AR := self(S_AXI_AR'length + S_AXI_AW'length + S_AXI_B'length + S_AXI_R'length +  S_AXI_W'length - 1 downto S_AXI_AW'length + S_AXI_B'length +  S_AXI_R'length + S_AXI_W'length);

        ret.S_AXI_W.S_AXI_WREADY := S_AXI_W(0);
        
        ret.S_AXI_R.S_AXI_RDATA  := S_AXI_R(                                                                    ret.S_AXI_R.S_AXI_RDATA'length - 1 downto                                                                0);
        ret.S_AXI_R.S_AXI_RRESP  := S_AXI_R(                                   ret.S_AXI_R.S_AXI_RRESP'length + ret.S_AXI_R.S_AXI_RDATA'length - 1 downto                                   ret.S_AXI_R.S_AXI_RDATA'length);
        ret.S_AXI_R.S_AXI_RVALID := S_AXI_R(                           1 +     ret.S_AXI_R.S_AXI_RRESP'length + ret.S_AXI_R.S_AXI_RDATA'length - 1 );

        ret.S_AXI_B.S_AXI_BRESP  := S_AXI_B(                                                                    ret.S_AXI_B.S_AXI_BRESP'length - 1 downto                                                                0);
        ret.S_AXI_B.S_AXI_BVALID := S_AXI_B(                                                                1+  ret.S_AXI_B.S_AXI_BRESP'length - 1);
        
        ret.S_AXI_AW.S_AXI_AWREADY := S_AXI_AW(0);
        ret.S_AXI_AR.S_AXI_ARREADY := S_AXI_AR(0);
        
        return ret;
    end function;

    procedure pull(self: inout AXI4LITE_slave ; signal  m2s : in  AXI4LITE_m2s) is 
    begin 
        self.rx.S_AXI_AR_m2s := m2s.S_AXI_AR;
        self.rx.S_AXI_R_m2s  := m2s.S_AXI_R;
        self.rx.S_AXI_AW_m2s  := m2s.S_AXI_AW;
        self.rx.S_AXI_W_m2s  := m2s.S_AXI_W;
        self.rx.S_AXI_B_m2s  := m2s.S_AXI_B;

        if self.rx.S_AXI_R_m2s.S_AXI_RREADY = '1' then 
            self.rx.S_AXI_R_s2m.S_AXI_RVALID  := '0';
            self.rx.S_AXI_R_s2m.S_AXI_RDATA   := (others =>  '0');
        end if;

        if self.rx.S_AXI_B_m2s.S_AXI_BREADY = '1' then 
            self.rx.S_AXI_B_s2m.S_AXI_BRESP  := (others =>  '0');
            self.rx.S_AXI_B_s2m.S_AXI_BVALID  := '0';
        end if;

        if self.rx.S_AXI_AR_m2s.S_AXI_ARVALID ='1' and self.rx.S_AXI_AR_s2m.S_AXI_ARREADY = '1' then 
            self.read_addr.data := self.rx.S_AXI_AR_m2s.S_AXI_ARADDR;
            self.read_addr.valid := '1';
        end if;

        
        if self.rx.S_AXI_B_s2m.S_AXI_BVALID = '0' and self.rx.S_AXI_AW_m2s.S_AXI_AWVALID ='1' and self.rx.S_AXI_AW_s2m.S_AXI_AWREADY = '1' then 
            self.write_addr.data := self.rx.S_AXI_AW_m2s.S_AXI_AWADDR;
            self.write_addr.valid := '1';
        end if;
        
        
        if self.rx.S_AXI_B_s2m.S_AXI_BVALID = '0' and self.rx.S_AXI_W_m2s.S_AXI_WVALID ='1' and self.rx.S_AXI_W_s2m.S_AXI_WREADY = '1' then 
            self.write_data.data := self.rx.S_AXI_W_m2s.S_AXI_WDATA 
                                                and 
                                    s_axi_wstrb_to_mask(to_integer(unsigned(self.rx.S_AXI_W_m2s.S_AXI_WSTRB )));
            self.write_data.valid := '1';
        end if;
		  


    end procedure;

    procedure push(self: inout AXI4LITE_slave ; signal  s2m : out AXI4LITE_s2m) is 
    begin 


        self.rx.S_AXI_AR_s2m.S_AXI_ARREADY := not self.read_addr.valid;
        self.rx.S_AXI_AW_s2m.S_AXI_AWREADY :=
                                                 (not self.write_addr.valid and not self.rx.S_AXI_B_s2m.S_AXI_BVALID) 
                                               ;

        self.rx.S_AXI_W_s2m.S_AXI_WREADY   := 
                                                 (not self.write_data.valid and not self.rx.S_AXI_B_s2m.S_AXI_BVALID) 
                                               ;


        s2m.S_AXI_AR <= self.rx.S_AXI_AR_s2m;
        s2m.S_AXI_R  <= self.rx.S_AXI_R_s2m;
        s2m.S_AXI_AW <= self.rx.S_AXI_AW_s2m;
        s2m.S_AXI_W  <= self.rx.S_AXI_W_s2m;
        s2m.S_AXI_B  <= self.rx.S_AXI_B_s2m;
    end procedure;

    function  is_requesting_data(self:  AXI4LITE_slave) return boolean is 
    begin
        return  self.read_addr.valid = '1' and self.rx.S_AXI_R_s2m.S_AXI_RVALID = '0';
    end function;

    procedure get_read_address(self: inout AXI4LITE_slave ; address : out std_logic_vector(31 downto 0)) is 
    begin 
        address := self.read_addr.data;
        self.read_addr.valid := '0';
    end procedure;


    procedure get_read_address_s(self: inout AXI4LITE_slave ;signal address : out std_logic_vector(31 downto 0)) is 
    begin 
        address <= self.read_addr.data;
        self.read_addr.valid := '0';
    end procedure;


    procedure set_read_data(self: inout AXI4LITE_slave ; data :  in std_logic_vector(31 downto 0)) is 
    begin 
        self.rx.S_AXI_R_s2m.S_AXI_RDATA  := data;
        self.rx.S_AXI_R_s2m.S_AXI_RVALID := '1';
    
    end procedure;


    function  is_receiving_data(self:  AXI4LITE_slave ) return boolean is 
    begin 
        return self.write_addr.valid = '1' and self.write_data.valid = '1';
    end function;


    procedure get_write_data(self: inout AXI4LITE_slave ; addr :  out std_logic_vector(31 downto 0);  data :  out std_logic_vector(31 downto 0)) is 
    begin 
        addr := self.write_addr.data;
        self.write_addr.valid := '0';

        data := self.write_data.data;
        self.write_data.valid := '0';
        
        self.rx.S_AXI_B_s2m.S_AXI_BRESP := AXI4_lite_Response_Signalling.OKAY;
        self.rx.S_AXI_B_s2m.S_AXI_BVALID := '1';

    end procedure;


    procedure get_write_data_s(self: inout AXI4LITE_slave ; signal addr :  out std_logic_vector(31 downto 0);  signal data :  out std_logic_vector(31 downto 0) ) is 
    begin
    
        addr <= self.write_addr.data;
        self.write_addr.valid := '0';

        data <= self.write_data.data;
        self.write_data.valid := '0';
        self.rx.S_AXI_B_s2m.S_AXI_BRESP := AXI4_lite_Response_Signalling.OKAY;
        self.rx.S_AXI_B_s2m.S_AXI_BVALID := '1';
    
    end procedure;


    function AXI4LITE_s2m_length(AXI4LITE_RDATA_WIDTH : integer) return integer is
    begin 
        return 1
        +  AXI4LITE_RDATA_WIDTH 
        + 1 
        + 2 
        + 1 
        + 1 
        + 2 
        + 1 ;
    end function;


    function AXI4LITE_m2s_length(AXI4LITE_RDATA_WIDTH : integer; AXI4LITE_ADDR_WIDTH : integer ) return integer is 
    begin 

        return     
        AXI4LITE_ADDR_WIDTH 
        + 1
        + 1
        + AXI4LITE_ADDR_WIDTH
        + 1
        + AXI4LITE_RDATA_WIDTH
        + 1  
        + 4 
        + 1  ;
    end function;


end package body;