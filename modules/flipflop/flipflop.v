/*
 * c4puter northbridge - flipflop primitives
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

/**
 * D flip-flop with asynchronous clear
 *
 * Uses Spartan 6 FDCE block for synthesis.
 */
module dff_async_clr (
    input   d,
    input   ce,
    input   clk,
    output  q,

    input   clr
);

parameter init = 0;

`ifdef COCOTB_SIM
    reg     ff;
    assign  q = clr ? 0 : ff;

    always @(posedge clk)
        if (ce)
            ff <= d;

    always @(negedge clr)
            ff <= 0;

    initial begin
        @(clk);
        ff <= init;
    end
`else
    FDCE #(
        .INIT(init)
    ) FDCE_inst (
        .Q(q),
        .C(clk),
        .CE(ce),
        .D(d),
        .CLR(clr)
    );
`endif
endmodule

/**
 * D flip-flop with asynchronous set
 *
 * Uses Spartan 6 FDPE block for synthesis.
 */
module dff_async_set (
    input   d,
    input   ce,
    input   clk,
    output  q,

    input   set
);

parameter init = 0;

`ifdef COCOTB_SIM
    reg     ff;
    assign  q = set ? 1 : ff;

    always @(posedge clk)
        if (ce)
            ff <= d;

    always @(negedge set)
        ff <= 1;

    initial begin
        @(clk);
        ff <= init;
    end
`else
    FDPE #(
        .INIT(init)
    ) FDPE_inst (
        .Q(q),
        .C(clk),
        .CE(ce),
        .D(d),
        .PRE(set)
    );
`endif
endmodule
