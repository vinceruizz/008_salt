module microprocessor (
	input clk, reset,
	input [3:0] i_pins,
	output wire [7:0] pm_data, pm_address, rom_address, pc, ir, from_PS, from_ID, from_CU,
	output wire [8:0] reg_enables,
	output wire zero_flag, NOPC8, NOPCF, NOPD8, NOPDF, hold_out, start_hold, end_hold, hold, cache_wren,
	output wire [2:0] cache_rdoffset, cache_wroffset,
	output wire [2:0] hold_count,
	output wire [3:0] o_reg, i, m, x0, x1, y0, y1, r,
	output wire [1:0] cache_wrline, cache_rdline
	);

/* ***************************
INTERMEDIATE WIRE DECLARATIONS
*****************************/
wire [3:0] LS_nibble_ir, source_select, data_mem_addr, data_bus, dm;
wire jump, conditional_jump, i_mux_select, y_reg_select, x_reg_select;
reg [7:0] id_in, cache_out;

/* ********
RESET LOGIC
**********/
reg sync_reset;
always @ (posedge clk)
	sync_reset = reset;

/* ***********
PROG SEQUENCER
*************/
program_sequencer prog_sequencer (
	.clk(clk),
	.sync_reset(sync_reset),
	.rom_address(rom_address),
	.pm_addr(pm_address),
	.jmp(jump),
	.jmp_nz(conditional_jump),
	.jmp_addr(LS_nibble_ir),
	.dont_jmp(zero_flag),
	.from_PS(from_PS),
	.pc(pc),
	.NOPDF(NOPDF),
	.hold_out(hold_out),
	.hold_count(hold_count),
	.start_hold(start_hold),
	.end_hold(end_hold),
	.hold(hold),
	.cache_wroffset(cache_wroffset),
	.cache_rdoffset(cache_rdoffset),
	.cache_rdline(cache_rdline),
	.cache_wrline(cache_wrline),
	.cache_wren(cache_wren)
);

/************
----CACHE----
************/
cache_multi cache(
	.clk(clk),
	.wren(cache_wren),
	.wroffset(cache_wroffset),
	.rdoffset(cache_rdoffset),
	.wrline(cache_wrline),
	.rdline(cache_rdline),
	.data(pm_data),
	.q(cache_out)
);

/* *********
PROGRAM ROM 
***********/
program_memory prog_mem (
	.clock(~clk),
	.address(rom_address),
	.q(pm_data)
);
	
/* *********************
INSTRUCTION DECODER INIT
***********************/
instruction_decoder instr_decoder (
	.next_instr(id_in),
	.sync_reset(sync_reset),
	.clk(clk),
	.jmp(jump),
	.jmp_nz(conditional_jump),
	.ir_nibble(LS_nibble_ir),
	.i_sel(i_mux_select),
	.y_sel(y_reg_select),
	.x_sel(x_reg_select),
	.source_sel(source_select),
	.reg_en(reg_enables),
	.from_ID(from_ID),
	.ir(ir),
	.NOPC8(NOPC8),
	.NOPCF(NOPCF),
	.NOPD8(NOPD8),
	.NOPDF(NOPDF)
);

/* ***************
COMPUTATIONAL UNIT
*****************/
computational_unit comp_unit (
	.clk(clk),
	.sync_reset(sync_reset),
	.r_eq_0(zero_flag),
	.i_pins(i_pins),
	.i(data_mem_addr),
	.data_bus(data_bus),
	.dm(dm),
	.o_reg(o_reg),
	.nibble_ir(LS_nibble_ir),
	.i_sel(i_mux_select),
	.y_sel(y_reg_select),
	.x_sel(x_reg_select),
	.source_sel(source_select),
	.reg_en(reg_enables),
	.from_CU(from_CU),
	.x0(x0),
	.x1(x1),
	.y0(y0),
	.y1(y1),
	.m(m),
	.r(r)
);
	
/* ********
DATA MEMORY
**********/
data_memory data_mem (
	.inclock(~clk),
	.address(data_mem_addr),
	.data(data_bus),
	.q(dm),
	.we(reg_enables[7])
);

always @ * begin
	if (hold_out)
		id_in = 8'hc8;
	else
		id_in = cache_out;
end
	
endmodule