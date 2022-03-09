//Mandelbrot Lab 3 Single Iterator Module

//Signed 4.23 multiplier

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
	input signed [26:0] ci,
	input signed [26:0] cr,
	input [31:0] max_iter,
	output [31:0] num_iter
);
	reg         [3:0]  state;
	reg                done;
	reg         [31:0] iter_counter, num_iter_out_reg;
	reg signed  [26:0] zi, zr, zi_next, zr_next;
	wire signed [26:0] zi_2, zr_2, zr_zi, zi_wire, zr_wire;
	
	
	signed_mult mult1 (.out(zi_2), .a(zi), .b(zi));
	signed_mult mult2 (.out(zr_2), .a(zr), .b(zr));
	signed_mult mult3 (.out(zr_zi), .a(zr), .b(zi));

	assign num_iter = num_iter_out_reg;
	//assign zi_wire = zi;
	//assign zr_wire = zr;
	
	always @ (posedge clk) begin
		if (reset) begin
			zi               <= 0;
			zr               <= 0;
			zi_next          <= 0;
			zr_next          <= 0;
			state            <= 0;
			iter_counter     <= 0;
			done             <= 0;
			num_iter_out_reg <= 0;
			
		end
		
		else begin
			if(~done) begin
				
				
				zi_next <= (zr_zi <<< 1) + ci;
				zr_next <= zr_2 - zi_2 + cr;
				
				zi <= zi_next;
				zr <= zr_next;
				
				if(iter_counter == max_iter || (zi > 27'h1000000) || (zr > 27'h1000000) || (zi_2 + zr_2 > 27'h2000000))
					done <= 1; //Check signed comparison and also negative ranges, add flags to see which is triggering exit
				else
					iter_counter <= iter_counter + 1;
			end
			if(done)
				num_iter_out_reg <= iter_counter - 1;
		end
	
	end


endmodule