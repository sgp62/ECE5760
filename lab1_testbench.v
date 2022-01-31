`timescale 1ns/1ns
`include "lab1/lab1_integrator.v"

module testbench();
	
	reg clk_50, clk_25, reset;
	
	reg [31:0] index;

	reg  signed [26:0]  sigma;
	reg  signed [26:0]  beta;
	reg  signed [26:0]  rho;

	reg  signed [26:0]  xi;
	reg  signed [26:0]  yi;
	reg  signed [26:0]  zi;

	reg  signed [26:0]  dt;

	wire signed [26:0]  xout;
	wire signed [26:0]  yout;
	wire signed [26:0]  zout;

	//Initialize constants
	initial begin
		sigma = 27'ha_00000;
		beta  = 27'h2_aaaaa;
		rho   = 27'h1c_00000;
		dt    = 27'h0_01000;
		xi    = -27'sh1_00000;
		yi    = 27'h0_19999;
		zi    = 27'h19_00000;
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

	

	//Instantiation of Device Under Test
full_integrator lab1_dda (clk_50, reset, sigma, beta, rho, dt, xi, yi, zi, xout, yout, zout);
	
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

	

	functx fx (xk_new, sigma, xout, yout, dt);
	functy fy (yk_new, rho, xout, yout, zout ,dt);
	functz fz (zk_new, beta, xout, yout, zout, dt);

	integrator x_int (xout, xk_new, xi, clk, reset);
	integrator y_int (yout, yk_new, yi, clk, reset);
	integrator z_int (zout, zk_new, zi, clk, reset);
	//Undefined output could be because one of the inputs is not defined from the module

endmodule