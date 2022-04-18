//FinalProj_DS_One_Iterator
`include "./ds_col.v"



module lfsr ( //Used for pseudorandom R numbers
	input clk, reset,
	input [7:0] seed,
	output [7:0] out_num
);
	reg [7:0] num;
	reg in_bit;
	assign out_num = num;

	always @ (posedge clk) begin
		if(reset) begin
			num <= seed;
		end
		else begin
			in_bit <= num[7] ^ num[5] ^ num[4] ^ num[2] ^ 1;
			num <= num << 1;
			num[0] <= in_bit;
		end
		
	end

endmodule


module diamond_square_operator #(parameter dim_power = 3) (
	input clk, reset,
	output 	[9:0]	x,y,
	output	[7:0]	z
	
);

	wire		 	done;
	wire    [8:0]	dim, step_size, half;
	
	wire	[7:0]	out_up_array [(1 << dim_power) : 0];
	wire	[7:0]	out_down_array [(1 << dim_power): 0];
	wire    [8:0]   step_size_array [(1 << dim_power): 0];
	
	assign dim = (1 << dim_power) + 9'b1;
	assign step_size = step_size_array[dim >> 1];
	assign half = step_size >> 1;
	
	assign x = 0;
	assign y = 0;
	assign z = 0;

	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
		end
		//Will need clocked logic block to send pixel values up to top level module after all have been calculated
	end
	
	generate
		genvar i;
		for (i = 0; i < ((1 << dim_power) + 8'b1); i=i+1) begin: col_gen
			diamond_square_col my_col(
				.clk          		(clk),
				.reset        		(reset),
				.col_id             (i),
				.dim_power          (dim_power),
				.step_size_out      (step_size_array[i]),
				.val_l				(out_up_array[((i<half) ? (dim-9'b1-half) : (i-half))]), //From step_size/2 columns to the left (Wrap around???)
				.val_r				(out_up_array[((i>=(dim-half)) ? (half) : (i+half))]), //From step_size/2 columns to the right
				.val_l_down			(out_down_array[((i<half) ? (dim-9'b1-half) : (i-half))]), //Undefined for diamond step, otherwise stepsize/2 columns to left
				.val_r_down			(out_down_array[((i>=(dim-half)) ? (half) : (i+half))]), //Undefined for diamond step, otherwise stepsize/2 columns to right
				.out_up				(out_up_array[i]),
				.out_down			(out_down_array[i])
			);
		end
	endgenerate
	

endmodule