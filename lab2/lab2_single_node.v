//Verilog Module for Lab 2 Drum Synthesis


module single_node(clk, reset, out, initial_u_n, initial_u_n_prev, rho, g_tension, eta_term);
  input clk, reset;
  input signed   [17:0] rho, g_tension, eta_term, initial_u_n, initial_u_n_prev;
  
  wire   signed  [17:0] u_n_next, u_cent;
  output signed  [17:0] out;
  reg 	 signed  [17:0] u_n, u_n_prev;
  
  
  wire  signed   [17:0] rho_eff;
  wire  signed   [17:0] temp1;
  wire  signed   [17:0] temp2;
  wire  signed   [17:0] u_cent_g_tension;
  
  always @ (posedge clk) 
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
  end
  

  //assign rho_eff = (0.49 < (rho + u_cent_g_tension)) ? 0.49:(rho + u_cent_g_tension);
  assign u_cent = u_n;
  assign out = u_n;
  //signed_mult mult4 (.out(u_cent_g_tension), .a(u_cent), .b(g_tension));
  
  //u_n_next = (1-eta_term) * [rho *(-4*u_n) + 2*u_n - (1-eta_term)*u_n_prev
  signed_mult mult1 (.out(temp1), .a(rho), .b(u_n << 2));
  signed_mult mult2 (.out(temp2), .a(18'h1ffff-eta_term), .b(u_n_prev));
  signed_mult mult3 (.out(u_n_next), .a((u_n << 1) - temp1 - temp2), .b(18'h1ffff-eta_term));
  
endmodule

//////////////////////////////////////////////////
//// signed mult of 1.17 format 2'comp////////////
//////////////////////////////////////////////////

module signed_mult (out, a, b);
  output  signed  [17:0]  out;
  input   signed  [17:0]  a;
  input   signed  [17:0]  b;
  // intermediate full bit length
  wire    signed  [35:0]  mult_out;
  assign mult_out = a * b;
  // select bits for 1.17 fixed point
  assign out = {mult_out[35], mult_out[33:17]};
endmodule