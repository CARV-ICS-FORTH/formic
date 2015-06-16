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
-- Abstract      : Xilinx MicroBlaze Debug Module (MDM) wrapper
--
-- =============================[ CVS Variables ]=============================
--
-- File name     : $RCSfile: xil_mdm.vhd,v $
-- CVS revision  : $Revision: 1.4 $
-- Last modified : $Date: 2012/07/03 16:28:58 $
-- Last author   : $Author: lyberis $
--
-- ===========================================================================

library IEEE;
use IEEE.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library mdm_v2_00_a;
use mdm_v2_00_a.all;

entity xil_mdm is
  port (
    -- Clock and reset
    clk_cpu        : in  std_logic;
    rst_mc         : in  std_logic;
    i_boot_done    : in  std_logic;

    -- Common break signals and system reset
    o_ext_brk      : out std_logic;
    o_ext_nm_brk   : out std_logic;
    o_sys_reset    : out std_logic;

    -- Microblaze 0
    o_mbs0_clk     : out std_logic;
    o_mbs0_tdi     : out std_logic;
    i_mbs0_tdo     : in  std_logic;
    o_mbs0_reg_en  : out std_logic_vector(0 to 7);
    o_mbs0_shift   : out std_logic;
    o_mbs0_capture : out std_logic;
    o_mbs0_update  : out std_logic;
    o_mbs0_reset   : out std_logic;

    -- Microblaze 1
    o_mbs1_clk     : out std_logic;
    o_mbs1_tdi     : out std_logic;
    i_mbs1_tdo     : in  std_logic;
    o_mbs1_reg_en  : out std_logic_vector(0 to 7);
    o_mbs1_shift   : out std_logic;
    o_mbs1_capture : out std_logic;
    o_mbs1_update  : out std_logic;
    o_mbs1_reset   : out std_logic;

    -- Microblaze 2
    o_mbs2_clk     : out std_logic;
    o_mbs2_tdi     : out std_logic;
    i_mbs2_tdo     : in  std_logic;
    o_mbs2_reg_en  : out std_logic_vector(0 to 7);
    o_mbs2_shift   : out std_logic;
    o_mbs2_capture : out std_logic;
    o_mbs2_update  : out std_logic;
    o_mbs2_reset   : out std_logic;

    -- Microblaze 3
    o_mbs3_clk     : out std_logic;
    o_mbs3_tdi     : out std_logic;
    i_mbs3_tdo     : in  std_logic;
    o_mbs3_reg_en  : out std_logic_vector(0 to 7);
    o_mbs3_shift   : out std_logic;
    o_mbs3_capture : out std_logic;
    o_mbs3_update  : out std_logic;
    o_mbs3_reset   : out std_logic;

    -- Microblaze 4
    o_mbs4_clk     : out std_logic;
    o_mbs4_tdi     : out std_logic;
    i_mbs4_tdo     : in  std_logic;
    o_mbs4_reg_en  : out std_logic_vector(0 to 7);
    o_mbs4_shift   : out std_logic;
    o_mbs4_capture : out std_logic;
    o_mbs4_update  : out std_logic;
    o_mbs4_reset   : out std_logic;

    -- Microblaze 5
    o_mbs5_clk     : out std_logic;
    o_mbs5_tdi     : out std_logic;
    i_mbs5_tdo     : in  std_logic;
    o_mbs5_reg_en  : out std_logic_vector(0 to 7);
    o_mbs5_shift   : out std_logic;
    o_mbs5_capture : out std_logic;
    o_mbs5_update  : out std_logic;
    o_mbs5_reset   : out std_logic;

    -- Microblaze 6
    o_mbs6_clk     : out std_logic;
    o_mbs6_tdi     : out std_logic;
    i_mbs6_tdo     : in  std_logic;
    o_mbs6_reg_en  : out std_logic_vector(0 to 7);
    o_mbs6_shift   : out std_logic;
    o_mbs6_capture : out std_logic;
    o_mbs6_update  : out std_logic;
    o_mbs6_reset   : out std_logic;

    -- Microblaze 7
    o_mbs7_clk     : out std_logic;
    o_mbs7_tdi     : out std_logic;
    i_mbs7_tdo     : in  std_logic;
    o_mbs7_reg_en  : out std_logic_vector(0 to 7);
    o_mbs7_shift   : out std_logic;
    o_mbs7_capture : out std_logic;
    o_mbs7_update  : out std_logic;
    o_mbs7_reset   : out std_logic
  );
end xil_mdm;

architecture str of xil_mdm is

  component rst_sync_simple is
    generic (
      CLOCK_CYCLES : integer := 8
    );
    port (
      clk           : in  std_logic;
      rst_async     : in  std_logic;
      deassert      : in  std_logic;
      rst           : out std_logic
    );
  end component;

  component MDM is
    generic (
      C_FAMILY              : string                        := "virtex2";
      C_JTAG_CHAIN          : integer                       := 2;
      C_INTERCONNECT        : integer                       := 1;
      C_BASEADDR            : std_logic_vector(0 to 31)     := X"FFFF_FFFF";
      C_HIGHADDR            : std_logic_vector(0 to 31)     := X"0000_0000";
      C_SPLB_AWIDTH         : integer                       := 32;
      C_SPLB_DWIDTH         : integer                       := 32;
      C_SPLB_P2P            : integer                       := 0;
      C_SPLB_MID_WIDTH      : integer                       := 3;
      C_SPLB_NUM_MASTERS    : integer                       := 8;
      C_SPLB_NATIVE_DWIDTH  : integer                       := 32;
      C_SPLB_SUPPORT_BURSTS : integer                       := 0;
      C_MB_DBG_PORTS        : integer                       := 1;
      C_USE_UART            : integer                       := 1;
      C_S_AXI_ADDR_WIDTH    : integer range 32 to 36        := 32;
      C_S_AXI_DATA_WIDTH    : integer range 32 to 128       := 32
    );

    port (
      -- Global signals
      S_AXI_ACLK    : in std_logic;
      S_AXI_ARESETN : in std_logic;

      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;

      Interrupt     : out std_logic;
      Ext_BRK       : out std_logic;
      Ext_NM_BRK    : out std_logic;
      Debug_SYS_Rst : out std_logic;

      -- AXI signals
      S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWVALID : in  std_logic;
      S_AXI_AWREADY : out std_logic;
      S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WVALID  : in  std_logic;
      S_AXI_WREADY  : out std_logic;
      S_AXI_BRESP   : out std_logic_vector(1 downto 0);
      S_AXI_BVALID  : out std_logic;
      S_AXI_BREADY  : in  std_logic;
      S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID : in  std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP   : out std_logic_vector(1 downto 0);
      S_AXI_RVALID  : out std_logic;
      S_AXI_RREADY  : in  std_logic;

      -- PLBv46 signals
      PLB_ABus       : in std_logic_vector(0 to 31);
      PLB_UABus      : in std_logic_vector(0 to 31);
      PLB_PAValid    : in std_logic;
      PLB_SAValid    : in std_logic;
      PLB_rdPrim     : in std_logic;
      PLB_wrPrim     : in std_logic;
      PLB_masterID   : in std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
      PLB_abort      : in std_logic;
      PLB_busLock    : in std_logic;
      PLB_RNW        : in std_logic;
      PLB_BE         : in std_logic_vector(0 to (C_SPLB_DWIDTH/8) - 1);
      PLB_MSize      : in std_logic_vector(0 to 1);
      PLB_size       : in std_logic_vector(0 to 3);
      PLB_type       : in std_logic_vector(0 to 2);
      PLB_lockErr    : in std_logic;
      PLB_wrDBus     : in std_logic_vector(0 to C_SPLB_DWIDTH-1);
      PLB_wrBurst    : in std_logic;
      PLB_rdBurst    : in std_logic;
      PLB_wrPendReq  : in std_logic;
      PLB_rdPendReq  : in std_logic;
      PLB_wrPendPri  : in std_logic_vector(0 to 1);
      PLB_rdPendPri  : in std_logic_vector(0 to 1);
      PLB_reqPri     : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);

      Sl_addrAck     : out std_logic;
      Sl_SSize       : out std_logic_vector(0 to 1);
      Sl_wait        : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck      : out std_logic;
      Sl_wrComp      : out std_logic;
      Sl_wrBTerm     : out std_logic;
      Sl_rdDBus      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
      Sl_rdWdAddr    : out std_logic_vector(0 to 3);
      Sl_rdDAck      : out std_logic;
      Sl_rdComp      : out std_logic;
      Sl_rdBTerm     : out std_logic;
      Sl_MBusy       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MWrErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MRdErr      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
      Sl_MIRQ        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);

      -- MicroBlaze Debug Signals
      Dbg_Clk_0     : out std_logic;
      Dbg_TDI_0     : out std_logic;
      Dbg_TDO_0     : in  std_logic;
      Dbg_Reg_En_0  : out std_logic_vector(0 to 7);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0   : out std_logic;
      Dbg_Update_0  : out std_logic;
      Dbg_Rst_0     : out std_logic;

      Dbg_Clk_1     : out std_logic;
      Dbg_TDI_1     : out std_logic;
      Dbg_TDO_1     : in  std_logic;
      Dbg_Reg_En_1  : out std_logic_vector(0 to 7);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1   : out std_logic;
      Dbg_Update_1  : out std_logic;
      Dbg_Rst_1     : out std_logic;

      Dbg_Clk_2     : out std_logic;
      Dbg_TDI_2     : out std_logic;
      Dbg_TDO_2     : in  std_logic;
      Dbg_Reg_En_2  : out std_logic_vector(0 to 7);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2   : out std_logic;
      Dbg_Update_2  : out std_logic;
      Dbg_Rst_2     : out std_logic;

      Dbg_Clk_3     : out std_logic;
      Dbg_TDI_3     : out std_logic;
      Dbg_TDO_3     : in  std_logic;
      Dbg_Reg_En_3  : out std_logic_vector(0 to 7);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3   : out std_logic;
      Dbg_Update_3  : out std_logic;
      Dbg_Rst_3     : out std_logic;

      Dbg_Clk_4     : out std_logic;
      Dbg_TDI_4     : out std_logic;
      Dbg_TDO_4     : in  std_logic;
      Dbg_Reg_En_4  : out std_logic_vector(0 to 7);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4   : out std_logic;
      Dbg_Update_4  : out std_logic;
      Dbg_Rst_4     : out std_logic;

      Dbg_Clk_5     : out std_logic;
      Dbg_TDI_5     : out std_logic;
      Dbg_TDO_5     : in  std_logic;
      Dbg_Reg_En_5  : out std_logic_vector(0 to 7);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5   : out std_logic;
      Dbg_Update_5  : out std_logic;
      Dbg_Rst_5     : out std_logic;

      Dbg_Clk_6     : out std_logic;
      Dbg_TDI_6     : out std_logic;
      Dbg_TDO_6     : in  std_logic;
      Dbg_Reg_En_6  : out std_logic_vector(0 to 7);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6   : out std_logic;
      Dbg_Update_6  : out std_logic;
      Dbg_Rst_6     : out std_logic;

      Dbg_Clk_7     : out std_logic;
      Dbg_TDI_7     : out std_logic;
      Dbg_TDO_7     : in  std_logic;
      Dbg_Reg_En_7  : out std_logic_vector(0 to 7);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7   : out std_logic;
      Dbg_Update_7  : out std_logic;
      Dbg_Rst_7     : out std_logic;

      bscan_tdi     : out std_logic;
      bscan_reset   : out std_logic;
      bscan_shift   : out std_logic;
      bscan_update  : out std_logic;
      bscan_capture : out std_logic;
      bscan_sel1    : out std_logic;
      bscan_drck1   : out std_logic;
      bscan_tdo1    : in  std_logic;

      Ext_JTAG_DRCK    : out std_logic;
      Ext_JTAG_RESET   : out std_logic;
      Ext_JTAG_SEL     : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT   : out std_logic;
      Ext_JTAG_UPDATE  : out std_logic;
      Ext_JTAG_TDI     : out std_logic;
      Ext_JTAG_TDO     : in  std_logic
    );
  end component;
  
  constant net_gnd       : std_logic := '0';
  constant net_gnd0_bus  : std_logic_vector (0 to 0)  := "0";
  constant net_gnd2      : std_logic_vector (0 to 1)  := "00";
  constant net_gnd3      : std_logic_vector (0 to 2)  := "000";
  constant net_gnd4      : std_logic_vector (0 to 3)  := "0000";
  constant net_gnd8      : std_logic_vector (0 to 7)  := "00000000";
  constant net_gnd16     : std_logic_vector (0 to 15) := "0000000000000000";
  constant net_gnd32     : std_logic_vector (0 to 31) := X"00000000";

  signal   rst_cpu       : std_logic;
  signal   not_rst_cpu   : std_logic;

begin

  not_rst_cpu <= not rst_cpu;

  i0_rst_sync_simple: rst_sync_simple generic map (
    CLOCK_CYCLES  => 2
  ) port map (
    clk           => clk_cpu,
    rst_async     => rst_mc,
    deassert      => i_boot_done,
    rst           => rst_cpu
  );

  i0_mdm: mdm generic map (
    C_FAMILY              => "spartan6",
    C_MB_DBG_PORTS        => 8,
    C_JTAG_CHAIN          => 2,
    C_USE_UART            => 0,
    C_INTERCONNECT        => 2,
    C_BASEADDR            => X"FFFF_FFFF",
    C_HIGHADDR            => X"0000_0000",
    C_SPLB_AWIDTH         => 32,
    C_SPLB_DWIDTH         => 32,
    C_SPLB_P2P            => 0,
    C_SPLB_MID_WIDTH      => 3,
    C_SPLB_NUM_MASTERS    => 8,
    C_SPLB_NATIVE_DWIDTH  => 32,
    C_SPLB_SUPPORT_BURSTS => 0,
    C_S_AXI_ADDR_WIDTH    => 32,
    C_S_AXI_DATA_WIDTH    => 32
  ) port map (

    -- Global signals
    S_AXI_ACLK            => clk_cpu,
    S_AXI_ARESETN         => not_rst_cpu,
    SPLB_Clk              => clk_cpu,
    SPLB_Rst              => rst_cpu,
    Interrupt             => open,
    Ext_BRK               => o_ext_brk,
    Ext_NM_BRK            => o_ext_nm_brk,
    Debug_SYS_Rst         => o_sys_reset,

    -- MicroBlaze Debug Signals
    Dbg_Clk_0             => o_mbs0_clk,
    Dbg_TDI_0             => o_mbs0_tdi,
    Dbg_TDO_0             => i_mbs0_tdo,
    Dbg_Reg_En_0          => o_mbs0_reg_en,
    Dbg_Capture_0         => o_mbs0_capture,
    Dbg_Shift_0           => o_mbs0_shift,
    Dbg_Update_0          => o_mbs0_update,
    Dbg_Rst_0             => o_mbs0_reset,
    
    Dbg_Clk_1             => o_mbs1_clk,
    Dbg_TDI_1             => o_mbs1_tdi,
    Dbg_TDO_1             => i_mbs1_tdo,
    Dbg_Reg_En_1          => o_mbs1_reg_en,
    Dbg_Capture_1         => o_mbs1_capture,
    Dbg_Shift_1           => o_mbs1_shift,
    Dbg_Update_1          => o_mbs1_update,
    Dbg_Rst_1             => o_mbs1_reset,

    Dbg_Clk_2             => o_mbs2_clk,
    Dbg_TDI_2             => o_mbs2_tdi,
    Dbg_TDO_2             => i_mbs2_tdo,
    Dbg_Reg_En_2          => o_mbs2_reg_en,
    Dbg_Capture_2         => o_mbs2_capture,
    Dbg_Shift_2           => o_mbs2_shift,
    Dbg_Update_2          => o_mbs2_update,
    Dbg_Rst_2             => o_mbs2_reset,

    Dbg_Clk_3             => o_mbs3_clk,
    Dbg_TDI_3             => o_mbs3_tdi,
    Dbg_TDO_3             => i_mbs3_tdo,
    Dbg_Reg_En_3          => o_mbs3_reg_en,
    Dbg_Capture_3         => o_mbs3_capture,
    Dbg_Shift_3           => o_mbs3_shift,
    Dbg_Update_3          => o_mbs3_update,
    Dbg_Rst_3             => o_mbs3_reset,

    Dbg_Clk_4             => o_mbs4_clk,
    Dbg_TDI_4             => o_mbs4_tdi,
    Dbg_TDO_4             => i_mbs4_tdo,
    Dbg_Reg_En_4          => o_mbs4_reg_en,
    Dbg_Capture_4         => o_mbs4_capture,
    Dbg_Shift_4           => o_mbs4_shift,
    Dbg_Update_4          => o_mbs4_update,
    Dbg_Rst_4             => o_mbs4_reset,

    Dbg_Clk_5             => o_mbs5_clk,
    Dbg_TDI_5             => o_mbs5_tdi,
    Dbg_TDO_5             => i_mbs5_tdo,
    Dbg_Reg_En_5          => o_mbs5_reg_en,
    Dbg_Capture_5         => o_mbs5_capture,
    Dbg_Shift_5           => o_mbs5_shift,
    Dbg_Update_5          => o_mbs5_update,
    Dbg_Rst_5             => o_mbs5_reset,

    Dbg_Clk_6             => o_mbs6_clk,
    Dbg_TDI_6             => o_mbs6_tdi,
    Dbg_TDO_6             => i_mbs6_tdo,
    Dbg_Reg_En_6          => o_mbs6_reg_en,
    Dbg_Capture_6         => o_mbs6_capture,
    Dbg_Shift_6           => o_mbs6_shift,
    Dbg_Update_6          => o_mbs6_update,
    Dbg_Rst_6             => o_mbs6_reset,

    Dbg_Clk_7             => o_mbs7_clk,
    Dbg_TDI_7             => o_mbs7_tdi,
    Dbg_TDO_7             => i_mbs7_tdo,
    Dbg_Reg_En_7          => o_mbs7_reg_en,
    Dbg_Capture_7         => o_mbs7_capture,
    Dbg_Shift_7           => o_mbs7_shift,
    Dbg_Update_7          => o_mbs7_update,
    Dbg_Rst_7             => o_mbs7_reset,

    -- AXI signals
    S_AXI_AWADDR          => net_gnd32,
    S_AXI_AWVALID         => net_gnd,
    S_AXI_AWREADY         => open,
    S_AXI_WDATA           => net_gnd32,
    S_AXI_WSTRB           => net_gnd4,
    S_AXI_WVALID          => net_gnd,
    S_AXI_WREADY          => open,
    S_AXI_BRESP           => open,
    S_AXI_BVALID          => open,
    S_AXI_BREADY          => net_gnd,
    S_AXI_ARADDR          => net_gnd32,
    S_AXI_ARVALID         => net_gnd,
    S_AXI_ARREADY         => open,
    S_AXI_RDATA           => open,
    S_AXI_RRESP           => open,
    S_AXI_RVALID          => open,
    S_AXI_RREADY          => net_gnd,

    -- PLBv46 signals
    PLB_ABus              => net_gnd32,
    PLB_UABus             => net_gnd32,
    PLB_PAValid           => net_gnd,
    PLB_SAValid           => net_gnd,
    PLB_rdPrim            => net_gnd,
    PLB_wrPrim            => net_gnd,
    PLB_masterID          => net_gnd3,
    PLB_abort             => net_gnd,
    PLB_busLock           => net_gnd,
    PLB_RNW               => net_gnd,
    PLB_BE                => net_gnd4,
    PLB_MSize             => net_gnd2,
    PLB_size              => net_gnd4,
    PLB_type              => net_gnd3,
    PLB_lockErr           => net_gnd,
    PLB_wrDBus            => net_gnd32,
    PLB_wrBurst           => net_gnd,
    PLB_rdBurst           => net_gnd,
    PLB_wrPendReq         => net_gnd,
    PLB_rdPendReq         => net_gnd,
    PLB_wrPendPri         => net_gnd2,
    PLB_rdPendPri         => net_gnd2,
    PLB_reqPri            => net_gnd2,
    PLB_TAttribute        => net_gnd16,
    Sl_addrAck            => open,
    Sl_SSize              => open,
    Sl_wait               => open,
    Sl_rearbitrate        => open,
    Sl_wrDAck             => open,
    Sl_wrComp             => open,
    Sl_wrBTerm            => open,
    Sl_rdDBus             => open,
    Sl_rdWdAddr           => open,
    Sl_rdDAck             => open,
    Sl_rdComp             => open,
    Sl_rdBTerm            => open,
    Sl_MBusy              => open,
    Sl_MWrErr             => open,
    Sl_MRdErr             => open,
    Sl_MIRQ               => open,

    -- Chipscope ICON interface
    bscan_tdi             => open,
    bscan_reset           => open,
    bscan_shift           => open,
    bscan_update          => open,
    bscan_capture         => open,
    bscan_sel1            => open,
    bscan_drck1           => open,
    bscan_tdo1            => net_gnd,

    -- Microblaze Trace interface
    Ext_JTAG_DRCK         => open,
    Ext_JTAG_RESET        => open,
    Ext_JTAG_SEL          => open,
    Ext_JTAG_CAPTURE      => open,
    Ext_JTAG_SHIFT        => open,
    Ext_JTAG_UPDATE       => open,
    Ext_JTAG_TDI          => open,
    Ext_JTAG_TDO          => net_gnd
  );


end str;




