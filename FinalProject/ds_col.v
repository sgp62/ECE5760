//Diamond-Square Column Solver

// Implement an the M10K block write to/ read fom memory
module M10K_512_20(
	output reg signed [7:0] q,
	input signed 		[7:0] data,
	input 				[8:0] wraddress, rdaddress,
	input 				wren, clock
);
	reg signed 			[7:0] mem [511:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
	always @ (posedge clock)
	begin
		if (wren) 
			mem[wraddress] <= data;
	end
	always @ (posedge clock) begin
		q <= mem[rdaddress];
	end
endmodule


module diamond_square_col (
	input        clk, reset,
	input  [8:0] col_id,
	input  [9:0] dim,
	input  [7:0] val_l, val_r, val_l_down, val_r_down,
	output [7:0] out_up, out_down
);

	wire	[7:0] 	m10k_r_data;
	reg		[7:0]   r_data_down, r_data_up;
	reg	 	[7:0] 	m10k_w_data;
	reg	 	[8:0] 	m10k_r_addr, m10k_w_addr;
	reg 	        m10k_w_en;

	reg 	[8:0]	step_size;
	reg 	[7:0]	r;
	reg 	[9:0]	i;
	reg		[3:0]	state;
	
	reg     [9:0]   sum; //Used to add all four values together, thus is 10 bits instead of 8 for overflow

	/* Indicates when all pixels are done.
		Occurs after 512 iterations of either diamond or square for dim = 513
		Should increment after corners are initially set and after values for a given stage are fully written to memory
	*/
	assign out_up = r_data_up;
	assign out_down = r_data_down;

	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			step_size <= dim-1;
			
			m10k_w_en <= 0;
			
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
		// Write corners to memory, only on far left and right solver
		if (state == 4'd0) begin
		
			if(col_id == 0 || col_id == dim-1) begin
				m10k_w_en <= 1'd1;
				// Writes top corners
				m10k_w_addr <= 0;
				m10k_w_data <= 8'hee;
			end
			
			state <= 4'd1;
		end
		
		if (state == 4'd1) begin
		
			if(col_id == 0 || col_id == dim-1) begin
				m10k_w_en <= 1'd1;
				// Writes bottom corners
				m10k_w_addr <= {dim-1}[8:0];
				m10k_w_data <= 8'hbb;
			end

			state <= 4'd2;
		end
		// Read Setup Stage for Diamond Stage
		if (state == 4'd2) begin
			//Disable corner writes
			m10k_w_en <= 0;
			
			//Read bottom row value
			m10k_r_addr <= 0;
			
			state <= 4'd3;
		end
		//Read Latency stage for M10k
		if(state == 4'd3) begin
			state <= 4'd4;
		end
		
		//Reading upper value, assign down reg to previously read value
		//Might need extra delay cycle here for M10k read latency once synthesized
		if(state == 4'd4) begin
			r_data_down <= m10k_r_data;
			m10k_r_addr <= step_size; // Upper read value will be step_size away
			
			state <= 4'd5;
		end
		//stall stage
		if(state == 4'd5) begin
			state <= 4'd6;
		end
		
		//Assign up reg to up value just read in, now we are ready to do our pipeline
		if(state == 4'd6) begin 
			r_data_up <= m10k_r_data; //Used for nearby iterators that need this value blocking
			
			state <= 4'd7;
		end
		
		//Diamond Stage
		if(state <= 4'd7) begin//TODO: Figure out which columns get to write.Should they know based on their ID or does the operator have to enable?
			m10k_w_en <= 1'b1;
		
			sum = val_l + val_r + val_l_down + val_r_down;
			m10k_w_data <= {(sum >> 2)}[7:0]; //Maybe syntax error???
			
			//Queue up next read, for up reg if we have more diamonds to do (haven't reached the end)
			m10k_r_addr <= 
			//Set down reg equal to previous up reg
			
			//State must stall then go back to 7 if we have more to do, otherwise move on to square step
			
		end
		
		
	end
	/*
		// Divide step_size by two after every time we loop through one diamond step and one square step
	if (prev_state == 4) begin
		step_size <= step_size >> 1;
	end
	*/
	

	M10K_512_20 ds_m10k (
		.clock     (clk),
		.wren      (m10k_w_en),
		.q         (m10k_r_data),
		.data      (m10k_w_data),
		.wraddress (m10k_w_addr),
		.rdaddress (m10k_r_addr)
	);


endmodule