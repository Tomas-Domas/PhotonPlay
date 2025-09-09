`timescale 1ns / 1ps

module lut_driver_tb (
);

localparam NUM_CYCLES = 7000;

logic clk = 1'b0, rst, dac_clk, chip_sel, data_out1, data_out2, ready;
logic [3:0] btn;
lut_driver DUT(.*);

event clk_disabled;

dac_handshake_headless_tb dac_tb (
                        .clk_disabled(clk_disabled),
                        .clk(clk),
                        .rst(rst),
                        .go(DUT.go),
                        .data_in1(DUT.data_in1),
                        .data_in2(DUT.data_in2),
                        .dac_clk(dac_clk),
                        .chip_sel(chip_sel),
                        .data_out1(data_out1),
                        .data_out2(data_out2),
                        .ready(ready));

mailbox scoreboard_data_in1_mailbox = new;
mailbox scoreboard_data_in2_mailbox = new;
mailbox scoreboard_data_out1_mailbox = new;
mailbox scoreboard_data_out2_mailbox = new;

initial begin : gen_clk
    forever #5 clk <= ~clk;
end

initial begin : initialization
    $timeformat(-9, 0, " ns");
    rst <= 1'b1;
    btn <= '0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst <= 1'b0;
end

initial begin : sim_loop
    #NUM_CYCLES;
    disable gen_clk;
    ->clk_disabled;
end

endmodule