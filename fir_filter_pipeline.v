`timescale 1ns / 1ps
module fir_filter_pipeline #(
    parameter DATA_WIDTH   = 8,
    parameter IMAGE_WIDTH  = 110,
    parameter IMAGE_HEIGHT = 103
)(
    input      clk,
    input      reset,
    input      start,
    input      [DATA_WIDTH-1:0] pixel_in,
    input      valid_in,
    output     [DATA_WIDTH-1:0] pixel_out,
    output     valid_out,
    output reg done
);
    localparam IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam S_IDLE=2'b00, S_HORIZ=2'b01, S_VERT=2'b10, S_DONE=2'b11;
    
    reg [1:0] state, next_state;
    reg [$clog2(IMAGE_SIZE):0] h_pixel_counter, v_pixel_counter;

    wire [DATA_WIDTH-1:0] horiz_data, vert_data, transpose_data;
    wire horiz_valid, vert_valid, transpose_valid; 

    optimized_fir_core #(.DATA_WIDTH(DATA_WIDTH)) horiz_fir (
        .clk(clk), .reset(reset), .pixel_in(pixel_in), .valid_in(valid_in), 
        .pixel_out(horiz_data), .valid_out(horiz_valid));

    transpose_buffer #(.DATA_WIDTH(DATA_WIDTH), .IMAGE_WIDTH(IMAGE_WIDTH), .IMAGE_HEIGHT(IMAGE_HEIGHT)) t_buff (
        .clk(clk), .reset(reset), .write_en(horiz_valid), .data_in(horiz_data), 
        .read_en(state == S_VERT), .data_out(transpose_data), .valid_out(transpose_valid));

    optimized_fir_core #(.DATA_WIDTH(DATA_WIDTH)) vert_fir (
        .clk(clk), .reset(reset), .pixel_in(transpose_data), .valid_in(transpose_valid), 
        .pixel_out(vert_data), .valid_out(vert_valid));

    assign pixel_out = vert_data;
    assign valid_out = vert_valid;

    always @(posedge clk) begin
        if (reset) begin 
            state <= S_IDLE; 
            h_pixel_counter <= 0; 
            v_pixel_counter <= 0; 
        end else begin 
            state <= next_state;
            if (horiz_valid) h_pixel_counter <= h_pixel_counter + 1;
            if (vert_valid)  v_pixel_counter <= v_pixel_counter + 1;
        end
    end

    always @(*) begin
        next_state = state;
        done = 0;
        case(state)
            S_IDLE:  if(start) next_state = S_HORIZ;
            S_HORIZ: if(h_pixel_counter == IMAGE_SIZE) next_state = S_VERT;
            // FIX: Wait for full count
            S_VERT:  if(v_pixel_counter == IMAGE_SIZE) next_state = S_DONE;
            S_DONE:  done = 1; 
        endcase
    end
endmodule
