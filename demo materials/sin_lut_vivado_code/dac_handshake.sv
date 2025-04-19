
`timescale 1ns / 1ps

module dac_handshake(
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
    
    logic [15:0] next_data_in1, data_in1_r;
    logic [15:0] next_data_in2, data_in2_r;
    logic [3:0] next_counter, counter_r; 

    typedef enum logic [1:0] {
        WAIT_STATE,
        SEND_STATE
    } state_t;
     
    state_t next_state, state_r;
     
    always_ff @(posedge clk) begin
        if(rst) begin 
            state_r <= WAIT_STATE;
        end
        else begin
            state_r <= next_state;
            counter_r <= next_counter;
            data_in1_r <= next_data_in1;
            data_in2_r <= next_data_in2;
        end
    end
     
    always_comb begin
        next_state = state_r;
        next_counter = counter_r;
        next_data_in1 = data_in1_r;
        next_data_in2 = data_in2_r;
        chip_sel = 1'b1;
        data_out1 = '0;
        data_out2 = '0;
        ready = '0;
        
        case(state_r)
            WAIT_STATE: begin
                chip_sel = 1'b1;
                next_counter = $high(data_in1_r);
                next_data_in1 = {4'b0000, data_in1};
                next_data_in2 = {4'b0000, data_in2};
                ready = 1'b1;
                
                if(go) begin
                    next_state = SEND_STATE;
                end
            end 
            SEND_STATE: begin
                data_out1 = data_in1_r[counter_r];
                data_out2 = data_in2_r[counter_r];
                chip_sel = 1'b0;
                next_counter = counter_r - 1;
                ready = 1'b0;
                
                if(next_counter == $high(data_in1_r)) begin
                    next_state = WAIT_STATE;
                end
            end
        endcase
    end
    
    assign dac_clk = clk;
endmodule
