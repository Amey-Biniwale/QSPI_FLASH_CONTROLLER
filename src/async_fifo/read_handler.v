/*
  This module performs the incrementing of the read pointer synchronous to the read clock and read enable. It also converts the binary counter value to gray coded value.
  This module also recieves the synchronised gray coded write pointer value from write handler and checks the empty condition.
*/
`default_nettype none

module read_handler #(parameter DEPTH = 64)( // Parameterising the FIFO Depth Value to calculate address bits.
	
  input wire rclk,                                     // Read Clock
  input wire rrst,                                     // Read Reset
  input wire r_en,                                     // Read Enable
	input wire [$clog2(DEPTH):0] g_wptr_sync,            // Synchronised gray coded Write Pointer
	output wire empty,                                   // Output indicating when FIFO is empty
	output reg [$clog2(DEPTH):0] g_rptr,            // Gray Coded Read Pointer
	output reg [$clog2(DEPTH):0] b_rptr             // Binary Coded Read Pointer
);

	wire [$clog2(DEPTH):0] g_rptr_reg;              // Register intermediate output after converting to gray
	
  assign empty = (g_wptr_sync == g_rptr);         // Checking whether the read pointer and write pointer are on same address to check whether the FIFO is empty.


	bi_to_gr #(DEPTH) btg(.bi(b_rptr),.gr(g_rptr_reg));      // Converting the binary coded read pointer to gray coded read pointer

	always @(posedge rclk or negedge rrst) begin    // Sequential always block with asynchronous reset
		if(!rrst) begin
			b_rptr <= 0;                                // Reseting the read pointer to 0
		end
		else if(r_en && !empty) begin
			b_rptr <= b_rptr + 1;                       // Incrementing the value of read pointer everytime read enable is asserted.
		end
	end

	always @(posedge rclk or negedge rrst) begin    // Sequential always block with asynchronous reset
		if(!rrst) begin
			g_rptr <= 0;                                // Reseting the gray coded read pointer to 0
		end
		else begin
			g_rptr <= g_rptr_reg;                       // Registering the gray coded read pointer in the read clock domain
		end
	end

endmodule
