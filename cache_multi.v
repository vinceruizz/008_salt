module cache_multi( clk,
                    data,
                    rdline,
                    rdoffset,
                    wrline,
                    wroffset,
                    wren,
                    q,
						  q_tmp);

input clk;
input [7:0] data;
input [1:0] rdline;
input [2:0] rdoffset;
input [1:0] wrline;
input [2:0] wroffset;
input wren;
output [7:0] q;

output [63:0] q_tmp;

reg [7:0] byteena_a;
always @ *
begin
    byteena_a <= 7'd1 << wroffset;
end

ram_2port cache_ram_inst (
    .byteena_a ( byteena_a ),
    .clock ( ~clk ),
    .data ( {8{data}} ),
    .rdaddress ( rdline ),
    .wraddress ( wrline ),
    .wren ( wren ),
    .q ( q_tmp )
    );

reg [7:0] q;
always @ *
begin
    case(rdoffset)
        8'd0: q = q_tmp[7:0];
        8'd1: q = q_tmp[15:8];
        8'd2: q = q_tmp[23:16];
        8'd3: q = q_tmp[31:24];
        8'd4: q = q_tmp[39:32];
        8'd5: q = q_tmp[47:40];
        8'd6: q = q_tmp[55:48];
        8'd7: q = q_tmp[63:56];
    endcase
end

endmodule 
