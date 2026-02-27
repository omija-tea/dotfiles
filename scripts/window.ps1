# 0. 인코딩 설정
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 프로그램 리스트
$apps = @(
    @{ Name = "IntelliJ IDEA"; ID = "JetBrains.IntelliJIDEA" }
    @{ Name = "Logi Options+"; ID = "Logitech.OptionsPlus" }
    @{ Name = "AutoHotkey";    ID = "AutoHotkey.AutoHotkey" }
    @{ Name = "Obsidian";      ID = "Obsidian.Obsidian" }
    @{ Name = "WezTerm";       ID = "wezterm.wezterm" }
    @{ Name = "Neovim";        ID = "Neovim.Neovim" }
)

Write-Host "`n=== 1. App Installation Check ===" -ForegroundColor Cyan

# 2. 미설치 프로그램 감지 및 목록 생성
$uninstalledApps = New-Object System.Collections.Generic.List[PSCustomObject]

foreach ($app in $apps) {
    winget list --id $($app.ID) -e --source winget > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        $uninstalledApps.Add($app)
    } else {
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "$($app.Name) is already installed."
    }
}

# 3. CLI 기반 설치 선택
if ($uninstalledApps.Count -gt 0) {
    Write-Host "`n[ Available Apps to Install ]" -ForegroundColor Yellow
    for ($i = 0; $i -lt $uninstalledApps.Count; $i++) {
        Write-Host "  ($($i + 1)) $($uninstalledApps[$i].Name)"
    }
    Write-Host "  (A) Install All"
    Write-Host "  (Q) Skip / Quit"

    $choice = Read-Host "`nSelect numbers to install (e.g. 1,3,4 or A)"
    $targets = @()

    if ($choice -eq 'A' -or $choice -eq 'a') {
        $targets = $uninstalledApps
    } elseif ($choice -ne 'Q' -and $choice -ne 'q') {
        $indices = $choice.Split(',').Trim()
        foreach ($idx in $indices) {
            if ([int]::TryParse($idx, [ref]$n) -and $n -le $uninstalledApps.Count) {
                $targets += $uninstalledApps[$n-1]
            }
        }
    }

    # 설치 실행
    foreach ($item in $targets) {
        Write-Host "  [+] " -ForegroundColor Yellow -NoNewline
        Write-Host "Installing $($item.Name)..."
        winget install --id $item.ID --silent --accept-package-agreements --accept-source-agreements > $null
    }
} else {
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host "All apps are already installed."
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

        if ($ahkExe) {
            New-Item -ItemType SymbolicLink -Path $ahkLink -Target $ahkSource -ErrorAction Stop | Out-Null
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "AutoHotkey added to startup"
            
            Start-Process $ahkExe -ArgumentList "`"$ahkSource`""
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "AutoHotkey has been started"
        }
    } catch {
        Write-Host "  [x] " -ForegroundColor Red -NoNewline
        Write-Host "AutoHotkey setup failed"
    }
}

Write-Host "`n=== Complete ===`n" -ForegroundColor Cyan