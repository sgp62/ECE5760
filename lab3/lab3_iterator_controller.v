//Iterator Controller
`include "C:/Users/sgp62/Desktop/sgp62_hlg66_rbm244/ECE5760/lab3/lab3_one_iterator.v"

module mandelbrot_iterator_controller #(parameter num_iterators = 25) ( //Parameter for number of solvers to generate
	input clk, reset, iter_sel, //Which solver had its outputs selected
	input [31:0] max_iter,
	input [31:0] zoom_factor, //Zoom factor from mouse input which affects complex coordinate incrementing
	input signed [26:0] cr_top_left, ci_top_left, cr_bottom_right, ci_bottom_right, //Screen bounds, complex space
	input signed [26:0] cr_incr, ci_incr, //Complex coordinate incrementing, to be sent to solvers
	output fin_val, //If we found an output in a given cycle
	output [10:0] single_num_iter, //Selected number of iterations to be turned into a VGA color
	output [9:0]  single_x, single_y, //Pixel value selected
	output [31:0] cycles
);
	
	reg [31:0] 	cycles_counter;
	reg [31:0] 	cycles_per_update;

	assign cycles = cycles_per_update;
	
	wire   [31:0]  num_iter_array [num_iterators-1:0];
	wire   [9:0]  x_px_array [num_iterators-1:0];
	wire   [9:0]  y_px_array [num_iterators-1:0];
	
	reg [9:0] single_x_reg, single_y_reg;
	reg [10:0] single_num_iter_reg;
	
	assign single_num_iter = single_num_iter_reg;
	assign single_x = single_x_reg;
	assign single_y = single_y_reg;
	
	reg   [31:0]  start_array; //Stores bitwise synch signals for the iterators
	
	//wire   [31:0]  num_steps_x_array [num_iterators-1:0];//Arrays because each iterator finishes at different times, could be at different offsets
	//wire   [31:0]  num_steps_y_array [num_iterators-1:0];
	
	//wire   [26:0]  ci_init_array [num_iterators-1:0];
	//wire   [26:0]  cr_init_array [num_iterators-1:0];
	
	//wire signed [26:0] cr_incr = 27'h9999 >> zoom_factor; //1\640 is 27'h3333
	//wire signed [26:0] ci_incr = 27'h8888 >> zoom_factor;
	
	
	wire [num_iterators-1:0] at_end_wire;
	wire finished_array [num_iterators-1:0];
	//wire running_array [num_iterators-1:0];
	wire signed [26:0] cr_incr_scaled;
	reg [5:0] offset;
	reg [5:0] j;
	reg [5:0] init_i;
	reg found_one;
	reg [5:0] sel_idx;
	reg fin_val_reg;
	reg [4:0] state;
	
	assign fin_val = fin_val_reg;
	assign cr_incr_scaled = cr_incr * num_iterators[26:0];
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
			fin_val_reg <= 0;
			cycles_counter <= 0;
			cycles_per_update <= 0;
			single_x_reg <= 0;
			single_y_reg <= 0;
			state <= 4'd0;
		end
		
		else begin
			if (state == 4'd0) begin
			
				for(j = 0; j < num_iterators; j=j+1) begin
					start_array[j] <= 0; //Each iterator should not start again unless it's value was outputted
				end
				//One iterator is done, tell it to stop and need to write its value to VGA sram
				
				cycles_counter <= cycles_counter + 32'b1;
				//loop through iterators until we find one that's finished
				if(finished_array[offset] == 1) begin
					sel_idx <= offset; //The selected iterator's id is set to sel_idx
					fin_val_reg <= 1;
					state <= 4'd1;
				end
				else begin
					fin_val_reg <= 0; //None are finished, try again
				end
				offset <= (offset == num_iterators-1) ? 0 : offset + 1; //Increase offset to solve starvation problem.

			end
			else if (state == 4'd1) begin
				if (at_end_wire < {num_iterators{1'b1}}) begin //If not all the iterators are finished yet
					cycles_counter <= cycles_counter + 32'b1; //Go back to selection stage on next cycle
					state <= 4'd0;
				end
				else state <= 4'd2; //If all iterators are finished, go to done stage.
				
				single_num_iter_reg <= num_iter_array[sel_idx]; //Setting arbiter outputs to selected solver's pixel and iterations calculated
				single_x_reg <= x_px_array[sel_idx];
				single_y_reg <= y_px_array[sel_idx];
				start_array[sel_idx] <= 1;
				
			end
			else if (state == 4'd2) begin //Done state, stop looking at iterators
				//if (cycles_per_update == 32'b0) 
				cycles_per_update <= cycles_counter;
				//state <= 4'd0;
			end
		end
	end
	
	
	
	generate
		genvar i;
		for (i = 0; i < num_iterators; i=i+1) begin: iterator_gen
			mandelbrot_iterator m_it (
				.clk      (clk),
				.reset    (reset),
				.ci_init  (ci_top_left), //Top left screen bound, y coordinate
				.cr_init  (cr_top_left + cr_incr * i[26:0] ), //Initial x coordinate, changes so each iterator is unique.
				.ci_bottom_right (ci_bottom_right), //Bottom right screen bounds
				.cr_bottom_right (cr_bottom_right),
				.x1       (i), //Initial pixel will be the same x coordinate as this solver's ID
				.y1       (0), 
				.x2       (32'd640), 
				.y2       (32'd480),
				.x_step   (num_iterators), //Spacing between selected pixels for each iterator, equal to the number of solvers
				.y_step   (1),
				.x_px     (x_px_array[i]), //Hook up outputs
				.y_px     (y_px_array[i]),
				.max_iter (max_iter),
				.num_iter (num_iter_array[i]), //Hook up outputs
				.start    (start_array[i]), //Enable signals, arbiter controls setting of these
				.cr_incr  (cr_incr_scaled), //Increment between complex pairs, changes with zooming
				.ci_incr  (ci_incr),
				.done     (finished_array[i]), //Status signal, tells arbiter the solver is finished
				.at_end   (at_end_wire[i])
			);
		end
	endgenerate

endmodule
