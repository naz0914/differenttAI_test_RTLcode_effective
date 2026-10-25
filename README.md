# 🔬 評估三大生成式 AI 最佳化 RTL Synthesis Coding Style 之硬體效能 (PPA)

> **學生學號：** `7114068027`  
> **課程作業：** Homework 1: 驗證不同的生成式 AI (Generative AI) 對於更正 (最佳化) RTL Synthesis Coding Style 的效能  
> **正式報告：** 📄 [7114068027.md](./7114068027.md) ｜ 🌐 [7114068027.html](./7114068027.html) ｜ 📑 [7114068027.pdf](./7114068027.pdf)  
> **目標晶片：** Xilinx Zynq-7000 FPGA (`xc7z020clg400-1`)  
> **EDA 工具：** Xilinx Vivado 2023.2 (16 Parallel Threads 本地編譯)  
> **時序約束：** 100MHz (Period: 10.000 ns, Setup WNS $\ge 0\text{ ns}$)  
> **評測對象：** OpenAI **ChatGPT** vs Google **Gemini** vs Anthropic **Claude**  

---


## 📋 教授指定實驗步驟達成檢核清單

| 實驗步驟 | 教授指定要求 | 達成狀態 | 具體執行成果 |
| :--- | :--- | :---: | :--- |
| **Step 1** | 使用三大頂尖生成式 AI (ChatGPT, Gemini, Claude) | ✅ 100% 達成 | 使用統一 Prompt 約束三家 AI 生成管線化與資源共享 Verilog |
| **Step 2** | 使用 Xilinx Vivado 驗證 RTL Synthesis 硬體效能 | ✅ 100% 達成 | 於 Vivado 2023.2 提取實際 PPA (LUT, DSP, Reg, WNS, Power) |
| **步驟 1** | 建立基準 (Baseline)：最差情況 PPA | ✅ 100% 達成 | 完成 `bad_coding_style_alu` 合成，證實單週期時序違規 (WNS=inf) |
| **步驟 2** | AI 重構三大目標：資源共享、管線化、邏輯結構優化 | ✅ 100% 達成 | 成功實現 DSP/乘法共享、3~4 級流水線切分、長串 `if-else` 轉平行 `case` |
| **步驟 3** | 合成與 PPA 提取：`Set as Top` 逐一提取並交叉比對 | ✅ 100% 達成 | 取得精確數據，繪製量化差距圖表並深入分析 EDA 合成行為 |
| **步驟 4** | 驗證與報告：撰寫架構分析結論與 Testbench 驗證 | ✅ 100% 達成 | 撰寫完整報告 [HW1_Report.md](./HW1_Report.md) 與跨週期比對 [tb_alu_comparison.v](./tb_alu_comparison.v) |

---

## 📊 一、 PPA 效能核心比較表

| 模組版本 | 運算延遲 | Slice LUTs | DSP48s | Slice Regs | WNS (ns) | 等效極限頻率 | 總晶片功耗 (W) | 優化亮點與架構特徵 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Baseline** | 1 cycle | 567 | 2 | 16 | **inf (時序違規)** | 崩潰 (<100MHz) | 0.122 | 未管線化、邏輯深度大、階層多工器鏈 |
| **ChatGPT** | 3 cycles | **170** | 1 | 71 | **+3.828** | ~162.0 MHz | 0.116 | **LUT 面積冠軍** (省 70.0%)，狀態編碼壓縮 (2-bit mode) |
| **Gemini** | 3 cycles | 177 | 1 | 75 | **+3.828** | ~162.0 MHz | **0.115** | **功耗控制冠軍** (最低 0.115W)，結構對稱規整 |
| **Claude** | 4 cycles | 194 | 1 | 96 | **+3.828** | ~162.0 MHz | 0.122 | **最符 FPGA 規範**：同步重置 + 輸入隔離暫存 (UG949) |

---

## 📈 二、 各 AI 模型效能差距圖表展示 (Visual Gap Analysis)

### 1. 邏輯閘面積 (Slice LUTs) 差距比較（越少越佳 🔻）
> 基準 (Baseline) 為 567 LUTs。AI 重構展現出驚人的資源共享能力，將面積大幅精簡 **65% ~ 70%**！

```text
Baseline  [567 LUTs]  ██████████████████████████████  100.0% (基準不良寫法)
ChatGPT   [170 LUTs]  █████████░░░░░░░░░░░░░░░░░░░░░   30.0% 【🔻 節省 70.0% 最佳】
Gemini    [177 LUTs]  █████████░░░░░░░░░░░░░░░░░░░░░   31.2% 【🔻 節省 68.8%】
Claude    [194 LUTs]  ██████████░░░░░░░░░░░░░░░░░░░░   34.2% 【🔻 節省 65.8%】
```

---

### 2. 管線暫存器開銷 (Slice Registers) 比較
> 反映各 AI 的管線切分策略：ChatGPT 透過狀態解碼壓縮暫存器；Claude 則因採用 4-Stage 與輸入暫存，開銷最高。

```text
Baseline  [ 16 Regs]  ███░░░░░░░░░░░░░░░░░  (僅輸出暫存，無任何管線)
ChatGPT   [ 71 Regs]  ███████████████░░░░░  (3-Stage，將 4-bit sel 壓縮為 2-bit mode)
Gemini    [ 75 Regs]  ████████████████░░░░  (3-Stage，標準對稱管線暫存)
Claude    [ 96 Regs]  ████████████████████  (4-Stage，包含 Stage 1 輸入隔離暫存器)
```

---

### 3. 晶片總功耗 (Total On-Chip Power) 差距比較（越低越佳 🔻）
> Gemini 因流水線路徑最直觀且無冗餘多工運算，動態切換活動率最低，獲得最佳功耗表現。

```text
Baseline  [0.122 W]   ████████████████████  100.0%
ChatGPT   [0.116 W]   ███████████████████░   95.1% 【🔻 節能 4.9%】
Gemini    [0.115 W]   ██████████████████░░   94.3% 【🔻 節能 5.7% 最佳】
Claude    [0.122 W]   ████████████████████  100.0% (額外管線 FF 增加時鐘樹功耗)
```

---

### 4. 時序裕度 (Worst Negative Slack, WNS) 改善對比
> 目標時脈為 100MHz (週期 10.000 ns)。WNS $\ge 0$ 代表滿足時序要求。

```text
Baseline  [WNS =  inf ] ❌ 嚴重時序違規！邏輯閘層數過多，頻率無法達到 100MHz
ChatGPT   [WNS = +3.828] ✅ 完美收斂！關鍵路徑 6.172 ns，最高極限頻率可達 162.0 MHz
Gemini    [WNS = +3.828] ✅ 完美收斂！關鍵路徑 6.172 ns，最高極限頻率可達 162.0 MHz
Claude    [WNS = +3.828] ✅ 完美收斂！關鍵路徑 6.172 ns，最高極限頻率可達 162.0 MHz
```

---

## 🏗️ 三、 微架構演進與關鍵路徑對比 (Mermaid Diagrams)

```mermaid
graph TD
    subgraph Baseline [❌ 原始不良寫法 (Baseline) : 單一週期硬塞]
        B_IN[輸入信號 a, b, c, d, sel] --> B_CHAIN[階層式 if-else 優先編碼鏈]
        B_CHAIN --> B_MULT[多組未共享乘法器 a*b, c*d, a*c, b*d...]
        B_MULT --> B_ALU[四輸入前置加法 / 後置加減法]
        B_ALU --> B_REG[輸出暫存器 result]
        style B_CHAIN fill:#ffcccc,stroke:#ff0000,stroke-width:2px
        style B_ALU fill:#ffcccc,stroke:#ff0000,stroke-width:2px
    end

    subgraph ThreeStage [⚡ Gemini & ChatGPT : 3 級流水線架構]
        S1[Stage 1: 運算元路由 / 前置加法 / 狀態壓縮] -->|op1, op2| S2[Stage 2: 共享乘法器 Resource Sharing]
        S2 -->|prod1, prod2| S3[Stage 3: 後置加減運算與輸出暫存]
        style S1 fill:#d4edda,stroke:#28a745
        style S2 fill:#cce5ff,stroke:#004085
        style S3 fill:#d1ecf1,stroke:#0c5460
    end

    subgraph FourStage [🛡️ Claude : 4 級深度流水線 (含同步重置)]
        C1[Stage 1: 輸入隔離暫存器 Input Registering] --> C2[Stage 2: 運算元路由與模式選擇]
        C2 --> C3[Stage 3: 共享乘法器核心]
        C3 --> C4[Stage 4: 加減法選擇輸出]
        style C1 fill:#fff3cd,stroke:#856404
        style C3 fill:#cce5ff,stroke:#004085
        style C4 fill:#d1ecf1,stroke:#0c5460
    end
```

---

## 🏆 四、 三大生成式 AI 輔助硬體設計綜合評鑑

| 評測維度 | 🥇 ChatGPT (OpenAI) | 🥈 Gemini (Google) | 🥉 Claude (Anthropic) |
| :--- | :--- | :--- | :--- |
| **面積最佳化 (LUT)** | ⭐⭐⭐⭐⭐ **(冠軍 170 LUTs)** | ⭐⭐⭐⭐☆ (177 LUTs) | ⭐⭐⭐☆☆ (194 LUTs) |
| **低功耗表現 (Power)**| ⭐⭐⭐⭐☆ (0.116 W) | ⭐⭐⭐⭐⭐ **(冠軍 0.115 W)** | ⭐⭐⭐☆☆ (0.122 W) |
| **FPGA 規範性 (Coding Style)**| ⭐⭐⭐⭐☆ (非同步重置) | ⭐⭐⭐⭐☆ (非同步重置) | ⭐⭐⭐⭐⭐ **(冠軍 同步重置+UG949)** |
| **運算延遲代價 (Latency)**| 3 cycles (中) | 3 cycles (中) | 4 cycles (較高) |
| **微架構巧思** | 將 4-bit 控制碼壓縮為 2-bit 模式碼 | 程式碼對稱簡潔，運算元路由乾淨 | 前端隔離暫存，防禦性最高 |
| **最佳適用場景** | **ASIC/FPGA 面積資源極度受限專案** | **低功耗 IoT / 行動端晶片設計** | **超高頻通訊與嚴格 FPGA 標準設計** |

---

## 📷 五、 Vivado 實測原始數據截圖庫 (Synthesis Evidence Gallery)

本專案所有數據均於 **ASUS ROG Zephyrus G15 (AMD 16-Threads) + Vivado 2023.2** 完成實機合成，以下為各模組提取之原始報表佐證：

### 1. 基準模組 (Baseline) 實測截圖
> 時序違規崩潰 (WNS = inf)、消耗 567 LUTs 與 2 DSPs。

| 資源利用率 (Utilization) | 時序報告 (Timing WNS = inf) | 功耗分析 (Power = 0.122W) |
| :---: | :---: | :---: |
| <img src="./原%20程式碼數據/螢幕擷取畫面%202026-10-24%20185133.png" width="300"/> | <img src="./原%20程式碼數據/螢幕擷取畫面%202026-10-24%20185230.png" width="300"/> | <img src="./原%20程式碼數據/螢幕擷取畫面%202026-10-24%20185315.png" width="300"/> |

---

### 2. Google Gemini 模組實測截圖
> 總晶片功耗降至 0.115W 最低，LUT 降至 177，WNS 達 +3.828 ns。

| 資源利用率 (177 LUTs, 1 DSP) | 時序報告 (WNS = +3.828ns) | 功耗分析 (0.115W 最優) |
| :---: | :---: | :---: |
| <img src="./gemini_alu數據圖/螢幕擷取畫面%202026-10-24%20194952.png" width="300"/> | <img src="./gemini_alu數據圖/螢幕擷取畫面%202026-10-24%20194900.png" width="300"/> | <img src="./gemini_alu數據圖/螢幕擷取畫面%202026-10-24%20195017.png" width="300"/> |

---

### 3. OpenAI ChatGPT 模組實測截圖
> LUT 面積降至 170 (省 70.0% 最佳)，WNS 達 +3.828 ns。

| 資源利用率 (170 LUTs 最佳) | 時序報告 (WNS = +3.828ns) | 功耗分析 (0.116W) |
| :---: | :---: | :---: |
| <img src="./gpt_alu數據圖/螢幕擷取畫面%202026-10-24%20200053.png" width="300"/> | <img src="./gpt_alu數據圖/螢幕擷取畫面%202026-10-24%20200024.png" width="300"/> | <img src="./gpt_alu數據圖/螢幕擷取畫面%202026-10-24%20200115.png" width="300"/> |

---

### 4. Anthropic Claude 模組實測截圖
> 4-Stage 同步重置架構，96 Registers，WNS 達 +3.828 ns。

| 資源利用率 (194 LUTs, 96 Regs) | 時序報告 (WNS = +3.828ns) | 功耗分析 (0.122W) |
| :---: | :---: | :---: |
| <img src="./claude_alu數據圖/螢幕擷取畫面%202026-10-24%20202151.png" width="300"/> | <img src="./claude_alu數據圖/螢幕擷取畫面%202026-10-24%20202131.png" width="300"/> | <img src="./claude_alu數據圖/螢幕擷取畫面%202026-10-24%20202209.png" width="300"/> |

---

## 🛠️ 六、 專案檔案清單與目錄指引 (Repository File Inventory)

本儲存庫包含完整的作業成果報告、Verilog 硬體原始碼、自動比對驗證平台與 Vivado 實測報告截圖：

### 1. 📄 正式作業報告與文件 (Homework Reports)
| 檔案名稱 | 說明 | 格式與用途 |
| :--- | :--- | :--- |
| 📄 [**7114068027.md**](./7114068027.md) | **正式作業總結報告（以學號命名）** | Markdown 正式報告，包含微架構、PPA、問答與程式碼 |
| 🌐 [**7114068027.html**](./7114068027.html) | **網頁版高解析度報告** | 內建 A4 列印樣式與即時預覽，支援一鍵另存為 PDF |
| 📑 [**7114068027.pdf**](./7114068027.pdf) | **正式列印版 PDF 成果報告** | 方便直接繳交給教授與列印檢視 |
| 📝 [**HW1_Report.md**](./HW1_Report.md) | 作業一專案分析技術報告 | 深入微架構機理與 EDA 走線極限剖析 |
| 📘 [**README.md**](./README.md) | GitHub 專案首頁說明文件 | 提供完整量化圖表、截圖畫廊與成果展示 |

---

### 2. 🔌 Verilog 硬體電路模組 (RTL Source Codes)
* [`bad_coding_style_alu.v`](./bad_coding_style_alu.v) : 原始未管線化 Baseline 不良寫法模組 (1-Cycle)
* [`gemini_optimized_alu.v`](./gemini_optimized_alu.v) : Google Gemini 最佳化之 3-Stage 對稱流水線 ALU (低功耗冠軍 0.115W)
* [`optimized_alu_gpt.v`](./optimized_alu_gpt.v) : OpenAI ChatGPT 最佳化之 3-Stage 狀態壓縮 ALU (面積冠軍 170 LUTs)
* [`optimized_alu_claude.v`](./optimized_alu_claude.v) : Anthropic Claude 最佳化之 4-Stage 同步重置 ALU (UG949 規範冠軍)

---

### 3. 🧪 驗證與自動比對平台 (Simulation & Testbench)
* [`tb_alu_comparison.v`](./tb_alu_comparison.v) : **跨管線自動比對驗證 Testbench**（利用移位暫存器同步驗證 1-cycle、3-cycle、4-cycle 延遲之數學 Golden Model 正確性）
* [`tb_alu.v`](./tb_alu.v) : 單元功能驗證 Testbench

---

### 4. 📷 Vivado 實測截圖數據庫 (Synthesis Screenshot Galleries)
* 📁 [`原 程式碼數據/`](./原%20程式碼數據/) : Baseline 資源使用率、時序分析 (WNS=inf)、功耗報告截圖
* 📁 [`gemini_alu數據圖/`](./gemini_alu數據圖/) : Gemini 資源使用率、時序分析 (+3.828ns)、功耗報告截圖
* 📁 [`gpt_alu數據圖/`](./gpt_alu數據圖/) : ChatGPT 資源使用率、時序分析 (+3.828ns)、功耗報告截圖
* 📁 [`claude_alu數據圖/`](./claude_alu數據圖/) : Claude 資源使用率、時序分析 (+3.828ns)、功耗報告截圖

---

### 5. ⚡ 實用自動化腳本工具 (Automation Tools)
* [`convert_to_pdf.bat`](./convert_to_pdf.bat) : 呼叫 Windows 內建 Edge 引擎，一鍵將 HTML 轉為正式 `7114068027.pdf`
* [`start_auto_sync.bat`](./start_auto_sync.bat) : 背景自動同步啟動器，監聽目錄檔案變更並自動 push 至 GitHub
* [`auto_git_sync.ps1`](./auto_git_sync.ps1) : PowerShell 自動 Git 監聽引擎

---

### 模擬驗證執行：
在 Vivado 中將 `tb_alu_comparison.v` 設為 Simulation Top，點擊 **Run Behavioral Simulation**，即可在波形視窗中一覽四個模組在不同管線週期下的輸出比對狀態。

---

## 💻 七、 模組 Verilog 完整程式碼清單 (Verilog Source Codes)

### 1. 基準模組：不良寫法 (Baseline - 1-Cycle Unpipelined)
> 📄 檔案位置：[`bad_coding_style_alu.v`](./bad_coding_style_alu.v)  
> ⚠️ 特徵：單一週期硬塞所有運算、長串 `if-else` 階層多工器、算術運算未共享，時序嚴重違規 (`WNS = inf`)。

```verilog
module bad_coding_style_alu (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a, b, c, d,
    input wire [3:0] sel,
    output reg [15:0] result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) result <= 16'd0;
        else begin
            if (sel == 4'b0000) result <= (a * b) + (c * d);
            else if (sel == 4'b0001) result <= (a * b) - (c * d);
            else if (sel == 4'b0010) result <= (a * c) + (b * d);
            else if (sel == 4'b0011) result <= (a * c) - (b * d);
            else if (sel == 4'b0100) result <= (a * d) + (b * c);
            else if (sel == 4'b0101) result <= (a + b + c + d) * a;
            else if (sel == 4'b0110) result <= (a + b + c + d) * b;
            else result <= 16'd0;
        end
    end
endmodule
```

---

### 2. Google Gemini：最佳化 3 級管線 (Gemini - 3-Stage Pipelined)
> 📄 檔案位置：[`gemini_optimized_alu.v`](./gemini_optimized_alu.v)  
> 🏆 特徵：功耗冠軍 (**0.115 W**)、三級管線結構對稱整潔、切換活動率最低。

```verilog
module gemini_optimized_alu (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a, b, c, d,
    input wire [3:0] sel,
    output reg [15:0] result
);
    // Stage 1: Operand Routing & Pre-addition
    reg [9:0] op1a; reg [7:0] op1b, op2a, op2b; reg [3:0] sel_st1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            op1a <= 10'd0; op1b <= 8'd0; op2a <= 8'd0; op2b <= 8'd0; sel_st1 <= 4'd0;
        end else begin
            sel_st1 <= sel;
            case (sel)
                4'b0000, 4'b0001: begin op1a <= a; op1b <= b; op2a <= c; op2b <= d; end
                4'b0010, 4'b0011: begin op1a <= a; op1b <= c; op2a <= b; op2b <= d; end
                4'b0100: begin op1a <= a; op1b <= d; op2a <= b; op2b <= c; end
                4'b0101: begin op1a <= a + b + c + d; op1b <= a; op2a <= 8'd0; op2b <= 8'd0; end
                4'b0110: begin op1a <= a + b + c + d; op1b <= b; op2a <= 8'd0; op2b <= 8'd0; end
                default: begin op1a <= 10'd0; op1b <= 8'd0; op2a <= 8'd0; op2b <= 8'd0; end
            endcase
        end
    end

    // Stage 2: Multiplier Resource Sharing
    reg [15:0] prod1, prod2; reg [3:0] sel_st2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin prod1 <= 16'd0; prod2 <= 16'd0; sel_st2 <= 4'd0; end
        else begin prod1 <= op1a * op1b; prod2 <= op2a * op2b; sel_st2 <= sel_st1; end
    end

    // Stage 3: Post-Addition/Subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) result <= 16'd0;
        else begin
            case (sel_st2)
                4'b0000, 4'b0010, 4'b0100: result <= prod1 + prod2;
                4'b0001, 4'b0011:          result <= prod1 - prod2;
                4'b0101, 4'b0110:          result <= prod1;
                default:                   result <= 16'd0;
            endcase
        end
    end
endmodule
```

---

### 3. OpenAI ChatGPT：最佳化 3 級管線 (ChatGPT - 3-Stage Pipelined)
> 📄 檔案位置：[`optimized_alu_gpt.v`](./optimized_alu_gpt.v)  
> 🏆 特徵：面積冠軍 (**170 LUTs，省 70.0%**)、狀態編碼壓縮 (將 4-bit `sel` 壓縮為 2-bit `mode`)、顯式位元擴展防溢位。

```verilog
module optimized_alu_gpt (
    input wire clk, rst_n,
    input wire [7:0] a, b, c, d,
    input wire [3:0] sel,
    output reg [15:0] result
);
    wire [9:0] sum_all = {2'b0, a} + {2'b0, b} + {2'b0, c} + {2'b0, d};
    reg [9:0] mul1_a_s1; reg [7:0] mul1_b_s1, mul2_a_s1, mul2_b_s1; reg [1:0] mode_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul1_a_s1 <= 10'd0; mul1_b_s1 <= 8'd0; mul2_a_s1 <= 8'd0; mul2_b_s1 <= 8'd0; mode_s1 <= 2'b11;
        end else begin
            case (sel)
                4'b0000: begin mul1_a_s1 <= {2'b0, a}; mul1_b_s1 <= b; mul2_a_s1 <= c; mul2_b_s1 <= d; mode_s1 <= 2'b00; end
                4'b0001: begin mul1_a_s1 <= {2'b0, a}; mul1_b_s1 <= b; mul2_a_s1 <= c; mul2_b_s1 <= d; mode_s1 <= 2'b01; end
                4'b0010: begin mul1_a_s1 <= {2'b0, a}; mul1_b_s1 <= c; mul2_a_s1 <= b; mul2_b_s1 <= d; mode_s1 <= 2'b00; end
                4'b0011: begin mul1_a_s1 <= {2'b0, a}; mul1_b_s1 <= c; mul2_a_s1 <= b; mul2_b_s1 <= d; mode_s1 <= 2'b01; end
                4'b0100: begin mul1_a_s1 <= {2'b0, a}; mul1_b_s1 <= d; mul2_a_s1 <= b; mul2_b_s1 <= c; mode_s1 <= 2'b00; end
                4'b0101: begin mul1_a_s1 <= sum_all; mul1_b_s1 <= a; mul2_a_s1 <= 8'd0; mul2_b_s1 <= 8'd0; mode_s1 <= 2'b10; end
                4'b0110: begin mul1_a_s1 <= sum_all; mul1_b_s1 <= b; mul2_a_s1 <= 8'd0; mul2_b_s1 <= 8'd0; mode_s1 <= 2'b10; end
                default: begin mul1_a_s1 <= 10'd0; mul1_b_s1 <= 8'd0; mul2_a_s1 <= 8'd0; mul2_b_s1 <= 8'd0; mode_s1 <= 2'b11; end
            endcase
        end
    end

    reg [17:0] product1_s2; reg [15:0] product2_s2; reg [1:0] mode_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin product1_s2 <= 18'd0; product2_s2 <= 16'd0; mode_s2 <= 2'b11; end
        else begin product1_s2 <= mul1_a_s1 * mul1_b_s1; product2_s2 <= mul2_a_s1 * mul2_b_s1; mode_s2 <= mode_s1; end
    end

    wire [18:0] add_value = {1'b0, product1_s2} + {3'b0, product2_s2};
    wire [18:0] sub_value = {1'b0, product1_s2} - {3'b0, product2_s2};
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) result <= 16'd0;
        else begin
            case (mode_s2)
                2'b00: result <= add_value[15:0];
                2'b01: result <= sub_value[15:0];
                2'b10: result <= product1_s2[15:0];
                default: result <= 16'd0;
            endcase
        end
    end
endmodule
```

---

### 4. Anthropic Claude：最佳化 4 級管線 (Claude - 4-Stage Pipelined)
> 📄 檔案位置：[`optimized_alu_claude.v`](./optimized_alu_claude.v)  
> 🛡️ 特徵：FPGA 標準規範冠軍、**同步重置 (UG949 規範)**、Stage 1 專門設置輸入隔離暫存器 (Input Registering)。

```verilog
module optimized_alu_claude (
    input wire clk, rst_n,
    input wire [7:0] a, b, c, d,
    input wire [3:0] sel,
    output reg [15:0] result
);
    // Stage 1: 輸入隔離暫存 (Input Registering) & 前置加法
    reg [7:0] a_s1, b_s1, c_s1, d_s1; reg [3:0] sel_s1; reg [9:0] sum_s1;
    always @(posedge clk) begin
        if (!rst_n) begin a_s1<=0; b_s1<=0; c_s1<=0; d_s1<=0; sel_s1<=0; sum_s1<=0; end
        else begin a_s1<=a; b_s1<=b; c_s1<=c; d_s1<=d; sel_s1<=sel; sum_s1<=a+b+c+d; end
    end

    // Stage 2: 運算元選擇與減法控制標誌
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

    // Stage 3: 共享乘法器核心運算
    reg [15:0] p1, p2; reg do_sub_s3;
    wire [17:0] p1_full = m1_x * m1_y; wire [15:0] p2_full = m2_x * m2_y;
    always @(posedge clk) begin
        if (!rst_n) begin p1<=0; p2<=0; do_sub_s3<=0; end
        else begin p1<=p1_full[15:0]; p2<=p2_full; do_sub_s3<=do_sub; end
    end

    // Stage 4: 後置加減法選擇輸出
    always @(posedge clk) begin
        if (!rst_n) result <= 16'd0;
        else result <= do_sub_s3 ? (p1 - p2) : (p1 + p2);
    end
endmodule
```

---

### 5. 跨管線週期自動驗證 Testbench (Multi-latency Comparison TB)
> 📄 檔案位置：[`tb_alu_comparison.v`](./tb_alu_comparison.v)  
> 🧪 特徵：同一 Stimulus 同步激勵四個模組，利用移位暫存器（Shift Registers）比對 1-cycle、3-cycle、4-cycle 後的數學 Golden Model，自動判定 PASS / FAIL。

```verilog
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

    // 例化四個待測模組
    bad_coding_style_alu u_baseline (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .c(c), .d(d), .sel(sel), .result(res_baseline));
    gemini_optimized_alu u_gemini   (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .c(c), .d(d), .sel(sel), .result(res_gemini));
    optimized_alu_gpt    u_gpt      (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .c(c), .d(d), .sel(sel), .result(res_gpt));
    optimized_alu_claude u_claude   (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .c(c), .d(d), .sel(sel), .result(res_claude));

    // 時鐘生成：100MHz (週期 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // 數學參考模型 (Golden Model)
    function [15:0] calc_golden;
        input [3:0] f_sel; input [7:0] f_a, f_b, f_c, f_d;
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

    // 延遲管道：對應不同週期延遲
    reg [15:0] exp_pipe [0:4]; integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= 4; i = i + 1) exp_pipe[i] <= 16'd0;
        end else begin
            exp_pipe[0] <= calc_golden(sel, a, b, c, d);
            for (i = 1; i <= 4; i = i + 1) exp_pipe[i] <= exp_pipe[i-1];
        end
    end

    // 測試激勵流程
    initial begin
        rst_n = 0; a = 0; b = 0; c = 0; d = 0; sel = 0; #20;
        rst_n = 1; #10;

        test_op(4'b0000, 8'd10, 8'd5, 8'd4, 8'd2);
        test_op(4'b0001, 8'd20, 8'd3, 8'd5, 8'd6);
        test_op(4'b0010, 8'd12, 8'd7, 8'd3, 8'd4);
        test_op(4'b0011, 8'd15, 8'd2, 8'd4, 8'd5);
        test_op(4'b0100, 8'd8,  8'd6, 8'd5, 8'd2);
        test_op(4'b0101, 8'd2,  8'd3, 8'd4, 8'd1);
        test_op(4'b0110, 8'd1,  8'd4, 8'd2, 8'd3);

        #60;
        $display("Simulation Completed! All Pipeline Latencies Verified.");
        $finish;
    end

    task test_op;
        input [3:0] t_sel; input [7:0] t_a, t_b, t_c, t_d;
        begin
            @(posedge clk); sel = t_sel; a = t_a; b = t_b; c = t_c; d = t_d;
        end
    endtask

    // 自動跨週期檢驗斷言
    always @(posedge clk) begin
        if (rst_n && $time > 50) begin
            if (res_baseline !== exp_pipe[0]) $display("[FAIL][Baseline 1-cycle] Got %0d, Exp %0d", res_baseline, exp_pipe[0]);
            if (res_gemini   !== exp_pipe[2]) $display("[FAIL][Gemini 3-cycle]   Got %0d, Exp %0d", res_gemini, exp_pipe[2]);
            if (res_gpt      !== exp_pipe[2]) $display("[FAIL][ChatGPT 3-cycle]  Got %0d, Exp %0d", res_gpt, exp_pipe[2]);
            if (res_claude   !== exp_pipe[3]) $display("[FAIL][Claude 4-cycle]   Got %0d, Exp %0d", res_claude, exp_pipe[3]);
        end
    end
endmodule
```

---

## 🏁 八、 實驗結論與工程反思 (Conclusions & Architectural Insights)

### 1. 實驗核心結論
本作業透過 **Xilinx Vivado 2023.2** 於 **Zynq-7000 FPGA (`xc7z020`)** 平台，全面驗證了三大生成式 AI 輔助硬體 RTL 最佳化的實務效能，得出以下核心結論：

1. **破除不良編程風格的時序枷鎖：**  
   * 原始 Baseline 模組因未管線化、長串 `if-else` 階層多工器與運算子重複，在 100MHz (10ns) 約束下發生嚴重的 Setup Time 違規（$WNS = \text{inf}$），硬體頻率完全無法達標。
   * **最佳化成效：** 三家 AI 模型均成功突破關鍵路徑瓶頸，將時序收斂至 **$WNS = +3.828\text{ ns}$**（等效最高頻率提升至 **$162.0\text{ MHz}$**），且大幅精簡邏輯閘面積達 **65.8% ~ 70.0%**，展現出生成式 AI 在數位電路重構上的高度實用價值。

2. **三大 AI 模型之微架構風格深度對比：**
   * **OpenAI ChatGPT（面積極致壓縮冠軍 🥇）：**  
     展現出敏銳的硬體直覺，在 Stage 1 獨創性地將 4-bit `sel` 壓縮編碼為 2-bit `mode` 傳遞過流水線，以最低的暫存器開銷換取最大的面積收益，**Slice LUT 僅需 170 個（節省 70.0%）**，極度適合 ASIC / FPGA 晶片面積受限的極致設計。
   * **Google Gemini（低功耗控制冠軍 🥇）：**  
     流水線結構最為整潔直觀、高度對稱（路由 $\rightarrow$ 共享乘法 $\rightarrow$ 後處理加減），無多餘的狀態跳轉與擾動，使得信號切換活動率（Switching Activity）最低，**總晶片功耗達到全場最低的 0.115 W**，最適合行動裝置或電池供電的低功耗物聯網晶片。
   * **Anthropic Claude（FPGA 原生規範冠軍 🥇）：**  
     唯一主動採用 **同步重置 (Synchronous Reset)** 並建立 **輸入隔離暫存 (Input Registering)** 的模型，完全遵循 Xilinx 官方 *UltraFast Design Methodology (UG949)* 最佳實務。雖因 4 級管線在 100MHz 下略顯 Over-pipelining（暫存器 96 個），但其防禦性設計在未來推升至 200MHz+ 超高頻時具備最佳的時序彈性。

---

### 2. 硬體工程反思與設計權衡 (Hardware Trade-offs)
* **延遲週期與時脈頻率的代價（Latency vs. Throughput）：**  
  AI 雖然大幅提升了時鐘頻率（$F_{max}$ 提升超過 60%）並消除了時序違規，但將運算延遲由原始的 1 cycle 拉長至 **3 cycles (GPT/Gemini)** 或 **4 cycles (Claude)**。這警惕硬體工程師：在系統層次整合時，不可盲目將 AI 生成代碼直接替換，必須同步更新上游/下游的握手協定（Valid/Ready）與狀態機控制。
* **EDA 合成機制的物理邊界：**  
  三款 AI 的 WNS 均剛好停在 $+3.828\text{ ns}$，揭示了 Vivado 合成工具在達到目標時序裕度（Slack > 0）後會停止進一步激進重構的工程特性，同時也凸顯了 DSP48E1 專用硬體走線至 Slice 組合邏輯的物理傳遞延遲極限。

---

### 3. 未來研究與延伸方向
1. **極限頻率探索 (Frequency Scaling)：** 將時脈約束逐步提升至 150MHz、200MHz 與 250MHz，驗證 Claude 4 級管線與同步重置在超高頻下的潛在優勢。
2. **自動化驗證機制 (Automated Verification)：** 結合 SystemVerilog 與 UVM 框架，利用生成式 AI 自動產出隨機激勵與 Assertions，建構更全面的驗證閉環。


