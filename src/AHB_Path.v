`default_nettype none

module AHB_Path #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter LINE_WORDS = 8
)(
    // CLOCK AND RESET
    input wire                  HCLK,
    input wire                  HRESETn,

    // AHB-Lite inputs
    input wire                  HSEL,
    input wire [ADDR_WIDTH-1:0] HADDR,
    input wire                  HWRITE,
    input wire [1:0]            HTRANS,
    
    // AHB-Lite outputs
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADYOUT,
    output wire                  HRESP,
    
    // REQUEST TO QSPI ARBITER
    output wire QSPI_START,
    output wire [7:0] QSPI_OPCODE,
    output wire [ADDR_WIDTH-1:0] QSPI_ADDRESS,
    output wire [1:0] QSPI_MODE,
    output wire [7:0] QSPI_MODE_QIOR,
    output wire [4:0] QSPI_DUMMY,
    output wire [5:0] QSPI_ENABLE,

    // XIP -> ARB COMMAND FIFO WRITE ENABLE
    output wire FIFO_EN,

    // RESPONSE FROM QSPI ARBITER
    input wire QSPI_BUSY,
    input wire QSPI_DONE,
    input wire [DATA_WIDTH-1:0] QSPI_RX_DATA,
    input wire QSPI_RX_VALID,
    input wire QSPI_ERROR
    );
    
    
    wire [DATA_WIDTH-1:0] XIP_AHB_RDATA;
    wire XIP_AHB_VALID;
    wire XIP_AHB_ERROR;
    
    wire [ADDR_WIDTH-1:0] AHB_XIP_ADDR;
    wire AHB_XIP_READ;
    
    // AHB SLAVE
    
    AHB_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ahb(
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        
        .XIP_RDATA(XIP_AHB_RDATA),
        .XIP_VALID(XIP_AHB_VALID),
        .XIP_ERROR(XIP_AHB_ERROR),
        
        .HRDATA(HRDATA),
        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP),
        
        .XIP_ADDR(AHB_XIP_ADDR),
        .XIP_READ(AHB_XIP_READ)
    );
    
    
    // XIP + PREFETCH BUFFER
    
    
    XIP_PREFETCH_BUFFER #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LINE_WORDS(LINE_WORDS)
    ) xip(
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .XIP_ADDR(AHB_XIP_ADDR),
        .XIP_READ(AHB_XIP_READ),
        
        .XIP_RDATA(XIP_AHB_RDATA),
        .XIP_VALID(XIP_AHB_VALID),
        .XIP_ERROR(XIP_AHB_ERROR),
        
        .QSPI_START(QSPI_START),
        .QSPI_OPCODE(QSPI_OPCODE),
        .QSPI_ADDRESS(QSPI_ADDRESS),
        .QSPI_MODE(QSPI_MODE),
        .QSPI_MODE_QIOR(QSPI_MODE_QIOR),
        .QSPI_DUMMY(QSPI_DUMMY),
        .QSPI_ENABLE(QSPI_ENABLE),
        
        .FIFO_EN(FIFO_EN),
        
        .QSPI_BUSY(QSPI_BUSY),
        .QSPI_DONE(QSPI_DONE),
        .QSPI_RX_DATA(QSPI_RX_DATA),
        .QSPI_RX_VALID(QSPI_RX_VALID),
        .QSPI_ERROR(QSPI_ERROR)
    );
endmodule

