module optimized_alu_claude (
    input wire clk, rst_n,
    input wire [7:0] a, b, c, d,
    input wire [3:0] sel,
    output reg [15:0] result
);
    // Stage 1
    reg [7:0] a_s1, b_s1, c_s1, d_s1; reg [3:0] sel_s1; reg [9:0] sum_s1;
    always @(posedge clk) begin
        if (!rst_n) begin a_s1<=0; b_s1<=0; c_s1<=0; d_s1<=0; sel_s1<=0; sum_s1<=0; end
        else begin a_s1<=a; b_s1<=b; c_s1<=c; d_s1<=d; sel_s1<=sel; sum_s1<=a+b+c+d; end
    end

    // Stage 2
    reg [9:0] m1_x; reg [7:0] m1_y, m2_x, m2_y; reg do_sub;
    always @(posedge clk) begin
        if (!rst_n) begin m1_x<=0; m1_y<=0; m2_x<=0; m2_y<=0; do_sub<=0; end
        else begin
            case (sel_s1)
                4'b0000: begin m1_x<={2'b0, a_s1}; m1_y<=b_s1; m2_x<=c_s1; m2_y<=d_s1; do_sub<=0; end
                4'b0001: begin m1_x<={2'b0, a_s1}; m1_y<=b_s1; m2_x<=c_s1; m2_y<=d_s1; do_sub<=1; end
                4'b0010: begin m1_x<={2'b0, a_s1}; m1_y<=c_s1; m2_x<=b_s1; m2_y<=d_s1; do_sub<=0; end
                4'b0011: begin m1_x<={2'b0, a_s1}; m1_y<=c_s1; m2_x<=b_s1; m2_y<=d_s1; do_sub<=1; end
                4'b0100: begin m1_x<={2'b0, a_s1}; m1_y<=d_s1; m2_x<=b_s1; m2_y<=c_s1; do_sub<=0; end
                4'b0101: begin m1_x<=sum_s1; m1_y<=a_s1; m2_x<=0; m2_y<=0; do_sub<=0; end
                4'b0110: begin m1_x<=sum_s1; m1_y<=b_s1; m2_x<=0; m2_y<=0; do_sub<=0; end
                default: begin m1_x<=0; m1_y<=0; m2_x<=0; m2_y<=0; do_sub<=0; end
            endcase
        end
    end

    // Stage 3
    reg [15:0] p1, p2; reg do_sub_s3;
    wire [17:0] p1_full = m1_x * m1_y; wire [15:0] p2_full = m2_x * m2_y;
    always @(posedge clk) begin
        if (!rst_n) begin p1<=0; p2<=0; do_sub_s3<=0; end
        else begin p1<=p1_full[15:0]; p2<=p2_full; do_sub_s3<=do_sub; end
    end

    // Stage 4
    always @(posedge clk) begin
        if (!rst_n) result <= 16'd0;
        else result <= do_sub_s3 ? (p1 - p2) : (p1 + p2);
    end
endmodule
