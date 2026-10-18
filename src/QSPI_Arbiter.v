`default_nettype none

module QSPI_Arbiter (
    // CLOCK AND RESET
    input wire SCLK,
    input wire SRESETn,
    
    // INDIRECT INPUTS
    input wire PSTART,
    input wire [76:0] PCTRL,
    
    // XIP INPUTS
    input wire HSTART,
    input wire [76:0] HCTRL,
    
    // QSPI INPUTS
    input wire BUSY,
    input wire ERROR,
    
        
    // OUTPUT TO QSPI
    output reg START,
    output reg OWNER,
    output reg [76:0] OUT_CTRL,
    
    // OUTPUT TO THE FIFOS
    output reg FLUSH_APB,
    output reg FLUSH_AHB,
    
    
    // OUTPUT TO PCLK
    output reg PBUSY,
    output reg PERROR,

        
    // OUTPUT TO HCLK
    output reg HBUSY,
    output reg HERROR
    
    );
    
    reg [1:0] PS, NS;
    
    reg PSTART_PREV, HSTART_PREV, BUSY_PREV;
    
    reg GOT_IND, GOT_XIP;
    
    localparam IDLE = 2'd0;
    localparam INDIRECT = 2'd1;
    localparam XIP = 2'd2;
    
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PSTART_PREV <= 0;
            HSTART_PREV <= 0;
            BUSY_PREV <= 0;
        end
        else begin
            PSTART_PREV <= PSTART;
            HSTART_PREV <= HSTART;
            BUSY_PREV <= BUSY;
        end
    end 
    
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            PS <= IDLE;
        end
        else begin
            PS <= NS;
        end
    end
    
    always @(*) begin
        case(PS)
            IDLE : begin
                if(GOT_IND) NS = INDIRECT;
                else if(GOT_XIP) NS = XIP;
                else if(PSTART != PSTART_PREV) NS = INDIRECT;
                else if(HSTART != HSTART_PREV) NS = XIP;
                else NS = IDLE;
            end
            INDIRECT : begin
                if(!BUSY && BUSY_PREV) begin
                    NS = IDLE;
                end
                else NS = INDIRECT;
            end
            XIP : begin
                if(!BUSY && BUSY_PREV) begin
                    NS = IDLE;
                end
                else NS = XIP;
            end
            default : begin
                NS = IDLE;
            end
        endcase
    end
    
    always @(posedge SCLK or negedge SRESETn) begin
        if(!SRESETn) begin
            START <= 0;
            OWNER <= 0;
            OUT_CTRL <= 0;
            
            FLUSH_APB <= 0;
            FLUSH_AHB <= 0;
            
            PBUSY <= 0;
            PERROR <= 0;
            
            HBUSY <= 0;
            HERROR <= 0;
            
            GOT_IND <= 0;
            GOT_XIP <= 0;
        end
        else begin
            FLUSH_APB <= 0;
            FLUSH_AHB <= 0;
            case(PS)
                IDLE : begin
                    GOT_IND <= 0;
                    GOT_XIP <= 0;
                    
                    OWNER <= 0;
                    
                    START <= 0;
                    if((PSTART != PSTART_PREV) || GOT_IND) begin
                        START <= 1;
                        OUT_CTRL <= PCTRL;
                        if(HSTART != HSTART_PREV || GOT_XIP) GOT_XIP <= 1;
                    end
                    else if((HSTART != HSTART_PREV) || GOT_XIP) begin
                        START <= 1;
                        OUT_CTRL <= HCTRL;
                        if(PSTART != PSTART_PREV || GOT_IND) GOT_IND <= 1;
                    end
                    
                    PBUSY <= 0;
                    PERROR <= 0;
                    
                    HBUSY <= 0;
                    HERROR <= 0;
                    
                end
                INDIRECT : begin
                    START <= 0;
                    OWNER <= 0;
                    
                    if(ERROR) FLUSH_APB <= 1;
                                        
                    PBUSY <= 1;
                    PERROR <= ERROR;
                    
                    HBUSY <= 0;
                    HERROR <= 0;
                    
                    if(HSTART != HSTART_PREV) GOT_XIP <= 1;
                end
                XIP : begin
                    START <= 0;
                    OWNER <= 1;
                    
                    if(ERROR) FLUSH_AHB <= 1;
                    
                    HBUSY <= 1;
                    HERROR <= ERROR;
                    
                    PBUSY <= 0;
                    PERROR <= 0;
                    
                    
                    if(PSTART != PSTART_PREV) GOT_IND <= 1;
                end
                default : begin
                    START <= 0;
                    OUT_CTRL <= 0;
                    
                    FLUSH_APB <= 0;
                    FLUSH_AHB <= 0;
                    
                    PBUSY <= 0;
                    PERROR <= 0;
                    
                    HBUSY <= 0;
                    HERROR <= 0;
                    
                    GOT_IND <= 0;
                    GOT_XIP <= 0;
                end
            endcase 
        end
    end
endmodule

