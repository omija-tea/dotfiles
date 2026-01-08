# 0. 인코딩 설정 (UTF-8 및 콘솔 출력 고정)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 색상 출력용 헬퍼 함수
function Show-Doctor($success, $name) {
    if ($success) {
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "$name is installed"
    } else {
        Write-Host "  [x] " -ForegroundColor Red -NoNewline
        Write-Host "$name is not installed"
    }
}

Write-Host "`n=== Windows Environment Doctor ===" -ForegroundColor Cyan

# 2. 프로그램 진단
Show-Doctor (Get-Command "wezterm" -ErrorAction SilentlyContinue) "WezTerm"
Show-Doctor (Get-Command "nvim" -ErrorAction SilentlyContinue) "Neovim"

$ahk1 = Test-Path "C:\Program Files\AutoHotkey\AutoHotkey.exe"
$ahk2 = Test-Path "$env:LOCALAPPDATA\Programs\AutoHotkey\AutoHotkey.exe"
$ahk3 = Test-Path "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$ahk4 = Get-Command "AutoHotkey" -ErrorAction SilentlyContinue
$ahkInstalled = $ahk1 -or $ahk2 -or $ahk3 -or $ahk4
Show-Doctor $ahkInstalled "AutoHotkey"

Write-Host "`nStart linking config..." -ForegroundColor Cyan

# 3. 경로 계산
$dotfilesPath = (Get-Item "$PSScriptRoot\..").FullName
$configPath = Join-Path $dotfilesPath "config"

# 4. XDG_CONFIG_HOME 환경 변수 설정
try {
    [System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $configPath, 'User')
    Write-Host "  [v] " -ForegroundColor Green -NoNewline
    Write-Host "XDG_CONFIG_HOME set complete"
} catch {
    Write-Host "  [x] " -ForegroundColor Red -NoNewline
    Write-Host "Failed to set environment variable"
}

# 5. AutoHotkey 시작 프로그램 등록
$ahkSource = Join-Path $configPath "ahk\autohotkey.ahk"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ahkLink = Join-Path $startupFolder "autohotkey.ahk"

if (Test-Path $ahkSource) {
    if (Test-Path $ahkLink) { 
        Remove-Item $ahkLink -Force -ErrorAction SilentlyContinue 
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $ahkLink -Target $ahkSource -ErrorAction Stop | Out-Null
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "AutoHotkey added to startup"

        Start-Process $ahkLink
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "AutoHotkey has been started"
    } catch {
        Write-Host "  [x] " -ForegroundColor Red -NoNewline
        Write-Host "AutoHotkey link failed: Please run PowerShell as ADMIN"
    }
}

Write-Host "`n=== Complete ===`n" -ForegroundColor Cyan
