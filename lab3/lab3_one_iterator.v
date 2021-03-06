//Mandelbrot Lab 3 Single Iterator Module

//Signed 4.23 multiplier


//Store the top left pixel value and the specified offset based on the number of iterators
//Zooming corresponds to a shift of the offset, panning corresponds to a change of the top left pixel
//VGA Memory is stored such that each row of pixels corresponds to a contiguous block, starting with top row 


module signed_mult (out, a, b);
  output  signed  [26:0]  out;
  input   signed  [26:0]  a;
  input   signed  [26:0]  b;
  // intermediate full bit length
  wire    signed  [53:0]  mult_out;
  assign mult_out = a * b;
  // select bits for 4.23 fixed point
  assign out = {mult_out[53], mult_out[48:23]};
   
endmodule


module mandelbrot_iterator (
	input clk,
	input reset,
	input signed [26:0] ci_init, //Initial complex y value
	input signed [26:0] cr_init, //Initial complex x value
	input signed [26:0] ci_bottom_right, cr_bottom_right, //Edge of screen values in complex space
	input [31:0] x1,y1,x2,y2,x_step,y_step, //Initial screen coordinates, and pixel step (based on # of parallel solvers)
	input start, //Enable coming from arbiter; whether this iterator can produce a new output value
	input [31:0] max_iter, //Maximum number of iterations to determine convergence
	input signed [26:0] ci_incr, cr_incr, //Complex delta values for moving to a new complex pair
	output [31:0] num_iter, //Number of iterations to diverge
	output [9:0]  x_px, y_px, //Output screen pixel pair
	output       done, //Notification that this solver is done (used by arbiter to select among finished solvers)
	output 		 at_end //At end of screen
);
	reg         [3:0]  state;
	reg                done_reg;
	reg         [31:0] iter_counter, num_iter_out_reg, x_px_reg, y_px_reg;
	reg signed  [26:0] zi, zr, zi_next, zr_next, ci_reg, cr_reg; //Local variables for Z value calculation
	wire signed [26:0] zi_2, zr_2, zr_zi, zi_wire, zr_wire;
	wire zi_comp, zr_comp, squared_comp;
	reg at_end_reg;
	
	signed_mult mult1 (.out(zi_2), .a(zi), .b(zi)); //Signed Multipliers used for Z value calculation
	signed_mult mult2 (.out(zr_2), .a(zr), .b(zr));
	signed_mult mult3 (.out(zr_zi), .a(zr), .b(zi));

	assign num_iter = num_iter_out_reg;
	assign done = done_reg;
	assign x_px = x_px_reg;
	assign y_px = y_px_reg;
	
	assign at_end = at_end_reg;
	//assign zi_wire = zi;
	//assign zr_wire = zr;
	
	assign zi_comp = (zi < 0) ? (zi < -27'sh1000000) : (zi > 27'h1000000); //Boolean comparators to determine divergence
	assign zr_comp = (zr < 0) ? (zr < -27'sh1000000) : (zr > 27'h1000000);
	assign squared_comp = (zi_2 + zr_2 > 27'h2000000);
	
	always @ (posedge clk) begin
		if (reset) begin
			zi               <= 0;
			zr               <= 0;
			zi_next          <= 0;
			zr_next          <= 0;
			state            <= 0;
			iter_counter     <= 0;
			done_reg         <= 0;
			num_iter_out_reg <= 0;
			ci_reg           <= ci_init;
			cr_reg           <= cr_init;
			x_px_reg         <= x1;
			y_px_reg         <= y1;
			at_end_reg       <= 0;
			
		end
		
		else begin
			if(~done_reg) begin //Calculate z value, increase iterations
				
				zi_next = (zr_zi <<< 1) + ci_reg;
				zr_next = zr_2 - zi_2 + cr_reg;
				
				zi <= zi_next;
				zr <= zr_next;
				
				if(iter_counter == max_iter || zi_comp || zr_comp || squared_comp) //If we have diverged or hit max iterations
					done_reg <= 1; 
				else
					iter_counter <= iter_counter + 1;
			end
			else if(done_reg) begin //Set up next complex pair 
				if(start && ((x_px_reg + x_step < x2) || (y_px_reg + y_step < y2))) begin //If the iterator is allowed to continue, based on the start input
					num_iter_out_reg <= iter_counter; //Assign output iterations to calculated amount
					iter_counter     <= 0;
					zi               <= 0;
					zr               <= 0;
					zi_next          <= 0;
					zr_next          <= 0;
					done_reg <= 1'b0; //No longer done; go back to z calculation state next

					if((x_px_reg + x_step) < x2) begin //Increment x pixel and real complex value if we are in a row
						cr_reg <= cr_reg + cr_incr;
						x_px_reg <= x_px_reg + x_step;
					end

					else if ((y_px_reg + y_step) < y2) begin //Increment y pixel if we are at end of a row
						ci_reg <= ci_reg - ci_incr;
						cr_reg <= cr_init;
						
						y_px_reg <= y_px_reg + y_step;
						x_px_reg <= x1;
					end
					else begin //If we are at the bottom corner, go back to beginning (first complex pair analyzed)
						ci_reg <= ci_init;
						cr_reg <= cr_init;
						
						x_px_reg <= x1;
						y_px_reg <= y1;
					end
				end
				else if (!((x_px_reg + x_step < x2) || (y_px_reg + y_step < y2))) begin
					at_end_reg <= 1;
				end
			end
		end
	
	end
	
	
endmodule
