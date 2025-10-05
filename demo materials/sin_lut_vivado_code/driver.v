
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2025 02:27:45 PM
// Design Name: 
// Module Name: driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module driver(
    input  clk,
    input  sw0,
    input [3:0] btn,
    output  dac_clk,
    output  chip_sel,
    output  data_out1,
    output  data_out2,
    output  led0,
    output  laser_en
    );
	
	reg [6:0] count;
	reg clk_div;
	always @(posedge clk) begin
		if(sw0) begin
			count <= 0;
			clk_div <= 0;
		end
		else begin
			count <= count + 1;
			if(&count) clk_div <= ~clk_div;
		end
	end

    
    lut_driver DUT      (.clk(clk_div), 
                         .rst(sw0), 
                         .btn(btn),
                         .dac_clk(dac_clk), 
                         .chip_sel(chip_sel), 
                         .data_out1(data_out1), 
                         .data_out2(data_out2), 
                         .ready(led0),
                         .laser_en(laser_en)
                         );
endmodule
