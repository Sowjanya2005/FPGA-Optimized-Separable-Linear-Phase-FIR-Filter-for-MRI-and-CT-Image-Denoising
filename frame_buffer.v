`timescale 1ns / 1ps
module frame_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 14
)(
    input wire wr_clk,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,
    
    input wire rd_clk,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always @(posedge wr_clk) if (wr_en) ram[wr_addr] <= wr_data;
    always @(posedge rd_clk) rd_data <= ram[rd_addr];
endmodule
