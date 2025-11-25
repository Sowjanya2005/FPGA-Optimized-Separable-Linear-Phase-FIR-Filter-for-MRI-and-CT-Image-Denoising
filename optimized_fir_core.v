`timescale 1ns / 1ps
module optimized_fir_core #(
    parameter DATA_WIDTH = 8
) (
    input wire clk,
    input wire reset,
    input wire [DATA_WIDTH-1:0] pixel_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] pixel_out,
    output reg valid_out
);
    localparam C0 = 1;
    localparam C1 = 4;
    localparam C2 = 6;
    
    reg [DATA_WIDTH-1:0] x1, x2, x3, x4;
    
    always @(posedge clk) begin
        if (reset) {x1, x2, x3, x4} <= 0;
        else if (valid_in) {x1, x2, x3, x4} <= {pixel_in, x1, x2, x3};
    end

    reg [DATA_WIDTH+3:0] sum_outer, sum_inner, term_center;
    
    always @(posedge clk) begin
        if (reset) begin
            sum_outer <= 0; sum_inner <= 0; term_center <= 0;
        end else begin
            sum_outer <= (pixel_in + x4) * C0;
            sum_inner <= (x1 + x3) * C1;
            term_center <= x2 * C2;
        end
    end

    reg [DATA_WIDTH+5:0] total_sum;
    always @(posedge clk) begin
        if (reset) total_sum <= 0;
        else total_sum <= sum_outer + sum_inner + term_center;
    end

    always @(posedge clk) begin
        if (reset) pixel_out <= 0;
        else pixel_out <= total_sum[DATA_WIDTH+3:4]; // Divide by 16
    end

    reg [2:0] val_pipe;
    always @(posedge clk) begin
        if (reset) {val_pipe, valid_out} <= 0;
        else {valid_out, val_pipe} <= {val_pipe, valid_in};
    end
endmodule
