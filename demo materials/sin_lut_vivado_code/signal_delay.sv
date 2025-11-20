module signal_delay#(
    parameter int DELAY = 2500    // number of cycles to delay
)(
    input  logic clk,
    input  logic rst,
    input  logic din,
    output logic dout
);

    typedef enum logic [1:0] {
        SEND_ZERO,
        SEND_ONE
    } delay_state_t;
    delay_state_t curr_state, next_state; 
    logic [$clog2(DELAY)-1:0] curr_delay_count, next_delay_count;

    always_ff @(posedge clk) begin
        if(rst) begin
            curr_state <= SEND_ONE;
            curr_delay_count <= '0;
        end
        else begin
            curr_state <= next_state;
            curr_delay_count <= next_delay_count;
        end
    end

    always_comb begin
        next_state = curr_state;
        next_delay_count = curr_delay_count;
        case(curr_state) 
            SEND_ZERO: begin
                dout = '0;
                if(din == '1) begin
                    if(curr_delay_count == DELAY-1) begin 
                        next_state = SEND_ONE;
                        dout = '1;
                    end
                    else begin
                        next_delay_count = curr_delay_count + 1;
                    end
                end
            end
            SEND_ONE: begin
                dout = '1;
                if(din == '0) begin //immediate transition to sending 0s
                    next_state = SEND_ZERO;
                    dout = '0;
                    next_delay_count = '0;
                end
            end
        endcase
        
    end

endmodule
