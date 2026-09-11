`default_nettype none

module QSPI_CONTROLLER #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // CLOCK AND RESET
    input wire SCLK,
    input wire SRESETn,
    
    // INPUTS FROM THE ARBITER
    input wire [7:0] OPCODE,
    input wire [ADDR_WIDTH-1:0] ADDRESS,
    input wire [1:0] MODE,
    input wire [DATA_WIDTH-1:0] TX_DATA,
    input wire [4:0] DUMMY,
    input wire START,
    input wire [5:0] ENABLE,
    input wire [7:0] MODE_QIOR,
    input wire DATA_DIR,
    
    // INPUTS FROM THE PHYSICAL QSPI SHIFT REGISTER MODULE
    input wire PHY_PHASE_DONE,
    input wire PHY_ERROR,
    input wire [DATA_WIDTH-1:0] PHY_RX_DATA,
    
    // INPUT FROM THE FLASH MEMORY
    input wire FLASH_WIP,
    
    // OUTPUTS TO THE PHYSICAL QSPI SHIFT REGISTER MODULE
    output reg PHY_START,
    output reg [7:0] PHY_OPCODE,
    output reg [3:0] PHY_PHASE,
    output reg [1:0] PHY_MODE,
    output reg [7:0] PHY_MODE_QIOR,
    output reg [ADDR_WIDTH-1:0] PHY_ADDRESS,
    output reg [4:0] PHY_DUMMY,
    output reg [DATA_WIDTH-1:0] PHY_TX_DATA,
    
    // OUTPUTS TO THE ARBITER
    output reg DONE,
    output reg BUSY,
    output reg [DATA_WIDTH-1:0] RX_DATA,
    output reg RX_VALID,
    output reg ERROR
    );
    
    
    // STATE DECLARATION
    localparam ST_IDLE = 4'b0000;
    localparam ST_OPCODE = 4'b0001;
    localparam ST_ADDRESS = 4'b0010;
    localparam ST_MODE = 4'b0011;
    localparam ST_DUMMY = 4'b0100;
    localparam ST_DATA_TX = 4'b0101;
    localparam ST_DATA_RX = 4'b0110;
    localparam ST_DATA_RX_CAPTURE = 4'b0111;
    localparam ST_DONE = 4'b1000;
    localparam ST_SE = 4'b1001;
    localparam ST_START = 4'b1010;
    
    // STATE REGISTER DECLARATION
    reg [3:0] PS, NS;
    
    // PRESENT STATE LOGIC
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PS <= ST_IDLE;
        end
        else begin
            PS <= NS;
        end
    end
    
    // NEXT STATE LOGIC
    always @(*) begin
        case(PS)
            ST_IDLE : NS = START ? ST_START : ST_IDLE;
            ST_START : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) begin
                        if(ENABLE[0]) NS = ST_OPCODE;
                        else if(ENABLE[1]) NS = ST_ADDRESS;
                        else if(ENABLE[2]) NS = ST_MODE;
                        else if(ENABLE[3]) NS = ST_DUMMY;
                        else if(ENABLE[4]) begin
                            if(DATA_DIR) NS = ST_DATA_TX;
                            else NS = ST_DATA_RX;
                        end
                        else NS = ST_DONE;
                    end
                    else NS = ST_START;
                end
            end
            ST_OPCODE : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) begin
                        if(ENABLE[1]) NS = ST_ADDRESS;
                        else if(ENABLE[2]) NS = ST_MODE;
                        else if(ENABLE[3]) NS = ST_DUMMY;
                        else if(ENABLE[4]) begin
                            if(DATA_DIR) NS = ST_DATA_TX;
                            else NS = ST_DATA_RX;
                        end
                        else NS = ST_DONE;
                    end
                    else NS = ST_OPCODE;
                end
            end
            ST_ADDRESS : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) begin
                        if(ENABLE[2]) NS = ST_MODE;
                        else if(ENABLE[3]) NS = ST_DUMMY;
                        else if(ENABLE[4]) begin
                            if(DATA_DIR) NS = ST_DATA_TX;
                            else NS = ST_DATA_RX;
                        end
                        else NS = ST_DONE;
                    end
                    else NS = ST_ADDRESS;
                end
            end
            ST_MODE : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) begin
                        if(ENABLE[3]) NS = ST_DUMMY;
                        else if(ENABLE[4]) begin
                            if(DATA_DIR) NS = ST_DATA_TX;
                            else NS = ST_DATA_RX;
                        end
                        else NS = ST_DONE;
                    end
                    else NS = ST_MODE;
                end
            end
            ST_DUMMY : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) begin
                        if(ENABLE[4]) begin
                            if(DATA_DIR) NS = ST_DATA_TX;
                            else NS = ST_DATA_RX;
                        end
                        else if(ENABLE[5]) NS = ST_SE;
                        else NS = ST_DONE;
                    end
                    else NS = ST_DUMMY;
                end
            end
            ST_DATA_TX : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) NS = ST_DONE;
                    else NS = ST_DATA_TX;
                end
            end
            ST_DATA_RX : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(PHY_PHASE_DONE) NS = ST_DATA_RX_CAPTURE;
                    else NS = ST_DATA_RX;
                end
            end
            ST_DATA_RX_CAPTURE : NS = ST_DONE;
            ST_SE : begin
                if(PHY_ERROR) NS = ST_DONE;
                else begin
                    if(!FLASH_WIP) NS = ST_DONE;
                    else NS = ST_SE;
                end
            end
            ST_DONE : NS = ST_IDLE;
            default : NS = ST_IDLE;
        endcase
    end
    
    // OUTPUT LOGIC
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PHY_START <= 0;
            PHY_OPCODE <= 0;
            PHY_ADDRESS <= 0;
            PHY_DUMMY <= 0;
            PHY_MODE <= 0;
            PHY_MODE_QIOR <= 0;
            PHY_TX_DATA <= 0;
            PHY_PHASE <= ST_IDLE;
            
            DONE <= 1;
            BUSY <= 0;
            RX_DATA <= 0;
            RX_VALID <= 0;
            ERROR <= 0;
        end
        else begin
           PHY_START <= 0;
           DONE <= 0;
           RX_VALID <= 0;
           case(PS)
            ST_IDLE : begin
                BUSY <= 0;
                ERROR <= 0;
                if(START) begin
                    PHY_OPCODE <= OPCODE;
                    PHY_MODE <= MODE;
                    PHY_ADDRESS <= ADDRESS;
                    PHY_DUMMY <= DUMMY;
                    PHY_TX_DATA <= TX_DATA;
                    PHY_MODE_QIOR <= MODE_QIOR;
                    
                    PHY_PHASE <= ST_OPCODE;
                    PHY_START <= 1;
                    ERROR <= 0;
                    BUSY <= 1;
                end
            end
            ST_START : begin
                PHY_PHASE <= ST_IDLE;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_OPCODE : begin
                PHY_PHASE <= ST_OPCODE;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_ADDRESS : begin
                PHY_PHASE <= ST_ADDRESS;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_DUMMY : begin
                PHY_PHASE <= ST_DUMMY;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_MODE : begin
                PHY_PHASE <= ST_MODE;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_DATA_TX : begin
                PHY_PHASE <= ST_DATA_TX;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_DATA_RX : begin
                PHY_PHASE <= ST_DATA_RX;
                if(PHY_ERROR) ERROR <= 1;
            end
            ST_DATA_RX_CAPTURE : begin
                RX_DATA <= PHY_RX_DATA;
                RX_VALID <= 1;
                PHY_PHASE <= ST_IDLE;
            end
            ST_DONE : begin
                PHY_PHASE <= ST_IDLE;
                BUSY <= 0;
                DONE <= 1;
            end
            ST_SE : begin
                PHY_PHASE <= ST_OPCODE;
                PHY_OPCODE <= 8'h05;
            end
            default : begin
                PHY_PHASE <= ST_IDLE;
                BUSY <= 0;
                ERROR <= 0;
            end
           endcase 
        end
    end
endmodule

