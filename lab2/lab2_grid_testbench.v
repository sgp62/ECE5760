//Testbench for lab 2 node grid
`timescale 1ns/1ns
`include "/lab2_node_grid.v"


module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg          [31:0] index;

	reg  signed  [17:0]  rho;
	reg  signed  [17:0]  g_tension;
	reg  signed  [17:0]  eta_term;

	wire signed  [17:0] out;
	wire         [31:0] up_cyc;
	wire                to_fifo;

	reg			 [8:0]   column_power;
	reg          [8:0]   row_size;
	
	

	
	//Initialize constants
	initial begin
		rho              = 18'h3;
		eta_term         = 18'd11;	//Power of 2 used for shifting
		g_tension        = 18'd6; //Power of 2 to be shifted
		column_power     = 9'd7;
		
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
	
	
	
	node_grid  #(.row_size(32)) my_grid (
		.clk             (clk_50),
		.reset           (reset),
		.column_power    (column_power),
		.initial_amp     (18'd17),
		.rho             (rho),
		.g_tension       (g_tension),
		.eta_term        (eta_term),
		.center_node_amp (out),
		.update_cycles   (up_cyc),
		.start_update    (1'b1),
		.done_update_to_fifo  (to_fifo)
	);
	
	
	
endmodule
