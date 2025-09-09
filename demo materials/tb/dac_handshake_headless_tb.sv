`timescale 1ns / 1ps


module dac_handshake_headless_tb #(
    parameter file_name="output.txt",
    parameter debug=0
)
(
    //connect this interface to the internal dut from the main testbench
    input event clk_disabled,
    input logic clk, //input clock rate; note this is the same as the clock rate you want the dac at
    input logic rst,
    input logic go, //start translation
    input logic [11:0] data_in1, //input data entered in parallel holding register
    input logic [11:0] data_in2,
    output logic dac_clk, //output dac clock (max 30Mhz)
    output logic chip_sel, //connects to dac CS bit. Used to start transactiton
    output logic data_out1, //output to dac1
    output logic data_out2, //output to dac2
    output logic ready //indicates whether module is currently sending data to the dac
);


int passed, failed;
mailbox scoreboard_data_in1_mailbox = new;
mailbox scoreboard_data_in2_mailbox = new;
mailbox scoreboard_data_out1_mailbox = new;
mailbox scoreboard_data_out2_mailbox = new;
integer file_handle;

initial begin : file_select
    file_handle = $fopen(file_name, "w");

    if (file_handle == 0) begin
        $fatal("Failed to open file!");
    end
end

initial begin : write_file
    @clk_disabled;
    $fclose(file_handle);
    $display("Wrote to file %s", file_name);
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

initial begin : dac_scoreboard
    logic [15:0] data_out1_res, data_out2_res;
    logic [11:0] expected_res1, expected_res2;

    forever begin
        scoreboard_data_in1_mailbox.get(expected_res1);
        scoreboard_data_in2_mailbox.get(expected_res2);
        scoreboard_data_out1_mailbox.get(data_out1_res);
        scoreboard_data_out2_mailbox.get(data_out2_res);
        if(expected_res1 == data_out1_res[11:0] && expected_res2 == data_out2_res[11:0] && data_out1_res[15:12] == '0 && data_out1_res[15:12] == '0) begin
            $fwrite(file_handle, "%d, %d\n", expected_res1, expected_res2);
            if(debug) begin
                $display("DAC Test passed (time %0t) for inputs = [%h, %h]", $time, expected_res1, expected_res2);
            end
        end
        else begin
            $fatal("DAC Test failed (time %0t) for inputs = [%h, %h] (recieved [%h, %h], header [%h, %h])", $time, expected_res1, expected_res2, data_out1_res[11:0], data_out2_res[11:0], data_out1_res[15:12], data_out2_res[15:12]);
        end
    end
end


assert property (@(posedge clk) disable iff (rst) ready == chip_sel); //assert that chip_sel is always the same as ready
assert property (@(posedge clk) disable iff (rst) (ready && go) |=> (ready == '0)); //ready is false one cycle after go

endmodule