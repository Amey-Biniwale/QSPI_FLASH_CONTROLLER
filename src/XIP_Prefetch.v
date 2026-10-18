`default_nettype none

`define WORD_OFFSET $clog2(LINE_SIZE)
`define BYTE_OFFSET $clog2(DATA_BYTES)

module XIP_Prefetch #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter LINE_SIZE = 4, // NUMBER OF DATA WIDTH WORDS IN THE CACHE
    parameter DATA_BYTES = DATA_WIDTH / 8,
    parameter ADDR_BYTES = 3
)(
    // CLOCK AND RESET
    input wire HCLK,
    input wire HRESETn,
    
    // INPUTS FROM AHB
    input wire [ADDR_WIDTH-1:0] REQ_ADDR,
    input wire REQ_START,
    
    // INPUTS FROM QSPI
    input wire BUSY,
    input wire ERROR,
    input wire FIFO_EMPTY,
    
    input wire [DATA_WIDTH-1:0] RET_DATA,
    
    // OUTPUTS TO THE QSPI
    output reg START,
    output reg [76:0] OUT_CTRL,    // {OPCODE ADDRESS_LENGTH ADDRESS MODE DUMMY DATA_LENGTH LINE_WIDTH ENABLE}
    output reg FIFO_RD_EN,
    output reg FLUSH,
    
    // OUTPUTS TO THE AHB
    output reg [DATA_WIDTH-1:0] AHB_DATA,
    output reg AHB_DATA_VALID,
    output reg AHB_ERROR
    );
    
    reg VALID;
    reg [DATA_WIDTH-1:0] CACHE [0:LINE_SIZE-1];
    reg [ADDR_WIDTH-1:(`WORD_OFFSET + `BYTE_OFFSET)] TAG;
    
    reg [ADDR_WIDTH-1:0] TEMP_REQ;
    reg [DATA_WIDTH-1:0] TEMP_RET;
    
    reg [2:0] PS, NS;
    
    localparam IDLE = 3'd0;
    localparam CACHE_CHECK = 3'd1;
    localparam FETCH = 3'd2;
    localparam WAIT = 3'd3;
    localparam FIFO_WAIT = 3'd4;
    
    reg DATA_DONE;
    
    integer i;
    reg [`WORD_OFFSET:0] count;
    reg line_done;
    wire [8:0] DATA_LENGTH;
    wire [2:0] ADDR_LENGTH;
    
    assign ADDR_LENGTH = ADDR_BYTES;
    
    assign DATA_LENGTH = DATA_BYTES * LINE_SIZE;
    
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            PS <= IDLE;
        end
        else begin
            PS <= NS;
        end
    end
    
    always @(*) begin
        case(PS)
            IDLE : begin
                NS = REQ_START ? CACHE_CHECK : IDLE;
            end
            CACHE_CHECK : begin
                NS = VALID && TEMP_REQ[ADDR_WIDTH-1:(`WORD_OFFSET + `BYTE_OFFSET)] == TAG ? IDLE : FETCH;
            end
            FETCH : begin
                if(ERROR) NS = IDLE;
                else if(line_done) NS = IDLE;
                else if(!line_done) NS = WAIT;
                else NS = FETCH;
            end
            WAIT : begin
                if(ERROR) NS = IDLE;
                else if(DATA_DONE) NS = FETCH;
                else if(FIFO_RD_EN) NS = FIFO_WAIT;
                else NS = WAIT;
            end
            FIFO_WAIT : begin
                if(ERROR) NS = IDLE;
                else NS = WAIT;
            end
        endcase
    end
    
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            VALID <= 0;
            for(i = 0; i < LINE_SIZE; i = i + 1) begin
                CACHE[i] <= 0;
            end
           
            TAG <= 0;
            DATA_DONE <= 0;
            line_done <= 0;
            
            START <= 0;
            OUT_CTRL <= 0;
            
            FIFO_RD_EN <= 0;
            
            FLUSH <= 0;
            
            AHB_DATA <= 0;
            AHB_DATA_VALID <= 0;
            AHB_ERROR <= 0;
            
            TEMP_REQ  <= 0;
            TEMP_RET <= 0;
            
            count <= 0;
        end
        else begin
            FIFO_RD_EN <= 0;
            AHB_DATA_VALID <= 0;
            DATA_DONE <= 0;
            AHB_ERROR <= 0;
            FLUSH <= 0;
            
            if(ERROR) FLUSH <= 1;
            case(PS)
                IDLE : begin
                    OUT_CTRL <= 0;
                    if(REQ_START) TEMP_REQ <= REQ_ADDR;
                end
                CACHE_CHECK : begin
                    if(VALID && TEMP_REQ[ADDR_WIDTH-1:(`WORD_OFFSET + `BYTE_OFFSET)] == TAG) begin
                        AHB_DATA <= CACHE[TEMP_REQ[(`WORD_OFFSET + `BYTE_OFFSET)-1:`BYTE_OFFSET]];
                        AHB_DATA_VALID <= 1;
                    end
                end
                FETCH : begin
                    if(ERROR) begin
                        AHB_ERROR <= 1;
                        VALID <= 0;
                        line_done <= 0;
                        count <= 0;
                    end
                    else if(line_done) begin
                        AHB_DATA <= TEMP_RET;
                        AHB_DATA_VALID <= 1;
                        VALID <= 1;
                        TAG <= TEMP_REQ[ADDR_WIDTH-1:(`WORD_OFFSET + `BYTE_OFFSET)];
                        count <= 0;
                        line_done <= 0;
                    end
                    else begin
                        line_done <= 0;
                        count <= 0;
                        START <= ~START;
                        OUT_CTRL <= {8'hEB, ADDR_LENGTH, {TEMP_REQ[ADDR_WIDTH-1:(`WORD_OFFSET + `BYTE_OFFSET)],{(`WORD_OFFSET + `BYTE_OFFSET){1'b0}}, 8'hFF, 5'd4, DATA_LENGTH, 8'h2A, 4'b1101}};
                    end
                end
                WAIT : begin
                    if(ERROR) begin
                        AHB_ERROR <= 1; 
                        VALID <= 0; 
                        count <= 0;
                        line_done <= 0;
                    end
                    else if(!BUSY) begin
                        if(count < LINE_SIZE) begin
                            if(!FIFO_EMPTY && !FIFO_RD_EN) FIFO_RD_EN <= 1;
                        end
                        else begin
                            line_done <= 1;
                            DATA_DONE <= 1;
                        end
                    end
                end
                FIFO_WAIT : begin
                    if(ERROR) begin
                        AHB_ERROR <= 1;
                        count <= 0;
                        VALID <= 0;
                        line_done <= 0;
                    end
                    else begin
                        CACHE[count] <= RET_DATA;
                        if(count == TEMP_REQ[`WORD_OFFSET+`BYTE_OFFSET-1:`BYTE_OFFSET]) TEMP_RET <= RET_DATA;
                        count <= count + 1;
                    end
                end
            endcase
        end
    end
endmodule

