# Connect local project to GitHub repository
$remoteUrl = "https://github.com/naz0914/differenttAI_test_RTLcode_effective.git"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Connecting to GitHub Repository:" -ForegroundColor Cyan
Write-Host "$remoteUrl" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    Write-Host "[1/5] Initializing Git repository..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "[1/5] Git repository already initialized." -ForegroundColor Yellow
}

Write-Host "[2/5] Setting branch to main..." -ForegroundColor Yellow
git branch -M main

Write-Host "[3/5] Setting remote origin..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin $remoteUrl

Write-Host "[4/5] Staging files and creating commit..." -ForegroundColor Yellow
git add .
git commit -m "Add RTL synthesis coding style optimization modules, HW1 report and testbench"

Write-Host "[5/5] Pushing to GitHub (origin main)..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSuccessfully connected and pushed to GitHub!" -ForegroundColor Green
} else {
    Write-Host "`nIf push was rejected because remote has existing commits, run:" -ForegroundColor Magenta
    Write-Host "git pull origin main --rebase" -ForegroundColor White
    Write-Host "git push -u origin main" -ForegroundColor White
}
