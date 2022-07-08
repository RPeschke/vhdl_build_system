library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.AXI4LITE_pac.all;


entity axi4_lite_custom_vs_xilinx is
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
        clk : in std_logic;


        xilinx_mode : in std_logic;
		--S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(31 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((32/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(31 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic;


        slv_reg0_o	: out  std_logic_vector(32-1 downto 0);
	    slv_reg1_o	: out  std_logic_vector(32-1 downto 0);
	    slv_reg2_o  : out  std_logic_vector(32-1 downto 0);
	    slv_reg3_o  : out  std_logic_vector(32-1 downto 0)
	);
end entity;

architecture rtl of axi4_lite_custom_vs_xilinx is

        constant C_S_AXI_ADDR_WIDTH: integer := 32;
        constant C_S_AXI_DATA_WIDTH: integer := 32;

		signal xi_S_AXI_ACLK	:  std_logic;
		
		signal xi_S_AXI_ARESETN	:  std_logic;
		
		signal xi_S_AXI_AWADDR	:  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		
		signal xi_S_AXI_AWPROT	:  std_logic_vector(2 downto 0);
		
		signal xi_S_AXI_AWVALID	:  std_logic;
		
		signal xi_S_AXI_AWREADY	:  std_logic;
		
		signal xi_S_AXI_WDATA	:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		
		signal xi_S_AXI_WSTRB	:  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		
		signal xi_S_AXI_WVALID	:  std_logic;
		
		signal xi_S_AXI_WREADY	:  std_logic;
		
		signal xi_S_AXI_BRESP	:  std_logic_vector(1 downto 0);
		
		signal xi_S_AXI_BVALID	:  std_logic;
		
    	
		signal xi_S_AXI_BREADY	:  std_logic;
		
		signal xi_S_AXI_ARADDR	:  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		
		signal xi_S_AXI_ARPROT	:  std_logic_vector(2 downto 0);
		
		signal xi_S_AXI_ARVALID	: std_logic;
		
		signal xi_S_AXI_ARREADY	:  std_logic;
		
		signal xi_S_AXI_RDATA	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		
		signal xi_S_AXI_RRESP	:  std_logic_vector(1 downto 0);
		
		signal xi_S_AXI_RVALID	: std_logic;
		
		signal xi_S_AXI_RREADY	:  std_logic;
        signal xi_slv_reg0_o	:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal xi_slv_reg1_o	:  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal xi_slv_reg2_o  :   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal xi_slv_reg3_o  :   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);


        signal rst :  std_logic;

        signal rx_m2s :  AXI4LITE_m2s;
        signal rx_s2m :  AXI4LITE_s2m;

        signal ARADDR :   optional_slv_32;
        signal R_DATA :    optional_slv_32;
        
        signal AWADDR :   optional_slv_32;
        signal AWDATA :   optional_slv_32;

        signal co_slv_reg0_o  :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal co_slv_reg1_o  :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal co_slv_reg2_o  :   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    signal co_slv_reg3_o  :   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
begin 
    xi_S_AXI_ARESETN <= S_AXI_ARESETN;
    rst  <= not xi_S_AXI_ARESETN;
    
    rx_m2s.S_AXI_AR.S_AXI_ARADDR  <= S_AXI_ARADDR  when   xilinx_mode = '0' else (others =>'0');
    rx_m2s.S_AXI_AR.S_AXI_ARVALID <= S_AXI_ARVALID when   xilinx_mode = '0' else '0';
    
    rx_m2s.S_AXI_AW.S_AXI_AWADDR  <= S_AXI_AWADDR  when   xilinx_mode = '0' else (others =>'0');
    rx_m2s.S_AXI_AW.S_AXI_AWVALID <= S_AXI_AWVALID when   xilinx_mode = '0' else '0';

    rx_m2s.S_AXI_B.S_AXI_BREADY   <= S_AXI_BREADY  when   xilinx_mode = '0' else '0';
    
    rx_m2s.S_AXI_R.S_AXI_RREADY   <= S_AXI_RREADY  when   xilinx_mode = '0' else '0';
    
    rx_m2s.S_AXI_W.S_AXI_WDATA    <= S_AXI_WDATA   when   xilinx_mode = '0' else (others =>'0');
    rx_m2s.S_AXI_W.S_AXI_WSTRB    <= S_AXI_WSTRB   when   xilinx_mode = '0' else (others =>'0');
    rx_m2s.S_AXI_W.S_AXI_WVALID   <= S_AXI_WVALID  when   xilinx_mode = '0' else '0';


    xi_S_AXI_ARADDR  <= S_AXI_ARADDR  when   xilinx_mode = '1' else (others =>'0');
    xi_S_AXI_ARVALID <= S_AXI_ARVALID when   xilinx_mode = '1' else '0';
    
    xi_S_AXI_AWADDR  <= S_AXI_AWADDR  when   xilinx_mode = '1' else (others =>'0');
    xi_S_AXI_AWVALID <= S_AXI_AWVALID when   xilinx_mode = '1' else '0';

    xi_S_AXI_BREADY   <= S_AXI_BREADY  when   xilinx_mode = '1' else '0';
    
    xi_S_AXI_RREADY   <= S_AXI_RREADY  when   xilinx_mode = '1' else '0';
    
    xi_S_AXI_WDATA    <= S_AXI_WDATA   when   xilinx_mode = '1' else (others =>'0');
    xi_S_AXI_WSTRB    <= S_AXI_WSTRB   when   xilinx_mode = '1' else (others =>'0');
    xi_S_AXI_WVALID   <= S_AXI_WVALID  when   xilinx_mode = '1' else '0';



    S_AXI_ARREADY <= rx_s2m.S_AXI_AR.S_AXI_ARREADY when   xilinx_mode = '0' else xi_S_AXI_ARREADY;
    
    S_AXI_AWREADY <= rx_s2m.S_AXI_AW.S_AXI_AWREADY when   xilinx_mode = '0' else xi_S_AXI_AWREADY;
    
    S_AXI_BRESP <= rx_s2m.S_AXI_B.S_AXI_BRESP when   xilinx_mode = '0' else xi_S_AXI_BRESP;
    S_AXI_BVALID <= rx_s2m.S_AXI_B.S_AXI_BVALID when   xilinx_mode = '0' else xi_S_AXI_BVALID;

    S_AXI_RDATA <= rx_s2m.S_AXI_R.S_AXI_RDATA when   xilinx_mode = '0' else xi_S_AXI_RDATA;
    S_AXI_RRESP <= rx_s2m.S_AXI_R.S_AXI_RRESP when   xilinx_mode = '0' else xi_S_AXI_RRESP;
    S_AXI_RVALID <= rx_s2m.S_AXI_R.S_AXI_RVALID when   xilinx_mode = '0' else xi_S_AXI_RVALID;


    S_AXI_WREADY <= rx_s2m.S_AXI_W.S_AXI_WREADY when   xilinx_mode = '0' else xi_S_AXI_WREADY;
    
    
    slv_reg0_o <= co_slv_reg0_o  when   xilinx_mode = '0' else xi_slv_reg0_o;
    slv_reg1_o <= co_slv_reg1_o  when   xilinx_mode = '0' else xi_slv_reg1_o;
    slv_reg2_o <= co_slv_reg2_o  when   xilinx_mode = '0' else xi_slv_reg2_o;
    slv_reg3_o <= co_slv_reg3_o  when   xilinx_mode = '0' else xi_slv_reg3_o;


    u_custom: entity work.axi4lite_slave_example port map (
        clk => clk,
        rst=>rst,

        rx_m2s=>rx_m2s,
        rx_s2m=>rx_s2m,

      --  ARADDR=>ARADDR,
      --  R_DATA =>R_DATA,
        
    --    AWADDR=>AWADDR,
     --  AWDATA =>AWDATA,
        
        slv_reg0_o	 => co_slv_reg0_o,
        slv_reg1_o	 => co_slv_reg1_o,
        slv_reg2_o   => co_slv_reg2_o,
        slv_reg3_o   => co_slv_reg3_o
  );


u_xilinx: entity work.AXI4_slave_example_xilinx 
	generic map (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH=>C_S_AXI_DATA_WIDTH,
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH=>C_S_AXI_ADDR_WIDTH
	)

	port map(
		S_AXI_ACLK	=> clk,

		S_AXI_ARESETN	=> xi_S_AXI_ARESETN,

		S_AXI_AWADDR => xi_S_AXI_AWADDR,

		S_AXI_AWPROT =>xi_S_AXI_AWPROT,

		S_AXI_AWVALID => xi_S_AXI_AWVALID,

		S_AXI_AWREADY=> xi_S_AXI_AWREADY,

		S_AXI_WDATA=> xi_S_AXI_WDATA,

		S_AXI_WSTRB=>xi_S_AXI_WSTRB,

		S_AXI_WVALID=>xi_S_AXI_WVALID,

		S_AXI_WREADY=>xi_S_AXI_WREADY,

		S_AXI_BRESP=>xi_S_AXI_BRESP,

		S_AXI_BVALID=>xi_S_AXI_BVALID,

		S_AXI_BREADY=>xi_S_AXI_BREADY,
		
		S_AXI_ARADDR=>xi_S_AXI_ARADDR,
		
		S_AXI_ARPROT=> xi_S_AXI_ARPROT,
		
		S_AXI_ARVALID=>xi_S_AXI_ARVALID,
		
		S_AXI_ARREADY=>xi_S_AXI_ARREADY,
		
		S_AXI_RDATA=> xi_S_AXI_RDATA,
		
		S_AXI_RRESP=>xi_S_AXI_RRESP,
		
		S_AXI_RVALID=>xi_S_AXI_RVALID,
		
		S_AXI_RREADY=>xi_S_AXI_RREADY,
        slv_reg0_o=>xi_slv_reg0_o,
	    slv_reg1_o=>xi_slv_reg1_o,
	    slv_reg2_o=>xi_slv_reg2_o,
	    slv_reg3_o=>xi_slv_reg3_o
	);

end architecture;