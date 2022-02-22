//Testbench for lab 2 node column
`timescale 1ns/1ns
`include "/lab2_node_column.v"

//Move data from  three registesr to each other 

module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg          [31:0] index;

	reg  signed  [17:0]  initial_u_n;
	reg  signed  [17:0]  initial_u_n_prev;
	reg  signed  [17:0]  rho;
	reg  signed  [17:0]  g_tension;
	reg  signed  [17:0]  eta_term;

	wire signed  [17:0] out;
	
	wire signed	 [17:0] m10k_read_data;
	reg	 signed	 [17:0] m10k_data_buffer, m10k_write_data;
	reg	         [8:0]  m10k_read_addr, m10k_write_addr;
	reg 				m10k_write_en, m10k_read_en;
	
	wire signed	 [17:0] m10k_prev_read_data;
	reg	 signed	 [17:0] m10k_prev_data_buffer, m10k_prev_write_data;
	reg	         [8:0]  m10k_prev_read_addr, m10k_prev_write_addr;
	reg 				m10k_prev_write_en, m10k_prev_read_en;


	reg          [4:0]    state;
	reg          [4:0]    init_state;
	reg          [8:0]    init_addr ;
	reg 		          memory_init_en;
	reg			 [8:0]    column_idx;
	reg  signed  [17:0]   u_n_down_reg, u_n_reg, u_n_up_reg, u_n_prev_reg, u_n_bottom_reg;
	reg			 [31:0]   column_size;
	
	wire  signed  [17:0]   up_compute_input, cent_compute_input, center_prev_compute_input, down_compute_input;
	
	reg  signed  [17:0]   m10k_read_reg, m10k_prev_read_reg;

	
	//Initialize constants
	initial begin
		initial_u_n      = 18'h04000;
		initial_u_n_prev = 18'h04000;
		rho              = 18'h02000;
		eta_term         = 18'h0000d;
		g_tension        = 18'h02000;
		
		state 			   = 5'd0;
		init_state 		= 5'd0;
		column_size        = 9'd30;
		memory_init_en 	   = 1'b1;
		init_addr 	 	   = 9'd0;
		m10k_write_en 	   = 1'b1;
		m10k_prev_write_en = 1'b1;
		column_idx 		   = 9'd0;
		u_n_down_reg	   = 18'h0;
		u_n_reg 		   = 18'h0; //TODO: Resolve hard coding (Maybe take parameter inputs)
		u_n_up_reg		   = 18'h1111; //TODO: Resolve hard coding (Maybe take parameter inputs)
		u_n_prev_reg 	   = 18'h0; //TODO: Resolve hard coding (Maybe take parameter inputs)
		u_n_bottom_reg     = 18'h0; //TODO: Resolve hard coding (Maybe take parameter inputs)
		
		m10k_read_reg      = 18'h0;
		m10k_prev_read_reg = 18'h0;
		
	end

	
	//Initialize clocks and index
	initial begin
		clk_50 = 1'b0;
		clk_25 = 1'b0;
		index  = 32'd0;
		//testbench_out = 15'd0 ;
	end
	
	//Toggle the clocks
	always begin
		#10
		clk_50  = !clk_50;
	end
	
	always begin
		#20
		clk_25  = !clk_25;
	end
	
	//Intialize and drive signals
	initial begin
		reset  = 1'b0;
		#10 
		reset  = 1'b1;
		#30
		reset  = 1'b0;

	end
	
	//Increment index
	always @ (posedge clk_50) begin
		index  <= index + 32'd1;
	end
	
	
	
	
	
	always @ (posedge clk_50) begin //Memory init
		if(memory_init_en) begin
			if (init_state == 0) begin
				m10k_write_en <= 1'b1;
				m10k_prev_write_en <= 1'b1;
				//[0..1ffff] [0..f]
				m10k_write_addr <= init_addr;
				
				m10k_prev_write_addr <= init_addr;
				
				if(init_addr == (column_size-9'b1)) begin
					m10k_prev_write_data <= 18'b0;
					m10k_write_data <= 18'b0; //TODO: Resolve hard coding for variable column lengths
				
					memory_init_en <= 1'b0;
					/* m10k_prev_write_en <= 1'b0;
					m10k_write_en <= 1'b0; */
				end
				else begin
					m10k_prev_write_data <= (init_addr < (column_size >> 1)) ? ({ {9{init_addr[8]}},  (init_addr[8:0]) }* 18'h1111) : (((column_size-9'b1) - init_addr - 9'b1) * 18'h1111);
					m10k_write_data <= (init_addr < (column_size >> 1)) ? ({ {9{init_addr[8]}},  (init_addr[8:0]) } * 18'h1111) : (((column_size-9'b1) - init_addr - 9'b1) *  18'h1111); //TODO: Resolve hard coding for variable column lengths
				
				end
				init_state <= 1;
			end
			
			if (init_state == 1) begin
				init_state <= 2;
			end
			
			if (init_state == 2) begin
				init_addr <= init_addr + 9'b1;
				init_state <= 0;
			end
			
			
			
			
		end
	end
	
	/* always @ (posedge clk_50) begin
		if(~memory_init_en) begin
			if(state == 5'd0)begin
				m10k_read_en <= 1'b1;
				m10k_read_addr <= column_idx+9'b1;
				state <= 5'd1;
			end
			
			if(state == 5'd1)begin
				state <= 5'd2;
			end
			
			if(state == 5'd2)begin
				
				state <= 5'd3;
				column_idx <= (column_idx == (column_size-9'd2)) ? 9'b1 : (column_idx + 9'b1);
			end
			
			if(state == 5'd3)begin
				m10k_read_en <= 1'b0;
				state <= 5'd0;
			end
			
		end
	end */
	
	
	always @ (*) begin
		m10k_read_reg = m10k_read_data;
		m10k_prev_read_reg = m10k_prev_read_data;
	end
	
	always @ (posedge clk_50) begin
		if(~memory_init_en) begin
			if(state == 5'd0)begin
			
				m10k_prev_write_en <= 1'b0;
				m10k_write_en <= 1'b0;
				m10k_read_en <= 1'b1;
				m10k_prev_read_en <= 1'b1;
			
				m10k_read_addr <= column_idx + 9'd1;
				m10k_prev_read_addr <= column_idx;
			
				u_n_prev_reg <= u_n_prev_reg;
				u_n_up_reg <= u_n_up_reg;
				u_n_down_reg <= u_n_down_reg;
				u_n_reg <= u_n_reg;
				u_n_bottom_reg <= u_n_bottom_reg;
				
				state <= 5'd1;
			end
			
			if(state == 5'd1)begin
				state <= 5'd2;
				u_n_prev_reg <= u_n_prev_reg;
				u_n_up_reg <= u_n_up_reg;
				u_n_down_reg <= u_n_down_reg;
				u_n_reg <= u_n_reg;
				u_n_bottom_reg <= u_n_bottom_reg;
				
			end
			
			if(state == 5'd2)begin
				state <= 5'd3;
				u_n_prev_reg <= u_n_prev_reg;
				u_n_up_reg <= u_n_up_reg;
				u_n_down_reg <= u_n_down_reg;
				u_n_reg <= u_n_reg;
				u_n_bottom_reg <= u_n_bottom_reg;
				
			end
			
			if(state == 5'd3)begin
				m10k_write_en <= (column_idx == 9'd0) ? 1'b0 : 1'b1;
				m10k_prev_write_en <= 1'b1;
				m10k_read_en <= 1'b0;
				m10k_prev_read_en <= 1'b0;
				
				m10k_write_addr <= column_idx;
				m10k_prev_write_addr <= column_idx;

				if (column_idx > 9'd0) m10k_write_data <= out;
				else m10k_write_data <= out;// m10k_write_data;
				
				if (column_idx == 9'd1) u_n_bottom_reg <= out;
				else u_n_bottom_reg <= u_n_bottom_reg;
				
				m10k_prev_write_data <= (column_idx == 9'd0) ? (u_n_bottom_reg) : u_n_reg;

				u_n_prev_reg <= m10k_prev_read_reg;
				u_n_up_reg <= (column_idx == (column_size - 9'd3)) ? 18'b0 : m10k_read_reg;
				u_n_down_reg <= (column_idx == 9'd0) ? (u_n_bottom_reg) : u_n_reg;
				u_n_reg <= u_n_up_reg;

				if (column_idx == (column_size-9'd2)) begin
					column_idx <= 9'd0;
					//column_idx <= (column_idx == (column_size-9'd2)) ? 9'b1 : (column_idx + 9'b1);
					//u_n_reg <= u_n_bottom_reg;
					//u_n_down_reg <= 0;
				end
				else column_idx <= (column_idx + 9'd1);  
				
				state <= 5'd0;
			end
			
			/* if(state == 5'd3)begin

				m10k_prev_write_en <= 1'b0;
				m10k_write_en <= 1'b0;
				
				state <= 5'd0;
			end */
		end
	end
	

	

	//Instantiation of Device Under Test
M10K_512_18 u_n_m10k (
	.clock     (clk_50),
	.wren      (m10k_write_en),
	.q         (m10k_read_data),
	.data      (m10k_write_data),
	.wraddress (m10k_write_addr),
	.rdaddress (m10k_read_addr),
	.rden      (m10k_read_en)
);

M10K_512_18 u_n_prev_m10k (
	.clock     (clk_50),
	.wren      (m10k_prev_write_en),
	.q         (m10k_prev_read_data),
	.data      (m10k_prev_write_data),
	.wraddress (m10k_prev_write_addr),
	.rdaddress (m10k_prev_read_addr),
	.rden      (m10k_prev_read_en)
);


assign up_compute_input = u_n_up_reg;
assign cent_compute_input = (column_idx == 9'b1) ? u_n_bottom_reg : u_n_reg;
assign center_prev_compute_input = u_n_prev_reg;
assign down_compute_input = (column_idx == 9'b1) ? 18'b0 : u_n_down_reg;

column_node calc_module (
	.out       (out),
	.rho       (rho),
	.g_tension (g_tension),
	.eta_term  (eta_term),
	.u_n       (cent_compute_input),
	.u_n_prev  (center_prev_compute_input),
	.u_n_up    (up_compute_input),
	.u_n_down  (down_compute_input)
);


//single_node lab2_single (clk_50, reset, out, initial_u_n, initial_u_n_prev, rho, g_tension, eta_term, temp1_trace, temp2_trace);
	
endmodule
