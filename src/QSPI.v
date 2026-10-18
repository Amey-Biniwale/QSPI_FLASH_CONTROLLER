`default_nettype none

`define QUAD 2
`define DUAL 1
`define SINGLE 0

module QSPI #(
    parameter DATA_WIDTH = 32,
    parameter BYTES = DATA_WIDTH/8
)(
    // CLOCK AND ACTIVE LOW RESET
    input wire SCLK,
    input wire SRESETn,
    
    // INPUTS FROM THE ARBITER
    input wire START,
    input wire OWNER, // 1 : XIP, 0 : IND
    input wire [76:0] OUT_CTRL, // OPCODE : 76-69 ADDR_LEN : 68-66 ADDR : 65-34 MODE : 33-26 DUMMY : 25-21 DATA_LEN : 20-12 LINE_WIDTH : 11-4 ENABLE : 3-0
    
    // INPUT FROM THE PCLK
    input wire [DATA_WIDTH-1:0] POUT_FIFO,
    
    // OUTPUT TO THE ARBITER
    output reg BUSY,
    output reg ERROR,
    
    output reg CLK_EN,
    
    // OUTPUT TO THE PCLK
    output reg PFIFO_RD_EN,
    output reg PFIFO_WR_EN,
    
    output reg [DATA_WIDTH-1:0] PRET_DATA,
    
    // OUTPUT TO THE HCLK
    output reg HFIFO_WR_EN,
    
    output reg [DATA_WIDTH-1:0] HRET_DATA,
    
    // INPUTS TO THE FLASH
    input wire [3:0] io_in,
    
    // OUTPUT TO THE FLASH
    output wire [3:0] io_out,
    output reg CSn
    );
    
    reg [7:0] OPCODE;
    reg [2:0] ADDR_LEN;
    reg [31:0] ADDR;
    reg [7:0] MODE;
    reg [4:0] DUMMY;
    reg [8:0] DATA_LEN;
    reg [7:0] LINE_WIDTH;
    reg [3:0] ENABLE;
    
    // ENABLE : {ADDRESS MODE DATA_TX DATA_RX}
    // LINE_WIDTH : {OPCODE : 7-6, ADDRESS : 5-4, MODE : 3-2, DATA : 1-0}
    
    reg [3:0] PS, NS;
    
    localparam ST_IDLE = 4'd0;
    localparam ST_CS_ASSERT = 4'd1;
    localparam ST_OPCODE = 4'd2;
    localparam ST_ADDRESS = 4'd3;
    localparam ST_MODE = 4'd4;
    localparam ST_DUMMY = 4'd5;
    localparam ST_TX_DATA = 4'd6;
    localparam ST_RX_DATA = 4'd7;
    localparam ST_CS_DEASSERT = 4'd8;
    localparam ST_DONE = 4'd9;
    localparam ST_SHIFT = 4'd10;
    localparam ST_FIFO_WAIT = 4'd11;
    localparam ST_FIFO_SEND = 4'd12;
    
    // OUTPUT ENABLE
    reg [3:0] io_oe;
    // TEMPERORY OUTPUT REGISTER
    reg [3:0] io_o;
    
    assign io_out[3] = io_oe[3] ? io_o[3] : 1'bz;
    assign io_out[2] = io_oe[2] ? io_o[2] : 1'bz;
    assign io_out[1] = io_oe[1] ? io_o[1] : 1'bz;
    assign io_out[0] = io_oe[0] ? io_o[0] : 1'bz;
    
    // TRANSFER DONE
    reg trans_done;
    // STORING PREVIOUS STATE VALUE
    reg [3:0] PREV_STATE;
    
    // COUNT FOR DUMMY CYCLES AND CS DEASSERTION
    reg [4:0] count;
    reg cnt;
    
    // COUNT FOR NUMBER OF BITS TRANSFERRED
    reg [3:0] bit_count;
    
    // COUNT FOR NUMBER OF BYTES TRANSFERRED
    reg [2:0] byte_count;
    
    // COUNT FOR NUMBER OF DATA LENGTH WORDS TRANSFERRED
    reg [8:0] data_count;
    
    // TEMP REG FOR ST_SHIFT
    reg [31:0] SHIFT_DATA; // DATA WHICH WILL BE SHIFTED
    reg [DATA_WIDTH-1:0] GATHER_DATA;
    reg [1:0] LW; // LINE WIDTH
    reg [2:0] BL; // BYTE LENGTH Eg. 1 for opcode, ADDR_LEN for address BYTES for data
    
    wire [8:0] REM;
    reg req;
    
    assign REM = DATA_LEN - data_count;
    

    
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PS <= ST_IDLE;
        end
        else begin
            PS <= NS;
        end
    end
    
    always @(*) begin
        case(PS)
            ST_IDLE : begin
                NS = START ? ST_CS_ASSERT : ST_IDLE;
            end
            ST_CS_ASSERT : begin
                NS = ST_OPCODE;
            end
            ST_OPCODE : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(trans_done) begin
                    if(ENABLE[3]) NS = ST_ADDRESS;
                    else if(ENABLE[2]) NS = ST_MODE;
                    else if(DUMMY > 0) NS = ST_DUMMY;
                    else if(ENABLE[1]) NS = ST_TX_DATA;
                    else if(ENABLE[0]) NS = ST_RX_DATA;
                    else NS = ST_CS_DEASSERT;
                end
                else begin
                    NS = ST_SHIFT;
                end
            end
            ST_ADDRESS : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(trans_done) begin
                    if(ENABLE[2]) NS = ST_MODE;
                    else if(DUMMY > 0) NS = ST_DUMMY;
                    else if(ENABLE[1]) NS = ST_TX_DATA;
                    else if(ENABLE[0]) NS = ST_RX_DATA;
                    else NS = ST_CS_DEASSERT;
                end
                else begin
                    NS = ST_SHIFT;
                end
            end
            ST_MODE : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(trans_done) begin
                    if(DUMMY > 0) NS = ST_DUMMY;
                    else if(ENABLE[1]) NS = ST_TX_DATA;
                    else if(ENABLE[0]) NS = ST_RX_DATA;
                    else NS = ST_CS_DEASSERT;
                end
                else begin
                    NS = ST_SHIFT;
                end
            end
            ST_DUMMY : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(count == DUMMY - 1) begin
                    if(ENABLE[1]) NS = ST_TX_DATA;
                    else if(ENABLE[0]) NS = ST_RX_DATA;
                    else NS = ST_CS_DEASSERT;
                end
                else NS = ST_DUMMY;
            end
            ST_TX_DATA : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(trans_done && (data_count >= DATA_LEN)) begin
                    if(ENABLE[0]) NS = ST_RX_DATA;
                    else NS = ST_CS_DEASSERT;
                end
                else begin
                    NS = ST_FIFO_WAIT;
                end
            end
            ST_RX_DATA : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(trans_done && (data_count >= DATA_LEN)) begin
                    NS = ST_CS_DEASSERT;
                end
                else begin
                    NS = ST_FIFO_WAIT;
                end
            end
            ST_CS_DEASSERT : begin
                if(trans_done) NS = ST_DONE;
                else NS = ST_CS_DEASSERT;
            end
            ST_DONE : begin
                NS = ST_IDLE;
            end
            ST_SHIFT : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(byte_count == BL) NS = PREV_STATE;
                else NS = ST_SHIFT;
            end
            ST_FIFO_WAIT : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else if(cnt == 1) NS = ST_SHIFT;
                else NS = ST_FIFO_WAIT;
            end
            ST_FIFO_SEND : begin
                if(ERROR) NS = ST_CS_DEASSERT;
                else NS = ST_RX_DATA;
            end
            default : begin
                NS = ST_IDLE;
            end
        endcase
    end
    
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            OPCODE <= 0;
            ADDR_LEN <= 0;
            ADDR <= 0;
            MODE <= 0;
            DUMMY <= 0;
            DATA_LEN <= 0;
            LINE_WIDTH <= 0;
            ENABLE <= 0;
            
            LW <= 3;
            BL <= 0;
            SHIFT_DATA <= 0;
            GATHER_DATA <= 0;
            io_o <= 0;
            
            BUSY <= 0;
            ERROR <= 0;
            
            PREV_STATE <= 0;
            
            cnt <= 0;
            count <= 0;
            bit_count <= 0;
            byte_count <= 0;
            data_count <= 0;
            
            trans_done <= 0;
            
            CSn <= 1;
            
            HFIFO_WR_EN <= 0;
            PFIFO_WR_EN <= 0;
            PFIFO_RD_EN <= 0;
            
            CLK_EN <= 0;
            
            HRET_DATA <= 0;
            PRET_DATA <= 0;
        end
        else begin
            CLK_EN <= (PS == ST_SHIFT && byte_count != BL && !ERROR) || (PS == ST_DUMMY);
            HFIFO_WR_EN <= 0;
            PFIFO_WR_EN <= 0;
            PFIFO_RD_EN <= 0;
            ERROR <= 0;
            req <= (PS==ST_SHIFT) && (PREV_STATE==ST_FIFO_SEND) && (byte_count != BL);
            case(PS)
                ST_IDLE : begin
                    OPCODE <= 0;
                    ADDR_LEN <= 0;
                    ADDR <= 0;
                    MODE <= 0;
                    DUMMY <= 0;
                    DATA_LEN <= 0;
                    LINE_WIDTH <= 0;
                    ENABLE <= 0;
                    
                    count <= 0;
                    bit_count <= 0;
                    byte_count <= 0;
                    data_count <= 0;
                end
                ST_CS_ASSERT : begin
                    trans_done <= 0;
                    CSn <= 0;
                    BUSY <= 1;
                    OPCODE <= OUT_CTRL[76:69];
                    ADDR_LEN <= OUT_CTRL[68:66];
                    ADDR <= OUT_CTRL[65:34];
                    MODE <= OUT_CTRL[33:26];
                    DUMMY <= OUT_CTRL[25:21];
                    DATA_LEN <= OUT_CTRL[20:12];
                    LINE_WIDTH <= OUT_CTRL[11:4];
                    ENABLE <= OUT_CTRL[3:0];
                end
                ST_OPCODE : begin
                    if(trans_done) begin
                        data_count <= 0;
                    end
                    trans_done <= 0;
                    PREV_STATE <= ST_OPCODE;
                    SHIFT_DATA <= OPCODE;
                    LW <= LINE_WIDTH[7:6];
                    BL <= 2'd1;
                    if(LINE_WIDTH[7:6] != 2'b00) ERROR <= 1;
                end
                ST_ADDRESS : begin
                    if(trans_done) begin
                        data_count <= 0;
                    end
                    trans_done <= 0;
                    PREV_STATE <= ST_ADDRESS;
                    SHIFT_DATA <= ADDR;
                    LW <= LINE_WIDTH[5:4];
                    BL <= ADDR_LEN; 
                    if(ADDR_LEN > 4) ERROR <= 1;
                end
                ST_MODE : begin
                    if(trans_done) begin
                        data_count <= 0;
                    end
                    trans_done <= 0;
                    PREV_STATE <= ST_MODE;
                    SHIFT_DATA <= MODE;
                    LW <= LINE_WIDTH[3:2];
                    BL <= 2'd1;
                end
                ST_DUMMY : begin
                    LW <= 2'd3;
                    trans_done <= 0;
                    if(count == DUMMY - 1) begin
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end
                end
                ST_TX_DATA : begin
                    if(trans_done && data_count >= DATA_LEN) begin
                        data_count <= 0;
                    end
                    else if(!OWNER) PFIFO_RD_EN <= 1;
                    trans_done <= 0;
                    PREV_STATE <= ST_TX_DATA;
                    LW <= LINE_WIDTH[1:0];
                    BL <= REM >= BYTES ? BYTES[2:0] : REM[2:0];
                end
                ST_RX_DATA : begin
                    if(trans_done && data_count >= DATA_LEN) begin
                        data_count <= 0;
                    end
                    trans_done <= 0;
                    PREV_STATE <= ST_FIFO_SEND;
                    LW <= LINE_WIDTH[1:0];
                    BL <= REM >= BYTES ? BYTES[2:0] : REM[2:0];
                end
                ST_CS_DEASSERT : begin
                    LW <= 3;
                    trans_done <= 0;
                    CSn <= 1;
                    if(count == 4) begin
                        trans_done <= 1;
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end
                end
                ST_DONE : begin
                    trans_done <= 0;
                    BUSY <= 0;
                end
                ST_SHIFT : begin
                    trans_done <= 0;
                    if(PREV_STATE == ST_FIFO_SEND) begin
                        case(LW)
                            `SINGLE : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    if(bit_count == 7) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 1;
                                    end
                                end
                            end
                            `DUAL : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    if(bit_count + 2 == 8) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 2;
                                    end
                                end
                            end
                            `QUAD : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    if(bit_count + 4 == 8) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 4;
                                    end
                                end
                            end
                            default : begin
                                ERROR <= 1;
                                bit_count <= 0;
                                byte_count <= 0;
                                data_count <= 0;
                            end
                        endcase
                        if(req) begin
                            case(LW)
                                `SINGLE : GATHER_DATA <= {GATHER_DATA[DATA_WIDTH-2:0], io_in[1]};
                                `DUAL   : GATHER_DATA <= {GATHER_DATA[DATA_WIDTH-3:0], io_in[1:0]};
                                `QUAD   : GATHER_DATA <= {GATHER_DATA[DATA_WIDTH-5:0], io_in[3:0]};
                            endcase 
                        end
                    end
                    else begin
                        case(LW)
                            `SINGLE : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    io_o[0] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - bit_count)];
                                    if(bit_count == 7) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 1;
                                    end
                                end
                            end
                            `DUAL : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    io_o[1] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - bit_count)];
                                    io_o[0] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - (bit_count + 1))];
                                    if(bit_count + 2 == 8) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 2;
                                    end
                                end
                            end
                            `QUAD : begin
                                if(byte_count == BL) begin
                                    trans_done <= 1;
                                    bit_count <= 0;
                                    byte_count <= 0;
                                    data_count <= data_count + byte_count;
                                end
                                else begin
                                    io_o[3] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - bit_count)];
                                    io_o[2] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - (bit_count + 1))];
                                    io_o[1] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - (bit_count + 2))];
                                    io_o[0] <= SHIFT_DATA[(((BL-byte_count) * 8) - 1 - (bit_count + 3))];
                                    if(bit_count + 4 == 8) begin
                                        bit_count <= 0;
                                        byte_count <= byte_count + 1;
                                    end
                                    else begin
                                        bit_count <= bit_count + 4;
                                    end
                                end
                            end
                            default : begin
                                ERROR <= 1;
                                bit_count <= 0;
                                byte_count <= 0;
                                data_count <= 0;
                            end
                        endcase
                    end
                end
                ST_FIFO_WAIT : begin
                    case(cnt)
                        0 : cnt <= 1;
                        1 : begin
                            SHIFT_DATA <= POUT_FIFO;
                            cnt <= 0;
                        end
                    endcase
                end
                ST_FIFO_SEND : begin
                    if(OWNER) begin
                        HFIFO_WR_EN <= 1;
                        HRET_DATA <= GATHER_DATA;
                    end
                    else begin
                        PFIFO_WR_EN <= 1;
                        PRET_DATA <= GATHER_DATA;
                    end
                    GATHER_DATA <= 0;
                end
                default : begin
                    
                end
            endcase
        end
    end
    
    always @(*) begin
        case(LW)
            `SINGLE : begin
                io_oe = 4'b0001;
            end
            `DUAL : begin
                io_oe = 4'b0011;
            end
            `QUAD : begin
                io_oe = 4'b1111;
            end
            3 : begin
                io_oe = 4'b0000;
            end
            default : begin
                io_oe = 4'b0000;
            end
        endcase
        if(PREV_STATE == ST_FIFO_SEND) io_oe = 4'b0000;
    end
    
endmodule

