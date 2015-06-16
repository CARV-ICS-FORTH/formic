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
-- Abstract      : Xilinx MicroBlaze block wrapper
--
-- =============================[ CVS Variables ]=============================
--
-- File name     : $RCSfile: xil_microblaze.vhd,v $
-- CVS revision  : $Revision: 1.15 $
-- Last modified : $Date: 2012/07/03 16:28:58 $
-- Last author   : $Author: lyberis $
--
-- ===========================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library microblaze_v8_00_b;
use microblaze_v8_00_b.all;


entity xil_microblaze is
  generic (

    NEED_TRACING    : integer;
    NEED_DEBUG      : integer

  );
  port (

    -- Core interface
    clk_cpu         : in std_logic;
    rst_cpu         : in std_logic;
    i_ctl_interrupt : in std_logic;

    -- Instruction LMB
    o_iadr          : out std_logic_vector(0 to 31);
    o_istrobe       : out std_logic;
    o_ifetch        : out std_logic;
    i_idata         : in std_logic_vector(0 to 31);
    i_iready        : in std_logic;

    -- Data LMB
    o_dadr          : out std_logic_vector(0 to 31);
    o_dstrobe       : out std_logic;
    o_drd           : out std_logic;
    o_dwr           : out std_logic;
    o_ben           : out std_logic_vector(0 to 3);
    o_dwdata        : out std_logic_vector(0 to 31);
    i_drdata        : in std_logic_vector(0 to 31);
    i_dready        : in std_logic;

    -- Trace interface
    o_ctl_trace_daccess    : out std_logic;
    o_ctl_trace_inst_adr   : out std_logic_vector(0 to 31);
    o_ctl_trace_data_adr   : out std_logic_vector(0 to 31);
    o_ctl_trace_energy     : out std_logic;
    o_ctl_trace_energy_val : out std_logic_vector(2 downto 0);

    -- MDM Debug interface
    i_mdm_brk              : in  std_logic;
    i_mdm_nm_brk           : in  std_logic;
    i_mdm_clk              : in  std_logic;
    i_mdm_tdi              : in  std_logic;
    o_mdm_tdo              : out std_logic;
    i_mdm_reg_en           : in  std_logic_vector(0 to 7);
    i_mdm_shift            : in  std_logic;
    i_mdm_capture          : in  std_logic;
    i_mdm_update           : in  std_logic;
    i_mdm_reset            : in  std_logic
  );

  attribute x_core_info : STRING;
  attribute x_core_info of xil_microblaze : entity is "microblaze_v8_00_b";

end xil_microblaze;

architecture str of xil_microblaze is

  component microblaze is
    generic (
      C_SCO : integer;
      C_FREQ : integer;
      C_DATA_SIZE : integer;
      C_DYNAMIC_BUS_SIZING : integer;
      C_FAMILY : string;
      C_INSTANCE : string;
      C_FAULT_TOLERANT : integer;
      C_ECC_USE_CE_EXCEPTION : integer;
      C_ENDIANNESS : integer;
      C_AREA_OPTIMIZED : integer;
      C_OPTIMIZATION : integer;
      C_INTERCONNECT : integer;
      C_STREAM_INTERCONNECT : integer;
      C_DPLB_DWIDTH : integer;
      C_DPLB_NATIVE_DWIDTH : integer;
      C_DPLB_BURST_EN : integer;
      C_DPLB_P2P : integer;
      C_IPLB_DWIDTH : integer;
      C_IPLB_NATIVE_DWIDTH : integer;
      C_IPLB_BURST_EN : integer;
      C_IPLB_P2P : integer;
      C_M_AXI_DP_THREAD_ID_WIDTH : integer;
      C_M_AXI_DP_DATA_WIDTH : integer;
      C_M_AXI_DP_ADDR_WIDTH : integer;
      C_M_AXI_DP_EXCLUSIVE_ACCESS : integer;
      C_M_AXI_IP_THREAD_ID_WIDTH : integer;
      C_M_AXI_IP_DATA_WIDTH : integer;
      C_M_AXI_IP_ADDR_WIDTH : integer;
      C_D_AXI : integer;
      C_D_PLB : integer;
      C_D_LMB : integer;
      C_I_AXI : integer;
      C_I_PLB : integer;
      C_I_LMB : integer;
      C_USE_MSR_INSTR : integer;
      C_USE_PCMP_INSTR : integer;
      C_USE_BARREL : integer;
      C_USE_DIV : integer;
      C_USE_HW_MUL : integer;
      C_USE_FPU : integer;
      C_UNALIGNED_EXCEPTIONS : integer;
      C_ILL_OPCODE_EXCEPTION : integer;
      C_M_AXI_I_BUS_EXCEPTION : integer;
      C_M_AXI_D_BUS_EXCEPTION : integer;
      C_IPLB_BUS_EXCEPTION : integer;
      C_DPLB_BUS_EXCEPTION : integer;
      C_DIV_ZERO_EXCEPTION : integer;
      C_FPU_EXCEPTION : integer;
      C_FSL_EXCEPTION : integer;
      C_PVR : integer;
      C_PVR_USER1 : std_logic_vector(0 to 7);
      C_PVR_USER2 : std_logic_vector(0 to 31);
      C_DEBUG_ENABLED : integer;
      C_NUMBER_OF_PC_BRK : integer;
      C_NUMBER_OF_RD_ADDR_BRK : integer;
      C_NUMBER_OF_WR_ADDR_BRK : integer;
      C_INTERRUPT_IS_EDGE : integer;
      C_EDGE_IS_POSITIVE : integer;
      C_RESET_MSR : std_logic_vector;
      C_OPCODE_0x0_ILLEGAL : integer;
      C_FSL_LINKS : integer;
      C_FSL_DATA_SIZE : integer;
      C_USE_EXTENDED_FSL_INSTR : integer;
      C_M0_AXIS_DATA_WIDTH : integer;
      C_S0_AXIS_DATA_WIDTH : integer;
      C_M1_AXIS_DATA_WIDTH : integer;
      C_S1_AXIS_DATA_WIDTH : integer;
      C_M2_AXIS_DATA_WIDTH : integer;
      C_S2_AXIS_DATA_WIDTH : integer;
      C_M3_AXIS_DATA_WIDTH : integer;
      C_S3_AXIS_DATA_WIDTH : integer;
      C_M4_AXIS_DATA_WIDTH : integer;
      C_S4_AXIS_DATA_WIDTH : integer;
      C_M5_AXIS_DATA_WIDTH : integer;
      C_S5_AXIS_DATA_WIDTH : integer;
      C_M6_AXIS_DATA_WIDTH : integer;
      C_S6_AXIS_DATA_WIDTH : integer;
      C_M7_AXIS_DATA_WIDTH : integer;
      C_S7_AXIS_DATA_WIDTH : integer;
      C_M8_AXIS_DATA_WIDTH : integer;
      C_S8_AXIS_DATA_WIDTH : integer;
      C_M9_AXIS_DATA_WIDTH : integer;
      C_S9_AXIS_DATA_WIDTH : integer;
      C_M10_AXIS_DATA_WIDTH : integer;
      C_S10_AXIS_DATA_WIDTH : integer;
      C_M11_AXIS_DATA_WIDTH : integer;
      C_S11_AXIS_DATA_WIDTH : integer;
      C_M12_AXIS_DATA_WIDTH : integer;
      C_S12_AXIS_DATA_WIDTH : integer;
      C_M13_AXIS_DATA_WIDTH : integer;
      C_S13_AXIS_DATA_WIDTH : integer;
      C_M14_AXIS_DATA_WIDTH : integer;
      C_S14_AXIS_DATA_WIDTH : integer;
      C_M15_AXIS_DATA_WIDTH : integer;
      C_S15_AXIS_DATA_WIDTH : integer;
      C_ICACHE_BASEADDR : std_logic_vector;
      C_ICACHE_HIGHADDR : std_logic_vector;
      C_USE_ICACHE : integer;
      C_ALLOW_ICACHE_WR : integer;
      C_ADDR_TAG_BITS : integer;
      C_CACHE_BYTE_SIZE : integer;
      C_ICACHE_USE_FSL : integer;
      C_ICACHE_LINE_LEN : integer;
      C_ICACHE_ALWAYS_USED : integer;
      C_ICACHE_INTERFACE : integer;
      C_ICACHE_VICTIMS : integer;
      C_ICACHE_STREAMS : integer;
      C_ICACHE_FORCE_TAG_LUTRAM : integer;
      C_ICACHE_DATA_WIDTH : integer;
      C_M_AXI_IC_THREAD_ID_WIDTH : integer;
      C_M_AXI_IC_DATA_WIDTH : integer;
      C_M_AXI_IC_ADDR_WIDTH : integer;
      C_DCACHE_BASEADDR : std_logic_vector;
      C_DCACHE_HIGHADDR : std_logic_vector;
      C_USE_DCACHE : integer;
      C_ALLOW_DCACHE_WR : integer;
      C_DCACHE_ADDR_TAG : integer;
      C_DCACHE_BYTE_SIZE : integer;
      C_DCACHE_USE_FSL : integer;
      C_DCACHE_LINE_LEN : integer;
      C_DCACHE_ALWAYS_USED : integer;
      C_DCACHE_INTERFACE : integer;
      C_DCACHE_USE_WRITEBACK : integer;
      C_DCACHE_VICTIMS : integer;
      C_DCACHE_FORCE_TAG_LUTRAM : integer;
      C_DCACHE_DATA_WIDTH : integer;
      C_M_AXI_DC_THREAD_ID_WIDTH : integer;
      C_M_AXI_DC_DATA_WIDTH : integer;
      C_M_AXI_DC_ADDR_WIDTH : integer;
      C_M_AXI_DC_EXCLUSIVE_ACCESS : integer;
      C_USE_MMU : integer;
      C_MMU_DTLB_SIZE : integer;
      C_MMU_ITLB_SIZE : integer;
      C_MMU_TLB_ACCESS : integer;
      C_MMU_ZONES : integer;
      C_USE_INTERRUPT : integer;
      C_USE_EXT_BRK : integer;
      C_USE_EXT_NM_BRK : integer;
      C_USE_BRANCH_TARGET_CACHE : integer;
      C_BRANCH_TARGET_CACHE_SIZE : integer
    );
    port (
      CLK : in std_logic;
      RESET : in std_logic;
      MB_RESET : in std_logic;
      INTERRUPT : in std_logic;
      EXT_BRK : in std_logic;
      EXT_NM_BRK : in std_logic;
      DBG_STOP : in std_logic;
      MB_Halted : out std_logic;
      MB_Error : out std_logic;
      INSTR : in std_logic_vector(0 to 31);
      IREADY : in std_logic;
      IWAIT : in std_logic;
      ICE : in std_logic;
      IUE : in std_logic;
      INSTR_ADDR : out std_logic_vector(0 to 31);
      IFETCH : out std_logic;
      I_AS : out std_logic;
      IPLB_M_ABort : out std_logic;
      IPLB_M_ABus : out std_logic_vector(0 to 31);
      IPLB_M_UABus : out std_logic_vector(0 to 31);
      IPLB_M_BE : out std_logic_vector(0 to (C_IPLB_DWIDTH-1)/8);
      IPLB_M_busLock : out std_logic;
      IPLB_M_lockErr : out std_logic;
      IPLB_M_MSize : out std_logic_vector(0 to 1);
      IPLB_M_priority : out std_logic_vector(0 to 1);
      IPLB_M_rdBurst : out std_logic;
      IPLB_M_request : out std_logic;
      IPLB_M_RNW : out std_logic;
      IPLB_M_size : out std_logic_vector(0 to 3);
      IPLB_M_TAttribute : out std_logic_vector(0 to 15);
      IPLB_M_type : out std_logic_vector(0 to 2);
      IPLB_M_wrBurst : out std_logic;
      IPLB_M_wrDBus : out std_logic_vector(0 to C_IPLB_DWIDTH-1);
      IPLB_MBusy : in std_logic;
      IPLB_MRdErr : in std_logic;
      IPLB_MWrErr : in std_logic;
      IPLB_MIRQ : in std_logic;
      IPLB_MWrBTerm : in std_logic;
      IPLB_MWrDAck : in std_logic;
      IPLB_MAddrAck : in std_logic;
      IPLB_MRdBTerm : in std_logic;
      IPLB_MRdDAck : in std_logic;
      IPLB_MRdDBus : in std_logic_vector(0 to C_IPLB_DWIDTH-1);
      IPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      IPLB_MRearbitrate : in std_logic;
      IPLB_MSSize : in std_logic_vector(0 to 1);
      IPLB_MTimeout : in std_logic;
      DATA_READ : in std_logic_vector(0 to 31);
      DREADY : in std_logic;
      DWAIT : in std_logic;
      DCE : in std_logic;
      DUE : in std_logic;
      DATA_WRITE : out std_logic_vector(0 to 31);
      DATA_ADDR : out std_logic_vector(0 to 31);
      D_AS : out std_logic;
      READ_STROBE : out std_logic;
      WRITE_STROBE : out std_logic;
      BYTE_ENABLE : out std_logic_vector(0 to 3);
      DPLB_M_ABort : out std_logic;
      DPLB_M_ABus : out std_logic_vector(0 to 31);
      DPLB_M_UABus : out std_logic_vector(0 to 31);
      DPLB_M_BE : out std_logic_vector(0 to (C_DPLB_DWIDTH-1)/8);
      DPLB_M_busLock : out std_logic;
      DPLB_M_lockErr : out std_logic;
      DPLB_M_MSize : out std_logic_vector(0 to 1);
      DPLB_M_priority : out std_logic_vector(0 to 1);
      DPLB_M_rdBurst : out std_logic;
      DPLB_M_request : out std_logic;
      DPLB_M_RNW : out std_logic;
      DPLB_M_size : out std_logic_vector(0 to 3);
      DPLB_M_TAttribute : out std_logic_vector(0 to 15);
      DPLB_M_type : out std_logic_vector(0 to 2);
      DPLB_M_wrBurst : out std_logic;
      DPLB_M_wrDBus : out std_logic_vector(0 to C_DPLB_DWIDTH-1);
      DPLB_MBusy : in std_logic;
      DPLB_MRdErr : in std_logic;
      DPLB_MWrErr : in std_logic;
      DPLB_MIRQ : in std_logic;
      DPLB_MWrBTerm : in std_logic;
      DPLB_MWrDAck : in std_logic;
      DPLB_MAddrAck : in std_logic;
      DPLB_MRdBTerm : in std_logic;
      DPLB_MRdDAck : in std_logic;
      DPLB_MRdDBus : in std_logic_vector(0 to C_DPLB_DWIDTH-1);
      DPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      DPLB_MRearbitrate : in std_logic;
      DPLB_MSSize : in std_logic_vector(0 to 1);
      DPLB_MTimeout : in std_logic;
      M_AXI_IP_AWID : out std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_AWADDR : out std_logic_vector((C_M_AXI_IP_ADDR_WIDTH-1) downto 0);
      M_AXI_IP_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_IP_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_IP_AWLOCK : out std_logic;
      M_AXI_IP_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_IP_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_IP_AWVALID : out std_logic;
      M_AXI_IP_AWREADY : in std_logic;
      M_AXI_IP_WDATA : out std_logic_vector((C_M_AXI_IP_DATA_WIDTH-1) downto 0);
      M_AXI_IP_WSTRB : out std_logic_vector(((C_M_AXI_IP_DATA_WIDTH/8)-1) downto 0);
      M_AXI_IP_WLAST : out std_logic;
      M_AXI_IP_WVALID : out std_logic;
      M_AXI_IP_WREADY : in std_logic;
      M_AXI_IP_BID : in std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_IP_BVALID : in std_logic;
      M_AXI_IP_BREADY : out std_logic;
      M_AXI_IP_ARID : out std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_ARADDR : out std_logic_vector((C_M_AXI_IP_ADDR_WIDTH-1) downto 0);
      M_AXI_IP_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_IP_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_IP_ARLOCK : out std_logic;
      M_AXI_IP_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_IP_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_IP_ARVALID : out std_logic;
      M_AXI_IP_ARREADY : in std_logic;
      M_AXI_IP_RID : in std_logic_vector((C_M_AXI_IP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IP_RDATA : in std_logic_vector((C_M_AXI_IP_DATA_WIDTH-1) downto 0);
      M_AXI_IP_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_IP_RLAST : in std_logic;
      M_AXI_IP_RVALID : in std_logic;
      M_AXI_IP_RREADY : out std_logic;
      M_AXI_DP_AWID : out std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_AWADDR : out std_logic_vector((C_M_AXI_DP_ADDR_WIDTH-1) downto 0);
      M_AXI_DP_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_DP_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_DP_AWLOCK : out std_logic;
      M_AXI_DP_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_DP_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_DP_AWVALID : out std_logic;
      M_AXI_DP_AWREADY : in std_logic;
      M_AXI_DP_WDATA : out std_logic_vector((C_M_AXI_DP_DATA_WIDTH-1) downto 0);
      M_AXI_DP_WSTRB : out std_logic_vector(((C_M_AXI_DP_DATA_WIDTH/8)-1) downto 0);
      M_AXI_DP_WLAST : out std_logic;
      M_AXI_DP_WVALID : out std_logic;
      M_AXI_DP_WREADY : in std_logic;
      M_AXI_DP_BID : in std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_DP_BVALID : in std_logic;
      M_AXI_DP_BREADY : out std_logic;
      M_AXI_DP_ARID : out std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_ARADDR : out std_logic_vector((C_M_AXI_DP_ADDR_WIDTH-1) downto 0);
      M_AXI_DP_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_DP_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_DP_ARLOCK : out std_logic;
      M_AXI_DP_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_DP_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_DP_ARVALID : out std_logic;
      M_AXI_DP_ARREADY : in std_logic;
      M_AXI_DP_RID : in std_logic_vector((C_M_AXI_DP_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DP_RDATA : in std_logic_vector((C_M_AXI_DP_DATA_WIDTH-1) downto 0);
      M_AXI_DP_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_DP_RLAST : in std_logic;
      M_AXI_DP_RVALID : in std_logic;
      M_AXI_DP_RREADY : out std_logic;
      M_AXI_IC_AWID : out std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_AWADDR : out std_logic_vector((C_M_AXI_IC_ADDR_WIDTH-1) downto 0);
      M_AXI_IC_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_IC_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_IC_AWLOCK : out std_logic;
      M_AXI_IC_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_IC_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_IC_AWVALID : out std_logic;
      M_AXI_IC_AWREADY : in std_logic;
      M_AXI_IC_WDATA : out std_logic_vector((C_M_AXI_IC_DATA_WIDTH-1) downto 0);
      M_AXI_IC_WSTRB : out std_logic_vector(((C_M_AXI_IC_DATA_WIDTH/8)-1) downto 0);
      M_AXI_IC_WLAST : out std_logic;
      M_AXI_IC_WVALID : out std_logic;
      M_AXI_IC_WREADY : in std_logic;
      M_AXI_IC_BID : in std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_IC_BVALID : in std_logic;
      M_AXI_IC_BREADY : out std_logic;
      M_AXI_IC_ARID : out std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_ARADDR : out std_logic_vector((C_M_AXI_IC_ADDR_WIDTH-1) downto 0);
      M_AXI_IC_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_IC_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_IC_ARLOCK : out std_logic;
      M_AXI_IC_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_IC_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_IC_ARVALID : out std_logic;
      M_AXI_IC_ARREADY : in std_logic;
      M_AXI_IC_RID : in std_logic_vector((C_M_AXI_IC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_IC_RDATA : in std_logic_vector((C_M_AXI_IC_DATA_WIDTH-1) downto 0);
      M_AXI_IC_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_IC_RLAST : in std_logic;
      M_AXI_IC_RVALID : in std_logic;
      M_AXI_IC_RREADY : out std_logic;
      M_AXI_DC_AWID : out std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_AWADDR : out std_logic_vector((C_M_AXI_DC_ADDR_WIDTH-1) downto 0);
      M_AXI_DC_AWLEN : out std_logic_vector(7 downto 0);
      M_AXI_DC_AWSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWBURST : out std_logic_vector(1 downto 0);
      M_AXI_DC_AWLOCK : out std_logic;
      M_AXI_DC_AWCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWPROT : out std_logic_vector(2 downto 0);
      M_AXI_DC_AWQOS : out std_logic_vector(3 downto 0);
      M_AXI_DC_AWVALID : out std_logic;
      M_AXI_DC_AWREADY : in std_logic;
      M_AXI_DC_WDATA : out std_logic_vector((C_M_AXI_DC_DATA_WIDTH-1) downto 0);
      M_AXI_DC_WSTRB : out std_logic_vector(((C_M_AXI_DC_DATA_WIDTH/8)-1) downto 0);
      M_AXI_DC_WLAST : out std_logic;
      M_AXI_DC_WVALID : out std_logic;
      M_AXI_DC_WREADY : in std_logic;
      M_AXI_DC_BID : in std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_BRESP : in std_logic_vector(1 downto 0);
      M_AXI_DC_BVALID : in std_logic;
      M_AXI_DC_BREADY : out std_logic;
      M_AXI_DC_ARID : out std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_ARADDR : out std_logic_vector((C_M_AXI_DC_ADDR_WIDTH-1) downto 0);
      M_AXI_DC_ARLEN : out std_logic_vector(7 downto 0);
      M_AXI_DC_ARSIZE : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARBURST : out std_logic_vector(1 downto 0);
      M_AXI_DC_ARLOCK : out std_logic;
      M_AXI_DC_ARCACHE : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARPROT : out std_logic_vector(2 downto 0);
      M_AXI_DC_ARQOS : out std_logic_vector(3 downto 0);
      M_AXI_DC_ARVALID : out std_logic;
      M_AXI_DC_ARREADY : in std_logic;
      M_AXI_DC_RID : in std_logic_vector((C_M_AXI_DC_THREAD_ID_WIDTH-1) downto 0);
      M_AXI_DC_RDATA : in std_logic_vector((C_M_AXI_DC_DATA_WIDTH-1) downto 0);
      M_AXI_DC_RRESP : in std_logic_vector(1 downto 0);
      M_AXI_DC_RLAST : in std_logic;
      M_AXI_DC_RVALID : in std_logic;
      M_AXI_DC_RREADY : out std_logic;
      DBG_CLK : in std_logic;
      DBG_TDI : in std_logic;
      DBG_TDO : out std_logic;
      DBG_REG_EN : in std_logic_vector(0 to 7);
      DBG_SHIFT : in std_logic;
      DBG_CAPTURE : in std_logic;
      DBG_UPDATE : in std_logic;
      DEBUG_RST : in std_logic;
      Trace_Instruction : out std_logic_vector(0 to 31);
      Trace_Valid_Instr : out std_logic;
      Trace_PC : out std_logic_vector(0 to 31);
      Trace_Reg_Write : out std_logic;
      Trace_Reg_Addr : out std_logic_vector(0 to 4);
      Trace_MSR_Reg : out std_logic_vector(0 to 14);
      Trace_PID_Reg : out std_logic_vector(0 to 7);
      Trace_New_Reg_Value : out std_logic_vector(0 to 31);
      Trace_Exception_Taken : out std_logic;
      Trace_Exception_Kind : out std_logic_vector(0 to 4);
      Trace_Jump_Taken : out std_logic;
      Trace_Delay_Slot : out std_logic;
      Trace_Data_Address : out std_logic_vector(0 to 31);
      Trace_Data_Access : out std_logic;
      Trace_Data_Read : out std_logic;
      Trace_Data_Write : out std_logic;
      Trace_Data_Write_Value : out std_logic_vector(0 to 31);
      Trace_Data_Byte_Enable : out std_logic_vector(0 to 3);
      Trace_DCache_Req : out std_logic;
      Trace_DCache_Hit : out std_logic;
      Trace_DCache_Rdy : out std_logic;
      Trace_DCache_Read : out std_logic;
      Trace_ICache_Req : out std_logic;
      Trace_ICache_Hit : out std_logic;
      Trace_ICache_Rdy : out std_logic;
      Trace_OF_PipeRun : out std_logic;
      Trace_EX_PipeRun : out std_logic;
      Trace_MEM_PipeRun : out std_logic;
      Trace_MB_Halted : out std_logic;
      Trace_Jump_Hit : out std_logic;
      FSL0_S_CLK : out std_logic;
      FSL0_S_READ : out std_logic;
      FSL0_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_S_CONTROL : in std_logic;
      FSL0_S_EXISTS : in std_logic;
      FSL0_M_CLK : out std_logic;
      FSL0_M_WRITE : out std_logic;
      FSL0_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL0_M_CONTROL : out std_logic;
      FSL0_M_FULL : in std_logic;
      FSL1_S_CLK : out std_logic;
      FSL1_S_READ : out std_logic;
      FSL1_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL1_S_CONTROL : in std_logic;
      FSL1_S_EXISTS : in std_logic;
      FSL1_M_CLK : out std_logic;
      FSL1_M_WRITE : out std_logic;
      FSL1_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL1_M_CONTROL : out std_logic;
      FSL1_M_FULL : in std_logic;
      FSL2_S_CLK : out std_logic;
      FSL2_S_READ : out std_logic;
      FSL2_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL2_S_CONTROL : in std_logic;
      FSL2_S_EXISTS : in std_logic;
      FSL2_M_CLK : out std_logic;
      FSL2_M_WRITE : out std_logic;
      FSL2_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL2_M_CONTROL : out std_logic;
      FSL2_M_FULL : in std_logic;
      FSL3_S_CLK : out std_logic;
      FSL3_S_READ : out std_logic;
      FSL3_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL3_S_CONTROL : in std_logic;
      FSL3_S_EXISTS : in std_logic;
      FSL3_M_CLK : out std_logic;
      FSL3_M_WRITE : out std_logic;
      FSL3_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL3_M_CONTROL : out std_logic;
      FSL3_M_FULL : in std_logic;
      FSL4_S_CLK : out std_logic;
      FSL4_S_READ : out std_logic;
      FSL4_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL4_S_CONTROL : in std_logic;
      FSL4_S_EXISTS : in std_logic;
      FSL4_M_CLK : out std_logic;
      FSL4_M_WRITE : out std_logic;
      FSL4_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL4_M_CONTROL : out std_logic;
      FSL4_M_FULL : in std_logic;
      FSL5_S_CLK : out std_logic;
      FSL5_S_READ : out std_logic;
      FSL5_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL5_S_CONTROL : in std_logic;
      FSL5_S_EXISTS : in std_logic;
      FSL5_M_CLK : out std_logic;
      FSL5_M_WRITE : out std_logic;
      FSL5_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL5_M_CONTROL : out std_logic;
      FSL5_M_FULL : in std_logic;
      FSL6_S_CLK : out std_logic;
      FSL6_S_READ : out std_logic;
      FSL6_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL6_S_CONTROL : in std_logic;
      FSL6_S_EXISTS : in std_logic;
      FSL6_M_CLK : out std_logic;
      FSL6_M_WRITE : out std_logic;
      FSL6_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL6_M_CONTROL : out std_logic;
      FSL6_M_FULL : in std_logic;
      FSL7_S_CLK : out std_logic;
      FSL7_S_READ : out std_logic;
      FSL7_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL7_S_CONTROL : in std_logic;
      FSL7_S_EXISTS : in std_logic;
      FSL7_M_CLK : out std_logic;
      FSL7_M_WRITE : out std_logic;
      FSL7_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL7_M_CONTROL : out std_logic;
      FSL7_M_FULL : in std_logic;
      FSL8_S_CLK : out std_logic;
      FSL8_S_READ : out std_logic;
      FSL8_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL8_S_CONTROL : in std_logic;
      FSL8_S_EXISTS : in std_logic;
      FSL8_M_CLK : out std_logic;
      FSL8_M_WRITE : out std_logic;
      FSL8_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL8_M_CONTROL : out std_logic;
      FSL8_M_FULL : in std_logic;
      FSL9_S_CLK : out std_logic;
      FSL9_S_READ : out std_logic;
      FSL9_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL9_S_CONTROL : in std_logic;
      FSL9_S_EXISTS : in std_logic;
      FSL9_M_CLK : out std_logic;
      FSL9_M_WRITE : out std_logic;
      FSL9_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL9_M_CONTROL : out std_logic;
      FSL9_M_FULL : in std_logic;
      FSL10_S_CLK : out std_logic;
      FSL10_S_READ : out std_logic;
      FSL10_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL10_S_CONTROL : in std_logic;
      FSL10_S_EXISTS : in std_logic;
      FSL10_M_CLK : out std_logic;
      FSL10_M_WRITE : out std_logic;
      FSL10_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL10_M_CONTROL : out std_logic;
      FSL10_M_FULL : in std_logic;
      FSL11_S_CLK : out std_logic;
      FSL11_S_READ : out std_logic;
      FSL11_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL11_S_CONTROL : in std_logic;
      FSL11_S_EXISTS : in std_logic;
      FSL11_M_CLK : out std_logic;
      FSL11_M_WRITE : out std_logic;
      FSL11_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL11_M_CONTROL : out std_logic;
      FSL11_M_FULL : in std_logic;
      FSL12_S_CLK : out std_logic;
      FSL12_S_READ : out std_logic;
      FSL12_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL12_S_CONTROL : in std_logic;
      FSL12_S_EXISTS : in std_logic;
      FSL12_M_CLK : out std_logic;
      FSL12_M_WRITE : out std_logic;
      FSL12_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL12_M_CONTROL : out std_logic;
      FSL12_M_FULL : in std_logic;
      FSL13_S_CLK : out std_logic;
      FSL13_S_READ : out std_logic;
      FSL13_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL13_S_CONTROL : in std_logic;
      FSL13_S_EXISTS : in std_logic;
      FSL13_M_CLK : out std_logic;
      FSL13_M_WRITE : out std_logic;
      FSL13_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL13_M_CONTROL : out std_logic;
      FSL13_M_FULL : in std_logic;
      FSL14_S_CLK : out std_logic;
      FSL14_S_READ : out std_logic;
      FSL14_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL14_S_CONTROL : in std_logic;
      FSL14_S_EXISTS : in std_logic;
      FSL14_M_CLK : out std_logic;
      FSL14_M_WRITE : out std_logic;
      FSL14_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL14_M_CONTROL : out std_logic;
      FSL14_M_FULL : in std_logic;
      FSL15_S_CLK : out std_logic;
      FSL15_S_READ : out std_logic;
      FSL15_S_DATA : in std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL15_S_CONTROL : in std_logic;
      FSL15_S_EXISTS : in std_logic;
      FSL15_M_CLK : out std_logic;
      FSL15_M_WRITE : out std_logic;
      FSL15_M_DATA : out std_logic_vector(0 to C_FSL_DATA_SIZE-1);
      FSL15_M_CONTROL : out std_logic;
      FSL15_M_FULL : in std_logic;
      M0_AXIS_TLAST : out std_logic;
      M0_AXIS_TDATA : out std_logic_vector(C_M0_AXIS_DATA_WIDTH-1 downto 0);
      M0_AXIS_TVALID : out std_logic;
      M0_AXIS_TREADY : in std_logic;
      S0_AXIS_TLAST : in std_logic;
      S0_AXIS_TDATA : in std_logic_vector(C_S0_AXIS_DATA_WIDTH-1 downto 0);
      S0_AXIS_TVALID : in std_logic;
      S0_AXIS_TREADY : out std_logic;
      M1_AXIS_TLAST : out std_logic;
      M1_AXIS_TDATA : out std_logic_vector(C_M1_AXIS_DATA_WIDTH-1 downto 0);
      M1_AXIS_TVALID : out std_logic;
      M1_AXIS_TREADY : in std_logic;
      S1_AXIS_TLAST : in std_logic;
      S1_AXIS_TDATA : in std_logic_vector(C_S1_AXIS_DATA_WIDTH-1 downto 0);
      S1_AXIS_TVALID : in std_logic;
      S1_AXIS_TREADY : out std_logic;
      M2_AXIS_TLAST : out std_logic;
      M2_AXIS_TDATA : out std_logic_vector(C_M2_AXIS_DATA_WIDTH-1 downto 0);
      M2_AXIS_TVALID : out std_logic;
      M2_AXIS_TREADY : in std_logic;
      S2_AXIS_TLAST : in std_logic;
      S2_AXIS_TDATA : in std_logic_vector(C_S2_AXIS_DATA_WIDTH-1 downto 0);
      S2_AXIS_TVALID : in std_logic;
      S2_AXIS_TREADY : out std_logic;
      M3_AXIS_TLAST : out std_logic;
      M3_AXIS_TDATA : out std_logic_vector(C_M3_AXIS_DATA_WIDTH-1 downto 0);
      M3_AXIS_TVALID : out std_logic;
      M3_AXIS_TREADY : in std_logic;
      S3_AXIS_TLAST : in std_logic;
      S3_AXIS_TDATA : in std_logic_vector(C_S3_AXIS_DATA_WIDTH-1 downto 0);
      S3_AXIS_TVALID : in std_logic;
      S3_AXIS_TREADY : out std_logic;
      M4_AXIS_TLAST : out std_logic;
      M4_AXIS_TDATA : out std_logic_vector(C_M4_AXIS_DATA_WIDTH-1 downto 0);
      M4_AXIS_TVALID : out std_logic;
      M4_AXIS_TREADY : in std_logic;
      S4_AXIS_TLAST : in std_logic;
      S4_AXIS_TDATA : in std_logic_vector(C_S4_AXIS_DATA_WIDTH-1 downto 0);
      S4_AXIS_TVALID : in std_logic;
      S4_AXIS_TREADY : out std_logic;
      M5_AXIS_TLAST : out std_logic;
      M5_AXIS_TDATA : out std_logic_vector(C_M5_AXIS_DATA_WIDTH-1 downto 0);
      M5_AXIS_TVALID : out std_logic;
      M5_AXIS_TREADY : in std_logic;
      S5_AXIS_TLAST : in std_logic;
      S5_AXIS_TDATA : in std_logic_vector(C_S5_AXIS_DATA_WIDTH-1 downto 0);
      S5_AXIS_TVALID : in std_logic;
      S5_AXIS_TREADY : out std_logic;
      M6_AXIS_TLAST : out std_logic;
      M6_AXIS_TDATA : out std_logic_vector(C_M6_AXIS_DATA_WIDTH-1 downto 0);
      M6_AXIS_TVALID : out std_logic;
      M6_AXIS_TREADY : in std_logic;
      S6_AXIS_TLAST : in std_logic;
      S6_AXIS_TDATA : in std_logic_vector(C_S6_AXIS_DATA_WIDTH-1 downto 0);
      S6_AXIS_TVALID : in std_logic;
      S6_AXIS_TREADY : out std_logic;
      M7_AXIS_TLAST : out std_logic;
      M7_AXIS_TDATA : out std_logic_vector(C_M7_AXIS_DATA_WIDTH-1 downto 0);
      M7_AXIS_TVALID : out std_logic;
      M7_AXIS_TREADY : in std_logic;
      S7_AXIS_TLAST : in std_logic;
      S7_AXIS_TDATA : in std_logic_vector(C_S7_AXIS_DATA_WIDTH-1 downto 0);
      S7_AXIS_TVALID : in std_logic;
      S7_AXIS_TREADY : out std_logic;
      M8_AXIS_TLAST : out std_logic;
      M8_AXIS_TDATA : out std_logic_vector(C_M8_AXIS_DATA_WIDTH-1 downto 0);
      M8_AXIS_TVALID : out std_logic;
      M8_AXIS_TREADY : in std_logic;
      S8_AXIS_TLAST : in std_logic;
      S8_AXIS_TDATA : in std_logic_vector(C_S8_AXIS_DATA_WIDTH-1 downto 0);
      S8_AXIS_TVALID : in std_logic;
      S8_AXIS_TREADY : out std_logic;
      M9_AXIS_TLAST : out std_logic;
      M9_AXIS_TDATA : out std_logic_vector(C_M9_AXIS_DATA_WIDTH-1 downto 0);
      M9_AXIS_TVALID : out std_logic;
      M9_AXIS_TREADY : in std_logic;
      S9_AXIS_TLAST : in std_logic;
      S9_AXIS_TDATA : in std_logic_vector(C_S9_AXIS_DATA_WIDTH-1 downto 0);
      S9_AXIS_TVALID : in std_logic;
      S9_AXIS_TREADY : out std_logic;
      M10_AXIS_TLAST : out std_logic;
      M10_AXIS_TDATA : out std_logic_vector(C_M10_AXIS_DATA_WIDTH-1 downto 0);
      M10_AXIS_TVALID : out std_logic;
      M10_AXIS_TREADY : in std_logic;
      S10_AXIS_TLAST : in std_logic;
      S10_AXIS_TDATA : in std_logic_vector(C_S10_AXIS_DATA_WIDTH-1 downto 0);
      S10_AXIS_TVALID : in std_logic;
      S10_AXIS_TREADY : out std_logic;
      M11_AXIS_TLAST : out std_logic;
      M11_AXIS_TDATA : out std_logic_vector(C_M11_AXIS_DATA_WIDTH-1 downto 0);
      M11_AXIS_TVALID : out std_logic;
      M11_AXIS_TREADY : in std_logic;
      S11_AXIS_TLAST : in std_logic;
      S11_AXIS_TDATA : in std_logic_vector(C_S11_AXIS_DATA_WIDTH-1 downto 0);
      S11_AXIS_TVALID : in std_logic;
      S11_AXIS_TREADY : out std_logic;
      M12_AXIS_TLAST : out std_logic;
      M12_AXIS_TDATA : out std_logic_vector(C_M12_AXIS_DATA_WIDTH-1 downto 0);
      M12_AXIS_TVALID : out std_logic;
      M12_AXIS_TREADY : in std_logic;
      S12_AXIS_TLAST : in std_logic;
      S12_AXIS_TDATA : in std_logic_vector(C_S12_AXIS_DATA_WIDTH-1 downto 0);
      S12_AXIS_TVALID : in std_logic;
      S12_AXIS_TREADY : out std_logic;
      M13_AXIS_TLAST : out std_logic;
      M13_AXIS_TDATA : out std_logic_vector(C_M13_AXIS_DATA_WIDTH-1 downto 0);
      M13_AXIS_TVALID : out std_logic;
      M13_AXIS_TREADY : in std_logic;
      S13_AXIS_TLAST : in std_logic;
      S13_AXIS_TDATA : in std_logic_vector(C_S13_AXIS_DATA_WIDTH-1 downto 0);
      S13_AXIS_TVALID : in std_logic;
      S13_AXIS_TREADY : out std_logic;
      M14_AXIS_TLAST : out std_logic;
      M14_AXIS_TDATA : out std_logic_vector(C_M14_AXIS_DATA_WIDTH-1 downto 0);
      M14_AXIS_TVALID : out std_logic;
      M14_AXIS_TREADY : in std_logic;
      S14_AXIS_TLAST : in std_logic;
      S14_AXIS_TDATA : in std_logic_vector(C_S14_AXIS_DATA_WIDTH-1 downto 0);
      S14_AXIS_TVALID : in std_logic;
      S14_AXIS_TREADY : out std_logic;
      M15_AXIS_TLAST : out std_logic;
      M15_AXIS_TDATA : out std_logic_vector(C_M15_AXIS_DATA_WIDTH-1 downto 0);
      M15_AXIS_TVALID : out std_logic;
      M15_AXIS_TREADY : in std_logic;
      S15_AXIS_TLAST : in std_logic;
      S15_AXIS_TDATA : in std_logic_vector(C_S15_AXIS_DATA_WIDTH-1 downto 0);
      S15_AXIS_TVALID : in std_logic;
      S15_AXIS_TREADY : out std_logic;
      ICACHE_FSL_IN_CLK : out std_logic;
      ICACHE_FSL_IN_READ : out std_logic;
      ICACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      ICACHE_FSL_IN_CONTROL : in std_logic;
      ICACHE_FSL_IN_EXISTS : in std_logic;
      ICACHE_FSL_OUT_CLK : out std_logic;
      ICACHE_FSL_OUT_WRITE : out std_logic;
      ICACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      ICACHE_FSL_OUT_CONTROL : out std_logic;
      ICACHE_FSL_OUT_FULL : in std_logic;
      DCACHE_FSL_IN_CLK : out std_logic;
      DCACHE_FSL_IN_READ : out std_logic;
      DCACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      DCACHE_FSL_IN_CONTROL : in std_logic;
      DCACHE_FSL_IN_EXISTS : in std_logic;
      DCACHE_FSL_OUT_CLK : out std_logic;
      DCACHE_FSL_OUT_WRITE : out std_logic;
      DCACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      DCACHE_FSL_OUT_CONTROL : out std_logic;
      DCACHE_FSL_OUT_FULL : in std_logic
    );
  end component;

  constant net_gnd0      : std_logic := '0';
  constant net_gnd0_bus  : std_logic_vector (0 to 0)  := "0";
  constant net_gnd2      : std_logic_vector (0 to 1)  := "00";
  constant net_gnd4      : std_logic_vector (0 to 3)  := "0000";
  constant net_gnd8      : std_logic_vector (0 to 7)  := "00000000";
  constant net_gnd32     : std_logic_vector (0 to 31) := X"00000000";

  signal trc_valid       : std_logic;
  signal trc_data_valid  : std_logic;
  signal trc_instruction : std_logic_vector(0 to 31);
  signal trc_inst_adr    : std_logic_vector(0 to 31);
  signal trc_data_adr    : std_logic_vector(0 to 31);
  
  signal trc_arithmetic  : std_logic;
  signal trc_mul_float   : std_logic;
  signal trc_load_store  : std_logic;

  signal instr_wait      : std_logic;
  signal data_wait       : std_logic;
  signal instr_strobe    : std_logic;
  signal data_strobe     : std_logic;

begin

  process (clk_cpu) begin
    if (clk_cpu'event and clk_cpu = '1') then
      if (rst_cpu = '1') then
        instr_wait <= '0';
        data_wait  <= '0';
      else

        if (instr_strobe = '1') then
          instr_wait <= '1';
        elsif (i_iready = '1') then
          instr_wait <= '0';
        end if;

        if (data_strobe = '1') then
          data_wait <= '1';
        elsif (i_dready = '1') then
          data_wait <= '0';
        end if;

      end if;
    end if;
  end process;

  o_dstrobe <= data_strobe;
  o_istrobe <= instr_strobe;

  i0_microblaze: microblaze
    generic map (
      C_SCO => 0,
      C_FREQ => 10000000,
      C_DATA_SIZE => 32,
      C_DYNAMIC_BUS_SIZING => 1,
      C_FAMILY => "spartan6",
      C_INSTANCE => "microblaze_0",
      C_FAULT_TOLERANT => 0,
      C_ECC_USE_CE_EXCEPTION => 0,
      C_ENDIANNESS => 1,
      C_AREA_OPTIMIZED => 1,
      C_OPTIMIZATION => 0,
      C_INTERCONNECT => 2,
      C_STREAM_INTERCONNECT => 0,
      C_DPLB_DWIDTH => 32,
      C_DPLB_NATIVE_DWIDTH => 32,
      C_DPLB_BURST_EN => 0,
      C_DPLB_P2P => 0,
      C_IPLB_DWIDTH => 32,
      C_IPLB_NATIVE_DWIDTH => 32,
      C_IPLB_BURST_EN => 0,
      C_IPLB_P2P => 0,
      C_M_AXI_DP_THREAD_ID_WIDTH => 1,
      C_M_AXI_DP_DATA_WIDTH => 32,
      C_M_AXI_DP_ADDR_WIDTH => 32,
      C_M_AXI_DP_EXCLUSIVE_ACCESS => 0,
      C_M_AXI_IP_THREAD_ID_WIDTH => 1,
      C_M_AXI_IP_DATA_WIDTH => 32,
      C_M_AXI_IP_ADDR_WIDTH => 32,
      C_D_AXI => 0,
      C_D_PLB => 0,
      C_D_LMB => 1,
      C_I_AXI => 0,
      C_I_PLB => 0,
      C_I_LMB => 1,
      C_USE_MSR_INSTR => 1,
      C_USE_PCMP_INSTR => 1,
      C_USE_BARREL => 1,
      C_USE_DIV => 0,
      C_USE_HW_MUL => 1,
      C_USE_FPU => 2,
      C_UNALIGNED_EXCEPTIONS => 0,
      C_ILL_OPCODE_EXCEPTION => 0,
      C_M_AXI_I_BUS_EXCEPTION => 0,
      C_M_AXI_D_BUS_EXCEPTION => 0,
      C_IPLB_BUS_EXCEPTION => 0,
      C_DPLB_BUS_EXCEPTION => 0,
      C_DIV_ZERO_EXCEPTION => 0,
      C_FPU_EXCEPTION => 0,
      C_FSL_EXCEPTION => 0,
      C_PVR => 0,
      C_PVR_USER1 => X"00",
      C_PVR_USER2 => X"00000000",
      C_DEBUG_ENABLED => NEED_DEBUG,
      C_NUMBER_OF_PC_BRK => 1,
      C_NUMBER_OF_RD_ADDR_BRK => 0,
      C_NUMBER_OF_WR_ADDR_BRK => 0,
      C_INTERRUPT_IS_EDGE => 0,
      C_EDGE_IS_POSITIVE => 1,
      C_RESET_MSR => X"00000000",
      C_OPCODE_0x0_ILLEGAL => 0,
      C_FSL_LINKS => 0,
      C_FSL_DATA_SIZE => 32,
      C_USE_EXTENDED_FSL_INSTR => 0,
      C_M0_AXIS_DATA_WIDTH => 32,
      C_S0_AXIS_DATA_WIDTH => 32,
      C_M1_AXIS_DATA_WIDTH => 32,
      C_S1_AXIS_DATA_WIDTH => 32,
      C_M2_AXIS_DATA_WIDTH => 32,
      C_S2_AXIS_DATA_WIDTH => 32,
      C_M3_AXIS_DATA_WIDTH => 32,
      C_S3_AXIS_DATA_WIDTH => 32,
      C_M4_AXIS_DATA_WIDTH => 32,
      C_S4_AXIS_DATA_WIDTH => 32,
      C_M5_AXIS_DATA_WIDTH => 32,
      C_S5_AXIS_DATA_WIDTH => 32,
      C_M6_AXIS_DATA_WIDTH => 32,
      C_S6_AXIS_DATA_WIDTH => 32,
      C_M7_AXIS_DATA_WIDTH => 32,
      C_S7_AXIS_DATA_WIDTH => 32,
      C_M8_AXIS_DATA_WIDTH => 32,
      C_S8_AXIS_DATA_WIDTH => 32,
      C_M9_AXIS_DATA_WIDTH => 32,
      C_S9_AXIS_DATA_WIDTH => 32,
      C_M10_AXIS_DATA_WIDTH => 32,
      C_S10_AXIS_DATA_WIDTH => 32,
      C_M11_AXIS_DATA_WIDTH => 32,
      C_S11_AXIS_DATA_WIDTH => 32,
      C_M12_AXIS_DATA_WIDTH => 32,
      C_S12_AXIS_DATA_WIDTH => 32,
      C_M13_AXIS_DATA_WIDTH => 32,
      C_S13_AXIS_DATA_WIDTH => 32,
      C_M14_AXIS_DATA_WIDTH => 32,
      C_S14_AXIS_DATA_WIDTH => 32,
      C_M15_AXIS_DATA_WIDTH => 32,
      C_S15_AXIS_DATA_WIDTH => 32,
      C_ICACHE_BASEADDR => X"00000000",
      C_ICACHE_HIGHADDR => X"3FFFFFFF",
      C_USE_ICACHE => 0,
      C_ALLOW_ICACHE_WR => 1,
      C_ADDR_TAG_BITS => 0,
      C_CACHE_BYTE_SIZE => 8192,
      C_ICACHE_USE_FSL => 1,
      C_ICACHE_LINE_LEN => 4,
      C_ICACHE_ALWAYS_USED => 0,
      C_ICACHE_INTERFACE => 0,
      C_ICACHE_VICTIMS => 0,
      C_ICACHE_STREAMS => 0,
      C_ICACHE_FORCE_TAG_LUTRAM => 0,
      C_ICACHE_DATA_WIDTH => 0,
      C_M_AXI_IC_THREAD_ID_WIDTH => 1,
      C_M_AXI_IC_DATA_WIDTH => 32,
      C_M_AXI_IC_ADDR_WIDTH => 32,
      C_DCACHE_BASEADDR => X"00000000",
      C_DCACHE_HIGHADDR => X"3FFFFFFF",
      C_USE_DCACHE => 0,
      C_ALLOW_DCACHE_WR => 1,
      C_DCACHE_ADDR_TAG => 0,
      C_DCACHE_BYTE_SIZE => 8192,
      C_DCACHE_USE_FSL => 1,
      C_DCACHE_LINE_LEN => 4,
      C_DCACHE_ALWAYS_USED => 0,
      C_DCACHE_INTERFACE => 0,
      C_DCACHE_USE_WRITEBACK => 0,
      C_DCACHE_VICTIMS => 0,
      C_DCACHE_FORCE_TAG_LUTRAM => 0,
      C_DCACHE_DATA_WIDTH => 0,
      C_M_AXI_DC_THREAD_ID_WIDTH => 1,
      C_M_AXI_DC_DATA_WIDTH => 32,
      C_M_AXI_DC_ADDR_WIDTH => 32,
      C_M_AXI_DC_EXCLUSIVE_ACCESS => 0,
      C_USE_MMU => 0,
      C_MMU_DTLB_SIZE => 4,
      C_MMU_ITLB_SIZE => 2,
      C_MMU_TLB_ACCESS => 3,
      C_MMU_ZONES => 16,
      C_USE_INTERRUPT => 1,
      C_USE_EXT_BRK => 1,
      C_USE_EXT_NM_BRK => 1,
      C_USE_BRANCH_TARGET_CACHE => 0,
      C_BRANCH_TARGET_CACHE_SIZE => 0
    )
    port map (

      -- Core interface
      CLK => clk_cpu,
      RESET => rst_cpu,
      MB_RESET => rst_cpu,
      INTERRUPT => i_ctl_interrupt,
      DBG_STOP => net_gnd0,
      MB_Halted => open,
      MB_Error => open,

      -- Instruction LMB
      INSTR => i_idata,
      IREADY => i_iready,
      IWAIT => instr_wait,
      ICE => net_gnd0,
      IUE => net_gnd0,
      INSTR_ADDR => o_iadr,
      IFETCH => o_ifetch,
      I_AS => instr_strobe,

      -- Data LMB
      DATA_READ => i_drdata,
      DREADY => i_dready,
      DWAIT => data_wait,
      DCE => net_gnd0,
      DUE => net_gnd0,
      DATA_WRITE => o_dwdata,
      DATA_ADDR => o_dadr,
      D_AS => data_strobe,
      READ_STROBE => o_drd,
      WRITE_STROBE => o_dwr,
      BYTE_ENABLE => o_ben,

      -- Trace interface
      Trace_Instruction => trc_instruction,
      Trace_Valid_Instr => trc_valid,
      Trace_PC => trc_inst_adr,
      Trace_Reg_Write => open,
      Trace_Reg_Addr => open,
      Trace_MSR_Reg => open,
      Trace_PID_Reg => open,
      Trace_New_Reg_Value => open,
      Trace_Exception_Taken => open,
      Trace_Exception_Kind => open,
      Trace_Jump_Taken => open,
      Trace_Delay_Slot => open,
      Trace_Data_Address => trc_data_adr, 
      Trace_Data_Access => trc_data_valid,
      Trace_Data_Read => open,
      Trace_Data_Write => open,
      Trace_Data_Write_Value => open,
      Trace_Data_Byte_Enable => open,
      Trace_DCache_Req => open,
      Trace_DCache_Hit => open,
      Trace_DCache_Rdy => open,
      Trace_DCache_Read => open,
      Trace_ICache_Req => open,
      Trace_ICache_Hit => open,
      Trace_ICache_Rdy => open,
      Trace_OF_PipeRun => open,
      Trace_EX_PipeRun => open,
      Trace_MEM_PipeRun => open,
      Trace_MB_Halted => open,
      Trace_Jump_Hit => open,

      -- MDM Debug interface
      EXT_BRK => i_mdm_brk,
      EXT_NM_BRK => i_mdm_nm_brk,
      DBG_CLK => i_mdm_clk,
      DBG_TDI => i_mdm_tdi,
      DBG_TDO => o_mdm_tdo,
      DBG_REG_EN => i_mdm_reg_en,
      DBG_SHIFT => i_mdm_shift,
      DBG_CAPTURE => i_mdm_capture,
      DBG_UPDATE => i_mdm_update,
      DEBUG_RST => i_mdm_reset,

      -- Unconnected
      IPLB_M_ABort => open,
      IPLB_M_ABus => open,
      IPLB_M_UABus => open,
      IPLB_M_BE => open,
      IPLB_M_busLock => open,
      IPLB_M_lockErr => open,
      IPLB_M_MSize => open,
      IPLB_M_priority => open,
      IPLB_M_rdBurst => open,
      IPLB_M_request => open,
      IPLB_M_RNW => open,
      IPLB_M_size => open,
      IPLB_M_TAttribute => open,
      IPLB_M_type => open,
      IPLB_M_wrBurst => open,
      IPLB_M_wrDBus => open,
      IPLB_MBusy => net_gnd0,
      IPLB_MRdErr => net_gnd0,
      IPLB_MWrErr => net_gnd0,
      IPLB_MIRQ => net_gnd0,
      IPLB_MWrBTerm => net_gnd0,
      IPLB_MWrDAck => net_gnd0,
      IPLB_MAddrAck => net_gnd0,
      IPLB_MRdBTerm => net_gnd0,
      IPLB_MRdDAck => net_gnd0,
      IPLB_MRdDBus => net_gnd32,
      IPLB_MRdWdAddr => net_gnd4,
      IPLB_MRearbitrate => net_gnd0,
      IPLB_MSSize => net_gnd2,
      IPLB_MTimeout => net_gnd0,
      DPLB_M_ABort => open,
      DPLB_M_ABus => open,
      DPLB_M_UABus => open,
      DPLB_M_BE => open,
      DPLB_M_busLock => open,
      DPLB_M_lockErr => open,
      DPLB_M_MSize => open,
      DPLB_M_priority => open,
      DPLB_M_rdBurst => open,
      DPLB_M_request => open,
      DPLB_M_RNW => open,
      DPLB_M_size => open,
      DPLB_M_TAttribute => open,
      DPLB_M_type => open,
      DPLB_M_wrBurst => open,
      DPLB_M_wrDBus => open,
      DPLB_MBusy => net_gnd0,
      DPLB_MRdErr => net_gnd0,
      DPLB_MWrErr => net_gnd0,
      DPLB_MIRQ => net_gnd0,
      DPLB_MWrBTerm => net_gnd0,
      DPLB_MWrDAck => net_gnd0,
      DPLB_MAddrAck => net_gnd0,
      DPLB_MRdBTerm => net_gnd0,
      DPLB_MRdDAck => net_gnd0,
      DPLB_MRdDBus => net_gnd32,
      DPLB_MRdWdAddr => net_gnd4,
      DPLB_MRearbitrate => net_gnd0,
      DPLB_MSSize => net_gnd2,
      DPLB_MTimeout => net_gnd0,
      M_AXI_IP_AWID => open,
      M_AXI_IP_AWADDR => open,
      M_AXI_IP_AWLEN => open,
      M_AXI_IP_AWSIZE => open,
      M_AXI_IP_AWBURST => open,
      M_AXI_IP_AWLOCK => open,
      M_AXI_IP_AWCACHE => open,
      M_AXI_IP_AWPROT => open,
      M_AXI_IP_AWQOS => open,
      M_AXI_IP_AWVALID => open,
      M_AXI_IP_AWREADY => net_gnd0,
      M_AXI_IP_WDATA => open,
      M_AXI_IP_WSTRB => open,
      M_AXI_IP_WLAST => open,
      M_AXI_IP_WVALID => open,
      M_AXI_IP_WREADY => net_gnd0,
      M_AXI_IP_BID => net_gnd0_bus,
      M_AXI_IP_BRESP => net_gnd2,
      M_AXI_IP_BVALID => net_gnd0,
      M_AXI_IP_BREADY => open,
      M_AXI_IP_ARID => open,
      M_AXI_IP_ARADDR => open,
      M_AXI_IP_ARLEN => open,
      M_AXI_IP_ARSIZE => open,
      M_AXI_IP_ARBURST => open,
      M_AXI_IP_ARLOCK => open,
      M_AXI_IP_ARCACHE => open,
      M_AXI_IP_ARPROT => open,
      M_AXI_IP_ARQOS => open,
      M_AXI_IP_ARVALID => open,
      M_AXI_IP_ARREADY => net_gnd0,
      M_AXI_IP_RID => net_gnd0_bus,
      M_AXI_IP_RDATA => net_gnd32,
      M_AXI_IP_RRESP => net_gnd2,
      M_AXI_IP_RLAST => net_gnd0,
      M_AXI_IP_RVALID => net_gnd0,
      M_AXI_IP_RREADY => open,
      M_AXI_DP_AWID => open,
      M_AXI_DP_AWADDR => open,
      M_AXI_DP_AWLEN => open,
      M_AXI_DP_AWSIZE => open,
      M_AXI_DP_AWBURST => open,
      M_AXI_DP_AWLOCK => open,
      M_AXI_DP_AWCACHE => open,
      M_AXI_DP_AWPROT => open,
      M_AXI_DP_AWQOS => open,
      M_AXI_DP_AWVALID => open,
      M_AXI_DP_AWREADY => net_gnd0,
      M_AXI_DP_WDATA => open,
      M_AXI_DP_WSTRB => open,
      M_AXI_DP_WLAST => open,
      M_AXI_DP_WVALID => open,
      M_AXI_DP_WREADY => net_gnd0,
      M_AXI_DP_BID => net_gnd0_bus,
      M_AXI_DP_BRESP => net_gnd2,
      M_AXI_DP_BVALID => net_gnd0,
      M_AXI_DP_BREADY => open,
      M_AXI_DP_ARID => open,
      M_AXI_DP_ARADDR => open,
      M_AXI_DP_ARLEN => open,
      M_AXI_DP_ARSIZE => open,
      M_AXI_DP_ARBURST => open,
      M_AXI_DP_ARLOCK => open,
      M_AXI_DP_ARCACHE => open,
      M_AXI_DP_ARPROT => open,
      M_AXI_DP_ARQOS => open,
      M_AXI_DP_ARVALID => open,
      M_AXI_DP_ARREADY => net_gnd0,
      M_AXI_DP_RID => net_gnd0_bus,
      M_AXI_DP_RDATA => net_gnd32, 
      M_AXI_DP_RRESP => net_gnd2,
      M_AXI_DP_RLAST => net_gnd0,
      M_AXI_DP_RVALID => net_gnd0,
      M_AXI_DP_RREADY => open,
      M_AXI_IC_AWID => open,
      M_AXI_IC_AWADDR => open,
      M_AXI_IC_AWLEN => open,
      M_AXI_IC_AWSIZE => open,
      M_AXI_IC_AWBURST => open,
      M_AXI_IC_AWLOCK => open,
      M_AXI_IC_AWCACHE => open,
      M_AXI_IC_AWPROT => open,
      M_AXI_IC_AWQOS => open,
      M_AXI_IC_AWVALID => open,
      M_AXI_IC_AWREADY => net_gnd0,
      M_AXI_IC_WDATA => open,
      M_AXI_IC_WSTRB => open,
      M_AXI_IC_WLAST => open,
      M_AXI_IC_WVALID => open,
      M_AXI_IC_WREADY => net_gnd0,
      M_AXI_IC_BID => net_gnd0_bus,
      M_AXI_IC_BRESP => net_gnd2, 
      M_AXI_IC_BVALID => net_gnd0,
      M_AXI_IC_BREADY => open,
      M_AXI_IC_ARID => open,
      M_AXI_IC_ARADDR => open,
      M_AXI_IC_ARLEN => open,
      M_AXI_IC_ARSIZE => open,
      M_AXI_IC_ARBURST => open,
      M_AXI_IC_ARLOCK => open,
      M_AXI_IC_ARCACHE => open,
      M_AXI_IC_ARPROT => open,
      M_AXI_IC_ARQOS => open,
      M_AXI_IC_ARVALID => open,
      M_AXI_IC_ARREADY => net_gnd0,
      M_AXI_IC_RID => net_gnd0_bus,
      M_AXI_IC_RDATA => net_gnd32,
      M_AXI_IC_RRESP => net_gnd2, 
      M_AXI_IC_RLAST => net_gnd0,
      M_AXI_IC_RVALID => net_gnd0,
      M_AXI_IC_RREADY => open,
      M_AXI_DC_AWID => open,
      M_AXI_DC_AWADDR => open,
      M_AXI_DC_AWLEN => open,
      M_AXI_DC_AWSIZE => open,
      M_AXI_DC_AWBURST => open,
      M_AXI_DC_AWLOCK => open,
      M_AXI_DC_AWCACHE => open,
      M_AXI_DC_AWPROT => open,
      M_AXI_DC_AWQOS => open,
      M_AXI_DC_AWVALID => open,
      M_AXI_DC_AWREADY => net_gnd0,
      M_AXI_DC_WDATA => open,
      M_AXI_DC_WSTRB => open,
      M_AXI_DC_WLAST => open,
      M_AXI_DC_WVALID => open,
      M_AXI_DC_WREADY => net_gnd0,
      M_AXI_DC_BID => net_gnd0_bus,
      M_AXI_DC_BRESP => net_gnd2,
      M_AXI_DC_BVALID => net_gnd0,
      M_AXI_DC_BREADY => open,
      M_AXI_DC_ARID => open,
      M_AXI_DC_ARADDR => open,
      M_AXI_DC_ARLEN => open,
      M_AXI_DC_ARSIZE => open,
      M_AXI_DC_ARBURST => open,
      M_AXI_DC_ARLOCK => open,
      M_AXI_DC_ARCACHE => open,
      M_AXI_DC_ARPROT => open,
      M_AXI_DC_ARQOS => open,
      M_AXI_DC_ARVALID => open,
      M_AXI_DC_ARREADY => net_gnd0,
      M_AXI_DC_RID => net_gnd0_bus,
      M_AXI_DC_RDATA => net_gnd32,
      M_AXI_DC_RRESP => net_gnd2,
      M_AXI_DC_RLAST => net_gnd0,
      M_AXI_DC_RVALID => net_gnd0,
      M_AXI_DC_RREADY => open,
      FSL0_S_CLK => open,
      FSL0_S_READ => open,
      FSL0_S_DATA => net_gnd32,
      FSL0_S_CONTROL => net_gnd0,
      FSL0_S_EXISTS => net_gnd0,
      FSL0_M_CLK => open,
      FSL0_M_WRITE => open,
      FSL0_M_DATA => open,
      FSL0_M_CONTROL => open,
      FSL0_M_FULL => net_gnd0,
      FSL1_S_CLK => open,
      FSL1_S_READ => open,
      FSL1_S_DATA => net_gnd32,
      FSL1_S_CONTROL => net_gnd0,
      FSL1_S_EXISTS => net_gnd0,
      FSL1_M_CLK => open,
      FSL1_M_WRITE => open,
      FSL1_M_DATA => open,
      FSL1_M_CONTROL => open,
      FSL1_M_FULL => net_gnd0,
      FSL2_S_CLK => open,
      FSL2_S_READ => open,
      FSL2_S_DATA => net_gnd32,
      FSL2_S_CONTROL => net_gnd0,
      FSL2_S_EXISTS => net_gnd0,
      FSL2_M_CLK => open,
      FSL2_M_WRITE => open,
      FSL2_M_DATA => open,
      FSL2_M_CONTROL => open,
      FSL2_M_FULL => net_gnd0,
      FSL3_S_CLK => open,
      FSL3_S_READ => open,
      FSL3_S_DATA => net_gnd32,
      FSL3_S_CONTROL => net_gnd0,
      FSL3_S_EXISTS => net_gnd0,
      FSL3_M_CLK => open,
      FSL3_M_WRITE => open,
      FSL3_M_DATA => open,
      FSL3_M_CONTROL => open,
      FSL3_M_FULL => net_gnd0,
      FSL4_S_CLK => open,
      FSL4_S_READ => open,
      FSL4_S_DATA => net_gnd32,
      FSL4_S_CONTROL => net_gnd0,
      FSL4_S_EXISTS => net_gnd0,
      FSL4_M_CLK => open,
      FSL4_M_WRITE => open,
      FSL4_M_DATA => open,
      FSL4_M_CONTROL => open,
      FSL4_M_FULL => net_gnd0,
      FSL5_S_CLK => open,
      FSL5_S_READ => open,
      FSL5_S_DATA => net_gnd32,
      FSL5_S_CONTROL => net_gnd0,
      FSL5_S_EXISTS => net_gnd0,
      FSL5_M_CLK => open,
      FSL5_M_WRITE => open,
      FSL5_M_DATA => open,
      FSL5_M_CONTROL => open,
      FSL5_M_FULL => net_gnd0,
      FSL6_S_CLK => open,
      FSL6_S_READ => open,
      FSL6_S_DATA => net_gnd32,
      FSL6_S_CONTROL => net_gnd0,
      FSL6_S_EXISTS => net_gnd0,
      FSL6_M_CLK => open,
      FSL6_M_WRITE => open,
      FSL6_M_DATA => open,
      FSL6_M_CONTROL => open,
      FSL6_M_FULL => net_gnd0,
      FSL7_S_CLK => open,
      FSL7_S_READ => open,
      FSL7_S_DATA => net_gnd32,
      FSL7_S_CONTROL => net_gnd0,
      FSL7_S_EXISTS => net_gnd0,
      FSL7_M_CLK => open,
      FSL7_M_WRITE => open,
      FSL7_M_DATA => open,
      FSL7_M_CONTROL => open,
      FSL7_M_FULL => net_gnd0,
      FSL8_S_CLK => open,
      FSL8_S_READ => open,
      FSL8_S_DATA => net_gnd32,
      FSL8_S_CONTROL => net_gnd0,
      FSL8_S_EXISTS => net_gnd0,
      FSL8_M_CLK => open,
      FSL8_M_WRITE => open,
      FSL8_M_DATA => open,
      FSL8_M_CONTROL => open,
      FSL8_M_FULL => net_gnd0,
      FSL9_S_CLK => open,
      FSL9_S_READ => open,
      FSL9_S_DATA => net_gnd32,
      FSL9_S_CONTROL => net_gnd0,
      FSL9_S_EXISTS => net_gnd0,
      FSL9_M_CLK => open,
      FSL9_M_WRITE => open,
      FSL9_M_DATA => open,
      FSL9_M_CONTROL => open,
      FSL9_M_FULL => net_gnd0,
      FSL10_S_CLK => open,
      FSL10_S_READ => open,
      FSL10_S_DATA => net_gnd32,
      FSL10_S_CONTROL => net_gnd0,
      FSL10_S_EXISTS => net_gnd0,
      FSL10_M_CLK => open,
      FSL10_M_WRITE => open,
      FSL10_M_DATA => open,
      FSL10_M_CONTROL => open,
      FSL10_M_FULL => net_gnd0,
      FSL11_S_CLK => open,
      FSL11_S_READ => open,
      FSL11_S_DATA => net_gnd32,
      FSL11_S_CONTROL => net_gnd0,
      FSL11_S_EXISTS => net_gnd0,
      FSL11_M_CLK => open,
      FSL11_M_WRITE => open,
      FSL11_M_DATA => open,
      FSL11_M_CONTROL => open,
      FSL11_M_FULL => net_gnd0,
      FSL12_S_CLK => open,
      FSL12_S_READ => open,
      FSL12_S_DATA => net_gnd32,
      FSL12_S_CONTROL => net_gnd0,
      FSL12_S_EXISTS => net_gnd0,
      FSL12_M_CLK => open,
      FSL12_M_WRITE => open,
      FSL12_M_DATA => open,
      FSL12_M_CONTROL => open,
      FSL12_M_FULL => net_gnd0,
      FSL13_S_CLK => open,
      FSL13_S_READ => open,
      FSL13_S_DATA => net_gnd32,
      FSL13_S_CONTROL => net_gnd0,
      FSL13_S_EXISTS => net_gnd0,
      FSL13_M_CLK => open,
      FSL13_M_WRITE => open,
      FSL13_M_DATA => open,
      FSL13_M_CONTROL => open,
      FSL13_M_FULL => net_gnd0,
      FSL14_S_CLK => open,
      FSL14_S_READ => open,
      FSL14_S_DATA => net_gnd32,
      FSL14_S_CONTROL => net_gnd0,
      FSL14_S_EXISTS => net_gnd0,
      FSL14_M_CLK => open,
      FSL14_M_WRITE => open,
      FSL14_M_DATA => open,
      FSL14_M_CONTROL => open,
      FSL14_M_FULL => net_gnd0,
      FSL15_S_CLK => open,
      FSL15_S_READ => open,
      FSL15_S_DATA => net_gnd32,
      FSL15_S_CONTROL => net_gnd0,
      FSL15_S_EXISTS => net_gnd0,
      FSL15_M_CLK => open,
      FSL15_M_WRITE => open,
      FSL15_M_DATA => open,
      FSL15_M_CONTROL => open,
      FSL15_M_FULL => net_gnd0,
      M0_AXIS_TLAST => open,
      M0_AXIS_TDATA => open,
      M0_AXIS_TVALID => open,
      M0_AXIS_TREADY => net_gnd0,
      S0_AXIS_TLAST => net_gnd0,
      S0_AXIS_TDATA => net_gnd32,
      S0_AXIS_TVALID => net_gnd0,
      S0_AXIS_TREADY => open,
      M1_AXIS_TLAST => open,
      M1_AXIS_TDATA => open,
      M1_AXIS_TVALID => open,
      M1_AXIS_TREADY => net_gnd0,
      S1_AXIS_TLAST => net_gnd0,
      S1_AXIS_TDATA => net_gnd32,
      S1_AXIS_TVALID => net_gnd0,
      S1_AXIS_TREADY => open,
      M2_AXIS_TLAST => open,
      M2_AXIS_TDATA => open,
      M2_AXIS_TVALID => open,
      M2_AXIS_TREADY => net_gnd0,
      S2_AXIS_TLAST => net_gnd0,
      S2_AXIS_TDATA => net_gnd32,
      S2_AXIS_TVALID => net_gnd0,
      S2_AXIS_TREADY => open,
      M3_AXIS_TLAST => open,
      M3_AXIS_TDATA => open,
      M3_AXIS_TVALID => open,
      M3_AXIS_TREADY => net_gnd0,
      S3_AXIS_TLAST => net_gnd0,
      S3_AXIS_TDATA => net_gnd32,
      S3_AXIS_TVALID => net_gnd0,
      S3_AXIS_TREADY => open,
      M4_AXIS_TLAST => open,
      M4_AXIS_TDATA => open,
      M4_AXIS_TVALID => open,
      M4_AXIS_TREADY => net_gnd0,
      S4_AXIS_TLAST => net_gnd0,
      S4_AXIS_TDATA => net_gnd32,
      S4_AXIS_TVALID => net_gnd0,
      S4_AXIS_TREADY => open,
      M5_AXIS_TLAST => open,
      M5_AXIS_TDATA => open,
      M5_AXIS_TVALID => open,
      M5_AXIS_TREADY => net_gnd0,
      S5_AXIS_TLAST => net_gnd0,
      S5_AXIS_TDATA => net_gnd32,
      S5_AXIS_TVALID => net_gnd0,
      S5_AXIS_TREADY => open,
      M6_AXIS_TLAST => open,
      M6_AXIS_TDATA => open,
      M6_AXIS_TVALID => open,
      M6_AXIS_TREADY => net_gnd0,
      S6_AXIS_TLAST => net_gnd0,
      S6_AXIS_TDATA => net_gnd32,
      S6_AXIS_TVALID => net_gnd0,
      S6_AXIS_TREADY => open,
      M7_AXIS_TLAST => open,
      M7_AXIS_TDATA => open,
      M7_AXIS_TVALID => open,
      M7_AXIS_TREADY => net_gnd0,
      S7_AXIS_TLAST => net_gnd0,
      S7_AXIS_TDATA => net_gnd32,
      S7_AXIS_TVALID => net_gnd0,
      S7_AXIS_TREADY => open,
      M8_AXIS_TLAST => open,
      M8_AXIS_TDATA => open,
      M8_AXIS_TVALID => open,
      M8_AXIS_TREADY => net_gnd0,
      S8_AXIS_TLAST => net_gnd0,
      S8_AXIS_TDATA => net_gnd32,
      S8_AXIS_TVALID => net_gnd0,
      S8_AXIS_TREADY => open,
      M9_AXIS_TLAST => open,
      M9_AXIS_TDATA => open,
      M9_AXIS_TVALID => open,
      M9_AXIS_TREADY => net_gnd0,
      S9_AXIS_TLAST => net_gnd0,
      S9_AXIS_TDATA => net_gnd32,
      S9_AXIS_TVALID => net_gnd0,
      S9_AXIS_TREADY => open,
      M10_AXIS_TLAST => open,
      M10_AXIS_TDATA => open,
      M10_AXIS_TVALID => open,
      M10_AXIS_TREADY => net_gnd0,
      S10_AXIS_TLAST => net_gnd0,
      S10_AXIS_TDATA => net_gnd32,
      S10_AXIS_TVALID => net_gnd0,
      S10_AXIS_TREADY => open,
      M11_AXIS_TLAST => open,
      M11_AXIS_TDATA => open,
      M11_AXIS_TVALID => open,
      M11_AXIS_TREADY => net_gnd0,
      S11_AXIS_TLAST => net_gnd0,
      S11_AXIS_TDATA => net_gnd32,
      S11_AXIS_TVALID => net_gnd0,
      S11_AXIS_TREADY => open,
      M12_AXIS_TLAST => open,
      M12_AXIS_TDATA => open,
      M12_AXIS_TVALID => open,
      M12_AXIS_TREADY => net_gnd0,
      S12_AXIS_TLAST => net_gnd0,
      S12_AXIS_TDATA => net_gnd32,
      S12_AXIS_TVALID => net_gnd0,
      S12_AXIS_TREADY => open,
      M13_AXIS_TLAST => open,
      M13_AXIS_TDATA => open,
      M13_AXIS_TVALID => open,
      M13_AXIS_TREADY => net_gnd0,
      S13_AXIS_TLAST => net_gnd0,
      S13_AXIS_TDATA => net_gnd32,
      S13_AXIS_TVALID => net_gnd0,
      S13_AXIS_TREADY => open,
      M14_AXIS_TLAST => open,
      M14_AXIS_TDATA => open,
      M14_AXIS_TVALID => open,
      M14_AXIS_TREADY => net_gnd0,
      S14_AXIS_TLAST => net_gnd0,
      S14_AXIS_TDATA => net_gnd32,
      S14_AXIS_TVALID => net_gnd0,
      S14_AXIS_TREADY => open,
      M15_AXIS_TLAST => open,
      M15_AXIS_TDATA => open,
      M15_AXIS_TVALID => open,
      M15_AXIS_TREADY => net_gnd0,
      S15_AXIS_TLAST => net_gnd0,
      S15_AXIS_TDATA => net_gnd32,
      S15_AXIS_TVALID => net_gnd0,
      S15_AXIS_TREADY => open,
      ICACHE_FSL_IN_CLK => open,
      ICACHE_FSL_IN_READ => open,
      ICACHE_FSL_IN_DATA => net_gnd32,
      ICACHE_FSL_IN_CONTROL => net_gnd0,
      ICACHE_FSL_IN_EXISTS => net_gnd0,
      ICACHE_FSL_OUT_CLK => open,
      ICACHE_FSL_OUT_WRITE => open,
      ICACHE_FSL_OUT_DATA => open,
      ICACHE_FSL_OUT_CONTROL => open,
      ICACHE_FSL_OUT_FULL => net_gnd0,
      DCACHE_FSL_IN_CLK => open,
      DCACHE_FSL_IN_READ => open,
      DCACHE_FSL_IN_DATA => net_gnd32,
      DCACHE_FSL_IN_CONTROL => net_gnd0,
      DCACHE_FSL_IN_EXISTS => net_gnd0,
      DCACHE_FSL_OUT_CLK => open,
      DCACHE_FSL_OUT_WRITE => open,
      DCACHE_FSL_OUT_DATA => open,
      DCACHE_FSL_OUT_CONTROL => open,
      DCACHE_FSL_OUT_FULL => net_gnd0
    );

  -- Trace interface enabled conditional compilation
  g_trc0: if (NEED_TRACING = 1) generate

    -- Data access trace enable
    o_ctl_trace_daccess <= trc_valid and trc_data_valid;

    -- "Energy" meter
    trc_mul_float  <= '1' when  (trc_instruction(0 to 1) = "01") else '0';
    trc_load_store <= '1' when  (trc_instruction(0 to 1) = "11") else '0';
    trc_arithmetic <= '1' when ((trc_instruction(0 to 1) = "00") or 
                                (trc_instruction(0 to 1) = "10")) else '0';

    o_ctl_trace_energy     <= trc_valid;
    o_ctl_trace_energy_val <= "010" when (trc_arithmetic = '1') else
                              "001" when (trc_load_store = '1') else
                              "100" when (trc_mul_float  = '1') else
                              "000";

    -- Addresses
    o_ctl_trace_data_adr <= trc_data_adr;
    o_ctl_trace_inst_adr <= trc_inst_adr;

  end generate g_trc0;

  -- Trace interface disabled conditional compilation
  g_trc1: if (NEED_TRACING = 0) generate

    o_ctl_trace_daccess <= '0';
    o_ctl_trace_energy  <= '0';
    o_ctl_trace_energy_val <= "000";
    o_ctl_trace_data_adr <= (others => '0');
    o_ctl_trace_inst_adr <= (others => '0');

  end generate g_trc1;

end architecture str;

