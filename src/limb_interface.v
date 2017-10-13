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
    limb_d_in, limb_d_out, limb_d_oe, limb_clk, limb_nrd, limb_start, limb_nwait,
    wb_adr_o, wb_we_o, wb_sel_o, wb_stb_o, wb_cyc_o, wb_dat_o, wb_dat_i, wb_ack_i,
    clk, reset );

input   [7:0]   limb_d_in;
output  [7:0]   limb_d_out;
output          limb_d_oe;
input           limb_clk;
input           limb_nrd;
input           limb_start;
output          limb_nwait;

// Wishbone master
output  [35:0]  wb_adr_o;
output          wb_we_o;
output          wb_sel_o;
output          wb_stb_o;
output          wb_cyc_o;
output  [31:0]  wb_dat_o;
input   [31:0]  wb_dat_i;
input           wb_ack_i;

input           clk;
input           reset;

reg     [7:0]   addr0;
reg     [7:0]   addr1;
reg     [7:0]   addr2;
reg     [7:0]   addr3;
reg     [7:0]   addr4;
reg     [7:0]   data0;
reg     [7:0]   data1;
reg     [7:0]   data2;
reg     [7:0]   data3;

wire    [7:0]   next_addr0; // autoincrement over lsb
wire            addr0_load;
wire            addr1_load;
wire            addr2_load;
wire            addr3_load;
wire            addr4_load;
wire            data0_load;
wire            data1_load;
wire            data2_load;
wire            data3_load;

reg             autoincr;
reg     [8:0]   limb_state  = STATE_ADDR0;
wire    [8:0]   limb_nstate;
localparam      STATE_ADDR0 = 9'b000000001;
localparam      STATE_ADDR1 = 9'b000000010;
localparam      STATE_ADDR2 = 9'b000000100;
localparam      STATE_ADDR3 = 9'b000001000;
localparam      STATE_ADDR4 = 9'b000010000;
localparam      STATE_DATA0 = 9'b000100000;
localparam      STATE_DATA1 = 9'b001000000;
localparam      STATE_DATA2 = 9'b010000000;
localparam      STATE_DATA3 = 9'b100000000;

assign      limb_d_out = 'b00000000;
assign      limb_d_oe  = limb_nrd;
assign      wb_adr_o = {addr4[3:0], addr3, addr2, addr1, addr0};
assign      wb_dat_o = {data3, data2, data1, data0};
assign      wb_sel_o = 0;
assign      wb_stb_o = 0;
assign      wb_cyc_o = 0;

assign      limb_nwait = 1;

assign      addr0_load = (limb_start || (limb_state == STATE_ADDR0) || (autoincr && limb_state == STATE_DATA0)) ? 1 : 0;
assign      addr1_load = (limb_state == STATE_ADDR1) ? 1 : 0;
assign      addr2_load = (limb_state == STATE_ADDR2) ? 1 : 0;
assign      addr3_load = (limb_state == STATE_ADDR3) ? 1 : 0;
assign      addr4_load = (limb_state == STATE_ADDR4) ? 1 : 0;
assign      data0_load = (limb_state == STATE_DATA0) ? 1 : 0;
assign      data1_load = (limb_state == STATE_DATA1) ? 1 : 0;
assign      data2_load = (limb_state == STATE_DATA2) ? 1 : 0;
assign      data3_load = (limb_state == STATE_DATA3) ? 1 : 0;

assign      next_addr0 = (limb_start == 1) ? limb_d_in : addr0 + 1;

assign      limb_nstate =
    (limb_start == 1) ? STATE_ADDR1 :
    (limb_state == STATE_ADDR0) ? STATE_ADDR1 :
    (limb_state == STATE_ADDR1) ? STATE_ADDR2 :
    (limb_state == STATE_ADDR2) ? STATE_ADDR3 :
    (limb_state == STATE_ADDR3) ? STATE_ADDR4 :
    (limb_state == STATE_ADDR4) ? STATE_DATA0 :
    (limb_state == STATE_DATA0) ? STATE_DATA1 :
    (limb_state == STATE_DATA1) ? STATE_DATA2 :
    (limb_state == STATE_DATA2) ? STATE_DATA3 :
    (limb_state == STATE_DATA3) ? STATE_DATA0 : STATE_ADDR0;

always @(posedge limb_clk) begin
    limb_state <= limb_nstate;

    if (limb_start == 1)
        autoincr <= 0;
    else if (limb_state == STATE_DATA3)
        autoincr <= 1;
    else
        autoincr <= autoincr;

    if (addr0_load == 1) addr0 <= next_addr0;
    if (addr1_load == 1) addr1 <= limb_d_in;
    if (addr2_load == 1) addr2 <= limb_d_in;
    if (addr3_load == 1) addr3 <= limb_d_in;
    if (addr4_load == 1) addr4 <= limb_d_in;
    if (data0_load == 1) data0 <= limb_d_in;
    if (data1_load == 1) data1 <= limb_d_in;
    if (data2_load == 1) data2 <= limb_d_in;
    if (data3_load == 1) data3 <= limb_d_in;
end


`include "sim.v"

endmodule
