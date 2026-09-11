`default_nettype none

module QSPI_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter DATA_BYTES = DATA_WIDTH/8,
    parameter LINE_WORDS = 8
)(
    // APB INTERFACE
    
    input wire PCLK,
    input wire PRESETn,
    
    input wire PWRITE,
    input wire PENABLE,
    input wire PSEL,
    input wire [DATA_BYTES-1:0] PSTRB,
    input wire [31:0] PADDR,
    input wire [DATA_WIDTH-1:0] PWDATA,
    
    output wire PSLVERR,
    output wire PREADY,
    output wire [DATA_WIDTH-1:0] PRDATA,
    
    output wire APB_ERROR,
    
    
    // AHB INTERFACE
    
    input wire                  HCLK,
    input wire                  HRESETn,

    input wire                  HSEL,
    input wire [ADDR_WIDTH-1:0] HADDR,
    input wire                  HWRITE,
    input wire [1:0]            HTRANS,
    
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADYOUT,
    output wire                  HRESP,
    
    output wire [3:0] EMPTY,
    output wire [3:0] FULL,


    input wire SCLK,
    input wire SRESETn,
    
    
    // QSPI OUTPUTS
    
    input wire FLASH_WIP,
    
    input wire io0_i,
    input wire io1_i,
    input wire io2_i,
    input wire io3_i,
    
    output wire CSn,
  
    output wire io0_o,
    output wire io1_o,
    output wire io2_o,
    output wire io3_o,
    output wire io0_oe,
    output wire io1_oe,
    output wire io2_oe,
    output wire io3_oe    
);


    // APB PATH
    
    wire IND_FIFO_START;
    wire [7:0] IND_FIFO_OPCODE;
    wire [ADDR_WIDTH-1:0] IND_FIFO_ADDRESS;
    wire [DATA_WIDTH-1:0] IND_FIFO_TX_DATA;
    wire [4:0] IND_FIFO_DUMMY;
    wire [1:0] IND_FIFO_MODE;
    wire IND_FIFO_DATA_DIR;
    wire [5:0] IND_FIFO_ENABLE;
    wire IND_FIFO_EN_READ;
    
    wire IND_FIFO_ARB_START;
    wire [7:0] IND_FIFO_ARB_OPCODE;
    wire [ADDR_WIDTH-1:0] IND_FIFO_ARB_ADDRESS;
    wire [DATA_WIDTH-1:0] IND_FIFO_ARB_TX_DATA;
    wire [4:0] IND_FIFO_ARB_DUMMY;
    wire [1:0] IND_FIFO_ARB_MODE;
    wire IND_FIFO_ARB_DATA_DIR;
    wire [5:0] IND_FIFO_ARB_ENABLE;
    
    wire IND_FIFO_EN;
    wire FIFO_IND_BUSY;
    wire FIFO_IND_DONE;
    wire FIFO_IND_RX_VALID;
    wire [DATA_WIDTH-1:0] FIFO_IND_RX_DATA;
    wire FIFO_IND_ERROR;
    
    wire [DATA_WIDTH-1:0] ARB_FIFO_IND_RX_DATA;
    wire ARB_FIFO_IND_ERROR;
    wire ARB_FIFO_IND_RX_VALID;
    wire ARB_FIFO_IND_BUSY;
    wire ARB_FIFO_IND_DONE;
    wire IND_GET_EN;
    
    
    wire [DATA_WIDTH-1:0] XIP_AHB_RDATA;
    wire XIP_AHB_VALID;
    wire XIP_AHB_ERROR;
    
    wire [ADDR_WIDTH-1:0] AHB_XIP_ADDR;
    wire AHB_XIP_READ;
    
    wire XIP_FIFO_START;
    wire [7:0] XIP_FIFO_OPCODE;
    wire [ADDR_WIDTH-1:0] XIP_FIFO_ADDRESS;
    wire [4:0] XIP_FIFO_DUMMY;
    wire [1:0] XIP_FIFO_MODE;
    wire [7:0] XIP_FIFO_MODE_QIOR;
    wire [5:0] XIP_FIFO_ENABLE;
    
    wire XIP_FIFO_EN_READ;
    
    
    wire XIP_FIFO_ARB_START;
    wire XIP_FIFO_EN;
    
    wire [7:0] XIP_FIFO_ARB_OPCODE;
    wire [ADDR_WIDTH-1:0] XIP_FIFO_ARB_ADDRESS;
    wire [4:0] XIP_FIFO_ARB_DUMMY;
    wire [1:0] XIP_FIFO_ARB_MODE;
    wire [7:0] XIP_FIFO_ARB_MODE_QIOR;
    wire [5:0] XIP_FIFO_ARB_ENABLE;
    
    
    wire ARB_FIFO_XIP_BUSY;
    wire ARB_FIFO_XIP_DONE;
    wire ARB_FIFO_XIP_RX_VALID;
    wire [DATA_WIDTH-1:0] ARB_FIFO_XIP_RX_DATA;
    wire ARB_FIFO_XIP_ERROR;
    wire XIP_GET_EN;
    
    wire FIFO_XIP_BUSY;
    wire FIFO_XIP_DONE;
    wire FIFO_XIP_RX_VALID;
    wire [DATA_WIDTH-1:0] FIFO_XIP_RX_DATA;
    wire FIFO_XIP_ERROR;
    
    
    APB_Path #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_BYTES(DATA_BYTES)
) u_apb_path (
    .PCLK(PCLK),
    .PRESETn(PRESETn),

    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),
    .PSTRB(PSTRB),
    .PADDR(PADDR),
    .PWDATA(PWDATA),

    .PSLVERR(PSLVERR),
    .PREADY(PREADY),
    .PRDATA(PRDATA),

    .QSPI_BUSY(FIFO_IND_BUSY),
    .QSPI_DONE(FIFO_IND_DONE),
    .QSPI_RX_DATA(FIFO_IND_RX_DATA),
    .QSPI_RX_VALID(FIFO_IND_RX_VALID),
    .QSPI_ERROR(FIFO_IND_ERROR),

    .QSPI_START(IND_FIFO_START),
    .QSPI_OPCODE(IND_FIFO_OPCODE),
    .QSPI_ADDRESS(IND_FIFO_ADDRESS),
    .QSPI_DUMMY(IND_FIFO_DUMMY),
    .QSPI_MODE(IND_FIFO_MODE),
    .QSPI_TX_DATA(IND_FIFO_TX_DATA),
    .DATA_DIR(IND_FIFO_DATA_DIR),
    .QSPI_ENABLE(IND_FIFO_ENABLE),

    .FIFO_EN(IND_FIFO_EN_READ),

    .APB_ERROR(APB_ERROR)
);
    
    
    
    // ICE -> ARB FIFO
    
    syncro ff1(
        .clk(SCLK),
        .rst(SRESETn),
        .data_in(IND_FIFO_START),
        .data_out(IND_FIFO_ARB_START)
    );
    
    fifo_top #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + 22),
        .DEPTH(4)
    ) ice_arb(
        .wclk(PCLK),
        .wrst(PRESETn),
        .rclk(SCLK),
        .rrst(SRESETn),
        .w_en(IND_FIFO_EN_READ),
        .r_en(IND_FIFO_EN),
        .data_in({IND_FIFO_OPCODE,
                IND_FIFO_ADDRESS,
                IND_FIFO_DUMMY,
                IND_FIFO_MODE,
                IND_FIFO_TX_DATA,
                IND_FIFO_DATA_DIR,
                IND_FIFO_ENABLE}),
        .data_out({IND_FIFO_ARB_OPCODE,
                IND_FIFO_ARB_ADDRESS,
                IND_FIFO_ARB_DUMMY,
                IND_FIFO_ARB_MODE,
                IND_FIFO_ARB_TX_DATA,
                IND_FIFO_ARB_DATA_DIR,
                IND_FIFO_ARB_ENABLE}),
        .full(FULL[0]),
        .empty(EMPTY[0])
    );
    
    
    
    
    
    // ARB -> ICE FIFO
    
    syncro ff4(
        .clk(HCLK),
        .rst(HRESETn),
        .data_in(ARB_FIFO_IND_BUSY),
        .data_out(FIFO_IND_BUSY)
    );
    
    syncro ff5(
        .clk(HCLK),
        .rst(HRESETn),
        .data_in(ARB_FIFO_IND_DONE),
        .data_out(FIFO_IND_DONE)
    );
    
    fifo_top #(
        .DATA_WIDTH(DATA_WIDTH + 2),
        .DEPTH(4)
    ) arb_ice(
        .wclk(SCLK),
        .wrst(SRESETn),
        .rclk(PCLK),
        .rrst(PRESETn),
        .w_en(IND_GET_EN),
        .r_en(!EMPTY[1]),
        .data_in({ARB_FIFO_IND_RX_DATA,
                  ARB_FIFO_IND_ERROR,
                  ARB_FIFO_IND_RX_VALID}),
        .data_out({FIFO_IND_RX_DATA,
                  FIFO_IND_ERROR,
                  FIFO_IND_RX_VALID}),
        .full(FULL[1]),
        .empty(EMPTY[1])
    );
    
    
    
    
    
    AHB_Path #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .LINE_WORDS(LINE_WORDS)
) u_ahb_path (
    .HCLK(HCLK),
    .HRESETn(HRESETn),

    .HSEL(HSEL),
    .HADDR(HADDR),
    .HWRITE(HWRITE),
    .HTRANS(HTRANS),

    .HRDATA(HRDATA),
    .HREADYOUT(HREADYOUT),
    .HRESP(HRESP),

    .QSPI_START(XIP_FIFO_START),
    .QSPI_OPCODE(XIP_FIFO_OPCODE),
    .QSPI_ADDRESS(XIP_FIFO_ADDRESS),
    .QSPI_MODE(XIP_FIFO_MODE),
    .QSPI_MODE_QIOR(XIP_FIFO_MODE_QIOR),
    .QSPI_DUMMY(XIP_FIFO_DUMMY),
    .QSPI_ENABLE(XIP_FIFO_ENABLE),

    .FIFO_EN(XIP_FIFO_EN_READ),

    .QSPI_BUSY(FIFO_XIP_BUSY),
    .QSPI_DONE(FIFO_XIP_DONE),
    .QSPI_RX_DATA(FIFO_XIP_RX_DATA),
    .QSPI_RX_VALID(FIFO_XIP_RX_VALID),
    .QSPI_ERROR(FIFO_XIP_ERROR)
);
    
   
    
    
    
    // XIP -> ARB FIFO
    
    
    syncro ff6(
        .clk(SCLK),
        .rst(SRESETn),
        .data_in(XIP_FIFO_START),
        .data_out(XIP_FIFO_ARB_START)
    );
    
    fifo_top #(
        .DATA_WIDTH(ADDR_WIDTH + 29),
        .DEPTH(4)
    ) xip_arb(
        .wclk(HCLK),
        .wrst(HRESETn),
        .rclk(SCLK),
        .rrst(SRESETn),
        .w_en(XIP_FIFO_EN_READ),
        .r_en(XIP_FIFO_EN),
        .data_in({XIP_FIFO_OPCODE,
                  XIP_FIFO_ADDRESS,
                  XIP_FIFO_DUMMY,
                  XIP_FIFO_MODE,
                  XIP_FIFO_ENABLE,
                  XIP_FIFO_MODE_QIOR}),
        .data_out({XIP_FIFO_ARB_OPCODE,
                   XIP_FIFO_ARB_ADDRESS,
                   XIP_FIFO_ARB_DUMMY,
                   XIP_FIFO_ARB_MODE,
                   XIP_FIFO_ARB_ENABLE,
                   XIP_FIFO_ARB_MODE_QIOR}),
        .full(FULL[2]),
        .empty(EMPTY[2])
    );
    
    
    
    
    
    //ARB -> XIP FIFO
    
    syncro ff2(
        .clk(HCLK),
        .rst(HRESETn),
        .data_in(ARB_FIFO_XIP_BUSY),
        .data_out(FIFO_XIP_BUSY)
    );
    
    syncro ff3(
        .clk(HCLK),
        .rst(HRESETn),
        .data_in(ARB_FIFO_XIP_DONE),
        .data_out(FIFO_XIP_DONE)
    );
    
    fifo_top #(
        .DATA_WIDTH(2 + DATA_WIDTH),
        .DEPTH(4)
    ) arb_xip(
        .wclk(SCLK),
        .wrst(SRESETn),
        .rclk(HCLK),
        .rrst(HRESETn),
        .w_en(XIP_GET_EN),
        .r_en(!EMPTY[3]),
        .data_in({ARB_FIFO_XIP_RX_VALID,
                  ARB_FIFO_XIP_RX_DATA,
                  ARB_FIFO_XIP_ERROR}),
        .data_out({FIFO_XIP_RX_VALID,
                   FIFO_XIP_RX_DATA,
                   FIFO_XIP_ERROR}),
        .full(FULL[3]),
        .empty(EMPTY[3])
    );
    
    QSPI_Core #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_qspi_core (
    .SCLK(SCLK),
    .SRESETn(SRESETn),

    .IND_START(IND_FIFO_ARB_START),
    .IND_OPCODE(IND_FIFO_ARB_OPCODE),
    .IND_ADDRESS(IND_FIFO_ARB_ADDRESS),
    .IND_TX_DATA(IND_FIFO_ARB_TX_DATA),
    .IND_DUMMY(IND_FIFO_ARB_DUMMY),
    .IND_MODE(IND_FIFO_ARB_MODE),
    .IND_DATA_DIR(IND_FIFO_ARB_DATA_DIR),
    .IND_ENABLE(IND_FIFO_ARB_ENABLE),

    .XIP_START(XIP_FIFO_ARB_START),
    .XIP_OPCODE(XIP_FIFO_ARB_OPCODE),
    .XIP_ADDRESS(XIP_FIFO_ARB_ADDRESS),
    .XIP_DUMMY(XIP_FIFO_ARB_DUMMY),
    .XIP_MODE(XIP_FIFO_ARB_MODE),
    .XIP_ENABLE(XIP_FIFO_ARB_ENABLE),
    .XIP_MODE_QIOR(XIP_FIFO_ARB_MODE_QIOR),

    .IND_BUSY(ARB_FIFO_IND_BUSY),
    .IND_DONE(ARB_FIFO_IND_DONE),
    .IND_RX_DATA(ARB_FIFO_IND_RX_DATA),
    .IND_RX_DATA_VALID(ARB_FIFO_IND_RX_VALID),
    .IND_ERROR(ARB_FIFO_IND_ERROR),
    .IND_FIFO_EN(IND_FIFO_EN),
    .IND_GET_EN(IND_GET_EN),

    .XIP_BUSY(ARB_FIFO_XIP_BUSY),
    .XIP_DONE(ARB_FIFO_XIP_DONE),
    .XIP_RX_DATA(ARB_FIFO_XIP_RX_DATA),
    .XIP_RX_DATA_VALID(ARB_FIFO_XIP_RX_VALID),
    .XIP_ERROR(ARB_FIFO_XIP_ERROR),
    .XIP_FIFO_EN(XIP_FIFO_EN),
    .XIP_GET_EN(XIP_GET_EN),

    .io0_i(io0_i),
    .io1_i(io1_i),
    .io2_i(io2_i),
    .io3_i(io3_i),

    .FLASH_WIP(FLASH_WIP),

    .CSn(CSn),

    .io0_o(io0_o),
    .io1_o(io1_o),
    .io2_o(io2_o),
    .io3_o(io3_o),

    .io0_oe(io0_oe),
    .io1_oe(io1_oe),
    .io2_oe(io2_oe),
    .io3_oe(io3_oe)
);
    
    
    
   
endmodule
