module computational_unit (
	input clk, sync_reset, i_sel, y_sel, x_sel,
	input [3:0] i_pins, nibble_ir, source_sel, dm,
	input [8:0] reg_en,
	output reg r_eq_0,
	output reg [3:0] i, data_bus, o_reg, x0, x1, y0, y1, m, r,
	output reg [7:0] from_CU
	);
	
assign from_CU = {x1,x0};
	
/* ****************************************
LOGIC FOR SOURCE SELECTION FOR THE DATA BUS	
******************************************/
	always @ *
		case (source_sel)
			4'd0: data_bus <= x0;
			4'd1: data_bus <= x1;
			4'd2: data_bus <= y0;
			4'd3: data_bus <= y1;
			4'd4: data_bus <= r;
			4'd5: data_bus <= m;
			4'd6: data_bus <= i;
			4'd7: data_bus <= dm;
			4'd8: data_bus <= nibble_ir;
			4'd9: data_bus <= i_pins;
			default: data_bus <= 4'H0;
		endcase
	
	// ----- X/Y SELECT MUX ----- //
	
	reg [3:0] x, y;
	always @ *
		if (x_sel)
			x <= x1;
		else
			x <= x0;
	
	always @ *
		if (y_sel)
			y <= y1;
		else
			y <= y0;
	
	reg [7:0] mul;
	always @ *
		mul <= x * y;
	
	// ----- ALU ----- //
	
	reg [3:0] alu_out;
	reg [2:0] alu_func;
	reg alu_out_eq_0, ir3;
	
	// ir3
	always @ *
		ir3 <= nibble_ir[3];
		
	// alu_func
	always @ *
		alu_func <= nibble_ir[2:0];
	
	// alu_out
	always @ *
		if (sync_reset)
			alu_out <= 4'H0;
		else
			case (alu_func)
				3'b000:	if (ir3) alu_out <= r;
							else alu_out <= ~x + 4'H1;
				3'b001:	alu_out <= x-y;
				3'b010: 	alu_out <= x+y;
				3'b011: 	alu_out <= mul[7:4];
				3'b100: 	alu_out <= mul[3:0];
				3'b101: 	alu_out <= x^y;
				3'b110: 	alu_out <= x&y;
				default: if (ir3) alu_out <= r;
							else alu_out <= ~x;
			endcase
	
	// zero_flag
	always @ *
		if (sync_reset)
			alu_out_eq_0 <= 1'b1;
		else
			alu_out_eq_0 <= (alu_out == 4'H0);
	
	// ----- REGISTERS ----- //
	
	// x0
	always @ (posedge clk)
		if (reg_en[0])
			x0 <= data_bus;
		else
			x0 <= x0;
	
	// x1
	always @ (posedge clk)
		if (reg_en[1])
			x1 <= data_bus;
		else
			x1 <= x1;
	
	// y0
	always @ (posedge clk)
		if (reg_en[2])
			y0 <= data_bus;
		else
			y0 <= y0;
	// y1
	always @ (posedge clk)
		if (reg_en[3])
			y1 <= data_bus;
		else
			y1 <= y1;
	
	// r
	always @ (posedge clk)
		if (reg_en[4])
			r <= alu_out;
		else
			r <= r;
	
	// zero_flag
	always @ (posedge clk)
		if (reg_en[4])
			r_eq_0 <= alu_out_eq_0;
		else
			r_eq_0 <= r_eq_0;
	
	// m
	always @ (posedge clk)
		if (reg_en[5])
			m <= data_bus;
		else
			m <= m;
	
	// i
	always @ (posedge clk)
		if (reg_en[6] && i_sel)
			i <= i + m;
		else if (reg_en[6] && ~i_sel)
			i <= data_bus;
		else
			i <= i;
	
	// o_reg
	always @ (posedge clk)
		if (reg_en[8])
			o_reg <= data_bus;
		else
			o_reg <= o_reg;
	
endmodule