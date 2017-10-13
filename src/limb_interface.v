/*
 * c4puter northbridge - LIMB(EC) to Wishbone glue
 * Copyright (C) 2017 Chris Pavlina
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

`include "timescale.v"

module limb_interface (
    // LIMB interface - toplevel should combine limb_d_in, limb_d_out, and
    // limb_d_oe into a single 'inout' bus.
    input       [7:0]   limb_d_in,
    output      [7:0]   limb_d_out,
    output              limb_d_oe,
    input               limb_clk,
    input               limb_nrd,
    input               limb_start,
    output              limb_nwait,

    // Wishbone master
    output reg  [35:0]  wb_adr_o = 0,
    output              wb_we_o,
    output      [3:0]   wb_sel_o,
    output              wb_stb_o,
    output              wb_cyc_o,
    output reg  [31:0]  wb_dat_o = 0,
    input       [31:0]  wb_dat_i,
    input               wb_ack_i,

    input               clk,
    input               reset
);

reg     [7:0]   adreg[8:0];

wire    [7:0]   next_addr0; // autoincrement over lsb
wire    [8:0]   adreg_load;

wire    [35:0]  limb_wb_adr;
wire    [31:0]  limb_wb_dat;
reg     [36:0]  wb_addr = 0;
reg     [31:0]  wb_data = 0;
reg     [31:0]  wb_data_in_latched = 0;

wire            limb_wb_ready_wr;
wire            limb_wb_ready_wr_set;
wire            async_wb_ready_wr_clr;
reg             wb_ready_wr = 0;

wire            wb_ready_rd;
wire            wb_ready_rd_clr;
wire            async_wb_ready_rd_set;

reg             autoincr = 0;
reg     [8:0]   limb_state  = STATE_ADDR0;
wire    [8:0]   limb_nextstate;
localparam      STATE_ADDR0 = 9'b000000001; // [0]
localparam      STATE_ADDR1 = 9'b000000010; // [1]
localparam      STATE_ADDR2 = 9'b000000100; // [2]
localparam      STATE_ADDR3 = 9'b000001000; // [3]
localparam      STATE_ADDR4 = 9'b000010000; // [4]
localparam      STATE_DATA0 = 9'b000100000; // [5]
localparam      STATE_DATA1 = 9'b001000000; // [6]
localparam      STATE_DATA2 = 9'b010000000; // [7]
localparam      STATE_DATA3 = 9'b100000000; // [8]

assign          limb_d_out  = limb_state[6] ? wb_data_in_latched[7:0] :
                              limb_state[7] ? wb_data_in_latched[15:8] :
                              limb_state[8] ? wb_data_in_latched[23:16] :
                                              wb_data_in_latched[31:24];
assign          limb_d_oe   = limb_nrd;
assign          limb_nwait  = !(limb_wb_ready_wr || wb_ready_rd);
assign          limb_wb_adr = {adreg[4][3:0], adreg[3], adreg[2], adreg[1], adreg[0]};
assign          limb_wb_dat = {adreg[8], adreg[7], adreg[6], adreg[5]};
assign          wb_sel_o    = 4'b1111;

// A/D load is generally a function of the state, but the address LSB can also
// be loaded on autoincrement or any time limb_start is asserted.
assign      adreg_load[0] =
                limb_state[0] ||
                limb_start ||
                (autoincr && limb_state[5]);
assign      adreg_load[8:1] = limb_state[8:1];
assign      limb_wb_ready_wr_set = limb_nrd && limb_state[8];
assign      async_wb_ready_rd_set = !limb_nrd && limb_state[5];
assign      next_addr0      = limb_start ? limb_d_in : adreg[0] + 1;

// Walk through the state machine. This is mostly forward steps, except DATA3
// returns to DATA0 (block transfer) and limb_start is equivalent to ADDR0.
assign      limb_nextstate =
                limb_start ? STATE_ADDR1 :
                limb_state[0] ? STATE_ADDR1 :
                limb_state[1] ? STATE_ADDR2 :
                limb_state[2] ? STATE_ADDR3 :
                limb_state[3] ? STATE_ADDR4 :
                limb_state[4] ? STATE_DATA0 :
                limb_state[5] ? STATE_DATA1 :
                limb_state[6] ? STATE_DATA2 :
                limb_state[7] ? STATE_DATA3 :
                limb_state[8] ? STATE_DATA0 :
                STATE_ADDR0;

// Latch states on each clock
always @(posedge limb_clk) begin
    limb_state <= limb_nextstate;

    if (limb_start)
        autoincr <= 0;
    else if (limb_state == STATE_DATA3)
        autoincr <= 1;
end

// Latch address/data
always @(posedge limb_clk)
    if (adreg_load[0]) adreg[0] <= next_addr0;

genvar i;
for (i = 1; i < 9; i = i + 1)
    always @(posedge limb_clk)
        if (adreg_load[i]) adreg[i] <= limb_d_in;

dff_async_clr #( .init(0) )
dff_wb_ready_wr (
    .q(limb_wb_ready_wr),
    .d(1'b1),
    .clk(limb_clk),
    .ce(limb_wb_ready_wr_set),
    .clr(async_wb_ready_wr_clr) );

dff_async_set #( .init(0) )
dff_wb_ready_rd (
    .q(wb_ready_rd),
    .d(1'b0),
    .clk(clk),
    .ce(wb_ready_rd_clr),
    .set(async_wb_ready_rd_set) );

localparam      WB_STATE_WAIT      = 5'b00001; // [0]
localparam      WB_STATE_START_WR  = 5'b00010; // [1]
localparam      WB_STATE_FINISH_WR = 5'b00100; // [2]
localparam      WB_STATE_START_RD  = 5'b01000; // [3]
localparam      WB_STATE_FINISH_RD = 5'b10000; // [4]
reg     [4:0]   wb_state = WB_STATE_WAIT;

assign  wb_stb_o    = wb_state[1] || wb_state[3];
assign  wb_cyc_o    = wb_state[1] || wb_state[3];
assign  wb_we_o     = wb_state[1];
assign  async_wb_ready_wr_clr = wb_state[2] || wb_state[3] || wb_state[4];
assign  wb_ready_rd_clr = wb_state[4];

always @(posedge clk) begin
    wb_ready_wr <= limb_wb_ready_wr;
    wb_adr_o <= limb_wb_adr;
    wb_dat_o <= limb_wb_dat;

    if (wb_state[4])
        wb_data_in_latched <= wb_dat_i;

    if (reset)
        wb_state <= WB_STATE_WAIT;
    else
        casez(wb_state)
            5'b00001: wb_state <= wb_ready_rd ? WB_STATE_START_RD :
                                wb_ready_wr ? WB_STATE_START_WR : WB_STATE_WAIT;

            5'b0001?: wb_state <= wb_ack_i ? WB_STATE_FINISH_WR : WB_STATE_START_WR;
            5'b001??: wb_state <= WB_STATE_WAIT;

            5'b01???: wb_state <= wb_ack_i ? WB_STATE_FINISH_RD : WB_STATE_START_RD;
            5'b1????: wb_state <= WB_STATE_WAIT;
        endcase
end

`include "sim.v"

endmodule
