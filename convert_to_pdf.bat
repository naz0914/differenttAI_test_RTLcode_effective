@echo off
chcp 65001 >nul
echo ========================================================
echo   正在生成 7114068027.pdf ...
echo ========================================================

set "HTML_PATH=%~dp07114068027.html"
set "PDF_PATH=%~dp07114068027.pdf"

:: 優先使用 Windows 內建 Microsoft Edge (100% 存在於 Win10/Win11)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    echo [1/2] 呼叫 Microsoft Edge 引擎渲染輸出...
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf="%PDF_PATH%" "%HTML_PATH%"
    goto CHECK_RESULT
)

if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    echo [1/2] 呼叫 Microsoft Edge 引擎渲染輸出...
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe" --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf="%PDF_PATH%" "%HTML_PATH%"
    goto CHECK_RESULT
)

:: 備用 Google Chrome
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo [1/2] 呼叫 Google Chrome 引擎渲染輸出...
    "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf="%PDF_PATH%" "%HTML_PATH%"
    goto CHECK_RESULT
)

:CHECK_RESULT
timeout /t 2 >nul
if exist "%PDF_PATH%" (
    echo ========================================================
    echo   [2/2] ✅ PDF 生成成功！
    echo   檔案名稱：7114068027.pdf
    echo   檔案路徑：%PDF_PATH%
    echo ========================================================
    start "" "%PDF_PATH%"
) else (
    echo ========================================================
    echo   未能自動產出，已自動為你開啟 7114068027.html
    echo   請在瀏覽器按右下角綠色按鈕或按 Ctrl+P，目的地選擇「另存為 PDF」！
    echo ========================================================
    start "" "%HTML_PATH%"
)

pause
