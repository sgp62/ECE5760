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
		q <= mem[read_address_reg];
		read_address_reg <= rdaddress;
	end
endmodule 

module node_column( 
    output reg [31:0] q,
    input [31:0] d,
    input [7:0] write_address, read_address,
    input we, clk
);
	 // force M10K ram style
    reg [31:0] mem [255:0]  /* synthesis ramstyle = "no_rw_check, M10K" */;
	 
    always @ (posedge clk) begin
        if (we) begin
            mem[write_address] <= d;
        end
        q <= mem[read_address]; // q doesn't get d in this clock cycle
    end
endmodule