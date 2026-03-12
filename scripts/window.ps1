# 0. 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 프로그램 리스트 (winget + 수동 다운로드 통합)
$apps = @(
    @{ Name = "IntelliJ IDEA"; ID = "JetBrains.IntelliJIDEA"; Type = "winget" }
    @{ Name = "Logi Options+"; ID = "Logitech.OptionsPlus";   Type = "winget" }
    @{ Name = "AutoHotkey";    ID = "AutoHotkey.AutoHotkey";   Type = "winget" }
    @{ Name = "Obsidian";      ID = "Obsidian.Obsidian";       Type = "winget" }
    @{ Name = "WezTerm";       ID = "wezterm.wezterm";         Type = "winget" }
    @{ Name = "Neovim";        ID = "Neovim.Neovim";           Type = "winget" }
    @{ Name = "im-select";     ID = "";                        Type = "manual"
       Url  = "https://github.com/daipeihust/im-select/raw/master/win/out/x64/im-select.exe"
       Dest = "$env:USERPROFILE\bin\im-select.exe" }
)

# --- 설치 상태 확인 함수 ---
function Test-AppInstalled($app) {
    if ($app.Type -eq "winget") {
        winget list --id $($app.ID) -e --source winget > $null 2>&1
        return ($LASTEXITCODE -eq 0)
    } else {
        return (Test-Path $app.Dest)
    }
}

# --- 앱 설치 함수 ---
function Install-App($app) {
    if ($app.Type -eq "winget") {
        winget install --id $app.ID --silent --accept-package-agreements --accept-source-agreements
    } else {
        $dest = $app.Dest
        $dir = Split-Path $dest -Parent
        mkdir $dir -Force > $null
        Invoke-WebRequest -Uri $app.Url -OutFile $dest

        # PATH에 추가
        if ($env:PATH -notlike "*$dir*") {
            $env:PATH += ";$dir"
            [Environment]::SetEnvironmentVariable("PATH",
                [Environment]::GetEnvironmentVariable("PATH", "User") + ";$dir",
                "User")
        }

        if (Test-Path $dest) {
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "Downloaded to $dest"
        } else {
            Write-Host "  [x] " -ForegroundColor Red -NoNewline
            Write-Host "Download failed."
        }
    }
}

# === 메인 루프 ===
Write-Host "`n=== 1. App Installation ===" -ForegroundColor Cyan

while ($true) {
    # 미설치 앱 감지
    $uninstalledApps = New-Object System.Collections.Generic.List[PSCustomObject]

    foreach ($app in $apps) {
        if (Test-AppInstalled $app) {
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "$($app.Name) is already installed."
        } else {
            $uninstalledApps.Add($app)
        }
    }

    # 전부 설치됨 → 루프 탈출
    if ($uninstalledApps.Count -eq 0) {
        Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
        Write-Host "All apps are already installed."
        break
    }

    # 선택지 표시
    Write-Host "`n[ Available Apps to Install ]" -ForegroundColor Yellow
    for ($i = 0; $i -lt $uninstalledApps.Count; $i++) {
        $tag = if ($uninstalledApps[$i].Type -eq "manual") { " (direct download)" } else { "" }
        Write-Host "  ($($i + 1)) $($uninstalledApps[$i].Name)$tag"
    }
    Write-Host "  (A) Install All"
    Write-Host "  (Q) Skip / Quit"

    $choice = Read-Host "`nSelect numbers to install (e.g. 1,3,4 or A)"

    # Quit
    if ($choice -eq 'Q' -or $choice -eq 'q' -or [string]::IsNullOrWhiteSpace($choice)) {
        break
    }

    # 대상 결정
    $targets = @()
    $n = 0

    if ($choice -eq 'A' -or $choice -eq 'a') {
        $targets = $uninstalledApps
    } else {
        $indices = $choice.Split(',').Trim()
        foreach ($idx in $indices) {
            if ([int]::TryParse($idx, [ref]$n) -and $n -gt 0 -and $n -le $uninstalledApps.Count) {
                $targets += $uninstalledApps[$n - 1]
            }
        }
    }

    # 설치 실행
    foreach ($item in $targets) {
        Write-Host "  [+] " -ForegroundColor Yellow -NoNewline
        Write-Host "Installing $($item.Name)..."
        Install-App $item
    }

    Write-Host ""
}

Write-Host "`n=== 2. Environment Setup & Linking ===" -ForegroundColor Cyan

# 4. 경로 계산
$dotfilesPath = (Get-Item "$PSScriptRoot\..").FullName
$configPath = Join-Path $dotfilesPath "config"
$homeDotfilesPath = Join-Path $dotfilesPath "home"

# 5. XDG_CONFIG_HOME 설정
try {
    [System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $configPath, 'User')
    Write-Host "  [v] " -ForegroundColor Green -NoNewline
    Write-Host "XDG_CONFIG_HOME set to $configPath"
} catch {
    Write-Host "  [x] " -ForegroundColor Red -NoNewline
    Write-Host "Failed to set XDG_CONFIG_HOME"
}

# 6. Home 폴더 파일 심볼릭 링크
if (Test-Path $homeDotfilesPath) {
    $files = Get-ChildItem -Path $homeDotfilesPath -Force
    foreach ($file in $files) {
        $targetPath = Join-Path $HOME $file.Name
        if (Test-Path $targetPath) { Remove-Item $targetPath -Force -Recurse -ErrorAction SilentlyContinue }
        try {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $file.FullName -ErrorAction Stop | Out-Null
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "Linked: $($file.Name)"
        } catch {
            Write-Host "  [x] " -ForegroundColor Red -NoNewline
            Write-Host "Link failed: $($file.Name)"
        }
    }
}

# 7. AutoHotkey 시작 프로그램 등록 및 실행
$ahkSource = Join-Path $configPath "ahk\autohotkey.ahk"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ahkLink = Join-Path $startupFolder "autohotkey.ahk"

if (Test-Path $ahkSource) {
    if (Test-Path $ahkLink) { Remove-Item $ahkLink -Force }
    try {
        $ahkExe = (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue).Source
        if (-not $ahkExe) { $ahkExe = (Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue).Source }

        $ahkPaths = @(
            "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
            "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
            "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe"
        )

        if (-not $ahkExe) {
            foreach ($path in $ahkPaths) {
                if (Test-Path $path) { $ahkExe = $path; break }
            }
        }

        if ($ahkExe) {
            New-Item -ItemType SymbolicLink -Path $ahkLink -Target $ahkSource -ErrorAction Stop | Out-Null
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "AutoHotkey added to startup (Path: $ahkExe)"

            Start-Process $ahkExe -ArgumentList "`"$ahkSource`""
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "AutoHotkey has been started"
        } else {
            Write-Host "  [x] " -ForegroundColor Red -NoNewline
            Write-Host "AutoHotkey executable not found in PATH or Program Files."
        }
    } catch {
        Write-Host "  [x] " -ForegroundColor Red -NoNewline
        Write-Host "AutoHotkey setup failed: $($_.Exception.Message)"
    }
}

Write-Host "`n=== Complete ===`n" -ForegroundColor Cyan