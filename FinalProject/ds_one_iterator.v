//FinalProj_DS_One_Iterator

// Implement an the M10K block write to/ read fom memory
module M10K_512_20(
	output reg signed [19:0] q,
	input signed [19:0] data,
	input [8:0] wraddress, rdaddress,
	input wren, clock
);
	reg signed [19:0] mem [511:0] /* synthesis ramstyle = "no_rw_check, M10K" */;
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
	input	[19:0]	tl, tr, bl, br, r,
	output	[19:0]	z
);
	wire [31:0] avg;
	
	assign avg = ((tl + tr + bl + br) >> 2) + r;
	assign z = avg[19:0];
	
endmodule


module square_step (
	input	[19:0]	ml, mr, mt, mb, r,
	output	[19:0]	z
);
	wire [31:0] avg;
	
	assign avg = ((ml + mr + mt + mb) >> 2) + r;
	assign z = avg[19:0];
	
endmodule



module diamond_square_operator (#parameter dim = 257) (
	input clk, reset,
	output [9:0] x,y,
	output [19:0] z
	
);

	wire [19:0] 	m10k_r_data[dim-1:0];
	reg	 [19:0] 	m10k_w_data;
	reg	 [8:0] 	    m10k_r_addr[dim-1:0], m10k_w_addr;
	reg 	        m10k_w_en[dim-1:0];

	reg [8:0] step_size;
	reg [19:0] r;
	reg [9:0] i;

	always@(posedge clk) begin
		if(reset) begin
			step_size <= dim-1;
			for (i=0; i<dim; i=i+1) begin
				m10k_r_addr <= 0;
				m10k_w_en <= 0;
			end 
			m10k_w_data <= 0;
			m10k_w_addr <= 0;
			//TODO: Initialize 4 Corners, figure out random init
			//TODO: Set up state machine
		end
	end
	


	generate
		genvar i;
		for (i = 0; i < dim; i=i+1) begin: m10k_gen
			M10K_512_20 ds_m10k (
				.clock     (clk),
				.wren      (m10k_w_en[dim]),
				.q         (m10k_r_data[dim]),
				.data      (m10k_w_data),
				.wraddress (m10k_w_addr),
				.rdaddress (m10k_r_addr[dim])
			);
		end
	endgenerate

endmodule