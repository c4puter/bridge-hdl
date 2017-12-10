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
    output          pci_ndevsel,
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

assign pci_ad       = 32'hZZZZZZZZ;
assign pci_nserr    = 1'bZ;
assign pci_nperr    = 1'bZ;
assign pci_nlock    = 1'bZ;
assign pci_parity   = 1'bZ;
assign pci_clk      = 1'b0;
assign pci_ngnt     = 4'hF;
assign pci_cbe      = 4'hF;
assign pci_nframe   = 1'b1;
assign pci_nirdy    = 1'b1;
assign pci_ndevsel  = 1'b1;

assign cpu_d        = 32'hZZZZZZZZ;
assign cpu_nwait    = 1'b1;
assign cpu_nack     = 1'b11;
assign cpu_nint     = 1'b11;
assign cpu_clk_out  = 1'b0;

assign limb_nreq    = 1'b0;

wire ck150;
wire ck75;
wire[2:0] ddr_cmd;
wire ddr_reset;

`define DEF_WISHBONE_WIRES(name) \
    (* keep="soft" *) \
    wire    [35:0]  wb_adr_``name; \
    wire            wb_we_``name; \
    wire    [3:0]   wb_sel_``name; \
    wire            wb_stb_``name; \
    wire            wb_cyc_``name; \
    wire    [31:0]  wb_dat_to_``name; \
    wire    [31:0]  wb_dat_from_``name; \
    wire            wb_ack_``name;

`define DEF_WISHBONE_UNUSED(n) \
    wire            wb_ack_stb_``n;

`define CONNECT_MASTER(n, name) \
    .m``n``_data_i(wb_dat_from_``name), \
    .m``n``_data_o(wb_dat_to_``name), \
    .m``n``_addr_i(wb_adr_``name), \
    .m``n``_sel_i(wb_sel_``name), \
    .m``n``_we_i(wb_we_``name), \
    .m``n``_cyc_i(wb_cyc_``name), \
    .m``n``_stb_i(wb_stb_``name), \
    .m``n``_ack_o(wb_ack_``name)

`define UNUSED_MASTER(n) \
    .m``n``_data_i(32'h00000000), \
    .m``n``_addr_i(36'h000000000), \
    .m``n``_sel_i(4'h0), \
    .m``n``_we_i(1'b0), \
    .m``n``_cyc_i(1'b0), \
    .m``n``_stb_i(1'b0)

`define CONNECT_SLAVE(n, name) \
    .s``n``_data_i(wb_dat_from_``name), \
    .s``n``_data_o(wb_dat_to_``name), \
    .s``n``_addr_o(wb_adr_``name), \
    .s``n``_sel_o(wb_sel_``name), \
    .s``n``_we_o(wb_we_``name), \
    .s``n``_cyc_o(wb_cyc_``name), \
    .s``n``_stb_o(wb_stb_``name), \
    .s``n``_ack_i(wb_ack_``name), \
    .s``n``_err_i(1'b0), \
    .s``n``_rty_i(1'b0)

`define UNUSED_SLAVE(n) \
    .s``n``_data_i(32'h00000000), \
    .s``n``_ack_i(wb_ack_stb_``n), \
    .s``n``_stb_o(wb_ack_stb_``n), \
    .s``n``_err_i(1'b0), \
    .s``n``_rty_i(1'b0)

`DEF_WISHBONE_WIRES(limb)
`DEF_WISHBONE_WIRES(blockram)
`DEF_WISHBONE_WIRES(dram)
`DEF_WISHBONE_UNUSED(1)
`DEF_WISHBONE_UNUSED(2)
`DEF_WISHBONE_UNUSED(3)
`DEF_WISHBONE_UNUSED(4)
`DEF_WISHBONE_UNUSED(5)
`DEF_WISHBONE_UNUSED(6)
`DEF_WISHBONE_UNUSED(7)
`DEF_WISHBONE_UNUSED(8)
`DEF_WISHBONE_UNUSED(9)
`DEF_WISHBONE_UNUSED(10)
`DEF_WISHBONE_UNUSED(11)
`DEF_WISHBONE_UNUSED(12)
`DEF_WISHBONE_UNUSED(13)
`DEF_WISHBONE_UNUSED(15)

wire    [7:0]   limb_d_out;
wire            limb_d_oe;

//assign wb_adr = {wb_adr_full[3:0], 2'b00};
assign limb_d = limb_d_oe ? limb_d_out : 8'bZZZZZZZZ;

limb_interface limb_interface_inst (
    .limb_d_in(limb_d),
    .limb_d_out(limb_d_out),
    .limb_d_oe(limb_d_oe),
    .limb_clk(limb_clk),
    .limb_nrd(limb_nrd),
    .limb_start(limb_start),
    .limb_nwait(limb_nwait),

    .wb_adr_o(wb_adr_limb),
    .wb_we_o(wb_we_limb),
    .wb_sel_o(wb_sel_limb),
    .wb_stb_o(wb_stb_limb),
    .wb_cyc_o(wb_cyc_limb),
    .wb_dat_o(wb_dat_from_limb),
    .wb_dat_i(wb_dat_to_limb),
    .wb_ack_i(wb_ack_limb),
    .clk(ck150) );

wb_ram #( .ADDR_WIDTH(6) ) wb_ram_inst (
    .clk(ck150),
    .adr_i({wb_adr_blockram[3:0], 2'b00}),
    .dat_i(wb_dat_to_blockram),
    .dat_o(wb_dat_from_blockram),
    .we_i(wb_we_blockram),
    .sel_i(wb_sel_blockram),
    .stb_i(wb_stb_blockram),
    .ack_o(wb_ack_blockram),
    .cyc_i(wb_cyc_blockram) );

wb_conmax_top #( .dw(32), .aw(36) ) wb_conmax_inst (
    .clk_i(ck150),
    .rst_i(1'b0),

    `CONNECT_MASTER(0, limb),
    `UNUSED_MASTER(1),
    `UNUSED_MASTER(2),
    `UNUSED_MASTER(3),
    `UNUSED_MASTER(4),
    `UNUSED_MASTER(5),
    `UNUSED_MASTER(6),
    `UNUSED_MASTER(7),

    `CONNECT_SLAVE(0, blockram),
    `UNUSED_SLAVE(1),
    `UNUSED_SLAVE(2),
    `UNUSED_SLAVE(3),
    `UNUSED_SLAVE(4),
    `UNUSED_SLAVE(5),
    `UNUSED_SLAVE(6),
    `UNUSED_SLAVE(7),
    `UNUSED_SLAVE(8),
    `UNUSED_SLAVE(9),
    `UNUSED_SLAVE(10),
    `UNUSED_SLAVE(11),
    `UNUSED_SLAVE(12),
    `UNUSED_SLAVE(13),
    `CONNECT_SLAVE(14, dram),
    `UNUSED_SLAVE(15)
);

wire            drac_srd;
wire            drac_swr;
wire    [33:5]  drac_sa;
wire    [255:0] drac_swdat;
wire    [31:0]  drac_smsk;
wire    [255:0] drac_srdat;
wire            drac_srdy;
wire    [7:0]   drac_dbg;

assign drac_dbg = 8'h00;
assign ddr_nras = ddr_cmd[2];
assign ddr_ncas = ddr_cmd[1];
assign ddr_nwe  = ddr_cmd[0];

drac_wb_adapter drac_wb (
    .drac_srd_o     (drac_srd),
    .drac_swr_o     (drac_swr),
    .drac_sa_o      (drac_sa),
    .drac_swdat_o   (drac_swdat),
    .drac_smsk_o    (drac_smsk),
    .drac_srdat_i   (drac_srdat),
    .drac_srdy_i    (drac_srdy),

    .wb_adr_i       (wb_adr_dram),
    .wb_we_i        (wb_we_dram),
    .wb_sel_i       (wb_sel_dram),
    .wb_stb_i       (wb_stb_dram),
    .wb_cyc_i       (wb_cyc_dram),
    .wb_dat_i       (wb_dat_to_dram),
    .wb_dat_o       (wb_dat_from_dram),
    .wb_ack_o       (wb_ack_dram)
);

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

    .srd(drac_srd),
    .swr(drac_swr),
    .sa(drac_sa),
    .swdat(drac_swdat),
    .smsk(drac_smsk),
    .srdat(drac_srdat),
    .srdy(drac_srdy),
    .dbg_out(),
    .dbg_in(drac_dbg)
);

endmodule
