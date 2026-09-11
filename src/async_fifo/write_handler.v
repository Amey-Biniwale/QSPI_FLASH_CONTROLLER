/*
This is a write handler code. It works in the write clock domain. It increments the write pointer synchronous to write clock and write enable.
It also converts the binary coded write pointer to gray coded write pointer
*/
`default_nettype none
module write_handler #(parameter DEPTH = 64)( // Parameterising the Depth of FIFO
	
  input wire wclk,                               // Write Clock
  input wire wrst,                               // Write Reset
  input wire w_en,                               // Write Enable
	input wire [$clog2(DEPTH):0] g_rptr_sync,      // Synchronised gray coded read pointer
	output wire full,                              // Signal indicating whether FIFO is full
	output reg [$clog2(DEPTH):0] g_wptr,      // gray coded write pointer
	output reg [$clog2(DEPTH):0] b_wptr       // binary coded write pointer
);

  localparam CLOG_DEPTH = $clog2(DEPTH);   // Initialising a local parameter for address bits

	wire [CLOG_DEPTH:0] g_wptr_reg;         // Intermediate register for registering the gray coded write pointer

	bi_to_gr #(DEPTH) btg(.bi(b_wptr),.gr(g_wptr_reg)); // Convertung the binary coded write pointer to gray coded write pointer

	assign full = (g_rptr_sync) == ({~g_wptr[CLOG_DEPTH:CLOG_DEPTH-1],g_wptr[CLOG_DEPTH-2:0]}); // Checking the full condition 
	
	always @(posedge wclk or negedge wrst) begin // Sequential Block with asynchronous reset
		if(!wrst) begin
			b_wptr <= 0; // Reseting the write pointer to 0
		end
		else if(w_en && !full) begin
			b_wptr <= b_wptr + 1; // Incrementing the write pointer by 1 everytime write enable is asserted
		end
	end

	always @(posedge wclk or negedge wrst) begin
		if(!wrst) begin
			g_wptr <= 0; // Reseting the gray coded write pointer to 0
		end
		else begin
			g_wptr <= g_wptr_reg; // Registering the gray coded write pointer in write clock domain and then sending the output
		end
	end


endmodule
