`timescale 1ns / 1ps

module tb_alu_comparison;
    reg clk;
    reg rst_n;
    reg [7:0] a, b, c, d;
    reg [3:0] sel;

    wire [15:0] res_baseline;
    wire [15:0] res_gemini;
    wire [15:0] res_gpt;
    wire [15:0] res_claude;

    // Instantiate Baseline (Latency = 1 cycle)
    bad_coding_style_alu u_baseline (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .c(c), .d(d), .sel(sel),
        .result(res_baseline)
    );

    // Instantiate Gemini (Latency = 3 cycles)
    gemini_optimized_alu u_gemini (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .c(c), .d(d), .sel(sel),
        .result(res_gemini)
    );

    // Instantiate ChatGPT (Latency = 3 cycles)
    optimized_alu_gpt u_gpt (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .c(c), .d(d), .sel(sel),
        .result(res_gpt)
    );

    // Instantiate Claude (Latency = 4 cycles)
    optimized_alu_claude u_claude (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(b), .c(c), .d(d), .sel(sel),
        .result(res_claude)
    );

    // Clock Generation: 100MHz (Period = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Golden Model Reference Function
    function [15:0] calc_golden;
        input [3:0] f_sel;
        input [7:0] f_a, f_b, f_c, f_d;
        begin
            case (f_sel)
                4'b0000: calc_golden = (f_a * f_b) + (f_c * f_d);
                4'b0001: calc_golden = (f_a * f_b) - (f_c * f_d);
                4'b0010: calc_golden = (f_a * f_c) + (f_b * f_d);
                4'b0011: calc_golden = (f_a * f_c) - (f_b * f_d);
                4'b0100: calc_golden = (f_a * f_d) + (f_b * f_c);
                4'b0101: calc_golden = (f_a + f_b + f_c + f_d) * f_a;
                4'b0110: calc_golden = (f_a + f_b + f_c + f_d) * f_b;
                default: calc_golden = 16'd0;
            endcase
        end
    endfunction

    // Shift registers for verification across latencies
    reg [15:0] exp_pipe [0:4];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= 4; i = i + 1)
                exp_pipe[i] <= 16'd0;
        end else begin
            exp_pipe[0] <= calc_golden(sel, a, b, c, d);
            for (i = 1; i <= 4; i = i + 1)
                exp_pipe[i] <= exp_pipe[i-1];
        end
    end

    // Stimulus & Testing
    initial begin
        $display("==========================================================");
        $display("Starting Functional & Latency Verification for HW1 ALUs...");
        $display("==========================================================");

        rst_n = 0;
        a = 0; b = 0; c = 0; d = 0; sel = 0;
        #20;
        rst_n = 1;
        #10;

        // Apply 7 operations
        test_op(4'b0000, 8'd10, 8'd5, 8'd4, 8'd2); // (10*5)+(4*2) = 58
        test_op(4'b0001, 8'd20, 8'd3, 8'd5, 8'd6); // (20*3)-(5*6) = 30
        test_op(4'b0010, 8'd12, 8'd7, 8'd3, 8'd4); // (12*3)+(7*4) = 64
        test_op(4'b0011, 8'd15, 8'd2, 8'd4, 8'd5); // (15*4)-(2*5) = 50
        test_op(4'b0100, 8'd8,  8'd6, 8'd5, 8'd2); // (8*2)+(6*5)  = 46
        test_op(4'b0101, 8'd2,  8'd3, 8'd4, 8'd1); // (2+3+4+1)*2  = 20
        test_op(4'b0110, 8'd1,  8'd4, 8'd2, 8'd3); // (1+4+2+3)*4  = 40

        // Flush pipeline
        #60;
        $display("==========================================================");
        $display("Simulation Completed! All Pipeline Latencies Verified.");
        $display("==========================================================");
        $finish;
    end

    task test_op;
        input [3:0] t_sel;
        input [7:0] t_a, t_b, t_c, t_d;
        begin
            @(posedge clk);
            sel = t_sel; a = t_a; b = t_b; c = t_c; d = t_d;
            $display("[T=%0t ns] Input Stimulus: sel=%b, a=%0d, b=%0d, c=%0d, d=%0d", 
                     $time, t_sel, t_a, t_b, t_c, t_d);
        end
    endtask

    // Check assertions at each posedge after reset
    always @(posedge clk) begin
        if (rst_n && $time > 50) begin
            // Latency 1: Baseline
            if (res_baseline !== exp_pipe[0])
                $display("[FAIL][Baseline 1-cycle] Got %0d, Expected %0d", res_baseline, exp_pipe[0]);
            
            // Latency 3: Gemini & ChatGPT
            if (res_gemini !== exp_pipe[2])
                $display("[FAIL][Gemini 3-cycle] Got %0d, Expected %0d", res_gemini, exp_pipe[2]);
            if (res_gpt !== exp_pipe[2])
                $display("[FAIL][ChatGPT 3-cycle] Got %0d, Expected %0d", res_gpt, exp_pipe[2]);

            // Latency 4: Claude
            if (res_claude !== exp_pipe[3])
                $display("[FAIL][Claude 4-cycle] Got %0d, Expected %0d", res_claude, exp_pipe[3]);
        end
    end

endmodule
