//Iterator Controller
`include "C:/Users/sgp62/Desktop/sgp62_hlg66_rbm244/ECE5760/lab3/lab3_mandelbrot_one_iterator.v"

module mandelbrot_iterator_controller #(parameter num_iterators = 25) (
	input clk, reset, iter_sel,
	input [31:0] max_iter,
	input [31:0] zoom_factor,
	input signed [26:0] cr_top_left, ci_top_left, cr_bottom_right, ci_bottom_right,
	//output finished_array,
	output [31:0] single_num_iter, 
	output [9:0]  single_x, single_y
);

	wire   [31:0]  num_iter_array [num_iterators-1:0];
	wire   [9:0]  x_px_array [num_iterators-1:0];
	wire   [9:0]  y_px_array [num_iterators-1:0];
	
	reg [9:0] single_x_reg, single_y_reg;
	reg [31:0] single_num_iter_reg;
	
	assign single_num_iter = single_num_iter_reg;
	assign single_x = single_x_reg;
	assign single_y = single_y_reg;
	
	reg   [31:0]  start_array; //Stores bitwise synch signals for the iterators
	
	//wire   [31:0]  num_steps_x_array [num_iterators-1:0];//Arrays because each iterator finishes at different times, could be at different offsets
	//wire   [31:0]  num_steps_y_array [num_iterators-1:0];
	
	//wire   [26:0]  ci_init_array [num_iterators-1:0];
	//wire   [26:0]  cr_init_array [num_iterators-1:0];
	
	wire signed [26:0] cr_incr = 27'h9999 >> zoom_factor; //1\640 is 27'h3333
	wire signed [26:0] ci_incr = 27'h8888 >> zoom_factor;
	
	wire finished_array [num_iterators-1:0]; //TODO: Use as output and fix the finished_iter in the upper module
	reg [5:0] offset;
	reg [5:0] j;
	reg [5:0] init_i;
	reg found_one;
	reg [5:0] sel_idx;
	
	//need to generate the initial upper left (cr,ci) and (x,y) for each iterator,
	//Only the first one is (-2,1) , (0,0)
	//x = -2 + i * x_incr + num_steps_x * x_incr;
	//y = 1 + i * y_incr
	
	//Based on iter_sel, pick single_x,y,num_iter
	//Iter sel will be selected in the top module, based on which bit of finished_array is cleared
	
	always @ (posedge clk) begin
		//How to initialize and update each ci_reg, cr_reg pair independently?
		if(reset) begin
			found_one <= 0;
			offset <= 0;
			sel_idx <= 0;
		end
		
		else begin
		
			//One iterator is done, tell it to stop and need to write its value to VGA sram
				//Might just do this in top level module, this will control the VGA state machine
				//How to deal with possible starvation of finished iterators?
			
			//loop through iterators until we find one that's finished
			for(j = 0; j < num_iterators; j=j+1) begin
				if(~found_one) begin
					if(j+offset >= num_iterators-1) //preventing overflow and out of bounds 
						offset = 0;
					if(finished_array[j+offset] == 1) begin //Found a finished iterator, set its values as the output
						single_num_iter_reg = num_iter_array[j+offset];
						single_x_reg = x_px_array[j+offset];
						single_y_reg = y_px_array[j+offset];
						sel_idx = j + offset; // Identify which iterator was selected
						start_array[j+offset] = 1;//Tell this iterator it's allowed to start again
						offset = j+offset+1; //Move so as to not starve other iterators
						found_one = 1; //Only want to do this ONCE per clock cycle
					end
				end
				else begin
					if(j == num_iterators-1)
						found_one = 0; // this will take effect the NEXT clock cycle (entire for loop executes this cycle)
					if(j != sel_idx)
						start_array[j] <= 0; //Each iterator should not start again unless it's value was outputted
				end
			end
			//Send the x and y coordinate of the chosen iterator up to the top level module, along with the color.
			//Use this to write to the x and y pixel that that iterator is assigned to
			
		end
	end
	
	
	
	generate
		genvar i;
		for (i = 0; i < num_iterators; i=i+1) begin: iterator_gen
			mandelbrot_iterator m_it (
				.clk      (clk),
				.reset    (reset),
				.ci_init  (ci_top_left),
				.cr_init  (cr_top_left + cr_incr * i[26:0] ),
				.ci_bottom_right (ci_bottom_right),
				.cr_bottom_right (cr_bottom_right),
				.x1       (i), //Modify with zooming
				.y1       (0), //Modify with zooming
				.x2       (32'd639), //Need to modify these values with zooming
				.y2       (32'd479), //Modify with zooming
				.x_step   (num_iterators),
				.y_step   (1),
				.x_px     (x_px_array[i]),
				.y_px     (y_px_array[i]),
				.max_iter (max_iter),
				.num_iter (num_iter_array[i]),
				.start    (start_array[i]),
				.cr_incr  (cr_incr * num_iterators[26:0]), //Hopefully doesn't use any more DSP units
				.ci_incr  (ci_incr),
				.done     (finished_array[i])
			
			);
		end
	endgenerate

endmodule