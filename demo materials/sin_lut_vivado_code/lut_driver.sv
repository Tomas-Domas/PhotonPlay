`timescale 1ns / 1ps

module lut_driver #(
    localparam LUT_SIZE = 128
)
(
    input logic clk,
    input logic rst,
    output logic dac_clk,
    output logic chip_sel,
    output logic data_out1,
    output logic data_out2,
    output logic ready
);

    logic [11:0] data_in1, data_in2;
    logic [$clog2(LUT_SIZE)-1:0] count1, count2;
    logic go;

    typedef enum [1:0] {
        WAIT_STATE,
        START
    } state_t;

    state_t state_r;

    always_ff @(posedge clk) begin
        if(rst) begin
            count1 <= '0;
            go <= 1'b0; 
            state_r <= WAIT_STATE;
        end
        else begin
            case(state_r)
                WAIT_STATE: begin
                    state_r <= START;
                    go <= 1'b1;
                end
                START: begin
                    go <= 1'b0;
                    if(ready) begin 
                        state_r <= WAIT_STATE;
                        count1 <= count1 + 1;
                    end
                end
            endcase
        end
    end

    assign count2 = count1 + 64;

    rom_dev #(.LUT_SIZE(LUT_SIZE)) rom1 
                (.clk(clk), 
                .we(1'b0), 
                .addr(count1), 
                .dout(data_in1));

    rom_dev #(.LUT_SIZE(LUT_SIZE)) rom2(.clk(clk), 
                .we(1'b0), 
                .addr(count2), 
                .dout(data_in2));

    dac_handshake dac_mod(.clk(clk), 
                         .rst(rst), 
                         .go(go), 
                         .data_in1(data_in1),
                         .data_in2(data_in2),
                         .dac_clk(dac_clk), 
                         .chip_sel(chip_sel), 
                         .data_out1(data_out1), 
                         .data_out2(data_out2),
                         .ready(ready)
                         );
endmodule