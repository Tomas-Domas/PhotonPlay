`timescale 1ns / 1ps

module game_draw_loop 
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
    logic [11:0] circle_in1, circle_in2, rect_in1, rect_in2;
    logic [$clog2(LUT_SIZE)-1:0] count_r, next_count;
    logic go;

    typedef enum [1:0] {
        START,
        RETRIEVE_CIRCLE,
        CIRCLE,
        SQUARE
    } state_t;

    state_t state_r, next_state;

    //circle rom
    rom_circle rom_circle_x  
                (.clk(clk), 
                .we(1'b0), 
                .addr(count_r), 
                .dout(circle_in1));
    rom_circle rom_circle_x
                (.clk(clk), 
                .we(1'b0), 
                .addr(count_r), 
                .dout(circle_in2));
    //square rom
    rom_rectx rom_rect_x
                (.clk(clk), 
                .we(1'b0), 
                .addr(count_r), 
                .dout(rect_in1));
    rom_recty rom_rect_x
                (.clk(clk), 
                .we(1'b0), 
                .addr(count_r), 
                .dout(rect_in2));

    //2 process fsm
    always_ff @(posedge clk) begin
        if(rst) begin
            state_r <= START;
            count_r <= '0;
        end
        else begin
            state_r <= next_state;
            count_r <= next_count;
        end
    end

    always_comb begin
        data_in1 = '0;
        data_in2 = '0;
        go = 1'b0;
        next_state = state_r;
        next_count = count_r;

        case(state_r)
            START: begin
                next_state = RETRIEVE_CIRCLE;
                next_count = MAX_COUNT_CIRCLE; 
            end
            RETRIEVE_CIRCLE: begin
                //1 cycle latency due to block ram access
                next_state = CIRCLE;
                if(ready) begin
                    next_count = count-1;
                end
            end
            CIRCLE: begin
                if(ready) begin
                    go = 1'b1;
                    next_count = count_r-1;
                end
                //last bit of data will have been sent out once count_r wraps around again due to rom latency
                if(count_r == $high(count_r)) begin
                    next_state = RETRIEVE_RECT;
                    next_count = MAX_COUNT_RECT;
                end
                data_in1 = circle_in1;
                data_in2 = circle_in2;
            end 
            RETRIEVE_RECT: begin
                next_state = RECT;
                if(ready) begin
                    next_count = count-1;
                end
            end
            RECT: begin
                if(ready) begin
                    go = 1'b1;
                    next_count = count_r-1;
                end
                //last bit of data will have been sent out once count_r wraps around again due to rom latency
                if(count_r == $high(count_r)) begin
                    next_state = START;
                    next_count = '0;
                end
                data_in1 = rect_in1;
                data_in2 = rect_in2;
            end
        endcase 
    end

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