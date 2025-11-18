module delay_signal #(
    parameter int DELAY = 2500    // number of cycles to delay
)(
    input  logic clk,
    input  logic rst,
    input  logic din,
    output logic dout
);

    // Shift register for delay storage
    logic [DELAY:0] shift_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= '0;
        end else begin
            shift_reg <= {shift_reg[DELAY-1:0], din};
        end
    end

    assign dout = shift_reg[DELAY];

endmodule
