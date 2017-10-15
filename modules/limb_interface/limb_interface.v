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

    input               clk
);

/******************************************************************************
 * CLOCK DOMAINS                                                              *
 ******************************************************************************/
// This module has three main clock domains, and prefixes all signals to
// indicate: L_ = LIMB, W_ = Wishbone, A_ = asynchronous.

wire            L_clk;
wire            W_clk;
assign          L_clk = limb_clk;
assign          W_clk = clk;

/******************************************************************************
 * DATAPATH                                                                   *
 ******************************************************************************/

wire    [8:0]   L_capture_limb;
wire            L_autoincr;
wire            W_capture_wb;
wire    [3:0]   L_limb_data_select;

reg     [7:0]   L_ad_from_limb  [8:0];
reg     [31:0]  W_data_from_wb      = 32'h00000000;

genvar i;
for (i = 0; i < 9; i = i + 1)
    initial L_ad_from_limb[i] = 8'h00;

// Capture address and data coming from LIMB
always @(posedge L_clk)
    if (L_capture_limb[0]) L_ad_from_limb[0] <= (L_autoincr ? L_ad_from_limb[0] + 8'b1 : limb_d_in);

for (i = 1; i < 9; i = i + 1)
    always @(posedge L_clk)
        if (L_capture_limb[i]) L_ad_from_limb[i] <= limb_d_in;

// Transfer address and data from LIMB to Wishbone clock domain
always @(posedge W_clk) begin
    wb_adr_o <= {L_ad_from_limb[4][3:0], L_ad_from_limb[3], L_ad_from_limb[2],
                 L_ad_from_limb[1], L_ad_from_limb[0]};
    wb_dat_o <= {L_ad_from_limb[8], L_ad_from_limb[7],
                 L_ad_from_limb[6], L_ad_from_limb[5]};
end

// Miscellaneous interface control signals
assign limb_d_oe = limb_nrd;
assign wb_sel_o  = 4'hF;

// Capture data from Wishbone for LIMB
always @(posedge W_clk) begin
    if (W_capture_wb)
        W_data_from_wb <= wb_dat_i;
end

// Multiplex captured Wishbone data to LIMB
// Mixed clock domain. Validity of signals when read by LIMB is guaranteed by
// handshaking protocol.
assign limb_d_out = L_limb_data_select[0] ? W_data_from_wb[0+:8] :
                    L_limb_data_select[1] ? W_data_from_wb[8+:8] :
                    L_limb_data_select[2] ? W_data_from_wb[16+:8] :
                                            W_data_from_wb[24+:8];

/******************************************************************************
 * HANDSHAKING                                                                *
 ******************************************************************************/

// Handshake sequence:
// 1.   LIMB FSM asserts L_req to request a cycle.
// 2.   At rising L_clk, L_wait latches high to tell the LIMB that the cycle
//      is in progress. Both L_wait signals combine to give limb_nwait.
// 3.   At rising W_clk, L_wait is captured into W_req to tell the WB FSM to
//      begin.
// 4.   When the WB FSM finishes, it asserts A_ack; L_wait is asynchronously
//      deasserted to allow the LIMB to proceed.
// 5.   The WB FSM steps through a settling state to allow L_wait to be
//      synchronized back into the Wishbone clock domain and avoid starting
//      another cycle.

wire            L_req_wr;
wire            L_req_rd;

wire            A_ack_wr;
wire            A_ack_rd;

reg             W_req_wr = 0;
reg             W_req_rd = 0;

wire            L_wait_wr;
wire            L_wait_rd;

dff_async_clr #( .init(0) )
dff_wb_ready_wr (
    .q(L_wait_wr),
    .d(1'b1),
    .clk(L_clk),
    .ce(L_req_wr),
    .clr(A_ack_wr) );

dff_async_clr #( .init(0) )
dff_wb_ready_rd (
    .q(L_wait_rd),
    .d(1'b1),
    .clk(L_clk),
    .ce(L_req_rd),
    .clr(A_ack_rd) );

always @(posedge W_clk) begin
    W_req_wr <= L_wait_wr;
    W_req_rd <= L_wait_rd;
end

assign          limb_nwait  = !(L_wait_wr || L_wait_rd);


/******************************************************************************
 * LIMB STATE MACHINE                                                         *
 ******************************************************************************/
localparam      ADDR1 = 8'd0;
localparam      ADDR2 = 8'd1;
localparam      ADDR3 = 8'd2;
localparam      ADDR4 = 8'd3;
localparam      DATA0 = 8'd4;
localparam      DATA1 = 8'd5;
localparam      DATA2 = 8'd6;
localparam      DATA3 = 8'd7;

(* signal_encoding = "one-hot" *)
reg     [7:0]   L_state             = 8'd1 << DATA0;
reg             L_cyc_is_write      = 1'b0;
reg             L_next_continues    = 1'b0; // next cycle continues a block
reg     [7:0]   L_next_normal;
wire    [7:0]   L_next;

assign          L_next = limb_start ? (8'd1 << ADDR1) : L_next_normal;

always @(L_state) begin
    L_next_normal = 8'd0;
    (* parallel_case *)
    case (1'b1)
        L_state[ADDR1]: L_next_normal[ADDR2] = 1'b1;
        L_state[ADDR2]: L_next_normal[ADDR3] = 1'b1;
        L_state[ADDR3]: L_next_normal[ADDR4] = 1'b1;
        L_state[ADDR4]: L_next_normal[DATA0] = 1'b1;
        L_state[DATA0]: L_next_normal[DATA1] = 1'b1;
        L_state[DATA1]: L_next_normal[DATA2] = 1'b1;
        L_state[DATA2]: L_next_normal[DATA3] = 1'b1;
        L_state[DATA3]: L_next_normal[DATA0] = 1'b1;
    endcase
end

always @(posedge L_clk) begin
    L_state <= L_next;

    if (L_state[DATA0])
        L_cyc_is_write <= limb_nrd;

    if (limb_start || L_state[DATA0])
        L_next_continues <= L_state[DATA0];
end

// A/D load is generally a function of the state, but the address LSB can also
// be loaded on autoincrement or any time limb_start is asserted.
assign      L_capture_limb[0] =
                limb_start ||
                (L_next_continues && L_cyc_is_write ? L_state[DATA0]
                                                    : L_state[DATA3]);
assign      L_capture_limb[8:1] = L_state[7:0];
assign      L_req_wr = L_cyc_is_write && L_state[DATA3];
assign      L_req_rd = !limb_nrd && L_state[DATA0];

assign      L_limb_data_select = {L_state[DATA0], L_state[DATA3:DATA1]};
assign      L_autoincr = !limb_start;

/******************************************************************************
 * WISHBONE STATE MACHINE                                                     *
 ******************************************************************************/

localparam      WAIT        = 6'd0;
localparam      START_WR    = 6'd1;
localparam      FINISH_WR   = 6'd2;
localparam      START_RD    = 6'd3;
localparam      FINISH_RD   = 6'd4;
localparam      SETTLE      = 6'd5;

(* signal_encoding = "one-hot" *)
reg     [5:0]   W_state     = 6'b00001;
reg     [5:0]   W_next;

always @(W_state, W_req_wr, W_req_rd, wb_ack_i) begin
    W_next = 6'd0;
    (* parallel_case *)
    case (1'b1)
        W_state[WAIT]:
            if      (W_req_wr && !W_req_rd)     W_next[START_WR]  = 1'b1;
            else if (W_req_rd && !W_req_wr)     W_next[START_RD]  = 1'b1;
            else                                W_next[WAIT]      = 1'b1;
        W_state[START_WR]:
            if      (wb_ack_i)                  W_next[FINISH_WR] = 1'b1;
            else                                W_next[START_WR]  = 1'b1;
        W_state[FINISH_WR]:
                                                W_next[SETTLE]    = 1'b1;
        W_state[START_RD]:
            if      (wb_ack_i)                  W_next[FINISH_RD] = 1'b1;
            else                                W_next[START_RD]  = 1'b1;
        W_state[FINISH_RD]:
                                                W_next[SETTLE]    = 1'b1;
        W_state[SETTLE]:
                                                W_next[WAIT]      = 1'b1;
    endcase
end

always @(posedge W_clk) begin
    W_state <= W_next;
end

assign wb_stb_o     = W_state[START_WR] || W_state[START_RD];
assign wb_cyc_o     = W_state[START_WR] || W_state[START_RD];
assign wb_we_o      = W_state[START_WR];
assign A_ack_wr     = W_state[FINISH_WR];
assign A_ack_rd     = W_state[FINISH_RD];
assign W_capture_wb = W_state[FINISH_RD];

endmodule
