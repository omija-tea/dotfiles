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
$homeDotfilesPath = Join-Path $dotfilesPath "home"  # 새롭게 추가된 home 폴더 경로

# 4. XDG_CONFIG_HOME 환경 변수 설정
try {
    [System.Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $configPath, 'User')
    Write-Host "  [v] " -ForegroundColor Green -NoNewline
    Write-Host "XDG_CONFIG_HOME set to $configPath"
} catch {
    Write-Host "  [x] " -ForegroundColor Red -NoNewline
    Write-Host "Failed to set environment variable"
}

# 5. Home 폴더 내 파일들 연결 (.ideavimrc 등)
if (Test-Path $homeDotfilesPath) {
    # home 폴더 안의 모든 파일들을 순회 (숨김 파일 포함)
    $files = Get-ChildItem -Path $homeDotfilesPath -Force
    foreach ($file in $files) {
        $targetPath = Join-Path $HOME $file.Name
        
        # 기존 파일이나 링크가 있으면 삭제 (Mac의 rm -f와 동일 효과)
        if (Test-Path $targetPath) {
            Remove-Item $targetPath -Force -ErrorAction SilentlyContinue
        }

        try {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $file.FullName -ErrorAction Stop | Out-Null
            Write-Host "  [v] " -ForegroundColor Green -NoNewline
            Write-Host "$($file.Name) linked to $HOME"
        } catch {
            Write-Host "  [x] " -ForegroundColor Red -NoNewline
            Write-Host "Failed to link $($file.Name): Please run PowerShell as ADMIN"
        }
    }
}

# 6. AutoHotkey 시작 프로그램 등록
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

        # AHK 실행 (이미 실행 중일 수 있으므로 주의)
        Start-Process $ahkLink
        Write-Host "  [v] " -ForegroundColor Green -NoNewline
        Write-Host "AutoHotkey has been started"
    } catch {
        Write-Host "  [x] " -ForegroundColor Red -NoNewline
        Write-Host "AutoHotkey link failed: Please run PowerShell as ADMIN"
    }
}

Write-Host "`n=== Complete ===`n" -ForegroundColor Cyan
