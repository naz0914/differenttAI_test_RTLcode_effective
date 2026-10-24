`timescale 1ns / 1ps

module tb_alu();

    // 宣告連接 UUT (Unit Under Test) 的訊號
    reg clk;
    reg rst_n;
    reg [7:0] a, b, c, d;
    reg [3:0] sel;
    wire [15:0] result;

    // 例化待測模組 (在此替換為 AI 最佳化後的模組名稱來進行比較)
    bad_coding_style_alu uut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .sel(sel),
        .result(result)
    );

    // 產生 100MHz 的 Clock (週期 10ns)
    always #5 clk = ~clk;

    initial begin
        // 配合 Verdi 或 Vivado 的波形傾印
        $dumpfile("alu_wave.vcd"); // 如果用 VCS/Verdi，可改為 $fsdbDumpfile("alu_wave.fsdb");
        $dumpvars(0, tb_alu);

        // 1. 初始化與 Reset 序列
        clk = 0;
        rst_n = 0;
        a = 8'd0; b = 8'd0; c = 8'd0; d = 8'd0; sel = 4'd0;
        
        #20 rst_n = 1; // 釋放 Reset
        #10;

        // 2. 邊界與特定測資 (Directed Tests)
        a = 8'd10; b = 8'd5; c = 8'd4; d = 8'd2;
        $display("--- 啟動 Directed Test ---");
        for (integer i = 0; i < 8; i = i + 1) begin
            sel = i;
            #10; // 等待一個 Clock 週期讓結果輸出
            $display("Time=%0t | sel=%b | result=%d", $time, sel, result);
        end

        // 3. 隨機測資 (Random Tests)
        $display("--- 啟動 Random Test ---");
        for (integer i = 0; i < 10; i = i + 1) begin
            a = $random % 256;
            b = $random % 256;
            c = $random % 256;
            d = $random % 256;
            sel = $random % 8;
            #10;
        end

        // 結束模擬
        #50;
        $display("--- 模擬結束 ---");
        $finish;
    end

endmodule