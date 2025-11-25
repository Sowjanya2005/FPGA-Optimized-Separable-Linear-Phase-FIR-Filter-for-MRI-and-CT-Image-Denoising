`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.11.2025 10:29:23
// Design Name: 
// Module Name: vga_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 10:27:23
// Design Name: 
// Module Name: vga_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga_ctrl(
    input  wire clk25, rst,
    output wire hsync, vsync,
    output wire [9:0] x, y,
    output wire video_on
);
    // VGA timing
    localparam H_ACTIVE=640, H_FP=16, H_SYNC=96, H_BP=48, H_TOTAL=800;
    localparam V_ACTIVE=480, V_FP=10, V_SYNC=2, V_BP=33, V_TOTAL=525;

    reg [9:0] hcnt, vcnt;

    always @(posedge clk25 or posedge rst)
        if (rst) hcnt<=0;
        else if (hcnt==H_TOTAL-1) hcnt<=0;
        else hcnt<=hcnt+1;

    always @(posedge clk25 or posedge rst)
        if (rst) vcnt<=0;
        else if (hcnt==H_TOTAL-1)
            if (vcnt==V_TOTAL-1) vcnt<=0;
            else vcnt<=vcnt+1;

    assign hsync = ~((hcnt>=H_ACTIVE+H_FP) && (hcnt<H_ACTIVE+H_FP+H_SYNC));
    assign vsync = ~((vcnt>=V_ACTIVE+V_FP) && (vcnt<V_ACTIVE+V_FP+V_SYNC));

    assign video_on = (hcnt<H_ACTIVE)&&(vcnt<V_ACTIVE);
    assign x = hcnt; assign y = vcnt;
endmodule
