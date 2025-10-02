`timescale 1ns / 1ps

module lut_driver #(
	localparam MAX_LUT_SIZE = 4096,
    localparam APPLE_OFFSET_LUT_SIZE = 500,
	localparam TRIANGLE_LUT_SIZE = 10,
	localparam BORDER_LUT_SIZE = 5,
	localparam APPLE_LUT_SIZE = 5,
	localparam SPEED_DOWN = 2,
	localparam BUFFER_SIZE = (TRIANGLE_LUT_SIZE + APPLE_LUT_SIZE + BORDER_LUT_SIZE)*SPEED_DOWN
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
	logic [$clog2(BUFFER_SIZE)-1:0] speed;
	logic [11:0] triangle_x_box [0:1] = '{0, 100};
	logic [11:0] triangle_y_box [0:1] = '{0, 87};
    always_ff @(posedge clk) begin //moving triangle
        if(rst) begin
            pos_x <= 4095/2;
            pos_y <= 4095/2;
            speed <= '0;
        end
        else if (go) begin
            speed <= speed + 1;
		    if(speed == BUFFER_SIZE-1) begin
				//defaults
				speed <= '0;
				pos_x <= pos_x + x_velocity;
				pos_y <= pos_y + y_velocity;
			
				//collision detection for x cases
				if ((pos_x + x_velocity + triangle_x_box[1]) >= 4095) begin
						pos_x <= 4095/2;
						pos_y <= 4095/2;
				end else if ((pos_x + x_velocity + triangle_x_box[0]) <= 0) begin
						pos_x <= 4095/2;
						pos_y <= 4095/2;
				end

				//collision detection for y cases
				if ((pos_y + y_velocity + triangle_y_box[1]) >= 4095) begin
						pos_x <= 4095/2;
						pos_y <= 4095/2;
				end else if ((pos_y + y_velocity + triangle_y_box[0]) <= 0) begin
						pos_x <= 4095/2;
						pos_y <= 4095/2;
				end
			end
        end
    end

	logic [11:0] x_velocity, y_velocity;
	always_ff @(posedge clk) begin
		if (rst) begin
			x_velocity <= BUFFER_SIZE;
			y_velocity <= '0;
		end
		else begin
			casez(btn[3:0])
				4'b??01: begin
					x_velocity <= BUFFER_SIZE;
					y_velocity <= '0;
				end
				4'b??10: begin
					x_velocity <= -1*BUFFER_SIZE;
					y_velocity <= '0;
				end
				4'b01??: begin
					x_velocity <='0;
					y_velocity <= BUFFER_SIZE;
				end
				4'b10??: begin
					x_velocity <='0;
					y_velocity <= -1*BUFFER_SIZE;
				end
				default: begin
					x_velocity <= x_velocity;
					y_velocity <= y_velocity;
				end 
			endcase
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
 				data_in1 <= outtrianglex + pos_x;
 				data_in2 <= outtriangley + pos_y;
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
