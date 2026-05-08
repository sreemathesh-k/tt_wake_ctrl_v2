/*
 * Copyright (c) 2025 Sreemathesh K
 * SPDX-License-Identifier: Apache-2.0
 *
 * wake_ctrl_v2 - Priority-Aware Event-Driven Wake Controller
 * Author: Sreemathesh K, 2nd Year ECE
 * SRM Institute of Science and Technology, Kattankulathur
 */
`default_nettype none
module tt_um_sreemathesh_wake_ctrl (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire       wake_out;
    wire [3:0] evt_flags;
    wire [1:0] priority_ch;

    wake_ctrl_v2 my_wake_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .thresh_in  (ui_in[3:0]),
        .ch_en      (ui_in[7:4]),
        .mode_and   (uio_in[0]),
        .wake_out   (wake_out),
        .evt_flags  (evt_flags),
        .priority_ch(priority_ch)
    );

    assign uo_out[0]   = wake_out;
    assign uo_out[4:1] = evt_flags;
    assign uo_out[6:5] = priority_ch;
    assign uo_out[7]   = 1'b0;

endmodule
