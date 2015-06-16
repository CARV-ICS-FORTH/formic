-- ===========================================================================
--
--                              FORTH-ICS / CARV
--
--      Licensed under the TAPR Open Hardware License (www.tapr.org/NCL)
--                           Copyright (c) 2010-2012
--
--
-- ==========================[ Static Information ]===========================
--
-- Author        : Spyros Lyberis
-- Abstract      : GTP dual for Formic Spartan-6
--
-- =============================[ CVS Variables ]=============================
--
-- File name     : $RCSfile: rio_gtps6.vhd,v $
-- CVS revision  : $Revision: 1.5 $
-- Last modified : $Date: 2012/07/03 16:28:57 $
-- Last author   : $Author: lyberis $
--
-- ===========================================================================

library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
-- synthesis translate_off
use unisim.gtpa1_dual;
-- synthesis translate_on
use unisim.vcomponents.all;


entity rio_gtps6 is
  port (
    -- Shared Ports - Tile and PLL Ports
    GTPRESET_IN         : in  std_logic;
    CLKIN_IN            : in  std_logic;
    PLLLKDET_OUT        : out std_logic;
    REFCLKOUT_OUT       : out std_logic;

    POWERDOWN0_IN       : in  std_logic;
    POWERDOWN1_IN       : in  std_logic;

    USRCLK_IN           : in  std_logic;
    USRCLK2_IN          : in  std_logic;
    INITRST_IN          : in  std_logic;

    RESETDONE0_OUT      : out std_logic;
    RESETDONE1_OUT      : out std_logic;

    -- Transmit Ports - 8b10b Encoder Control Ports
    TXDATA0_IN          : in  std_logic_vector(15 downto 0);
    TXDATA1_IN          : in  std_logic_vector(15 downto 0);
    TXCHARISK0_IN       : in  std_logic_vector(1 downto 0);
    TXCHARISK1_IN       : in  std_logic_vector(1 downto 0);

    -- Receive Ports - RX Data Path interface
    RXDATA0_OUT         : out std_logic_vector(15 downto 0);
    RXDATA1_OUT         : out std_logic_vector(15 downto 0);
    RXCHARISK0_OUT      : out std_logic_vector(1 downto 0);
    RXCHARISK1_OUT      : out std_logic_vector(1 downto 0);

    -- Receive Ports - 8b10b Decoder
    RXLOSSOFSYNC0_OUT   : out std_logic_vector(1 downto 0);
    RXLOSSOFSYNC1_OUT   : out std_logic_vector(1 downto 0);
    RXDISPERR0_OUT      : out std_logic_vector(1 downto 0);
    RXDISPERR1_OUT      : out std_logic_vector(1 downto 0);
    RXNOTINTABLE0_OUT   : out std_logic_vector(1 downto 0);
    RXNOTINTABLE1_OUT   : out std_logic_vector(1 downto 0);
    RXBUFSTATUS0_OUT    : out std_logic_vector(2 downto 0);
    RXBUFSTATUS1_OUT    : out std_logic_vector(2 downto 0);

    -- Transmit Ports - TX Driver and OOB signalling
    TXN0_OUT            : out std_logic;
    TXN1_OUT            : out std_logic;
    TXP0_OUT            : out std_logic;
    TXP1_OUT            : out std_logic;

    -- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR
    RXN0_IN             : in  std_logic;
    RXN1_IN             : in  std_logic;
    RXP0_IN             : in  std_logic;
    RXP1_IN             : in  std_logic
  );

end rio_gtps6;

architecture rtl of rio_gtps6 is 


  component GTPA1_DUAL is
    generic (
      AC_CAP_DIS_0 : boolean := TRUE;
      AC_CAP_DIS_1 : boolean := TRUE;
      ALIGN_COMMA_WORD_0 : integer := 1;
      ALIGN_COMMA_WORD_1 : integer := 1;
      CB2_INH_CC_PERIOD_0 : integer := 8;
      CB2_INH_CC_PERIOD_1 : integer := 8;
      CDR_PH_ADJ_TIME_0 : bit_vector := "01010";
      CDR_PH_ADJ_TIME_1 : bit_vector := "01010";
      CHAN_BOND_1_MAX_SKEW_0 : integer := 7;
      CHAN_BOND_1_MAX_SKEW_1 : integer := 7;
      CHAN_BOND_2_MAX_SKEW_0 : integer := 1;
      CHAN_BOND_2_MAX_SKEW_1 : integer := 1;
      CHAN_BOND_KEEP_ALIGN_0 : boolean := FALSE;
      CHAN_BOND_KEEP_ALIGN_1 : boolean := FALSE;
      CHAN_BOND_SEQ_1_1_0 : bit_vector := "0101111100";
      CHAN_BOND_SEQ_1_1_1 : bit_vector := "0101111100";
      CHAN_BOND_SEQ_1_2_0 : bit_vector := "0001001010";
      CHAN_BOND_SEQ_1_2_1 : bit_vector := "0001001010";
      CHAN_BOND_SEQ_1_3_0 : bit_vector := "0001001010";
      CHAN_BOND_SEQ_1_3_1 : bit_vector := "0001001010";
      CHAN_BOND_SEQ_1_4_0 : bit_vector := "0110111100";
      CHAN_BOND_SEQ_1_4_1 : bit_vector := "0110111100";
      CHAN_BOND_SEQ_1_ENABLE_0 : bit_vector := "1111";
      CHAN_BOND_SEQ_1_ENABLE_1 : bit_vector := "1111";
      CHAN_BOND_SEQ_2_1_0 : bit_vector := "0110111100";
      CHAN_BOND_SEQ_2_1_1 : bit_vector := "0110111100";
      CHAN_BOND_SEQ_2_2_0 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_2_1 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_3_0 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_3_1 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_4_0 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_4_1 : bit_vector := "0100111100";
      CHAN_BOND_SEQ_2_ENABLE_0 : bit_vector := "1111";
      CHAN_BOND_SEQ_2_ENABLE_1 : bit_vector := "1111";
      CHAN_BOND_SEQ_2_USE_0 : boolean := FALSE;
      CHAN_BOND_SEQ_2_USE_1 : boolean := FALSE;
      CHAN_BOND_SEQ_LEN_0 : integer := 1;
      CHAN_BOND_SEQ_LEN_1 : integer := 1;
      CLK25_DIVIDER_0 : integer := 4;
      CLK25_DIVIDER_1 : integer := 4;
      CLKINDC_B_0 : boolean := TRUE;
      CLKINDC_B_1 : boolean := TRUE;
      CLKRCV_TRST_0 : boolean := TRUE;
      CLKRCV_TRST_1 : boolean := TRUE;
      CLK_CORRECT_USE_0 : boolean := TRUE;
      CLK_CORRECT_USE_1 : boolean := TRUE;
      CLK_COR_ADJ_LEN_0 : integer := 1;
      CLK_COR_ADJ_LEN_1 : integer := 1;
      CLK_COR_DET_LEN_0 : integer := 1;
      CLK_COR_DET_LEN_1 : integer := 1;
      CLK_COR_INSERT_IDLE_FLAG_0 : boolean := FALSE;
      CLK_COR_INSERT_IDLE_FLAG_1 : boolean := FALSE;
      CLK_COR_KEEP_IDLE_0 : boolean := FALSE;
      CLK_COR_KEEP_IDLE_1 : boolean := FALSE;
      CLK_COR_MAX_LAT_0 : integer := 20;
      CLK_COR_MAX_LAT_1 : integer := 20;
      CLK_COR_MIN_LAT_0 : integer := 18;
      CLK_COR_MIN_LAT_1 : integer := 18;
      CLK_COR_PRECEDENCE_0 : boolean := TRUE;
      CLK_COR_PRECEDENCE_1 : boolean := TRUE;
      CLK_COR_REPEAT_WAIT_0 : integer := 0;
      CLK_COR_REPEAT_WAIT_1 : integer := 0;
      CLK_COR_SEQ_1_1_0 : bit_vector := "0100011100";
      CLK_COR_SEQ_1_1_1 : bit_vector := "0100011100";
      CLK_COR_SEQ_1_2_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_2_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_3_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_3_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_4_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_4_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_ENABLE_0 : bit_vector := "1111";
      CLK_COR_SEQ_1_ENABLE_1 : bit_vector := "1111";
      CLK_COR_SEQ_2_1_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_1_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_2_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_2_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_3_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_3_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_4_0 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_4_1 : bit_vector := "0000000000";
      CLK_COR_SEQ_2_ENABLE_0 : bit_vector := "1111";
      CLK_COR_SEQ_2_ENABLE_1 : bit_vector := "1111";
      CLK_COR_SEQ_2_USE_0 : boolean := FALSE;
      CLK_COR_SEQ_2_USE_1 : boolean := FALSE;
      CLK_OUT_GTP_SEL_0 : string := "REFCLKPLL0";
      CLK_OUT_GTP_SEL_1 : string := "REFCLKPLL1";
      CM_TRIM_0 : bit_vector := "00";
      CM_TRIM_1 : bit_vector := "00";
      COMMA_10B_ENABLE_0 : bit_vector := "1111111111";
      COMMA_10B_ENABLE_1 : bit_vector := "1111111111";
      COM_BURST_VAL_0 : bit_vector := "1111";
      COM_BURST_VAL_1 : bit_vector := "1111";
      DEC_MCOMMA_DETECT_0 : boolean := TRUE;
      DEC_MCOMMA_DETECT_1 : boolean := TRUE;
      DEC_PCOMMA_DETECT_0 : boolean := TRUE;
      DEC_PCOMMA_DETECT_1 : boolean := TRUE;
      DEC_VALID_COMMA_ONLY_0 : boolean := TRUE;
      DEC_VALID_COMMA_ONLY_1 : boolean := TRUE;
      GTP_CFG_PWRUP_0 : boolean := TRUE;
      GTP_CFG_PWRUP_1 : boolean := TRUE;
      MCOMMA_10B_VALUE_0 : bit_vector := "1010000011";
      MCOMMA_10B_VALUE_1 : bit_vector := "1010000011";
      MCOMMA_DETECT_0 : boolean := TRUE;
      MCOMMA_DETECT_1 : boolean := TRUE;
      OOBDETECT_THRESHOLD_0 : bit_vector := "110";
      OOBDETECT_THRESHOLD_1 : bit_vector := "110";
      OOB_CLK_DIVIDER_0 : integer := 4;
      OOB_CLK_DIVIDER_1 : integer := 4;
      PCI_EXPRESS_MODE_0 : boolean := FALSE;
      PCI_EXPRESS_MODE_1 : boolean := FALSE;
      PCOMMA_10B_VALUE_0 : bit_vector := "0101111100";
      PCOMMA_10B_VALUE_1 : bit_vector := "0101111100";
      PCOMMA_DETECT_0 : boolean := TRUE;
      PCOMMA_DETECT_1 : boolean := TRUE;
      PLLLKDET_CFG_0 : bit_vector := "101";
      PLLLKDET_CFG_1 : bit_vector := "101";
      PLL_COM_CFG_0 : bit_vector := X"21680A";
      PLL_COM_CFG_1 : bit_vector := X"21680A";
      PLL_CP_CFG_0 : bit_vector := X"00";
      PLL_CP_CFG_1 : bit_vector := X"00";
      PLL_DIVSEL_FB_0 : integer := 5;
      PLL_DIVSEL_FB_1 : integer := 5;
      PLL_DIVSEL_REF_0 : integer := 2;
      PLL_DIVSEL_REF_1 : integer := 2;
      PLL_RXDIVSEL_OUT_0 : integer := 1;
      PLL_RXDIVSEL_OUT_1 : integer := 1;
      PLL_SATA_0 : boolean := FALSE;
      PLL_SATA_1 : boolean := FALSE;
      PLL_SOURCE_0 : string := "PLL0";
      PLL_SOURCE_1 : string := "PLL0";
      PLL_TXDIVSEL_OUT_0 : integer := 1;
      PLL_TXDIVSEL_OUT_1 : integer := 1;
      PMA_CDR_SCAN_0 : bit_vector := X"6404040";
      PMA_CDR_SCAN_1 : bit_vector := X"6404040";
      PMA_COM_CFG_EAST : bit_vector := X"000008000";
      PMA_COM_CFG_WEST : bit_vector := X"00000A000";
      PMA_RXSYNC_CFG_0 : bit_vector := X"00";
      PMA_RXSYNC_CFG_1 : bit_vector := X"00";
      PMA_RX_CFG_0 : bit_vector := X"05CE048";
      PMA_RX_CFG_1 : bit_vector := X"05CE048";
      PMA_TX_CFG_0 : bit_vector := X"00082";
      PMA_TX_CFG_1 : bit_vector := X"00082";
      RCV_TERM_GND_0 : boolean := FALSE;
      RCV_TERM_GND_1 : boolean := FALSE;
      RCV_TERM_VTTRX_0 : boolean := TRUE;
      RCV_TERM_VTTRX_1 : boolean := TRUE;
      RXEQ_CFG_0 : bit_vector := "01111011";
      RXEQ_CFG_1 : bit_vector := "01111011";
      RXPRBSERR_LOOPBACK_0 : bit := '0';
      RXPRBSERR_LOOPBACK_1 : bit := '0';
      RX_BUFFER_USE_0 : boolean := TRUE;
      RX_BUFFER_USE_1 : boolean := TRUE;
      RX_DECODE_SEQ_MATCH_0 : boolean := TRUE;
      RX_DECODE_SEQ_MATCH_1 : boolean := TRUE;
      RX_EN_IDLE_HOLD_CDR_0 : boolean := FALSE;
      RX_EN_IDLE_HOLD_CDR_1 : boolean := FALSE;
      RX_EN_IDLE_RESET_BUF_0 : boolean := TRUE;
      RX_EN_IDLE_RESET_BUF_1 : boolean := TRUE;
      RX_EN_IDLE_RESET_FR_0 : boolean := TRUE;
      RX_EN_IDLE_RESET_FR_1 : boolean := TRUE;
      RX_EN_IDLE_RESET_PH_0 : boolean := TRUE;
      RX_EN_IDLE_RESET_PH_1 : boolean := TRUE;
      RX_EN_MODE_RESET_BUF_0 : boolean := TRUE;
      RX_EN_MODE_RESET_BUF_1 : boolean := TRUE;
      RX_IDLE_HI_CNT_0 : bit_vector := "1000";
      RX_IDLE_HI_CNT_1 : bit_vector := "1000";
      RX_IDLE_LO_CNT_0 : bit_vector := "0000";
      RX_IDLE_LO_CNT_1 : bit_vector := "0000";
      RX_LOSS_OF_SYNC_FSM_0 : boolean := FALSE;
      RX_LOSS_OF_SYNC_FSM_1 : boolean := FALSE;
      RX_LOS_INVALID_INCR_0 : integer := 1;
      RX_LOS_INVALID_INCR_1 : integer := 1;
      RX_LOS_THRESHOLD_0 : integer := 4;
      RX_LOS_THRESHOLD_1 : integer := 4;
      RX_SLIDE_MODE_0 : string := "PCS";
      RX_SLIDE_MODE_1 : string := "PCS";
      RX_STATUS_FMT_0 : string := "PCIE";
      RX_STATUS_FMT_1 : string := "PCIE";
      RX_XCLK_SEL_0 : string := "RXREC";
      RX_XCLK_SEL_1 : string := "RXREC";
      SATA_BURST_VAL_0 : bit_vector := "100";
      SATA_BURST_VAL_1 : bit_vector := "100";
      SATA_IDLE_VAL_0 : bit_vector := "011";
      SATA_IDLE_VAL_1 : bit_vector := "011";
      SATA_MAX_BURST_0 : integer := 7;
      SATA_MAX_BURST_1 : integer := 7;
      SATA_MAX_INIT_0 : integer := 22;
      SATA_MAX_INIT_1 : integer := 22;
      SATA_MAX_WAKE_0 : integer := 7;
      SATA_MAX_WAKE_1 : integer := 7;
      SATA_MIN_BURST_0 : integer := 4;
      SATA_MIN_BURST_1 : integer := 4;
      SATA_MIN_INIT_0 : integer := 12;
      SATA_MIN_INIT_1 : integer := 12;
      SATA_MIN_WAKE_0 : integer := 4;
      SATA_MIN_WAKE_1 : integer := 4;
      SIM_GTPRESET_SPEEDUP : integer := 0;
      SIM_RECEIVER_DETECT_PASS : boolean := FALSE;
      SIM_REFCLK0_SOURCE : bit_vector := "000";
      SIM_REFCLK1_SOURCE : bit_vector := "000";
      SIM_TX_ELEC_IDLE_LEVEL : string := "X";
      SIM_VERSION : string := "2.0";
      TERMINATION_CTRL_0 : bit_vector := "10100";
      TERMINATION_CTRL_1 : bit_vector := "10100";
      TERMINATION_OVRD_0 : boolean := FALSE;
      TERMINATION_OVRD_1 : boolean := FALSE;
      TRANS_TIME_FROM_P2_0 : bit_vector := X"03C";
      TRANS_TIME_FROM_P2_1 : bit_vector := X"03C";
      TRANS_TIME_NON_P2_0 : bit_vector := X"19";
      TRANS_TIME_NON_P2_1 : bit_vector := X"19";
      TRANS_TIME_TO_P2_0 : bit_vector := X"064";
      TRANS_TIME_TO_P2_1 : bit_vector := X"064";
      TST_ATTR_0 : bit_vector := X"00000000";
      TST_ATTR_1 : bit_vector := X"00000000";
      TXRX_INVERT_0 : bit_vector := "011";
      TXRX_INVERT_1 : bit_vector := "011";
      TX_BUFFER_USE_0 : boolean := FALSE;
      TX_BUFFER_USE_1 : boolean := FALSE;
      TX_DETECT_RX_CFG_0 : bit_vector := X"1832";
      TX_DETECT_RX_CFG_1 : bit_vector := X"1832";
      TX_IDLE_DELAY_0 : bit_vector := "011";
      TX_IDLE_DELAY_1 : bit_vector := "011";
      TX_TDCC_CFG_0 : bit_vector := "00";
      TX_TDCC_CFG_1 : bit_vector := "00";
      TX_XCLK_SEL_0 : string := "TXUSR";
      TX_XCLK_SEL_1 : string := "TXUSR"
    );

    port (
      DRDY                 : out std_ulogic;
      DRPDO                : out std_logic_vector(15 downto 0);
      GTPCLKFBEAST         : out std_logic_vector(1 downto 0);
      GTPCLKFBWEST         : out std_logic_vector(1 downto 0);
      GTPCLKOUT0           : out std_logic_vector(1 downto 0);
      GTPCLKOUT1           : out std_logic_vector(1 downto 0);
      PHYSTATUS0           : out std_ulogic;
      PHYSTATUS1           : out std_ulogic;
      PLLLKDET0            : out std_ulogic;
      PLLLKDET1            : out std_ulogic;
      RCALOUTEAST          : out std_logic_vector(4 downto 0);
      RCALOUTWEST          : out std_logic_vector(4 downto 0);
      REFCLKOUT0           : out std_ulogic;
      REFCLKOUT1           : out std_ulogic;
      REFCLKPLL0           : out std_ulogic;
      REFCLKPLL1           : out std_ulogic;
      RESETDONE0           : out std_ulogic;
      RESETDONE1           : out std_ulogic;
      RXBUFSTATUS0         : out std_logic_vector(2 downto 0);
      RXBUFSTATUS1         : out std_logic_vector(2 downto 0);
      RXBYTEISALIGNED0     : out std_ulogic;
      RXBYTEISALIGNED1     : out std_ulogic;
      RXBYTEREALIGN0       : out std_ulogic;
      RXBYTEREALIGN1       : out std_ulogic;
      RXCHANBONDSEQ0       : out std_ulogic;
      RXCHANBONDSEQ1       : out std_ulogic;
      RXCHANISALIGNED0     : out std_ulogic;
      RXCHANISALIGNED1     : out std_ulogic;
      RXCHANREALIGN0       : out std_ulogic;
      RXCHANREALIGN1       : out std_ulogic;
      RXCHARISCOMMA0       : out std_logic_vector(3 downto 0);
      RXCHARISCOMMA1       : out std_logic_vector(3 downto 0);
      RXCHARISK0           : out std_logic_vector(3 downto 0);
      RXCHARISK1           : out std_logic_vector(3 downto 0);
      RXCHBONDO            : out std_logic_vector(2 downto 0);
      RXCLKCORCNT0         : out std_logic_vector(2 downto 0);
      RXCLKCORCNT1         : out std_logic_vector(2 downto 0);
      RXCOMMADET0          : out std_ulogic;
      RXCOMMADET1          : out std_ulogic;
      RXDATA0              : out std_logic_vector(31 downto 0);
      RXDATA1              : out std_logic_vector(31 downto 0);
      RXDISPERR0           : out std_logic_vector(3 downto 0);
      RXDISPERR1           : out std_logic_vector(3 downto 0);
      RXELECIDLE0          : out std_ulogic;
      RXELECIDLE1          : out std_ulogic;
      RXLOSSOFSYNC0        : out std_logic_vector(1 downto 0);
      RXLOSSOFSYNC1        : out std_logic_vector(1 downto 0);
      RXNOTINTABLE0        : out std_logic_vector(3 downto 0);
      RXNOTINTABLE1        : out std_logic_vector(3 downto 0);
      RXPRBSERR0           : out std_ulogic;
      RXPRBSERR1           : out std_ulogic;
      RXRECCLK0            : out std_ulogic;
      RXRECCLK1            : out std_ulogic;
      RXRUNDISP0           : out std_logic_vector(3 downto 0);
      RXRUNDISP1           : out std_logic_vector(3 downto 0);
      RXSTATUS0            : out std_logic_vector(2 downto 0);
      RXSTATUS1            : out std_logic_vector(2 downto 0);
      RXVALID0             : out std_ulogic;
      RXVALID1             : out std_ulogic;
      TSTOUT0              : out std_logic_vector(4 downto 0);
      TSTOUT1              : out std_logic_vector(4 downto 0);
      TXBUFSTATUS0         : out std_logic_vector(1 downto 0);
      TXBUFSTATUS1         : out std_logic_vector(1 downto 0);
      TXKERR0              : out std_logic_vector(3 downto 0);
      TXKERR1              : out std_logic_vector(3 downto 0);
      TXN0                 : out std_ulogic;
      TXN1                 : out std_ulogic;
      TXOUTCLK0            : out std_ulogic;
      TXOUTCLK1            : out std_ulogic;
      TXP0                 : out std_ulogic;
      TXP1                 : out std_ulogic;
      TXRUNDISP0           : out std_logic_vector(3 downto 0);
      TXRUNDISP1           : out std_logic_vector(3 downto 0);
      CLK00                : in std_ulogic;
      CLK01                : in std_ulogic;
      CLK10                : in std_ulogic;
      CLK11                : in std_ulogic;
      CLKINEAST0           : in std_ulogic;
      CLKINEAST1           : in std_ulogic;
      CLKINWEST0           : in std_ulogic;
      CLKINWEST1           : in std_ulogic;
      DADDR                : in std_logic_vector(7 downto 0);
      DCLK                 : in std_ulogic;
      DEN                  : in std_ulogic;
      DI                   : in std_logic_vector(15 downto 0);
      DWE                  : in std_ulogic;
      GATERXELECIDLE0      : in std_ulogic;
      GATERXELECIDLE1      : in std_ulogic;
      GCLK00               : in std_ulogic;
      GCLK01               : in std_ulogic;
      GCLK10               : in std_ulogic;
      GCLK11               : in std_ulogic;
      GTPCLKFBSEL0EAST     : in std_logic_vector(1 downto 0);
      GTPCLKFBSEL0WEST     : in std_logic_vector(1 downto 0);
      GTPCLKFBSEL1EAST     : in std_logic_vector(1 downto 0);
      GTPCLKFBSEL1WEST     : in std_logic_vector(1 downto 0);
      GTPRESET0            : in std_ulogic;
      GTPRESET1            : in std_ulogic;
      GTPTEST0             : in std_logic_vector(7 downto 0);
      GTPTEST1             : in std_logic_vector(7 downto 0);
      IGNORESIGDET0        : in std_ulogic;
      IGNORESIGDET1        : in std_ulogic;
      INTDATAWIDTH0        : in std_ulogic;
      INTDATAWIDTH1        : in std_ulogic;
      LOOPBACK0            : in std_logic_vector(2 downto 0);
      LOOPBACK1            : in std_logic_vector(2 downto 0);
      PLLCLK00             : in std_ulogic;
      PLLCLK01             : in std_ulogic;
      PLLCLK10             : in std_ulogic;
      PLLCLK11             : in std_ulogic;
      PLLLKDETEN0          : in std_ulogic;
      PLLLKDETEN1          : in std_ulogic;
      PLLPOWERDOWN0        : in std_ulogic;
      PLLPOWERDOWN1        : in std_ulogic;
      PRBSCNTRESET0        : in std_ulogic;
      PRBSCNTRESET1        : in std_ulogic;
      RCALINEAST           : in std_logic_vector(4 downto 0);
      RCALINWEST           : in std_logic_vector(4 downto 0);
      REFCLKPWRDNB0        : in std_ulogic;
      REFCLKPWRDNB1        : in std_ulogic;
      REFSELDYPLL0         : in std_logic_vector(2 downto 0);
      REFSELDYPLL1         : in std_logic_vector(2 downto 0);
      RXBUFRESET0          : in std_ulogic;
      RXBUFRESET1          : in std_ulogic;
      RXCDRRESET0          : in std_ulogic;
      RXCDRRESET1          : in std_ulogic;
      RXCHBONDI            : in std_logic_vector(2 downto 0);
      RXCHBONDMASTER0      : in std_ulogic;
      RXCHBONDMASTER1      : in std_ulogic;
      RXCHBONDSLAVE0       : in std_ulogic;
      RXCHBONDSLAVE1       : in std_ulogic;
      RXCOMMADETUSE0       : in std_ulogic;
      RXCOMMADETUSE1       : in std_ulogic;
      RXDATAWIDTH0         : in std_logic_vector(1 downto 0);
      RXDATAWIDTH1         : in std_logic_vector(1 downto 0);
      RXDEC8B10BUSE0       : in std_ulogic;
      RXDEC8B10BUSE1       : in std_ulogic;
      RXENCHANSYNC0        : in std_ulogic;
      RXENCHANSYNC1        : in std_ulogic;
      RXENMCOMMAALIGN0     : in std_ulogic;
      RXENMCOMMAALIGN1     : in std_ulogic;
      RXENPCOMMAALIGN0     : in std_ulogic;
      RXENPCOMMAALIGN1     : in std_ulogic;
      RXENPMAPHASEALIGN0   : in std_ulogic;
      RXENPMAPHASEALIGN1   : in std_ulogic;
      RXENPRBSTST0         : in std_logic_vector(2 downto 0);
      RXENPRBSTST1         : in std_logic_vector(2 downto 0);
      RXEQMIX0             : in std_logic_vector(1 downto 0);
      RXEQMIX1             : in std_logic_vector(1 downto 0);
      RXN0                 : in std_ulogic;
      RXN1                 : in std_ulogic;
      RXP0                 : in std_ulogic;
      RXP1                 : in std_ulogic;
      RXPMASETPHASE0       : in std_ulogic;
      RXPMASETPHASE1       : in std_ulogic;
      RXPOLARITY0          : in std_ulogic;
      RXPOLARITY1          : in std_ulogic;
      RXPOWERDOWN0         : in std_logic_vector(1 downto 0);
      RXPOWERDOWN1         : in std_logic_vector(1 downto 0);
      RXRESET0             : in std_ulogic;
      RXRESET1             : in std_ulogic;
      RXSLIDE0             : in std_ulogic;
      RXSLIDE1             : in std_ulogic;
      RXUSRCLK0            : in std_ulogic;
      RXUSRCLK1            : in std_ulogic;
      RXUSRCLK20           : in std_ulogic;
      RXUSRCLK21           : in std_ulogic;
      TSTCLK0              : in std_ulogic;
      TSTCLK1              : in std_ulogic;
      TSTIN0               : in std_logic_vector(11 downto 0);
      TSTIN1               : in std_logic_vector(11 downto 0);
      TXBUFDIFFCTRL0       : in std_logic_vector(2 downto 0);
      TXBUFDIFFCTRL1       : in std_logic_vector(2 downto 0);
      TXBYPASS8B10B0       : in std_logic_vector(3 downto 0);
      TXBYPASS8B10B1       : in std_logic_vector(3 downto 0);
      TXCHARDISPMODE0      : in std_logic_vector(3 downto 0);
      TXCHARDISPMODE1      : in std_logic_vector(3 downto 0);
      TXCHARDISPVAL0       : in std_logic_vector(3 downto 0);
      TXCHARDISPVAL1       : in std_logic_vector(3 downto 0);
      TXCHARISK0           : in std_logic_vector(3 downto 0);
      TXCHARISK1           : in std_logic_vector(3 downto 0);
      TXCOMSTART0          : in std_ulogic;
      TXCOMSTART1          : in std_ulogic;
      TXCOMTYPE0           : in std_ulogic;
      TXCOMTYPE1           : in std_ulogic;
      TXDATA0              : in std_logic_vector(31 downto 0);
      TXDATA1              : in std_logic_vector(31 downto 0);
      TXDATAWIDTH0         : in std_logic_vector(1 downto 0);
      TXDATAWIDTH1         : in std_logic_vector(1 downto 0);
      TXDETECTRX0          : in std_ulogic;
      TXDETECTRX1          : in std_ulogic;
      TXDIFFCTRL0          : in std_logic_vector(3 downto 0);
      TXDIFFCTRL1          : in std_logic_vector(3 downto 0);
      TXELECIDLE0          : in std_ulogic;
      TXELECIDLE1          : in std_ulogic;
      TXENC8B10BUSE0       : in std_ulogic;
      TXENC8B10BUSE1       : in std_ulogic;
      TXENPMAPHASEALIGN0   : in std_ulogic;
      TXENPMAPHASEALIGN1   : in std_ulogic;
      TXENPRBSTST0         : in std_logic_vector(2 downto 0);
      TXENPRBSTST1         : in std_logic_vector(2 downto 0);
      TXINHIBIT0           : in std_ulogic;
      TXINHIBIT1           : in std_ulogic;
      TXPDOWNASYNCH0       : in std_ulogic;
      TXPDOWNASYNCH1       : in std_ulogic;
      TXPMASETPHASE0       : in std_ulogic;
      TXPMASETPHASE1       : in std_ulogic;
      TXPOLARITY0          : in std_ulogic;
      TXPOLARITY1          : in std_ulogic;
      TXPOWERDOWN0         : in std_logic_vector(1 downto 0);
      TXPOWERDOWN1         : in std_logic_vector(1 downto 0);
      TXPRBSFORCEERR0      : in std_ulogic;
      TXPRBSFORCEERR1      : in std_ulogic;
      TXPREEMPHASIS0       : in std_logic_vector(2 downto 0);
      TXPREEMPHASIS1       : in std_logic_vector(2 downto 0);
      TXRESET0             : in std_ulogic;
      TXRESET1             : in std_ulogic;
      TXUSRCLK0            : in std_ulogic;
      TXUSRCLK1            : in std_ulogic;
      TXUSRCLK20           : in std_ulogic;
      TXUSRCLK21           : in std_ulogic;
      USRCODEERR0          : in std_ulogic;
      USRCODEERR1          : in std_ulogic      
    );
  end component;


  constant tied_to_ground_i     : std_logic := '0';
  constant tied_to_ground_vec_i : std_logic_vector (63 downto 0) := 
                                        X"0000000000000000";
  constant tied_to_vcc_i     : std_logic := '1';
  constant tied_to_vcc_vec_i : std_logic_vector (63 downto 0) := 
                                        X"FFFFFFFFFFFFFFFF";

  signal RXENCOMMAALIGN_INT : std_logic;

  signal PLLLKDET0 : std_logic;
  signal PLLLKDET1 : std_logic;

  signal RXDATA0        : std_logic_vector (31 downto 0);
  signal RXDATA1        : std_logic_vector (31 downto 0);
  signal RXCHARISK0     : std_logic_vector ( 3 downto 0);
  signal RXCHARISK1     : std_logic_vector ( 3 downto 0);
  signal RXNOTINTABLE0  : std_logic_vector ( 3 downto 0);
  signal RXNOTINTABLE1  : std_logic_vector ( 3 downto 0);
  signal RXDISPERR0     : std_logic_vector ( 3 downto 0);
  signal RXDISPERR1     : std_logic_vector ( 3 downto 0);
  signal GTPCLKOUT0     : std_logic_vector ( 1 downto 0);

  signal TXDATA0        : std_logic_vector (31 downto 0);
  signal TXDATA1        : std_logic_vector (31 downto 0);
  signal TXCHARISK0     : std_logic_vector ( 3 downto 0);
  signal TXCHARISK1     : std_logic_vector ( 3 downto 0);

  signal RESETDONE0_INT : std_logic;
  signal RESETDONE1_INT : std_logic;

  signal RX_POWERDOWN0  : std_logic_vector (1 downto 0);
  signal RX_POWERDOWN1  : std_logic_vector (1 downto 0);
  signal TX_POWERDOWN0  : std_logic_vector (1 downto 0);
  signal TX_POWERDOWN1  : std_logic_vector (1 downto 0);

begin

  RX_POWERDOWN0 <= POWERDOWN0_IN & POWERDOWN0_IN;
  RX_POWERDOWN1 <= POWERDOWN1_IN & POWERDOWN1_IN;
  TX_POWERDOWN0 <= POWERDOWN0_IN & POWERDOWN0_IN;
  TX_POWERDOWN1 <= POWERDOWN1_IN & POWERDOWN1_IN;
         

  process(USRCLK2_IN, GTPRESET_IN)
  begin
    if (GTPRESET_IN = '1') then
      RXENCOMMAALIGN_INT <= '0';
    elsif (USRCLK2_IN'event and USRCLK2_IN = '1') then
      if ((RESETDONE0_INT and RESETDONE1_INT) = '0') then
        RXENCOMMAALIGN_INT <= '0';
      else 
        RXENCOMMAALIGN_INT <= '1';
      end if;
    end if;
  end process;


  PLLLKDET_OUT <= PLLLKDET0 and PLLLKDET1;

  REFCLKOUT_OUT <= GTPCLKOUT0(0);

  RXDATA0_OUT       <= RXDATA0(15 downto 0);
  RXDATA1_OUT       <= RXDATA1(15 downto 0);
  RXCHARISK0_OUT    <= RXCHARISK0(1 downto 0);
  RXCHARISK1_OUT    <= RXCHARISK1(1 downto 0);
  RXNOTINTABLE0_OUT <= RXNOTINTABLE0(1 downto 0);
  RXNOTINTABLE1_OUT <= RXNOTINTABLE1(1 downto 0);
  RXDISPERR0_OUT    <= RXDISPERR0(1 downto 0);
  RXDISPERR1_OUT    <= RXDISPERR1(1 downto 0);
         
  TXCHARISK0        <= tied_to_ground_vec_i(1 downto 0) & TXCHARISK0_IN;
  TXCHARISK1        <= tied_to_ground_vec_i(1 downto 0) & TXCHARISK1_IN;
  TXDATA0           <= tied_to_ground_vec_i(15 downto 0) & TXDATA0_IN;
  TXDATA1           <= tied_to_ground_vec_i(15 downto 0) & TXDATA1_IN;

  RESETDONE0_OUT <= RESETDONE0_INT or POWERDOWN0_IN;
  RESETDONE1_OUT <= RESETDONE1_INT or POWERDOWN1_IN;
                                            
  gtpa1_dual_i: GTPA1_DUAL 
    generic map (
      -- Simulation-Only Attributes
      SIM_TX_ELEC_IDLE_LEVEL                => "Z",
      SIM_RECEIVER_DETECT_PASS              => true,
      SIM_VERSION                           => "2.0",
      SIM_REFCLK0_SOURCE                    => "000",
      SIM_REFCLK1_SOURCE                    => "000",
      SIM_GTPRESET_SPEEDUP                  => 1,
      CLK25_DIVIDER_0                       => 6,
      CLK25_DIVIDER_1                       => 6,
      PLL_DIVSEL_FB_0                       => 2, 
      PLL_DIVSEL_FB_1                       => 2,  
      PLL_DIVSEL_REF_0                      => 1, 
      PLL_DIVSEL_REF_1                      => 1,
 
      -- PLL Attributes
      CLKINDC_B_0                           => true,
      CLKRCV_TRST_0                         => true,
      OOB_CLK_DIVIDER_0                     => 6,
      PLL_COM_CFG_0                         => X"21680a",
      PLL_CP_CFG_0                          => X"00",
      PLL_RXDIVSEL_OUT_0                    => 1,
      PLL_SATA_0                            => false,
      PLL_SOURCE_0                          => "PLL0",
      PLL_TXDIVSEL_OUT_0                    => 1,
      PLLLKDET_CFG_0                        => "111",

      -- 
      CLKINDC_B_1                           => true,
      CLKRCV_TRST_1                         => true,
      OOB_CLK_DIVIDER_1                     => 6,
      PLL_COM_CFG_1                         => X"21680a",
      PLL_CP_CFG_1                          => X"00",
      PLL_RXDIVSEL_OUT_1                    => 1,
      PLL_SATA_1                            => false,
      PLL_SOURCE_1                          => "PLL1",
      PLL_TXDIVSEL_OUT_1                    => 1,
      PLLLKDET_CFG_1                        => "111",
      PMA_COM_CFG_EAST                      => X"000008000",
      PMA_COM_CFG_WEST                      => X"00000a000",
      TST_ATTR_0                            => X"00000000",
      TST_ATTR_1                            => X"00000000",

      -- TX Interface Attributes
      CLK_OUT_GTP_SEL_0                     => "REFCLKPLL0",
      TX_TDCC_CFG_0                         => "11",
      CLK_OUT_GTP_SEL_1                     => "REFCLKPLL1",
      TX_TDCC_CFG_1                         => "11",

      -- TX Buffer and Phase Alignment Attributes
      PMA_TX_CFG_0                          => X"00082",
      TX_BUFFER_USE_0                       => true,
      TX_XCLK_SEL_0                         => "TXOUT",
      TXRX_INVERT_0                         => "011",
      PMA_TX_CFG_1                          => X"00082",
      TX_BUFFER_USE_1                       => true,
      TX_XCLK_SEL_1                         => "TXOUT",
      TXRX_INVERT_1                         => "011",

      -- TX Driver and OOB signalling Attributes
      CM_TRIM_0                             => "00",
      TX_IDLE_DELAY_0                       => "011",
      CM_TRIM_1                             => "00",
      TX_IDLE_DELAY_1                       => "011",

      -- TX PIPE/SATA Attributes
      COM_BURST_VAL_0                       => "1111",
      COM_BURST_VAL_1                       => "1111",

      -- RX Driver,OOB signalling,Coupling and Eq,CDR Attributes
      AC_CAP_DIS_0                          => true,
      OOBDETECT_THRESHOLD_0                 => "110",
      PMA_CDR_SCAN_0                        => X"6404040",
      PMA_RX_CFG_0                          => X"05ce004",
      PMA_RXSYNC_CFG_0                      => X"00",
      RCV_TERM_GND_0                        => false,
      RCV_TERM_VTTRX_0                      => true,
      RXEQ_CFG_0                            => "01111011",
      TERMINATION_CTRL_0                    => "10100",
      TERMINATION_OVRD_0                    => false,
      TX_DETECT_RX_CFG_0                    => X"1832",
      AC_CAP_DIS_1                          => true,
      OOBDETECT_THRESHOLD_1                 => "110",
      PMA_CDR_SCAN_1                        => X"6404040",
      PMA_RX_CFG_1                          => X"05ce004",
      PMA_RXSYNC_CFG_1                      => X"00",
      RCV_TERM_GND_1                        => false,
      RCV_TERM_VTTRX_1                      => true,
      RXEQ_CFG_1                            => "01111011",
      TERMINATION_CTRL_1                    => "10100",
      TERMINATION_OVRD_1                    => false,
      TX_DETECT_RX_CFG_1                    => X"1832",

      -- PRBS Detection Attributes
      RXPRBSERR_LOOPBACK_0                  => '0',
      RXPRBSERR_LOOPBACK_1                  => '0',

      -- Comma Detection and Alignment Attributes
      ALIGN_COMMA_WORD_0                    => 2,
      COMMA_10B_ENABLE_0                    => "1111111111",
      DEC_MCOMMA_DETECT_0                   => true,
      DEC_PCOMMA_DETECT_0                   => true,
      DEC_VALID_COMMA_ONLY_0                => true,
      MCOMMA_10B_VALUE_0                    => "1010000011",
      MCOMMA_DETECT_0                       => true,
      PCOMMA_10B_VALUE_0                    => "0101111100",
      PCOMMA_DETECT_0                       => true,
      RX_SLIDE_MODE_0                       => "PCS",
      ALIGN_COMMA_WORD_1                    => 2,
      COMMA_10B_ENABLE_1                    => "1111111111",
      DEC_MCOMMA_DETECT_1                   => true,
      DEC_PCOMMA_DETECT_1                   => true,
      DEC_VALID_COMMA_ONLY_1                => true,
      MCOMMA_10B_VALUE_1                    => "1010000011",
      MCOMMA_DETECT_1                       => true,
      PCOMMA_10B_VALUE_1                    => "0101111100",
      PCOMMA_DETECT_1                       => true,
      RX_SLIDE_MODE_1                       => "PCS",

      -- RX Loss-of-sync State Machine Attributes
      RX_LOS_INVALID_INCR_0                 => 128,
      RX_LOS_THRESHOLD_0                    => 4,
      RX_LOSS_OF_SYNC_FSM_0                 => true,
      RX_LOS_INVALID_INCR_1                 => 128,
      RX_LOS_THRESHOLD_1                    => 4,
      RX_LOSS_OF_SYNC_FSM_1                 => true,

      -- RX Elastic Buffer and Phase alignment Attributes
      RX_BUFFER_USE_0                       => true,
      RX_EN_IDLE_RESET_BUF_0                => false,
      RX_IDLE_HI_CNT_0                      => "1000",
      RX_IDLE_LO_CNT_0                      => "0000",
      RX_XCLK_SEL_0                         => "RXREC",
      RX_BUFFER_USE_1                       => true,
      RX_EN_IDLE_RESET_BUF_1                => false,
      RX_IDLE_HI_CNT_1                      => "1000",
      RX_IDLE_LO_CNT_1                      => "0000",
      RX_XCLK_SEL_1                         => "RXREC",

      -- Clock Correction Attributes
      CLK_COR_ADJ_LEN_0                     => 2,
      CLK_COR_DET_LEN_0                     => 2,
      CLK_COR_INSERT_IDLE_FLAG_0            => false,
      CLK_COR_KEEP_IDLE_0                   => false,
      CLK_COR_MAX_LAT_0                     => 18,
      CLK_COR_MIN_LAT_0                     => 16,
      CLK_COR_PRECEDENCE_0                  => true,
      CLK_COR_REPEAT_WAIT_0                 => 0,
      CLK_COR_SEQ_1_1_0                     => "0110111100",
      CLK_COR_SEQ_1_2_0                     => "0111111011",
      CLK_COR_SEQ_1_3_0                     => "0100000000",
      CLK_COR_SEQ_1_4_0                     => "0100000000",
      CLK_COR_SEQ_1_ENABLE_0                => "0011",
      CLK_COR_SEQ_2_1_0                     => "0100000000",
      CLK_COR_SEQ_2_2_0                     => "0100000000",
      CLK_COR_SEQ_2_3_0                     => "0100000000",
      CLK_COR_SEQ_2_4_0                     => "0100000000",
      CLK_COR_SEQ_2_ENABLE_0                => "0000",
      CLK_COR_SEQ_2_USE_0                   => false,
      CLK_CORRECT_USE_0                     => true,
      RX_DECODE_SEQ_MATCH_0                 => true,

      CLK_COR_ADJ_LEN_1                     => 2,
      CLK_COR_DET_LEN_1                     => 2,
      CLK_COR_INSERT_IDLE_FLAG_1            => false,
      CLK_COR_KEEP_IDLE_1                   => false,
      CLK_COR_MAX_LAT_1                     => 18,
      CLK_COR_MIN_LAT_1                     => 16,
      CLK_COR_PRECEDENCE_1                  => true,
      CLK_COR_REPEAT_WAIT_1                 => 0,
      CLK_COR_SEQ_1_1_1                     => "0110111100",
      CLK_COR_SEQ_1_2_1                     => "0111111011",
      CLK_COR_SEQ_1_3_1                     => "0100000000",
      CLK_COR_SEQ_1_4_1                     => "0100000000",
      CLK_COR_SEQ_1_ENABLE_1                => "0011",
      CLK_COR_SEQ_2_1_1                     => "0100000000",
      CLK_COR_SEQ_2_2_1                     => "0100000000",
      CLK_COR_SEQ_2_3_1                     => "0100000000",
      CLK_COR_SEQ_2_4_1                     => "0100000000",
      CLK_COR_SEQ_2_ENABLE_1                => "0000",
      CLK_COR_SEQ_2_USE_1                   => false,
      CLK_CORRECT_USE_1                     => true,
      RX_DECODE_SEQ_MATCH_1                 => true,

      -- Channel Bonding Attributes
      CHAN_BOND_1_MAX_SKEW_0                => 1,
      CHAN_BOND_2_MAX_SKEW_0                => 1,
      CHAN_BOND_KEEP_ALIGN_0                => false,
      CHAN_BOND_SEQ_1_1_0                   => "0000000000",
      CHAN_BOND_SEQ_1_2_0                   => "0000000000",
      CHAN_BOND_SEQ_1_3_0                   => "0000000000",
      CHAN_BOND_SEQ_1_4_0                   => "0000000000",
      CHAN_BOND_SEQ_1_ENABLE_0              => "0000",
      CHAN_BOND_SEQ_2_1_0                   => "0000000000",
      CHAN_BOND_SEQ_2_2_0                   => "0000000000",
      CHAN_BOND_SEQ_2_3_0                   => "0000000000",
      CHAN_BOND_SEQ_2_4_0                   => "0000000000",
      CHAN_BOND_SEQ_2_ENABLE_0              => "0000",
      CHAN_BOND_SEQ_2_USE_0                 => false,
      CHAN_BOND_SEQ_LEN_0                   => 1,
      RX_EN_MODE_RESET_BUF_0                => false,
      CHAN_BOND_1_MAX_SKEW_1                => 1,
      CHAN_BOND_2_MAX_SKEW_1                => 1,
      CHAN_BOND_KEEP_ALIGN_1                => false,
      CHAN_BOND_SEQ_1_1_1                   => "0000000000",
      CHAN_BOND_SEQ_1_2_1                   => "0000000000",
      CHAN_BOND_SEQ_1_3_1                   => "0000000000",
      CHAN_BOND_SEQ_1_4_1                   => "0000000000",
      CHAN_BOND_SEQ_1_ENABLE_1              => "0000",
      CHAN_BOND_SEQ_2_1_1                   => "0000000000",
      CHAN_BOND_SEQ_2_2_1                   => "0000000000",
      CHAN_BOND_SEQ_2_3_1                   => "0000000000",
      CHAN_BOND_SEQ_2_4_1                   => "0000000000",
      CHAN_BOND_SEQ_2_ENABLE_1              => "0000",
      CHAN_BOND_SEQ_2_USE_1                 => false,
      CHAN_BOND_SEQ_LEN_1                   => 1,
      RX_EN_MODE_RESET_BUF_1                => false,

      -- RX PCI Express Attributes
      CB2_INH_CC_PERIOD_0                   => 8,
      CDR_PH_ADJ_TIME_0                     => "01010",
      PCI_EXPRESS_MODE_0                    => false,
      RX_EN_IDLE_HOLD_CDR_0                 => false,
      RX_EN_IDLE_RESET_FR_0                 => false,
      RX_EN_IDLE_RESET_PH_0                 => false,
      RX_STATUS_FMT_0                       => "PCIE",
      TRANS_TIME_FROM_P2_0                  => X"03c",
      TRANS_TIME_NON_P2_0                   => X"19",
      TRANS_TIME_TO_P2_0                    => X"064",
      CB2_INH_CC_PERIOD_1                   => 8,
      CDR_PH_ADJ_TIME_1                     => "01010",
      PCI_EXPRESS_MODE_1                    => false,
      RX_EN_IDLE_HOLD_CDR_1                 => false,
      RX_EN_IDLE_RESET_FR_1                 => false,
      RX_EN_IDLE_RESET_PH_1                 => false,
      RX_STATUS_FMT_1                       => "PCIE",
      TRANS_TIME_FROM_P2_1                  => X"03c",
      TRANS_TIME_NON_P2_1                   => X"19",
      TRANS_TIME_TO_P2_1                    => X"064",

      -- RX SATA Attributes
      SATA_BURST_VAL_0                      => "100",
      SATA_IDLE_VAL_0                       => "100",
      SATA_MAX_BURST_0                      => 7,
      SATA_MAX_INIT_0                       => 22,
      SATA_MAX_WAKE_0                       => 7,
      SATA_MIN_BURST_0                      => 4,
      SATA_MIN_INIT_0                       => 12,
      SATA_MIN_WAKE_0                       => 4,
      SATA_BURST_VAL_1                      => "100",
      SATA_IDLE_VAL_1                       => "100",
      SATA_MAX_BURST_1                      => 7,
      SATA_MAX_INIT_1                       => 22,
      SATA_MAX_WAKE_1                       => 7,
      SATA_MIN_BURST_1                      => 4,
      SATA_MIN_INIT_1                       => 12,
      SATA_MIN_WAKE_1                       => 4
     ) 
     port map (
        -------------- Loopback and Powerdown Ports ----------------------
        LOOPBACK0                           => tied_to_ground_vec_i(2 downto 0),
        LOOPBACK1                           => tied_to_ground_vec_i(2 downto 0),
        RXPOWERDOWN0                        => RX_POWERDOWN0,
        RXPOWERDOWN1                        => RX_POWERDOWN1,
        TXPOWERDOWN0                        => TX_POWERDOWN0,
        TXPOWERDOWN1                        => TX_POWERDOWN1,
        ----------------------- PLL Ports --------------------------------
        CLK00                               => CLKIN_IN,
        CLK01                               => CLKIN_IN,
        CLK10                               => tied_to_ground_i,
        CLK11                               => tied_to_ground_i,
        CLKINEAST0                          => tied_to_ground_i,
        CLKINEAST1                          => tied_to_ground_i,
        CLKINWEST0                          => tied_to_ground_i,
        CLKINWEST1                          => tied_to_ground_i,
        GCLK00                              => tied_to_ground_i,
        GCLK01                              => tied_to_ground_i,
        GCLK10                              => tied_to_ground_i,
        GCLK11                              => tied_to_ground_i,
        GTPRESET0                           => GTPRESET_IN,
        GTPRESET1                           => GTPRESET_IN,
        GTPTEST0                            => "00010000",
        GTPTEST1                            => "00010000",
        INTDATAWIDTH0                       => tied_to_vcc_i,
        INTDATAWIDTH1                       => tied_to_vcc_i,
        PLLCLK00                            => tied_to_ground_i,
        PLLCLK01                            => tied_to_ground_i,
        PLLCLK10                            => tied_to_ground_i,
        PLLCLK11                            => tied_to_ground_i,
        PLLLKDET0                           => PLLLKDET0,
        PLLLKDET1                           => PLLLKDET1,
        PLLLKDETEN0                         => tied_to_vcc_i,
        PLLLKDETEN1                         => tied_to_vcc_i,
        PLLPOWERDOWN0                       => tied_to_ground_i,
        PLLPOWERDOWN1                       => tied_to_ground_i,
        REFCLKOUT0                          => open,
        REFCLKOUT1                          => open,
        REFCLKPLL0                          => open,
        REFCLKPLL1                          => open,
        REFCLKPWRDNB0                       => tied_to_vcc_i,
        REFCLKPWRDNB1                       => tied_to_vcc_i,
        REFSELDYPLL0                        => tied_to_ground_vec_i(2 downto 0),
        REFSELDYPLL1                        => tied_to_ground_vec_i(2 downto 0),
        RESETDONE0                          => RESETDONE0_INT,
        RESETDONE1                          => RESETDONE1_INT,
        TSTCLK0                             => tied_to_ground_i,
        TSTCLK1                             => tied_to_ground_i,
        TSTIN0                              => tied_to_ground_vec_i(11 downto 0),
        TSTIN1                              => tied_to_ground_vec_i(11 downto 0),
        TSTOUT0                             => open,
        TSTOUT1                             => open,
        ------------- Receive Ports - 8b10b Decoder ----------------------
        RXCHARISCOMMA0                      => open,
        RXCHARISCOMMA1                      => open,
        RXCHARISK0                          => RXCHARISK0,
        RXCHARISK1                          => RXCHARISK1,
        RXDEC8B10BUSE0                      => tied_to_vcc_i,
        RXDEC8B10BUSE1                      => tied_to_vcc_i,
        RXDISPERR0                          => RXDISPERR0,
        RXDISPERR1                          => RXDISPERR1,
        RXNOTINTABLE0                       => RXNOTINTABLE0,
        RXNOTINTABLE1                       => RXNOTINTABLE1,
        RXRUNDISP0                          => open,
        RXRUNDISP1                          => open,
        USRCODEERR0                         => tied_to_ground_i,
        USRCODEERR1                         => tied_to_ground_i,
        ------------ Receive Ports - Channel Bonding ---------------------
        RXCHANBONDSEQ0                      => open,
        RXCHANBONDSEQ1                      => open,
        RXCHANISALIGNED0                    => open,
        RXCHANISALIGNED1                    => open,
        RXCHANREALIGN0                      => open,
        RXCHANREALIGN1                      => open,
        RXCHBONDI                           => tied_to_ground_vec_i(2 downto 0),
        RXCHBONDMASTER0                     => tied_to_ground_i,
        RXCHBONDMASTER1                     => tied_to_ground_i,
        RXCHBONDO                           => open,
        RXCHBONDSLAVE0                      => tied_to_ground_i,
        RXCHBONDSLAVE1                      => tied_to_ground_i,
        RXENCHANSYNC0                       => tied_to_ground_i,
        RXENCHANSYNC1                       => tied_to_ground_i,
        ------------ Receive Ports - Clock Correction --------------------
        RXCLKCORCNT0                        => open,
        RXCLKCORCNT1                        => open,
        ----- Receive Ports - Comma Detection and Alignment --------------
        RXBYTEISALIGNED0                    => open,
        RXBYTEISALIGNED1                    => open,
        RXBYTEREALIGN0                      => open,
        RXBYTEREALIGN1                      => open,
        RXCOMMADET0                         => open,
        RXCOMMADET1                         => open,
        RXCOMMADETUSE0                      => tied_to_vcc_i,
        RXCOMMADETUSE1                      => tied_to_vcc_i,
        RXENMCOMMAALIGN0                    => RXENCOMMAALIGN_INT,
        RXENMCOMMAALIGN1                    => RXENCOMMAALIGN_INT,
        RXENPCOMMAALIGN0                    => RXENCOMMAALIGN_INT,
        RXENPCOMMAALIGN1                    => RXENCOMMAALIGN_INT,
        RXSLIDE0                            => tied_to_ground_i,
        RXSLIDE1                            => tied_to_ground_i,
        ------------- Receive Ports - PRBS Detection ---------------------
        PRBSCNTRESET0                       => tied_to_ground_i,
        PRBSCNTRESET1                       => tied_to_ground_i,
        RXENPRBSTST0                        => tied_to_ground_vec_i(2 downto 0),
        RXENPRBSTST1                        => tied_to_ground_vec_i(2 downto 0),
        RXPRBSERR0                          => open,
        RXPRBSERR1                          => open,
        --------- Receive Ports - RX Data Path interface -----------------
        RXDATA0                             => RXDATA0,
        RXDATA1                             => RXDATA1,
        RXDATAWIDTH0                        => "01",
        RXDATAWIDTH1                        => "01",
        RXRECCLK0                           => open,
        RXRECCLK1                           => open,
        RXRESET0                            => INITRST_IN,
        RXRESET1                            => INITRST_IN,
        RXUSRCLK0                           => USRCLK_IN,
        RXUSRCLK1                           => USRCLK_IN,
        RXUSRCLK20                          => USRCLK2_IN,
        RXUSRCLK21                          => USRCLK2_IN,
        -- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        GATERXELECIDLE0                     => tied_to_ground_i,
        GATERXELECIDLE1                     => tied_to_ground_i,
        IGNORESIGDET0                       => tied_to_ground_i,
        IGNORESIGDET1                       => tied_to_ground_i,
        RCALINEAST                          => tied_to_ground_vec_i(4 downto 0),
        RCALINWEST                          => tied_to_ground_vec_i(4 downto 0),
        RCALOUTEAST                         => open,
        RCALOUTWEST                         => open,
        RXCDRRESET0                         => tied_to_ground_i,
        RXCDRRESET1                         => tied_to_ground_i,
        RXELECIDLE0                         => open,
        RXELECIDLE1                         => open,
        RXEQMIX0                            => tied_to_ground_vec_i(1 downto 0),
        RXEQMIX1                            => tied_to_ground_vec_i(1 downto 0),
        RXN0                                => RXN0_IN,
        RXN1                                => RXN1_IN,
        RXP0                                => RXP0_IN,
        RXP1                                => RXP1_IN,
        -- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
        RXBUFRESET0                         => tied_to_ground_i,
        RXBUFRESET1                         => tied_to_ground_i,
        RXBUFSTATUS0                        => RXBUFSTATUS0_OUT,
        RXBUFSTATUS1                        => RXBUFSTATUS1_OUT,
        RXENPMAPHASEALIGN0                  => tied_to_ground_i,
        RXENPMAPHASEALIGN1                  => tied_to_ground_i,
        RXPMASETPHASE0                      => tied_to_ground_i,
        RXPMASETPHASE1                      => tied_to_ground_i,
        RXSTATUS0                           => open,
        RXSTATUS1                           => open,
        ----- Receive Ports - RX Loss-of-sync State Machine --------------
        RXLOSSOFSYNC0                       => RXLOSSOFSYNC0_OUT,
        RXLOSSOFSYNC1                       => RXLOSSOFSYNC1_OUT,
        ---- Receive Ports - RX Pipe Control for PCI Express -------------
        PHYSTATUS0                          => open,
        PHYSTATUS1                          => open,
        RXVALID0                            => open,
        RXVALID1                            => open,
        ---------- Receive Ports - RX Polarity Control -------------------
        RXPOLARITY0                         => tied_to_ground_i,
        RXPOLARITY1                         => tied_to_ground_i,
        --- Shared Ports - Dynamic Reconfiguration Port (DRP) ------------
        DADDR                               => tied_to_ground_vec_i(7 downto 0),
        DCLK                                => tied_to_ground_i,
        DEN                                 => tied_to_ground_i,
        DI                                  => tied_to_ground_vec_i(15 downto 0),
        DRDY                                => open,
        DRPDO                               => open,
        DWE                                 => tied_to_ground_i,
        ------------------ TX/RX Datapath Ports --------------------------
        GTPCLKFBEAST                        => open,
        GTPCLKFBSEL0EAST                    => "10",
        GTPCLKFBSEL0WEST                    => "00",
        GTPCLKFBSEL1EAST                    => "11",
        GTPCLKFBSEL1WEST                    => "01",
        GTPCLKFBWEST                        => open,
        GTPCLKOUT0                          => GTPCLKOUT0,
        GTPCLKOUT1                          => open,
        --------- Transmit Ports - 8b10b Encoder Control -----------------
        TXBYPASS8B10B0                      => tied_to_ground_vec_i(3 downto 0),
        TXBYPASS8B10B1                      => tied_to_ground_vec_i(3 downto 0),
        TXCHARDISPMODE0                     => tied_to_ground_vec_i(3 downto 0),
        TXCHARDISPMODE1                     => tied_to_ground_vec_i(3 downto 0),
        TXCHARDISPVAL0                      => tied_to_ground_vec_i(3 downto 0),
        TXCHARDISPVAL1                      => tied_to_ground_vec_i(3 downto 0),
        TXCHARISK0                          => TXCHARISK0,
        TXCHARISK1                          => TXCHARISK1,
        TXENC8B10BUSE0                      => tied_to_vcc_i,
        TXENC8B10BUSE1                      => tied_to_vcc_i,
        TXKERR0                             => open,
        TXKERR1                             => open,
        TXRUNDISP0                          => open,
        TXRUNDISP1                          => open,
        ----- Transmit Ports - TX Buffer and Phase Alignment -------------
        TXBUFSTATUS0                        => open,
        TXBUFSTATUS1                        => open,
        TXENPMAPHASEALIGN0                  => tied_to_ground_i,
        TXENPMAPHASEALIGN1                  => tied_to_ground_i,
        TXPMASETPHASE0                      => tied_to_ground_i,
        TXPMASETPHASE1                      => tied_to_ground_i,
        -------- Transmit Ports - TX Data Path interface -----------------
        TXDATA0                             => TXDATA0,
        TXDATA1                             => TXDATA1,
        TXDATAWIDTH0                        => "01",
        TXDATAWIDTH1                        => "01",
        TXOUTCLK0                           => open,
        TXOUTCLK1                           => open,
        TXRESET0                            => INITRST_IN,
        TXRESET1                            => INITRST_IN,
        TXUSRCLK0                           => USRCLK_IN,
        TXUSRCLK1                           => USRCLK_IN,
        TXUSRCLK20                          => USRCLK2_IN,
        TXUSRCLK21                          => USRCLK2_IN,
        ----- Transmit Ports - TX Driver and OOB signalling --------------
        TXBUFDIFFCTRL0                      => "101",
        TXBUFDIFFCTRL1                      => "101",
        TXDIFFCTRL0                         => "1111", -- 929 mV -> 1000 , max is 1106mV -> 1111
        TXDIFFCTRL1                         => "1111", -- 929 mV -> 1000 , max is 1106mV -> 1111
        TXINHIBIT0                          => tied_to_ground_i,
        TXINHIBIT1                          => tied_to_ground_i,
        TXN0                                => TXN0_OUT,
        TXN1                                => TXN1_OUT,
        TXP0                                => TXP0_OUT,
        TXP1                                => TXP1_OUT,
        TXPREEMPHASIS0                      => "111",
        TXPREEMPHASIS1                      => "111",
        ----------- Transmit Ports - TX PRBS Generator -------------------
        TXENPRBSTST0                        => tied_to_ground_vec_i(2 downto 0),
        TXENPRBSTST1                        => tied_to_ground_vec_i(2 downto 0),
        TXPRBSFORCEERR0                     => tied_to_ground_i,
        TXPRBSFORCEERR1                     => tied_to_ground_i,
        ---------- Transmit Ports - TX Polarity Control ------------------
        TXPOLARITY0                         => tied_to_ground_i,
        TXPOLARITY1                         => tied_to_ground_i,
        ------- Transmit Ports - TX Ports for PCI Express ----------------
        TXDETECTRX0                         => tied_to_ground_i,
        TXDETECTRX1                         => tied_to_ground_i,
        TXELECIDLE0                         => tied_to_ground_i,
        TXELECIDLE1                         => tied_to_ground_i,
        TXPDOWNASYNCH0                      => tied_to_ground_i,
        TXPDOWNASYNCH1                      => tied_to_ground_i,
        ----------- Transmit Ports - TX Ports for SATA -------------------
        TXCOMSTART0                         => tied_to_ground_i,
        TXCOMSTART1                         => tied_to_ground_i,
        TXCOMTYPE0                          => tied_to_ground_i,
        TXCOMTYPE1                          => tied_to_ground_i
     );

end rtl;
