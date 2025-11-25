`timescale 1ns / 1ps
module transpose_buffer #(
    parameter DATA_WIDTH   = 8,
    parameter IMAGE_WIDTH  = 110,
    parameter IMAGE_HEIGHT = 103
) (
    input wire clk,
    input wire reset,
    input wire write_en,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire read_en,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out 
);
    localparam MEM_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT;
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:MEM_SIZE-1];
    
    reg [13:0] wr_addr;
    always @(posedge clk) begin
        if (reset) wr_addr <= 0;
        else if (write_en) begin
            mem[wr_addr] <= data_in;
            wr_addr <= wr_addr + 1;
        end
    end

    reg [7:0] col_count;
    reg [7:0] row_count;
    wire [13:0] rd_addr = col_count * IMAGE_HEIGHT + row_count;

    always @(posedge clk) begin
        if (reset) begin
            col_count <= 0; row_count <= 0; data_out <= 0; valid_out <= 0;
        end else begin
            valid_out <= read_en;
            if (read_en) begin
                data_out <= mem[rd_addr];
                if (row_count == IMAGE_HEIGHT - 1) begin
                    row_count <= 0;
                    col_count <= col_count + 1;
                end else begin
                    row_count <= row_count + 1;
                end
            end
        end
    end
endmodule
