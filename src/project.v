/*
 * Copyright (c) 2025 Sreemathesh K
 * SPDX-License-Identifier: Apache-2.0
 *
 * wake_ctrl_v2 - Priority-Aware Event-Driven Wake Controller
 * Author: Sreemathesh K, 2nd Year ECE
 * SRM Institute of Science and Technology, Kattankulathur
 *
 * I built this as part of my undergrad project to solve
 * a real problem - batteryless IoT sensors need a tiny
 * always-on block that only wakes the processor when
 * something meaningful actually happens. This does that.
 */

`default_nettype none

// TinyTapeout top wrapper
// ui_in[3:0]  -> thresh_in  (4 sensor inputs)
// ui_in[7:4]  -> ch_en      (enable each channel)
// ui_in[4]    -> mode_and   (AND=1, OR=0)
// uo_out[0]   -> wake_out   (wake pulse)
// uo_out[4:1] -> evt_flags  (which channel fired)
// uo_out[6:5] -> priority_ch (highest priority channel)

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

    // bidirectional pins not used - set as inputs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire       wake_out;
    wire [3:0] evt_flags;
    wire [1:0] priority_ch;

    // connect TinyTapeout pins to my design
    wake_ctrl_v2 #(
        .N(4),
        .DB(8),
        .PW(4)
    ) my_wake_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .thresh_in   (ui_in[3:0]),
        .ch_en       (ui_in[7:4]),
        .mode_and    (ui_in[4]),
        .wake_out    (wake_out),
        .evt_flags   (evt_flags),
        .priority_ch (priority_ch)
    );

    assign uo_out[0]   = wake_out;
    assign uo_out[4:1] = evt_flags;
    assign uo_out[6:5] = priority_ch;
    assign uo_out[7]   = 1'b0;

endmodule


// my actual design - exactly as I wrote it
module wake_ctrl_v2 #(
    parameter N = 4,
    parameter DB = 8,
    parameter PW = 4
)(
    input clk,
    input rst_n,
    input [N-1:0] thresh_in,
    input [N-1:0] ch_en,
    input mode_and,
    output reg wake_out,
    output reg [N-1:0] evt_flags,
    output reg [1:0] priority_ch
);
    reg [N-1:0] sync1;
    reg [N-1:0] sync2;
    reg [DB-1:0] dbcnt [0:N-1];
    reg [N-1:0] stable;
    reg [PW-1:0] pcnt;
    reg firing;
    integer i;

    // 2FF synchronizer - stops metastability from async inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= 0;
            sync2 <= 0;
        end
        else begin
            sync1 <= thresh_in;
            sync2 <= sync1;
        end
    end

    // debounce - input must stay high for DB cycles
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable <= 0;
            for (i = 0; i < N; i = i + 1) begin
                dbcnt[i] <= 0;
            end
        end
        else begin
            for (i = 0; i < N; i = i + 1) begin
                if (!ch_en[i]) begin
                    dbcnt[i] <= 0;
                    stable[i] <= 0;
                end
                else if (sync2[i]) begin
                    if (&dbcnt[i])
                        stable[i] <= 1;
                    else
                        dbcnt[i] <= dbcnt[i] + 1;
                end
                else begin
                    dbcnt[i] <= 0;
                    stable[i] <= 0;
                end
            end
        end
    end

    // priority encoder - if multiple channels fire, report lowest index first
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_ch <= 0;
        end
        else begin
            if ((stable & ch_en) & 4'b0001)
                priority_ch <= 0;
            else if ((stable & ch_en) & 4'b0010)
                priority_ch <= 1;
            else if ((stable & ch_en) & 4'b0100)
                priority_ch <= 2;
            else
                priority_ch <= 3;
        end
    end

    // event detection - AND mode needs all channels, OR mode needs any one
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            firing <= 0;
            evt_flags <= 0;
        end
        else begin
            if (!firing) begin
                if (mode_and) begin
                    if (((stable & ch_en) == ch_en) && (ch_en != 0)) begin
                        firing <= 1;
                        evt_flags <= stable;
                    end
                end
                else begin
                    if ((stable & ch_en) != 0) begin
                        firing <= 1;
                        evt_flags <= stable & ch_en;
                    end
                end
            end
            if (&pcnt)
                firing <= 0;
        end
    end

    // pulse generator - makes a clean fixed-width output pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wake_out <= 0;
            pcnt <= 0;
        end
        else begin
            if (firing && !wake_out) begin
                wake_out <= 1;
                pcnt <= 0;
            end
            else if (wake_out) begin
                if (&pcnt)
                    wake_out <= 0;
                else
                    pcnt <= pcnt + 1;
            end
        end
    end

endmodule
