/*
This is the fifo module in which the data transfer takes place.
*/
`default_nettype none
module fifo#(parameter DATA_WIDTH = 32, DEPTH = 64)( // Parameterising the Data Width and FIFO Depth

	input wire wclk,                                         // Write Clock
  input wire rclk,                                         // Read Clock
  input wire wrst,                                         // Write Reset
  input wire rrst,                                         // Read Reset
	input wire w_en,                                         // Write Enable
  input wire r_en,                                         // Read Enable
	input wire full,                                         // Signal indicating whether FIFO is full
  input wire empty,                                        // Signal indicating whether FIFO is empty
	input wire [$clog2(DEPTH)-1:0] b_wptr,                   // binary coded write pointer
  input wire [$clog2(DEPTH)-1:0]b_rptr,                    // binary coded read pointer
	input wire [DATA_WIDTH-1:0] data_in,             // Input data
	output reg [DATA_WIDTH-1:0] data_out        // Output Data
);


// Memory Initialization

	reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];


  integer i; // Interger declaration for use in for loop

	always @(posedge wclk or negedge wrst) begin // Writing Block
		if(!wrst) begin
			for(i=0;i<DEPTH;i=i+1) begin
				mem[i] <= 0;                      // Clearing the FIFO when reset is asserted
			end
		end
		else if(w_en && !full) begin
			mem[b_wptr] <= data_in;             // Writing the input data into the memory when write enable is asserted and the FIFO is not full
		end
	end

	always @(posedge rclk or negedge rrst) begin // Read Block
		if(!rrst) begin
			data_out <= 0;                      // Sending 0 as the output data when reset is asserted
		end
		else if(r_en && !empty) begin
			data_out <= mem[b_rptr];            // Sending the data present in the address of the read pointer when read enable is asserted and the FIFO is not empty
		end
	end

endmodule
