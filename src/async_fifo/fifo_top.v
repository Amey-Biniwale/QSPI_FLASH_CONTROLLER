`default_nettype none
/* This is the top module for the Asynchronous FIFO. It has instantiations of read handler, write handler, fifo, and the synchronisers.
To use the asynchronous FIFO, you just need to instantiate this module in the required code with specified parameters.
*/


module fifo_top#(parameter DATA_WIDTH = 32, DEPTH = 64)( // Setting the parameter values: DATA_WIDTH : The width of incoming and outgoing data
                                                         // DEPTH : Depth of the FIFO
	
    input wire wclk,                                 // Write Clock
    input wire rclk,                                 // Read Clock
    input wire wrst,                                 // Write Reset
    input wire rrst,                                 // Read Reset
	input wire w_en,                                 // Write Enable
    input wire r_en,                                 // Read Enable
	input wire [DATA_WIDTH-1:0] data_in,     // Input Data Register
	output  wire [DATA_WIDTH-1:0] data_out,  // Output Data Register
	output wire full,                                // Shows whether FIFO is Full
    output wire empty                                // Shows whether FIFO is Empty
);

  localparam CLOG_DEPTH = $clog2(DEPTH); // Putting the address_bits + 1 in a local parameter for ease in use

	wire [CLOG_DEPTH:0] g_wptr_sync;        // Wire Declaration for Syncronised gray coded Write Pointer
  wire [CLOG_DEPTH:0] g_rptr_sync;        // Wire Declaration for Synchronised gray coded Read Pointer
	wire [CLOG_DEPTH:0] g_wptr;             // Wire Declaration for gray coded Write Pointer
  wire [CLOG_DEPTH:0] g_rptr;             // Wire Declaration for gray coded Read Pointer
	wire [CLOG_DEPTH:0] b_rptr;             // Wire Declaration for binary coded Write Pointer
  wire [CLOG_DEPTH:0] b_wptr;             // Wire Declaration for binary coded Read Pointer


  // FIFO Instantiation 

	fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))f1(.wclk(wclk),.rclk(rclk),.wrst(wrst),.rrst(rrst),
	.w_en(w_en),.r_en(r_en),.full(full),.empty(empty),.b_wptr(b_wptr[CLOG_DEPTH-1:0]),.b_rptr(b_rptr[CLOG_DEPTH-1:0]),
	.data_in(data_in),.data_out(data_out));

  // Read Handler Instantiation

	read_handler #(.DEPTH(DEPTH)) r1(.rclk(rclk),.rrst(rrst),.r_en(r_en),
	.g_wptr_sync(g_wptr_sync),.empty(empty),.g_rptr(g_rptr),.b_rptr(b_rptr));

  // Write Handler Instantiation

	write_handler #(.DEPTH(DEPTH)) h1(.wclk(wclk),.wrst(wrst),.w_en(w_en),
	.g_rptr_sync(g_rptr_sync),.full(full),.g_wptr(g_wptr),.b_wptr(b_wptr));

  // 2 Flip Flop Synchroniser Instantiation

	ff2_sync #(.DEPTH(DEPTH)) ff1(.clk(wclk),.rst(wrst),.sync_in(g_rptr),.sync_out(g_rptr_sync)); // Synchronising read pointer with Write Clock
	ff2_sync #(.DEPTH(DEPTH)) ff2(.clk(rclk),.rst(rrst),.sync_in(g_wptr),.sync_out(g_wptr_sync)); // Synchronising write pointer with Read Clock


endmodule
