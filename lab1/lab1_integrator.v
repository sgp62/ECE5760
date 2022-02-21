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
    if (reset==1) //reset 
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

	input signed [26:0] sigma; //constant
	input signed [26:0] xk; //The x output value at time t
	input signed [26:0] yk; //The y output value at timet 
	input signed [26:0] dt; //Constant
	wire  signed [26:0] temp; //Used for multiple sequential multipliers

	signed_mult mult (.out(temp), .a(sigma), .b(dt)); //7.20 multiplier
	signed_mult mult2 (.out(xk_new), .a(yk-xk), .b(temp)); // 7.20 multiplier creating derivative euler step increase for x
  
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functy(yk_new, rho, xk, yk, zk, dt);
  output signed [26:0] yk_new;

	input signed [26:0] xk; //The x output value at time t
	input signed [26:0] rho; //constant
	input signed [26:0] yk; //The y output value at time t
	input signed [26:0] zk; //The z output value at time t
	input signed [26:0] dt; //Constant timestep
	wire  signed [26:0] temp; //Temporary variable outputs for multipliers
	wire  signed [26:0] temp2; 
	wire  signed [26:0] temp3; 

	//Signed 7.20 multipliers used to create derivative euler approx step increase for y
  	signed_mult mult (.out(temp), .a(xk), .b(dt));
  	signed_mult mult2 (.out(temp2), .a(yk), .b(dt));
  	signed_mult mult3 (.out(temp3), .a(rho-zk), .b(temp));
  	assign yk_new = temp3 - temp2;
  
endmodule

//////////////////////////////////////////////////
//// derivative calculator module //////////
//////////////////////////////////////////////////

module functz(zk_new, beta, xk, yk, zk, dt);
  output signed [26:0] zk_new;

	input signed [26:0] xk; //The x output value at time t
	input signed [26:0] yk; //The y output value at time t
	input signed [26:0] zk; //The z output value at time t
	input signed [26:0] dt; //Constant timestep
	input signed [26:0] beta; //Constant
	
	//Temporary variables used for signed multipliers
	wire  signed [26:0] x_dt; 
	wire  signed [26:0] z_dt; 
	wire  signed [26:0] temp; 
	wire  signed [26:0] temp2; 
  	
	//7.20 multipliers used to create derivative euler step for z output
	signed_mult mult (.out(x_dt), .a(xk), .b(dt)); 
	signed_mult mult2 (.out(temp), .a(yk), .b(x_dt)); 
	signed_mult mult3 (.out(z_dt), .a(zk), .b(dt)); 
	signed_mult mult4 (.out(temp2), .a(beta), .b(z_dt)); 
  	assign zk_new = temp-temp2;

endmodule

module full_integrator(clk, reset, sigma, beta, rho, dt, xi, yi, zi, xout, yout, zout);

	input clk, reset;
	input  signed [26:0]  sigma;
	input  signed [26:0]  beta;
	input  signed [26:0]  rho;

	input  signed [26:0]  xi;
	input  signed [26:0]  yi;
	input  signed [26:0]  zi;

	input  signed [26:0]  dt;

	output signed [26:0]  xout;
	output signed [26:0]  yout;
	output signed [26:0]  zout;

	wire   signed [26:0]  xk_new;
	wire   signed [26:0]  yk_new;
	wire   signed [26:0]  zk_new;

	

	functx fx (xk_new, sigma, xout, yout, dt); //Creates dx/dt
	functy fy (yk_new, rho, xout, yout, zout ,dt);
	functz fz (zk_new, beta, xout, yout, zout, dt);

	integrator x_int (xout, xk_new, xi, clk, reset); //clocked register module for updating x output
	integrator y_int (yout, yk_new, yi, clk, reset);//clocked register module for updating y output
	integrator z_int (zout, zk_new, zi, clk, reset);//clocked register module for updating z output
	//Undefined output could be because one of the inputs is not defined from the module

endmodule

//full_integrator lab1_dda (clk_50, reset, sigma, beta, rho, dt, xi, yi, zi, xout, yout, zout);


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
