//Iterator Controller
`include "C:/Users/sgp62/Desktop/sgp62_hlg66_rbm244/ECE5760/lab3/lab3_mandelbrot_one_iterator.v"

module mandelbrot_iterator_controller #(parameter num_iterators = 25) (
	input clk, reset, iter_sel
	input [31:0] max_iter,
	input [31:0] zoom_factor,
	input signed [26:0] cr_top_left, cr_top_left, cr_bottom_right, ci_bottom_right,
	output finished_array,
	output [31:0] single_num_iter, single_x, single_y
);

	wire   [31:0]  num_iter_array [num_iterators-1:0];
	
	reg   [31:0]  start_array, finished_array; //Stores bitwise synch signals for the iterators
	
	//wire   [31:0]  num_steps_x_array [num_iterators-1:0];//Arrays because each iterator finishes at different times, could be at different offsets
	//wire   [31:0]  num_steps_y_array [num_iterators-1:0];
	
	//wire   [26:0]  ci_init_array [num_iterators-1:0];
	//wire   [26:0]  cr_init_array [num_iterators-1:0];
	
	wire signed [26:0] x_incr = 27'h9999 >> zoom_factor; //1\640 is 27'h3333
	wire signed [26:0] y_incr = 27'h8888 >> zoom_factor;
	
	
	//need to generate the initial upper left (cr,ci) and (x,y) for each iterator,
	//Only the first one is (-2,1) , (0,0)
	//x = -2 + i * x_incr + num_steps_x * x_incr;
	//y = 1 + i * y_incr
	
	//Based on iter_sel, pick single_x,y,num_iter
	//Iter sel will be selected in the top module, based on which bit of finished_array is cleared
	
	always @ (posedge clk) begin
		//How to initialize and update each ci_reg, cr_reg pair independently?
		if(reset) begin
			start_array <=  32'hffffffff;
		end
		
		else begin
			//if(finished_array > 0) begin //One iterator is done, tell it to stop and need to write its value to VGA sram
				//Might just do this in top level module, this will control the VGA state machine
				//How to deal with possible starvation of finished iterators?
				
			//end
			//Send the x and y coordinate of the chosen iterator up to the top level module, along with the color.
			//Use this to write to the x and y pixel that that iterator is assigned to
			
			//Need to reassign the step values to be multiplied by the num_iterators
		end
	end
	
	
	
	generate
		genvar i;
		for (i = 0; i < num_iterators; i=i+1) begin: iterator_gen
			mandelbrot_iterator m_it (
				.clk      (clk),
				.reset    (reset),
				.ci_init  (ci_top_left),
				.cr_init  (cr_top_left + x_incr * i ),
				.ci_bottom_right (ci_bottom_right),
				.cr_bottom_right (cr_bottom_right),
				.max_iter (max_iter),
				.num_iter (num_iter_array[i]),
				.start    (start_array[i]),
				.x_incr   (x_incr), //MULTIPY YOU IDIOT
				.y_incr   (y_incr),
				.done     (finished_array[i])
			);
		end
	endgenerate

endmodule

/*
wire signed [26:0] ci; //[-1,1]
wire signed [26:0] cr; //[-2,1]
reg  [31:0] zoom_factor;
reg  [31:0] num_steps_x;
reg  [31:0] num_steps_y;

wire signed [26:0] x_incr = 27'h9999 >> zoom_factor; //1\640 is 27'h3333
wire signed [26:0] y_incr = 27'h8888 >> zoom_factor;

assign cr =  -27'sh1000000 + num_steps_x * x_incr;
assign ci =  27'sh800000 - num_steps_y * y_incr;

*/