//Iterator Controller
`include "C:/Users/sgp62/Desktop/sgp62_hlg66_rbm244/ECE5760/lab3/lab3_mandelbrot_one_iterator.v"

module mandelbrot_iterator_controller #(parameter num_iterators = 25) (
	input clk, reset,
	input [31:0] max_iter,
	output one_finished
);

	wire   [31:0]  num_iter_array [num_iterators-1:0];
	wire           finished_array [num_iterators-1:0];
	wire   [31:0]  num_steps_x_array [num_iterators-1:0];//Arrays because each iterator finishes at different times, could be at different offsets
	wire   [31:0]  num_steps_y_array [num_iterators-1:0];
	
	wire signed [26:0] x_incr = 27'h9999 >> zoom_factor; //1\640 is 27'h3333
	wire signed [26:0] y_incr = 27'h8888 >> zoom_factor;
	
	
	//need to generate the initial upper left (cr,ci) and (x,y) for each iterator,
	//Only the first one is (-2,1) , (0,0)
	//x = -2 + i * x_incr + num_steps_x * x_incr;
	//y = 1 + i * y_incr
	
	
	generate
		genvar i;
		for (i = 0; i < num_iterators; i=i+1) begin: iterator_gen
			mandelbrot_iterator m_it (
				.clk      (clk),
				.reset    (reset),
				.ci       (27'sh800000 - y_incr * (num_steps_y_array[i])), //Turn this into an array of ci registers that updates with new values
				.cr       (-27'sh1000000 + x_incr * (i + num_steps_x_array[i])),
				.max_iter (max_iter),
				.num_iter (num_iter_array[i]),
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