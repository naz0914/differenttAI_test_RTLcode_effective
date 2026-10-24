# Evaluating Generative AI on RTL Synthesis Coding Style Optimization

本專案旨在評估與驗證主流生成式 AI（**OpenAI ChatGPT**、**Google Gemini**、**Anthropic Claude**）在硬體描述語言（Verilog HDL）中，針對不良 RTL Coding Style 進行重構與最佳化（Resource Sharing, Pipelining, Logic Flattening）之硬體效能（PPA）。

---

## 🎯 實驗環境與約束

* **目標平台 (Target FPGA)**: Xilinx Zynq-7000 (`xc7z020clg400-1`)
* **EDA 工具**: Xilinx Vivado 2023.2 (Local Synthesis, 16 Threads)
* **時序約束 (Timing Constraint)**: 100MHz (Period: 10.000 ns)

---

## 📊 PPA 效能綜合比較表

| 模組版本 | 延遲週期 (Latency) | Slice LUTs | DSPs | Slice Registers | WNS (ns) | 等效極限頻率 | 總晶片功耗 (W) | 架構特徵 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Baseline** | 1 cycle | 567 | 2 | 16 | **inf (未滿足)** | 崩潰 (<100MHz) | 0.122 | 長串 `if-else`、單週期硬塞所有運算、關鍵路徑過長 |
| **ChatGPT** | 3 cycles | **170** | 1 | 71 | **+3.828** | ~162.0 MHz | 0.116 | **LUT 面積冠軍** (省 70%)，控制信號編碼壓縮 (2-bit mode) |
| **Gemini** | 3 cycles | 177 | 1 | 75 | **+3.828** | ~162.0 MHz | **0.115** | **功耗控制冠軍** (最低 0.115W)，三級管線結構對稱整潔 |
| **Claude** | 4 cycles | 194 | 1 | 96 | **+3.828** | ~162.0 MHz | 0.122 | **最符 FPGA 規範**：同步重置 + 輸入隔離暫存 (UG949) |

---

## 📁 檔案結構說明

* [`bad_coding_style_alu.v`](./bad_coding_style_alu.v): 原始充滿多工浪費與無管線之不良寫法模組 (Baseline)。
* [`gemini_optimized_alu.v`](./gemini_optimized_alu.v): Google Gemini 最佳化之 3-Stage 管線化 ALU。
* [`optimized_alu_gpt.v`](./optimized_alu_gpt.v): OpenAI ChatGPT 最佳化之 3-Stage 管線化 ALU。
* [`optimized_alu_claude.v`](./optimized_alu_claude.v): Anthropic Claude 最佳化之 4-Stage 管線化 ALU（採用同步重置）。
* [`tb_alu_comparison.v`](./tb_alu_comparison.v): 多週期跨管線自動比對驗證 Testbench。
* [`HW1_Report.md`](./HW1_Report.md): 完整實驗成果報告（包含深層微架構與 EDA 合成機理解析）。

---

## 🚀 執行模擬驗證 (Simulation)

在 Vivado 中將 `tb_alu_comparison.v` 與四個 ALU 模組一同加入專案，直接執行 Behavioral Simulation：
* Baseline 延遲：1 cycle
* Gemini / ChatGPT 延遲：3 cycles
* Claude 延遲：4 cycles
Testbench 具備自動比對機制，模擬完成後將自動輸出驗證狀態。
