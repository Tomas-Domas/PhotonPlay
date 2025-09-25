module x_apple #(
    parameter LUT_SIZE = 5
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
		rom[0] = 12'd100;
		rom[1] = 12'd0;
		rom[2] = 12'd0;
		rom[3] = 12'd100;
		rom[4] = 12'd100;
    end

    always @(posedge clk) begin
        if (we) rom[addr] <= di;
        dout <= rom[addr];
    end

endmodule
