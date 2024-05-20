module cache (
   input wire clk, wren,
   input wire [7:0] data,
   input wire [4:0] rdoffset, wroffset,
   output wire [7:0] q
);

wire [31:0] byteena_a;
wire [255:0] q_tmp;

assign byteena_a = 32'b1 << wroffset;

ram_2port ram (
    .byteena_a(byteena_a),
    .clock(~clk),
    .data({32{data}}),
    .rdaddress(1'b0),
    .wraddress(1'b0),
    .q(q_tmp),
    .wren(wren)
);

assign q = q_tmp[rdoffset*8 +:8];

endmodule