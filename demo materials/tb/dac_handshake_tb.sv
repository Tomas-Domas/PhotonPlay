`timescale 1ns / 1ps

//standalone dac testbench
module dac_handshake_tb #(
);

localparam NUM_TESTS = 1000;
localparam DEBUG = 1;

logic clk = 1'b0, rst, go, ready, dac_clk, chip_sel, data_out1, data_out2;
logic [11:0] data_in1, data_in2;
dac_handshake DUT(.*);
class dac_item;
    rand bit [11:0] data_in1, data_in2;
endclass

int passed, failed;

mailbox driver_mailbox = new;
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
    go <= 1'b0;
    data_in1 <= '0;
    data_in2 <= '0;
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst <= 1'b0;
end

initial begin : generator
    dac_item test;

    for(int i=0; i<NUM_TESTS; i++) begin
        test = new();
        if(!DEBUG) assert (test.randomize()) else $fatal(1, "Randomization Failed.");
        else begin
            test.data_in1 = i;
            test.data_in2 = i;
        end
        driver_mailbox.put(test);
    end
end

initial begin : start_monitor
    logic [15:0] data_out1_res, data_out2_res;
    //wait until cycle where rst and go are high after the clk pulse
    //this is the data that will actually be sampled during the next clock pulse where go is detected as true.
    @(posedge clk iff (!rst && go));
    scoreboard_data_in1_mailbox.put(data_in1);
    scoreboard_data_in2_mailbox.put(data_in2);
    for(int i=15; i>=0; i--) begin
        @(posedge clk);
        data_out1_res[i] = data_out1;
        data_out2_res[i] = data_out2;
    end
    scoreboard_data_out1_mailbox.put(data_out1_res);
    scoreboard_data_out2_mailbox.put(data_out2_res);

    forever begin
        //this is to sammple the input data the cycle that go and ready become asserted
        @(posedge clk iff (go && ready));
        scoreboard_data_in1_mailbox.put(data_in1);
        scoreboard_data_in2_mailbox.put(data_in2);

        //immediately after starting, need to start recording the outputs
        for(int i=15; i>=0; i--) begin
            @(posedge clk); //the first time this happens is the state transistion into the next state
            data_out1_res[i] = data_out1;
            data_out2_res[i] = data_out2;
        end
        scoreboard_data_out1_mailbox.put(data_out1_res);
        scoreboard_data_out2_mailbox.put(data_out2_res);
    end
end

initial begin : driver
    dac_item test;
    forever begin
        @(posedge clk iff (ready && !rst));
        driver_mailbox.get(test);
        data_in1 <= test.data_in1;
        data_in2 <= test.data_in2;
        go <= 1'b1;
        @(posedge clk); //go gets sent, but doesn't change the state yet
        go <= 1'b0;
        @(posedge clk); //state transistion happens here

        //cycle inputs randomly
        while(!ready) begin
            go <= $urandom;
            data_in1 <= $urandom;
            data_in2 <= $urandom;

            @(posedge clk);

            //need to allow combinatorial circuit time to change the value of ready after the clock edge
            #1;
        end
        go <= 1'b0;
    end
end

initial begin : scoreboard
    logic [15:0] data_out1_res, data_out2_res;
    logic [11:0] expected_res1, expected_res2;

    passed = 0;
    failed = 0;
    for(int i=0; i<NUM_TESTS; i++) begin
        scoreboard_data_in1_mailbox.get(expected_res1);
        scoreboard_data_in2_mailbox.get(expected_res2);
        scoreboard_data_out1_mailbox.get(data_out1_res);
        scoreboard_data_out2_mailbox.get(data_out2_res);
        if(expected_res1 == data_out1_res[11:0] && expected_res2 == data_out2_res[11:0] && data_out1_res[15:12] == '0 && data_out1_res[15:12] == '0) begin
            $display("Test passed (time %0t) for inputs = [%h, %h]", $time, expected_res1, expected_res2);
            passed++; 
        end
        else begin
            $display("Test failed (time %0t) for inputs = [%h, %h] (recieved [%h, %h], header [%h, %h])", $time, expected_res1, expected_res2, data_out1_res[11:0], data_out2_res[11:0], data_out1_res[15:12], data_out2_res[15:12]);
            failed++;
        end
    end

    $display("Tests completed: %0d passed, %0d failed", passed, failed);
    disable gen_clk;
end

assert property (@(posedge clk) disable iff (rst) ready == chip_sel); //assert that chip_sel is always the same as ready
assert property (@(posedge clk) disable iff (rst) (ready && go) |=> (ready == '0)); //ready is false one cycle after go

endmodule