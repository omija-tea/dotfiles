#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Color Reset

echo -e "\n=== Environment Doctor ==="

# 진단 함수
check_app() {
    if command -v "$1" &> /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} $2 가 설치되어 있습니다."
        return 0
    else
        echo -e "  ${RED}[✗]${NC} $2 가 설치되어 있지 않습니다."
        return 1
    fi
}

# 1. [필수] GNU Stow 체크
check_app "stow" "GNU Stow"
if [ $? -ne 0 ]; then
    echo -e "\n${RED}[ERROR] GNU Stow는 필수 프로그램입니다.${NC}"
    exit 1
fi

# 2. 나머지 앱 진단
check_app "wezterm" "WezTerm"
check_app "nvim" "Neovim"

echo ""
echo "설정 파일 연결을 시작"

# 경로 이동 (Scripts 폴더 기준 한 단계 위)
cd "$(dirname "$0")/.."
mkdir -p ~/.config

# 설정 연결
stow -t ~/.config config

if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}[✓]${NC} 심볼릭 링크 연결 완료 (~/.config/)"
else
    echo -e "  ${RED}[✗]${NC} 링크 연결 중 오류 발생"
fi

echo -e "=== Complete ===\n"
