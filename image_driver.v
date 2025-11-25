`timescale 1ns / 1ps
module image_driver #(
    parameter IMAGE_WIDTH  = 110,
    parameter IMAGE_HEIGHT = 103
)(
    input wire clk,
    input wire reset,
    output wire [7:0] pixel_out,
    output reg        valid_out,
    output reg        start_processing
);

    parameter IMG_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;
    reg [13:0] read_addr; 
    reg active;

    // ROM Instance
    image_rom #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(14)
    ) img_rom_inst (
        .clk(clk),
        .addr(read_addr),
        .data(pixel_out)
    );

    always @(posedge clk) begin
        if (reset) begin
            read_addr <= 0;
            valid_out <= 0;
            active    <= 1; 
            start_processing <= 0;
        end else begin
            start_processing <= active; 
            
            if (active) begin
                valid_out <= 1;
                
                if (read_addr < IMG_SIZE - 1) begin
                    read_addr <= read_addr + 1;
                end else begin
                    active    <= 0;
                    // FIX: valid_out stays high for this final cycle
                end
            end else begin
                valid_out <= 0;
            end
        end
    end
endmodule
