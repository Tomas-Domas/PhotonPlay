module triangley_rom #(
    parameter LUT_SIZE = 10
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
		rom[2] = 12'd0;
		rom[3] = 12'd0; //traverse bottom
		rom[4] = 12'd867;
		rom[5] = 12'd1733;
		rom[6] = 12'd2598; //traverse right side
		rom[7] = 12'd1733;
		rom[8] = 12'd867;
		rom[9] = 12'd0; //traverse left side
    end

    always @(posedge clk) begin
        if (we) rom[addr] <= di;
        dout <= rom[addr];
    end

endmodule
