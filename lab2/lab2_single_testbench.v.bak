`timescale 1ns/1ns
`include "/lab2_single_node.v"

module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg [31:0] index;

	reg  signed [17:0]  initial_u_n;
	reg  signed [17:0]  initial_u_n_prev;
	reg  signed [17:0]  rho;
	reg  signed [17:0]  g_tension;
	reg  signed [17:0]  eta_term;

	wire  signed [17:0] out;


	//Initialize constants
	initial begin
		initial_u_n      = 18'h04000;
		initial_u_n_prev = 18'h04000;
		rho              = 18'h02000;
		eta_term         = 18'h0000d;
		g_tension        = 18'h02000;
	end

	
	//Initialize clocks and index
	initial begin
		clk_50 = 1'b0;
		clk_25 = 1'b0;
		index  = 32'd0;
		//testbench_out = 15'd0 ;
	end
	
	//Toggle the clocks
	always begin
		#10
		clk_50  = !clk_50;
	end
	
	always begin
		#20
		clk_25  = !clk_25;
	end
	
	//Intialize and drive signals
	initial begin
		reset  = 1'b0;
		#10 
		reset  = 1'b1;
		#30
		reset  = 1'b0;
	end
	
	//Increment index
	always @ (posedge clk_50) begin
		index  <= index + 32'd1;
	end

	

	//Instantiation of Device Under Test
single_node lab2_single (
	.clk (clk_25),
	.reset (reset),
	.out (out),
	.initial_u_n (initial_u_n),
	.initial_u_n_prev (initial_u_n_prev),
	.rho (rho),
	.g_tension (g_tension),
	.eta_term (eta_term)
);


//single_node lab2_single (clk_50, reset, out, initial_u_n, initial_u_n_prev, rho, g_tension, eta_term, temp1_trace, temp2_trace);
	
endmodule
