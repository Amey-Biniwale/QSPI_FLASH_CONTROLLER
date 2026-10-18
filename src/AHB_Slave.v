`default_nettype none

module AHB_Slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // CLOCK AND ACTIVE LOW RESET
    input wire HCLK,
    input wire HRESETn,
    
    // INPUTS FROM THE MASTER
    input wire HSEL,
    input wire [1:0] HTRANS,
    input wire HREADY,
    input wire HWRITE,
    input wire [ADDR_WIDTH-1:0] HADDR,
    
    // INPUTS FROM THE XIP
    input wire [DATA_WIDTH-1:0] RET_DATA,
    input wire RET_DATA_VALID,
    input wire ERROR,
    
    // OUTPUT TO THE MASTER
    output reg HREADYOUT,
    output reg HRESP,
    output reg [DATA_WIDTH-1:0] HRDATA,
    
    // OUTPUT TO THE XIP
    output reg [ADDR_WIDTH-1:0] REQ_ADDR,
    output reg REQ_START
    );
    
    reg [1:0] PS;
    
    localparam IDLE = 2'd0;
    localparam WAIT = 2'd1;
    localparam ERR = 2'd2;
    
    
    
    always @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HREADYOUT <= 1;
            HRESP <= 0;
            HRDATA <= 0;
            
            REQ_ADDR <= 0;
            REQ_START <= 0;
            
            PS <= IDLE;
        end
        else begin
            REQ_START <= 0;
            case(PS)
                IDLE : begin
                    if(HSEL && HTRANS[1] && HREADY) begin
                        if(!HWRITE) begin
                            REQ_START <= 1;
                            REQ_ADDR <= HADDR;
                            HREADYOUT <= 0;
                            HRESP <= 0;
                            PS <= WAIT;
                        end
                        else begin
                            HREADYOUT <= 0;
                            HRESP <= 1;
                            PS <= ERR;
                        end
                    end
                    else begin
                        HRESP <= 0;
                    end
                end
                WAIT : begin
                    if(ERROR) begin
                        HRDATA <= 0;
                        HRESP <= 1;
                        PS <= ERR;
                    end
                    else if(RET_DATA_VALID) begin
                        HRDATA <= RET_DATA;
                        HREADYOUT <= 1;
                        HRESP <= 0;
                        PS <= IDLE;
                    end
                end
                ERR : begin
                    HREADYOUT <= 1;
                    PS <= IDLE;
                end
                default : begin
                    PS <= IDLE;
                end
            endcase
        end
    end
    
endmodule

