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

echo ""
echo "start linking config"

# 경로 이동 (Scripts 폴더 기준 한 단계 위)
cd "$(dirname "$0")/.."
mkdir -p ~/.config

# 설정 연결
stow -t ~/.config config

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}[✓]${NC} link complete (~/.config/)"
else
    echo -e "  ${RED}[✗]${NC} error linking config"
fi

echo -e "=== Complete ===\n"
