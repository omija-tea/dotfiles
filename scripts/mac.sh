#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Color Reset

echo -e "\n=== Environment Doctor ==="

# 진단 함수
check_app() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} $2 is installed"
        return 0
    else
        echo -e "  ${RED}[✗]${NC} $2 is not installed"
        return 1
    fi
}

# 1. [필수] GNU Stow 체크
check_app "stow" "GNU Stow"
if [ $? -ne 0 ]; then
    echo -e "\n${RED}[ERROR] GNU Stow is essential program${NC}"
    exit 1
fi

# 2. 나머지 앱 진단
check_app "wezterm" "WezTerm"
check_app "nvim" "Neovim"

echo -e "\n--- Start Linking ---"

# 스크립트 위치와 상관없이 dotfiles 루트 디렉토리로 이동
DOTFILES_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$DOTFILES_ROOT"

# 목적지 디렉토리 생성
mkdir -p ~/.config

# [Task 1] ~/.config/ 하위로 들어갈 설정들
stow -t ~/.config config
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}[✓]${NC} Config files linked to ~/.config/"
else
    echo -e "  ${RED}[✗]${NC} Error linking ~/.config/"
fi

# [Task 2] 홈 디렉토리($HOME) 바로 아래로 들어갈 설정들 (.ideavimrc 등)
if [ -d "home" ]; then
    stow -t ~ home
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}[✓]${NC} Home dotfiles linked to ~/"
    else
        echo -e "  ${RED}[✗]${NC} Error linking home dotfiles"
    fi
else
    echo -e "  ${RED}[✗]${NC} 'home' directory not found"
fi

echo -e "\n=== Complete ===\n"
