
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
    input  sw1,
    output  spi,
    output  chip_sel,
    output  data_out1,
    output  data_out2,
    output led0
    );
    
    lut_driver DUT      (.clk(clk), 
                         .rst(sw0), 
                         .sw1(sw1), 
                         .dac_clk(spi), 
                         .chip_sel(chip_sel), 
                         .data_out1(data_out1), 
                         .data_out2(data_out2), 
                         .ready(led0)
                         );
endmodule
