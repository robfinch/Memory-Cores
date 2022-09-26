`timescale 1ns / 1ps
// ============================================================================
//        __
//   \\__/ o\    (C) 2015  Robert Finch, Stratford
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//
// ============================================================================
//
module mpmc(
rst_i, clk200MHz, fpga_temp,
mem_ui_clk,
cyc0, stb0, ack0, we0, adr0, dati0, dato0,
cyc1, stb1, ack1, we1, sel1, adr1, dati1, dato1, sr1, cr1, rb1,
cyc2, stb2, ack2, we2, sel2, adr2, dati2, dato2,
cyc3, stb3, ack3, we3, sel3, adr3, dati3, dato3,
cyc4, stb4, ack4, we4, adr4, dati4, dato4,
cyc5, stb5, ack5, adr5, dato5,
cyc6, stb6, ack6, we6, sel6, adr6, dati6, dato6,
cyc7, stb7, ack7, we7, sel7, adr7, dati7, dato7, sr7, cr7, rb7,
ddr2_dq, ddr2_dqs_n, ddr2_dqs_p,
ddr2_addr, ddr2_ba, ddr2_ras_n, ddr2_cas_n, ddr2_we_n,
ddr2_ck_p, ddr2_ck_n, ddr2_cke, ddr2_cs_n, ddr2_dm, ddr2_odt
);
parameter TMR = 1'b0;
parameter ECC = 1'b0;
parameter TRUE = 1'b1;
parameter FALSE = 1'b0;
parameter CMD_READ = 3'b001;
parameter CMD_WRITE = 3'b000;

parameter IDLE = 4'd1;
parameter PRESET = 4'd2;
parameter SEND_DATA = 4'd3;
parameter SET_CMD_RD = 4'd4;
parameter SET_CMD_WR = 4'd5;
parameter WAIT_NACK = 4'd6;
parameter WAIT_RD = 4'd7;
parameter MAJOR_RD = 4'd8;
parameter WAIT_REFACK = 4'd0;

input rst_i;
input clk200MHz;
input [11:0] fpga_temp;
output mem_ui_clk;

// Channel 0 is reserved for bitmapped graphics display, which is read-only
//
input cyc0;
input stb0;
output ack0;
input we0;
input [31:0] adr0;
input [127:0] dati0;
output reg [127:0] dato0;
reg [127:0] dato0n;

// Channel 1 is reserved for cpu1
input cyc1;
input stb1;
output ack1;
input we1;
input [7:0] sel1;
input [31:0] adr1;
input [63:0] dati1;
output reg [63:0] dato1;
input sr1;
input cr1;
output reg rb1;

// Channel 2 is reserved for the ethernet controller
input cyc2;
input stb2;
output ack2;
input we2;
input [3:0] sel2;
input [31:0] adr2;
input [31:0] dati2;
output reg [31:0] dato2;

// Channel 3 is reserved for the graphics controller
input cyc3;
input stb3;
output ack3;
input we3;
input [15:0] sel3;
input [31:0] adr3;
input [127:0] dati3;
output reg [127:0] dato3;

// Channel 4 is reserved for the graphics controller
input cyc4;
input stb4;
output ack4;
input we4;
input [31:0] adr4;
input [127:0] dati4;
output reg [127:0] dato4;

// Channel 5 is reserved for sprite DMA, which is read-only
input cyc5;
input stb5;
output ack5;
input [31:0] adr5;
output reg [31:0] dato5;

// Channel 6 is reserved for the SD/MMC controller
input cyc6;
input stb6;
output ack6;
input we6;
input [3:0] sel6;
input [31:0] adr6;
input [31:0] dati6;
output reg [31:0] dato6;

// Channel 7 is reserved for the cpu
input cyc7;
input stb7;
output ack7;
input we7;
input [3:0] sel7;
input [31:0] adr7;
input [31:0] dati7;
output [31:0] dato7;
input sr7;
input cr7;
output reg rb7;

inout [15:0] ddr2_dq;
inout [1:0] ddr2_dqs_p;
inout [1:0] ddr2_dqs_n;
output [12:0] ddr2_addr;
output [2:0] ddr2_ba;
output ddr2_ras_n;
output ddr2_cas_n;
output ddr2_we_n;
output ddr2_ck_p;
output ddr2_ck_n;
output ddr2_cke;
output ddr2_cs_n;
output [1:0] ddr2_dm;
output ddr2_odt;

reg [7:0] sel;
reg [31:0] adr;
reg [63:0] dato;
reg [63:0] dati;
reg [127:0] dat128;
reg [15:0] wmask;

reg [3:0] state;
reg [2:0] ch;
reg do_wr;
reg [1:0] sreg;
reg rstn;
reg fast_read0, fast_read1, fast_read2, fast_read3;
reg fast_read4, fast_read5, fast_read6, fast_read7;
reg read0,read1,read2,read3;
reg read4,read5,read6,read7;

wire cs0 = cyc0 && stb0 && adr0[31:28]==4'h1;
wire cs1 = cyc1 && stb1 && adr1[31:28]==4'h1;
wire cs2 = cyc2 && stb2 && adr2[31:28]==4'h1;
wire cs3 = cyc3 && stb3 && adr3[31:28]==4'h1;
wire cs4 = cyc4 && stb4 && adr4[31:28]==4'h1;
wire cs5 = cyc5 && stb5 && adr5[31:28]==4'h1;
wire cs6 = cyc6 && stb6 && adr6[31:28]==4'h1;
wire cs7 = cyc7 && stb7 && (adr7[31:28]==4'h0 || adr7[31:27]==5'h1E)
    // and not the scratchpad ram
    && adr7[31:14]!=18'h0
    ;

reg acki0,acki1,acki2,acki3,acki4,acki5,acki6,acki7;

// Record of the last read address for each channel.
// Cache address tag
reg [31:0] ch0_addr;
reg [31:0] ch1_addr;
reg [31:0] ch2_addr;
reg [31:0] ch3_addr;
reg [31:0] ch4_addr;
reg [31:0] ch5_addr;
reg [31:0] ch6_addr;
reg [31:0] ch7_addr;

// Read data caches
reg [127:0] ch0_rd_data;
reg [127:0] ch1_rd_data;
reg [127:0] ch2_rd_data;
reg [127:0] ch3_rd_data;
reg [127:0] ch4_rd_data;
reg [127:0] ch5_rd_data;
reg [127:0] ch6_rd_data;
reg [127:0] ch7_rd_dataA;
reg [127:0] ch7_rd_dataB;
reg [127:0] ch7_rd_dataC;
reg [127:0] ch7_rd_data;

reg [1:0] bank;
reg [26:0] mem_addr;
wire [2:0] mem_cmd;
wire mem_en;
reg [127:0] mem_wdf_data;
reg [15:0] mem_wdf_mask;
wire mem_wdf_end;
wire mem_wdf_wren;

wire [127:0] mem_rd_data;
wire mem_rd_data_end;
wire mem_rd_data_valid;
wire mem_rdy;
wire mem_wdf_rdy;
wire mem_ui_clk;
wire mem_ui_rst;
wire calib_complete;
reg [15:0] refcnt;
reg refreq;
wire refack;

wire cpu1=cs1;
wire cpu7=cs7;

reg [3:0] resv_ch0,resv_ch1;
reg [31:0] resv_adr0,resv_adr1;

reg [7:0] match;
always @(posedge mem_ui_clk)
if (rst_i)
	match <= 8'h00;
else
	match <= match + 8'd1;

reg cs1xx;
reg we1xx;
reg [7:0] sel1xx;
reg [31:0] adr1xx;
reg [63:0] dati1xx;
reg sr1xx;
reg cr1xx;

reg cs7xx;
reg we7xx;
reg [3:0] sel7xx;
reg [31:0] adr7xx;
reg [31:0] dati7xx;
reg sr7xx;
reg cr7xx;

wire [4:0] chkbitso0;
wire [4:0] chkbitso1;
wire [4:0] chkbitso2;
wire [4:0] chkbitso3;
wire [4:0] chkbitsi0;
wire [4:0] chkbitsi1;
wire [4:0] chkbitsi2;
wire [4:0] chkbitsi3;
wire [31:0] ecc_data_out;
reg [63:0] mem_rd_data1;

generate
begin : ECCx
if (ECC) begin
/*
ecce_byte ecce0 (
  .ecc_data_in(dati7xx[7:0]),          // input wire [7 : 0] ecc_data_in
  .ecc_data_out(),        // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_out(chkbitso0)  // output wire [4 : 0] ecc_chkbits_out
);
ecce_byte ecce1 (
  .ecc_data_in(dati7xx[15:8]),          // input wire [7 : 0] ecc_data_in
  .ecc_data_out(),        // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_out(chkbitso1)  // output wire [4 : 0] ecc_chkbits_out
);
ecce_byte ecce2 (
  .ecc_data_in(dati7xx[23:16]),          // input wire [7 : 0] ecc_data_in
  .ecc_data_out(),        // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_out(chkbitso2)  // output wire [4 : 0] ecc_chkbits_out
);
ecce_byte ecce3 (
  .ecc_data_in(dati7xx[31:24]),          // input wire [7 : 0] ecc_data_in
  .ecc_data_out(),        // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_out(chkbitso3)  // output wire [4 : 0] ecc_chkbits_out
);

eccd_byte eccd0 (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(mem_rd_data1[7:0]),        // input wire [7 : 0] ecc_data_in
  .ecc_data_out(ecc_data_out[7:0]),      // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_in(mem_rd_data1[12:8]),  // input wire [4 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
eccd_byte eccd1 (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(mem_rd_data1[23:16]),        // input wire [7 : 0] ecc_data_in
  .ecc_data_out(ecc_data_out[15:8]),      // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_in(mem_rd_data1[28:24]),  // input wire [4 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
eccd_byte eccd2 (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(mem_rd_data1[39:32]),        // input wire [7 : 0] ecc_data_in
  .ecc_data_out(ecc_data_out[23:16]),      // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_in(mem_rd_data1[44:40]),  // input wire [4 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
eccd_byte eccd3 (
  .ecc_correct_n(1'b0),    // input wire ecc_correct_n
  .ecc_data_in(mem_rd_data1[55:48]),        // input wire [7 : 0] ecc_data_in
  .ecc_data_out(ecc_data_out[31:24]),      // output wire [7 : 0] ecc_data_out
  .ecc_chkbits_in(mem_rd_data1[60:56]),  // input wire [4 : 0] ecc_chkbits_in
  .ecc_sbit_err(),      // output wire ecc_sbit_err
  .ecc_dbit_err()      // output wire ecc_dbit_err
);
*/
end
end
endgenerate

// Terminate the ack signal as soon as the circuit select goes away.
assign ack0 = acki0 & cs0;
assign ack1 = acki1 & cs1;
assign ack2 = acki2 & cs2;
assign ack3 = acki3 & cs3;
assign ack4 = acki4 & cs4;
assign ack5 = acki5 & cs5;
assign ack6 = acki6 & cs6;
assign ack7 = acki7 & cs7;

reg [31:0] dato7x;
assign dato7 = cs7 ? dato7x : 32'd0;

// Register signals onto mem_ui_clk domain
// The following channels don't need to be registered as they are operating
// under the mem_ui_clk domain already.
// Channel 0 (bmp controller) 
// Channel 5 (sprite controller)
always @(posedge mem_ui_clk)
begin
	cs1xx <= cs1;
	we1xx <= we1;
	sel1xx <= sel1;
	adr1xx <= adr1;
	dati1xx <= dati1;
	sr1xx <= sr1;
	cr1xx <= cr1;

	cs7xx <= cs7;
    we7xx <= we7;
    sel7xx <= sel7;
    adr7xx <= adr7;
    dati7xx <= dati7;
    sr7xx <= sr7;
    cr7xx <= cr7;
end

//------------------------------------------------------------------------
// Component Declarations
//------------------------------------------------------------------------

ddr2  # (

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   .BANK_WIDTH                    (3),
                                     // # of memory Bank Address bits.
   .CK_WIDTH                      (1),
                                     // # of CK/CK# outputs to memory.
   .COL_WIDTH                     (10),
                                     // # of memory Column Address bits.
   .CS_WIDTH                      (1),
                                     // # of unique CS outputs to memory.
   .nCS_PER_RANK                  (1),
                                     // # of unique CS outputs per rank for phy
   .CKE_WIDTH                     (1),
                                     // # of CKE outputs to memory.
   .DATA_BUF_ADDR_WIDTH           (5),
   .DQ_CNT_WIDTH                  (4),
                                     // = ceil(log2(DQ_WIDTH))
   .DQ_PER_DM                     (8),
   .DM_WIDTH                      (2),
                                     // # of DM (data mask)
   .DQ_WIDTH                      (16),
                                     // # of DQ (data)
   .DQS_WIDTH                     (2),
   .DQS_CNT_WIDTH                 (1),
                                     // = ceil(log2(DQS_WIDTH))
   .DRAM_WIDTH                    (8),
                                     // # of DQ per DQS
   .ECC                           ("OFF"),
   .DATA_WIDTH                    (16),
   .ECC_TEST                      ("OFF"),
   .PAYLOAD_WIDTH                 (16),
   .ECC_WIDTH                     (8),
   .MC_ERR_ADDR_WIDTH             (31),
   .nBANK_MACHS                   (4),
   .RANKS                         (1),
                                     // # of Ranks.
   .ODT_WIDTH                     (1),
                                     // # of ODT outputs to memory.
   .ROW_WIDTH                     (13),
                                     // # of memory Row Address bits.
   .ADDR_WIDTH                    (27),
                                     // # = RANK_WIDTH + BANK_WIDTH
                                     //     + ROW_WIDTH + COL_WIDTH;
                                     // Chip Select is always tied to low for
                                     // single rank devices
   .USE_CS_PORT                   (1),
                                     // # = 1, When Chip Select (CS#) output is enabled
                                     //   = 0, When Chip Select (CS#) output is disabled
                                     // If CS_N disabled, user must connect
                                     // DRAM CS_N input(s) to ground
   .USE_DM_PORT                   (1),
                                     // # = 1, When Data Mask option is enabled
                                     //   = 0, When Data Mask option is disbaled
                                     // When Data Mask option is disabled in
                                     // MIG Controller Options page, the logic
                                     // related to Data Mask should not get
                                     // synthesized
   .USE_ODT_PORT                  (1),
                                     // # = 1, When ODT output is enabled
                                     //   = 0, When ODT output is disabled
   .PHY_CONTROL_MASTER_BANK       (0),
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   .AL                            ("0"),
                                     // DDR3 SDRAM:
                                     // Additive Latency (Mode Register 1).
                                     // # = "0", "CL-1", "CL-2".
                                     // DDR2 SDRAM:
                                     // Additive Latency (Extended Mode Register).
   .nAL                           (0),
                                     // # Additive Latency in number of clock
                                     // cycles.
   .BURST_MODE                    ("8"),
                                     // DDR3 SDRAM:
                                     // Burst Length (Mode Register 0).
                                     // # = "8", "4", "OTF".
                                     // DDR2 SDRAM:
                                     // Burst Length (Mode Register).
                                     // # = "8", "4".
   .BURST_TYPE                    ("SEQ"),
                                     // DDR3 SDRAM: Burst Type (Mode Register 0).
                                     // DDR2 SDRAM: Burst Type (Mode Register).
                                     // # = "SEQ" - (Sequential),
                                     //   = "INT" - (Interleaved).
   .CL                            (5),
                                     // in number of clock cycles
                                     // DDR3 SDRAM: CAS Latency (Mode Register 0).
                                     // DDR2 SDRAM: CAS Latency (Mode Register).
   .OUTPUT_DRV                    ("HIGH"),
                                     // Output Drive Strength (Extended Mode Register).
                                     // # = "HIGH" - FULL,
                                     //   = "LOW" - REDUCED.
   .RTT_NOM                       (1),
                                     // RTT (Nominal) (Extended Mode Register).
                                     //   = "150" - 150 Ohms,
                                     //   = "75" - 75 Ohms,
                                     //   = "50" - 50 Ohms.
   .ADDR_CMD_MODE                 ("1T" ),
                                     // # = "1T", "2T".
   .REG_CTRL                      ("OFF"),
                                     // # = "ON" - RDIMMs,
                                     //   = "OFF" - Components, SODIMMs, UDIMMs.
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   .CLKIN_PERIOD                  (4999),
                                     // Input Clock Period
   .CLKFBOUT_MULT                 (6),
                                     // write PLL VCO multiplier
   .DIVCLK_DIVIDE                 (1),
                                     // write PLL VCO divisor
   .CLKOUT0_DIVIDE                (2),
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   .CLKOUT1_DIVIDE                (4),
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   .CLKOUT2_DIVIDE                (64),
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   .CLKOUT3_DIVIDE                (16),
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Memory Timing Parameters. These parameters varies based on the selected
   // memory part.
   //***************************************************************************
   .tCKE                          (7500),
                                     // memory tCKE paramter in pS.
   .tFAW                          (45000),
                                     // memory tRAW paramter in pS.
   .tPRDI                         (1_000_000),
                                     // memory tPRDI paramter in pS.
   .tRAS                          (40000),
                                     // memory tRAS paramter in pS.
   .tRCD                          (15000),
                                     // memory tRCD paramter in pS.
   .tREFI                         (7800000),
                                     // memory tREFI paramter in pS.
   .tRFC                          (127500),
                                     // memory tRFC paramter in pS.
   .tRP                           (12500),
                                     // memory tRP paramter in pS.
   .tRRD                          (10000),
                                     // memory tRRD paramter in pS.
   .tRTP                          (7500),
                                     // memory tRTP paramter in pS.
   .tWTR                          (7500),
                                     // memory tWTR paramter in pS.
   .tZQI                          (128_000_000),
                                     // memory tZQI paramter in nS.
   .tZQCS                         (64),
                                     // memory tZQCS paramter in clock cycles.

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   .SIM_BYPASS_INIT_CAL           ("OFF"),
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Not supported
                                     // # = "FAST" - Complete memory init & use
                                     //              abbreviated calib sequence
   .SIMULATION                    ("FALSE"),
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   .BYTE_LANES_B0                 (4'b1111),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B1                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B2                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B3                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .BYTE_LANES_B4                 (4'b0000),
                                     // Byte lanes used in an IO column.
   .DATA_CTL_B0                   (4'b0101),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B1                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B2                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B3                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   .DATA_CTL_B4                   (4'b0000),
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane

   .PHY_0_BITLANES                (48'hFFC3F7FFF3FE),
   .PHY_1_BITLANES                (48'h000000000000),
   .PHY_2_BITLANES                (48'h000000000000),
   .CK_BYTE_MAP                   (144'h000000000000000000000000000000000003),
   .ADDR_MAP                      (192'h00000000001003301A01903203A034018036012011017015),
   .BANK_MAP                      (36'h01301601B),
   .CAS_MAP                       (12'h039),
   .CKE_ODT_BYTE_MAP              (8'h00),
   .CKE_MAP                       (96'h000000000000000000000038),
   .ODT_MAP                       (96'h000000000000000000000035),
   .CS_MAP                        (120'h000000000000000000000000000037),
   .PARITY_MAP                    (12'h000),
   .RAS_MAP                       (12'h014),
   .WE_MAP                        (12'h03B),
   .DQS_BYTE_MAP                  (144'h000000000000000000000000000000000200),
   .DATA0_MAP                     (96'h008004009007005001006003),
   .DATA1_MAP                     (96'h022028020024027025026021),
   .DATA2_MAP                     (96'h000000000000000000000000),
   .DATA3_MAP                     (96'h000000000000000000000000),
   .DATA4_MAP                     (96'h000000000000000000000000),
   .DATA5_MAP                     (96'h000000000000000000000000),
   .DATA6_MAP                     (96'h000000000000000000000000),
   .DATA7_MAP                     (96'h000000000000000000000000),
   .DATA8_MAP                     (96'h000000000000000000000000),
   .DATA9_MAP                     (96'h000000000000000000000000),
   .DATA10_MAP                    (96'h000000000000000000000000),
   .DATA11_MAP                    (96'h000000000000000000000000),
   .DATA12_MAP                    (96'h000000000000000000000000),
   .DATA13_MAP                    (96'h000000000000000000000000),
   .DATA14_MAP                    (96'h000000000000000000000000),
   .DATA15_MAP                    (96'h000000000000000000000000),
   .DATA16_MAP                    (96'h000000000000000000000000),
   .DATA17_MAP                    (96'h000000000000000000000000),
   .MASK0_MAP                     (108'h000000000000000000000029002),
   .MASK1_MAP                     (108'h000000000000000000000000000),

   .SLOT_0_CONFIG                 (8'b00000001),
                                     // Mapping of Ranks.
   .SLOT_1_CONFIG                 (8'b0000_0000),
                                     // Mapping of Ranks.
   .MEM_ADDR_ORDER                ("BANK_ROW_COLUMN"),
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   .IODELAY_HP_MODE               ("ON"),
                                     // to phy_top
   .IBUF_LPWR_MODE                ("OFF"),
                                     // to phy_top
   .DATA_IO_IDLE_PWRDWN           ("ON"),
                                     // # = "ON", "OFF"
   .DATA_IO_PRIM_TYPE             ("HR_LP"),
                                     // # = "HP_LP", "HR_LP", "DEFAULT"
   .CKE_ODT_AUX                   ("FALSE"),
   .USER_REFRESH                  ("OFF"),
   .WRLVL                         ("OFF"),
                                     // # = "ON" - DDR3 SDRAM
                                     //   = "OFF" - DDR2 SDRAM.
   .ORDERING                      ("STRICT"),
                                     // # = "NORM", "STRICT", "RELAXED".
   .CALIB_ROW_ADD                 (16'h0000),
                                     // Calibration row address will be used for
                                     // calibration read and write operations
   .CALIB_COL_ADD                 (12'h000),
                                     // Calibration column address will be used for
                                     // calibration read and write operations
   .CALIB_BA_ADD                  (3'h0),
                                     // Calibration bank address will be used for
                                     // calibration read and write operations
   .TCQ                           (100),
   .IODELAY_GRP                   ("IODELAY_MIG"),
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
   .SYSCLK_TYPE                   ("NO_BUFFER"),
                                     // System clock type DIFFERENTIAL or SINGLE_ENDED
   .REFCLK_TYPE                   ("USE_SYSTEM_CLOCK"),
                                     // Reference clock type DIFFERENTIAL or SINGLE_ENDED
   .CMD_PIPE_PLUS1                ("ON"),
                                     // add pipeline stage between MC and PHY
   .DRAM_TYPE                       ("DDR2"),
   .CAL_WIDTH                     ("HALF"),
   .STARVE_LIMIT                  (2),
                                     // # = 2,3,4.
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   .REFCLK_FREQ                   (200.0),
                                     // IODELAYCTRL reference clock frequency
   .DIFF_TERM_REFCLK              ("TRUE"),
                                     // Differential Termination for idelay
                                     // reference clock input pins
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   .tCK                           (3333),
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   .nCK_PER_CLK                   (4),
                                     // # of memory CKs per fabric CLK
   .DIFF_TERM_SYSCLK              ("TRUE"),
                                     // Differential Termination for System
                                     // clock input pins

   
   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   .DEBUG_PORT                      ("OFF"),
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   .RST_ACT_LOW                   (1)
                                     // =1 for active low reset,
                                     // =0 for active high.
   )
u_ddr
(
   // Inouts
   .ddr2_dq(ddr2_dq),
   .ddr2_dqs_p(ddr2_dqs_p),
   .ddr2_dqs_n(ddr2_dqs_n),
   // Outputs
   .ddr2_addr(ddr2_addr),
   .ddr2_ba(ddr2_ba),
   .ddr2_ras_n(ddr2_ras_n),
   .ddr2_cas_n(ddr2_cas_n),
   .ddr2_we_n(ddr2_we_n),
   .ddr2_ck_p(ddr2_ck_p),
   .ddr2_ck_n(ddr2_ck_n),
   .ddr2_cke(ddr2_cke),
   .ddr2_cs_n(ddr2_cs_n),
   .ddr2_dm(ddr2_dm),
   .ddr2_odt(ddr2_odt),
   // Inputs
   .sys_clk_i(clk200MHz),
//   .clk_ref_i(clk200MHz),
   .sys_rst(rstn),
   // user interface signals
   .app_addr(mem_addr),
   .app_cmd(mem_cmd),
   .app_en(mem_en),
   .app_wdf_data(mem_wdf_data),
   .app_wdf_end(mem_wdf_end),
   .app_wdf_mask(mem_wdf_mask),
   .app_wdf_wren(mem_wdf_wren),
   .app_rd_data(mem_rd_data),
   .app_rd_data_end(mem_rd_data_end),
   .app_rd_data_valid(mem_rd_data_valid),
   .app_rdy(mem_rdy),
   .app_wdf_rdy(mem_wdf_rdy),
   .app_sr_req(1'b0),
   .app_sr_active(),
   .app_ref_req(1'b0),
   .app_ref_ack(),
   .app_zq_req(1'b0),
   .app_zq_ack(),
   .ui_clk(mem_ui_clk),
   .ui_clk_sync_rst(mem_ui_rst),
   .device_temp_i(fpga_temp),
   .init_calib_complete(calib_complete)
);


always @(posedge clk200MHz)
begin
	sreg <= {sreg[0],rst_i};
	rstn <= ~sreg[1];
end

reg toggle;	// CPU1 / CPU0 priority toggle
reg toggle_sr;
reg [19:0] resv_to_cnt;
reg sr1x,sr7x;
reg [127:0] dati128;

always @(posedge mem_ui_clk)
if (mem_ui_rst) begin
	state <= IDLE;
	ch0_addr <= 32'hFFFFFFFF;
	ch1_addr <= 32'hFFFFFFFF;
	ch2_addr <= 32'hFFFFFFFF;
	ch3_addr <= 32'hFFFFFFFF;
	ch4_addr <= 32'hFFFFFFFF;
	ch5_addr <= 32'hFFFFFFFF;
	ch6_addr <= 32'hFFFFFFFF;
	ch7_addr <= 32'hFFFFFFFF;
	read0 <= FALSE;
	read1 <= FALSE;
	read2 <= FALSE;
	read3 <= FALSE;
	read4 <= FALSE;
	read5 <= FALSE;
	read6 <= FALSE;
	read7 <= FALSE;
	acki0 <= FALSE;
	acki1 <= FALSE;
	acki2 <= FALSE;
	acki3 <= FALSE;
	acki4 <= FALSE;
	acki5 <= FALSE;
	acki6 <= FALSE;
	acki7 <= FALSE;
	resv_to_cnt <= 20'd0;
	refcnt <= 16'd278;
	refreq <= FALSE;
	rb1 <= FALSE;
	rb7 <= FALSE;
	toggle <= FALSE;
	toggle_sr <= FALSE;
	resv_ch0 <= 4'hF;
	resv_ch1 <= 4'hF;
	bank <= 2'd0;
end
else begin
	fast_read0 = FALSE;
	fast_read1 = FALSE;
	fast_read2 = FALSE;
	fast_read3 = FALSE;
	fast_read4 = FALSE;
	fast_read5 = FALSE;
	fast_read6 = FALSE;
	fast_read7 = FALSE;
	resv_to_cnt <= resv_to_cnt + 20'd1;
	refcnt <= refcnt + 16'd1;
	refreq <= FALSE;
	sr1x = FALSE;
	sr7x = FALSE;

	// Fast read channels
	// All these read channels allow data to be read in parallel with another
	// access.
	// Read the data from the channel read buffer rather than issuing a memory
	// request.
	if (cs0 && adr0[31:4]==ch0_addr[31:4]) begin
		dato0 <= ch0_rd_data;
		acki0 <= TRUE;
		read0 <= TRUE;
		fast_read0 = TRUE;
	end
	if (!we1xx && cs1xx && adr1xx[31:4]==ch1_addr[31:4]) begin
		case(adr1xx[3])
		1'd0:	dato1 <= ch1_rd_data[63:0];
		1'd1:	dato1 <= ch1_rd_data[127:64];
		endcase
		acki1 <= TRUE;
		read1 <= TRUE;
		fast_read1 = TRUE;
		sr1x = sr1xx;
	end
	else
		dato1 <= 64'd0;
	if (!we2 && cs2 && adr2[31:4]==ch2_addr[31:4]) begin
		case(adr2[3:2])
		2'd0:	dato2 <= ch2_rd_data[31:0];
		2'd1:	dato2 <= ch2_rd_data[63:32];
		2'd2:	dato2 <= ch2_rd_data[95:64];
		2'd3:	dato2 <= ch2_rd_data[127:96];
		endcase
		acki2 <= TRUE;
		read2 <= TRUE;
		fast_read2 = TRUE;
	end
	if (!we3 && cs3 && adr3[31:4]==ch3_addr[31:4]) begin
		dato3 <= ch3_rd_data;
		acki3 <= TRUE;
		read3 <= TRUE;
		fast_read3 = TRUE;
	end
	if (!we4 && cs4 && adr4[31:4]==ch4_addr[31:4]) begin
		dato4 <= ch4_rd_data;
		acki4 <= TRUE;
		read4 <= TRUE;
		fast_read4 = TRUE;
	end
	if (cs5 && adr5[31:4]==ch5_addr[31:4]) begin
		case(adr5[3:2])
		2'd0:	dato5 <= ch5_rd_data[31:0];
		2'd1:	dato5 <= ch5_rd_data[63:32];
		2'd2:	dato5 <= ch5_rd_data[95:64];
		2'd3:	dato5 <= ch5_rd_data[127:96];
		endcase
		acki5 <= TRUE;
		read5 <= TRUE;
		fast_read5 = TRUE;
	end
	if (!we6 && cs6 && adr6[31:4]==ch6_addr[31:4]) begin
		case(adr6[3:2])
		2'd0:	dato6 <= ch6_rd_data[31:0];
		2'd1:	dato6 <= ch6_rd_data[63:32];
		2'd2:	dato6 <= ch6_rd_data[95:64];
		2'd3:	dato6 <= ch6_rd_data[127:96];
		endcase
		acki6 <= TRUE;
		read6 <= TRUE;
		fast_read6 = TRUE;
	end
	// The output bus for the cpu is shared and must be zero when
	// not accessed.
	else
		dato6 <= 32'd0;

  if (!we7xx && cs7xx && (ECC ? adr7xx[31:2]==ch7_addr[31:2] : adr7xx[31:4]==ch7_addr[31:4])) begin
    if (ECC)
       dato7x <= ch7_rd_data[31:0];
    else
       dato7x <= ch7_rd_data >> {adr7xx[3:2],5'd0};
    acki7 <= TRUE;
    read7 <= TRUE;
		fast_read7 = TRUE;
		sr7x = sr7xx;
	end

	if (sr1x & sr7x) begin
		if (toggle_sr) begin
			reserve_adr(4'h1,adr1xx);
			toggle_sr <= 1'b0;
		end
		else begin
			reserve_adr(4'h7,adr7xx);
			toggle_sr <= 1'b1;
		end
	end
	else begin
		if (sr1x)
			reserve_adr(4'h1,adr1xx);
		if (sr7x)
			reserve_adr(4'h7,adr7xx);
	end

	// Clear fast read ack's when deselected
	if (read0 & ~cs0) begin
		read0 <= FALSE;
		acki0 <= FALSE;
	end
	if (read1 & ~cs1xx) begin
		read1 <= FALSE;
		acki1 <= FALSE;
	end
	if (read2 & ~cs2) begin
		read2 <= FALSE;
		acki2 <= FALSE;
	end
	if (read3 & ~cs3) begin
		read3 <= FALSE;
		acki3 <= FALSE;
	end
	if (read4 & ~cs4) begin
		read4 <= FALSE;
		acki4 <= FALSE;
	end
	if (read5 & ~cs5) begin
		read5 <= FALSE;
		acki5 <= FALSE;
	end
	if (read6 & ~cs6) begin
		read6 <= FALSE;
		acki6 <= FALSE;
	end
	if (read7 & ~cs7) begin
    read7 <= FALSE;
    acki7 <= FALSE;
  end

	if (!cs0) acki0 <= FALSE;
	if (!cs1xx) acki1 <= FALSE;
	if (!cs2) acki2 <= FALSE;
	if (!cs3) acki3 <= FALSE;
	if (!cs4) acki4 <= FALSE;
	if (!cs5) acki5 <= FALSE;
	if (!cs6) acki6 <= FALSE;
	if (!cs7xx | !cs7) acki7 <= FALSE;

case(state)
IDLE:
  // According to the docs there's no need to wait for calib complete.
	if (calib_complete || 1'b1) begin
		// Refresh must be about 8us. 292 clocks at 40MHz
/*
		if (refcnt>=16'd280) begin
			refcnt <= 16'd0;
			refreq <= TRUE;
			state <= WAIT_REFACK;
		end
		else
*/
		begin
		do_wr <= FALSE;
		// Write cycles take priority over read cycles.
		// Reads
		if (cs0 & we0) begin
			clear_cache(adr0);
			ch <= 3'd0;
			adr <= adr0;
			dati128 <= dati0;
			acki0 <= TRUE;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs0 & ~fast_read0) begin
			ch <= 3'd0;
			adr <= adr0;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (cs1xx & we1xx & (cs7xx ? toggle : 1'b1)) begin
		    toggle <= 1'b0;
			ch <= 3'd1;
			sel <= sel1xx;
			adr <= adr1xx;
			dati <= dati1xx;
			acki1 <= TRUE;
			if (cr1) begin
				rb1 <= FALSE;
				state <= IDLE;
				if ((resv_ch0==4'd1) && (resv_adr0[31:4]==adr1xx[31:4])) begin
					resv_ch0 <= 4'hF;
					do_wr <= TRUE;
					state <= PRESET;
					rb1 <= TRUE;
					clear_cache(adr1xx);
				end
				if ((resv_ch1==4'd1) && (resv_adr1[31:4]==adr1xx[31:4])) begin
					resv_ch1 <= 4'hF;
					do_wr <= TRUE;
					state <= PRESET;
					rb1 <= TRUE;
					clear_cache(adr1xx);
				end
			end
			else begin
				// If the write address overlaps with cached read data,
				// invalidate the corresponding read cache.
				clear_cache(adr1xx);
				do_wr <= TRUE;
				state <= PRESET;
			end
		end
		else if (cs2 & we2) begin
			clear_cache(adr2);
			ch <= 3'd2;
			sel <= sel2;
			adr <= adr2;
			dati <= dati2;
			acki2 <= TRUE;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs3 & we3) begin
			clear_cache(adr3);
			ch <= 3'd3;
			adr <= adr3;
			dati128 <= dati3;
			acki3 <= TRUE;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs4 & we4) begin
			clear_cache(adr4);
			ch <= 3'd4;
			adr <= adr4;
			dati128 <= dati4;
			acki4 <= TRUE;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs6 & we6) begin
			clear_cache(adr6);
			ch <= 3'd6;
			sel <= sel6;
			adr <= adr6;
			dati <= dati6;
			acki6 <= TRUE;
			do_wr <= TRUE;
			state <= PRESET;
		end
		else if (cs7xx & we7xx) begin
			toggle <= 1'b1;
			ch <= 3'd7;
			adr <= adr7xx;
			if (ECC) begin
                dat128 <= {2{3'b0,chkbitso3,dati7xx[31:24],
                             3'b0,chkbitso2,dati7xx[23:16],
                             3'b0,chkbitso1,dati7xx[15:8],
                             3'b0,chkbitso0,dati7xx[7:0]}};
                wmask <= ~({sel7xx[3],sel7xx[3],sel7xx[2],sel7xx[2],sel7xx[1],sel7xx[1],sel7xx[0],sel7xx[0]} << {adr7xx[2],3'b000});
			end
			else begin
                dat128 <= {4{dati7xx}}; 
                wmask <= ~(sel7xx << {adr7xx[3:2],2'b00});
			end
			acki7 <= TRUE;
			if (cr7xx) begin
				rb7 <= FALSE;
				state <= IDLE;
				if ((resv_ch0==4'd7) && (resv_adr0[31:4]==adr7xx[31:4])) begin
					resv_ch0 <= 4'hF;
					do_wr <= TRUE;
					state <= PRESET;
					rb7 <= TRUE;
					clear_cache(adr7xx);
				end
				if ((resv_ch1==4'd7) && (resv_adr1[31:4]==adr7xx[31:4])) begin
					resv_ch1 <= 4'hF;
					do_wr <= TRUE;
					state <= PRESET;
					rb7 <= TRUE;
					clear_cache(adr7xx);
				end
			end
			else begin
				do_wr <= TRUE;
				state <= PRESET;
				clear_cache(adr7xx);
			end
		end
		else if (!we1xx & cs1xx & ~fast_read1 & (cs7xx ? toggle : 1'b1)) begin
			toggle <= 1'b0;
			ch <= 3'd1;
			adr <= adr1xx;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we2 & cs2 & ~fast_read2) begin
			ch <= 3'd2;
			adr <= adr2;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we3 & cs3 & ~fast_read3) begin
			ch <= 3'd3;
			adr <= adr3;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we4 & cs4 & ~fast_read4) begin
			ch <= 3'd4;
			adr <= adr4;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (cs5 & ~fast_read5) begin
			ch <= 3'd5;
			adr <= adr5;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we6 & cs6 & ~fast_read6) begin
			ch <= 3'd6;
			adr <= adr6;
			sel <= 8'hFF;
			state <= PRESET;
		end
		else if (!we7xx & cs7xx & ~fast_read7) begin
			toggle <= 1'b1;
			ch <= 3'd7;
			adr <= adr7xx;
			wmask <= 16'hFFFF;
			dat128 <= {16{8'hff}};
			state <= PRESET;
		end
		end
	end
	else begin
		refcnt <= 16'd278;
	end
PRESET:
	begin
	    if (TMR)
		    mem_addr <= {bank,adr[24:4],4'h0};		// common for all channels
		else if (ECC)
		    mem_addr <= {adr[25:3],4'h0};
    	else
		    mem_addr <= {adr[26:4],4'h0};		// common for all channels
		case(ch)
		3'd0:	begin
				mem_wdf_mask <= 16'h0000;
				mem_wdf_data <= dati0;
				end
		3'd4,3'd5:
				begin
				mem_wdf_mask <= 16'hFFFF;	// ch0,5 are read-only
				mem_wdf_data <= {128{1'b1}};
				end
		3'd3:
				begin
				mem_wdf_mask <= ~sel3;
				mem_wdf_data <= dati3;
				end
		3'd2,3'd6:
				begin
				case(adr[3:2])
				2'd0:	mem_wdf_mask <= {12'hFFF,~sel[3:0]};
				2'd1:	mem_wdf_mask <= {8'hFF,~sel[3:0],4'hF};
				2'd2:	mem_wdf_mask <= {4'hF,~sel[3:0],8'hFF};
				2'd3:	mem_wdf_mask <= {~sel[3:0],12'hFFF};
				endcase
				mem_wdf_data <= {4{dati[31:0]}};
				end
		3'd7:
		   begin
		   mem_wdf_mask <= wmask;
			 mem_wdf_data <= dat128;
		   end
		3'd1:
				begin
				case(adr[3])
				1'd0:	mem_wdf_mask <= {8'hFF,~sel[7:0]};
				1'd1:	mem_wdf_mask <= {~sel[7:0],8'hFF};
				endcase
				mem_wdf_data <= {2{dati}};
				end
		endcase
		if (do_wr)
			state <= SEND_DATA;
		else
			state <= SET_CMD_RD;
	end
SEND_DATA:
	begin
		if (mem_wdf_rdy == TRUE) begin
			state <= SET_CMD_WR;
		end
	end
SET_CMD_RD:
	begin
	if (mem_rdy == TRUE)
		state <= WAIT_RD;
	end
SET_CMD_WR:
	begin
		if (mem_rdy == TRUE) begin
		    if (TMR)
            case(bank)
            2'd0: begin bank <= bank + 2'd1; state <= PRESET; end
            2'd1: begin bank <= bank + 2'd1; state <= PRESET; end
            default: begin bank <= 2'd0; state <= IDLE; end
            endcase
        else
            state <= IDLE;
    end
	end

WAIT_RD:
	begin
		if (mem_rd_data_valid & mem_rd_data_end) begin
			state <= IDLE;
			case(ch)
			3'd0:
				begin
				ch0_addr <= adr0;
				ch0_rd_data <= mem_rd_data;
				end
			3'd1:
				begin
				ch1_addr <= adr1;
				ch1_rd_data <= mem_rd_data;
				end
			3'd2:
				begin
				ch2_addr <= adr2;
				ch2_rd_data <= mem_rd_data;
				end
			3'd3:
				begin
				ch3_addr <= adr3;
				ch3_rd_data <= mem_rd_data;
				end
			3'd4:
				begin
				ch4_addr <= adr4;
				ch4_rd_data <= mem_rd_data;
				end
			3'd5:
				begin
				ch5_addr <= adr5;
				ch5_rd_data <= mem_rd_data;
				end
			3'd6:
				begin
				ch6_addr <= adr6;
				ch6_rd_data <= mem_rd_data;
				end
			3'd7:
				begin
          if (TMR) begin
              case(bank)
              2'd0:   begin ch7_rd_dataA <= mem_rd_data; state <= PRESET; end
              2'd1:   begin ch7_rd_dataB <= mem_rd_data; state <= PRESET; end
              2'd2:   begin ch7_rd_dataC <= mem_rd_data; state <= MAJOR_RD; end
              2'd3:   state <= MAJOR_RD;
              endcase
              bank <= bank + 2'd1;
          end
          else if (ECC) begin
              mem_rd_data1 <= adr7xx[2] ? mem_rd_data[127:64] : mem_rd_data[63:0];
              state <= MAJOR_RD;
          end
          else begin
              ch7_rd_data <= mem_rd_data;
              ch7_addr <= adr7xx;
              state <= IDLE;
          end
        end
			endcase
		end
	end
MAJOR_RD:
    begin
        if (TMR)
            ch7_rd_data <= (ch7_rd_dataA&ch7_rd_dataB)|(ch7_rd_dataA&ch7_rd_dataC)|(ch7_rd_dataB&ch7_rd_dataC);
        else    // ECC
            ch7_rd_data <= ecc_data_out;
        ch7_addr <= adr7xx;
    	bank <= 2'd0;
        state <= IDLE;
    end

WAIT_REFACK:
	if (refack) state <= IDLE;
endcase
end

assign mem_wdf_wren = state==SEND_DATA;
assign mem_wdf_end = state==SEND_DATA;
assign mem_en = state==SET_CMD_RD || state==SET_CMD_WR;
assign mem_cmd = state==SET_CMD_WR ? CMD_WRITE : CMD_READ;

// Clear the read cache where the cache address matches the given address. This is to
// prevent reading stale data from a cache.
task clear_cache;
input [31:0] adr;
begin
	if (ch0_addr[31:4]==adr[31:4])
		ch0_addr <= 32'hFFFFFFFF;
	if (ch1_addr[31:4]==adr[31:4])
		ch1_addr <= 32'hFFFFFFFF;
	if (ch2_addr[31:4]==adr[31:4])
		ch2_addr <= 32'hFFFFFFFF;
	if (ch3_addr[31:4]==adr[31:4])
		ch3_addr <= 32'hFFFFFFFF;
	if (ch4_addr[31:4]==adr[31:4])
		ch4_addr <= 32'hFFFFFFFF;
	if (ch5_addr[31:4]==adr[31:4])
		ch5_addr <= 32'hFFFFFFFF;
	if (ch6_addr[31:4]==adr[31:4])
		ch6_addr <= 32'hFFFFFFFF;
	if (ch7_addr[31:4]==adr[31:4])
		ch7_addr <= 32'hFFFFFFFF;
end
endtask

// Two reservation buckets are allowed for. There are two (or more) CPU's in the
// system and as long as they are not trying to control the same resource (the
// same semaphore) then they should be able to set a reservation. Ideally there
// could be more reservation buckets available, but it starts to be a lot of
// hardware.
task reserve_adr;
input [3:0] ch;
input [31:0] adr;
begin
	// Ignore an attempt to reserve an address that's already reserved. The LWAR
	// instruction is usually called in a loop and we don't want it to use up
	// both address reservations.
	if (!(resv_ch0==ch && resv_adr0==adr) && !(resv_ch1==ch && resv_adr1==adr)) begin
		if (resv_ch0==4'hF) begin
			resv_ch0 <= ch;
			resv_adr0 <= adr;
		end
		else if (resv_ch1==4'hF) begin
			resv_ch1 <= ch;
			resv_adr1 <= adr;
		end
		else begin
			// Here there were no free reservation buckets, so toss one of the
			// old reservations out.
			if (match[6]) begin
				resv_ch0 <= ch;
				resv_adr0 <= adr;
			end
			else begin
				resv_ch1 <= ch;
				resv_adr1 <= adr;
			end
		end
	end
end
endtask

endmodule

