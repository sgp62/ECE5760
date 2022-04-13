//FinalProj_DS_One_Iterator




module diamond_step (
	input		[7:0]	tl, tr, bl, br, r,
	output	[7:0]	z
);
	wire 		[31:0] 	avg;
	
	assign avg = ((tl + tr + bl + br) >> 2) + r;
	assign z = avg[7:0];
	
endmodule


module square_step (
	input		[7:0]	ml, mr, mt, mb, r,
	output	[7:0]	z
);
	wire 		[31:0] 	avg;
	
	assign avg = ((ml + mr + mt + mb) >> 2) + r;
	assign z = avg[7:0];
	
endmodule

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


module diamond_square_operator (#parameter dim = 257) (
	input clk, reset,
	output 	[9:0]	x,y,
	output	[7:0]	z
	
);
	wire	[7:0] 	m10k_r_data[dim-1:0];
	reg		[7:0]   r_data_down[dim-1:0];
	reg	 	[7:0] 	m10k_w_data[dim-1:0];
	reg	 	[8:0] 	m10k_r_addr[dim-1:0], m10k_w_addr[dim-1:0];
	reg 	        m10k_w_en[dim-1:0];

	reg 	[8:0]	step_size;
	reg 	[7:0]	r;
	reg 	[9:0]	i;
	reg		[3:0]	state;
	
	// Initial corner values, set on reset
	reg		[7:0]	tl;
	reg		[7:0]	tr;
	reg		[7:0]	bl;
	reg		[7:0]	br;
	
	reg		[3:0]	maxval;
	reg		[3:0]	minval;
	/* Indicates when all pixels are done.
		Occurs after 512 iterations of either diamond or square for dim = 513
		Should increment after corners are initially set and after values for a given stage are fully written to memory
	*/
	
	reg		[9:0]		not_done;



	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			step_size <= dim-1;
			for (i=0; i<dim; i=i+1) begin
				m10k_r_addr[i] <= 0;
				m10k_w_en[i] <= 0;
			end
			
			not_done <= 10'd513;
			state <= 4'd0;
			//TODO: Set up state machine
			/*
					1. Write four corners to memory
					2. Read all values from memory
					3. Diamond Step
					4. Write all values to memory
					5. Read all values from memory
					6. Square Step
					7. Write all values to memory
					8. Loop through steps 2 - 7 until all values written to memory (occurs after dim/2 loops throguh steps 2-7)
			*/
			
		end
		// Write corners to memory
		if (state == 4'd0) begin
			m10k_w_en[0] <= 1'd1;
			m10k_w_en[dim-1] <= 1'd1;
			
			// Writes top two corners
			m10k_w_addr[0] <= 0;
			m10k_w_addr[dim-1] <= 0;
			m10k_w_data[0] <= 20'h00fff;
			m10k_w_data[dim-1] <= 20'h00eff;
			
			state <= 4'd1;
		end
		if (state == 4'd1) begin
			m10k_w_en[0] <= 1;
			m10k_w_en[dim-1] <= 1;
			
			//Writes bottom two corners
			m10k_w_addr[0] <= {dim-1}[8:0];
			m10k_w_addr[dim-1] <= {dim-1}[8:0];
			m10k_w_data[0] <= 20'h01fff;
			m10k_w_data[dim-1] <= 20'h02eff;
			

			state <= 4'd2;
		end
		// Read Setup Stage for Diamond Stage
		if (state == 4'd2) begin
			//Disable corner writes
			m10k_w_en[0] <= 0;
			m10k_w_en[dim-1] <= 0;
			
			//Read bottom row, possibly store in bottom registers
			
		
		end
		
		
		
		// Square Step
		if (state == 3) begin
		
		end
		// Wait state to accomodate read latency
		if (state == 4) begin
			
			if (prev_state == 2) begin
				prev_state <= 4;
				state <= 3;
			end
			else begin
			
			end
			
		end
		// Write state to accomodate multiple writes for a given step
		if (state == 5) begin
		
			not_done = not_done - 1;
		end
	end
	/*
		// Divide step_size by two after every time we loop through one diamond step and one square step
	if (prev_state == 4) begin
		step_size <= step_size >> 1;
	end
	*/
	
	generate
		genvar i;
		for (i = 0; i < dim; i=i+1) begin: m10k_gen
			M10K_512_20 ds_m10k (
				.clock     (clk),
				.wren      (m10k_w_en[i]),
				.q         (m10k_r_data[i]),
				.data      (m10k_w_data[i]),
				.wraddress (m10k_w_addr[i]),
				.rdaddress (m10k_r_addr[i])
			);
		end
	endgenerate

endmodule