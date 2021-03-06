//Single operator Diamond Square

module M10K_512_8(
	output reg 		[7:0] q,
	input  			[7:0] data,
	input 			[8:0] wraddress, rdaddress,
	input 				  wren, clock
);
	reg 			[7:0] mem [256:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
	
	always @ (posedge clock)
	begin
		if (wren) 
			mem[wraddress] = data;
	end
	always @ (posedge clock) begin
		q = mem[rdaddress];
	end
endmodule

module rand63(rand_out, seed_in, state_in, clk, reset);
	// 16-bit random number on every cycle
	output wire [15:0] rand_out ;
	// the clocks and stuff
	input wire [3:0] state_in ;
	input wire clk, reset ;
	input wire [63:1] seed_in; // 128 bits is 32 hex digits 0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff

	reg [4:1] sr1, sr2, sr3, sr4, sr5, sr6, sr7, sr8, 
				sr9, sr10, sr11, sr12, sr13, sr14, sr15, sr16;
	
	// state names
	parameter react_start=4'd0 ;

	// generate random numbers	
	assign rand_out = {sr1[3], sr2[3], sr3[3], sr4[3],
							sr5[3], sr6[3], sr7[3], sr8[3],
							sr9[3], sr10[3], sr11[3], sr12[3],
							sr13[3], sr14[3], sr15[3], sr16[3]} ;
							
	always @ (posedge clk) //
	begin
		
		if (reset)
		begin	
			//init random number generator 
			sr1 <= seed_in[4:1] ;
			sr2 <= seed_in[8:5] ;
			sr3 <= seed_in[12:9] ;
			sr4 <= seed_in[16:13] ;
			sr5 <= seed_in[20:17] ;
			sr6 <= seed_in[24:21] ;
			sr7 <= seed_in[28:25] ;
			sr8 <= seed_in[32:29] ;
			sr9 <= seed_in[36:33] ;
			sr10 <= seed_in[40:37] ;
			sr11 <= seed_in[44:41] ;
			sr12 <= seed_in[48:45] ;
			sr13 <= seed_in[52:49] ;
			sr14 <= seed_in[56:53] ;
			sr15 <= seed_in[60:57] ;
			sr16 <= {1'b0,seed_in[63:61]} ;
		end
		
		// update 63-bit shift register
		// 16 times in parallel
		else 
		begin
			if(state_in == react_start) 
			begin
				sr1 <= {sr1[3:1], sr16[3]^sr15[3]} ;
				sr2 <= {sr2[3:1], sr16[3]^sr1[4]}  ;
				sr3 <= {sr3[3:1], sr1[4]^sr2[4]}  ;
				sr4 <= {sr4[3:1], sr2[4]^sr3[4]}  ;
				sr5 <= {sr5[3:1], sr3[4]^sr4[4]}  ;
				sr6 <= {sr6[3:1], sr4[4]^sr5[4]}  ;
				sr7 <= {sr7[3:1], sr5[4]^sr6[4]}  ;
				sr8 <= {sr8[3:1], sr6[4]^sr7[4]}  ;
				sr9 <= {sr9[3:1], sr7[4]^sr8[4]}  ;
				sr10 <= {sr10[3:1], sr8[4]^sr9[4]}  ;
				sr11 <= {sr11[3:1], sr9[4]^sr10[4]}  ;
				sr12 <= {sr12[3:1], sr10[4]^sr11[4]}  ;
				sr13 <= {sr13[3:1], sr11[4]^sr12[4]}  ;
				sr14 <= {sr14[3:1], sr12[4]^sr13[4]}  ;
				sr15 <= {sr15[3:1], sr13[4]^sr14[4]}  ;
				sr16 <= {sr16[3:1], sr14[4]^sr15[4]}  ;
			end	
		end
	end
endmodule

module diamond_square_single_operator #(parameter dim_power = 3, parameter dim = 9) (
	input 			clk, reset, ack,
	input 	[31:0]	rand_seed, corners,
	output 	[9:0]	x,y,
	output	[7:0]	z,
	output	reg 	new_value,
	output          done_out
	
);

	wire    [8:0]	step_size, half;

	//wire	[63:1]	seed;
	//wire	[15:0]	r;
	wire	[63:1]	seed [15:0];//[(dim >> 1): 0];
	wire	[15:0]	r [15:0];//[(dim >> 1): 0];
	
	wire    [7:0]   out_vga_data, rand_term;
	reg 	done;
	
	reg     [7:0] 	val_l, val_r, val_l_down, val_r_down, val_up, val_down, z_reg;
	reg     [8:0]   col_select, done_row, done_col;
	reg     [3:0]   vga_state;
	
	reg     [9:0]   x_reg, y_reg, n;
	
	wire	[7:0] 	m10k_r_data [(dim-1) : 0];
	reg	 	[7:0] 	m10k_w_data;
	reg	 	[8:0] 	m10k_r_addr [(dim-1) : 0];
	reg	 	[8:0]   m10k_w_addr;
	reg 	[(dim-1) : 0] m10k_w_en;
	

	reg     [3:0] 	step_power;
	reg		[3:0]	state;//, done_state;
	reg				m10k_init;
	
	reg     [9:0]   sum; //Used to add all four values together, this is 10 bits instead of 8 for overflow
	
	reg		[8:0]	row_id;

	assign step_size = 9'b1 << step_power;
	assign half = step_size >> 9'b1;
	//assign rand_term = (r[7:0] & ((1 << step_size) - 1));
	assign seed[0] = {rand_seed[30:0],rand_seed};
	
	
	generate 
		genvar s;
		for(s = 1; s < 16; s=s+1) begin: seed_gen
			assign seed[s] = seed[0] << s;
		end
	endgenerate
	
/* 	assign seed[0] = 63'hff7fffcf;
	assign seed[1] = 63'h8ffff1ffd;
	assign seed[2] = 63'h4f6ffaf0f;
 	assign seed[3] = 63'headdeadbeef;
	assign seed[4] = 63'heeeeeeeeeeeee;
    assign seed[5] = 63'haed409210291;
	assign seed[6] = 63'h123456789;
	assign seed[7] = 63'hfffffffffffffff;
	assign seed[8] = 63'hba0000000000000;
	assign seed[9] = 63'h1115555599988;
	assign seed[10] = 63'h666999666999;
	assign seed[11] = 63'hbbbbbeeeee0000;
	assign seed[12] = 63'h3;
	assign seed[13] = 63'h78965422211140;
	assign seed[14] = 63'h620200011011999;
	assign seed[15] = 63'h72820000002827; */
	//assign seed[16] = 63'h99999999;

	assign rand_term = ((1 << step_size) - 1) & ((col_select & 8'b1) ? r[col_select & 9'd15][15:8] : r[col_select & 9'd15][7:0]);     //number shift regs: (1 << (dim_power - 2)) + 1  ***NOT RIGHT******
	assign done_out = done;
	//assign rand_term = 0;

	wire [8:0] up_read_addr = row_id + step_size + half; //may overflow, checked in ternary below
	
	assign x = x_reg;//col_select;
	assign y = y_reg;//(addr_counter == 9'd0) ? dim-1 : addr_counter-1;
	assign z = z_reg;//out_vga_array[x_reg];
	//assign dim_out = dim;
	
	//assign seed = 63'hff7fffcf;
	
	


	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			col_select	 <= (dim-1)>>1;
			done_row     <= 9'd0;
			done_col     <= 9'd0;
			vga_state    <= 4'd0;
			state        <= 4'd0;
			x_reg        <= 10'b0;
			y_reg        <= 10'b0;
			new_value	 <= 1'b0;
			
			step_power  <= dim_power;
			row_id      <= half;
			m10k_init   <= 1'b1;
			
			for(n = 0; n < dim; n=n+1) begin
				m10k_r_addr[n] <= 9'b0;
			end
			m10k_w_addr <= 9'b0; 
			m10k_w_en   <= {dim{1'b1}};
			m10k_w_data <= 8'b0;
			
			done        <= 1'b0;
		end
		else begin
			if(done) begin
				case (state)
					4'd0 : begin
						//Do m10k read for the input m10k position
						m10k_r_addr[done_col] <= done_row;
						new_value <= 1'b0;
						state <= 4'd1;
					end
					4'd1 : begin
						state <= 4'd2;
					end
					4'd2 : begin
						z_reg <= m10k_r_data[done_col];
						x_reg <= done_col;
						y_reg <= done_row;
						new_value <= 1'b1;

						if(ack)  begin
							if ((done_col == dim-9'd1) && (done_row == dim-9'd1)) begin
								state <= 4'd3;
							end
							else if (done_row == dim-9'd1) begin
								done_col <= done_col + 9'd1;
								done_row <= 0;
								state <= 4'd0;
							end
							else begin
								done_row <= done_row + 9'd1;
								state <= 4'd0;
							end
						end
					end
					4'd3: begin //Idle state
					
					end
					default : state <= 4'd3;
				endcase
			end
			else if(m10k_init) begin
				if(m10k_w_addr < (dim-1)) begin
					m10k_w_addr <= m10k_w_addr + 9'b1;
				end
				else begin //Finished initializing the M10k blocks
					m10k_w_en <= {dim{1'b0}};
					m10k_init <= 1'b0;
					state <= 4'd0;
					//done_state <= 4'd0;
				end
			end
			else begin
				case (state)
					4'd0 : begin //Write top two corners
						m10k_w_en[0] <= 1'd1;
						m10k_w_addr <= 9'b0;
						m10k_w_data <= corners[31:24];//8'd200;
						
						state <= 4'd1;
					end
					
					4'd1 : begin
						m10k_w_en[0] <= 1'd1;
						m10k_w_addr <= (dim-9'b1);
						m10k_w_data <= corners[23:16];// 8'd160;
						
						state <= 4'd14;
					end
					
					4'd14 : begin
						m10k_w_en[0] <= 1'd0;
						m10k_w_en[dim-1] <= 1'd1;
						m10k_w_addr <= 9'd0;
						m10k_w_data <= corners[15:8];//8'd20;
						
						state <= 4'd15;
					end
					
					4'd15 : begin
						m10k_w_en[dim-1] <= 1'd1;
						m10k_w_addr <= (dim-9'b1);
						m10k_w_data <= corners[7:0];//8'd100;
						
						state <= 4'd2;
					end
					
					4'd2 : begin
						// Disable corner writes
						m10k_w_en[0] <= 0;
						m10k_w_en[dim-1] <= 0;
						
						
						//Queue up bottom left and bottom right read
						m10k_r_addr[col_select - half] <= row_id - half;
						m10k_r_addr[col_select + half] <= row_id - half;
						
						state <= 4'd3;
					end
					
					4'd3 : begin
						// Disable corner writes
						state <= 4'd4;
					end
					
					4'd4 : begin
						val_l_down <= m10k_r_data[col_select - half];
						val_r_down <= m10k_r_data[col_select + half];
						
						//Queue up top left and top right read
						m10k_r_addr[col_select - half] <= row_id + half;
						m10k_r_addr[col_select + half] <= row_id + half;
						
						state <= 4'd5;
					end
					
					4'd5 : begin
						state <= 4'd6;
					end
					
					4'd6 : begin
						val_l <= m10k_r_data[col_select - half];
						val_r <= m10k_r_data[col_select + half];
						
						state <= 4'd7;
					end
					
					4'd7 : begin
						// Take col_id, subtract step_size >> 2 --> AND with step_size-1 --> gets you mod step_size
						m10k_w_en[col_select] <= 1'b1;
						m10k_w_addr <= row_id;
						sum = val_l + val_r + val_l_down + val_r_down; 
						m10k_w_data <= (((sum >> 2) + rand_term) > 10'd255) ? ((sum >> 2) - rand_term) : ((sum >> 2) + rand_term);
						//m10k_w_data <= ((sum >> 2) + rand_term);
							
						val_l_down <= val_l;
						val_r_down <= val_r;
						
						if ((step_size + row_id) < dim) begin
							//same column
							m10k_r_addr[col_select - half] <= ((up_read_addr) >= dim) ? (up_read_addr - dim + 9'b1) : (up_read_addr);
							m10k_r_addr[col_select + half] <= ((up_read_addr) >= dim) ? (up_read_addr - dim + 9'b1) : (up_read_addr);
							
							row_id <= row_id + step_size;
							
							state <= 4'd5; 					
						end
						else begin
							// Finished Diamond Step in this column, move to next column, or move to square
							if ((col_select + step_size) < dim) begin
								//Move to next diamond column
								row_id <= half;
								state <= 4'd13;
							end
							else begin
								//Move to square
								row_id <= half;
								
								m10k_r_addr[0] <= 0;
								
								col_select <= 1'b0;
								state <= 4'd8;
							end
						end
					end
					
					4'd13: begin 
						
						//disable current column, because doing new column now
						m10k_w_en[col_select] <= 1'b0;
						col_select <= col_select + step_size;
						
						state <= 4'd2;
					end
					
					4'd16 : begin
						//wait for write
						col_select <= 1'b0;
						state <= 4'd8;
					end
					
					
					4'd8 : begin
						//wait stage
						m10k_w_en <= 1'b0;
						state <= 4'd9;
					end
					
					4'd9 : begin
						val_down <= m10k_r_data[col_select]; // Odd column this will be garbage
						
						//Queue up three read addresses
						m10k_r_addr[col_select] <= row_id + half; // Upper read value will be step_size away
						m10k_r_addr[((col_select>=(dim-half)) ? (half) : (col_select+half))] <= row_id;
						m10k_r_addr[(col_select<half) ? (dim-9'b1-half) : (col_select-half)] <= row_id;
						
						state <= 4'd10;
					end
					
					4'd10 : begin
						//Wait stage for upper square step read
						state <= 4'd11;
					end
					
					4'd11 : begin
						val_l <= m10k_r_data[(col_select < half) ? (dim-9'b1-half) : (col_select-half)];
						val_r <= m10k_r_data[((col_select >= (dim-half)) ? (half) : (col_select+half))];
						val_up <= m10k_r_data[col_select];
						
						state <= 4'd12;
					end
					
					4'd12 : begin
						m10k_w_en[col_select] <= 1'b1;
						m10k_w_addr <= row_id;
						
						sum = val_l + val_r + val_up + val_down;
						
						m10k_w_data <= (((sum >> 2) + rand_term) > 10'd255) ? ((sum >> 2) - rand_term) : ((sum >> 2) + rand_term); // Maybe syntax error???
						//m10k_w_data <= ((sum >> 2) + rand_term);	
							
						val_down <= val_up;
						
						// Queue up next read, for up reg if we have more squares to do (haven't reached the end)
						if ((step_size + row_id) < dim) begin
							m10k_r_addr[col_select] <= (up_read_addr >= dim) ? (up_read_addr - dim + 9'b1) : up_read_addr;
							
							//Queue up three read addresses
							m10k_r_addr[((col_select>=(dim-half)) ? (half) : (col_select+half))] <= row_id + step_size;
							m10k_r_addr[(col_select<half) ? (dim-9'b1-half) : (col_select-half)] <= row_id + step_size;
							
							row_id <= row_id + step_size;
							
							state <= 4'd10; 					
						end
						else begin
							// Finished One Column
							if ((col_select + half) < dim) begin
							//More columns to do
								if ((col_select >> (step_power - 9'b1)) & 8'b1) begin
									//Moving to an even column
									col_select <= col_select + half;
									row_id <= half;
									
									m10k_r_addr[col_select + half] <= 0;
									
									state <= 4'd8;
								end
								else begin
									//Odd column
									col_select <= col_select + half;
									row_id <= 0;
									
									m10k_r_addr[col_select + half] <= (dim-9'b1) - half;
									
									state <= 4'd8;
								end
								
							end
							//If totally done
							else begin
								if (step_power > 1) begin
									//Go to diamond step
									col_select  <= (1 << (step_power-9'b1)) >> 1;
									row_id 		<= (1 << (step_power-9'b1)) >> 1;
									step_power  <= step_power-9'b1;
									
									state 		<= 4'd2;
								end
								else begin
									done <= 1'b1;
									state <= 4'd0;
									m10k_w_en <= 0;
								end
							end
						end
					end
					
					default : state <= 4'd0;
					
				endcase
			end 
		end
		//Will need clocked logic block to send pixel values up to top level module after all have been calculated
	end
	
	
	generate
		genvar j;
		for (j = 0; j < 16; j=j+1) begin: rand_gen
			rand63 gen_rand(
				.clk          		(clk),
				.reset        		(reset),
				.rand_out           (r[j]),
				.state_in			(4'b0),
				.seed_in			(seed[j])
			);
		end
	endgenerate
	
	generate
		genvar k;
		for (k = 0; k < dim; k=k+1) begin: m10k_gen
		
			M10K_512_8 ds_m10k (
				.clock     (clk),
				.wren      (m10k_w_en[k]),
				.q         (m10k_r_data[k]),
				.data      (m10k_w_data),
				.wraddress (m10k_w_addr),
				.rdaddress (m10k_r_addr[k])
			);
		end
	endgenerate

endmodule