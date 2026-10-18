`default_nettype none

module CLOCK_DIV #(
    parameter DIVIDER = 4
)(
    input wire PCLK,
    input wire PRESETn,
    input wire EN,
    
    input wire CPOL,
    input wire CPHA,
    
    output reg SCLK_INT,
    output reg SCLK
    );
    
    reg [((DIVIDER>1) ? ($clog2(DIVIDER)-1) : 1):0] count;

    
    // IF ~(CPOL ^ CPHA) = 1, sample on rising edge else sample on falling edge
    
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            SCLK <= CPOL;
            SCLK_INT <= CPHA;
            count <= 0;
        end
        else begin
            if(count == DIVIDER-1) begin
                if(EN) SCLK <= ~SCLK;
                SCLK_INT <= ~SCLK_INT;
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
            if(!EN) SCLK <= CPOL;
        end
    end
    
    
    
    
endmodule

