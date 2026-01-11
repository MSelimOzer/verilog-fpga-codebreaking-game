module top_module(
    input clk,              // 27MHz board clock
    input [3:0] btn,        // btn[3]=A, btn[2]=RST, btn[0]=B
    input [3:0] sw,         // sw[2:0]=letterIn, sw[3]=single_player
    output [7:0] led,       // LED feedback
    output [7:0] seven,     // 7-segment data (pgfedcba + dot)
    output [3:0] segment    // 7-segment anodes (AN3-AN0)
);

// Internal wires
wire divided_clk;
wire rst;
wire enterA_debounced;
wire enterB_debounced;
wire [2:0] letterIn;
wire sp_mode;
wire rng_bit;
wire [7:0] LEDX;
wire [6:0] SSD3_data;
wire [6:0] SSD2_data;
wire [6:0] SSD1_data;
wire [6:0] SSD0_data;

// Map inputs
assign rst = btn[2];              // BTN2 is reset (active-low)
assign letterIn = sw[2:0];        // SW2, SW1, SW0 are letter inputs
assign sp_mode = sw[3]; // SW3 is single player mode

// Map LED output
assign led = LEDX;

// Clock divider: 27MHz -> 50Hz
clk_divider clk_div (
    .clk_in(clk),
    .divided_clk(divided_clk)
);

// Debouncer for Player A (BTN3)
debouncer debounce_A (
    .clk(divided_clk),
    .rst(~rst),
    .noisy_in(btn[3]),
    .clean_out(enterA_debounced)
);

// Debouncer for Player B (BTN0)
debouncer debounce_B (
    .clk(divided_clk),
    .rst(~rst),
    .noisy_in(btn[0]),
    .clean_out(enterB_debounced)
);

// RNG module for single player mode
rng_module rng (
    .clk(divided_clk),
    .rst(~rst),
    .rng_out(rng_bit)
);

// Mastermind game logic
mastermind game (
    .clk(divided_clk),
    .rst(rst),
    .enterA(enterA_debounced),
    .enterB(enterB_debounced),
    .letterIn(letterIn),
    .sp_mode(sp_mode),
    .rng_bit(rng_bit),
    .LEDX(LEDX),
    .SSD3(SSD3_data),
    .SSD2(SSD2_data),
    .SSD1(SSD1_data),
    .SSD0(SSD0_data)
);

// Seven segment display driver (uses original 27MHz clock)
ssd ssd_driver (
    .clk(clk),
    .disp0({1'b0, SSD0_data}),
    .disp1({1'b0, SSD1_data}),
    .disp2({1'b0, SSD2_data}),
    .disp3({1'b0, SSD3_data}),
    .seven(seven),
    .segment(segment)
);

endmodule