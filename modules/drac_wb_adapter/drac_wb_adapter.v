/*
 * c4puter northbridge - DRAM controller to Wishbone glue
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

module drac_wb_adapter (
    // DRAC interface
    output              drac_srd_o,
    output              drac_swr_o,
    output      [33:5]  drac_sa_o,
    output      [255:0] drac_swdat_o,
    output reg  [31:0]  drac_smsk_o,
    input       [255:0] drac_srdat_i,
    input               drac_srdy_i,

    // Wishbone slave
    input       [35:0]  wb_adr_i = 0,
    input               wb_we_i,
    input       [3:0]   wb_sel_i,
    input               wb_stb_i,
    input               wb_cyc_i,
    input       [31:0]  wb_dat_i,
    output reg  [31:0]  wb_dat_o,
    output              wb_ack_o
);

assign drac_srd_o = wb_stb_i && ~wb_we_i;
assign drac_swr_o = wb_stb_i &&  wb_we_i;
assign drac_sa_o = wb_adr_i[31:3];
assign drac_swdat_o = {wb_dat_i, wb_dat_i, wb_dat_i, wb_dat_i,
                       wb_dat_i, wb_dat_i, wb_dat_i, wb_dat_i};

assign wb_ack_o = drac_srdy_i;

always @(*)
begin
    case (wb_adr_i[2:0])
        3'b000: begin drac_smsk_o <= 32'hFFFFFFF0; wb_dat_o <= drac_srdat_i[ 31:  0]; end
        3'b001: begin drac_smsk_o <= 32'hFFFFFF0F; wb_dat_o <= drac_srdat_i[ 63: 32]; end
        3'b010: begin drac_smsk_o <= 32'hFFFFF0FF; wb_dat_o <= drac_srdat_i[ 95: 64]; end
        3'b011: begin drac_smsk_o <= 32'hFFFF0FFF; wb_dat_o <= drac_srdat_i[127: 96]; end
        3'b100: begin drac_smsk_o <= 32'hFFF0FFFF; wb_dat_o <= drac_srdat_i[159:128]; end
        3'b101: begin drac_smsk_o <= 32'hFF0FFFFF; wb_dat_o <= drac_srdat_i[191:160]; end
        3'b110: begin drac_smsk_o <= 32'hF0FFFFFF; wb_dat_o <= drac_srdat_i[223:192]; end
        3'b111: begin drac_smsk_o <= 32'h0FFFFFFF; wb_dat_o <= drac_srdat_i[255:224]; end
    endcase
end

endmodule
