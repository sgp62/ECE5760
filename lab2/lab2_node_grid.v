
`include "/lab2_node_column_v2.v"


module node_grid #(parameter row_size = 30) (
	input clk, reset,
	input [8:0] column_size,
	input signed [17:0] rho, g_tension, eta_term,
	output signed [17:0] center_node_amp
);
	


	wire signed [17:0] middle_nodes [row_size-1:0];
	wire signed [17:0] col_out [row_size-1:0];
	
	wire signed [17:0] compute_outputs [row_size-1:0];
	
	reg signed  [17:0] center_node_reg;
	
	assign center_node_amp = center_node_reg;
	
	
	always @ (posedge clk) begin
		if(reset) begin
			center_node_reg <= 18'h0;
		end
		else begin
			center_node_reg <= middle_nodes[row_size / 2];
		end
	end

	generate
		genvar i;
		for (i = 0; i < row_size; i=i+1) begin: col_gen

			column my_col(
				.clk          		(clk),
				.reset        		(reset),
				.rho          		(rho),
				.eta_term     		(eta_term),
				.g_tension    		(g_tension),
				.column_size  		(column_size),
				.out          		(compute_outputs[i]), //What we want to see for the checkoff
				.u_left       		((i == 0) ? 18'h0 : col_out[i-1]), //Maybe use compute_outputs (waveforms look wack rn)
				.u_right      		((i == row_size-1) ? 18'h0 : col_out[i+1]),
				.middle_out   		(middle_nodes[i]),
				.u_n_out      		(col_out[i]),
				//.column_num   ((i < row_size/2) ? i[17:0] + 18'b1 : row_size[17:0] - i[17:0]) //starts at 1, goes to row_size-1 inclusive
				.column_num         ((i < row_size/2) ? i[17:0] : row_size[17:0] - i[17:0] - 18'b1 ) //starts at 1, goes to row_size-1 inclusive
				//Check logic for u_n_out within the column module (should it be compute output or u_n_reg that's passed
				//to the left and right????

			);
		end
	endgenerate
	
endmodule