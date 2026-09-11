`default_nettype none

module XIP_PREFETCH_BUFFER #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_WORDS = 8
)(
    input wire HCLK,
    input wire HRESETn,

    // REQUEST FROM AHB SLAVE
    input wire [ADDR_WIDTH-1:0] XIP_ADDR,
    input wire XIP_READ,

    // RESPONSE TO AHB SLAVE
    output reg [DATA_WIDTH-1:0] XIP_RDATA,
    output reg XIP_VALID,
    output reg XIP_ERROR,

    // REQUEST TO QSPI ARBITER
    output reg QSPI_START,
    output reg [7:0] QSPI_OPCODE,
    output reg [ADDR_WIDTH-1:0] QSPI_ADDRESS,
    output reg [1:0] QSPI_MODE,
    output reg [7:0] QSPI_MODE_QIOR,
    output reg [4:0] QSPI_DUMMY,
    output reg [5:0] QSPI_ENABLE,

    // XIP -> ARB COMMAND FIFO WRITE ENABLE
    output reg FIFO_EN,

    // RESPONSE FROM QSPI ARBITER
    input wire QSPI_BUSY,
    input wire QSPI_DONE,
    input wire [DATA_WIDTH-1:0] QSPI_RX_DATA,
    input wire QSPI_RX_VALID,
    input wire QSPI_ERROR
);

localparam WORD_BYTES = DATA_WIDTH / 8;
localparam WORD_BITS = $clog2(WORD_BYTES);
localparam LINE_BITS = $clog2(LINE_WORDS);
localparam OFFSET_BITS = WORD_BITS + LINE_BITS;

localparam ST_IDLE     = 3'd0;
localparam ST_LOOKUP   = 3'd1;
localparam ST_PREFETCH = 3'd2;
localparam ST_WAIT     = 3'd3;
localparam ST_RETURN   = 3'd4;

reg [2:0] PS, NS;

reg [DATA_WIDTH-1:0] prefetch [0:LINE_WORDS-1];

reg [ADDR_WIDTH-OFFSET_BITS-1:0] tag;
reg prefetch_valid;

reg [ADDR_WIDTH-1:0] req_addr;
reg [ADDR_WIDTH-1:0] line_addr;

reg [LINE_BITS-1:0] word_offset;
reg [LINE_BITS-1:0] fill_count;

wire hit;

assign hit = prefetch_valid && (req_addr[ADDR_WIDTH-1:OFFSET_BITS] == tag);

always @(*) begin
    XIP_RDATA = 0;
    XIP_VALID = 0;

    if(PS == ST_RETURN) begin
        XIP_RDATA = prefetch[word_offset];
        XIP_VALID = 1;
    end
end

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn)
        PS <= ST_IDLE;
    else
        PS <= NS;
end

always @(*) begin
    NS = PS;
    case(PS)
        ST_IDLE: begin
            if(XIP_READ && !QSPI_BUSY)
                NS = ST_LOOKUP;
        end
        ST_LOOKUP: begin
            if(hit)
                NS = ST_RETURN;
            else
                NS = ST_PREFETCH;
        end
        ST_PREFETCH: begin
            NS = ST_WAIT;
        end
        ST_WAIT: begin
            if(QSPI_ERROR)
                NS = ST_IDLE;
            else if(QSPI_RX_VALID) begin
                if(fill_count == LINE_WORDS-1)
                    NS = ST_RETURN;
                else
                    NS = ST_PREFETCH;
            end
            else
                NS = ST_WAIT;
        end
        ST_RETURN: begin
            NS = ST_IDLE;
        end
        default: begin
            NS = ST_IDLE;
        end
    endcase
end

integer i;

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        prefetch_valid <= 0;
        tag            <= 0;
        req_addr       <= 0;
        line_addr      <= 0;
        word_offset    <= 0;
        fill_count     <= 0;

        QSPI_START     <= 0;
        QSPI_OPCODE    <= 0;
        QSPI_ADDRESS   <= 0;
        QSPI_MODE      <= 0;
        QSPI_MODE_QIOR <= 0;
        QSPI_DUMMY     <= 0;
        QSPI_ENABLE    <= 0;

        XIP_ERROR      <= 0;

        for(i = 0; i < LINE_WORDS; i = i + 1)
            prefetch[i] <= 0;
    end
    else begin
        XIP_ERROR <= 0;
        case(PS)
            ST_IDLE: begin
                QSPI_START <= 0;
                if(XIP_READ) begin
                    req_addr <= XIP_ADDR;
                    line_addr <= XIP_ADDR & ~(LINE_WORDS * WORD_BYTES - 1);
                    word_offset <= XIP_ADDR[OFFSET_BITS-1:WORD_BITS];
                end
            end
            ST_LOOKUP: begin
                if(!hit) begin
                    prefetch_valid <= 0;
                    fill_count     <= 0;
                end
            end
            ST_PREFETCH: begin
                QSPI_START <= 1;
                QSPI_OPCODE <= 8'hEB;
                QSPI_ADDRESS <= line_addr + (fill_count * WORD_BYTES);
                QSPI_MODE <= 2'b10;
                QSPI_MODE_QIOR <= 8'h00;
                QSPI_DUMMY <= 5'd8;
                QSPI_ENABLE <= 6'b011111;
            end
            ST_WAIT: begin
                QSPI_START <= 1;
                if(QSPI_ERROR) begin
                    prefetch_valid <= 0;
                    XIP_ERROR      <= 1;
                    QSPI_START     <= 0;
                end
                else if(QSPI_RX_VALID) begin
                    prefetch[fill_count] <= QSPI_RX_DATA;
                    QSPI_START <= 0;
                    if(fill_count == LINE_WORDS-1) begin
                        tag <= req_addr[ADDR_WIDTH-1:OFFSET_BITS];
                        prefetch_valid <= 1;
                    end
                    else begin
                        fill_count <= fill_count + 1;
                    end
                end
                else if(QSPI_DONE) begin
                    QSPI_START <= 0;
                end
            end
            ST_RETURN: begin
                QSPI_START <= 0;
            end
            default: begin
                QSPI_START <= 0;
            end
        endcase
    end
end

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        FIFO_EN <= 0;
    end
    else begin
        FIFO_EN <= 0;
        if((PS == ST_PREFETCH) && !QSPI_BUSY)
            FIFO_EN <= 1;
    end
end

endmodule
