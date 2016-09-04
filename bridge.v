module bridge (

    // EC/LIMB data bus
    inout   [7:0]   limb_d,
    input           limb_cmd,
    input           limb_ncs,
    input           linb_nwe,
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

endmodule
