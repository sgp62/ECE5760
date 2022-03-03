//Node Column v2 implementation


module M10K_512_18(
	output reg signed [17:0] q,
	input signed [17:0] data,
	input [8:0] wraddress, rdaddress,
	input wren, clock
);
	
	reg [8:0] read_address_reg;
	reg signed [17:0] mem [511:0];
	
	always @ (posedge clock)
	begin
		if (wren) 
			mem[wraddress] <= data;
	end
	always @ (posedge clock) begin
		q <= mem[rdaddress];
	end
endmodule 

module compute_module( 
  input  signed   [17:0] rho, g_tension, eta_term, u_n, u_n_prev, u_n_up, u_n_down, u_drum_center, u_left, u_right,
  output signed  [17:0] out
);
  
  wire  signed   [17:0] u_n_next, u_cent;
  wire  signed   [17:0] rho_eff;
  wire  signed   [17:0] temp1;
  wire  signed   [17:0] temp2;
  wire  signed   [17:0] u_cent_g_tension;
  wire  signed   [17:0] u_cent_g_tension_2;
  
  assign out = u_n_next;
  signed_mult mult4 (.out(u_cent_g_tension), .a(u_drum_center), .b(g_tension));
  signed_mult mult5 (.out(u_cent_g_tension_2), .a(u_cent_g_tension), .b(u_cent_g_tension));
  
  assign rho_eff = (18'hfae1 < (rho + u_cent_g_tension_2)) ? 18'hfae1 : (rho + u_cent_g_tension_2);
  
  //u_n_next = (1-eta_term) * [rho *(-4*u_n) + 2*u_n - (1-eta_term)*u_n_prev
  signed_mult mult1 (.out(temp1), .a(rho_eff), .b(u_left + u_right + u_n_up + u_n_down - (u_n << 2)));
  
  
  signed_mult mult2 (.out(temp2), .a(18'h1ffff-eta_term), .b(u_n_prev));
  
  
  signed_mult mult3 (.out(u_n_next), .a((u_n << 1) + temp1 - temp2), .b(18'h1ffff-eta_term));
  
endmodule

module column(
	input clk, reset,
	input [8:0] column_size,
	input signed [17:0] rho, g_tension, eta_term, u_left, u_right, u_drum_center,
	input signed [17:0]  column_num,
	output signed [17:0] out, middle_out, u_n_out,
	output reg [31:0] cycles_per_update
);

	wire signed	 [17:0] m10k_read_data;
	reg	 signed	 [17:0] m10k_write_data, m10k_read_reg;
	reg	         [8:0]  m10k_read_addr, m10k_write_addr;
	reg 				m10k_write_en;
	
	wire signed	 [17:0] m10k_prev_read_data;
	reg	 signed	 [17:0] m10k_prev_write_data, m10k_prev_read_reg;
	reg	         [8:0]  m10k_prev_read_addr, m10k_prev_write_addr;
	reg 				m10k_prev_write_en;


	reg          [4:0]    state, init_state;
	reg          [8:0]    init_addr, column_idx;
	reg 		          memory_init_en;

	reg  signed  [17:0]   u_n_down_reg, u_n_reg, u_n_up_reg, u_n_prev_reg, u_n_bottom_reg, u_left_reg, u_right_reg;
	reg  signed  [17:0]   u_n_center_reg, u_n_down_compute_reg;
	wire  signed [17:0]   up_compute_input, cent_compute_input, center_prev_compute_input, down_compute_input;
	
	reg signed   [17:0]   u_center, u_n_out_reg;
	
	wire         [8:0]    init_addr_temp ;
	wire         [8:0]    column_num_temp ;
	
	reg signed [17:0]   pyramid_step;
	
	reg 		 [31:0]   cycles_counter;
	reg					  done_update;
	
	always @(posedge clk) begin
		if (reset) begin
			state 			   <= 5'd0;
			init_state 		   <= 5'd0;
			memory_init_en 	   <= 1'b1;
			init_addr 	 	   <= 9'd0;
			m10k_write_en 	   <= 1'b1;
			m10k_prev_write_en <= 1'b1;
			column_idx 		   <= 9'd0;
			pyramid_step       <= 18'hfff0 / column_size;
			
			u_center           <= 18'h0;
			u_left_reg         <= 18'h0;
			u_right_reg        <= 18'h0;
			u_n_down_reg	   <= 18'h0;
			u_n_reg 		   <= 18'h0;

			u_n_up_reg		   <= ((column_num == 9'b0) || (column_num == (column_size - 9'b1))) ? pyramid_step : 18'd2 * pyramid_step; //need to change for variable height
			
			u_n_prev_reg 	   <= pyramid_step;
			u_n_bottom_reg     <= pyramid_step;
			
			cycles_counter     <= 32'b0;
			cycles_per_update  <= 32'b0;
			done_update		   <= 1'b0;
			
		end
	end
	
	assign init_addr_temp = (init_addr >= (column_size >> 1)) ? ((column_size) - init_addr - 9'b1) : init_addr;
	assign column_num_temp = (column_num >= (column_size >> 1)) ? ((column_size) - column_num - 9'b1) : column_num;
	
	always @ (posedge clk) begin //Memory init
		if(memory_init_en) begin
			if (init_state == 0) begin
				m10k_write_en <= 1'b1;
				m10k_prev_write_en <= 1'b1;

				m10k_write_addr <= init_addr;
				m10k_prev_write_addr <= init_addr;
				
				m10k_prev_write_data <= column_num_temp > init_addr_temp ? 
						((init_addr_temp + 9'b1) * pyramid_step) : ((column_num_temp + 9'b1) * pyramid_step);
						
				m10k_write_data <= column_num_temp > init_addr_temp ? 
						((init_addr_temp + 9'b1) * pyramid_step) : ((column_num_temp + 9'b1) * pyramid_step);

				if(init_addr == column_size - 1) begin
					memory_init_en <= 1'b0;
				end
				init_state <= 2;
			end
			
			if (init_state == 2) begin
				init_addr <= init_addr + 9'b1;
				init_state <= 0;
			end
			
		end
	end
	
	assign middle_out = u_center;
	assign u_n_out = u_n_out_reg;
	
	always@ (posedge clk) begin
		cycles_counter <= cycles_counter + 32'b1;
		if(done_update) begin
			cycles_per_update <= cycles_counter;
			cycles_counter <= 32'b0;
		end
	end
	
	always @ (posedge clk) begin
		if(~memory_init_en) begin
			if(state == 5'd0)begin
				m10k_prev_write_en <= 1'b0;
				m10k_write_en <= 1'b0;
			
				m10k_read_addr <= (column_idx == (column_size - 9'd1)) ? 9'd0 : column_idx + 9'd1;
				m10k_prev_read_addr <= column_idx;
			
				done_update <= 1'b0;
				
				state <= 5'd1;
			end
			
			if(state == 5'd1)begin
				state <= 5'd2;
			end
			
			if(state == 5'd2)begin

				u_n_prev_reg <= m10k_prev_read_data;
				u_n_up_reg <= (column_idx == (column_size - 9'd1)) ? 18'b0 : m10k_read_data;

				u_left_reg <= u_left;
				u_right_reg <= u_right;
				
				u_n_center_reg <= (column_idx == 9'b0) ? u_n_bottom_reg : u_n_reg;
				u_n_down_compute_reg <= (column_idx == 9'b0) ? 18'b0 : u_n_down_reg;
				
				u_n_out_reg <= (column_idx == 0) ? u_n_bottom_reg : u_n_reg;
				
				m10k_write_en <= 1'b0;
				m10k_prev_write_en <= 1'b0;
				
				state <= 5'd3;
			end
			
			if(state == 5'd3)begin
				m10k_write_en <= (column_idx == 9'd0) ? 1'b0 : 1'b1;
				m10k_prev_write_en <= 1'b1;
				
				m10k_write_addr <= column_idx;
				m10k_prev_write_addr <= column_idx;
				
				if (column_idx > 9'd0) m10k_write_data <= out;
				else m10k_write_data <= m10k_write_data;// m10k_write_data latch;
				
				if (column_idx == 9'd0) u_n_bottom_reg <= out;
				else u_n_bottom_reg <= u_n_bottom_reg;
				
				m10k_prev_write_data <= (column_idx == 9'd0) ? (u_n_bottom_reg) : u_n_reg;
				
				u_n_reg <= u_n_up_reg;
				u_n_down_reg <= (column_idx == 9'd0) ? (u_n_bottom_reg) : u_n_reg;

				
				if(column_idx == (column_size >> 1)) u_center <= out;
				
				if (column_idx == (column_size-9'd1)) begin
					column_idx <= 9'd0;
					done_update <= 9'b1;
				end
				else column_idx <= (column_idx + 9'd1);  
				
				state <= 5'd0;
			end
		end
	end


	//Instantiation of Device Under Test
	M10K_512_18 u_n_m10k (
		.clock     (clk),
		.wren      (m10k_write_en),
		.q         (m10k_read_data),
		.data      (m10k_write_data),
		.wraddress (m10k_write_addr),
		.rdaddress (m10k_read_addr)
	);

	M10K_512_18 u_n_prev_m10k (
		.clock     (clk),
		.wren      (m10k_prev_write_en),
		.q         (m10k_prev_read_data),
		.data      (m10k_prev_write_data),
		.wraddress (m10k_prev_write_addr),
		.rdaddress (m10k_prev_read_addr)
	);


	assign up_compute_input = u_n_up_reg;
	assign cent_compute_input =  u_n_center_reg;//mux for bottom
	assign center_prev_compute_input = u_n_prev_reg;
	assign down_compute_input = u_n_down_compute_reg;//mux for down
	

	compute_module calc_module (
		.out       (out),
		.rho       (rho),
		.g_tension (g_tension),
		.u_drum_center  (u_drum_center),
		.eta_term  (eta_term),
		.u_n       (cent_compute_input),
		.u_n_prev  (center_prev_compute_input),
		.u_n_up    (up_compute_input),
		.u_n_down  (down_compute_input),
		.u_left    (u_left),
		.u_right   (u_right)
	);
endmodule
	