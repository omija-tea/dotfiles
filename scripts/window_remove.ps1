# 0. 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 관리 대상 프로그램 리스트
$apps = @(
    @{ Name = "IntelliJ IDEA"; ID = "JetBrains.IntelliJIDEA"; Type = "winget" }
    @{ Name = "Logi Options+"; ID = "Logitech.OptionsPlus";   Type = "winget" }
    @{ Name = "AutoHotkey";    ID = "AutoHotkey.AutoHotkey";   Type = "winget" }
    @{ Name = "Obsidian";      ID = "Obsidian.Obsidian";       Type = "winget" }
    @{ Name = "WezTerm";       ID = "wezterm.wezterm";         Type = "winget" }
    @{ Name = "Neovim";        ID = "Neovim.Neovim";           Type = "winget" }
    @{ Name = "CF Warp";       ID = "Cloudflare.Warp";         Type = "winget" }
    @{ Name = "im-select";     ID = "";                        Type = "manual"
       Dest = "$env:USERPROFILE\bin\im-select.exe" }
    @{ Name = "Claude Code";   ID = "";                        Type = "script"
       CheckPath = "$env:USERPROFILE\.local\bin\claude.exe"
       ExtraDirs = @("$env:USERPROFILE\.local\share\claude") }
)

# --- 설치 상태 확인 함수 ---
function Test-AppInstalled($app) {
    switch ($app.Type) {
        "winget" {
            winget list --id $($app.ID) -e --source winget > $null 2>&1
            return ($LASTEXITCODE -eq 0)
        }
        "manual" {
            return (Test-Path $app.Dest)
        }
        "script" {
            return (Test-Path $app.CheckPath)
        }
    }
}

# --- 앱 삭제 함수 ---
function Uninstall-App($app) {
    switch ($app.Type) {
        "winget" {
            winget uninstall --id $app.ID --silent --accept-source-agreements > $null
        }
        "manual" {
            $dest = $app.Dest
            Remove-Item $dest -Force -ErrorAction SilentlyContinue

            # bin 폴더가 비었으면 같이 삭제 + PATH 정리
            $dir = Split-Path $dest -Parent
            if ((Get-ChildItem $dir -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                Remove-Item $dir -Force -ErrorAction SilentlyContinue
                Write-Host "  [v] " -ForegroundColor Green -NoNewline
                Write-Host "Removed empty directory: $dir"
            }
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -like "*$dir*") {
                $newPath = ($userPath.Split(';') | Where-Object { $_ -ne $dir }) -join ';'
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                Write-Host "  [v] " -ForegroundColor Green -NoNewline
                Write-Host "Removed from PATH: $dir"
            }
        }
        "script" {
            # 실행 파일 삭제
            $exe = $app.CheckPath
            if (Test-Path $exe) {
                Remove-Item $exe -Force -ErrorAction SilentlyContinue
                Write-Host "  [v] " -ForegroundColor Green -NoNewline
                Write-Host "Removed: $exe"
            }

            # bin 폴더가 비었으면 함께 삭제
            $binDir = Split-Path $exe -Parent
            if (Test-Path $binDir) {
                if ((Get-ChildItem $binDir -Force -ErrorAction SilentlyContinue).Count -eq 0) {
                    Remove-Item $binDir -Force -ErrorAction SilentlyContinue
                    Write-Host "  [v] " -ForegroundColor Green -NoNewline
                    Write-Host "Removed empty directory: $binDir"
                }
            }

            # 추가 디렉토리 삭제 (share 폴더 등)
            if ($app.ExtraDirs) {
                foreach ($dir in $app.ExtraDirs) {
                    if (Test-Path $dir) {
                        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [v] " -ForegroundColor Green -NoNewline
                        Write-Host "Removed directory: $dir"
                    }
                }
            }
        }
    }
}

# === 메인 루프 ===
Write-Host "`n=== 1. App Uninstall ===" -ForegroundColor Cyan

while ($true) {
    # 설치된 앱 감지
    $installedApps = New-Object System.Collections.Generic.List[PSCustomObject]

    foreach ($app in $apps) {
        if (Test-AppInstalled $app) {
            $installedApps.Add($app)
        }
    }

    # 설치된 앱 없음 → 루프 탈출
    if ($installedApps.Count -eq 0) {
        Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
        Write-Host "No managed apps found."
        break
    }

    # 현재 설치된 앱 표시
    Write-Host "`n[ Installed Apps ]" -ForegroundColor Red
    for ($i = 0; $i -lt $installedApps.Count; $i++) {
        $tag = switch ($installedApps[$i].Type) {
            "manual" { " (direct download)" }
            "script" { " (install script)" }
            default  { "" }
        }
        Write-Host "  ($($i + 1)) $($installedApps[$i].Name)$tag"
    }
    Write-Host "  (A) Uninstall All"
    Write-Host "  (Q) Quit"

    $choice = Read-Host "`nSelect numbers to uninstall (e.g. 1,2 or A)"

    # Quit
    if ($choice -eq 'Q' -or $choice -eq 'q' -or [string]::IsNullOrWhiteSpace($choice)) {
        break
    }

    # 대상 결정
    $targets = @()
    $n = 0

    if ($choice -eq 'A' -or $choice -eq 'a') {
        $targets = $installedApps
    } else {
        $indices = $choice.Split(',').Trim()
        foreach ($idx in $indices) {
            if ([int]::TryParse($idx, [ref]$n) -and $n -gt 0 -and $n -le $installedApps.Count) {
                $targets += $installedApps[$n - 1]
            } else {
                Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
                Write-Host "Invalid selection: $idx"
            }
        }
    }

    # 삭제 실행
    foreach ($item in $targets) {
        Write-Host "  [-] " -ForegroundColor Red -NoNewline
        Write-Host "Uninstalling $($item.Name)..."
        Uninstall-App $item
    }

    Write-Host ""
}

# 2. 심볼릭 링크 정리
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