module bad_coding_style_alu (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [3:0] sel,
    output reg [15:0] result
);

    // 教授的陷阱：將所有複雜運算與多工選擇塞在同一個 Clock Cycle 內完成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'd0;
        end else begin
            if (sel == 4'b0000) begin
                result <= (a * b) + (c * d);
            end else if (sel == 4'b0001) begin
                result <= (a * b) - (c * d);
            end else if (sel == 4'b0010) begin
                result <= (a * c) + (b * d);
            end else if (sel == 4'b0011) begin
                result <= (a * c) - (b * d);
            end else if (sel == 4'b0100) begin
                result <= (a * d) + (b * c);
            end else if (sel == 4'b0101) begin
                result <= (a + b + c + d) * a;
            end else if (sel == 4'b0110) begin
                result <= (a + b + c + d) * b;
            end else begin
                result <= 16'd0;
            end
        end
    end

endmodule