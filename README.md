# 🔬 評估三大生成式 AI 最佳化 RTL Synthesis Coding Style 之硬體效能 (PPA)

> **課程作業：** Homework 1: 驗證不同的生成式 AI (Generative AI) 對於更正 (最佳化) RTL Synthesis Coding Style 的效能  
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

## 🛠️ 六、 檔案清單與模擬驗證指引

* [`bad_coding_style_alu.v`](./bad_coding_style_alu.v) : 原始未管線化 Baseline 模組
* [`gemini_optimized_alu.v`](./gemini_optimized_alu.v) : Google Gemini 最佳化 3-Stage 模組
* [`optimized_alu_gpt.v`](./optimized_alu_gpt.v) : OpenAI ChatGPT 最佳化 3-Stage 模組
* [`optimized_alu_claude.v`](./optimized_alu_claude.v) : Anthropic Claude 最佳化 4-Stage 模組
* [`tb_alu_comparison.v`](./tb_alu_comparison.v) : **跨管線自動比對驗證 Testbench**（自動依據 1/3/4 cycle 延遲比對數學 Golden Model）
* [`HW1_Report.md`](./HW1_Report.md) : 詳細文字作業報告（含 EDA 機制與微架構深入剖析）

### 模擬驗證執行：
在 Vivado 中將 `tb_alu_comparison.v` 設為 Simulation Top，點擊 **Run Behavioral Simulation**，即可在波形視窗中一覽四個模組在不同管線週期下的輸出比對狀態。
