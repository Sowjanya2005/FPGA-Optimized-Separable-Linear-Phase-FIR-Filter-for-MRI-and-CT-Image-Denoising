`timescale 1ns / 1ps
module image_rom #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 14, 
    // PASTE YOUR FULL PATH HERE (Use forward slashes / )
    parameter IMG_FILENAME = "C:/Vivado_Projects/project_hdmi_interface.xpr/project_17/project_17.sim/sim_1/behav/xsim/inputHex_ct_1.txt" 
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

    (* rom_style = "block" *) 
    reg [DATA_WIDTH-1:0] rom_memory [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh(IMG_FILENAME, rom_memory);
    end

    always @(posedge clk) begin
        data <= rom_memory[addr];
    end

endmodule
