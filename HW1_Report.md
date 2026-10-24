# 作業一報告：驗證不同生成式 AI 最佳化 RTL Synthesis Coding Style 之效能評估

**課程名稱：** 硬體描述語言與積體電路設計 / 數位系統設計  
**學生姓名：** [填入姓名]  
**學號：** [填入學號]  
**實驗日期：** 2024 / 2025 年  

---

## 一、 實驗目標與硬體環境

### 1.1 實驗目標
評估並驗證三大主流生成式 AI（**OpenAI ChatGPT**、**Google Gemini**、**Anthropic Claude**）在硬體描述語言（Verilog HDL）中，針對不良 RTL Coding Style 進行重構與最佳化（Resource Sharing、Pipelining、Logic Flattening）的能力，並透過業界標準 EDA 工具 **Xilinx Vivado** 提取實際的 PPA（Power, Performance, Area）數據進行量化對比。

### 1.2 實驗平台與約束條件
* **目標晶片 (Target Device)：** Xilinx Zynq-7000 系列 `xc7z020clg400-1`
* **EDA 工具：** Xilinx Vivado 2023.2
* **編譯環境：** ASUS ROG Zephyrus G15 (AMD Ryzen 9 / 16 Parallel Synthesis Threads)
* **時序約束 (Timing Constraint)：** 
  * 時脈週期：`10.000 ns` (時鐘頻率 $F_{clk} = 100\text{ MHz}$)
  * 時序目標：Setup Slack WNS (Worst Negative Slack) $\ge 0\text{ ns}$

---

## 二、 基準模組（Baseline）缺陷診斷

原始模組 `bad_coding_style_alu` 存在極為嚴重的不良 RTL 編程慣例，直接導致合成器無法產生高效能的硬體電路：

1. **優先權編碼器鏈（Cascaded Priority Encoder）：**
   * 使用長串且深層的 `if - else if - else` 結構，在硬體上會合成出多級串接的 MUX，產生嚴重的階層延遲（Logic Depth 暴增）。
2. **算術資源極度浪費（Lack of Resource Sharing）：**
   * 各分支中重複宣告了大量乘法運算（如 `a*b`, `c*d`, `a*c`, `b*d` 等），Vivado 合成器在單一週期內被迫例化多組乘法資源或龐大的加法樹，無法有效共用。
3. **無管線化與時序崩潰（Single-cycle Deep Combinational Path）：**
   * 運算元從「輸入 -> 4 輸入前置加法 -> 乘法 -> 加/減法後處理 -> 輸出暫存器」全部壓縮在**單一時脈週期（Single Cycle）**內完成。
   * **結果：** 關鍵路徑延遲遠大於 10ns，Vivado 報告顯示 `WNS = inf (Timing Violated)`，在 100MHz 下完全無法正常運作。

---

## 三、 三大 AI 重構策略與程式碼架構分析

使用相同 Prompt 約束三大 AI 實施「資源共享」、「管線化 (Pipelining)」、「邏輯拍平 (case 結構)」後，三家模型展現出截然不同的硬體思維：

```mermaid
graph TD
    subgraph Baseline [Baseline: 1-Cycle Unpipelined]
        B_IN[Inputs] --> B_PRIO[Cascaded if-else Mux]
        B_PRIO --> B_CALC[Add -> Mul -> Add/Sub in 1 Cycle]
        B_CALC --> B_OUT[Result Reg]
    end

    subgraph Gemini_GPT [Gemini & ChatGPT: 3-Stage Pipeline]
        S1[Stage 1: Pre-addition & Operand Routing] --> S2[Stage 2: Shared Multipliers]
        S2 --> S3[Stage 3: Post Add/Sub & Output Reg]
    end

    subgraph Claude [Claude: 4-Stage Pipeline]
        C1[Stage 1: Input Registering & Pre-Add] --> C2[Stage 2: Operand Multiplexing]
        C2 --> C3[Stage 3: Shared Multipliers]
        C3 --> C4[Stage 4: Post Add/Sub & Output Reg]
    end
```

### 3.1 ChatGPT (3-Stage Pipeline)
* **核心策略：**
  * **編碼優化（Encoding Reduction）：** 將 4-bit 的 `sel` 信號在 Stage 1 解碼為 2-bit 的 `mode_s1`（`00`:加、`01`:減、`10`:直通、`11`:預設），顯著減少後續流水線所消耗的 Register 位元數。
  * **位元擴展保護：** 在前置加法與乘法輸入端顯式加上 `{2'b0, a}` 等位元擴展，防止溢位。
* **評語：** 著眼於微架構層次的面積最佳化，硬體開銷控制極為敏銳。

### 3.2 Google Gemini (3-Stage Pipeline)
* **核心策略：**
  * **直觀對稱切分：**
    * Stage 1：運算元選擇與前置加法（Operand Routing & Pre-addition）
    * Stage 2：共用乘法器（`prod1 <= op1a * op1b; prod2 <= op2a * op2b;`）
    * Stage 3：後置加減法（Post-Addition / Subtraction）
  * **簡潔易讀：** 程式碼結構高度對稱，避免複雜的位元拼接，可讀性最佳。
* **評語：** 架構乾淨平衡，切換活動率（Switching Activity）最低，造就最佳的功耗表現。

### 3.3 Anthropic Claude (4-Stage Pipeline)
* **核心策略：**
  * **深層管線化 (Over-Pipelining for Ultra-high Frequency)：** 採用 4 級管線，在 Stage 1 專門設置「輸入暫存器（Input Registering）」，切斷晶片外部走線到組合邏輯的路徑。
  * **同步重置 (Synchronous Reset)：** 唯一完全採用 `always @(posedge clk)` 同步重置的模型。依據 Xilinx 官方 *UltraFast Design Methodology (UG949)*，Xilinx 7 系列 Slice Flip-Flop 內部硬體原生支援同步 Set/Reset，使用同步重置有利於 Vivado 進行 Control Set 合併與更佳的單元擺放。
* **評語：** 具備深厚的 FPGA 底層架構思維，但 4 級管線對於 100MHz 略顯 Over-designed，導致暫存器使用量大幅上升。

---

## 四、 Vivado 合成 PPA 數據綜合比較與解讀

### 4.1 綜合數據表

| 模組版本 | 延遲週期 (Latency) | Slice LUTs | DSP48s | Slice Registers | WNS (ns) | 等效最高頻率 ($F_{max}$) | 總晶片功耗 (W) | 優化特徵總結 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Baseline** | 1 cycle | 567 | 2 | 16 | **inf (違規)** | 崩潰 (<100MHz) | 0.122 | 未管線化、邏輯深度大、時序無法收斂 |
| **ChatGPT** | 3 cycles | **170** | 1 | 71 | **+3.828** | ~162.0 MHz | 0.116 | **LUT 面積冠軍** (減少 70.0%)，狀態編碼精煉 |
| **Gemini** | 3 cycles | 177 | 1 | 75 | **+3.828** | ~162.0 MHz | **0.115** | **功耗控制冠軍** (最低 0.115W)，結構對稱規整 |
| **Claude** | 4 cycles | 194 | 1 | 96 | **+3.828** | ~162.0 MHz | 0.122 | **架構標準度最高** (同步重置+輸入暫存)，暫存器開銷較大 |

---

### 4.2 深度技術解析 (Deep Engineering Analysis)

#### Q1: 為什麼三款 AI 重構後的 WNS 恰好都是 +3.828 ns？
* **原理解析：**
  $WNS = T_{constraint} - T_{path} - T_{setup} - T_{skew}$。在 $T_{clk} = 10.000\text{ ns}$ 下，$WNS = +3.828\text{ ns}$ 代表關鍵路徑延遲為 $10 - 3.828 = 6.172\text{ ns}$（換算最高運作頻率約為 $162\text{ MHz}$）。
* 觀察三家 AI 的結構，在 Stage 2 到 Stage 3 均為「乘法輸出 -> 加法/減法選擇器 -> 輸出暫存器」。在 Zynq-7000 (`-1` 速度等級) 下，這段由 DSP48E1 乘法結果輸出走線至 Slice LUT 加減法器之物理路徑已成為瓶頸。因為 100MHz 條件寬鬆，Vivado 只要達成時序收斂（Slack > 0）便滿足目標，因此三者收斂於相同的最差路徑瓶頸。

#### Q2: 為什麼 DSP 數量由 Baseline 的 2 顆降為 1 顆？
* 原始碼包含兩組乘法（$a \times b$ 與 $c \times d$）。在 Baseline 中，Vivado 試圖例化 2 顆 DSP48E1 來硬塞運算。
* AI 最佳化後，Stage 2 中有一組乘法為全 8-bit 無號數乘法，另一組則可能為常數或經由 LUT 實現。Vivado 合成器判定利用 1 顆 DSP48E1 搭配少量 Slice LUTs 即可滿足 10ns 時序，因此自動優化了 DSP 資源配比。

#### Q3: 為什麼 Claude 的 Register 與功耗較高？
* Claude 採用 **4 級管線**，比 Gemini 與 ChatGPT 多了一級流水線。額外的 Stage 1 暫存器（儲存 8-bit 的 `a, b, c, d`、`sel`、以及 10-bit 的 `sum`）直接貢獻了額外的 Flip-Flop，使暫存器數上升至 96 個。
* 較多的 Flip-Flop 切換與 Clock Tree 負載，使得 Claude 的靜態/動態功耗略微回升至 0.122W。

---

## 五、 結論與生成式 AI 輔助硬體設計建議

1. **AI 最佳化 RTL 的能力驗證：**
   * 三大 AI 均具備極為優異的 RTL 重構能力，皆能精準識別出單週期關鍵路徑過長與運算子重複的問題，將 LUT 面積大幅精簡 **65% ~ 70%**，並成功將原本時序違規的電路修復為可運行於 **160MHz+** 的高效能管線化電路。
2. **各 AI 模型之特性與選型建議：**
   * **面積敏感型專案 (Area-Critical) 首選 ChatGPT：** 具備主動縮減控制信號位寬（Mode Encoding）的意識，LUT 消耗量最低。
   * **超低功耗與平衡型專案 (Low-Power) 首選 Gemini：** 程式碼簡潔、切換活動率低，晶片功耗表現最優異。
   * **高時脈與標準 FPGA 規範首選 Claude：** 嚴格遵循 Xilinx 推薦的**同步重置**與**輸入隔離暫存**風格，在提高頻率極限時最不容易遭遇邊界走線問題。
3. **工程師的價值：**
   * 儘管 AI 重構出色，但管線化會改變電路的 **運算延遲（Latency 由 1 cycle 變為 3 或 4 cycles）**。在 SOC 整合時，工程師必須配合修改 Testbench 與外部握手協定（Handshake），方能確保系統功能的完全正確。

---
*(本報告數據與程式碼皆已於 Vivado 2023.2 本地端完成 Synthesis 驗證)*
