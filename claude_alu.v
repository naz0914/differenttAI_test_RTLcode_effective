`timescale 1ns / 1ps

// 4 級管線化 ALU，目標 100MHz (Xilinx 7-Series / UltraScale)
// Latency = 4 cycles，Throughput = 1 result/cycle
module optimized_alu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [7:0]  c,
    input  wire [7:0]  d,
    input  wire [3:0]  sel,
    output reg  [15:0] result
);

    // ------------------------------------------------------------
    // Stage 1：輸入暫存 + 共用加法 (a+b+c+d 只算一次)
    // ------------------------------------------------------------
    reg [7:0] a_s1, b_s1, c_s1, d_s1;
    reg [3:0] sel_s1;
    reg [9:0] sum_s1;                      // 最大 4*255 = 1020，10 bit

    always @(posedge clk) begin
        if (!rst_n) begin
            a_s1 <= 8'd0; b_s1 <= 8'd0; c_s1 <= 8'd0; d_s1 <= 8'd0;
            sel_s1 <= 4'd0;
            sum_s1 <= 10'd0;
        end else begin
            a_s1 <= a; b_s1 <= b; c_s1 <= c; d_s1 <= d;
            sel_s1 <= sel;
            sum_s1 <= a + b + c + d;
        end
    end

    // ------------------------------------------------------------
    // Stage 2：平行 case 選擇「乘法器運算元」與加/減控制
    //   乘法器 1：m1_x * m1_y
    //   乘法器 2：m2_x * m2_y
    //   最終：result = P1 (+/-) P2
    // ------------------------------------------------------------
    reg [9:0] m1_x;
    reg [7:0] m1_y;
    reg [7:0] m2_x, m2_y;
    reg       do_sub;

    always @(posedge clk) begin
        if (!rst_n) begin
            m1_x <= 10'd0; m1_y <= 8'd0;
            m2_x <= 8'd0;  m2_y <= 8'd0;
            do_sub <= 1'b0;
        end else begin
            case (sel_s1)
                4'b0000: begin  // a*b + c*d
                    m1_x <= {2'b00, a_s1}; m1_y <= b_s1;
                    m2_x <= c_s1;          m2_y <= d_s1;
                    do_sub <= 1'b0;
                end
                4'b0001: begin  // a*b - c*d
                    m1_x <= {2'b00, a_s1}; m1_y <= b_s1;
                    m2_x <= c_s1;          m2_y <= d_s1;
                    do_sub <= 1'b1;
                end
                4'b0010: begin  // a*c + b*d
                    m1_x <= {2'b00, a_s1}; m1_y <= c_s1;
                    m2_x <= b_s1;          m2_y <= d_s1;
                    do_sub <= 1'b0;
                end
                4'b0011: begin  // a*c - b*d
                    m1_x <= {2'b00, a_s1}; m1_y <= c_s1;
                    m2_x <= b_s1;          m2_y <= d_s1;
                    do_sub <= 1'b1;
                end
                4'b0100: begin  // a*d + b*c
                    m1_x <= {2'b00, a_s1}; m1_y <= d_s1;
                    m2_x <= b_s1;          m2_y <= c_s1;
                    do_sub <= 1'b0;
                end
                4'b0101: begin  // (a+b+c+d)*a
                    m1_x <= sum_s1;        m1_y <= a_s1;
                    m2_x <= 8'd0;          m2_y <= 8'd0;
                    do_sub <= 1'b0;
                end
                4'b0110: begin  // (a+b+c+d)*b
                    m1_x <= sum_s1;        m1_y <= b_s1;
                    m2_x <= 8'd0;          m2_y <= 8'd0;
                    do_sub <= 1'b0;
                end
                default: begin  // 其餘 sel → 0
                    m1_x <= 10'd0;         m1_y <= 8'd0;
                    m2_x <= 8'd0;          m2_y <= 8'd0;
                    do_sub <= 1'b0;
                end
            endcase
        end
    end

    // ------------------------------------------------------------
    // Stage 3：乘法 (推論為 2 個 DSP48，輸入/輸出皆有暫存器)
    //   只保留低 16 bit，與原始設計 16-bit 截斷行為一致
    // ------------------------------------------------------------
    reg [15:0] p1, p2;
    reg        do_sub_s3;

    wire [17:0] p1_full = m1_x * m1_y;     // 10b x 8b
    wire [15:0] p2_full = m2_x * m2_y;     //  8b x 8b

    always @(posedge clk) begin
        if (!rst_n) begin
            p1 <= 16'd0;
            p2 <= 16'd0;
            do_sub_s3 <= 1'b0;
        end else begin
            p1 <= p1_full[15:0];
            p2 <= p2_full;
            do_sub_s3 <= do_sub;
        end
    end

    // ------------------------------------------------------------
    // Stage 4：共用加/減法器 → 輸出暫存器
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            result <= 16'd0;
        else
            result <= do_sub_s3 ? (p1 - p2) : (p1 + p2);
    end

endmodule