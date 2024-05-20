`timescale 1us / 1ns

module microprocessor_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [3:0] i_pins;

	// Outputs
	wire [3:0] o_reg;
	wire [7:0] ir, pc, pm_address, rom_address;
    	wire hold_out, start_hold, end_hold, hold, cache_wren;
    	wire [4:0] cache_wroffset, cache_rdoffset;
		wire [2:0] hold_count;

	// Instantiate the Unit Under Test (UUT)
	microprocessor uut (
		.clk(clk), 
		.reset(reset), 
        	.i_pins(i_pins),
        	.o_reg(o_reg),
		.pm_address(pm_address),
		.rom_address(rom_address),
        	.ir(ir),
        	.pc(pc),
        	.hold_out(hold_out),
        	.hold_count(hold_count),
        	.start_hold(start_hold),
        	.end_hold(end_hold),
        	.hold(hold),
		.cache_wren(cache_wren),
		.cache_rdoffset(cache_rdoffset),
		.cache_wroffset(cache_wroffset)
	);

    // length of simulation
    initial #1000 $stop;

    initial
    begin
        clk = 1'b0;
    end

    always
        #0.5 clk = ~clk;

    initial
    begin
        reset = 1'b1;
        #3.2 reset = 1'b0;
        #63 reset = 1'b1;
        #3 reset = 1'b0;
        #91 reset = 1'b1;
        #3 reset = 1'b0;
        #103 reset = 1'b1;
        #101 reset = 1'b0;
    end

	initial begin
        // i_pins stimulus
        i_pins = 4'd5;
	end

endmodule
