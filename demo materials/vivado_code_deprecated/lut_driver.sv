`timescale 1ns / 1ps

module lut_driver(
    input logic clk,
    input logic rst,
    input logic sw1,
    output logic dac_clk,
    output logic chip_sel,
    output logic data_out1,
    output logic data_out2,
    output logic ready
);

    logic [11:0] data_in;
    logic [11:0] count;
    logic go;

    typedef enum [1:0] {
        WAIT_STATE,
        START
    } state_t;

    state_t state_r;

    always_ff @(posedge clk) begin
        if(rst) begin
            count <= '0;
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
                        count <= count + 1;
                    end
                end
            endcase
        end
    end

    rom_dev rom(.clk(clk), 
                .we(1'b0), 
                .addr(count), 
                .dout(data_in));

    driver_sv spi_driver(.clk(clk), 
                         .rst(rst), 
                         .go(go), 
                         .dac_sel(sw1),
                         .data_in(data_in),
                         .dac_clk(dac_clk), 
                         .chip_sel(chip_sel), 
                         .data_out1(data_out1), 
                         .data_out2(data_out2),
                         .ready(ready)
                         );
endmodule