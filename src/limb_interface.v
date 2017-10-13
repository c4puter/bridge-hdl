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
    input   [7:0]   limb_d_in,
    output  [7:0]   limb_d_out,
    output          limb_d_oe,
    input           limb_clk,
    input           limb_nrd,
    input           limb_start,
    output          limb_nwait,

    // Wishbone master
    output  [35:0]  wb_adr_o,
    output          wb_we_o,
    output          wb_sel_o,
    output          wb_stb_o,
    output          wb_cyc_o,
    output  [31:0]  wb_dat_o,
    input   [31:0]  wb_dat_i,
    input           wb_ack_i,

    input           clk,
    input           reset
);

reg     [7:0]   adreg[8:0];

wire    [7:0]   next_addr0; // autoincrement over lsb
wire    [8:0]   adreg_load;

reg             autoincr;
reg     [8:0]   limb_state  = STATE_ADDR0;
wire    [8:0]   limb_nextstate;
localparam      STATE_ADDR0 = 9'b000000001;
localparam      STATE_ADDR1 = 9'b000000010;
localparam      STATE_ADDR2 = 9'b000000100;
localparam      STATE_ADDR3 = 9'b000001000;
localparam      STATE_ADDR4 = 9'b000010000;
localparam      STATE_DATA0 = 9'b000100000;
localparam      STATE_DATA1 = 9'b001000000;
localparam      STATE_DATA2 = 9'b010000000;
localparam      STATE_DATA3 = 9'b100000000;

assign          limb_d_out  = 'b00000000;
assign          limb_d_oe   = limb_nrd;
assign          limb_nwait  = 1;
assign          wb_adr_o    = {adreg[4][3:0], adreg[3], adreg[2], adreg[1], adreg[0]};
assign          wb_dat_o    = {adreg[8], adreg[7], adreg[6], adreg[5]};
assign          wb_sel_o    = 0;
assign          wb_stb_o    = 0;
assign          wb_cyc_o    = 0;

// A/D load is generally a function of the state, but the address LSB can also
// be loaded on autoincrement or any time limb_start is asserted.
assign      adreg_load[0] =
                limb_state[0] ||
                limb_start ||
                (autoincr && limb_state[5]);
assign      adreg_load[8:1] = limb_state[8:1];
assign      next_addr0      = (limb_start == 1) ? limb_d_in : adreg[0] + 1;

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

    if (limb_start == 1)
        autoincr <= 0;
    else if (limb_state == STATE_DATA3)
        autoincr <= 1;
end

// Latch address/data
always @(posedge limb_clk)
    if (adreg_load[0] == 1) adreg[0] <= next_addr0;

genvar i;
for (i = 1; i < 9; i = i + 1)
    always @(posedge limb_clk)
        if (adreg_load[i] == 1) adreg[i] <= limb_d_in;

`include "sim.v"

endmodule
