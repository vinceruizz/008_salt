module instruction_decoder (
	input clk, sync_reset,
	input [7:0] next_instr,
	output jmp, jmp_nz, i_sel, y_sel, x_sel,
	output [3:0] ir_nibble, source_sel,
	output [8:0] reg_en,
	output reg [7:0] ir,
	output reg [7:0] from_ID,
	output reg NOPC8, NOPCF, NOPD8, NOPDF
	);

always @ *
from_ID <= reg_en[7:0];

/* **********************************
NO-OPERATION CHECK SIGNALS (FOR EXAM)
************************************/
always @ *
	NOPC8 = (ir == 8'HC8); //ir == 8'hc8 causes a no operation
always @ *
	NOPCF = (ir == 8'HCF); //ir == 8'hcf causes a no operation
always @ *
	NOPD8 = (ir == 8'hD8); //ir == 8'hd8 causes a no operation
always @ *
	NOPDF = (ir == 8'HDF); //ir == 8'hdf causes a no operation
	
/* ***********************
INSTRUCTION REGISTER LOGIC
*************************/
// syncronously sets the value of the instruction register as the next instruction
always @ (posedge clk)
	ir <= next_instr;
	
// IR NIBBLE reg
always @ *
	ir_nibble = ir[3:0];
	
/* ******************
REGISTER ENABLE LOGIC
********************/
//the logic goes: if an instruction requires the use of any of these registers,
//enable the register

// for x0 enable
always @*
	if (sync_reset == 1'b1)
		reg_en[0] <= 1'b1;
	else if (ir[7:4] == 4'b0000) // load to x0
		reg_en[0] <= 1'b1;
	else if (ir[7:3] == 5'b10000) // move to x0
		reg_en[0] <= 1'b1;
	else
		reg_en[0] <= 1'b0;

// for x1 enable
always @*
   if (sync_reset == 1'b1)
		reg_en[1] <= 1'b1;
	else if (ir[7:4] == 4'b0001) // load to x1
		reg_en[1] <= 1'b1;
	else if (ir[7:3] == 5'b10001) // move to x1
		reg_en[1] <= 1'b1;
	else
		reg_en[1] <= 1'b0;	

// for y0 enable
always @*
	if (sync_reset == 1'b1)
		reg_en[2] <= 1'b1;
	else if (ir[7:4] == 4'b0010) // load to y0
		reg_en[2] <= 1'b1;
	else if (ir[7:3] == 5'b10010) // move to y0
		reg_en[2] <= 1'b1;
	else
		reg_en[2] <= 1'b0;	

// for y1 enable
always @*
	if (sync_reset == 1'b1)
		reg_en[3] <= 1'b1;
	else if (ir[7:4] == 4'b0011) // load to y1
		reg_en[3] <= 1'b1;
	else if (ir[7:3] == 5'b10011) // move to y1
		reg_en[3] <= 1'b1;
	else
		reg_en[3] <= 1'b0;	

// for r enable
always @*
	if (sync_reset == 1'b1)
		reg_en[4] <= 1'b1;
	else if (ir[7:5] == 3'b110) // ALU logic
		reg_en[4] <= 1'b1;
	else
		reg_en[4] <= 1'b0;	

// for m enable
always @*
	if (sync_reset == 1'b1)
		reg_en[5] <= 1'b1;
	else if (ir[7:4] == 4'b0101) // load to m
		reg_en[5] <= 1'b1;
	else if (ir[7:3] == 5'b10101) // move to m
		reg_en[5] <= 1'b1;
	else
		reg_en[5] <= 1'b0;	

// for i enable
always @*
	if (sync_reset == 1'b1)
		reg_en[6] <= 1'b1;
	else if (ir[7:4] == 4'b0110) // load to i
		reg_en[6] <= 1'b1;
	else if (ir[7:3] == 5'b10110) // move to i
		reg_en[6] <= 1'b1;
	else if (ir[7:4] == 4'b0111) // load to dm
		reg_en[6] <= 1'b1;
	else if (ir[7:3] == 5'b10111) // move to dm
		reg_en[6] <= 1'b1;	
	else if ((ir[7:6] == 2'b10) && (ir[2:0] == 3'b111)) // move instruction where dm is source
		reg_en[6] <= 1'b1;
	else
		reg_en[6] <= 1'b0;	

// for dm enable
always @*
	if (sync_reset == 1'b1)
		reg_en[7] <= 1'b1;
	else if (ir[7:4] == 4'b0111) // load to dm
		reg_en[7] <= 1'b1;
	else if (ir[7:3] == 5'b10111) // move to dm
		reg_en[7] <= 1'b1;
	else
		reg_en[7] <= 1'b0;	

// for o_reg enable
always @*
	if (sync_reset == 1'b1)
		reg_en[8] <= 1'b1;
	else if (ir[7:4] == 4'b0100) // load to o_reg
		reg_en[8] <= 1'b1;
	else if (ir[7:3] == 5'b10100) // move to o_reg
		reg_en[8] <= 1'b1;
	else
		reg_en[8] <= 1'b0;	
	
/* *******************************
LOGIC FOR DECODING SOURCE REGISTER
**********************************/
// logic for decoding source register
always @*
	if (sync_reset == 1'b1)  
		source_sel <= 4'd10; 
	else if (ir[7] == 1'b0) // condition for load instruction
		source_sel <= 4'd8; // set for data
	else if (ir[7:6] == 2'b10) // condition for move instruction
		if (ir[5:3] == ir[2:0]) // if data == source special condition
			if (ir[5:3] == 3'd4) // if both data and source equal 4
				source_sel <= 4'd4; // move to r register
			else 
				source_sel <= 4'd9; // move to i_pins
		else
			source_sel <= {1'b0,ir[2:0]}; // set as the source value
	else if (ir[7:5] == 3'b110) // ALU opperation
		source_sel <= 4'd10; // it doesn't matter
	else if ((ir[7:4] == 4'b1110)  || (ir[7:4] == 4'b1111)) // jump and jnz checks
		source_sel <= 4'd10; // it doesn't matter
	else
		source_sel <= 4'd10;	

/* ************************************
LOGIC FOR DECODING i, x, and y SELECTS
**************************************/
	// I SEL
always @ *
	if (sync_reset)
		i_sel = 1'b0;
	else if (~ir[7] && ir[6:4] == 3'd7) // LOAD (IF DM OCCURS INCREMENT I)
		i_sel = 1'b1;
	else if (~ir[7] && ir[6:4] == 3'd6) // LOAD (LOAD DATA INTO I)
		i_sel = 1'b0;
	else if (ir[7:6] == 2'b10 && (ir[5:3] == 3'd7 || (ir[2:0] == 3'd7 && ir[5:3] != 3'd6))) // MOV (IF DM IS DST OR DM IS SRC AND DST IS NOT I)
		i_sel = 1'b1;
	else if (ir[7:6] == 2'b10 && ir[5:3] == 3'd6) // MOV (MOV DATA INTO I)
		i_sel = 1'b0;
	else 
		i_sel = 1'b1;
	
	// X SEL
always @ *
	if (sync_reset)
		x_sel = 1'b0;
	else if (ir[7:5] == 3'b110) // ALU FUNCTION
		x_sel = ir[4];
	else
		x_sel = 1'b0;
	
	// Y SEL
always @ *
	if (sync_reset)
		y_sel = 1'b0;
	else if (ir[7:5] == 3'b110) // ALU FUNCTION
		y_sel = ir[3];
	else
		y_sel = 1'b0;
	
/* ***********************************************************
LOGIC FOR DECODING INSTRUCTION !!TYPE!! NOT INSTRUCTION ITSELF
*************************************************************/
// logic for checking if theres a jump 
always @*
	if (sync_reset == 1'b1) // set jump as 0 if sync reset is active 
		jmp <= 1'b0; 
	else if (ir[7:4] == 4'b1110) // if bits 7-4 == 1110, it is a jump instruction
		jmp <= 1'b1; 				  // so set this high
	else // anything else will set jump as 0
		jmp <= 1'b0;

// logic for checking if theres a conditional jump 
always @*
	if (sync_reset == 1'b1) // set conditional jump as 0 if sync reset is active 
		jmp_nz <= 1'b0; 
	else if (ir[7:4] == 4'b1111) // if bits 7-4 == 11111, it is a conditional jump instruction
		jmp_nz <= 1'b1;			  // so set this high
	else // anything else will set conditional jump as 0
		jmp_nz <= 1'b0;	
	
endmodule