//Lab 3 Single Integrator Testbench

`timescale 1ns/1ns
`include "/lab3_mandelbrot_one_iterator.v"

module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg [31:0] index;

	reg  signed [26:0]  ci;
	reg  signed [26:0]  cr;
	reg         [31:0]  max_iter;


	wire        [31:0]  num_iter;
	wire done;


	//Initialize constants
	initial begin
		//ci        = 27'h400000; // 0.5
		//cr        = 27'h400000; // 0.5 Expected 5
		//ci        = 27'h1000000; // 2
		//cr        = 27'h1000000; // 2
		//ci        = -27'sh1000000; // -2
		//cr        = 27'h1000000; // 2
		//ci        = 27'h347ae1; // 0.41
		//cr        = -27'sh51eb85; // -0.64 Expected 223
		//ci        = 27'h200000;//0.25
		//cr        = 27'h340000;//0.40625 Expected 12
		//ci        = -27'h200000;//0.25
		//cr        = -27'h340000;//0.40625 Expected 1000
		//ci        = -27'sh3f0000;//0.3125
		//cr        = 27'h280000;//-0.4921875 Expected 61
		//ci        = 27'h0;//0
		//cr        = 27'h0;//0 Expected 1000
		//ci        = 27'h800000;//0
		//cr        = 27'h800000;//0 Expected 2
		ci        = -27'h600000;//-.75
		cr        = -27'h200000;//-.25 Expected 22
		//ci        = -27'sh100000;
		//cr        = 27'sh80000;
		max_iter  = 31'd1000;
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
mandelbrot_iterator lab3_iter (clk_50, reset, ci, cr, max_iter, num_iter, done);
	
endmodule

