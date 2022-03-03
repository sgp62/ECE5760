//Testbench for lab 2 node column
`timescale 1ns/1ns
`include "/lab2_node_column.v"


module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg          [31:0] index;

	reg  signed  [17:0]  rho;
	reg  signed  [17:0]  g_tension;
	reg  signed  [17:0]  eta_term;

	wire signed  [17:0] out, middle_out;
	

	reg			 [8:0]   column_size;
	
	wire		 [17:0]  dont_care_wire;

	
	//Initialize constants
	initial begin
		
		//rho              = 18'h01000;
		//eta_term         = 18'h000ff;
		//g_tension        = 18'h02000;
		
		rho              = 18'h02000;
		eta_term         = 18'h000ff;	
		g_tension        = 18'h01000;
		
		
		column_size        = 9'd30;

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
	
column my_col(
	.clk          (clk_50),
	.reset        (reset),
	.rho          (rho),
	.eta_term     (eta_term),
	.g_tension    (g_tension),
	.column_size  (column_size),
	.out          (out),
	.u_left       (18'h0),
	.u_right      (18'h0),
	.middle_out   (middle_out),
	.u_n_out      (dont_care_wire),
	.column_num   (18'd15)

);
	
endmodule
