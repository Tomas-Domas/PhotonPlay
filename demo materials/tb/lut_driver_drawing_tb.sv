`timescale 1ns / 1ps

//meant to be paired with dac_handshake headless
module lut_driver_drawing_tb (
);

localparam NUM_CYCLES = 20000;

logic clk = 1'b0, rst, dac_clk, chip_sel, data_out1, data_out2, ready, laser_en;
logic [3:0] btn;
lut_driver DUT(.*);

event clk_disabled;
event button_start;

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
	->button_start;
end

initial begin : sim_loop
    @button_start;
	btn <= 4'b0001;
    repeat (NUM_CYCLES) @(posedge clk);
    disable gen_clk;
    ->clk_disabled;
end

//pos should not change until the next loop iter
// assert property (@(posedge clk) disable iff (rst) 
//     (DUT.state_r == DUT.COUNT_BORDER && DUT.count == '0) |=> ($stable(DUT.pos_x[0]) throughout   //should be stable until...
//     (DUT.state_r == DUT.COUNT_APPLE && DUT.count == DUT.APPLE_LUT_SIZE-1)[->1]));             //this condition becomes true

//on state transistion, the count should be zero
assert property (@(posedge clk) disable iff(rst)
    ($changed(DUT.state_r) |-> (DUT.count == '0)));

//after a state transition, the next time go happens count should have been zero for at least one cycle
//this ensures that the first packet sent in the state is the beginnning of the ROM
assert property (@(posedge clk) disable iff(rst)
    ($changed(DUT.state_r) |-> ((DUT.count == '0)[->1] ##1 (DUT.count == '0)[*0:$] ##0 DUT.go[->1])) 
) ; 

//this actually does the the same as the last one
assert property (@(posedge clk) disable iff(rst)
    ($changed(DUT.state_r) |-> (((DUT.count == '0)[->1] and DUT.go[->1]) |-> (DUT.count == '0 && DUT.go == '1))) 
) ; 
endmodule