library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;
use work.UtilityPkg.all;

entity GtpS6 is
   generic (
      -- Reference clock selection --
      -- 000: CLK00/CLK01 selected
      -- 001: GCLK00/GCLK01 selected
      -- 010: PLLCLK00/PLLCLK01 selected
      -- 011: CLKINEAST0/CLKINEAST0 selected
      -- 100: CLK10/CLK11 selected
      -- 101: GCLK10/GCLK11 selected
      -- 110: PLLCLK10/PLLCLK11 selected
      -- 111: CLKINWEST0/CLKINWEST1 selected 
      REF_SEL_PLL0_G : slv(2 downto 0) := "001";
      REF_SEL_PLL1_G : slv(2 downto 0) := "001"
   );
   port (
      -- Clocking & reset
      gtpClkIn         :  in std_logic;
      gtpReset0        :  in std_logic;
      gtpReset1        :  in std_logic;
      txReset0         :  in std_logic;
      txReset1         :  in std_logic;
      rxReset0         :  in std_logic;
      rxReset1         :  in std_logic;
      rxBufReset0      :  in std_logic;
      rxBufReset1      :  in std_logic;
      -- User clock out
      usrClkOut        : out std_logic;
      usrClkX2Out      : out std_logic;
      -- DCM clocking
      dcmClkValid      : out std_logic;
      dcmSpLocked      : out std_logic;
      usrClkValid      : out std_logic;
      usrClkLocked     : out std_logic;
      -- General status outputs
      pllLock0         : out std_logic;
      pllLock1         : out std_logic;
      gtpResetDone0    : out std_logic;
      gtpResetDone1    : out std_logic;
      -- Input signals (raw)
      gtpRxP0          :  in std_logic;
      gtpRxN0          :  in std_logic;
      gtpTxP0          : out std_logic;
      gtpTxN0          : out std_logic;
      gtpRxP1          :  in std_logic;
      gtpRxN1          :  in std_logic;
      gtpTxP1          : out std_logic;
      gtpTxN1          : out std_logic;
      -- Data interfaces
      rxDataOut0       : out std_logic_vector(15 downto 0);
      rxDataOut1       : out std_logic_vector(15 downto 0);
      txDataIn0        :  in std_logic_vector(15 downto 0);
      txDataIn1        :  in std_logic_vector(15 downto 0);
      -- RX status
      rxCharIsComma0   : out std_logic_vector(1 downto 0);
      rxCharIsComma1   : out std_logic_vector(1 downto 0);
      rxCharIsK0       : out std_logic_vector(1 downto 0);
      rxCharIsK1       : out std_logic_vector(1 downto 0);
      rxDispErr0       : out std_logic_vector(1 downto 0);
      rxDispErr1       : out std_logic_vector(1 downto 0);
      rxNotInTable0    : out std_logic_vector(1 downto 0);
      rxNotInTable1    : out std_logic_vector(1 downto 0);
      rxRunDisp0       : out std_logic_vector(1 downto 0);
      rxRunDisp1       : out std_logic_vector(1 downto 0);
      rxClkCor0        : out std_logic_vector(2 downto 0);
      rxClkCor1        : out std_logic_vector(2 downto 0);
      rxByteAligned0   : out std_logic;
      rxByteAligned1   : out std_logic;
      rxEnMCommaAlign0 :  in std_logic;
      rxEnMCommaAlign1 :  in std_logic;
      rxEnPCommaAlign0 :  in std_logic;
      rxEnPCommaAlign1 :  in std_logic;
      rxBufStatus0     : out std_logic_vector(2 downto 0);
      rxBufStatus1     : out std_logic_vector(2 downto 0);
      -- TX status
      txCharDispMode0  :  in std_logic_vector(1 downto 0) := "00";
      txCharDispMode1  :  in std_logic_vector(1 downto 0) := "00";
      txCharDispVal0   :  in std_logic_vector(1 downto 0) := "00";
      txCharDispVal1   :  in std_logic_vector(1 downto 0) := "00";
      txCharIsK0       :  in std_logic_vector(1 downto 0);
      txCharIsK1       :  in std_logic_vector(1 downto 0);
      txRunDisp0       : out std_logic_vector(1 downto 0);
      txRunDisp1       : out std_logic_vector(1 downto 0);
      txBufStatus0     : out std_logic_vector(1 downto 0);
      txBufStatus1     : out std_logic_vector(1 downto 0);
      -- Loopback settings
      loopbackIn0   :  in std_logic_vector(2 downto 0) := "000";
      loopbackIn1   :  in std_logic_vector(2 downto 0) := "000"
   );
end GtpS6;

architecture rtl of GtpS6 is

   constant slZero       : std_logic := '0';
   -- Reference clock selection --
   -- 000: CLK00/CLK01 selected
   -- 001: GCLK00/GCLK01 selected
   -- 010: PLLCLK00/PLLCLK01 selected
   -- 011: CLKINEAST0/CLKINEAST0 selected
   -- 100: CLK10/CLK11 selected
   -- 101: GCLK10/GCLK11 selected
   -- 110: PLLCLK10/PLLCLK11 selected
   -- 111: CLKINWEST0/CLKINWEST1 selected 
   -- constant refSelDyPll0 : std_logic_vector(2 downto 0) := "001";
   -- constant refSelDyPll1 : std_logic_vector(2 downto 0) := "001";

   -- DCM signals
   signal clk0                 : std_logic;
   signal clkOut1              : std_logic;
   signal clkDv                : std_logic;
   signal dcmInputClockStopped : std_logic;
   signal clkIn1  : std_logic;
   signal clkFbIn : std_logic; 
   signal gclkDcm : std_logic;

   signal dcmSpStatus         : std_logic_vector(7 downto 0);
   signal dcmSpLockedInternal : std_logic;

   signal usrClkStatus         : std_logic_vector(7 downto 0);
   signal usrClkLockedInternal : std_logic;

   signal pllLock0Internal : std_logic;
   signal pllLock1Internal : std_logic;

   signal rxClkCorr0 : std_logic_vector(2 downto 0);
   signal rxClkCorr1 : std_logic_vector(2 downto 0);

   -- User clocking
   signal gtpClkOut0 : std_logic_vector(1 downto 0);
   signal gtpClkOut1 : std_logic_vector(1 downto 0);
   signal txOutClk0  : std_logic;
   signal txOutClk1  : std_logic;

   signal usrClkSource     : std_logic;
   signal usrClkSourceBufG : std_logic;
   signal txRxUsrClkRaw    : std_logic;
   signal txRxUsrClk2Raw   : std_logic;
   signal txRxUsrClk       : std_logic;
   signal txRxUsrClk2      : std_logic;

   signal usrClkX2Raw      : std_logic;

begin
--   -- Set up input clocking here
--   U_S6_DCM : DCM_SP
--      generic map (
--         CLKDV_DIVIDE       => 2.000,
--         CLKFX_DIVIDE       => 1,
--         CLKFX_MULTIPLY     => 4,
--         CLKIN_DIVIDE_BY_2  => false,
--         CLKIN_PERIOD       => 4.0,
--         CLKOUT_PHASE_SHIFT => "NONE",
--         CLK_FEEDBACK       => "1X",
--         DESKEW_ADJUST      => "SYSTEM_SYNCHRONOUS",
--         PHASE_SHIFT        => 0,
--         STARTUP_WAIT       => false
--      )
--      port map (
--         
----         CLKIN    => clkIn1,
--         CLKIN    => gtpClkIn,
--         CLKFB    => clkFbIn,
--         -- Output clocks
--         CLK0     => clk0,
--         CLK90    => open,
--         CLK180   => open,
--         CLK270   => open,
--         CLK2X    => open,
--         CLK2X180 => open,
--         CLKFX    => open,
--         CLKFX180 => open,
--         CLKDV    => clkDv,
--         -- Ports for dynamic phase shift
--         PSCLK    => '0',
--         PSEN     => '0',
--         PSINCDEC => '0',
--         PSDONE   => open,
--         -- Control & status
--         LOCKED   => dcmSpLockedInternal,
--         STATUS   => dcmSpStatus,
--         RST      => '0',
--         -- Unused, tie low
--         DSSEN    => '0'
--      );
--   dcmInputClockStopped <= dcmSpStatus(1);
--   dcmSpLocked          <= dcmSpLockedInternal;
--   dcmClkValid          <= dcmSpLockedInternal and (not dcmSpStatus(1));
   dcmSpLocked <= '1';
	dcmClkValid <= '1';

----   U_DcmClkIn_BufG  : BUFG port map ( I => gtpClkIn, O => clkIn1  );
--   U_DcmFb_BufG     : BUFG port map ( I => clk0,     O => clkFbIn );
--   U_DcmClkOut_BufG : BUFG port map ( I => clkDv,    O => gClkDcm ); 

   -- Set up USR clocks (see UG386 p.  74 for TX)
   --                   (see UG386 p. 159 for RX)
   U_USRCLK_DCM : DCM_SP
      generic map (
         CLKDV_DIVIDE       => 2.000,
         CLKFX_DIVIDE       => 1,
         CLKFX_MULTIPLY     => 4,
         CLKIN_DIVIDE_BY_2  => false,
         CLKIN_PERIOD       => 8.0,
         CLKOUT_PHASE_SHIFT => "NONE",
         CLK_FEEDBACK       => "1X",
         DESKEW_ADJUST      => "SYSTEM_SYNCHRONOUS",
         PHASE_SHIFT        => 0,
         STARTUP_WAIT       => false
      )
      port map (
         CLKIN    => usrClkSource,
         CLKFB    => txRxUsrClk,
         -- Output clocks
         CLK0     => txRxUsrClkRaw,
         CLK90    => open,
         CLK180   => open,
         CLK270   => open,
         CLK2X    => open,
         CLK2X180 => open,
         CLKFX    => open,
         CLKFX180 => open,
         CLKDV    => txRxUsrClk2Raw,
         -- Ports for dynamic phase shift
         PSCLK    => '0',
         PSEN     => '0',
         PSINCDEC => '0',
         PSDONE   => open,
         -- Control & status
         LOCKED   => usrClkLockedInternal,
         STATUS   => usrClkStatus,
         RST      => not(pllLock1Internal),
         -- Unused, tie low
         DSSEN    => '0'
      );
	pllLock1             <= pllLock1Internal;
   pllLock0             <= pllLock0Internal;
   -- usrInputClockStopped <= usrClkStatus(1);
   usrClkLocked         <= usrClkLockedInternal;
   usrClkValid          <= usrClkLockedInternal and (not usrClkStatus(1));

   U_BufIo2          : BUFIO2 port map ( I => gtpClkOut0(0),  DIVCLK => usrClkSource );
--   U_usrClk_BufG     : BUFG   port map ( I => usrClkSource,   O => usrClkSourceBufG );
   U_UsrClkOut_BufG  : BUFG   port map ( I => txRxUsrClkRaw,  O => txRxUsrClk ); 
   U_UsrClk2Out_BufG : BUFG   port map ( I => txRxUsrClk2Raw, O => txRxUsrClk2 ); 

   usrClkX2Out <= txRxUsrClk;
--   U_UsrClkX2_BufG   : BUFG   port map ( I => usrClkX2Raw,    O => usrClkX2Out );

   -- Clock out to the rest of the system
   usrClkOut <= txRxUsrClk2;

   --------------------------
   -- Instantiate the tile --
   --------------------------
   U_GtpS6Tile : entity work.GtpS6Tile
      generic map (
         -- Simulation attributes
         TILE_SIM_GTPRESET_SPEEDUP => 0, -- Set to 1 to speed up sim reset
         TILE_CLK25_DIVIDER_0      => 5, 
         TILE_CLK25_DIVIDER_1      => 5,
         TILE_PLL_DIVSEL_FB_0      => 2,
         TILE_PLL_DIVSEL_FB_1      => 2,
         TILE_PLL_DIVSEL_REF_0     => 1,
         TILE_PLL_DIVSEL_REF_1     => 1,
         TILE_SIM_REFCLK0_SOURCE   => "000",
         TILE_SIM_REFCLK1_SOURCE   => "000",
         --
         TILE_PLL_SOURCE_0         => "PLL1",
         TILE_PLL_SOURCE_1         => "PLL1"
      )
      port map (
         ------------------------ Loopback and Powerdown Ports ----------------------
         LOOPBACK0_IN         => loopbackIn0,    --  in   std_logic_vector(2 downto 0);
         LOOPBACK1_IN         => loopbackIn1,    --  in   std_logic_vector(2 downto 0);
         --------------------------------- PLL Ports --------------------------------
         CLK00_IN             => slZero,         --  in   std_logic;
         CLK01_IN             => gtpClkIn,       --  in   std_logic;
         CLK10_IN             => slZero,         --  in   std_logic;
         CLK11_IN             => slZero,         --  in   std_logic;
         GCLK00_IN            => slZero,         --  in   std_logic;
         GCLK01_IN            => slZero,         --  in   std_logic;
         GCLK10_IN            => slZero,         --  in   std_logic;
         GCLK11_IN            => slZero,         --  in   std_logic;
         CLKINEAST0_IN        => slZero,         --  in   std_logic;
         CLKINEAST1_IN        => slZero,         --  in   std_logic;
         CLKINWEST0_IN        => slZero,         --  in   std_logic;
         CLKINWEST1_IN        => slZero,         --  in   std_logic;
         GTPRESET0_IN         => gtpReset0,      --  in   std_logic;
         GTPRESET1_IN         => gtpReset1,      --  in   std_logic;
         TXRESET0_IN          => txReset0,       --  in   std_logic;
         TXRESET1_IN          => txReset1,       --  in   std_logic;
         RXRESET0_IN          => rxReset0,       --  in   std_logic;
         RXRESET1_IN          => rxReset1,       --  in   std_logic;
         PLLLKDET0_OUT        => pllLock0Internal, --  out  std_logic;
         PLLLKDET1_OUT        => pllLock1Internal, --  out  std_logic;
         REFSELDYPLL0_IN      => REF_SEL_PLL0_G,   --  in   std_logic_vector(2 downto 0);
         REFSELDYPLL1_IN      => REF_SEL_PLL1_G,   --  in   std_logic_vector(2 downto 0);
         RESETDONE0_OUT       => gtpResetDone0,  --  out  std_logic;
         RESETDONE1_OUT       => gtpResetDone1,  --  out  std_logic;
         ----------------------- Receive Ports - 8b10b Decoder ----------------------
         RXCHARISCOMMA0_OUT   => rxCharIsComma0, --  out  std_logic_vector(1 downto 0);
         RXCHARISCOMMA1_OUT   => rxCharIsComma1, --  out  std_logic_vector(1 downto 0);
         RXCHARISK0_OUT       => rxCharIsK0,     --  out  std_logic_vector(1 downto 0);
         RXCHARISK1_OUT       => rxCharIsK1,     --  out  std_logic_vector(1 downto 0);
         RXDISPERR0_OUT       => rxDispErr0,     --  out  std_logic_vector(1 downto 0);
         RXDISPERR1_OUT       => rxDispErr1,     --  out  std_logic_vector(1 downto 0);
         RXNOTINTABLE0_OUT    => rxNotInTable0,  --  out  std_logic_vector(1 downto 0);
         RXNOTINTABLE1_OUT    => rxNotInTable1,  --  out  std_logic_vector(1 downto 0);
         RXRUNDISP0_OUT       => rxRunDisp0,     --  out  std_logic_vector(1 downto 0);
         RXRUNDISP1_OUT       => rxRunDisp1,     --  out  std_logic_vector(1 downto 0);
         --------------- Receive Ports - RX Buffer and Phase Alignment --------------
         RXBUFRESET0_IN       => rxBufReset0,    -- in   std_logic;
         RXBUFRESET1_IN       => rxBufReset1,    -- in   std_logic;
         RXBUFSTATUS0_OUT     => rxBufStatus0,   -- out  std_logic_vector(2 downto 0);
         RXBUFSTATUS1_OUT     => rxBufStatus1,   -- out  std_logic_vector(2 downto 0);
         ---------------------- Receive Ports - Clock Correction --------------------
         RXCLKCORCNT0_OUT     => rxClkCorr0,     --  out  std_logic_vector(2 downto 0);
         RXCLKCORCNT1_OUT     => rxClkCorr1,     --  out  std_logic_vector(2 downto 0);
         --------------- Receive Ports - Comma Detection and Alignment --------------
         RXBYTEISALIGNED0_OUT => rxByteAligned0,   --  out  std_logic;
         RXBYTEISALIGNED1_OUT => rxByteAligned1,   --  out  std_logic;
         RXENMCOMMAALIGN0_IN  => rxEnMCommaAlign0, --  in   std_logic;
         RXENMCOMMAALIGN1_IN  => rxEnMCommaAlign1, --  in   std_logic;
         RXENPCOMMAALIGN0_IN  => rxEnPCommaAlign0, --  in   std_logic;
         RXENPCOMMAALIGN1_IN  => rxEnPCommaAlign1, --  in   std_logic;
         ------------------- Receive Ports - RX Data Path interface -----------------
         RXDATA0_OUT          => rxDataOut0,  --  out  std_logic_vector(15 downto 0);
         RXDATA1_OUT          => rxDataOut1,  --  out  std_logic_vector(15 downto 0);
         RXUSRCLK0_IN         => txRxUsrClk,  --  in   std_logic;
         RXUSRCLK1_IN         => txRxUsrClk,  --  in   std_logic;
         RXUSRCLK20_IN        => txRxUsrClk2, --  in   std_logic;
         RXUSRCLK21_IN        => txRxUsrClk2, --  in   std_logic;
         ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
         RXN0_IN              => gtpRxN0,    --  in   std_logic;
         RXN1_IN              => gtpRxN1,    --  in   std_logic;
         RXP0_IN              => gtpRxP0,    --  in   std_logic;
         RXP1_IN              => gtpRxP1,    --  in   std_logic;
         ---------------------------- TX/RX Datapath Ports --------------------------
         GTPCLKOUT0_OUT       => gtpClkOut0, --  out  std_logic_vector(1 downto 0);
         GTPCLKOUT1_OUT       => gtpClkOut1, --  out  std_logic_vector(1 downto 0);
         ------------------- Transmit Ports - 8b10b Encoder Control -----------------
         TXCHARDISPMODE0_IN   => txCharDispMode0, --  in   std_logic_vector(1 downto 0);
         TXCHARDISPMODE1_IN   => txCharDispMode1, --  in   std_logic_vector(1 downto 0);
         TXCHARDISPVAL0_IN    => txCharDispVal0, --  in   std_logic_vector(1 downto 0);
         TXCHARDISPVAL1_IN    => txCharDispVal1, --  in   std_logic_vector(1 downto 0);
         TXCHARISK0_IN        => txCharIsK0, --  in   std_logic_vector(1 downto 0);
         TXCHARISK1_IN        => txCharIsK1, --  in   std_logic_vector(1 downto 0);
         TXRUNDISP0_OUT       => txRunDisp0, --  out  std_logic_vector(1 downto 0);
         TXRUNDISP1_OUT       => txRunDisp1, --  out  std_logic_vector(1 downto 0);
         --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
         TXBUFSTATUS0_OUT     => txBufStatus0, --  out  std_logic_vector(1 downto 0);
         TXBUFSTATUS1_OUT     => txBufStatus1, --  out  std_logic_vector(1 downto 0);
         ------------------ Transmit Ports - TX Data Path interface -----------------
         TXDATA0_IN           => txDataIn0, --  in   std_logic_vector(15 downto 0);
         TXDATA1_IN           => txDataIn1, --  in   std_logic_vector(15 downto 0);
         TXOUTCLK0_OUT        => txOutClk0, --  out  std_logic;
         TXOUTCLK1_OUT        => txOutClk1, --  out  std_logic;
         TXUSRCLK0_IN         => txRxUsrClk,  --  in   std_logic;
         TXUSRCLK1_IN         => txRxUsrClk,  --  in   std_logic;
         TXUSRCLK20_IN        => txRxUsrClk2, --  in   std_logic;
         TXUSRCLK21_IN        => txRxUsrClk2, --  in   std_logic;
         --------------- Transmit Ports - TX Driver and OOB signalling --------------
         TXN0_OUT             => gtpTxN0, --  out  std_logic;
         TXN1_OUT             => gtpTxN1, --  out  std_logic;
         TXP0_OUT             => gtpTxP0, --  out  std_logic;
         TXP1_OUT             => gtpTxP1  --  out  std_logic         
      );

end rtl;
