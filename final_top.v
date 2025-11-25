`timescale 1ns / 1ps

module final_top(
    input  wire sys_clk_in,
    input  wire sys_rst_in,
    output wire hdmi_clk_n,
    output wire hdmi_clk_p,
    output wire [2:0] hdmi_tx_n,
    output wire [2:0] hdmi_tx_p
);

    // 1. CLOCKS
    wire clk_25mhz, clk_125mhz, locked;
    wire rst = sys_rst_in || !locked;

    clk_wiz_1 clk_gen (
        .clk_out1(clk_25mhz),  .clk_out2(clk_125mhz),
        .reset(sys_rst_in),    .locked(locked),
        .clk_in1(sys_clk_in)
    );

    // 2. PIPELINE SIGNALS
    wire [7:0] rom_data;
    wire rom_valid, start_pipe;
    wire [7:0] filt_data;
    wire filt_valid, filt_done;

    // 3. DRIVER
    image_driver drv (
        .clk(sys_clk_in), .reset(rst),
        .pixel_out(rom_data), .valid_out(rom_valid), .start_processing(start_pipe)
    );

    // 4. PIPELINE
    fir_filter_pipeline pipe (
        .clk(sys_clk_in), .reset(rst), .start(start_pipe),
        .pixel_in(rom_data), .valid_in(rom_valid),
        .pixel_out(filt_data), .valid_out(filt_valid), .done(filt_done)
    );

    // =========================================================================
    // 5. BUFFER WRITE LOGIC (PROCESSED IMAGE)
    // =========================================================================
    
    reg [13:0] wr_addr;
    reg [6:0]  w_x_cnt; 
    reg [6:0]  w_y_cnt; 

    localparam DATA_WIDTH   = 103;
    localparam BUFFER_WIDTH = 110;
    localparam TOTAL_LINES  = 110;

    always @(posedge sys_clk_in) begin
        if (rst) begin
            w_x_cnt <= 0;
            w_y_cnt <= 0;
            wr_addr <= 0;
        end else if (filt_valid) begin
            wr_addr <= (w_y_cnt * BUFFER_WIDTH) + w_x_cnt;

            if (w_x_cnt == DATA_WIDTH - 1) begin
                w_x_cnt <= 0;
                if (w_y_cnt == TOTAL_LINES - 1) w_y_cnt <= 0;
                else w_y_cnt <= w_y_cnt + 1;
            end else begin
                w_x_cnt <= w_x_cnt + 1;
            end
        end
    end

    // 6. FRAME BUFFER (Right Image)
    wire [7:0] proc_pixel;
    wire [13:0] rd_addr;   
    
    frame_buffer buff (
        .wr_clk(sys_clk_in), .wr_en(filt_valid), .wr_addr(wr_addr), .wr_data(filt_data),
        .rd_clk(clk_25mhz),  .rd_addr(rd_addr),  .rd_data(proc_pixel)
    );

    // =========================================================================
    // 6b. DISPLAY ROM (Left Image)
    // =========================================================================
    
    wire [13:0] orig_addr;
    wire [7:0] orig_pixel; 
    
    image_rom #(
        .DATA_WIDTH(8), 
        .ADDR_WIDTH(14)
    ) display_rom (
        .clk(clk_25mhz),
        .addr(orig_addr),
        .data(orig_pixel)
    );

    // 7. VGA CONTROL
    wire [9:0] x, y;
    wire video_on, hsync, vsync;
    
    vga_ctrl vga (
        .clk25(clk_25mhz), .rst(rst),
        .hsync(hsync), .vsync(vsync), .video_on(video_on), .x(x), .y(y)
    );

    // =========================================================================
    // 8. TEXT OVERLAY LOGIC
    // =========================================================================
    wire text_active;
    
    simple_text_overlay text_mod (
        .x(x), .y(y),
        .pixel_on(text_active)
    );

    // =========================================================================
    // 9. DUAL DISPLAY LOGIC
    // =========================================================================
    
    localparam Y_START = 188;
    localparam W = 110;
    localparam H = 103;
    localparam REAL_IMG_W = 103; 
    
    localparam X_LEFT  = 160;
    localparam X_RIGHT = 370;

    // --- LEFT SIDE (ORIGINAL) ---
    wire in_left = (x >= X_LEFT) && (x < X_LEFT + W) && 
                   (y >= Y_START) && (y < Y_START + H);
                   
    wire [13:0] left_rel_x = x - X_LEFT;
    wire [13:0] left_rel_y = y - Y_START;
    
    assign orig_addr = (in_left && left_rel_x < REAL_IMG_W) ? 
                       (left_rel_y * REAL_IMG_W + left_rel_x) : 14'd0;

    // --- RIGHT SIDE (PROCESSED) ---
    wire in_right = (x >= X_RIGHT) && (x < X_RIGHT + W) && 
                    (y >= Y_START) && (y < Y_START + H);

    wire [13:0] right_rel_x = x - X_RIGHT;
    wire [13:0] right_rel_y = y - Y_START;

    assign rd_addr = (in_right && right_rel_x < REAL_IMG_W) ? 
                     (right_rel_y * 110 + right_rel_x) : 14'd0;

    // -------------------------------------------------------------------------
    // PIXEL SELECTOR
    // -------------------------------------------------------------------------
    reg [7:0] final_color;
    
    always @(*) begin
        if (!video_on) begin
            final_color = 8'h00;
        end else if (text_active) begin
            final_color = 8'hFF; // White Text
        end else if (in_left) begin
            if (left_rel_x < REAL_IMG_W) final_color = orig_pixel;
            else final_color = 8'h00; 
        end else if (in_right) begin
            if (right_rel_x < REAL_IMG_W) final_color = proc_pixel;
            else final_color = 8'h00;
        end else begin
            final_color = 8'h00;
        end
    end

    // 10. HDMI OUTPUT
    hdmi_tx_0 hdmi (
        .pix_clk(clk_25mhz), .pix_clkx5(clk_125mhz), .pix_clk_locked(locked),
        .rst(rst), .red(final_color), .green(final_color), .blue(final_color),
        .hsync(hsync), .vsync(vsync), .vde(video_on),
        .aux0_din(0), .aux1_din(0), .aux2_din(0), .ade(0),
        .TMDS_CLK_P(hdmi_clk_p), .TMDS_CLK_N(hdmi_clk_n),
        .TMDS_DATA_P(hdmi_tx_p), .TMDS_DATA_N(hdmi_tx_n)
    );
endmodule

// =============================================================================
// SUB-MODULE: TEXT OVERLAY (Hardcoded Strings)
// =============================================================================
module simple_text_overlay (
    input wire [9:0] x,
    input wire [9:0] y,
    output reg pixel_on
);
    // Text Coordinates
    // Left: "ORIGINAL IMAGE" at X=160, Y=170
    // Right: "DENOISED IMAGE" at X=370, Y=170
    
    localparam TEXT_Y_START = 170;
    localparam TEXT_Y_END   = 178; // 8 pixels high
    
    wire in_text_row = (y >= TEXT_Y_START) && (y < TEXT_Y_END);
    
    // Character Logic
    reg [7:0] char_code;
    wire [2:0] font_row = y - TEXT_Y_START;
    reg [2:0] font_col;
    reg [7:0] font_byte;
    
    always @(*) begin
        char_code = 0; // Default empty
        font_col = 0;
        
        if (in_text_row) begin
            // Check Left String: "ORIGINAL IMAGE" (14 chars)
            if (x >= 160 && x < 160 + (14*8)) begin
                char_code = get_left_char((x - 160) >> 3);
                font_col = (x - 160) & 7;
            end
            // Check Right String: "DENOISED IMAGE" (14 chars)
            else if (x >= 370 && x < 370 + (14*8)) begin
                char_code = get_right_char((x - 370) >> 3);
                font_col = (x - 370) & 7;
            end
        end
    end

    // Font Bitmap Lookup
    always @(*) begin
        case (char_code)
            "A": font_byte = get_font_A(font_row);
            "D": font_byte = get_font_D(font_row);
            "E": font_byte = get_font_E(font_row);
            "G": font_byte = get_font_G(font_row);
            "I": font_byte = get_font_I(font_row);
            "L": font_byte = get_font_L(font_row);
            "M": font_byte = get_font_M(font_row);
            "N": font_byte = get_font_N(font_row);
            "O": font_byte = get_font_O(font_row);
            "R": font_byte = get_font_R(font_row);
            "S": font_byte = get_font_S(font_row);
            default: font_byte = 0;
        endcase
        
        // Check bit (MSB first usually, but lets use simple indexing)
        pixel_on = font_byte[7 - font_col];
    end

    function [7:0] get_left_char;
        input [3:0] idx;
        begin
            case(idx)
                0: get_left_char = "O";
                1: get_left_char = "R";
                2: get_left_char = "I";
                3: get_left_char = "G";
                4: get_left_char = "I";
                5: get_left_char = "N";
                6: get_left_char = "A";
                7: get_left_char = "L";
                8: get_left_char = " ";
                9: get_left_char = "I";
                10:get_left_char = "M";
                11:get_left_char = "A";
                12:get_left_char = "G";
                13:get_left_char = "E";
                default: get_left_char = 0;
            endcase
        end
    endfunction

    function [7:0] get_right_char;
        input [3:0] idx;
        begin
            case(idx)
                0: get_right_char = "D";
                1: get_right_char = "E";
                2: get_right_char = "N";
                3: get_right_char = "O";
                4: get_right_char = "I";
                5: get_right_char = "S";
                6: get_right_char = "E";
                7: get_right_char = "D";
                8: get_right_char = " ";
                9: get_right_char = "I";
                10:get_right_char = "M";
                11:get_right_char = "A";
                12:get_right_char = "G";
                13:get_right_char = "E";
                default: get_right_char = 0;
            endcase
        end
    endfunction

    // --- FONT BITMAPS (8x8) ---
    function [7:0] get_font_A; input [2:0] r;
        case(r) 0:get_font_A=8'h18; 1:get_font_A=8'h3C; 2:get_font_A=8'h66; 3:get_font_A=8'h66; 
                4:get_font_A=8'h7E; 5:get_font_A=8'h66; 6:get_font_A=8'h66; 7:get_font_A=8'h00; endcase
    endfunction
    function [7:0] get_font_D; input [2:0] r;
        case(r) 0:get_font_D=8'h78; 1:get_font_D=8'h3C; 2:get_font_D=8'h66; 3:get_font_D=8'h66; 
                4:get_font_D=8'h66; 5:get_font_D=8'h3C; 6:get_font_D=8'h78; 7:get_font_D=8'h00; endcase
    endfunction
    function [7:0] get_font_E; input [2:0] r;
        case(r) 0:get_font_E=8'h7E; 1:get_font_E=8'h60; 2:get_font_E=8'h60; 3:get_font_E=8'h78; 
                4:get_font_E=8'h60; 5:get_font_E=8'h60; 6:get_font_E=8'h7E; 7:get_font_E=8'h00; endcase
    endfunction
    function [7:0] get_font_G; input [2:0] r;
        case(r) 0:get_font_G=8'h3C; 1:get_font_G=8'h66; 2:get_font_G=8'h60; 3:get_font_G=8'h6E; 
                4:get_font_G=8'h66; 5:get_font_G=8'h66; 6:get_font_G=8'h3C; 7:get_font_G=8'h00; endcase
    endfunction
    function [7:0] get_font_I; input [2:0] r;
        case(r) 0:get_font_I=8'h3C; 1:get_font_I=8'h18; 2:get_font_I=8'h18; 3:get_font_I=8'h18; 
                4:get_font_I=8'h18; 5:get_font_I=8'h18; 6:get_font_I=8'h3C; 7:get_font_I=8'h00; endcase
    endfunction
    function [7:0] get_font_L; input [2:0] r;
        case(r) 0:get_font_L=8'h60; 1:get_font_L=8'h60; 2:get_font_L=8'h60; 3:get_font_L=8'h60; 
                4:get_font_L=8'h60; 5:get_font_L=8'h60; 6:get_font_L=8'h7E; 7:get_font_L=8'h00; endcase
    endfunction
    function [7:0] get_font_M; input [2:0] r;
        case(r) 0:get_font_M=8'h66; 1:get_font_M=8'h7E; 2:get_font_M=8'h5A; 3:get_font_M=8'h42; 
                4:get_font_M=8'h42; 5:get_font_M=8'h42; 6:get_font_M=8'h42; 7:get_font_M=8'h00; endcase
    endfunction
    function [7:0] get_font_N; input [2:0] r;
        case(r) 0:get_font_N=8'h66; 1:get_font_N=8'h66; 2:get_font_N=8'h76; 3:get_font_N=8'h7E; 
                4:get_font_N=8'h6E; 5:get_font_N=8'h66; 6:get_font_N=8'h66; 7:get_font_N=8'h00; endcase
    endfunction
    function [7:0] get_font_O; input [2:0] r;
        case(r) 0:get_font_O=8'h3C; 1:get_font_O=8'h66; 2:get_font_O=8'h66; 3:get_font_O=8'h66; 
                4:get_font_O=8'h66; 5:get_font_O=8'h66; 6:get_font_O=8'h3C; 7:get_font_O=8'h00; endcase
    endfunction
    function [7:0] get_font_R; input [2:0] r;
        case(r) 0:get_font_R=8'h7C; 1:get_font_R=8'h66; 2:get_font_R=8'h66; 3:get_font_R=8'h7C; 
                4:get_font_R=8'h78; 5:get_font_R=8'h6C; 6:get_font_R=8'h66; 7:get_font_R=8'h00; endcase
    endfunction
    function [7:0] get_font_S; input [2:0] r;
        case(r) 0:get_font_S=8'h3C; 1:get_font_S=8'h66; 2:get_font_S=8'h60; 3:get_font_S=8'h3C; 
                4:get_font_S=8'h06; 5:get_font_S=8'h66; 6:get_font_S=8'h3C; 7:get_font_S=8'h00; endcase
    endfunction

endmodule
