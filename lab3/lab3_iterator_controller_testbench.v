//Full_iterator testbench

`timescale 1ns/1ns
`include "/lab3_iterator_controller.v"


module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg [31:0] index;

	reg  signed [26:0]  ci;
	reg  signed [26:0]  cr;
	reg         [31:0]  max_iter;


	wire        [31:0]  num_iter, finished_array;
	wire done;
	
	wire signed [26:0] ci_top_left, cr_top_left, ci_bottom_right, cr_bottom_right;
	
	assign cr_top_left =  -27'sh1000000;
	assign ci_top_left =  27'sh800000;
	assign ci_bottom_right = -27'sh800000;
	assign cr_bottom_right = 27'sh800000;


	//Initialize constants
	initial begin

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
mandelbrot_iterator_controller lab3_controller (clk_50, reset, max_iter, 0, cr_top_left, cr_top_left, 
 cr_bottom_right, ci_bottom_right, finished_array);
	
	
	
endmodule

