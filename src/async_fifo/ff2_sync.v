/*
This is a 2 flip flop synchroniser module. It takes in the input signal and synchronises it with the destination clock
*/
`default_nettype none
module ff2_sync #(parameter DEPTH=64)( // Parameterising the FIFO depth
	input wire clk,                            // Destination Clock
  input wire rst,                            // Destination Reset
  input wire [$clog2(DEPTH):0] sync_in,      // Input Data from Source Clock
	output reg [$clog2(DEPTH):0] sync_out // Output Data to the Destination Clock
);

	reg [$clog2(DEPTH):0] sync_1, sync_2; // Initialising the intermediate registers

	always @(posedge clk or negedge rst) begin
		if(!rst) begin
			sync_1 <= 0; // Reseting all registers to 0 when reset is asserted
			sync_2 <= 0;
			sync_out <= 0;
		end
		else begin
			sync_1 <= sync_in; // Sending the input data to first intermediate register
			sync_2 <= sync_1;  // Sending the data from first intermediate register to second intermediate register
			sync_out <= sync_2; // Sending the data from second intermediate to the output
		end
	end

endmodule
