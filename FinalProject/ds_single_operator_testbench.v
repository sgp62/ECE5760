//ds_single_operator testbench


//Testbench for lab 2 node grid
`timescale 1ns/1ns
`include "/ds_operator.v"


module testbench();
	
	reg clk_50, clk_25, reset;
	
	wire [9:0] x,y;
	wire [7:0] z;

	
	//Initialize constants
	initial begin
		//Fill
	end

	
	//Initialize clocks and index
	initial begin
		clk_50 = 1'b0;
		clk_25 = 1'b0;
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
	
	
	diamond_square_single_operator  #(.dim_power(6), .dim(65)) ds_operator (
		.clk             (clk_50),
		.reset           (reset),
		.ack		 	 (1'b1),
		.rand_seed       (32'hdeadbeef),
		.corners		 (32'hc8a01464),
		.x				 (x),
		.y				 (y),
		.z				 (z),
		.done_out        (),
		.new_value		 ()
	);
	
	
	
endmodule
