//FinalProj_DS_One_Iterator
`include "./ds_col.v"

//////////////////////////////////////////////////////////
// 16-bit parallel random number generator ///////////////
//////////////////////////////////////////////////////////
// Algorithm is based on:
// A special-purpose processor for the Monte Carlo simulation of ising spin systems
// A. Hoogland, J. Spaa, B. Selman and A. Compagner
// Journal of Computational Physics
// Volume 51, Issue 2, August 1983, Pages 250-260
// but modified to use a 63 bit shift register 
// with feedback from positions 63 and 62
//////////////////////////////////////////////////////////
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


module diamond_square_operator #(parameter dim_power = 3) (
	input clk, reset,
	output  [8:0]   dim_out,
	output 	[9:0]	x,y,
	output	[7:0]	z,
	output          done
	
);

	wire    [8:0]	dim, step_size, half;

	wire	[7:0]	out_up_array [(1 << dim_power) : 0];
	wire	[7:0]	out_down_array [(1 << dim_power): 0];
	wire    [8:0]   step_size_array [(1 << dim_power): 0];
	wire	[63:1]	seed [(1 << (dim_power-2)): 0];
	wire	[15:0]	r [(1 << (dim_power-2)): 0];
	wire    [7:0]   out_vga_array [(1 << dim_power) : 0];
	wire	[(1 << dim_power):0]  done_wire;
	
	reg     [8:0]   col_select, addr_counter;
	reg     [3:0]   vga_state;
	
	reg     [9:0]   x_reg, y_reg;
	reg 	[31:0] cycles;
	
	assign dim = (1 << dim_power) + 9'b1;
	assign step_size = step_size_array[dim >> 1];
	assign half = step_size >> 1;
	
	assign x = x_reg;//col_select;
	assign y = y_reg;//(addr_counter == 9'd0) ? dim-1 : addr_counter-1;
	assign z = out_vga_array[x_reg];
	assign dim_out = dim;
	assign done = done_wire;
	
	assign seed[0] = 63'hff7fffcf;
	assign seed[1] = 63'h8ffff1ffd;
	assign seed[2] = 63'h4f6ffaf0f;
 	assign seed[3] = 63'headdeadbeef;
	assign seed[4] = 63'heeeeeeeeeeeee;
/*	assign seed[5] = 63'haed409210291;
	assign seed[6] = 63'h123456789;
	assign seed[7] = 63'hfffffffffffffff;
	assign seed[8] = 63'hba0000000000000;
	assign seed[9] = 63'h1115555599988;
	
	assign seed[10] = 63'h666999666999;
	assign seed[11] = 63'hbbbbbeeeee0000;
	assign seed[12] = 63'h3;
	assign seed[13] = 63'h78965422211140;
	assign seed[14] = 63'h620200011011999;
	assign seed[15] = 63'h72820000002827;
	assign seed[16] = 63'h99999999; */


	always@(posedge clk) begin
		// Reset to initial conditions
		if(reset) begin
			col_select	 <= 9'd0;
			addr_counter <= 9'd0;
			vga_state    <= 4'd0;
			x_reg        <= 10'b0;
			y_reg        <= 10'b0;
			cycles		 <= 0;
		end
		else begin
			cycles <= cycles+1;
			if(done_wire) begin
				if(vga_state == 4'd0) begin
					vga_state <= 4'd1;
				end
				if(vga_state == 4'd1) begin
					vga_state <= 4'd2;
				end
				if(vga_state == 4'd2) begin
					addr_counter <= (addr_counter < (dim-9'd1)) ? addr_counter + 9'd1 : 9'd0;
					
					if((col_select == (dim-9'd1)) && (addr_counter == (dim-9'd1))) begin
						addr_counter <= dim-1;
						vga_state <= 4'd4;
					end
					//else if(addr_counter == (dim-9'd1)) vga_state <= 4'd3;
					else if(addr_counter == (dim-9'd1)) begin 
						vga_state <= 4'd0;
						col_select <= col_select + 9'd1;
					end
					else vga_state <= 4'd0;
					
					x_reg <= col_select;
					y_reg <= addr_counter;
					
				end
				/* if(vga_state == 4'd3) begin
					col_select <= col_select + 9'd1;
					vga_state <= 4'd0;
				end */
				if(vga_state == 4'd4) begin
				
					vga_state <= 4'd4;
				end
			end
		end
		//Will need clocked logic block to send pixel values up to top level module after all have been calculated
	end
	
	generate
		genvar j;
		for (j = 0; j < ((1 << (dim_power - 2)) + 1); j=j+1) begin: rand_gen
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
		genvar i;
		for (i = 0; i < ((1 << dim_power) + 8'b1); i=i+1) begin: col_gen
			diamond_square_col my_col(
				.clk          		(clk),
				.reset        		(reset),
				.col_id             (i),
				.dim_power          (dim_power),
				.dim                ((9'b1 << dim_power) + 9'b1),
				.step_size	        (step_size_array[i]),
				.val_l				(out_up_array[((i<half) ? (dim-9'b1-half) : (i-half))]), //From step_size/2 columns to the left (Wrap around???)
				.val_r				(out_up_array[((i>=(dim-half)) ? (half) : (i+half))]), //From step_size/2 columns to the right
				.val_l_down			(out_down_array[((i<half) ? (dim-9'b1-half) : (i-half))]), //Undefined for diamond step, otherwise stepsize/2 columns to left
				.val_r_down			(out_down_array[((i>=(dim-half)) ? (half) : (i+half))]), //Undefined for diamond step, otherwise stepsize/2 columns to right
				.r_data_up			(out_up_array[i]),
				.r_data_down		(out_down_array[i]),
				.r					(((i >>1) & 1) ? r[i >> 2][15:8] : r[i >> 2][7:0]),
				.vga_r_addr         ((col_select == i) ? addr_counter : 9'd0),
				.vga_r_data	        (out_vga_array[i]),
				.done               (done_wire[i])
			);
		end
	endgenerate
	

endmodule