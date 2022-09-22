library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.AXI4LITE_pac.all;


entity exporter_v2_0 is port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(AXI4LITE_ADDR_IN_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(AXI4LITE_RDATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((AXI4LITE_RDATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(AXI4LITE_ADDR_IN_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(AXI4LITE_RDATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

        -- Ports of Axi Master Bus Interface name   
        m00_axi_m2s  : out std_logic_vector(AXI4LITE_steering_signals_m2s_length  + AXI4LITE_ADDR_WIDTH +AXI4LITE_ADDR_WIDTH +AXI4LITE_RDATA_WIDTH downto  0) := (others => '0');
        m00_axi_s2m  : in  std_logic_vector(AXI4LITE_steering_signals_s2m_length  + AXI4LITE_RDATA_WIDTH                                           downto  0)  := (others => '0')
		
	);
end exporter_v2_0;

architecture arch_imp of exporter_v2_0 is
signal C_M00_AXI_m2s : AXI4LITE_m2s := AXI4LITE_m2s_null;
signal C_M00_AXI_s2m : AXI4LITE_s2m := AXI4LITE_s2m_null;
begin
C_M00_AXI_m2s.S_AXI_AR.S_AXI_ARADDR(s00_AXI_ARADDR'range) <= s00_AXI_ARADDR;
C_M00_AXI_m2s.S_AXI_AR.S_AXI_ARVALID                      <= s00_AXI_ARVALID;

C_M00_AXI_m2s.S_AXI_AW.S_AXI_AWADDR(S00_AXI_AWADDR'range)  <= S00_AXI_AWADDR;
C_M00_AXI_m2s.S_AXI_AW.S_AXI_AWVALID   <= s00_AXI_AWVALID;

C_M00_AXI_m2s.S_AXI_B.S_AXI_BREADY   <= s00_AXI_BREADY;

C_M00_AXI_m2s.S_AXI_R.S_AXI_RREADY  <= s00_AXI_RREADY;

C_M00_AXI_m2s.S_AXI_W.S_AXI_WDATA(s00_axi_wdata'range)  <= s00_AXI_WDATA;
C_M00_AXI_m2s.S_AXI_W.S_AXI_WSTRB   <= s00_AXI_WSTRB;
C_M00_AXI_m2s.S_AXI_W.S_AXI_WVALID    <= s00_AXI_WVALID ;



m00_axi_m2s <= AXI4LITE_m2s_serialize(C_M00_AXI_m2s);

C_M00_AXI_s2m <= AXI4LITE_s2m_deserialize(m00_axi_s2m);


S00_AXI_ARREADY   <=  C_M00_AXI_s2m.S_AXI_AR.S_AXI_ARREADY;

S00_AXI_AWREADY   <=  C_M00_AXI_s2m.S_AXI_AW.S_AXI_AWREADY ;

s00_AXI_BRESP     <=  C_M00_AXI_s2m.S_AXI_B.S_AXI_BRESP  ;
s00_AXI_BVALID    <=  C_M00_AXI_s2m.S_AXI_B.S_AXI_BVALID ;

s00_AXI_RDATA     <=  C_M00_AXI_s2m.S_AXI_R.S_AXI_RDATA(s00_AXI_RDATA'range) ;
s00_AXI_RRESP     <=  C_M00_AXI_s2m.S_AXI_R.S_AXI_RRESP  ;
s00_AXI_RVALID    <=  C_M00_AXI_s2m.S_AXI_R.S_AXI_RVALID   ;

s00_AXI_WREADY    <=  C_M00_AXI_s2m.S_AXI_W.S_AXI_WREADY   ;

 
end arch_imp;
