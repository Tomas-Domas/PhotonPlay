
`timescale 1ns / 1ps

module driver_sv(
    input logic clk, //input clock rate; note this is the same as the clock rate you want the dac at
    input logic rst,
    input logic go, //start translation
    input logic dac_sel, //send to dac 1 or 2
    input logic [11:0] data_in, //input data entered in parallel holding register
    output logic dac_clk, //output dac clock (max 30Mhz)
    output logic chip_sel, //connects to dac CS bit. Used to start transactiton
    output logic data_out1, //output to dac1
    output logic data_out2, //output to dac2
    output logic ready //indicates whether module is currently sending data to the dac
    );
    
    logic next_dac_sel, dac_sel_r;
    logic [15:0] next_data_in, data_in_r;
    logic [3:0] next_counter, counter_r; 
    logic [15:0] next_save1, save1_r;
    logic [15:0] next_save2, save2_r;

    typedef enum logic [1:0] {
        WAIT_STATE,
        SEND_STATE
    } state_t;
     
    state_t next_state, state_r;
     
    always_ff @(posedge clk) begin
        if(rst) begin 
            state_r <= WAIT_STATE;
            dac_sel_r <= 1'b0;
        end
        else begin
            state_r <= next_state;
            counter_r <= next_counter;
            data_in_r <= next_data_in;
            dac_sel_r <= next_dac_sel;
            save1_r <= next_save1;
            save2_r <= next_save2;
        end
    end
     
    always_comb begin
        next_state = state_r;
        next_counter = counter_r;
        next_data_in = data_in_r;
        next_dac_sel = dac_sel_r;
        next_save1 = save1_r;
        next_save2 = save2_r;
        chip_sel = 1'b1;
        data_out1 = '0;
        data_out2 = '0;
        ready = '0;
        
        case(state_r)
            WAIT_STATE: begin
                chip_sel = 1'b1;
                next_counter = $high(data_in_r);
                next_data_in = {4'b0000, data_in};
                next_dac_sel = dac_sel;
                ready = 1'b1;
                
                if(go) begin
                    next_state = SEND_STATE;
                end
            end 
            SEND_STATE: begin
                chip_sel = 1'b0;
                case(dac_sel_r)
                    0: begin
                        data_out1 = data_in_r[counter_r];
                        next_save1 = data_in_r;
                        data_out2 = save2_r[counter_r];
                    end
                    1: begin
                        data_out1 = save1_r[counter_r];
                        data_out2 = data_in_r[counter_r];
                        next_save2 = data_in_r;
                    end
                endcase
                next_counter = counter_r - 1;
                ready = 1'b0;
                
                if(next_counter == $high(data_in_r)) begin
                    next_state = WAIT_STATE;
                end
            end
        endcase
    end
    
    assign dac_clk = clk;
endmodule
