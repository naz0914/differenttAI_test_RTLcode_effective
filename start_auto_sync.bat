@echo off
chcp 65001 >nul
title GitHub Auto Sync Watcher
echo 啟動背景自動同步 GitHub 服務...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto_git_sync.ps1"
pause
