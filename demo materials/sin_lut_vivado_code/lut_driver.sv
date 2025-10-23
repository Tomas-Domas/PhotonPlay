`timescale 1ns / 1ps

module lut_driver #(
	localparam MAX_LUT_SIZE = 4096,
    localparam APPLE_OFFSET_LUT_SIZE = 500,
	localparam TRIANGLE_LUT_SIZE = 10,
	localparam BORDER_LUT_SIZE = 5,
	localparam APPLE_LUT_SIZE = 5,
	localparam SPEED_DOWN = 2,
	localparam VELOCITY = 100, //originally 64
	localparam MAX_NUM_SEGMENTS = 10,
	localparam TIME_TO_SEND = 16,
	localparam TRIANGLE_X_BOX = 100,
	localparam TRIANGLE_Y_BOX = 87,
	localparam APPLE_X_BOX = 100,
	localparam APPLE_Y_BOX = 100
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
	logic [$clog2(MAX_NUM_SEGMENTS)-1:0] current_segment, current_length;
    logic go;

    typedef enum logic [1:0] {
        COUNT_BORDER,
		COUNT_SEGMENTS,
		COUNT_APPLE
    } state_t;
    state_t state_r;

	//Draw loop
    always_ff @(posedge clk) begin
        if(rst) begin
            count <= '0;
			current_segment <= '0;
            state_r <= COUNT_BORDER;
        end
        else begin
            case(state_r)
                COUNT_BORDER: begin
					if (ready) begin
						count <= count + 1;
						if(count == BORDER_LUT_SIZE-1) begin
							count <= '0;
						    state_r <= COUNT_SEGMENTS;
						end
                    end
                end
				COUNT_SEGMENTS: begin
					if (ready) begin
						count <= count + 1;
						if(count == TRIANGLE_LUT_SIZE-1) begin
							count <= '0;
							if(current_segment == MAX_NUM_SEGMENTS-1) begin //replace this with the last known seg needed to draw
								current_segment <= '0;
								state_r <= COUNT_APPLE;
							end
							else current_segment <= current_segment + 1;
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
	
	//position update logic
	logic [11:0] pos_x[MAX_NUM_SEGMENTS-1:0];
	logic [11:0] pos_y[MAX_NUM_SEGMENTS-1:0];
	logic signed [12:0] next_pos_x, next_pos_y;

	assign next_pos_x = signed'({1'b0, pos_x[0]}) + x_velocity;
	assign next_pos_y = signed'({1'b0, pos_y[0]}) + y_velocity;

    always_ff @(posedge clk) begin //moving triangle
        if(rst) begin
            pos_x <= '{default: 4095/2};
            pos_y <= '{default: 4095/2};
        end
        else if(state_r == COUNT_APPLE && count == APPLE_LUT_SIZE-1 && ready) begin
			pos_x[0] <= next_pos_x[11:0];
			pos_y[0] <= next_pos_y[11:0]; 

			//collision detection for x cases
			if (next_pos_x + TRIANGLE_X_BOX > 4095) begin
				pos_x[0] <= 4095/2;
				pos_y[0] <= 4095/2;
			end 
			else if (next_pos_x < 0) begin
				pos_x[0] <= 4095/2;
				pos_y[0] <= 4095/2;
			end

			//collision detection for y cases
			if (next_pos_y + TRIANGLE_Y_BOX > 4095) begin
				pos_x[0] <= 4095/2;
				pos_y[0] <= 4095/2;
			end 
			else if (next_pos_y < 0) begin
				pos_x[0] <= 4095/2;
				pos_y[0] <= 4095/2;
			end

			// IF next pos equals ANY of the current segments minus the final one, then detect as collision and reset the game
			for (int i = 1; i < current_length; i++) begin
				if ((next_pos_x[11:0] + TRIANGLE_X_BOX >= pos_x[i]) &&
				(next_pos_x[11:0] <= pos_x[i] + TRIANGLE_X_BOX) &&
				(next_pos_y[11:0] + TRIANGLE_Y_BOX >= pos_y[i]) &&
				(next_pos_y[11:0] <= pos_y[i] + TRIANGLE_Y_BOX)) begin
					//Reset position				
					pos_x[0] <= 4095/2;
					pos_y[0] <= 4095/2;
				end
			end

			for(int i=1; i<MAX_NUM_SEGMENTS; i++) begin
				pos_x[i] <= pos_x[i-1];
				pos_y[i] <= pos_y[i-1];
			end
        end



    end

	logic signed [12:0] x_velocity, y_velocity;
	always_ff @(posedge clk) begin
		if (rst) begin
			x_velocity <= '0;
			y_velocity <= '0;
		end
		else begin
			casez(btn[3:0])
				4'b??01: begin
					x_velocity <= VELOCITY;
					y_velocity <= '0;
				end
				4'b??10: begin
					x_velocity <= -1*VELOCITY;
					y_velocity <= '0;
				end
				4'b01??: begin
					x_velocity <='0;
					y_velocity <= VELOCITY;
				end
				4'b10??: begin
					x_velocity <='0;
					y_velocity <= -1*VELOCITY;
				end
				default: begin
					x_velocity <= x_velocity;
					y_velocity <= y_velocity;
				end 
			endcase
		end 	
	end
	
	logic [$clog2(APPLE_OFFSET_LUT_SIZE)-1:0] apple_count;
	always_ff @(posedge clk) begin //collision detection for apple
        if(rst) begin
			apple_count <= '0;
			current_length <= 3;
        end
        else begin
			if ((next_pos_x[11:0] + TRIANGLE_X_BOX >= outapplexoffset) && 
				(next_pos_x[11:0] <= outapplexoffset + APPLE_X_BOX) &&
				(next_pos_y[11:0] <= outappleyoffset + APPLE_Y_BOX) &&
				(next_pos_y[11:0] + TRIANGLE_Y_BOX >= outappleyoffset)) begin 
					apple_count <= apple_count + 1;
					current_length  <= current_length + 10;
			end
		end
	end

 	//mux outputs to chose which rom will be drawn
 	always_comb begin
        // Disable laser before the start of each draw
        if(count == '0) begin
            laser_en = '1;
        end
        else begin
            laser_en = '0;
        end 

 		case(state_r)
 			COUNT_BORDER: begin
 				data_in1 = outsquarex;
 				data_in2 = outsquarey;
 			end
 			COUNT_SEGMENTS: begin
 				data_in1 = outtrianglex + pos_x[current_segment % current_length];
 				data_in2 = outtriangley + pos_y[current_segment % current_length];
 			end
			COUNT_APPLE: begin
 				data_in1 = outapplex + outapplexoffset;
 				data_in2 = outappley + outappleyoffset;
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
