# Auto Git Sync Watcher for IP HW Project
$repoPath = $PSScriptRoot
Set-Location $repoPath

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  🚀 Auto Git Sync Watcher Started!                       " -ForegroundColor Green
Write-Host "  專案目錄: $repoPath" -ForegroundColor Gray
Write-Host "  只要有任何檔案被修改或建立，本視窗將自動推送至 GitHub！" -ForegroundColor Yellow
Write-Host "  (你可以將此視窗縮小，讓它在背景常駐)" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repoPath
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$lastSyncTime = [DateTime]::MinValue
$syncDelaySeconds = 3

$syncAction = {
    $now = Get-Date
    if (($now - $global:lastSyncTime).TotalSeconds -lt $syncDelaySeconds) {
        return
    }
    $global:lastSyncTime = $now
    Start-Sleep -Seconds 2

    # Check for git changes
    $status = git status --porcelain
    if ($status) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "`n[$timestamp] 偵測到檔案變更，正在自動同步至 GitHub..." -ForegroundColor Yellow
        git add .
        git commit -m "Auto sync: $timestamp"
        $pushResult = git push origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$timestamp] ✅ 成功自動推送到 GitHub！" -ForegroundColor Green
        } else {
            Write-Host "[$timestamp] ⚠️ 推送失敗，稍後有變動將自動重試：`n$pushResult" -ForegroundColor Red
        }
    }
}

$createdEvent = Register-ObjectEvent $watcher "Created" -Action $syncAction
$changedEvent = Register-ObjectEvent $watcher "Changed" -Action $syncAction
$deletedEvent = Register-ObjectEvent $watcher "Deleted" -Action $syncAction

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Unregister-Event $createdEvent.Id
    Unregister-Event $changedEvent.Id
    Unregister-Event $deletedEvent.Id
    $watcher.Dispose()
}
