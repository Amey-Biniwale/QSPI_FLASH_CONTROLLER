//This is a module where we are converting binary to gray for CDC
`default_nettype none

module bi_to_gr#(parameter DEPTH = 64)( // It has been parameterised to the Depth of FIFO.
	input wire [$clog2(DEPTH):0] bi, // We will use the clog command to get the number of address bits required. So, we require $clog2(DEPTH) as a address to access the FIFO.
	output wire [$clog2(DEPTH):0] gr // We will use the same number of bits as output
);

	assign gr = bi ^ (bi >> 1); // This is the formula used to convert from binary to gray.

endmodule
