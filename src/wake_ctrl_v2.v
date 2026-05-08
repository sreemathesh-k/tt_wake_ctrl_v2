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

    // input sync
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

    // debounce
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

    // priority channel
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

    // event detect
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

    // wake pulse
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
