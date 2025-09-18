`timescale 1ns / 1ps

module lut_driver #(
    localparam LUT_SIZE = 4096,
	localparam ROM_COUNT = 3
)
(
    input logic clk,
    input logic rst,
    input logic [3:0] btn,
    output logic dac_clk,
    output logic chip_sel,
    output logic data_out1,
    output logic data_out2,
    output logic ready
);

    logic [11:0] data_in1, data_in2;
	logic [11:0] outsquarex, outsquarey, outtrianglex, outtriangley, outoctagonx, outoctagony;
    logic [$clog2(LUT_SIZE)-1:0] count;
    logic go;

    typedef enum logic [1:0] {
        START,
        COUNT_STATIC,
		COUNT_DYNAMIC
    } state_t;
    state_t state_r;

    always_ff @(posedge clk) begin
        if(rst) begin
            count <= '0;
            state_r <= COUNT_STATIC;
        end
        else begin
            case(state_r)
                COUNT_STATIC: begin
					if (ready) begin
						count <= count + 1;
						if(count == 4) begin
							count <= '0;
						    state_r <= COUNT_DYNAMIC;
						end
                    end
                end
				COUNT_DYNAMIC: begin
					if (ready) begin
						count <= count + 1;
						if(count == 3) begin
							count <= '0;
							state_r <= COUNT_STATIC;
						end
                    end
				end
            endcase
        end
    end
	
	
	logic [11:0] pos_x, pos_y;
    logic [11:0] speed;
	logic [11:0] triangle_x_box [0:1] = '{0, 3000};
	logic [11:0] triangle_y_box [0:1] = '{0, 2598};
    always_ff @(posedge clk) begin
        if(rst) begin
            pos_x <= '0;
            pos_y <= '0;
            speed <= '1;
        end
        else begin
            speed <= speed - 1;
		    if(speed == '0) begin
			
				case(btn[1:0]) //x case
					2'b01: pos_x <= ((pos_x + triangle_x_box[1]) < 4095) ? pos_x + 1 : pos_x;
					2'b10: pos_x <= ((pos_x + triangle_x_box[0]) > 0)    ? pos_x - 1 : pos_x;
					default: pos_x <= pos_x;
				endcase
				
				case(btn[3:2]) //y case
					2'b01 : pos_y <= ((pos_y + triangle_y_box[1]) < 4095) ? pos_y + 1 : pos_y;
					2'b10 : pos_y <= ((pos_y + triangle_y_box[0]) > 0)    ? pos_y - 1 : pos_y;
					default : pos_y <= pos_y;
				endcase
			end
        end
    end

	logic [3:0] speed_reg;
	logic [11:0] pos_regx, pos_regy;
	always_ff @(posedge clk) begin
		if(rst) begin //clock domain crossing issue, might need to do reset bridge irl
			speed_reg <= '0;
			pos_regx <= '0;
			pos_regy <= '0;
		end
		else if (go) begin
            speed_reg <= speed_reg + 1;
		    if(speed_reg == 8) begin
		        speed_reg <= '0;
			    pos_regx <= pos_x;
			    pos_regy <= pos_y;
		    end
		end
	end

 	//mux outputs to chose which rom will be drawn
 	always_comb begin
 		case(state_r)
 			COUNT_STATIC: begin
 				data_in1 <= outsquarex;
 				data_in2 <= outsquarey;
 			end
 			
 			COUNT_DYNAMIC: begin
 				data_in1 <= outtrianglex + pos_regx;
 				data_in2 <= outtriangley + pos_regy;
 			end
 		endcase
 	end
    assign go = ready;


    squarex_rom squarex 
                (.clk(clk), 
                .we(1'b0), 
                .addr(count), 
                .dout(outsquarex));

    squarey_rom squarey
				(.clk(clk), 
                .we(1'b0), 
                .addr(count), 
                .dout(outsquarey));
				
	trianglex_rom trianglex
				(.clk(clk), 
				.we(1'b0), 
				.addr(count), 
				.dout(outtrianglex));
		
	triangley_rom triangley
				(.clk(clk), 
				.we(1'b0), 
				.addr(count), 
				.dout(outtriangley));
				
	// octagonx_rom octagonx
	// 			(.clk(clk), 
	// 			.we(1'b0), 
	// 			.addr(count), 
	// 			.dout(outoctagonx));
		
	// octagony_rom octagony
	// 			(.clk(clk), 
	// 			.we(1'b0), 
	// 			.addr(count), 
	// 			.dout(outoctagony));
				
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
