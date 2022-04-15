//FinalProj_DS_One_Iterator



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
			in_bit <= (num[6] ^ num[5]) ^ num[4];
			num <= num << 1;
			num[0] <= in_bit;
		end
		
	end

endmodule


module diamond_square_operator (#parameter dim_power = 8) (
	input clk, reset,
	output 	[9:0]	x,y,
	output	[7:0]	z
	
);

	reg 	[9:0]	i;
	wire		 	done;
	wire    [8:0]	dim;
	
	
	assign dim = (1 << dim_power) + 8'b1;

	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin

		end
		//Will need clocked logic block to send pixel values up to top level module after all have been calculated
	end
	
	generate
		genvar i;
		for (i = 0; i < dim; i=i+1) begin: col_gen
			diamond_square_col my_col(
			
				input       	clk, reset,
	input  [8:0] 	col_id,
	//input  [9:0] 	dim,
	input  [4:0] 	dim_power,// TODO ***** need to set in higher level module to actually use this
	input  [7:0] 	val_l, val_r, val_l_down, val_r_down,
	output [7:0] 	out_up, out_down
				.clk          		(clk),
				.reset        		(reset),
				.col_id             (i),
				.dim_power          (dim_power),
				.val_l				(),
				.val_r				(),
				.val_l_down			(),
				.val_r_down			(),
				.out_up				(),
				.out_down			()
			);
		end
	endgenerate
	

endmodule