module program_sequencer (
	input clk, jmp, jmp_nz, dont_jmp, sync_reset,
	input [3:0] jmp_addr,
	input NOPDF,
	output [7:0] pm_addr,
	output [7:0] rom_address,
	output reg [7:0] pc,
	output reg [7:0] from_PS,
	output reg hold_out, start_hold, end_hold, hold, cache_wren,
	output reg [2:0] hold_count,
	output reg [2:0] cache_wroffset, cache_rdoffset,
	output reg [1:0] cache_wrline, cache_rdline
);

reg sync_reset_1;
reg reset_1shot;

reg [3:0][2:0] tagID;
reg [3:0] valid;

always @ * begin
	from_PS = pc;
end
	
// PROGRAM COUNTER
always @ (posedge clk)
	pc = pm_addr;

// NEXT PM ADDRESS LOGIC
always @ *
	if (sync_reset) 
		pm_addr = 8'H00;
	else if (hold)
		pm_addr = pc;
	else if (((jmp) || (jmp_nz & ~dont_jmp))) 
		pm_addr = { jmp_addr, 4'H0 };
	else 
		pm_addr = pc + 8'H01;

/* **********
MICRO SUSPEND
********** */

/* start hold */
always @ * begin
	if ((tagID[pm_addr[4:3]] != pm_addr[7:5]) || (valid[pm_addr[4:3]] == 1'b0 && !hold) || reset_1shot) begin
		start_hold = 1'b1;
	end
	else begin
		start_hold = 1'b0;
	end
end

/* hold */
always @ (posedge clk) begin
	if (end_hold)
		hold = 1'b0;
	else if (start_hold)
		hold = 1'b1;
end

/* end hold */
always @ * begin
	if (hold_count == 3'd7 && hold)
		end_hold = 1'b1;
	else
		end_hold = 1'b0;
end

/* counter */
always @ (posedge clk) begin
	if (reset_1shot)
		hold_count = 3'd0;
	else if (hold)
		hold_count = hold_count + 3'd1;
end

/* hold_out */
always @ * begin
	if ((start_hold || hold) && !end_hold)
		hold_out = 1'b1;
	else
		hold_out = 1'b0;
end

/* **************
CACHE CONNECTIONS
****************/
always @ * begin
	cache_wroffset = hold_count;
	cache_rdoffset = pm_addr[2:0];
	cache_wren = hold;
end

always @ (posedge clk) begin
	sync_reset_1 = sync_reset;
end

always @ * begin
	if (sync_reset && !sync_reset_1)
		reset_1shot = 1'b1;
	else
		reset_1shot = 1'b0;
end

always @ * begin
	if (reset_1shot)
		rom_address = 8'b0;
	else if (start_hold)
		rom_address = {pm_addr[7:3], 3'd0};
	else if (sync_reset)
		rom_address = {5'd0,hold_count+3'd1};
	else
		rom_address = {tagID[pc[4:3]],pc[4:3],hold_count+3'd1};
end

always @ * begin
	cache_wrline = pc[4:3];
	cache_rdline = pm_addr[4:3];
end

always @ (posedge clk) begin
	if (reset_1shot) begin
		tagID = 12'b0;
	end
	else if (start_hold) begin
		tagID[cache_rdline] = pm_addr[7:5];
	end
	else
		tagID = tagID;
end

always @ (posedge clk) begin
	if (reset_1shot) begin
		valid[0] = 1'b0;
		valid[1] = 1'b0;
		valid[2] = 1'b0;
		valid[3] = 1'b0;
	end
	else if (end_hold) begin
		valid[0] = 1'b1;
		valid[1] = 1'b1;
		valid[2] = 1'b1;
		valid[3] = 1'b1;
	end
end


	
endmodule