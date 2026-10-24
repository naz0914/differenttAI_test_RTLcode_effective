module gemini_optimized_alu (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [3:0] sel,
    output reg [15:0] result
);

    // Stage 1: 運算元繞線與預先加法 (Operand Routing & Pre-addition)
    reg [9:0] op1a;
    reg [7:0] op1b;
    reg [7:0] op2a, op2b;
    reg [3:0] sel_st1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op1a <= 10'd0; op1b <= 8'd0;
            op2a <= 8'd0;  op2b <= 8'd0;
            sel_st1 <= 4'd0;
        end else begin
            sel_st1 <= sel;
            case (sel)
                4'b0000, 4'b0001: begin
                    op1a <= a; op1b <= b;
                    op2a <= c; op2b <= d;
                end
                4'b0010, 4'b0011: begin
                    op1a <= a; op1b <= c;
                    op2a <= b; op2b <= d;
                end
                4'b0100: begin
                    op1a <= a; op1b <= d;
                    op2a <= b; op2b <= c;
                end
                4'b0101: begin
                    op1a <= a + b + c + d; op1b <= a;
                    op2a <= 8'd0; op2b <= 8'd0;
                end
                4'b0110: begin
                    op1a <= a + b + c + d; op1b <= b;
                    op2a <= 8'd0; op2b <= 8'd0;
                end
                default: begin
                    op1a <= 10'd0; op1b <= 8'd0;
                    op2a <= 8'd0;  op2b <= 8'd0;
                end
            endcase
        end
    end

    // Stage 2: 乘法器資源共享 (Multiplier Resource Sharing)
    reg [15:0] prod1, prod2;
    reg [3:0]  sel_st2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prod1 <= 16'd0;
            prod2 <= 16'd0;
            sel_st2 <= 4'd0;
        end else begin
            prod1 <= op1a * op1b; 
            prod2 <= op2a * op2b;
            sel_st2 <= sel_st1;
        end
    end

    // Stage 3: 加減法與最終輸出 (Post-Addition/Subtraction)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'd0;
        end else begin
            case (sel_st2)
                4'b0000, 4'b0010, 4'b0100: result <= prod1 + prod2;
                4'b0001, 4'b0011:          result <= prod1 - prod2;
                4'b0101, 4'b0110:          result <= prod1;
                default:                   result <= 16'd0;
            endcase
        end
    end

endmodule