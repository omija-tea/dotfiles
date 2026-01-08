# 색상 출력용 헬퍼 함수
function Show-Doctor($success, $name) {
    Write-Host "  [" -NoNewline
    if ($success) {
        Write-Host "✓" -ForegroundColor Green -NoNewline
        Write-Host "] $name 가 설치되어 있습니다."
    } else {
        Write-Host "✗" -ForegroundColor Red -NoNewline
        Write-Host "] $name 가 설치되어 있지 않습니다."
    }
}

Write-Host "`n=== Environment Doctor ==="

# 1. 의존성 진단
$stowInstalled = Get-Command "stow" -ErrorAction SilentlyContinue
Show-Doctor $stowInstalled "GNU Stow"

if (-not $stowInstalled) {
    Write-Host "`n[ERROR] GNU Stow는 필수 프로그램입니다." -ForegroundColor Red
    exit
}

Show-Doctor (Get-Command "wezterm" -ErrorAction SilentlyContinue) "WezTerm"
Show-Doctor (Get-Command "nvim" -ErrorAction SilentlyContinue) "Neovim"
$ahkInstalled = (Test-Path "C:\Program Files\AutoHotkey\AutoHotkey.exe") -or (Get-Command "AutoHotkey" -ErrorAction SilentlyContinue)
Show-Doctor $ahkInstalled "AutoHotkey"

Write-Host ""
Write-Host "설정 파일 연결 시작"

# 경로 계산 및 이동
$dotfilesPath = (Get-Item "$PSScriptRoot\..").FullName
$configPath = Join-Path $dotfilesPath "config"

# 환경 변수 설정
[System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $configPath, 'User')
Write-Host "  [" -NoNewline
Write-Host "✓" -ForegroundColor Green -NoNewline
Write-Host "] XDG_CONFIG_HOME 환경 변수 설정 완료"

# AHK 링크
$ahkSource = Join-Path $configPath "ahk\main.ahk"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ahkLink = Join-Path $startupFolder "main.ahk"

if (Test-Path $ahkSource) {
    if (Test-Path $ahkLink) { Remove-Item $ahkLink }
    New-Item -ItemType SymbolicLink -Path $ahkLink -Target $ahkSource | Out-Null
    Write-Host "  [" -NoNewline
    Write-Host "✓" -ForegroundColor Green -NoNewline
    Write-Host "] AutoHotkey 시작 프로그램 등록 완료"
}

Write-Host "=== Diagnosis Complete! Restart your terminal ===`n"
