

`include "C:/Users/sgp62/Desktop/sgp62_hlg66_rbm244/ECE5760/lab2/lab2_node_column_v2.v"

module node_grid #(parameter row_size = 32) (
	input clk, reset, start_update,
	input [8:0] column_power,
	input signed [17:0] rho, g_tension, eta_term, initial_amp,
	output signed [17:0] center_node_amp,
	output [31:0] update_cycles,
	output done_update_to_fifo
);
	


	wire signed [17:0] middle_nodes [row_size-1:0];
	wire signed [17:0] col_out [row_size-1:0];
	
	wire signed [17:0] compute_outputs [row_size-1:0];
	
	reg signed  [17:0] center_node_reg;
	
	wire	               done_update [row_size-1:0];
	
	wire         [31:0] cycles_per_update [row_size-1:0];
	
	wire         [17:0] rho_eff;
	wire         [17:0] u_cent_g_tension_2;
	
	reg signed   [17:0] pyramid_step;
	
	assign center_node_amp = center_node_reg;
	
	assign update_cycles = cycles_per_update [row_size >> 1];
	
	assign done_update_to_fifo = done_update [row_size >> 1];

	
	always @ (posedge clk) begin
		if(reset) begin
			center_node_reg <= 18'h0;
			pyramid_step <= initial_amp - column_power; //Used as power of 2 math, would be 2^(17 - col_pow)
		end
		else begin
			center_node_reg <= middle_nodes[row_size >> 1];
		end
	end
	
	signed_mult mult5 (.out(u_cent_g_tension_2), .a(center_node_amp >>> g_tension), .b(center_node_amp >>> g_tension));
  
	assign rho_eff = (18'hfae1 < ((18'h1ffff >>> rho) + u_cent_g_tension_2)) ? 18'hfae1 : ((18'h1ffff >>> rho) + u_cent_g_tension_2);

	generate
		genvar i;
		for (i = 0; i < row_size; i=i+1) begin: col_gen

			column my_col(
				.clk          		(clk),
				.reset        		(reset),
				.rho          		(rho_eff),
				.eta_term     		(eta_term),
				.g_tension    		(g_tension),
				.pyramid_step       (pyramid_step),
				.column_size  		(9'b1 << column_power),
				.out          		(compute_outputs[i]), //What we want to see for the checkoff
				.u_left       		((i == 0) ? 18'h0 : col_out[i-1]), 
				.u_right      		((i == row_size-1) ? 18'h0 : col_out[i+1]),
				.middle_out   		(middle_nodes[i]),
				.u_n_out      		(col_out[i]),
				.column_num         ((i < row_size/2) ? i[17:0] : row_size[17:0] - i[17:0] - 18'b1 ), //starts at 1, goes to row_size-1 inclusiv
				.u_drum_center      (center_node_amp),
				.cycles_per_update  (cycles_per_update[i]),
				.start_update       (start_update),
				.done_update_out    (done_update[i])
			);
		end
	endgenerate
	
endmodule