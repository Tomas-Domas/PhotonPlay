`timescale 1ns / 1ps

module lut_driver #(
	localparam MAX_LUT_SIZE = 4096,
    localparam APPLE_OFFSET_LUT_SIZE = 500,
	localparam TRIANGLE_LUT_SIZE = 10,
	localparam BORDER_LUT_SIZE = 5,
	localparam APPLE_LUT_SIZE = 5
)
(
    input logic clk,
    input logic rst,
    input logic [3:0] btn,
    output logic dac_clk,
    output logic chip_sel,
    output logic data_out1,
    output logic data_out2,
    output logic ready,
    output logic laser_en
);

    logic [11:0] data_in1, data_in2;
	logic [11:0] outsquarex, outsquarey, outapplex, outappley, outtrianglex, outtriangley, outapplexoffset, outappleyoffset;
    logic [$clog2(MAX_LUT_SIZE)-1:0] count;
    logic go;

    typedef enum logic [1:0] {
        COUNT_BORDER,
		COUNT_TRIANGLE,
		COUNT_APPLE
    } state_t;
    state_t state_r;

    always_ff @(posedge clk) begin
        if(rst) begin
            count <= '0;
            state_r <= COUNT_BORDER;
        end
        else begin
            case(state_r)
                COUNT_BORDER: begin
					if (ready) begin
						count <= count + 1;
						if(count == BORDER_LUT_SIZE-1) begin
							count <= '0;
						    state_r <= COUNT_TRIANGLE;
						end
                    end
                end
				COUNT_TRIANGLE: begin
					if (ready) begin
						count <= count + 1;
						if(count == TRIANGLE_LUT_SIZE-1) begin
							count <= '0;
							state_r <= COUNT_APPLE;
						end
                    end
				end
				COUNT_APPLE: begin
					if (ready) begin
						count <= count + 1;
						if(count == APPLE_LUT_SIZE-1) begin
							count <= '0;
							state_r <= COUNT_BORDER;
						end
                    end
				end
            endcase
        end
    end
	
	logic [11:0] pos_x, pos_y;
    logic [8:0] speed;
	logic [11:0] triangle_x_box [0:1] = '{0, 100};
	logic [11:0] triangle_y_box [0:1] = '{0, 87};
    always_ff @(posedge clk) begin //moving triangle
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
	
	logic [11:0] apple_x_box [0:1] = '{0, 100};
	logic [11:0] apple_y_box [0:1] = '{0, 100};
	logic [$clog2(APPLE_OFFSET_LUT_SIZE)-1:0] apple_count;
	always_ff @(posedge clk) begin //collision detection for apple
        if(rst) begin
			apple_count <= '0;
        end
        else begin
			///////////////////////// SIDE COLLISION ///////////////////////
			if ((pos_x + triangle_x_box[1] == apple_x_box[0] + outapplexoffset) ||
				(pos_x + triangle_x_box[0] == apple_x_box[1] + outapplexoffset)) begin //does the triangle touch the x bounds of the apple?
				
				if ((triangle_y_box[0] + pos_y <= apple_y_box[1] + outappleyoffset) &&
					(triangle_y_box[0] + pos_y >= apple_y_box[0] + outappleyoffset)) begin //does the bottom of the triangle fall within apples y bounds?
					apple_count <= apple_count + 1;
				end
				
				else if ((triangle_y_box[1] + pos_y <= apple_y_box[1] + outappleyoffset) &&
						 (triangle_y_box[1] + pos_y >= apple_y_box[0] + outappleyoffset)) begin //does the top of the trianlge fall within apples y bounds?
					apple_count <= apple_count + 1;
				end
			end

			///////////////////////// TOP/BOTTOM COLLISION ///////////////////////
			if ((pos_y + triangle_y_box[1] == apple_y_box[0] + outappleyoffset) ||
				(pos_y + triangle_y_box[0] == apple_y_box[1] + outappleyoffset)) begin //does the triangle touch the y bounds of the apple?
				
				if ((triangle_x_box[0] + pos_x <= apple_x_box[1] + outapplexoffset) &&
					(triangle_x_box[0] + pos_x >= apple_x_box[0] + outapplexoffset)) begin //does the left side of the triangle fall within apples y bounds?
					apple_count <= apple_count + 1;
				end
				
				else if ((triangle_x_box[1] + pos_x <= apple_x_box[1] + outapplexoffset) &&
						 (triangle_x_box[1] + pos_x >= apple_x_box[0] + outapplexoffset)) begin //does the right side of the trianlge fall within apples y bounds?
					apple_count <= apple_count + 1;
				end
			end

		end
	end

	logic [$clog2(APPLE_LUT_SIZE+TRIANGLE_LUT_SIZE+BORDER_LUT_SIZE)-1:0] speed_reg;
	logic [11:0] pos_regx, pos_regy;
	always_ff @(posedge clk) begin
		if(rst) begin //clock domain crossing issue, might need to do reset bridge irl
			speed_reg <= '0;
			pos_regx <= '0;
			pos_regy <= '0;
		end
		else if (go) begin
            speed_reg <= speed_reg + 1;
		    if(speed_reg == (APPLE_LUT_SIZE+TRIANGLE_LUT_SIZE+BORDER_LUT_SIZE)-1) begin
		        speed_reg <= '0;
			    pos_regx <= pos_x;
			    pos_regy <= pos_y;
		    end
		end
	end

 	//mux outputs to chose which rom will be drawn
 	always_comb begin
        // Disable laser before the start of each draw
        if(count == '0) begin
            laser_en <= '1;
        end
        else begin
            laser_en <= '0;
        end 

 		case(state_r)
 			COUNT_BORDER: begin
 				data_in1 <= outsquarex;
 				data_in2 <= outsquarey;
 			end
 			
 			COUNT_TRIANGLE: begin
 				data_in1 <= outtrianglex + pos_regx;
 				data_in2 <= outtriangley + pos_regy;
 			end
			
			COUNT_APPLE: begin
 				data_in1 <= outapplex + outapplexoffset;
 				data_in2 <= outappley + outappleyoffset;
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
				
	x_apple applex
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outapplex));
			
	y_apple appley
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outappley));
		
	x_apple_offset applexoffset
		(.clk(clk), 
		.we(1'b0), 
		.addr(apple_count), 
		.dout(outapplexoffset));
			
	y_apple_offset appleyoffset
		(.clk(clk), 
		.we(1'b0), 
		.addr(apple_count), 
		.dout(outappleyoffset));
				
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
