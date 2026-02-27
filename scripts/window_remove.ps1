# 0. 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 관리 대상 프로그램 리스트
$apps = @(
    @{ Name = "IntelliJ IDEA"; ID = "JetBrains.IntelliJIDEA" }
    @{ Name = "Logi Options+"; ID = "Logitech.OptionsPlus" }
    @{ Name = "AutoHotkey";    ID = "AutoHotkey.AutoHotkey" }
    @{ Name = "Obsidian";      ID = "Obsidian.Obsidian" }
    @{ Name = "WezTerm";       ID = "wezterm.wezterm" }
    @{ Name = "Neovim";        ID = "Neovim.Neovim" }
)

Write-Host "`n=== 1. Installed App Check ===" -ForegroundColor Cyan

# 2. 현재 설치된 프로그램 확인
$installedApps = New-Object System.Collections.Generic.List[PSCustomObject]

foreach ($app in $apps) {
    winget list --id $($app.ID) -e --source winget > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $installedApps.Add($app)
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "$($app.Name) is found and ready to uninstall."
    }
}

# 3. CLI 기반 삭제 선택
if ($installedApps.Count -gt 0) {
    Write-Host "`n[ Apps to Uninstall ]" -ForegroundColor Red
    for ($i = 0; $i -lt $installedApps.Count; $i++) {
        Write-Host "  ($($i + 1)) $($installedApps[$i].Name)"
    }
    Write-Host "  (A) Uninstall All"
    Write-Host "  (Q) Quit"

    $choice = Read-Host "`nSelect numbers to uninstall (e.g. 1,2 or A)"
    $targets = @()

    if ($choice -eq 'A' -or $choice -eq 'a') {
        $targets = $installedApps
    } elseif ($choice -ne 'Q' -and $choice -ne 'q') {
        $indices = $choice.Split(',').Trim()
        foreach ($idx in $indices) {
            if ([int]::TryParse($idx, [ref]$n) -and $n -le $installedApps.Count) {
                $targets += $installedApps[$n-1]
            }
        }
    }

    # 삭제 실행
    foreach ($item in $targets) {
        Write-Host "  [-] " -ForegroundColor Red -NoNewline
        Write-Host "Uninstalling $($item.Name)..."
        # --silent 옵션으로 삭제 진행
        winget uninstall --id $item.ID --silent --accept-source-agreements > $null
    }
} else {
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host "No managed apps found to uninstall."
}

# 4. 심볼릭 링크 정리 (선택 사항)
Write-Host "`n=== 2. Cleanup symbolic links? ===" -ForegroundColor Cyan
$cleanLinks = Read-Host "Do you want to remove created symbolic links in HOME? (y/n)"

if ($cleanLinks -eq 'y' -or $cleanLinks -eq 'Y') {
    $homeDotfilesPath = Join-Path (Get-Item "$PSScriptRoot\..").FullName "home"
    if (Test-Path $homeDotfilesPath) {
        $files = Get-ChildItem -Path $homeDotfilesPath -Force
        foreach ($file in $files) {
            $targetPath = Join-Path $HOME $file.Name
            if (Test-Path $targetPath) {
                Remove-Item $targetPath -Force -ErrorAction SilentlyContinue
                Write-Host "  [v] " -ForegroundColor Green -NoNewline
                Write-Host "Removed link: $($file.Name)"
            }
        }
    }
    
    # AHK 시작프로그램 링크 삭제
    $ahkLink = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\autohotkey.ahk"
    if (Test-Path $ahkLink) {
        Remove-Item $ahkLink -Force
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "Removed AutoHotkey startup link"
    }
}

Write-Host "`n=== Uninstall Process Complete ===`n" -ForegroundColor Cyan