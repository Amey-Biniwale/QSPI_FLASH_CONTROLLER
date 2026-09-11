`default_nettype none

module AHB_Slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // CLOCK AND RESET
    input wire                  HCLK,
    input wire                  HRESETn,

    // AHB-Lite inputs
    input wire                  HSEL,
    input wire [ADDR_WIDTH-1:0] HADDR,
    input wire                  HWRITE,
    input wire [1:0]            HTRANS,

    // From XIP module
    input wire [DATA_WIDTH-1:0] XIP_RDATA,
    input wire                  XIP_VALID,
    input wire                  XIP_ERROR,

    // AHB-Lite outputs
    output reg [DATA_WIDTH-1:0] HRDATA,
    output reg                  HREADYOUT,
    output reg                  HRESP,

    // To XIP module
    output reg [ADDR_WIDTH-1:0] XIP_ADDR,
    output reg                  XIP_READ
);

    localparam HTRANS_IDLE   = 2'b00;
    localparam HTRANS_BUSY   = 2'b01;
    localparam HTRANS_NONSEQ = 2'b10;
    localparam HTRANS_SEQ    = 2'b11;

    wire AHB_TRANSFER;

    assign AHB_TRANSFER =
        HSEL &&
        ((HTRANS == HTRANS_NONSEQ) ||
         (HTRANS == HTRANS_SEQ));

    // AHB request to XIP Prefetch Buffer
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            XIP_ADDR <= 0;
            XIP_READ <= 0;
        end
        else begin
            XIP_READ <= 0;

            if(AHB_TRANSFER && !HWRITE) begin
                XIP_ADDR <= HADDR;
                XIP_READ <= 1;
            end
        end
    end

    // AHB response
    always @(*) begin
        HRDATA    = 0;
        HREADYOUT = 0;
        HRESP     = 0;

        // XIP transaction error
        if(XIP_ERROR) begin
            HRDATA    = 0;
            HREADYOUT = 1;
            HRESP     = 1;
        end

        // XIP transaction successful
        else if(XIP_VALID) begin
            HRDATA    = XIP_RDATA;
            HREADYOUT = 1;
            HRESP     = 0;
        end

        // AHB write is not supported by XIP
        else if(AHB_TRANSFER && HWRITE) begin
            HRDATA    = 0;
            HREADYOUT = 1;
            HRESP     = 1;
        end
    end

endmodule
