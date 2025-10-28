module y_square #(
    parameter LUT_SIZE = 5,
    parameter SQUARE_SIZE = 128
)
(
    input clk,
    input we,
    input [$clog2(LUT_SIZE)-1:0] addr,
    input [11:0] di,
    output [11:0] dout
);

    reg [11:0] rom [LUT_SIZE-1:0];
    reg [11:0] dout;

    initial begin
		rom[0] = 12'd0;
		rom[1] = 12'd0;
		rom[2] = 12'(SQUARE_SIZE-1);
		rom[3] = 12'(SQUARE_SIZE-1);
		rom[4] = 12'd0;
    end

    always @(posedge clk) begin
        if (we) rom[addr] <= di;
        dout <= rom[addr];
    end

endmodule
