module bridge (

    // EC/LIMB data bus
    inout   [7:0]   limb_d,
    input           limb_start,
    input           limb_clk,
    input           limb_nrd,
    output          limb_nwait,
    output          limb_nreq,

    // CPU bus
    inout   [31:0]  cpu_d,
    output          cpu_nwait,
    input           cpu_naddr,
    input           cpu_nwr,
    input   [1:0]   cpu_nreq,
    output  [1:0]   cpu_nack,
    output  [1:0]   cpu_nint,
    output          cpu_clk_out,
    input           cpu_clk_in,

    // PCI bus
    inout   [31:0]  pci_ad,
    input   [3:0]   pci_nreq,
    output  [3:0]   pci_ngnt,
    input   [3:0]   pci_nint,
    output  [3:0]   pci_cbe,
    output          pci_nframe,
    input           pci_ntrdy,
    output          pci_nirdy,
    input           pci_ndevsel,
    input           pci_nstop,
    inout           pci_nserr,
    inout           pci_nperr,
    inout           pci_nlock,
    inout           pci_parity,
    output          pci_clk,

    // DDR3 SDRAM
    inout   [7:0]   ddr_ndqs,
    inout   [7:0]   ddr_pdqs,
    output  [2:0]   ddr_ba,
    output  [15:0]  ddr_addr,
    output  [7:0]   ddr_dm,
    output  [1:0]   ddr_nck,
    output  [1:0]   ddr_pck,
    output  [1:0]   ddr_cke,
    output          ddr_nwe,
    output          ddr_ncas,
    output          ddr_nras,
    output  [1:0]   ddr_ns,
    output  [1:0]   ddr_odt,
    inout   [63:0]  ddr_dq,
    input           ddr_clk_in
);

assign ddr_ba = 'h0;
assign ddr_addr = 'h0000;
assign ddr_dm = 'h00;
assign ddr_nck = 'h0;
assign ddr_pck = 'h0;
assign ddr_cke = 'h0;
assign ddr_nwe = 1;
assign ddr_ncas = 1;
assign ddr_nras = 1;
assign ddr_ns = 'b11;
assign ddr_odt = 'b00;

assign pci_clk = 0;
assign pci_ngnt = 'hf;
assign pci_cbe = 'hf;
assign pci_nframe = 1;
assign pci_nirdy = 1;

assign cpu_nwait = 1;
assign cpu_nack = 'b11;
assign cpu_nint = 'b11;
assign cpu_clk_out = 0;

assign limb_nreq = 1'b0;

wire ck150;
wire ck75;
wire[2:0] ddr_cmd;
wire ddr_reset;

wire mem_rd;
wire mem_wr;
wire [28:0] mem_addr;
wire [255:0] mem_wrdat;
wire [31:0] mem_mask;
wire [7:0] mem_debug;

(* keep="soft" *)
wire    [35:0]  wb_adr_full;
wire    [5:0]   wb_adr;
wire            wb_we;
wire    [3:0]   wb_sel;
wire            wb_stb;
wire            wb_cyc;
wire    [31:0]  wb_dat_to_ram;
wire    [31:0]  wb_dat_from_ram;
wire            wb_ack;
wire    [7:0]   limb_d_out;
wire            limb_d_oe;

assign wb_adr = {wb_adr_full[3:0], 2'b00};
assign limb_d = limb_d_oe ? limb_d_out : 8'bZZZZZZZZ;

limb_interface limb_interface_inst (
    .limb_d_in(limb_d),
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
    .clk(ddr_clk_in) );

wb_ram #( .ADDR_WIDTH(6) ) wb_ram_inst (
    .clk(ddr_clk_in),
    .adr_i(wb_adr),
    .dat_i(wb_dat_to_ram),
    .dat_o(wb_dat_from_ram),
    .we_i(wb_we),
    .sel_i(wb_sel),
    .stb_i(wb_stb),
    .ack_o(wb_ack),
    .cyc_i(wb_cyc) );

/*
assign ddr_nras = ddr_cmd[2];
assign ddr_ncas = ddr_cmd[1];
assign ddr_nwe  = ddr_cmd[0];
assign ddr_reset = 0;
assign mem_rd = 0;
assign mem_wr = 0;
assign mem_addr = 29'h0;
assign mem_wrdat = 256'h0;
assign mem_mask = 32'h0;
assign mem_debug = 8'h0;
*/

/*
drac_ddr3 drac (
    .ckin           (ddr_clk_in),   // should be 62.5 MHz
    .ckout          (ck150),
    .ckouthalf      (ck75),
    .reset          (ddr_reset),
    .ddq            (ddr_dq),
    .dqsp           (ddr_pdqs),
    .dqsn           (ddr_ndqs),
    .ddm            (ddr_dm),
    .da             (ddr_addr),
    .dba            (ddr_ba),
    .dcmd           (ddr_cmd),
    .dce            (ddr_cke),
    .dcs            (ddr_ns),
    .dckp           (ddr_pck),
    .dckn           (ddr_nck),
    .dodt           (ddr_odt),

    .srd(mem_rd),
    .swr(mem_wr),
    .sa(mem_addr),
    .swdat(mem_wrdat),
    .smsk(mem_mask),
    .srdat(),
    .srdy(),
    .dbg_out(),
    .dbg_in(mem_debug)
);
*/

endmodule
