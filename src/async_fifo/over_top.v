module over_top #(parameter DATA_WIDTH = 32, DEPTH = 64)(
	input clk1, clk2, rst1, rst2,
	input w_en, r_en,
	input [$clog2(DATA_WIDTH)-1:0] d1,
	output reg [$clog2(DATA_WIDTH)-1:0] d2,
	output full, empty
);

	reg [$clog2(DATA_WIDTH)-1:0] s1; 
	wire [$clog2(DATA_WIDTH)-1:0] s2;

	always @(posedge clk1 or posedge rst1) begin
		if(rst1) begin
			s1 <= 0;
		end
		else begin
			s1 <= d1;
		end
	end

	fifo_top #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) t1(.wclk(clk1),.rclk(clk2),.wrst(rst1),.rrst(rst2),.data_in(s1),.data_out(s2),.w_en(w_en),.r_en(r_en),.full(full),.empty(empty));

	always @(posedge clk2 or posedge rst2) begin
		if(rst2) begin
			d2 <= 0;
		end
		else begin
			d2 <= s2;
		end
	end

endmodule
