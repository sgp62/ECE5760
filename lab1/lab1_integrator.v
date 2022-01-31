//in the top-level module ///////////////////


// clock divider to slow system down for testing
//reg [4:0] count;
// analog update divided clock
//always @ (posedge CLOCK_50) 
//begin
//        count <= count + 1; 
//end 
//assign AnalogClock = (count==0);    

/*
  Helpful Notes from Lecture 1/31
  - Do we need to store the current time t anywhere?
  - Consider doing a shift with dt rather than a multiply (it is 1/256 so it would be >> 8)
  - Look into issues with the clk selection in the modelsim - generate a clock in C code(???)
  - Check in on the low reset condition in the integrator
  - Possibly make the integrator into a single integrator that takes in all 3 x,y,z and calculates new value
  - Look for overflow issues - symptom is the system looking like a damped oscillator
*/
    
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
  signed_mult mult2 (.out(xk_new), .a(dt), .b(xk_temp)); //Will this be zero?
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functy(yk_new, rho, xk, yk, zk, dt);
  output signed [26:0] yk_new;

  input signed [26:0] xk;
  input signed [26:0] rho;
  input signed [26:0] yk;
  input signed [26:0] zk;
  input signed [26:0] dt;
  wire  signed [26:0] yk_temp;

  signed_mult mult (.out(yk_temp), .a(xk), .b(rho-zk));
  signed_mult mult2 (.out(yk_new), .a(dt), .b(yk_temp-yk)); //Will this be zero?
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functz(zk_new, beta, xk, yk, zk, dt);
  output signed [26:0] zk_new;

  input signed [26:0] xk;
  input signed [26:0] yk;
  input signed [26:0] zk;
  input signed [26:0] dt;
  input signed [26:0] beta;
  wire  signed [26:0] x_y;
  wire  signed [26:0] beta_z;
  
  signed_mult mult (.out(x_y), .a(xk), .b(yk));
  signed_mult mult2 (.out(beta_z), .a(beta), .b(zk));
  signed_mult mult3 (.out(zk_new), .a(x_y - beta_z), .b(dt));
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