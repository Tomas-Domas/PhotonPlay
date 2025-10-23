`timescale 1ns / 1ps

module lut_driver_simple_tb ();

	localparam int CLOCK_CYCLES_RUN = 500;
	logic clk=1'b0, rst, dac_clk, chip_sel, data_out1, data_out2, ready, laser_en;
    logic [3:0] btn = 1'b0;
    
	initial begin : gen_clk
		forever #5 clk <= ~clk;
	end

	lut_driver DUT(.*);

	int i = 0;
	initial begin
		$timeformat(-9, 0, " ns");
		rst <= 1'b1;
		repeat (5) @(posedge clk);

		@(negedge clk);
		rst <= 1'b0;
		@(posedge clk);

        for(int i=0; i<CLOCK_CYCLES_RUN; i++) begin
    		@(posedge ready);
        end  
        disable gen_clk;

	end

endmodule
