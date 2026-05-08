/*
 * Copyright (c) 2025 Sreemathesh K
 * SPDX-License-Identifier: Apache-2.0
 *
 * wake_ctrl_v2 - Priority-Aware Event-Driven Wake Controller
 * Author: Sreemathesh K, 2nd Year ECE
 * SRM Institute of Science and Technology, Kattankulathur
 *
 * A 4-channel always-on digital block for batteryless IoT sensors.
 * Watches threshold inputs, removes noise, detects events,
 * and generates a clean wake pulse for a sleeping processor.
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

    // unused
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire       wake_out;
    wire [3:0] evt_flags;
    wire [1:0] priority_ch;

    wake_ctrl_v2 my_wake_ctrl (
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


module wake_ctrl_v2 #(
    parameter N  = 4,
    parameter DB = 8,
    parameter PW = 4
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [N-1:0] thresh_in,
    input  wire [N-1:0] ch_en,
    input  wire         mode_and,
    output reg          wake_out,
    output reg  [N-1:0] evt_flags,
    output reg  [1:0]   priority_ch
);

    reg [N-1:0]  sync1;
    reg [N-1:0]  sync2;
    reg [DB-1:0] dbcnt_0, dbcnt_1, dbcnt_2, dbcnt_3;
    reg [N-1:0]  stable;
    reg [PW-1:0] pcnt;
    reg          firing;

    // 2FF synchronizer - stops metastability from async inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= 0;
            sync2 <= 0;
        end else begin
            sync1 <= thresh_in;
            sync2 <= sync1;
        end
    end

    // debounce channel 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbcnt_0  <= 0;
            stable[0]<= 0;
        end else if (!ch_en[0]) begin
            dbcnt_0  <= 0;
            stable[0]<= 0;
        end else if (sync2[0]) begin
            if (&dbcnt_0) stable[0] <= 1;
            else          dbcnt_0   <= dbcnt_0 + 1;
        end else begin
            dbcnt_0  <= 0;
            stable[0]<= 0;
        end
    end

    // debounce channel 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbcnt_1  <= 0;
            stable[1]<= 0;
        end else if (!ch_en[1]) begin
            dbcnt_1  <= 0;
            stable[1]<= 0;
        end else if (sync2[1]) begin
            if (&dbcnt_1) stable[1] <= 1;
            else          dbcnt_1   <= dbcnt_1 + 1;
        end else begin
            dbcnt_1  <= 0;
            stable[1]<= 0;
        end
    end

    // debounce channel 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbcnt_2  <= 0;
            stable[2]<= 0;
        end else if (!ch_en[2]) begin
            dbcnt_2  <= 0;
            stable[2]<= 0;
        end else if (sync2[2]) begin
            if (&dbcnt_2) stable[2] <= 1;
            else          dbcnt_2   <= dbcnt_2 + 1;
        end else begin
            dbcnt_2  <= 0;
            stable[2]<= 0;
        end
    end

    // debounce channel 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbcnt_3  <= 0;
            stable[3]<= 0;
        end else if (!ch_en[3]) begin
            dbcnt_3  <= 0;
            stable[3]<= 0;
        end else if (sync2[3]) begin
            if (&dbcnt_3) stable[3] <= 1;
            else          dbcnt_3   <= dbcnt_3 + 1;
        end else begin
            dbcnt_3  <= 0;
            stable[3]<= 0;
        end
    end

    // priority encoder - lowest index wins
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_ch <= 0;
        end else begin
            if      ((stable & ch_en) & 4'b0001) priority_ch <= 2'd0;
            else if ((stable & ch_en) & 4'b0010) priority_ch <= 2'd1;
            else if ((stable & ch_en) & 4'b0100) priority_ch <= 2'd2;
            else                                  priority_ch <= 2'd3;
        end
    end

    // event detection - AND or OR mode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            firing    <= 0;
            evt_flags <= 0;
        end else begin
            if (!firing) begin
                if (mode_and) begin
                    if (((stable & ch_en) == ch_en) && (ch_en != 0)) begin
                        firing    <= 1;
                        evt_flags <= stable;
                    end
                end else begin
                    if ((stable & ch_en) != 0) begin
                        firing    <= 1;
                        evt_flags <= stable & ch_en;
                    end
                end
            end
            if (&pcnt) firing <= 0;
        end
    end

    // pulse generator - fixed width clean output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wake_out <= 0;
            pcnt     <= 0;
        end else begin
            if (firing && !wake_out) begin
                wake_out <= 1;
                pcnt     <= 0;
            end else if (wake_out) begin
                if (&pcnt) wake_out <= 0;
                else       pcnt     <= pcnt + 1;
            end
        end
    end

endmodule
