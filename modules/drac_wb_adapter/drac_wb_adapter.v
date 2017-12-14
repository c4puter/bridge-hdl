/*
 * c4puter northbridge - DRAM controller to Wishbone glue
 * Copyright (C) 2017 Chris Pavlina
 *
 * Wishbone to DDR3 glue
 * from MicroBlaze MCS to DDR3 glue
 * (C) Copyright 2012 Silicon On Inspiration
 * www.sioi.com.au
 * 86 Longueville Road
 * Lane Cove 2066
 * New South Wales
 * AUSTRALIA
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module drac_wb_adapter (
    // DRAC interface
    output              drac_srd_o,
    output              drac_swr_o,
    output      [33:5]  drac_sa_o,
    output      [255:0] drac_swdat_o,
    output      [31:0]  drac_smsk_o,
    input       [255:0] drac_srdat_i,
    input               drac_srdy_i,
    input               clk150,

    // Wishbone slave
    input       [35:0]  wb_adr_i,
    input               wb_we_i,
    input       [3:0]   wb_sel_i,
    input               wb_stb_i,
    input               wb_cyc_i,
    input       [31:0]  wb_dat_i,
    output      [31:0]  wb_dat_o,
    output              wb_ack_o,
    input               clk75,

    input               reset
);

reg     [31:0]  rdat;
reg     [255:0] wdat;
reg     [31:0]  msk;
reg     [33:2]  addr;
reg             rdy1 = 1'b0;
reg             rdy2 = 1'b0;
reg             read = 1'b0;
reg             write = 1'b0;
reg             wb_stb_delay = 1'b0;

always @(posedge clk75) begin
    if (wb_stb_i && !wb_stb_delay && wb_we_i) begin
        case (wb_adr_i[2:0])
            3'b000: wdat[31:0] <= wb_dat_i;
            3'b001: wdat[63:32] <= wb_dat_i;
            3'b010: wdat[95:64] <= wb_dat_i;
            3'b011: wdat[127:96] <= wb_dat_i;
            3'b100: wdat[159:128] <= wb_dat_i;
            3'b101: wdat[191:160] <= wb_dat_i;
            3'b110: wdat[223:192] <= wb_dat_i;
            3'b111: wdat[255:224] <= wb_dat_i;
        endcase

        case (wb_adr_i[2:0])
            3'b000: msk <= 32'hFFFFFFF0;
            3'b001: msk <= 32'hFFFFFF0F;
            3'b010: msk <= 32'hFFFFF0FF;
            3'b011: msk <= 32'hFFFF0FFF;
            3'b100: msk <= 32'hFFF0FFFF;
            3'b101: msk <= 32'hFF0FFFFF;
            3'b110: msk <= 32'hF0FFFFFF;
            3'b111: msk <= 32'h0FFFFFFF;
        endcase
    end

    if (wb_stb_i && !wb_stb_delay) begin
        addr[33:2] <= wb_adr_i[31:0];
    end
end

always @(posedge clk75 or posedge reset) begin
    if (reset) begin
        read <= 1'b0;
        write <= 1'b0;
        rdy2 <= 1'b0;
        wb_stb_delay <= 1'b0;
    end else begin
        wb_stb_delay <= wb_stb_i;

        if (wb_stb_i && !wb_stb_delay && !wb_we_i) begin
            read <= 1'b1;
        end else if (wb_stb_i && !wb_stb_delay && wb_we_i) begin
            write <= 1'b1;
        end

        if (rdy1) begin
            read <= 1'b0;
            write <= 1'b0;
            rdy2 <= 1'b1;
        end

        if (rdy2) begin
            rdy2 <= 1'b0;
        end
    end
end

always @(posedge clk150 or posedge reset) begin
    if (reset) begin
        rdy1 <= 1'b0;
    end else begin
        if (drac_srdy_i) begin
            rdy1 <= 1'b1;
        end
        if (rdy2) begin
            rdy1 <= 1'b0;
        end
        if (drac_srdy_i) case (addr[4:2])
            3'b000: rdat <= drac_srdat_i[31:0];
            3'b001: rdat <= drac_srdat_i[63:32];
            3'b010: rdat <= drac_srdat_i[95:64];
            3'b011: rdat <= drac_srdat_i[127:96];
            3'b100: rdat <= drac_srdat_i[159:128];
            3'b101: rdat <= drac_srdat_i[191:160];
            3'b110: rdat <= drac_srdat_i[223:192];
            3'b111: rdat <= drac_srdat_i[255:224];
        endcase
    end
end

assign wb_dat_o = rdat;
assign wb_ack_o = rdy2;
assign drac_srd_o = read;
assign drac_swr_o = write;
assign drac_swdat_o = wdat;
assign drac_smsk_o = msk;
assign drac_sa_o = addr[33:5];

endmodule
