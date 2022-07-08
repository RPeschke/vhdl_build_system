library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  use work.AXI4LITE_pac.all;


entity axi4_lite_custom_vs_xilinx_wrap is

  port (
        clk : in std_logic;
        

        xilinx_mode : in std_logic;
        
        S_AXI_ARESETN	: in std_logic;

        rx_m2s : in AXI4LITE_m2s;
        rx_s2m : out AXI4LITE_s2m;
        
        slv_reg0_o	: out  std_logic_vector(32-1 downto 0);
	    slv_reg1_o	: out  std_logic_vector(32-1 downto 0);
	    slv_reg2_o  : out  std_logic_vector(32-1 downto 0);
	    slv_reg3_o  : out  std_logic_vector(32-1 downto 0)
  );
end entity;

architecture rtl of axi4_lite_custom_vs_xilinx_wrap is
  
begin




dut : entity work.axi4_lite_custom_vs_xilinx port map (
        clk => clk,


        xilinx_mode => xilinx_mode,
		--S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	=> S_AXI_ARESETN,
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR =>rx_m2s.S_AXI_AW.S_AXI_AWADDR ,
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	=> (others =>'0'),
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	=>  rx_m2s.S_AXI_AW.S_AXI_AWVALID ,
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	=> rx_s2m.S_AXI_AW.S_AXI_AWREADY,
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	=>    rx_m2s.S_AXI_W.S_AXI_WDATA,
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB =>     rx_m2s.S_AXI_W.S_AXI_WSTRB,
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	=> rx_m2s.S_AXI_W.S_AXI_WVALID,
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	=> rx_s2m.S_AXI_W.S_AXI_WREADY,
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	=> rx_s2m.S_AXI_B.S_AXI_BRESP,
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	=> rx_s2m.S_AXI_B.S_AXI_BVALID,
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	=> rx_m2s.S_AXI_B.S_AXI_BREADY ,
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	=>  rx_m2s.S_AXI_AR.S_AXI_ARADDR ,

		S_AXI_ARPROT	=> (others =>'0'),

		S_AXI_ARVALID	=>    rx_m2s.S_AXI_AR.S_AXI_ARVALID ,

		S_AXI_ARREADY	=> rx_s2m.S_AXI_AR.S_AXI_ARREADY,


		S_AXI_RDATA	=> rx_s2m.S_AXI_R.S_AXI_RDATA,
		
		S_AXI_RRESP	=>rx_s2m.S_AXI_R.S_AXI_RRESP,
		
		S_AXI_RVALID	=> rx_s2m.S_AXI_R.S_AXI_RVALID,
		
		S_AXI_RREADY	=> rx_m2s.S_AXI_R.S_AXI_RREADY,


        slv_reg0_o	=> slv_reg0_o,
	    slv_reg1_o	=> slv_reg1_o,
	    slv_reg2_o  => slv_reg2_o,
	    slv_reg3_o  => slv_reg3_o
	);


end architecture;