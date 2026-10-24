@echo off
chcp 65001 >nul
echo ========================================================
echo   Connecting to GitHub Repository:
echo   https://github.com/naz0914/differenttAI_test_RTLcode_effective.git
echo ========================================================

:: Check if git is installed
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH! Please install Git for Windows.
    pause
    exit /b
)

:: Initialize git if not already initialized
if not exist ".git" (
    echo [1/5] Initializing Git repository...
    git init
) else (
    echo [1/5] Git repository already initialized.
)

:: Set default branch to main
echo [2/5] Setting branch to main...
git branch -M main

:: Configure remote origin
echo [3/5] Setting remote origin...
git remote remove origin >nul 2>nul
git remote add origin https://github.com/naz0914/differenttAI_test_RTLcode_effective.git

:: Add and commit files
echo [4/5] Staging files and creating commit...
git add .
git commit -m "Add RTL synthesis coding style optimization modules, HW1 report and testbench"

:: Push to remote
echo [5/5] Pushing to GitHub (origin main)...
echo Note: If prompted, please authenticate with your GitHub account.
git push -u origin main

if %errorlevel% equ 0 (
    echo ========================================================
    echo   Successfully connected and pushed to GitHub!
    echo ========================================================
) else (
    echo ========================================================
    echo   Push failed or required authentication.
    echo   If the remote repository already contains files (e.g. README/License),
    echo   you can run:
    echo     git pull origin main --rebase
    echo     git push -u origin main
    echo ========================================================
)

pause
