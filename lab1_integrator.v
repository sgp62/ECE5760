//in the top-level module ///////////////////


// clock divider to slow system down for testing
reg [4:0] count;
// analog update divided clock
always @ (posedge CLOCK_50) 
begin
        count <= count + 1; 
end 
assign AnalogClock = (count==0);    
    
/////////////////////////////////////////////////
//// integrator /////////////////////////////////
/////////////////////////////////////////////////

module integrator(out,funct,InitialOut,clk,reset);
  output  signed [26:0] out;    //the state variable V
  input signed [26:0] funct;      //the dV/dt function
  input clk, reset;
  input signed [26:0] InitialOut;  //the initial state variable V
  
  wire  signed  [26:0] out, v1new ;
  reg signed  [26:0] v1 ;
  
  always @ (posedge clk) 
  begin
    if (reset==0) //reset 
      v1 <= InitialOut ; // 
    else 
      v1 <= v1new ; 
  end
  assign v1new = v1 + funct;
  assign out = v1;
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////
module functx(xk_new, sigma, xk, yk, dt);
  output signed [26:0] xk_new;

  input signed [26:0] sigma;
  input signed [26:0] xk;
  input signed [26:0] yk;
  input signed [26:0] dt;
    wire  signed [26:0] xk_temp;

    signed_mult mult (.out(xk_temp), .a(sigma), .b(yk-xk));
    signed_mult mult (.out(xk_new), .a(dt), .b(xk_temp)); //Will this be zero?
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functy(yk_new, rho, xk, yk, zk, dt);
  output signed [26:0] yk_new;

  input signed [26:0] sigma;
  input signed [26:0] xk;
  input signed [26:0] rho;
  input signed [26:0] yk;
  input signed [26:0] zk;
  input signed [26:0] dt;
    wire  signed [26:0] yk_temp;

    signed_mult mult (.out(yk_temp), .a(xk), .b(rho-zk));
  signed_mult mult (.out(yk_new), .a(dt), .b(yk_temp-yk)); //Will this be zero?
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functz(zk_new, beta, xk, yk, zk, dt);
  output signed [26:0] zk_new;

  input signed [26:0] sigma;
  input signed [26:0] xk;
  input signed [26:0] yk;
  input signed [26:0] zk;
  input signed [26:0] dt;
  wire  signed [26:0] x_y;
  wire  signed [26:0] beta_z;
  
  signed_mult mult (.out(x_y), .a(xk), .b(yk));
  signed_mult mult (.out(beta_z), .a(beta), .b(zk));
  signed_mult mult (.out(zk_new), .a(x_y - beta_z), .b(dt));
endmodule

//////////////////////////////////////////////////
//// signed mult of 7.20 format 2'comp////////////
//////////////////////////////////////////////////

module signed_mult (out, a, b);
  output  signed  [26:0]  out;
  input   signed  [26:0]  a;
  input   signed  [26:0]  b;
  // intermediate full bit length
  wire    signed  [53:0]  mult_out;
  assign mult_out = a * b;
  // select bits for 7.20 fixed point
  assign out = {mult_out[53], mult_out[45:20]};
endmodule
//////////////////////////////////////////////////