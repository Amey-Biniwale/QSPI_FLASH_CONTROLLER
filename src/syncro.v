`default_nettype none
module syncro(
    input wire clk,
    input wire rst,
    input wire data_in,
    output reg data_out
    );
    
    reg syncro1, syncro2;
    
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            syncro1 <= 0;
            syncro2 <= 0;
            data_out <= 0;
        end
        else begin
            syncro1 <= data_in;
            syncro2 <= syncro1;
            data_out <= syncro2;
        end
    end
endmodule

