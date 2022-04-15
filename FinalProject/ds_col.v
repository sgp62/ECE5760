//Diamond-Square Column Solver

// Implement an the M10K block write to/ read fom memory
module M10K_512_20(
	output reg 		[7:0] q,
	input  			[7:0] data,
	input 			[8:0] wraddress, rdaddress,
	input 				  wren, clock
);
	reg 			[7:0] mem [511:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
	
	always @ (posedge clock)
	begin
		if (wren) 
			mem[wraddress] = data;
	end
	always @ (posedge clock) begin
		q = mem[rdaddress];
	end
endmodule


module diamond_square_col (
	input       	clk, reset,
	input  [8:0] 	col_id,
	//input  [9:0] 	dim,
	input  [4:0] 	dim_power,// TODO ***** need to set in higher level module to actually use this
	input  [7:0] 	val_l, val_r, val_l_down, val_r_down,
	output [8:0]    step_size_out,
	output [7:0] 	out_up, out_down
);

	wire	[7:0] 	m10k_r_data;
	wire	[8:0]	half;
	reg		[7:0]   r_data_down, r_data_up;
	reg	 	[7:0] 	m10k_w_data;
	reg	 	[8:0] 	m10k_r_addr, m10k_w_addr;
	reg 	        m10k_w_en;

	
	wire    [8:0] 	dim;
	wire 	[8:0]	step_size;
	reg     [3:0] 	step_power;
	reg 	[7:0]	r;
	reg 	[9:0]	i;
	reg		[3:0]	state;
	reg				m10k_init;
	
	reg     [9:0]   sum; //Used to add all four values together, thus is 10 bits instead of 8 for overflow
	
	reg		[8:0]	row_id;

	/* Indicates when all pixels are done.
		Occurs after 512 iterations of either diamond or square for dim = 513
		Should increment after corners are initially set and after values for a given stage are fully written to memory
	*/
	assign step_size_out = step_size;
	assign out_up = r_data_up;
	assign out_down = r_data_down;
	assign step_size = 9'b1 << step_power;
	assign half = step_size >> 9'b1;
	assign dim = (9'b1 << dim_power) + 9'b1; // so in our case ideally 257

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
	

	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			step_power <= dim_power;
			state <= 4'd15;
			row_id <= half;
			m10k_init <= 1'b1;
			
			m10k_w_addr <= 9'b0; 
			m10k_w_en <= 1'b1;
			m10k_w_data <= 8'b0;
			m10k_r_addr <= 9'b0;
		end
		if(m10k_init) begin
			if(m10k_w_addr < (dim-1)) begin
				m10k_w_addr <= m10k_w_addr + 9'b1;
			end
			else begin //Finished initializing the M10k blocks
				m10k_w_en <= 1'b0;
				m10k_init <= 1'b0;
				state <= 4'd0;
			end
		end
		
		// Write top corners to memory, only on far left and right solver - occurs one time
		if (state == 4'd0) begin
			if((col_id == 0) || (col_id == (dim-9'b1))) begin
				m10k_w_en <= 1'd1;
				m10k_w_addr <= 0;
				m10k_w_data <= 8'hee;
			end
			state <= 4'd1;
		end
		
		// Write bottom corners to memory, only on far left and right solver - occurs one time
		if (state == 4'd1) begin
			if((col_id == 0) || (col_id == (dim-9'b1))) begin
				m10k_w_en <= 1'd1;
				m10k_w_addr <= (dim-9'b1);
				m10k_w_data <= 8'hbb;
			end
			state <= 4'd2;
		end
		
		// Read Setup Stage for Diamond Stage
		if (state == 4'd2) begin
			// Disable corner writes
			m10k_w_en <= 0;
			// Read bottom row value
			m10k_r_addr <= 0;
			state <= 4'd3;
		end
		
		// Read Latency stage for bottom row value read
		if(state == 4'd3) begin
			state <= 4'd4;
		end
		
		// Reading upper value, assign down reg to previously read value
		// Might need extra delay cycle here for M10k read latency once synthesized
		if(state == 4'd4) begin
			r_data_down <= m10k_r_data;
			m10k_r_addr <= step_size; // Upper read value will be step_size away
			state <= 4'd5;
		end
		
		// Wait stage for upper value read
		if(state == 4'd5) begin
			state <= 4'd6;
		end
		
		// Assign up reg to up value just read in, now we are ready to do our pipeline
		if(state == 4'd6) begin 
			r_data_up <= m10k_r_data; //Used for nearby iterators that need this value blocking
			state <= 4'd7;
		end
		
		// Diamond Step
		if(state == 4'd7) begin
			// Take col_id, subtract step_size >> 2 --> AND with step_size-1 --> gets you mod step_size
			if (!((col_id - half) & (step_size - 9'b1))) begin 
				m10k_w_en <= 1'b1;
				m10k_w_addr <= row_id;
				sum = val_l + val_r + val_l_down + val_r_down; //Resolve val_l and val_r as inputs
				m10k_w_data <= (sum >> 2); // Maybe syntax error???
			end
			
			
			if ((step_size + row_id) < dim) begin
				row_id <= row_id + step_size;
				r_data_down <= r_data_up;
				m10k_r_addr <= row_id + step_size + half; //TODO: Address wrap around
				state <= 4'd5; 					
			end
			else begin
				// Finished Diamond Step, moving to Square Step
				if ((col_id >> (step_power - 9'b1)) & 8'b1) begin
					// ODD column
					row_id <= 0;
					// Reading top value for wraparound purposes
					m10k_r_addr <= (dim-9'b1) - half;
				end
				else begin
					// EVEN column (assuming column # start with 0)
					row_id <= half;
					m10k_r_addr <= 0;
				end
				state <= 4'd8;
			end
		end
		
		// Wait stage for starting Square Step initial read
		if(state == 4'd8) begin
			m10k_w_en <= 1'b0;
			state <= 4'd9;
		end
		
		// Upper read stage for square Step
		if (state == 4'd9) begin
			r_data_down <= m10k_r_data; // Odd column this will be garbage
			m10k_r_addr <= row_id + half; // Upper read value will be step_size away
			state <= 4'd10;
		end
		
		if(state == 4'd10) begin
			//Wait stage for upper square step read
			state <= 4'd11;
		end
		
		// Assign up reg to up value just read in, now we are ready to do our pipeline
		if(state == 4'd11) begin 
			r_data_up <= m10k_r_data; //Used for nearby iterators that need this value blocking
			state <= 4'd12;
		end
		
		if (state == 4'd12) begin //Square Step
			//col_id % (step_size >> 1)
			if (!(col_id & ((step_size >> 1)-9'b1))) begin
				m10k_w_en <= 1'b1;
				m10k_w_addr <= row_id;
				sum = val_l + val_r + r_data_up + r_data_down; //Resolve val_l and val_r as inputs
				m10k_w_data <= (sum >> 2); // Maybe syntax error???
			end
			// Queue up next read, for up reg if we have more squares to do (haven't reached the end)
			if ((step_size + row_id) < dim) begin
				row_id <= row_id + step_size;
				r_data_down <= r_data_up;
				m10k_r_addr <= row_id + step_size + half; //TODO: Address wrap around
				state <= 4'd10; 					
			end
			else begin
				// Finished Square Step, moving to Diamond Step
				m10k_r_addr <= 0; //TODO: Verify
				step_power <= step_power-9'b1; //Blocking assignment because half needs to change
				row_id <= (1 << (step_power-9'b1)) >> 1;
				//TODO: Random updates
				state <= 4'd3;
			end
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