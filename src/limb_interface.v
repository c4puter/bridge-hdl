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
reg     [31:0]  wb_data_in_lat = 0;

wire            limb_wb_ready_wr;
wire            limb_wb_ready_wr_set;
wire            async_wb_ready_wr_clr;
reg             wb_ready_wr = 0;
reg             wb_ready_rd = 0;

wire            async_wb_ready_rd_set;

reg             limb_cyc_is_write = 0;
reg             autoincr = 0;
reg     [8:0]   limb_state  = STATE_ADDR0;
localparam      STATE_ADDR0 = 1 << 0;
localparam      STATE_ADDR1 = 1 << 1;
localparam      STATE_ADDR2 = 1 << 2;
localparam      STATE_ADDR3 = 1 << 3;
localparam      STATE_ADDR4 = 1 << 4;
localparam      STATE_DATA0 = 1 << 5;
localparam      STATE_DATA1 = 1 << 6;
localparam      STATE_DATA2 = 1 << 7;
localparam      STATE_DATA3 = 1 << 8;

assign          limb_d_out  = limb_state == STATE_DATA1 ? wb_data_in_lat[0+:8] :
                              limb_state == STATE_DATA2 ? wb_data_in_lat[8+:8] :
                              limb_state == STATE_DATA3 ? wb_data_in_lat[16+:8] :
                                                          wb_data_in_lat[24+:8];
assign          limb_d_oe   = limb_nrd;
assign          limb_nwait  = !(limb_wb_ready_wr || limb_wb_ready_rd);
assign          limb_wb_adr = {adreg[4][3:0], adreg[3], adreg[2], adreg[1], adreg[0]};
assign          limb_wb_dat = {adreg[8], adreg[7], adreg[6], adreg[5]};
assign          wb_sel_o    = 4'b1111;

// A/D load is generally a function of the state, but the address LSB can also
// be loaded on autoincrement or any time limb_start is asserted.
assign      adreg_load[0] =
                (limb_state == STATE_ADDR0) ||
                limb_start ||
                (autoincr && limb_state == STATE_DATA0 && limb_cyc_is_write) ||
                (autoincr && limb_state == STATE_DATA3 && !limb_cyc_is_write);
assign      adreg_load[8:1] = limb_state[8:1];
assign      limb_wb_ready_wr_set = limb_cyc_is_write && limb_state == STATE_DATA3;
assign      limb_wb_ready_rd_set = !limb_nrd && limb_state == STATE_DATA0;
assign      next_addr0      = limb_start ? limb_d_in : adreg[0] + 1;

// Latch states on each clock
always @(posedge limb_clk) begin

    if (limb_state[5]) begin
        limb_cyc_is_write <= limb_nrd;
    end

    casez({limb_start, limb_state})
        {1'b1, 9'b?????????}:   limb_state <= STATE_ADDR1;
        {1'b0, STATE_ADDR0}:    limb_state <= STATE_ADDR1;
        {1'b0, STATE_ADDR1}:    limb_state <= STATE_ADDR2;
        {1'b0, STATE_ADDR2}:    limb_state <= STATE_ADDR3;
        {1'b0, STATE_ADDR3}:    limb_state <= STATE_ADDR4;
        {1'b0, STATE_ADDR4}:    limb_state <= STATE_DATA0;
        {1'b0, STATE_DATA0}:    limb_state <= STATE_DATA1;
        {1'b0, STATE_DATA1}:    limb_state <= STATE_DATA2;
        {1'b0, STATE_DATA2}:    limb_state <= STATE_DATA3;
        {1'b0, STATE_DATA3}:    limb_state <= STATE_DATA0;
        default:                $error("limb_interface limb SM: invalid_state");
    endcase

    if (limb_start)
        autoincr <= 0;
    else if (limb_state == STATE_DATA2)
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

dff_async_clr #( .init(0) )
dff_wb_ready_rd (
    .q(limb_wb_ready_rd),
    .d(1'b1),
    .clk(limb_clk),
    .ce(limb_wb_ready_rd_set),
    .clr(async_wb_ready_rd_clr) );

localparam      WB_STATE_WAIT      = 1 << 0;
localparam      WB_STATE_START_WR  = 1 << 1;
localparam      WB_STATE_FINISH_WR = 1 << 2;
localparam      WB_STATE_START_RD  = 1 << 3;
localparam      WB_STATE_FINISH_RD = 1 << 4;
reg     [4:0]   wb_state = WB_STATE_WAIT;

assign  wb_stb_o    = (wb_state == WB_STATE_START_WR) || (wb_state == WB_STATE_START_RD);
assign  wb_cyc_o    = (wb_state == WB_STATE_START_WR) || (wb_state == WB_STATE_START_RD);
assign  wb_we_o     = (wb_state == WB_STATE_START_WR);
assign  async_wb_ready_wr_clr = (wb_state == WB_STATE_FINISH_WR) || reset;
assign  async_wb_ready_rd_clr = (wb_state == WB_STATE_FINISH_RD) || reset;

always @(posedge clk) begin
    wb_ready_wr <= limb_wb_ready_wr;
    wb_ready_rd <= limb_wb_ready_rd;
    wb_adr_o <= limb_wb_adr;
    wb_dat_o <= limb_wb_dat;

    if (WB_STATE_FINISH_RD == wb_state)
        wb_data_in_lat <= wb_dat_i;

    if (reset)
        wb_state <= WB_STATE_WAIT;
    else
        casez({reset, wb_state})
            {1'b1, 5'b?????}:
                wb_state <= WB_STATE_WAIT;

            {1'b0, WB_STATE_WAIT}:
                if (wb_ready_rd)
                    wb_state <= WB_STATE_START_RD;
                else if (wb_ready_wr)
                    wb_state <= WB_STATE_START_WR;
                else
                    wb_state <= WB_STATE_WAIT;

            {1'b0, WB_STATE_START_WR}:
                if (wb_ack_i)
                    wb_state <= WB_STATE_FINISH_WR;
                else
                    wb_state <= WB_STATE_START_WR;

            {1'b0, WB_STATE_FINISH_WR}:
                wb_state <= WB_STATE_WAIT;

            {1'b0, WB_STATE_START_RD}:
                if (wb_ack_i)
                    wb_state <= WB_STATE_FINISH_RD;
                else
                    wb_state <= WB_STATE_START_RD;

            {1'b0, WB_STATE_FINISH_RD}:
                wb_state <= WB_STATE_WAIT;

            default:
                $error("limb_interface wishbone SM: invalid state");
        endcase
end

endmodule
