//Diamond-Square Column Solver

// Implement an the M10K block write to/ read fom memory
module M10K_512_20(
	output reg 		[7:0] q,
	input  			[7:0] data,
	input 			[8:0] wraddress, rdaddress,
	input 				  wren, clock
);
	reg 			[7:0] mem [127:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
	
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
	input   [8:0] 	col_id,
	input	[7:0]	r,
	input   [8:0]   vga_r_addr,
	input   [4:0] 	dim_power,
	input   [7:0] 	val_l, val_r, val_l_down, val_r_down,
	input   [8:0]   dim,
	output  reg		done,
	output  [8:0]   step_size, 
	output  reg [7:0] 	r_data_up, r_data_down, vga_r_data
);

	wire	[7:0] 	m10k_r_data;
	wire	[8:0]	half;
	reg	 	[7:0] 	m10k_w_data;
	reg	 	[8:0] 	m10k_r_addr, m10k_w_addr;
	reg 	        m10k_w_en;
	

	reg     [3:0] 	step_power;
	reg		[3:0]	state;//, done_state;
	reg				m10k_init;
	
	reg     [9:0]   sum; //Used to add all four values together, this is 10 bits instead of 8 for overflow
	
	reg		[8:0]	row_id;

	assign step_size = 9'b1 << step_power;
	assign half = step_size >> 9'b1;

	
	wire [8:0] read_addr = row_id + step_size + half; //may overflow, checked in ternary below
	
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
			step_power  <= dim_power;
			row_id      <= half;
			m10k_init   <= 1'b1;
			
			m10k_w_addr <= 9'b0; 
			m10k_w_en   <= 1'b1;
			m10k_w_data <= 8'b0;
			m10k_r_addr <= 9'b0;
			
			done        <= 1'b0;
		end
		
		if(m10k_init) begin
			if(m10k_w_addr < (dim-1)) begin
				m10k_w_addr <= m10k_w_addr + 9'b1;
			end
			else begin //Finished initializing the M10k blocks
				m10k_w_en <= 1'b0;
				m10k_init <= 1'b0;
				state <= 4'd0;
				//done_state <= 4'd0;
			end
		end
		
		if(done) begin
			case (state)
				4'd0 : begin
					//Do m10k read for the input m10k position
					m10k_r_addr <= vga_r_addr;
				
					state <= 4'd1;
				end
				4'd1 : begin
					state <= 4'd2;
				end
				4'd2 : begin
					vga_r_data <= m10k_r_data;
				
					state <= 4'd0;
				end
				default : state <= 4'd0;
			endcase
		end
		else begin
			case (state)
				4'd0 : begin
					if((col_id == 9'd0) || (col_id == (dim-9'b1))) begin
						m10k_w_en <= 1'd1;
						m10k_w_addr <= 9'b0;
						m10k_w_data <= 8'hee;
					end
					state <= 4'd1;
				end
				
				4'd1 : begin
					if((col_id == 0) || (col_id == (dim-9'b1))) begin
						m10k_w_en <= 1'd1;
						m10k_w_addr <= (dim-9'b1);
						m10k_w_data <= 8'hbb;
					end
					state <= 4'd2;
				end
				
				4'd2 : begin
					// Disable corner writes
					m10k_w_en <= 0;
					// Read bottom row value
					m10k_r_addr <= 0;
					
					state <= 4'd3;
				end
				
				4'd3 : begin
					state <= 4'd4;
				end
				
				4'd4 : begin
					r_data_down <= m10k_r_data;
					m10k_r_addr <= step_size; // Upper read value will be step_size away
					state <= 4'd5;
				end
				
				4'd5 : begin
					state <= 4'd6;
				end
				
				4'd6 : begin
					r_data_up <= m10k_r_data; //Used for nearby iterators that need this value blocking
					state <= 4'd7;
				end
				
				4'd7 : begin
					// Take col_id, subtract step_size >> 2 --> AND with step_size-1 --> gets you mod step_size
					if (!((col_id - half) & (step_size - 9'b1))) begin 
						m10k_w_en <= 1'b1;
						m10k_w_addr <= row_id;
						sum = val_l + val_r + val_l_down + val_r_down; //Resolve val_l and val_r as inputs
						m10k_w_data <= (sum >> 2) + (r & ((1 << step_size) - 1)); // Maybe syntax error???
					end
					r_data_down <= r_data_up;
					
					if ((step_size + row_id) < dim) begin
						m10k_r_addr <= ((read_addr) >= dim) ? (read_addr - dim + 9'b1) : (read_addr);
						row_id <= row_id + step_size;
						
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
				
				4'd8 : begin
					m10k_w_en <= 1'b0;
					state <= 4'd9;
				end
				
				4'd9 : begin
					r_data_down <= m10k_r_data; // Odd column this will be garbage
					m10k_r_addr <= row_id + half; // Upper read value will be step_size away
					state <= 4'd10;
				end
				
				4'd10 : begin
					//Wait stage for upper square step read
					state <= 4'd11;
				end
				
				4'd11 : begin
					r_data_up <= m10k_r_data; //Used for nearby iterators that need this value blocking
					state <= 4'd12;
				end
				
				4'd12 : begin
					//col_id % (step_size >> 1)
					if (!(col_id & ((step_size >> 1)-9'b1))) begin
						m10k_w_en <= 1'b1;
						m10k_w_addr <= row_id;
						
						if ((col_id >> (step_power - 9'b1)) & 8'b1) //Odd columns use down values
							sum = val_l_down + val_r_down + r_data_up + r_data_down;
						else //Even columns use up values
							sum = val_l + val_r + r_data_up + r_data_down;
						
						m10k_w_data <= (sum >> 2) + (r & ((1 << step_size) - 1)); // Maybe syntax error???
					end
					r_data_down <= r_data_up;
					
					// Queue up next read, for up reg if we have more squares to do (haven't reached the end)
					if ((step_size + row_id) < dim) begin
						m10k_r_addr <= (read_addr >= dim) ? (read_addr - dim + 9'b1) : read_addr;
						row_id <= row_id + step_size;
						
						state <= 4'd10; 					
					end
					else begin
						// Finished Square Step, moving to Diamond Step
						m10k_r_addr <= 0;

						//TODO: Random updates					
							
						if (!((col_id >> (step_power - 9'b1)) & 8'b1)) begin
							state <= 4'd13;
						end
						else begin
							if (step_power > 1) begin
								row_id <= (1 << (step_power-9'b1)) >> 1;
								step_power <= step_power-9'b1;
								state <= 4'd3;
							end
							else begin
								done <= 1'b1;
								state <= 4'd0;
							end

						end
					end
				end
				
				4'd13 : begin
					m10k_w_en <= 1'b0;
					state <= 4'd14;
				end
				
				4'd14 : begin
					m10k_w_en <= 1'b0;
					state <= 4'd15;
				end
				
				4'd15 : begin
					if (step_power > 1) begin
						row_id <= (1 << (step_power-9'b1)) >> 1;
						step_power <= step_power-9'b1;
						state <= 4'd3;
					end
					else begin
						done <= 1'b1;
						state <= 4'd0;
					end
					
					m10k_w_en <= 1'b0;
				end
				
				default : state <= 4'd0;
				
			endcase
			
			/* // Write top corners to memory, only on far left and right solver - occurs one time
			if (state == 4'd0) begin
				if((col_id == 9'd0) || (col_id == (dim-9'b1))) begin
					m10k_w_en <= 1'd1;
					m10k_w_addr <= 9'b0;
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
					m10k_w_data <= (sum >> 2) + (r & ((1 << step_size) - 1)); // Maybe syntax error???
				end
				r_data_down <= r_data_up;
				
				if ((step_size + row_id) < dim) begin
					m10k_r_addr <= ((read_addr) >= dim) ? (read_addr - dim + 9'b1) : (read_addr);
					row_id <= row_id + step_size;
					
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
					
					if ((col_id >> (step_power - 9'b1)) & 8'b1) //Odd columns use down values
						sum = val_l_down + val_r_down + r_data_up + r_data_down;
					else //Even columns use up values
						sum = val_l + val_r + r_data_up + r_data_down;
					
					m10k_w_data <= (sum >> 2) + (r & ((1 << step_size) - 1)); // Maybe syntax error???
				end
				r_data_down <= r_data_up;
				
				// Queue up next read, for up reg if we have more squares to do (haven't reached the end)
				if ((step_size + row_id) < dim) begin
					m10k_r_addr <= (read_addr >= dim) ? (read_addr - dim + 9'b1) : read_addr;
					row_id <= row_id + step_size;
					
					state <= 4'd10; 					
				end
				else begin
					// Finished Square Step, moving to Diamond Step
					m10k_r_addr <= 0;

					//TODO: Random updates					
						
					if (!((col_id >> (step_power - 9'b1)) & 8'b1)) begin
						state <= 4'd13;
					end
					else begin
						if (step_power > 1) begin
							row_id <= (1 << (step_power-9'b1)) >> 1;
							step_power <= step_power-9'b1;
							state <= 4'd3;
						end
						else begin
							done <= 1'b1;
							state <= 4'd0;
						end

					end
				end
			end
			
			if (state == 4'd13) begin
				m10k_w_en <= 1'b0;
				state <= 4'd14;
			end
			
			if (state == 4'd14) begin
				m10k_w_en <= 1'b0;
				state <= 4'd15;
			end
			
			if (state == 4'd15) begin
				if (step_power > 1) begin
					row_id <= (1 << (step_power-9'b1)) >> 1;
					step_power <= step_power-9'b1;
					state <= 4'd3;
				end
				else begin
					done <= 1'b1;
					state <= 4'd0;
				end
				
				m10k_w_en <= 1'b0;
			end*/
		end 
	end
	

	M10K_512_20 ds_m10k (
		.clock     (clk),
		.wren      (m10k_w_en),
		.q         (m10k_r_data),
		.data      (m10k_w_data),
		.wraddress (m10k_w_addr),
		.rdaddress (m10k_r_addr)
	);


endmodule