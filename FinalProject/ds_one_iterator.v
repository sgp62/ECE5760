//FinalProj_DS_One_Iterator

// Implement an the M10K block write to/ read fom memory
module M10K_512_20(
	output reg signed [19:0] q,
	input signed 		[19:0] data,
	input 				[8:0] wraddress, rdaddress,
	input 				wren, clock
);
	reg signed 			[19:0] mem [511:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
	always @ (posedge clock)
	begin
		if (wren) 
			mem[wraddress] <= data;
	end
	always @ (posedge clock) begin
		q <= mem[rdaddress];
	end
endmodule


module diamond_step (
	input		[19:0]	tl, tr, bl, br, r,
	output	[19:0]	z
);
	wire 		[31:0] 	avg;
	
	assign avg = ((tl + tr + bl + br) >> 2) + r;
	assign z = avg[19:0];
	
endmodule


module square_step (
	input		[19:0]	ml, mr, mt, mb, r,
	output	[19:0]	z
);
	wire 		[31:0] 	avg;
	
	assign avg = ((ml + mr + mt + mb) >> 2) + r;
	assign z = avg[19:0];
	
endmodule



module diamond_square_operator (#parameter dim = 257) (
	input clk, reset,
	output 	[9:0]		x,y,
	output	[19:0]	z
	
);
	wire		[19:0] 	m10k_r_data[dim-1:0];
	reg	 	[19:0] 	m10k_w_data[dim-1:0];
	reg	 	[8:0] 	m10k_r_addr[dim-1:0], m10k_w_addr[dim-1:0];
	reg 	        		m10k_w_en[dim-1:0];

	reg 		[8:0]		step_size;
	reg 		[19:0]	r;
	reg 		[9:0]		i;
	reg		[3:0]		state;
	reg		[3:0]		prev_state;
	
	// Initial corner values, set on reset
	reg		[19:0]	tl;
	reg		[19:0]	tr;
	reg		[19:0]	bl;
	reg		[19:0]	br;
	
	reg		[3:0]		maxval;
	reg		[3:0]		minval;
	/* Indicates when all pixels are done.
		Occurs after 512 iterations of either diamond or square for dim = 513
		Should increment after corners are initially set and after values for a given stage are fully written to memory
	*/
	
	reg		[9:0]		not_done;
	
	// Initialize state variables
	assign state = 0;
	assign prev_state = 0;
	
	// Initialize done counter
	assign not_done = 513;

	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			step_size <= dim-1;
			for (i=0; i<dim; i=i+1) begin
				m10k_r_addr[i] <= 0;
				m10k_w_en[i] <= 0;
			end
			
			//TODO: Initialize 4 Corners, figure out random init
			
			//Also generate 
			
			// Initialize random values for corners
			// maxval and minval get closer together, so they can't be fixed
			//Not synthesizable, need to use PIO port 
			tl <= $urandom_range(maxval, minval);
			tr <= $urandom_range(maxval, minval);
			bl <= $urandom_range(maxval, minval);
			br <= $urandom_range(maxval, minval);
			
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
			state <= 4'd0;
		end
		// Write corners to memory
		if (state == 4'd0) begin
			m10k_w_en[0] <= 1;
			m10k_w_en[dim-1] <= 1;
			// loop through this state until the four corners are written to memory
			
			// 
			if(m10k_w_d)
			state <= 4'd0;
		end
		// Diamond Step
		if (state == 2) begin
			// Divide step_size by two after every time we loop through one diamond step and one square step
			if (prev_state == 4) begin
				step_size <= step_size >> 1;
			end
		
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