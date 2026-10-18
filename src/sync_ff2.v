`default_nettype none

module sync_ff2(
    input wire CLK,
    input wire RSTn,
    input wire DATA_IN,
    output reg DATA_OUT
    );
    
    reg SYNC;
    
    always @(posedge CLK or negedge RSTn) begin
        if(!RSTn) begin
            SYNC <= 0;
            DATA_OUT <= 0;
        end
        else begin
            SYNC <= DATA_IN;
            DATA_OUT <= SYNC;
        end
    end
endmodule

