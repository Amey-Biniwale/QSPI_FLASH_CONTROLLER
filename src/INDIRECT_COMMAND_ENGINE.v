`default_nettype none

module INDIRECT_COMMAND_ENGINE #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // CLOCK AND RESET
    input wire PCLK,
    input wire PRESETn,

    // APB REGISTER INTERFACE
    input wire [DATA_WIDTH-1:0] APB_DATA,
    input wire [ADDR_WIDTH-1:0] APB_ADDR,
    input wire APB_WRITE,

    // QSPI CONTROLLER INTERFACE
    input wire QSPI_BUSY,
    input wire QSPI_DONE,
    input wire [DATA_WIDTH-1:0] QSPI_RX_DATA,
    input wire QSPI_RX_VALID,
    input wire QSPI_ERROR,

    // COMMAND TO ARBITER
    output reg QSPI_START,
    output reg [7:0] QSPI_OPCODE,
    output reg [ADDR_WIDTH-1:0] QSPI_ADDRESS,
    output reg [4:0] QSPI_DUMMY,
    output reg [1:0] QSPI_MODE,
    output reg [DATA_WIDTH-1:0] QSPI_TX_DATA,
    output reg DATA_DIR,
    output reg [5:0] QSPI_ENABLE,

    // IND -> ARB COMMAND FIFO WRITE ENABLE
    output reg FIFO_EN,

    // APB READ RESPONSE
    output reg [DATA_WIDTH-1:0] APB_RDATA,

    // QSPI TRANSACTION ERROR
    output reg APB_ERROR
);

localparam [31:0] OPCODE_ADDR   = 32'h0000;
localparam [31:0] ADDRESS_ADDR  = 32'h0008;
localparam [31:0] MODE_ADDR     = 32'h0028;
localparam [31:0] DUMMY_ADDR    = 32'h0030;
localparam [31:0] DATA_ADDR     = 32'h0038;
localparam [31:0] START_ADDR    = 32'h0058;
localparam [31:0] DATA_DIR_ADDR = 32'h0059;
localparam [31:0] EN_ADDR       = 32'h005A;

localparam IDLE  = 0;
localparam TRANS = 1;

reg PS, NS;

reg [7:0] opcode_reg;
reg [ADDR_WIDTH-1:0] address_reg;
reg [4:0] dummy_reg;
reg [1:0] mode_reg;
reg [DATA_WIDTH-1:0] data_reg;
reg start_reg;
reg data_dir_reg;
reg [5:0] en_reg;

reg [DATA_WIDTH-1:0] rdata_reg;
reg error_reg;

always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn)
        PS <= IDLE;
    else
        PS <= NS;
end

always @(*) begin
    NS = PS;

    case(PS)
        IDLE: begin
            if(start_reg && !QSPI_BUSY)
                NS = TRANS;
        end

        TRANS: begin
            if(QSPI_DONE || QSPI_ERROR)
                NS = IDLE;
        end

        default:
            NS = IDLE;
    endcase
end

always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        opcode_reg   <= 0;
        address_reg  <= 0;
        dummy_reg    <= 0;
        mode_reg     <= 0;
        data_reg     <= 0;
        start_reg    <= 0;
        data_dir_reg <= 0;
        en_reg       <= 0;
        rdata_reg <= 0;
        error_reg <= 0;
    end
    else begin
        if(APB_WRITE) begin
            case(APB_ADDR)
                OPCODE_ADDR: opcode_reg <= APB_DATA[7:0];
                ADDRESS_ADDR: address_reg <= APB_DATA[ADDR_WIDTH-1:0];
                MODE_ADDR: mode_reg <= APB_DATA[1:0];
                DUMMY_ADDR: dummy_reg <= APB_DATA[4:0];
                DATA_ADDR: data_reg <= APB_DATA;
                START_ADDR: start_reg <= APB_DATA[0];
                DATA_DIR_ADDR: data_dir_reg <= APB_DATA[0];
                EN_ADDR: en_reg <= APB_DATA[5:0];
            endcase
        end
        else if((PS == IDLE) && start_reg && !QSPI_BUSY) begin
            start_reg <= 0;
        end
        if(QSPI_RX_VALID)
            rdata_reg <= QSPI_RX_DATA;

        if(QSPI_ERROR)
            error_reg <= 1;
        else if(PS == IDLE)
            error_reg <= 0;
    end
end

always @(*) begin
    QSPI_OPCODE  = opcode_reg;
    QSPI_ADDRESS = address_reg;
    QSPI_DUMMY   = dummy_reg;
    QSPI_MODE    = mode_reg;
    QSPI_TX_DATA = data_reg;
    DATA_DIR     = data_dir_reg;
    QSPI_ENABLE  = en_reg;
    APB_RDATA = rdata_reg;
    APB_ERROR = error_reg;

    QSPI_START = 0;

    case(PS)
        IDLE: QSPI_START = 0;
        TRANS: QSPI_START = 1;
        default: QSPI_START = 0;
    endcase
end

always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
        FIFO_EN <= 0;
    end
    else begin
        FIFO_EN <= 0;
        if((PS == IDLE) && start_reg && !QSPI_BUSY) FIFO_EN <= 1;
    end
end

endmodule

