//Testbench for lab 2 node column
`timescale 1ns/1ns
`include "/lab2_node_column.v"

//Move data from  three registesr to each other 

module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg [31:0] index;

	reg  signed [17:0]  initial_u_n;
	reg  signed [17:0]  initial_u_n_prev;
	reg  signed [17:0]  rho;
	reg  signed [17:0]  g_tension;
	reg  signed [17:0]  eta_term;

	wire  signed [17:0] out;
	
	wire 	     [17:0] m10k_read_data;
	reg			 [17:0] m10k_data_buffer, m10k_write_data;
	reg			 [8:0]  m10k_read_addr, m10k_write_addr;
	reg 				m10k_write_en;
	
	wire 	     [17:0] m10k_prev_read_data;
	reg			 [17:0] m10k_prev_data_buffer, m10k_prev_write_data;
	reg			 [8:0]  m10k_prev_read_addr, m10k_prev_write_addr;
	reg 				m10k_prev_write_en;


	reg [4:0]    state;
	reg [4:0]    init_state;
	reg [8:0]    init_addr ;
	reg 		memory_init_en;
	
	//Initialize constants
	initial begin
		initial_u_n      = 18'h04000;
		initial_u_n_prev = 18'h04000;
		rho              = 18'h02000;
		eta_term         = 18'h0000d;
		g_tension        = 18'h02000;
		
		memory_init_en = 1'b1;
		init_addr = 9'd0;
		m10k_write_en = 1'b1;
		m10k_prev_write_en = 1'b1;
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
			m10k_write_addr <= init_addr;
			m10k_write_data <= 18'ha;
			
			
			m10k_prev_write_addr <= init_addr;
			m10k_prev_write_data <= 18'ha;
			
			if(init_addr == 9'd511) begin
				memory_init_en <= 1'b0;
				m10k_prev_write_en <= 1'b0;
				m10k_write_en <= 1'b0;
			end
			else init_addr <= init_addr + 9'b1;
			
		end
	end
	
	always @ (posedge clk) begin
		if(state == 5'd0)begin
			//m10k_read_addr <= 9'd42;
			m10k_write_addr <= (memory_init_en) ? 18'h0 ;
			
			m10k_write_data <= 18'h1ffff;
			m10k_write_en <= 1'b1;
			state <= 5'd1;
		end
		
		if(state == 5'd1)begin
			m10k_read_addr <= 9'd42;
			m10k_write_en <= 1'b0;
			state <= 5'd2;
		end
		
		if(state == 5'd2)begin
			state <= 5'd3;
		end
		
		if(state == 5'd3)begin
			m10k_data_buffer <= m10k_read_data;
			state <= 5'd0;
		end
	end

	

	//Instantiation of Device Under Test
single_node lab2_single (
	.clk (clk_50),
	.reset (reset),
	.out (out),
	.initial_u_n (initial_u_n),
	.initial_u_n_prev (initial_u_n_prev),
	.rho (rho),
	.g_tension (g_tension),
	.eta_term (eta_term)
);

/*output reg signed [17:0] q,
	input signed [17:0] data,
	input [8:0] wraddress, rdaddress,
	input wren, rden, clock*/
M10K_512_18 u_n_m10k (
	.clock     (clk_50),
	.wren      (m10k_write_en),
	.q         (m10k_read_data),
	.data      (m10k_write_data),
	.wraddress (m10k_write_addr),
	.rdaddress (m10k_read_addr)
);

M10K_512_18 u_n_prev_m10k (
	.clock     (clk_50),
	.wren      (m10k_prev_write_en),
	.q         (m10k_prev_read_data),
	.data      (m10k_prev_write_data),
	.wraddress (m10k_prev_write_addr),
	.rdaddress (m10k_prev_read_addr)
);


//single_node lab2_single (clk_50, reset, out, initial_u_n, initial_u_n_prev, rho, g_tension, eta_term, temp1_trace, temp2_trace);
	
endmodule
