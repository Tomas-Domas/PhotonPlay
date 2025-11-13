`timescale 1ns / 1ps

module lut_driver #(
	localparam MAX_LUT_SIZE = 4096,
    localparam APPLE_OFFSET_LUT_SIZE = 1024,
	localparam BORDER_LUT_SIZE = 14,
	localparam SQUARE_LUT_SIZE = 5,
	localparam WIN_LUT_SIZE = 154,
	localparam START_LUT_SIZE = 169,
	localparam VELOCITY = 128,
	localparam MAX_NUM_SEGMENTS = 32,
	localparam TIME_TO_SEND = 16,
	localparam SQUARE_X_BOX = VELOCITY-1,
	localparam SQUARE_Y_BOX = VELOCITY-1,
	localparam DRAW_UPDATE_SPEED_DOWN = 175,
	localparam DRAW_SEGMENTS_UPDATE_SPEED_DOWN = 75,
	localparam POS_UPDATE_SPEED_DOWN = 2,
	localparam REDRAW_APPLE = 3
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
	logic [11:0] outborderx, outbordery, outsquarex, outsquarey, outwinx, outwiny, outstartx, outstarty, outapplexoffset, outappleyoffset;
	logic [$clog2(DRAW_UPDATE_SPEED_DOWN)-1:0] draw_update_speed_down_count; 
	logic [$clog2(REDRAW_APPLE)-1:0] redraw_apple_count; 
    logic [$clog2(MAX_LUT_SIZE)-1:0] count;
	logic [$clog2(MAX_NUM_SEGMENTS)-1:0] current_segment;
	logic [$clog2(MAX_NUM_SEGMENTS):0] current_length;
    logic go;

    typedef enum logic [2:0] {
		COUNT_START,
        COUNT_BORDER,
		COUNT_SEGMENTS,
		COUNT_APPLE,
		COUNT_WIN
    } state_t;
    state_t state_r;

	// function void update_draw_count();
	// 	draw_update_speed_down_count <= draw_update_speed_down_count + 1;
	// 	if(draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1) begin
	// 		draw_update_speed_down_count <= '0;
	// 		count <= count + 1;
	// 	end
	// endfunction

	//Draw loop
    always_ff @(posedge clk) begin
        if(rst) begin
            count <= '0;
			current_segment <= '0;
            state_r <= COUNT_START;
			draw_update_speed_down_count <= '0;
			redraw_apple_count <= '0;
        end
        else begin
            case(state_r)
				COUNT_START: begin
					if (ready) begin
						if(btn != 0) begin
							count <='0;
							state_r <= COUNT_BORDER;
						end else begin
							draw_update_speed_down_count <= draw_update_speed_down_count + 1;
							if(draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1) begin
								draw_update_speed_down_count <= '0;

								if(count == START_LUT_SIZE) begin
									state_r <= COUNT_START;
									count <= '0;
								end
								else begin
									count <= count + 1;
								end
							end
						end
					end
				end
                COUNT_BORDER: begin
					if (ready) begin
						draw_update_speed_down_count <= draw_update_speed_down_count + 1;
						if(draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1) begin
							draw_update_speed_down_count <= '0;

							if(count == BORDER_LUT_SIZE-1) begin
								count <= '0;
								state_r <= COUNT_SEGMENTS;
							end
							else begin
								count <= count + 1;
							end
						end
                    end
                end
				COUNT_SEGMENTS: begin
					if (ready) begin
						draw_update_speed_down_count <= draw_update_speed_down_count + 1;
						if(draw_update_speed_down_count == DRAW_SEGMENTS_UPDATE_SPEED_DOWN-1) begin
							draw_update_speed_down_count <= '0;

							if(count == SQUARE_LUT_SIZE-1) begin
								count <= '0;
								if(current_segment == MAX_NUM_SEGMENTS-1) begin
									current_segment <= '0;
									state_r <= COUNT_APPLE;
								end
								else current_segment <= current_segment + 1;
							end
							else begin
								count <= count + 1;
							end
						end
                    end
				end
				COUNT_APPLE: begin
					if (ready) begin
						draw_update_speed_down_count <= draw_update_speed_down_count + 1;
						if(draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1) begin
							draw_update_speed_down_count <= '0;

							if(count == SQUARE_LUT_SIZE-1) begin
								count <= '0;
								if(redraw_apple_count == REDRAW_APPLE-1) begin
									redraw_apple_count <= '0;
									if(current_length >= MAX_NUM_SEGMENTS) state_r <= COUNT_WIN;
									else state_r <= COUNT_BORDER;
								end
								else redraw_apple_count <= redraw_apple_count + 1;
							end
							else begin
								count <= count + 1;
							end
						end
                    end
				end
				COUNT_WIN: begin
					if (ready) begin
						if(btn != 0) begin
							count <= '0;
							state_r <= COUNT_BORDER;
						end else begin
							draw_update_speed_down_count <= draw_update_speed_down_count + 1;
							if(draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1) begin
								draw_update_speed_down_count <= '0;

								if(count == WIN_LUT_SIZE) begin
									count <= '0;
									state_r <= COUNT_WIN;
								end
								else begin
									count <= count + 1;
								end
							end
						end
					end
				end
            endcase
        end
    end
	
	//position update logic
	logic [11:0] pos_x[MAX_NUM_SEGMENTS-1:0];
	logic [11:0] pos_y[MAX_NUM_SEGMENTS-1:0];
	logic [$clog2(POS_UPDATE_SPEED_DOWN)-1:0] pos_update_speed_down_count;
	logic signed [12:0] next_pos_x, next_pos_y;
	logic signed [12:0] x_velocity, y_velocity;
	logic [$clog2(APPLE_OFFSET_LUT_SIZE)-1:0] apple_count;

	assign next_pos_x = signed'({1'b0, pos_x[0]}) + x_velocity;
	assign next_pos_y = signed'({1'b0, pos_y[0]}) + y_velocity;

	function void reset_pos_vel();
		current_length <= 1;
		pos_x <= '{default: 4096/2};
		pos_y <= '{default: 4096/2};
		x_velocity <= '0;
		y_velocity <= '0;
	endfunction

    always_ff @(posedge clk) begin 
		logic [3:0] sampled_btn = btn;

        if(rst) begin
			pos_update_speed_down_count <= '0;
			apple_count <= '0;
			reset_pos_vel();
        end
        else if(state_r == COUNT_APPLE && count == SQUARE_LUT_SIZE-1 && ready && draw_update_speed_down_count == DRAW_UPDATE_SPEED_DOWN-1 && redraw_apple_count == REDRAW_APPLE-1) begin
			pos_update_speed_down_count <= pos_update_speed_down_count + 1;

			if(pos_update_speed_down_count == POS_UPDATE_SPEED_DOWN-1) begin
				pos_update_speed_down_count <= '0;
				pos_x[0] <= next_pos_x[11:0];
				pos_y[0] <= next_pos_y[11:0]; 

				for(int i=1; i<MAX_NUM_SEGMENTS; i++) begin
					pos_x[i] <= pos_x[i-1];
					pos_y[i] <= pos_y[i-1];
				end

				casez(sampled_btn[3:0])
					4'b??01: begin
						if(x_velocity == 0) begin
							x_velocity <= VELOCITY;
							y_velocity <= '0;
						end
					end
					4'b??10: begin
						if(x_velocity == 0) begin
							x_velocity <= -1*VELOCITY;
							y_velocity <= '0;
						end
					end
					4'b01??: begin
						if(y_velocity == 0) begin
							x_velocity <='0;
							y_velocity <= VELOCITY;
						end
					end
					4'b10??: begin
						if(y_velocity == 0) begin
							x_velocity <='0;
							y_velocity <= -1*VELOCITY;
						end
					end
					default: begin
						x_velocity <= x_velocity;
						y_velocity <= y_velocity;
					end 
				endcase

				if ((next_pos_x + SQUARE_X_BOX > 4095) || //x right
					(next_pos_x < 0) || 				  //x left
					(next_pos_y + SQUARE_Y_BOX > 4095) || //y top
					(next_pos_y < 0)) begin			      //y bottom
					reset_pos_vel();
				end 

				// IF next pos equals ANY of the current segments minus the final one, then detect as collision and reset the game
				for (int i = 1; i < current_length; i++) begin
					if ((next_pos_x[11:0] + SQUARE_X_BOX >= pos_x[i]) &&
					(next_pos_x[11:0] <= pos_x[i] + SQUARE_X_BOX) &&
					(next_pos_y[11:0] + SQUARE_Y_BOX >= pos_y[i]) &&
					(next_pos_y[11:0] <= pos_y[i] + SQUARE_Y_BOX)) begin
						reset_pos_vel();
					end
				end

				if ((next_pos_x[11:0] + SQUARE_X_BOX >= outapplexoffset) && 
					(next_pos_x[11:0] <= outapplexoffset + SQUARE_X_BOX) &&
					(next_pos_y[11:0] <= outappleyoffset + SQUARE_Y_BOX) &&
					(next_pos_y[11:0] + SQUARE_Y_BOX >= outappleyoffset)) begin 
					apple_count <= apple_count + 1;
					current_length  <= current_length + 3;
				end
			end
        end
    end

 	//mux outputs to chose which rom will be drawn
 	always_comb begin
        // Disable laser before the start of each draw
        if(count == '0) begin
            laser_en = '0;
        end
        else begin
            laser_en = '1;
        end 

 		case(state_r)
			COUNT_START: begin
 				data_in1 = outstartx;
 				data_in2 = outstarty;
 			end
 			COUNT_BORDER: begin
 				data_in1 = outborderx;
 				data_in2 = outbordery;
 			end
 			COUNT_SEGMENTS: begin
 				data_in1 = outsquarex + pos_x[current_segment % current_length];
 				data_in2 = outsquarey + pos_y[current_segment % current_length];
 			end
			COUNT_APPLE: begin
 				data_in1 = outsquarex + outapplexoffset;
 				data_in2 = outsquarey + outappleyoffset;
 			end
			COUNT_WIN: begin
				data_in1 = outwinx;
				data_in2 = outwiny;
			end
 		endcase

		data_in1 = 4095 - data_in1;
		data_in2 = 4095 - data_in2;
 	end
    assign go = ready;

    borderx_rom borderx 
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outborderx));

    bordery_rom bordery
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outbordery));
				
	x_square #(.SQUARE_SIZE(VELOCITY)) squarex 
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outsquarex));
			
	y_square #(.SQUARE_SIZE(VELOCITY)) squarey 
		(.clk(clk), 
		.we(1'b0), 
		.addr(count), 
		.dout(outsquarey));

	x_win winx
		(.clk(clk),
		.we(1'b0),
		.addr(count),
		.dout(outwinx));
	
	y_win winy
		(.clk(clk),
		.we(1'b0),
		.addr(count),
		.dout(outwiny));

	x_start startx
		(.clk(clk),
		.we(1'b0),
		.addr(count),
		.dout(outstartx));

	y_start starty
		(.clk(clk),
		.we(1'b0),
		.addr(count),
		.dout(outstarty));

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
