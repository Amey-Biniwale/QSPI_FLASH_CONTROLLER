`default_nettype none

module APB_Slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // APB CLOCK AND RESET
    input wire PCLK,
    input wire PRESETn,
    
    // CONTROL SIGNALS FROM APB
    input wire PENABLE,
    input wire PSEL,
    input wire PWRITE,
    
    // DATA FROM CPU
    input wire [ADDR_WIDTH-1:0] PADDR,
    input wire [DATA_WIDTH-1:0] PWDATA,
    
    // INPUTS FROM THE QSPI
    input wire BUSY,
    input wire ERROR,
    input wire FIFO_FULL,
    input wire FIFO_EMPTY,
    
    input wire [DATA_WIDTH-1:0] RET_DATA,
    
    // OUTPUT TO THE APB
    output reg PSLVERR,
    output reg PREADY,
    output reg [DATA_WIDTH-1:0] PRDATA,                       
    
    // OUTPUT TO THE SCLK DOMAIN
    output reg [DATA_WIDTH-1:0] OUT_FIFO,
    output reg FIFO_WR_EN,
    output reg FIFO_RD_EN,
    output reg FLUSH,
    
    output reg START,
    output wire [76:0] OUT_CTRL // {OPCODE ADDRESS_LENGTH ADDRESS MODE DUMMY DATA_LENGTH LINE_WIDTH ENABLE}
    );
    
    reg ERR;
    reg STR;
    
    reg [7:0] OPCODE;
    reg [2:0] ADDR_LEN;
    reg [31:0] ADDR;
    reg [7:0] MODE;
    reg [4:0] DUMMY;
    reg [8:0] DATA_LENGTH; // MAX DATA LENGTH OF 256 BYTES
    reg [7:0] LINE_WIDTH; // OPCODE : 7-6, ADDRESS : 5-4, MODE : 3-2, DATA : 1-0
    reg [3:0] ENABLE; // 3 : ADDRESS, 2 : MODE, 1 : DATA_TX, 0 : DATA_RX
    
    localparam EN_ADDR = 'h00;
    localparam OP_ADDR = 'h04;
    localparam AL_ADDR = 'h0C;
    localparam ADDR_ADDR = 'h10;
    localparam MODE_ADDR = 'h30;
    localparam DUMMY_ADDR = 'h38;
    localparam DL_ADDR = 'h3D;
    localparam LW_ADDR = 'h46;
    localparam DATA_ADDR = 'h4E;
    localparam START_ADDR = 'h6E;
    localparam STATUS_ADDR = 'h6F;
    
    reg  [1:0] count;
    
    assign OUT_CTRL = {OPCODE, ADDR_LEN, ADDR, MODE, DUMMY, DATA_LENGTH, LINE_WIDTH, ENABLE};
        

    
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            OPCODE <= 0;
            ADDR_LEN <= 0;
            ADDR <= 0;
            MODE <= 0;
            DUMMY <= 0;
            DATA_LENGTH <= 0;
            LINE_WIDTH <= 0;
            ENABLE <= 0;
            
            OUT_FIFO <= 0;
            FIFO_WR_EN <= 0;
            FIFO_RD_EN <= 0;
            START <= 0;
            
            PREADY <= 0;
            PRDATA <= 0;
            PSLVERR <= 0;
            FLUSH <= 0;
            
            count <= 0;
            
            ERR <= 0;
            STR <= 0;
        end
        else begin
            FIFO_WR_EN <= 0;
            PSLVERR <= 0;
            PREADY <= 0;
            FLUSH <= 0;
            FIFO_RD_EN <= 0;
            if(ERROR) begin
                FLUSH <= 1;
                ERR <= 1;
            end
            if(BUSY) begin
                STR <= 0;
            end
            if(PSEL && PENABLE && !PREADY) begin
                if(PWRITE) begin
                    if(!BUSY && !STR) begin
                        case(PADDR)
                            EN_ADDR : begin
                                ENABLE <= PWDATA;
                                PREADY <= 1;
                            end
                            OP_ADDR : begin
                                OPCODE <= PWDATA;
                                PREADY <= 1;
                            end
                            AL_ADDR : begin
                                ADDR_LEN <= PWDATA;
                                PREADY <= 1;
                            end
                            ADDR_ADDR : begin
                                ADDR <= PWDATA;
                                PREADY <= 1;
                            end
                            MODE_ADDR : begin
                                MODE <= PWDATA;
                                PREADY <= 1;
                            end
                            DUMMY_ADDR : begin
                                DUMMY <= PWDATA;
                                PREADY <= 1;
                            end
                            DL_ADDR : begin
                                DATA_LENGTH <= PWDATA;
                                PREADY <= 1;
                            end
                            LW_ADDR : begin
                                LINE_WIDTH <= PWDATA;
                                PREADY <= 1;
                            end
                            DATA_ADDR : begin
                                if(!FIFO_FULL) begin
                                    OUT_FIFO <= PWDATA;
                                    FIFO_WR_EN <= 1;
                                    PREADY <= 1;
                                end
                                else begin
                                    PREADY <= 1;
                                    PSLVERR <= 1;
                                end
                            end
                            START_ADDR : begin
                                    if(FIFO_EMPTY) begin
                                        START <= ~START;
                                        PREADY <= 1;
                                        STR <= 1;
                                        ERR <= 0;
                                    end
                                    else begin
                                        PSLVERR <= 1;
                                        PREADY <= 1;
                                    end
                            end
                            default : begin
                                PREADY <= 1;
                                PSLVERR <= 1;
                            end
                        endcase
                    end
                end
                else begin
                    case(PADDR)
                        DATA_ADDR : begin
                            if(ERROR) begin
                                PSLVERR <= 1;
                                PREADY  <= 1;
                                count   <= 0;
                            end
                            else case(count)
                                0: begin
                                    if(FIFO_EMPTY) begin
                                        PSLVERR <= 1;
                                        PREADY <= 1;
                                    end
                                    else begin
                                        count <= 2'd1;
                                        FIFO_RD_EN <= 1;
                                     end
                                end
                                1 : begin
                                    count <= 2'd2;
                                end                                             
                                2: begin 
                                    PRDATA <= RET_DATA; 
                                    PREADY <= 1; 
                                    count <= 0; 
                                end    
                                default: count <= 0;
                            endcase 
                        end
                        STATUS_ADDR : begin
                            PRDATA <= {{(DATA_WIDTH-4){1'b0}}, ERR, BUSY | STR, FIFO_FULL, FIFO_EMPTY};
                            PREADY <= 1;
                        end
                        default : begin
                            PREADY <= 1;
                            PSLVERR <= 1;
                        end
                    endcase
                end
            end
        end
    end
    
endmodule

