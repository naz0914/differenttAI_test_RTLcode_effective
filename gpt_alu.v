
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

    // =========================================================
    // Stage 1: Operand Selection and Pre-computation
    // =========================================================

    // Balanced addition tree: maximum sum = 1020 (10 bits)
    wire [9:0] sum_ab  = {2'b0, a} + {2'b0, b};
    wire [9:0] sum_cd  = {2'b0, c} + {2'b0, d};
    wire [9:0] sum_all = sum_ab + sum_cd;

    // Multiplier operand registers
    reg [9:0] mul1_a_s1;
    reg [7:0] mul1_b_s1;
    reg [7:0] mul2_a_s1;
    reg [7:0] mul2_b_s1;

    // mode: 00 = ADD, 01 = SUB, 10 = MUL_ONLY,
    //       11 = INVALID
    reg [1:0] mode_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul1_a_s1 <= 10'd0;
            mul1_b_s1 <= 8'd0;
            mul2_a_s1 <= 8'd0;
            mul2_b_s1 <= 8'd0;
            mode_s1   <= 2'b11;
        end else begin
            case (sel)
                4'b0000: begin
                    mul1_a_s1 <= {2'b0, a};
                    mul1_b_s1 <= b;
                    mul2_a_s1 <= c;
                    mul2_b_s1 <= d;
                    mode_s1   <= 2'b00;
                end

                4'b0001: begin
                    mul1_a_s1 <= {2'b0, a};
                    mul1_b_s1 <= b;
                    mul2_a_s1 <= c;
                    mul2_b_s1 <= d;
                    mode_s1   <= 2'b01;
                end

                4'b0010: begin
                    mul1_a_s1 <= {2'b0, a};
                    mul1_b_s1 <= c;
                    mul2_a_s1 <= b;
                    mul2_b_s1 <= d;
                    mode_s1   <= 2'b00;
                end

                4'b0011: begin
                    mul1_a_s1 <= {2'b0, a};
                    mul1_b_s1 <= c;
                    mul2_a_s1 <= b;
                    mul2_b_s1 <= d;
                    mode_s1   <= 2'b01;
                end

                4'b0100: begin
                    mul1_a_s1 <= {2'b0, a};
                    mul1_b_s1 <= d;
                    mul2_a_s1 <= b;
                    mul2_b_s1 <= c;
                    mode_s1   <= 2'b00;
                end

                4'b0101: begin
                    mul1_a_s1 <= sum_all;
                    mul1_b_s1 <= a;
                    mul2_a_s1 <= 8'd0;
                    mul2_b_s1 <= 8'd0;
                    mode_s1   <= 2'b10;
                end

                4'b0110: begin
                    mul1_a_s1 <= sum_all;
                    mul1_b_s1 <= b;
                    mul2_a_s1 <= 8'd0;
                    mul2_b_s1 <= 8'd0;
                    mode_s1   <= 2'b10;
                end

                default: begin
                    mul1_a_s1 <= 10'd0;
                    mul1_b_s1 <= 8'd0;
                    mul2_a_s1 <= 8'd0;
                    mul2_b_s1 <= 8'd0;
                    mode_s1   <= 2'b11;
                end
            endcase
        end
    end

    // =========================================================
    // Stage 2: Shared Multiplication
    // =========================================================

    reg [17:0] product1_s2;
    reg [15:0] product2_s2;
    reg [1:0]  mode_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product1_s2 <= 18'd0;
            product2_s2 <= 16'd0;
            mode_s2     <= 2'b11;
        end else begin
            product1_s2 <= mul1_a_s1 * mul1_b_s1;
            product2_s2 <= mul2_a_s1 * mul2_b_s1;
            mode_s2     <= mode_s1;
        end
    end

    // =========================================================
    // Stage 3: Add/Subtract and Output Register
    // =========================================================

    wire [18:0] product1_ext = {1'b0, product1_s2};
    wire [18:0] product2_ext = {3'b000, product2_s2};

    wire [18:0] add_value = product1_ext + product2_ext;
    wire [18:0] sub_value = product1_ext - product2_ext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'd0;
        end else begin
            case (mode_s2)
                2'b00: result <= add_value[15:0];
                2'b01: result <= sub_value[15:0];
                2'b10: result <= product1_s2[15:0];
                default: result <= 16'd0;
            endcase
        end
    end

endmodule
