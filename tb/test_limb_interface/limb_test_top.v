module limb_test_top (
    // LIMB interface - toplevel should combine limb_d_in, limb_d_out, and
    // limb_d_oe into a single 'inout' bus.
    input       [7:0]   limb_d_in,
    output      [7:0]   limb_d_out,
    output              limb_d_oe,
    input               limb_clk,
    input               limb_nrd,
    input               limb_start,
    output              limb_nwait,
    output      [35:0]  wb_adr_o,
    output      [31:0]  wb_dat_o,
    output              wb_we_o,
    output              wb_stb_o,
    input               clk
);

wire    [35:0]  wb_adr_full;
wire    [5:0]   wb_adr;
wire            wb_we;
wire    [3:0]   wb_sel;
wire            wb_stb;
wire            wb_cyc;
wire    [31:0]  wb_dat_to_ram;
wire    [31:0]  wb_dat_from_ram;
wire            wb_ack;

assign wb_adr = {wb_adr_full[3:0], 2'b00};

assign wb_adr_o = wb_adr_full;
assign wb_dat_o = wb_dat_to_ram;
assign wb_we_o = wb_we;
assign wb_stb_o = wb_stb;

limb_interface limb_interface_inst (
    .limb_d_in(limb_d_in),
    .limb_d_out(limb_d_out),
    .limb_d_oe(limb_d_oe),
    .limb_clk(limb_clk),
    .limb_nrd(limb_nrd),
    .limb_start(limb_start),
    .limb_nwait(limb_nwait),

    .wb_adr_o(wb_adr_full),
    .wb_we_o(wb_we),
    .wb_sel_o(wb_sel),
    .wb_stb_o(wb_stb),
    .wb_cyc_o(wb_cyc),
    .wb_dat_o(wb_dat_to_ram),
    .wb_dat_i(wb_dat_from_ram),
    .wb_ack_i(wb_ack),
    .clk(clk) );

wb_ram #( .ADDR_WIDTH(6) ) wb_ram_inst (
    .clk(clk),
    .adr_i(wb_adr),
    .dat_i(wb_dat_to_ram),
    .dat_o(wb_dat_from_ram),
    .we_i(wb_we),
    .sel_i(wb_sel),
    .stb_i(wb_stb),
    .ack_o(wb_ack),
    .cyc_i(wb_cyc) );

initial begin
    $dumpfile("out.vcd");
    $dumpvars();
end

endmodule
