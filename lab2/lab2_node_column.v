//Module for node column for lab 2

`include "/lab2_single_node.v"

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
		read_address_reg <= rdaddress;
		q <= mem[read_address_reg]; // Remember to change because not synthesizable
	end
endmodule 

module column_node( 
  input  signed   [17:0] rho, g_tension, eta_term, u_n, u_n_prev, u_n_up, u_n_down,
  output signed  [17:0] out
);
  
  wire   signed  [17:0] u_n_next, u_cent;
  wire  signed   [17:0] rho_eff;
  wire  signed   [17:0] temp1;
  wire  signed   [17:0] temp2;
  wire  signed   [17:0] u_cent_g_tension;
  
/*   always @ (posedge clk) 
  begin
    if (reset==1) begin//reset 
      u_n <= initial_u_n ; // 
	  u_n_prev <= initial_u_n_prev;
	  //u_n_next <= 18'h0;
    end 
	else begin
      u_n_prev <= u_n; 
      u_n <= u_n_next; 
	end
  end */
  

  //assign rho_eff = (0.49 < (rho + u_cent_g_tension)) ? 0.49:(rho + u_cent_g_tension);
  assign u_cent = u_n;
  assign out = u_n;
  //signed_mult mult4 (.out(u_cent_g_tension), .a(u_cent), .b(g_tension));
  
  //u_n_next = (1-eta_term) * [rho *(-4*u_n) + 2*u_n - (1-eta_term)*u_n_prev
  signed_mult mult1 (.out(temp1), .a(rho), .b(u_n_up + u_n_down - u_n << 2));
  signed_mult mult2 (.out(temp2), .a(18'h1ffff-eta_term), .b(u_n_prev));
  signed_mult mult3 (.out(u_n_next), .a((u_n << 1) + temp1 - temp2), .b(18'h1ffff-eta_term));
  
endmodule