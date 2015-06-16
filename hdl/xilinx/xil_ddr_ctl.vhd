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
-- Abstract      : Xilinx DDR2 DRAM controller wrapper
--
-- =============================[ CVS Variables ]=============================
--
-- File name     : $RCSfile: xil_ddr_ctl.vhd,v $
-- CVS revision  : $Revision: 1.5 $
-- Last modified : $Date: 2012/07/03 16:28:58 $
-- Last author   : $Author: lyberis $
--
-- ===========================================================================

library ieee;
use ieee.std_logic_1164.all;

entity xil_ddr_ctl is

  generic (
    C5_P0_MASK_SIZE         : integer := 4;
    C5_P0_DATA_PORT_SIZE    : integer := 32;
    C5_P1_MASK_SIZE         : integer := 4;
    C5_P1_DATA_PORT_SIZE    : integer := 32;
    C5_MEMCLK_PERIOD        : integer := 2500; 
    C5_RST_ACT_LOW          : integer := 0; 
    C5_INPUT_CLK_TYPE       : string := "DIFFERENTIAL"; 
    C5_CALIB_SOFT_IP        : string := "TRUE"; 
    C5_SIMULATION           : string := "FALSE"; 
    DEBUG_EN                : integer := 0; 
    --C5_MEM_ADDR_ORDER       : string := "ROW_BANK_COLUMN"; 
    C5_MEM_ADDR_ORDER       : string := "BANK_ROW_COLUMN"; 
    C5_NUM_DQ_PINS          : integer := 16; 
    C5_MEM_ADDR_WIDTH       : integer := 13; 
    C5_MEM_BANKADDR_WIDTH   : integer := 3 
  );
   
  port (

   -- System interface
   clk_800                  : in std_logic;
   clk_800_180              : in std_logic;
   i_pll_ce_0               : in std_logic;
   i_pll_ce_90              : in std_logic;
   clk_drp                  : in std_logic;
   rst_master_assert        : in std_logic;
   rst_drp_deassert         : in std_logic;
   i_pll_locked             : in std_logic;
   o_calib_done             : out std_logic;

   -- DDR2 interface
   io_ddr_dq                : inout  std_logic_vector(15 downto 0);
   o_ddr_a                  : out std_logic_vector(12 downto 0);
   o_ddr_ba                 : out std_logic_vector(2 downto 0);
   o_ddr_ras_n              : out std_logic;
   o_ddr_cas_n              : out std_logic;
   o_ddr_we_n               : out std_logic;
   o_ddr_odt                : out std_logic;
   o_ddr_cke                : out std_logic;
   o_ddr_dm                 : out std_logic;
   io_ddr_udqs              : inout  std_logic;
   io_ddr_udqs_n            : inout  std_logic;
   io_ddr_rzq               : inout  std_logic;
   io_ddr_zio               : inout  std_logic;
   o_ddr_udm                : out std_logic;
   io_ddr_dqs               : inout  std_logic;
   io_ddr_dqs_n             : inout  std_logic;
   o_ddr_ck                 : out std_logic;
   o_ddr_ck_n               : out std_logic;

   -- User port 0
   i_p0_clk                 : in std_logic;
   i_p0_cmd_en              : in std_logic;
   i_p0_cmd_instr           : in std_logic_vector(2 downto 0);
   i_p0_cmd_bl              : in std_logic_vector(5 downto 0);
   i_p0_cmd_byte_addr       : in std_logic_vector(29 downto 0);
   o_p0_cmd_empty           : out std_logic;
   o_p0_cmd_full            : out std_logic;
   i_p0_wr_en               : in std_logic;
   i_p0_wr_mask             : in std_logic_vector(3 downto 0);
   i_p0_wr_data             : in std_logic_vector(31 downto 0);
   o_p0_wr_almost_full      : out std_logic;
   i_p0_rd_en               : in std_logic;
   o_p0_rd_data             : out std_logic_vector(31 downto 0);
   o_p0_rd_empty            : out std_logic;
   o_p0_error               : out std_logic;

   -- User port 1
   i_p1_clk                 : in std_logic;
   i_p1_cmd_en              : in std_logic;
   i_p1_cmd_instr           : in std_logic_vector(2 downto 0);
   i_p1_cmd_bl              : in std_logic_vector(5 downto 0);
   i_p1_cmd_byte_addr       : in std_logic_vector(29 downto 0);
   o_p1_cmd_empty           : out std_logic;
   o_p1_cmd_full            : out std_logic;
   i_p1_wr_en               : in std_logic;
   i_p1_wr_mask             : in std_logic_vector(3 downto 0);
   i_p1_wr_data             : in std_logic_vector(31 downto 0);
   o_p1_wr_almost_full      : out std_logic;
   i_p1_rd_en               : in std_logic;
   o_p1_rd_data             : out std_logic_vector(31 downto 0);
   o_p1_rd_empty            : out std_logic;
   o_p1_error               : out std_logic;

   -- User port 2
   i_p2_clk                 : in std_logic;
   i_p2_cmd_en              : in std_logic;
   i_p2_cmd_instr           : in std_logic_vector(2 downto 0);
   i_p2_cmd_bl              : in std_logic_vector(5 downto 0);
   i_p2_cmd_byte_addr       : in std_logic_vector(29 downto 0);
   o_p2_cmd_empty           : out std_logic;
   o_p2_cmd_full            : out std_logic;
   i_p2_wr_en               : in std_logic;
   i_p2_wr_mask             : in std_logic_vector(3 downto 0);
   i_p2_wr_data             : in std_logic_vector(31 downto 0);
   o_p2_wr_almost_full      : out std_logic;
   i_p2_rd_en               : in std_logic;
   o_p2_rd_data             : out std_logic_vector(31 downto 0);
   o_p2_rd_empty            : out std_logic;
   o_p2_error               : out std_logic;

   -- User port 3
   i_p3_clk                 : in std_logic;
   i_p3_cmd_en              : in std_logic;
   i_p3_cmd_instr           : in std_logic_vector(2 downto 0);
   i_p3_cmd_bl              : in std_logic_vector(5 downto 0);
   i_p3_cmd_byte_addr       : in std_logic_vector(29 downto 0);
   o_p3_cmd_empty           : out std_logic;
   o_p3_cmd_full            : out std_logic;
   i_p3_wr_en               : in std_logic;
   i_p3_wr_mask             : in std_logic_vector(3 downto 0);
   i_p3_wr_data             : in std_logic_vector(31 downto 0);
   o_p3_wr_almost_full      : out std_logic;
   i_p3_rd_en               : in std_logic;
   o_p3_rd_data             : out std_logic_vector(31 downto 0);
   o_p3_rd_empty            : out std_logic;
   o_p3_error               : out std_logic
  );
end xil_ddr_ctl;

architecture arc of xil_ddr_ctl is

  component memc5_wrapper is
    generic (
      C_MEMCLK_PERIOD      : integer;
      C_CALIB_SOFT_IP      : string;
      C_SIMULATION         : string;
      C_P0_MASK_SIZE       : integer;
      C_P0_DATA_PORT_SIZE   : integer;
      C_P1_MASK_SIZE       : integer;
      C_P1_DATA_PORT_SIZE   : integer;
      C_ARB_NUM_TIME_SLOTS   : integer;
      C_ARB_TIME_SLOT_0    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_1    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_2    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_3    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_4    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_5    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_6    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_7    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_8    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_9    : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_10   : bit_vector(11 downto 0);
      C_ARB_TIME_SLOT_11   : bit_vector(11 downto 0);
      C_MEM_TRAS           : integer;
      C_MEM_TRCD           : integer;
      C_MEM_TREFI          : integer;
      C_MEM_TRFC           : integer;
      C_MEM_TRP            : integer;
      C_MEM_TWR            : integer;
      C_MEM_TRTP           : integer;
      C_MEM_TWTR           : integer;
      C_MEM_ADDR_ORDER     : string;
      C_NUM_DQ_PINS        : integer;
      C_MEM_TYPE           : string;
      C_MEM_DENSITY        : string;
      C_MEM_BURST_LEN      : integer;
      C_MEM_CAS_LATENCY    : integer;
      C_MEM_ADDR_WIDTH     : integer;
      C_MEM_BANKADDR_WIDTH   : integer;
      C_MEM_NUM_COL_BITS   : integer;
      C_MEM_DDR1_2_ODS     : string;
      C_MEM_DDR2_RTT       : string;
      C_MEM_DDR2_DIFF_DQS_EN   : string;
      C_MEM_DDR2_3_PA_SR   : string;
      C_MEM_DDR2_3_HIGH_TEMP_SR   : string;
      C_MEM_DDR3_CAS_LATENCY   : integer;
      C_MEM_DDR3_ODS       : string;
      C_MEM_DDR3_RTT       : string;
      C_MEM_DDR3_CAS_WR_LATENCY   : integer;
      C_MEM_DDR3_AUTO_SR   : string;
      C_MEM_DDR3_DYN_WRT_ODT   : string;
      C_MEM_MOBILE_PA_SR   : string;
      C_MEM_MDDR_ODS       : string;
      C_MC_CALIB_BYPASS    : string;
      C_MC_CALIBRATION_MODE   : string;
      C_MC_CALIBRATION_DELAY   : string;
      C_SKIP_IN_TERM_CAL   : integer;
      C_SKIP_DYNAMIC_CAL   : integer;
      C_LDQSP_TAP_DELAY_VAL   : integer;
      C_LDQSN_TAP_DELAY_VAL   : integer;
      C_UDQSP_TAP_DELAY_VAL   : integer;
      C_UDQSN_TAP_DELAY_VAL   : integer;
      C_DQ0_TAP_DELAY_VAL   : integer;
      C_DQ1_TAP_DELAY_VAL   : integer;
      C_DQ2_TAP_DELAY_VAL   : integer;
      C_DQ3_TAP_DELAY_VAL   : integer;
      C_DQ4_TAP_DELAY_VAL   : integer;
      C_DQ5_TAP_DELAY_VAL   : integer;
      C_DQ6_TAP_DELAY_VAL   : integer;
      C_DQ7_TAP_DELAY_VAL   : integer;
      C_DQ8_TAP_DELAY_VAL   : integer;
      C_DQ9_TAP_DELAY_VAL   : integer;
      C_DQ10_TAP_DELAY_VAL   : integer;
      C_DQ11_TAP_DELAY_VAL   : integer;
      C_DQ12_TAP_DELAY_VAL   : integer;
      C_DQ13_TAP_DELAY_VAL   : integer;
      C_DQ14_TAP_DELAY_VAL   : integer;
      C_DQ15_TAP_DELAY_VAL   : integer
      );
    port (
      mcb5_dram_dq                           : inout  std_logic_vector((C_NUM_DQ_PINS-1) downto 0);
      mcb5_dram_a                            : out  std_logic_vector((C_MEM_ADDR_WIDTH-1) downto 0);
      mcb5_dram_ba                           : out  std_logic_vector((C_MEM_BANKADDR_WIDTH-1) downto 0);
      mcb5_dram_ras_n                        : out  std_logic;
      mcb5_dram_cas_n                        : out  std_logic;
      mcb5_dram_we_n                         : out  std_logic;
      mcb5_dram_odt                          : out  std_logic;
      mcb5_dram_cke                          : out  std_logic;
      mcb5_dram_dm                           : out  std_logic;
      mcb5_dram_udqs                         : inout  std_logic;
      mcb5_dram_udqs_n                       : inout  std_logic;
      mcb5_rzq                               : inout  std_logic;
      mcb5_zio                               : inout  std_logic;
      mcb5_dram_udm                          : out  std_logic;
      calib_done                             : out  std_logic;
      async_rst                              : in  std_logic;
      sysclk_2x                              : in  std_logic;
      sysclk_2x_180                          : in  std_logic;
      pll_ce_0                               : in  std_logic;
      pll_ce_90                              : in  std_logic;
      pll_lock                               : in  std_logic;
      mcb_drp_clk                            : in  std_logic;
      mcb5_dram_dqs                          : inout  std_logic;
      mcb5_dram_dqs_n                        : inout  std_logic;
      mcb5_dram_ck                           : out  std_logic;
      mcb5_dram_ck_n                         : out  std_logic;
      p0_cmd_clk                            : in std_logic;
      p0_cmd_en                             : in std_logic;
      p0_cmd_instr                          : in std_logic_vector(2 downto 0);
      p0_cmd_bl                             : in std_logic_vector(5 downto 0);
      p0_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p0_cmd_empty                          : out std_logic;
      p0_cmd_full                           : out std_logic;
      p0_wr_clk                             : in std_logic;
      p0_wr_en                              : in std_logic;
      p0_wr_mask                            : in std_logic_vector(C_P0_MASK_SIZE - 1 downto 0);
      p0_wr_data                            : in std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_wr_full                            : out std_logic;
      p0_wr_empty                           : out std_logic;
      p0_wr_count                           : out std_logic_vector(6 downto 0);
      p0_wr_underrun                        : out std_logic;
      p0_wr_error                           : out std_logic;
      p0_rd_clk                             : in std_logic;
      p0_rd_en                              : in std_logic;
      p0_rd_data                            : out std_logic_vector(C_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_rd_full                            : out std_logic;
      p0_rd_empty                           : out std_logic;
      p0_rd_count                           : out std_logic_vector(6 downto 0);
      p0_rd_overflow                        : out std_logic;
      p0_rd_error                           : out std_logic;
      p1_cmd_clk                            : in std_logic;
      p1_cmd_en                             : in std_logic;
      p1_cmd_instr                          : in std_logic_vector(2 downto 0);
      p1_cmd_bl                             : in std_logic_vector(5 downto 0);
      p1_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p1_cmd_empty                          : out std_logic;
      p1_cmd_full                           : out std_logic;
      p1_wr_clk                             : in std_logic;
      p1_wr_en                              : in std_logic;
      p1_wr_mask                            : in std_logic_vector(C_P1_MASK_SIZE - 1 downto 0);
      p1_wr_data                            : in std_logic_vector(C_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_wr_full                            : out std_logic;
      p1_wr_empty                           : out std_logic;
      p1_wr_count                           : out std_logic_vector(6 downto 0);
      p1_wr_underrun                        : out std_logic;
      p1_wr_error                           : out std_logic;
      p1_rd_clk                             : in std_logic;
      p1_rd_en                              : in std_logic;
      p1_rd_data                            : out std_logic_vector(C_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_rd_full                            : out std_logic;
      p1_rd_empty                           : out std_logic;
      p1_rd_count                           : out std_logic_vector(6 downto 0);
      p1_rd_overflow                        : out std_logic;
      p1_rd_error                           : out std_logic;
      p2_cmd_clk                            : in std_logic;
      p2_cmd_en                             : in std_logic;
      p2_cmd_instr                          : in std_logic_vector(2 downto 0);
      p2_cmd_bl                             : in std_logic_vector(5 downto 0);
      p2_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p2_cmd_empty                          : out std_logic;
      p2_cmd_full                           : out std_logic;
      p2_wr_clk                             : in std_logic;
      p2_wr_en                              : in std_logic;
      p2_wr_mask                            : in std_logic_vector(3 downto 0);
      p2_wr_data                            : in std_logic_vector(31 downto 0);
      p2_wr_full                            : out std_logic;
      p2_wr_empty                           : out std_logic;
      p2_wr_count                           : out std_logic_vector(6 downto 0);
      p2_wr_underrun                        : out std_logic;
      p2_wr_error                           : out std_logic;
      p2_rd_clk                             : in std_logic;
      p2_rd_en                              : in std_logic;
      p2_rd_data                            : out std_logic_vector(31 downto 0);
      p2_rd_full                            : out std_logic;
      p2_rd_empty                           : out std_logic;
      p2_rd_count                           : out std_logic_vector(6 downto 0);
      p2_rd_overflow                        : out std_logic;
      p2_rd_error                           : out std_logic;
      p3_cmd_clk                            : in std_logic;
      p3_cmd_en                             : in std_logic;
      p3_cmd_instr                          : in std_logic_vector(2 downto 0);
      p3_cmd_bl                             : in std_logic_vector(5 downto 0);
      p3_cmd_byte_addr                      : in std_logic_vector(29 downto 0);
      p3_cmd_empty                          : out std_logic;
      p3_cmd_full                           : out std_logic;
      p3_wr_clk                             : in std_logic;
      p3_wr_en                              : in std_logic;
      p3_wr_mask                            : in std_logic_vector(3 downto 0);
      p3_wr_data                            : in std_logic_vector(31 downto 0);
      p3_wr_full                            : out std_logic;
      p3_wr_empty                           : out std_logic;
      p3_wr_count                           : out std_logic_vector(6 downto 0);
      p3_wr_underrun                        : out std_logic;
      p3_wr_error                           : out std_logic;
      p3_rd_clk                             : in std_logic;
      p3_rd_en                              : in std_logic;
      p3_rd_data                            : out std_logic_vector(31 downto 0);
      p3_rd_full                            : out std_logic;
      p3_rd_empty                           : out std_logic;
      p3_rd_count                           : out std_logic_vector(6 downto 0);
      p3_rd_overflow                        : out std_logic;
      p3_rd_error                           : out std_logic;
      selfrefresh_enter                     : in std_logic;
      selfrefresh_mode                      : out std_logic

      );
  end component;

  component rst_sync_simple is
    generic (
      CLOCK_CYCLES  : integer
    );
    port (
      clk           : in  std_logic;
      rst_async     : in  std_logic;
      deassert      : in  std_logic;
      rst           : out std_logic
    );
  end component;


   constant C5_CLKOUT0_DIVIDE       : integer := 1; 
   constant C5_CLKOUT1_DIVIDE       : integer := 1; 
   constant C5_CLKOUT2_DIVIDE       : integer := 16; 
   constant C5_CLKOUT3_DIVIDE       : integer := 8; 
   constant C5_CLKFBOUT_MULT        : integer := 2; 
   constant C5_DIVCLK_DIVIDE        : integer := 1; 
   constant C5_ARB_NUM_TIME_SLOTS   : integer := 12; 
   constant C5_ARB_TIME_SLOT_0      : bit_vector(11 downto 0) := o"0124"; 
   constant C5_ARB_TIME_SLOT_1      : bit_vector(11 downto 0) := o"1240"; 
   constant C5_ARB_TIME_SLOT_2      : bit_vector(11 downto 0) := o"2401"; 
   constant C5_ARB_TIME_SLOT_3      : bit_vector(11 downto 0) := o"4012"; 
   constant C5_ARB_TIME_SLOT_4      : bit_vector(11 downto 0) := o"0124"; 
   constant C5_ARB_TIME_SLOT_5      : bit_vector(11 downto 0) := o"1240"; 
   constant C5_ARB_TIME_SLOT_6      : bit_vector(11 downto 0) := o"2401"; 
   constant C5_ARB_TIME_SLOT_7      : bit_vector(11 downto 0) := o"4012"; 
   constant C5_ARB_TIME_SLOT_8      : bit_vector(11 downto 0) := o"0124"; 
   constant C5_ARB_TIME_SLOT_9      : bit_vector(11 downto 0) := o"1240"; 
   constant C5_ARB_TIME_SLOT_10     : bit_vector(11 downto 0) := o"2401"; 
   constant C5_ARB_TIME_SLOT_11     : bit_vector(11 downto 0) := o"4012"; 
   constant C5_MEM_TRAS             : integer := 42500; 
   constant C5_MEM_TRCD             : integer := 12500; 
   constant C5_MEM_TREFI            : integer := 7800000; 
   constant C5_MEM_TRFC             : integer := 127500; 
   constant C5_MEM_TRP              : integer := 12500; 
   constant C5_MEM_TWR              : integer := 15000; 
   constant C5_MEM_TRTP             : integer := 7500; 
   constant C5_MEM_TWTR             : integer := 7500; 
   constant C5_MEM_TYPE             : string := "DDR2"; 
   constant C5_MEM_DENSITY          : string := "1Gb"; 
   constant C5_MEM_BURST_LEN        : integer := 4; 
   constant C5_MEM_CAS_LATENCY      : integer := 5; 
   constant C5_MEM_NUM_COL_BITS     : integer := 10; 
   constant C5_MEM_DDR1_2_ODS       : string := "FULL"; 
   constant C5_MEM_DDR2_RTT         : string := "50OHMS"; 
   constant C5_MEM_DDR2_DIFF_DQS_EN  : string := "YES"; 
   constant C5_MEM_DDR2_3_PA_SR     : string := "FULL"; 
   constant C5_MEM_DDR2_3_HIGH_TEMP_SR  : string := "NORMAL"; 
   constant C5_MEM_DDR3_CAS_LATENCY  : integer := 6; 
   constant C5_MEM_DDR3_ODS         : string := "DIV6"; 
   constant C5_MEM_DDR3_RTT         : string := "DIV2"; 
   constant C5_MEM_DDR3_CAS_WR_LATENCY  : integer := 5; 
   constant C5_MEM_DDR3_AUTO_SR     : string := "ENABLED"; 
   constant C5_MEM_DDR3_DYN_WRT_ODT  : string := "OFF"; 
   constant C5_MEM_MOBILE_PA_SR     : string := "FULL"; 
   constant C5_MEM_MDDR_ODS         : string := "FULL"; 
   constant C5_MC_CALIB_BYPASS      : string := "NO"; 
   constant C5_MC_CALIBRATION_MODE  : string := "CALIBRATION"; 
   constant C5_MC_CALIBRATION_DELAY  : string := "HALF"; 
   constant C5_SKIP_IN_TERM_CAL     : integer := 0; 
   constant C5_SKIP_DYNAMIC_CAL     : integer := 0; 
   constant C5_LDQSP_TAP_DELAY_VAL  : integer := 0; 
   constant C5_LDQSN_TAP_DELAY_VAL  : integer := 0; 
   constant C5_UDQSP_TAP_DELAY_VAL  : integer := 0; 
   constant C5_UDQSN_TAP_DELAY_VAL  : integer := 0; 
   constant C5_DQ0_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ1_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ2_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ3_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ4_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ5_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ6_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ7_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ8_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ9_TAP_DELAY_VAL    : integer := 0; 
   constant C5_DQ10_TAP_DELAY_VAL   : integer := 0; 
   constant C5_DQ11_TAP_DELAY_VAL   : integer := 0; 
   constant C5_DQ12_TAP_DELAY_VAL   : integer := 0; 
   constant C5_DQ13_TAP_DELAY_VAL   : integer := 0; 
   constant C5_DQ14_TAP_DELAY_VAL   : integer := 0; 
   constant C5_DQ15_TAP_DELAY_VAL   : integer := 0; 

  signal  c5_sys_clk                               : std_logic;
  signal  c5_async_rst                             : std_logic;
  signal  c5_sysclk_2x                             : std_logic;
  signal  c5_sysclk_2x_180                         : std_logic;
  signal  c5_pll_ce_0                              : std_logic;
  signal  c5_pll_ce_90                             : std_logic;
  signal  c5_pll_lock                              : std_logic;
  signal  c5_mcb_drp_clk                           : std_logic;
  signal  c5_cmp_error                             : std_logic;
  signal  c5_cmp_data_valid                        : std_logic;
  signal  c5_vio_modify_enable                     : std_logic;
  signal  c5_error_status                          : std_logic_vector(127 downto 0);
  signal  c5_vio_data_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_vio_addr_mode_value                   : std_logic_vector(2 downto 0);
  signal  c5_cmp_data                              : std_logic_vector(31 downto 0);
  signal  c5_selfrefresh_enter                     : std_logic;
  signal  c5_selfrefresh_mode                      : std_logic;


  constant gnd : std_logic := '0';

  signal rst_drp : std_logic;

  signal p0_wr_count : std_logic_vector(6 downto 0);
  signal p1_wr_count : std_logic_vector(6 downto 0);
  signal p2_wr_count : std_logic_vector(6 downto 0);
  signal p3_wr_count : std_logic_vector(6 downto 0);

  signal p0_wr_underrun : std_logic;
  signal p0_wr_error    : std_logic;
  signal p0_rd_overflow : std_logic;
  signal p0_rd_error    : std_logic;
  signal p1_wr_underrun : std_logic;
  signal p1_wr_error    : std_logic;
  signal p1_rd_overflow : std_logic;
  signal p1_rd_error    : std_logic;
  signal p2_wr_underrun : std_logic;
  signal p2_wr_error    : std_logic;
  signal p2_rd_overflow : std_logic;
  signal p2_rd_error    : std_logic;
  signal p3_wr_underrun : std_logic;
  signal p3_wr_error    : std_logic;
  signal p3_rd_overflow : std_logic;
  signal p3_rd_error    : std_logic;


begin

  -- ==========================================================================
  -- Reset generation
  -- ==========================================================================
  i0_rst_sync_simple: rst_sync_simple generic map (
    CLOCK_CYCLES  => 4
  ) port map (
    clk           => clk_drp,
    rst_async     => rst_master_assert,
    deassert      => rst_drp_deassert,
    rst           => rst_drp
  );

 memc5_wrapper_inst : memc5_wrapper

generic map
 (
   C_MEMCLK_PERIOD                   => C5_MEMCLK_PERIOD,
   C_CALIB_SOFT_IP                   => C5_CALIB_SOFT_IP,
   C_SIMULATION                      => C5_SIMULATION,
   C_P0_MASK_SIZE                    => C5_P0_MASK_SIZE,
   C_P0_DATA_PORT_SIZE               => C5_P0_DATA_PORT_SIZE,
   C_P1_MASK_SIZE                    => C5_P1_MASK_SIZE,
   C_P1_DATA_PORT_SIZE               => C5_P1_DATA_PORT_SIZE,
   C_ARB_NUM_TIME_SLOTS              => C5_ARB_NUM_TIME_SLOTS,
   C_ARB_TIME_SLOT_0                 => C5_ARB_TIME_SLOT_0,
   C_ARB_TIME_SLOT_1                 => C5_ARB_TIME_SLOT_1,
   C_ARB_TIME_SLOT_2                 => C5_ARB_TIME_SLOT_2,
   C_ARB_TIME_SLOT_3                 => C5_ARB_TIME_SLOT_3,
   C_ARB_TIME_SLOT_4                 => C5_ARB_TIME_SLOT_4,
   C_ARB_TIME_SLOT_5                 => C5_ARB_TIME_SLOT_5,
   C_ARB_TIME_SLOT_6                 => C5_ARB_TIME_SLOT_6,
   C_ARB_TIME_SLOT_7                 => C5_ARB_TIME_SLOT_7,
   C_ARB_TIME_SLOT_8                 => C5_ARB_TIME_SLOT_8,
   C_ARB_TIME_SLOT_9                 => C5_ARB_TIME_SLOT_9,
   C_ARB_TIME_SLOT_10                => C5_ARB_TIME_SLOT_10,
   C_ARB_TIME_SLOT_11                => C5_ARB_TIME_SLOT_11,
   C_MEM_TRAS                        => C5_MEM_TRAS,
   C_MEM_TRCD                        => C5_MEM_TRCD,
   C_MEM_TREFI                       => C5_MEM_TREFI,
   C_MEM_TRFC                        => C5_MEM_TRFC,
   C_MEM_TRP                         => C5_MEM_TRP,
   C_MEM_TWR                         => C5_MEM_TWR,
   C_MEM_TRTP                        => C5_MEM_TRTP,
   C_MEM_TWTR                        => C5_MEM_TWTR,
   C_MEM_ADDR_ORDER                  => C5_MEM_ADDR_ORDER,
   C_NUM_DQ_PINS                     => C5_NUM_DQ_PINS,
   C_MEM_TYPE                        => C5_MEM_TYPE,
   C_MEM_DENSITY                     => C5_MEM_DENSITY,
   C_MEM_BURST_LEN                   => C5_MEM_BURST_LEN,
   C_MEM_CAS_LATENCY                 => C5_MEM_CAS_LATENCY,
   C_MEM_ADDR_WIDTH                  => C5_MEM_ADDR_WIDTH,
   C_MEM_BANKADDR_WIDTH              => C5_MEM_BANKADDR_WIDTH,
   C_MEM_NUM_COL_BITS                => C5_MEM_NUM_COL_BITS,
   C_MEM_DDR1_2_ODS                  => C5_MEM_DDR1_2_ODS,
   C_MEM_DDR2_RTT                    => C5_MEM_DDR2_RTT,
   C_MEM_DDR2_DIFF_DQS_EN            => C5_MEM_DDR2_DIFF_DQS_EN,
   C_MEM_DDR2_3_PA_SR                => C5_MEM_DDR2_3_PA_SR,
   C_MEM_DDR2_3_HIGH_TEMP_SR         => C5_MEM_DDR2_3_HIGH_TEMP_SR,
   C_MEM_DDR3_CAS_LATENCY            => C5_MEM_DDR3_CAS_LATENCY,
   C_MEM_DDR3_ODS                    => C5_MEM_DDR3_ODS,
   C_MEM_DDR3_RTT                    => C5_MEM_DDR3_RTT,
   C_MEM_DDR3_CAS_WR_LATENCY         => C5_MEM_DDR3_CAS_WR_LATENCY,
   C_MEM_DDR3_AUTO_SR                => C5_MEM_DDR3_AUTO_SR,
   C_MEM_DDR3_DYN_WRT_ODT            => C5_MEM_DDR3_DYN_WRT_ODT,
   C_MEM_MOBILE_PA_SR                => C5_MEM_MOBILE_PA_SR,
   C_MEM_MDDR_ODS                    => C5_MEM_MDDR_ODS,
   C_MC_CALIB_BYPASS                 => C5_MC_CALIB_BYPASS,
   C_MC_CALIBRATION_MODE             => C5_MC_CALIBRATION_MODE,
   C_MC_CALIBRATION_DELAY            => C5_MC_CALIBRATION_DELAY,
   C_SKIP_IN_TERM_CAL                => C5_SKIP_IN_TERM_CAL,
   C_SKIP_DYNAMIC_CAL                => C5_SKIP_DYNAMIC_CAL,
   C_LDQSP_TAP_DELAY_VAL             => C5_LDQSP_TAP_DELAY_VAL,
   C_LDQSN_TAP_DELAY_VAL             => C5_LDQSN_TAP_DELAY_VAL,
   C_UDQSP_TAP_DELAY_VAL             => C5_UDQSP_TAP_DELAY_VAL,
   C_UDQSN_TAP_DELAY_VAL             => C5_UDQSN_TAP_DELAY_VAL,
   C_DQ0_TAP_DELAY_VAL               => C5_DQ0_TAP_DELAY_VAL,
   C_DQ1_TAP_DELAY_VAL               => C5_DQ1_TAP_DELAY_VAL,
   C_DQ2_TAP_DELAY_VAL               => C5_DQ2_TAP_DELAY_VAL,
   C_DQ3_TAP_DELAY_VAL               => C5_DQ3_TAP_DELAY_VAL,
   C_DQ4_TAP_DELAY_VAL               => C5_DQ4_TAP_DELAY_VAL,
   C_DQ5_TAP_DELAY_VAL               => C5_DQ5_TAP_DELAY_VAL,
   C_DQ6_TAP_DELAY_VAL               => C5_DQ6_TAP_DELAY_VAL,
   C_DQ7_TAP_DELAY_VAL               => C5_DQ7_TAP_DELAY_VAL,
   C_DQ8_TAP_DELAY_VAL               => C5_DQ8_TAP_DELAY_VAL,
   C_DQ9_TAP_DELAY_VAL               => C5_DQ9_TAP_DELAY_VAL,
   C_DQ10_TAP_DELAY_VAL              => C5_DQ10_TAP_DELAY_VAL,
   C_DQ11_TAP_DELAY_VAL              => C5_DQ11_TAP_DELAY_VAL,
   C_DQ12_TAP_DELAY_VAL              => C5_DQ12_TAP_DELAY_VAL,
   C_DQ13_TAP_DELAY_VAL              => C5_DQ13_TAP_DELAY_VAL,
   C_DQ14_TAP_DELAY_VAL              => C5_DQ14_TAP_DELAY_VAL,
   C_DQ15_TAP_DELAY_VAL              => C5_DQ15_TAP_DELAY_VAL
   )
port map
(
   -- System interface
   sysclk_2x                       => clk_800,
   sysclk_2x_180                   => clk_800_180,
   pll_ce_0                        => i_pll_ce_0,
   pll_ce_90                       => i_pll_ce_90,
   mcb_drp_clk                     => clk_drp,
   async_rst                       => rst_drp,
   pll_lock                        => i_pll_locked,
   calib_done                      => o_calib_done,
   selfrefresh_enter               => gnd,
   selfrefresh_mode                => open,

   -- DDR2 interface
   mcb5_dram_dq                    => io_ddr_dq,
   mcb5_dram_a                     => o_ddr_a,
   mcb5_dram_ba                    => o_ddr_ba,
   mcb5_dram_ras_n                 => o_ddr_ras_n,
   mcb5_dram_cas_n                 => o_ddr_cas_n,
   mcb5_dram_we_n                  => o_ddr_we_n,
   mcb5_dram_odt                   => o_ddr_odt,
   mcb5_dram_cke                   => o_ddr_cke,
   mcb5_dram_dm                    => o_ddr_dm,
   mcb5_dram_udqs                  => io_ddr_udqs,
   mcb5_dram_udqs_n                => io_ddr_udqs_n,
   mcb5_rzq                        => io_ddr_rzq,
   mcb5_zio                        => io_ddr_zio,
   mcb5_dram_udm                   => o_ddr_udm,
   mcb5_dram_dqs                   => io_ddr_dqs,
   mcb5_dram_dqs_n                 => io_ddr_dqs_n,
   mcb5_dram_ck                    => o_ddr_ck,
   mcb5_dram_ck_n                  => o_ddr_ck_n,

   -- User port 0
   p0_cmd_clk                      => i_p0_clk,
   p0_cmd_en                       => i_p0_cmd_en,
   p0_cmd_instr                    => i_p0_cmd_instr,
   p0_cmd_bl                       => i_p0_cmd_bl,
   p0_cmd_byte_addr                => i_p0_cmd_byte_addr,
   p0_cmd_empty                    => o_p0_cmd_empty,
   p0_cmd_full                     => o_p0_cmd_full,
   p0_wr_clk                       => i_p0_clk,
   p0_wr_en                        => i_p0_wr_en,
   p0_wr_mask                      => i_p0_wr_mask,
   p0_wr_data                      => i_p0_wr_data,
   p0_wr_full                      => open,
   p0_wr_empty                     => open,
   p0_wr_count                     => p0_wr_count,
   p0_wr_underrun                  => p0_wr_underrun,
   p0_wr_error                     => p0_wr_error,
   p0_rd_clk                       => i_p0_clk,
   p0_rd_en                        => i_p0_rd_en,
   p0_rd_data                      => o_p0_rd_data,
   p0_rd_full                      => open,
   p0_rd_empty                     => o_p0_rd_empty,
   p0_rd_count                     => open,
   p0_rd_overflow                  => p0_rd_overflow,
   p0_rd_error                     => p0_rd_error,

   -- User port 1
   p1_cmd_clk                      => i_p1_clk,
   p1_cmd_en                       => i_p1_cmd_en,
   p1_cmd_instr                    => i_p1_cmd_instr,
   p1_cmd_bl                       => i_p1_cmd_bl,
   p1_cmd_byte_addr                => i_p1_cmd_byte_addr,
   p1_cmd_empty                    => o_p1_cmd_empty,
   p1_cmd_full                     => o_p1_cmd_full,
   p1_wr_clk                       => i_p1_clk,
   p1_wr_en                        => i_p1_wr_en,
   p1_wr_mask                      => i_p1_wr_mask,
   p1_wr_data                      => i_p1_wr_data,
   p1_wr_full                      => open,
   p1_wr_empty                     => open,
   p1_wr_count                     => p1_wr_count,
   p1_wr_underrun                  => p1_wr_underrun,
   p1_wr_error                     => p1_wr_error,
   p1_rd_clk                       => i_p1_clk,
   p1_rd_en                        => i_p1_rd_en,
   p1_rd_data                      => o_p1_rd_data,
   p1_rd_full                      => open,
   p1_rd_empty                     => o_p1_rd_empty,
   p1_rd_count                     => open,
   p1_rd_overflow                  => p1_rd_overflow,
   p1_rd_error                     => p1_rd_error,

   -- User port 2
   p2_cmd_clk                      => i_p2_clk,
   p2_cmd_en                       => i_p2_cmd_en,
   p2_cmd_instr                    => i_p2_cmd_instr,
   p2_cmd_bl                       => i_p2_cmd_bl,
   p2_cmd_byte_addr                => i_p2_cmd_byte_addr,
   p2_cmd_empty                    => o_p2_cmd_empty,
   p2_cmd_full                     => o_p2_cmd_full,
   p2_wr_clk                       => i_p2_clk,
   p2_wr_en                        => i_p2_wr_en,
   p2_wr_mask                      => i_p2_wr_mask,
   p2_wr_data                      => i_p2_wr_data,
   p2_wr_full                      => open,
   p2_wr_empty                     => open,
   p2_wr_count                     => p2_wr_count,
   p2_wr_underrun                  => p2_wr_underrun,
   p2_wr_error                     => p2_wr_error,
   p2_rd_clk                       => i_p2_clk,
   p2_rd_en                        => i_p2_rd_en,
   p2_rd_data                      => o_p2_rd_data,
   p2_rd_full                      => open,
   p2_rd_empty                     => o_p2_rd_empty,
   p2_rd_count                     => open,
   p2_rd_overflow                  => p2_rd_overflow,
   p2_rd_error                     => p2_rd_error,

   -- User port 3
   p3_cmd_clk                      => i_p3_clk,
   p3_cmd_en                       => i_p3_cmd_en,
   p3_cmd_instr                    => i_p3_cmd_instr,
   p3_cmd_bl                       => i_p3_cmd_bl,
   p3_cmd_byte_addr                => i_p3_cmd_byte_addr,
   p3_cmd_empty                    => o_p3_cmd_empty,
   p3_cmd_full                     => o_p3_cmd_full,
   p3_wr_clk                       => i_p3_clk,
   p3_wr_en                        => i_p3_wr_en,
   p3_wr_mask                      => i_p3_wr_mask,
   p3_wr_data                      => i_p3_wr_data,
   p3_wr_full                      => open,
   p3_wr_empty                     => open,
   p3_wr_count                     => p3_wr_count,
   p3_wr_underrun                  => p3_wr_underrun,
   p3_wr_error                     => p3_wr_error,
   p3_rd_clk                       => i_p3_clk,
   p3_rd_en                        => i_p3_rd_en,
   p3_rd_data                      => o_p3_rd_data,
   p3_rd_full                      => open,
   p3_rd_empty                     => o_p3_rd_empty,
   p3_rd_count                     => open,
   p3_rd_overflow                  => p3_rd_overflow,
   p3_rd_error                     => p3_rd_error
);

  process (i_p0_clk)
  begin
    if (i_p0_clk'event and i_p0_clk = '1') then
      if (p0_wr_count > "0111000") then
        o_p0_wr_almost_full <= '1';
      else
        o_p0_wr_almost_full <= '0';
      end if;

      o_p0_error <= p0_wr_underrun or p0_wr_error or 
                    p0_rd_overflow or p0_rd_error;
    end if;
  end process;
  
  process (i_p1_clk)
  begin
    if (i_p1_clk'event and i_p1_clk = '1') then
      if (p1_wr_count > "0111000") then
        o_p1_wr_almost_full <= '1';
      else
        o_p1_wr_almost_full <= '0';
      end if;

      o_p1_error <= p0_wr_underrun or p0_wr_error or 
                    p0_rd_overflow or p0_rd_error;
    end if;
  end process;
  
  process (i_p2_clk)
  begin
    if (i_p2_clk'event and i_p2_clk = '1') then
      if (p2_wr_count > "0111000") then
        o_p2_wr_almost_full <= '1';
      else
        o_p2_wr_almost_full <= '0';
      end if;

      o_p2_error <= p0_wr_underrun or p0_wr_error or 
                    p0_rd_overflow or p0_rd_error;
    end if;
  end process;
  
  process (i_p3_clk)
  begin
    if (i_p3_clk'event and i_p3_clk = '1') then
      if (p3_wr_count > "0111000") then
        o_p3_wr_almost_full <= '1';
      else
        o_p3_wr_almost_full <= '0';
      end if;

      o_p3_error <= p0_wr_underrun or p0_wr_error or 
                    p0_rd_overflow or p0_rd_error;
    end if;
  end process;
  

 end  arc;
