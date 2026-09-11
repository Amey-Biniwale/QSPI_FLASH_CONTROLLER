`default_nettype none

module QSPI_ARBITER #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // CLOCK AND RESET
    input wire SCLK,
    input wire SRESETn,
    
    // INPUTS FROM INDIRECT COMMAND ENGINE
    input wire IND_START,
    input wire [7:0] IND_OPCODE,
    input wire [ADDR_WIDTH-1:0] IND_ADDRESS,
    input wire [DATA_WIDTH-1:0] IND_TX_DATA,
    input wire [4:0] IND_DUMMY,
    input wire [1:0] IND_MODE,
    input wire IND_DATA_DIR,
    input wire [5:0] IND_ENABLE,
    
    // INPUTS FROM XIP
    input wire XIP_START,
    input wire [7:0] XIP_OPCODE,
    input wire [ADDR_WIDTH-1:0] XIP_ADDRESS,
    input wire [4:0] XIP_DUMMY,
    input wire [1:0] XIP_MODE,
    input wire [5:0] XIP_ENABLE,
    input wire [7:0] XIP_MODE_QIOR,
    
    // INPUTS FROM QSPI
    input wire QSPI_BUSY,
    input wire QSPI_DONE,
    input wire [DATA_WIDTH-1:0] QSPI_RX_DATA,
    input wire QSPI_RX_DATA_VALID,
    input wire QSPI_ERROR,
    
    // OUTPUTS TO QSPI
    output reg QSPI_START,
    output reg [7:0] QSPI_OPCODE,
    output reg [ADDR_WIDTH-1:0] QSPI_ADDRESS,
    output reg [DATA_WIDTH-1:0] QSPI_TX_DATA,
    output reg [4:0] QSPI_DUMMY,
    output reg [1:0] QSPI_MODE, 
    output reg [5:0] QSPI_ENABLE, 
    output reg [7:0] QSPI_MODE_QIOR,
    output reg QSPI_DATA_DIR,  
    
    // OUTPUTS TO INDIRECT COMMAND ENGINE
    output reg IND_BUSY,
    output reg IND_DONE,
    output reg [DATA_WIDTH-1:0] IND_RX_DATA,
    output reg IND_RX_DATA_VALID,
    output reg IND_ERROR,
    output reg IND_FIFO_EN,
    output reg IND_GET_EN,
    
    // OUTPUTS TO XIP
    output reg XIP_BUSY,
    output reg XIP_DONE,
    output reg [DATA_WIDTH-1:0] XIP_RX_DATA,
    output reg XIP_RX_DATA_VALID,
    output reg XIP_ERROR,
    output reg XIP_FIFO_EN,
    output reg XIP_GET_EN
);

    // STATE REGISTER DECLARATION
    reg [2:0] PS, NS;
    
    
    // STATE DECLARATION
    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] IND_GOT = 3'b001;
    localparam [2:0] XIP_GOT = 3'b010;
    localparam [2:0] IND_GOING = 3'b011;
    localparam [2:0] XIP_GOING = 3'b100;
    
    
    // PRESENT STATE LOGIC
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PS <= IDLE;
        end
        else begin
            PS <= NS;
        end
    end
    
    // NEXT STATE LOGIC
    always @(*) begin
        case(PS)
            IDLE : begin
                if(IND_START && !QSPI_BUSY) NS = IND_GOT;
                else if(XIP_START && !QSPI_BUSY) NS = XIP_GOT; 
                else NS = IDLE;
            end

            IND_GOT : begin
                NS = IND_GOING;
            end
            XIP_GOT : begin
                NS = XIP_GOING;
            end
            IND_GOING : begin
                if(QSPI_DONE || QSPI_ERROR) NS = IDLE;
                else NS = IND_GOING;
            end
            XIP_GOING : begin
                if(QSPI_DONE || QSPI_ERROR) NS = IDLE;
                else NS = XIP_GOING;
            end
            default : NS = IDLE;
        endcase
    end
    
    // OUTPUT LOGIC
    always @(*) begin
        QSPI_START = 0;
        IND_FIFO_EN = 0;
        IND_GET_EN = 0;
        XIP_FIFO_EN = 0;
        XIP_GET_EN = 0;
        case(PS)
            IDLE : begin
                if(IND_START && !QSPI_BUSY) IND_FIFO_EN = 1;
                else if(XIP_START && !QSPI_BUSY) XIP_FIFO_EN = 1;
                QSPI_START = 0;
                QSPI_OPCODE = 0;
                QSPI_ADDRESS = 0;
                QSPI_MODE = 0;
                QSPI_DUMMY = 0;
                QSPI_TX_DATA = 0;
                QSPI_DATA_DIR = 0;
                QSPI_MODE_QIOR = 0;
                QSPI_ENABLE = 0;
                
                IND_BUSY = 0;
                IND_DONE = 1;
                IND_RX_DATA = 0;
                IND_RX_DATA_VALID = 0;
                IND_ERROR = 0; 
                               
                XIP_BUSY = 0;
                XIP_DONE = 1;
                XIP_RX_DATA = 0;
                XIP_RX_DATA_VALID = 0;
                XIP_ERROR = 0;                
            end
            IND_GOT : begin
                QSPI_START = 1;
                QSPI_OPCODE = IND_OPCODE;
                QSPI_ADDRESS = IND_ADDRESS;
                QSPI_MODE = IND_MODE;
                QSPI_DUMMY = IND_DUMMY;
                QSPI_TX_DATA = IND_TX_DATA;
                QSPI_DATA_DIR = IND_DATA_DIR;
                QSPI_MODE_QIOR = 0;
                QSPI_ENABLE = IND_ENABLE;
                
                IND_GET_EN = 0;
                IND_RX_DATA = QSPI_RX_DATA;
                IND_RX_DATA_VALID = QSPI_RX_DATA_VALID;
                IND_ERROR = QSPI_ERROR;                    
                IND_BUSY = QSPI_BUSY;
                IND_DONE = QSPI_DONE;
                IND_ERROR = QSPI_ERROR;
                
                XIP_GET_EN = 0;
                XIP_BUSY = 1;
                XIP_DONE = 0;
                XIP_RX_DATA = 0;
                XIP_RX_DATA_VALID = 0;
                XIP_ERROR = 0;             
            end
            XIP_GOT : begin
                QSPI_START = 1;
                QSPI_OPCODE = XIP_OPCODE;
                QSPI_ADDRESS = XIP_ADDRESS;
                QSPI_MODE = XIP_MODE;
                QSPI_DUMMY = XIP_DUMMY;
                QSPI_TX_DATA = 0;
                QSPI_ENABLE = XIP_ENABLE;
                QSPI_MODE_QIOR = XIP_MODE_QIOR;
                QSPI_DATA_DIR = 0;
                
                
                IND_GET_EN = 0;
                IND_BUSY = 1;
                IND_DONE = 0;
                IND_RX_DATA = 0;
                IND_RX_DATA_VALID = 0;
                IND_ERROR = 0;
                
                XIP_GET_EN = 0;
                XIP_RX_DATA = QSPI_RX_DATA;
                XIP_RX_DATA_VALID = QSPI_RX_DATA_VALID;
                XIP_ERROR = QSPI_ERROR;                 
                XIP_BUSY = QSPI_BUSY;
                XIP_DONE = QSPI_DONE;
            end
            IND_GOING : begin
                QSPI_OPCODE = IND_OPCODE;
                QSPI_ADDRESS = IND_ADDRESS;
                QSPI_MODE = IND_MODE;
                QSPI_DUMMY = IND_DUMMY;
                QSPI_TX_DATA = IND_TX_DATA;
                QSPI_DATA_DIR = IND_DATA_DIR;
                QSPI_MODE_QIOR = 0;
                QSPI_ENABLE = IND_ENABLE;
                
                if(QSPI_RX_DATA_VALID || QSPI_ERROR) begin
                    IND_GET_EN = 1;
                    IND_RX_DATA = QSPI_RX_DATA;
                    IND_RX_DATA_VALID = 1;
                    IND_ERROR = QSPI_ERROR;                    
                end
                else begin
                    IND_RX_DATA = 0;
                    IND_RX_DATA_VALID = 0;
                    IND_ERROR = 1;
                end
                IND_BUSY = QSPI_BUSY;
                IND_DONE = QSPI_DONE;
                IND_ERROR = QSPI_ERROR;
                
                XIP_GET_EN = 0;
                XIP_BUSY = 1;
                XIP_DONE = 0;
                XIP_RX_DATA = 0;
                XIP_RX_DATA_VALID = 0;
                XIP_ERROR = 0;
            end
            XIP_GOING : begin
                QSPI_OPCODE = XIP_OPCODE;
                QSPI_ADDRESS = XIP_ADDRESS;
                QSPI_MODE = XIP_MODE;
                QSPI_DUMMY = XIP_DUMMY;
                QSPI_TX_DATA = 0;
                QSPI_ENABLE = XIP_ENABLE;
                QSPI_MODE_QIOR = XIP_MODE_QIOR;
                QSPI_DATA_DIR = 0;
                
                
                IND_GET_EN = 0;
                IND_BUSY = 1;
                IND_DONE = 0;
                IND_RX_DATA = 0;
                IND_RX_DATA_VALID = 0;
                IND_ERROR = 0;
                
                if(QSPI_RX_DATA_VALID || QSPI_ERROR) begin
                    XIP_GET_EN = 1;
                    XIP_RX_DATA = QSPI_RX_DATA;
                    XIP_RX_DATA_VALID = 1;
                    XIP_ERROR = QSPI_ERROR;                 
                end
                else begin
                    XIP_RX_DATA = 0;
                    XIP_RX_DATA_VALID = 0;
                    XIP_ERROR = 0;
                end
                XIP_BUSY = QSPI_BUSY;
                XIP_DONE = QSPI_DONE;

            end
            default : begin
                QSPI_START = 0;
                QSPI_OPCODE = 0;
                QSPI_ADDRESS = 0;
                QSPI_MODE = 0;
                QSPI_DUMMY = 0;
                QSPI_TX_DATA = 0;
                QSPI_DATA_DIR = 0;
                QSPI_MODE_QIOR = 0;
                QSPI_ENABLE = 0;
                
                IND_GET_EN = 0;
                IND_BUSY = 0;
                IND_DONE = 1;
                IND_RX_DATA = 0;
                IND_RX_DATA_VALID = 0;
                IND_ERROR = 0;
                
                XIP_GET_EN = 0;
                XIP_BUSY = 0;
                XIP_DONE = 1;
                XIP_RX_DATA = 0;
                XIP_RX_DATA_VALID = 0;
                XIP_ERROR = 0;              

                IND_RX_DATA_VALID = 0;
                IND_ERROR = 0;
                XIP_RX_DATA_VALID = 0;
                XIP_RX_DATA = 0;
                IND_RX_DATA = 0;
            end
        endcase
    end
    
endmodule

