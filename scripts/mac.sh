#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# === 0. Homebrew 체크 ===
echo -e "\n${CYAN}=== 0. Homebrew Check ===${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "  ${YELLOW}[!]${NC} Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon PATH
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if command -v brew &> /dev/null; then
        echo -e "  ${GREEN}[v]${NC} Homebrew installed."
    else
        echo -e "  ${RED}[x]${NC} Homebrew installation failed. Exiting."
        exit 1
    fi
else
    echo -e "  ${GREEN}[v]${NC} Homebrew is ready."
fi

# === 1. 앱 리스트 ===
# Type: brew / cask / manual
APP_NAMES=(
    "GNU Stow"
    "WezTerm"
    "Neovim"
    "Obsidian"
    "im-select"
)
APP_IDS=(
    "stow"
    "wezterm"
    "neovim"
    "obsidian"
    "im-select"
)
APP_TYPES=(
    "brew"
    "cask"
    "brew"
    "cask"
    "brew"
)
APP_CMDS=(
    "stow"
    "wezterm"
    "nvim"
    ""
    "im-select"
)

# --- 설치 상태 확인 ---
is_installed() {
    local idx=$1
    local type=${APP_TYPES[$idx]}
    local id=${APP_IDS[$idx]}
    local cmd=${APP_CMDS[$idx]}

    if [ "$type" = "cask" ]; then
        brew list --cask "$id" &> /dev/null
        return $?
    elif [ -n "$cmd" ]; then
        command -v "$cmd" &> /dev/null
        return $?
    else
        brew list "$id" &> /dev/null
        return $?
    fi
}

# --- 앱 설치 ---
install_app() {
    local idx=$1
    local type=${APP_TYPES[$idx]}
    local id=${APP_IDS[$idx]}

    if [ "$type" = "cask" ]; then
        brew install --cask "$id"
    else
        brew install "$id"
    fi
}

# === 메인 루프 ===
echo -e "\n${CYAN}=== 1. App Installation ===${NC}"

while true; do
    # 미설치 앱 수집
    uninstalled=()
    uninstalled_idx=()

    for i in "${!APP_NAMES[@]}"; do
        if is_installed "$i"; then
            echo -e "  ${GREEN}[v]${NC} ${APP_NAMES[$i]} is already installed."
        else
            uninstalled+=("${APP_NAMES[$i]}")
            uninstalled_idx+=("$i")
        fi
    done

    # 전부 설치됨
    if [ ${#uninstalled[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[!]${NC} All apps are already installed."
        break
    fi

    # 선택지 표시
    echo -e "\n${YELLOW}[ Available Apps to Install ]${NC}"
    for i in "${!uninstalled[@]}"; do
        echo "  ($((i + 1))) ${uninstalled[$i]}"
    done
    echo "  (A) Install All"
    echo "  (Q) Skip / Quit"

    read -rp $'\nSelect numbers to install (e.g. 1,3,4 or A): ' choice

    # Quit
    if [[ "$choice" =~ ^[Qq]$ ]] || [ -z "$choice" ]; then
        break
    fi

    # 대상 결정
    targets=()
    if [[ "$choice" =~ ^[Aa]$ ]]; then
        targets=("${uninstalled_idx[@]}")
    else
        IFS=',' read -ra indices <<< "$choice"
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#uninstalled[@]} ]; then
                targets+=("${uninstalled_idx[$((idx - 1))]}")
            fi
        done
    fi

    # 설치 실행
    for t in "${targets[@]}"; do
        echo -e "  ${YELLOW}[+]${NC} Installing ${APP_NAMES[$t]}..."
        install_app "$t"
    done

    echo ""
done

# === 2. 환경 설정 & 링크 ===
echo -e "\n${CYAN}=== 2. Environment Setup & Linking ===${NC}"

DOTFILES_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$DOTFILES_ROOT" || exit 1

# GNU Stow 필수 체크
if ! command -v stow &> /dev/null; then
    echo -e "  ${RED}[x]${NC} GNU Stow not found. Cannot link. Exiting."
    exit 1
fi

# [Task 1] ~/.config/ 하위 설정
mkdir -p ~/.config
stow -t ~/.config config
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}[v]${NC} Config files linked to ~/.config/"
else
    echo -e "  ${RED}[x]${NC} Error linking ~/.config/"
fi

# [Task 2] 홈 디렉토리 dotfiles
if [ -d "home" ]; then
    stow -t ~ home
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}[v]${NC} Home dotfiles linked to ~/"
    else
        echo -e "  ${RED}[x]${NC} Error linking home dotfiles"
    fi
else
    echo -e "  ${YELLOW}[!]${NC} 'home' directory not found. Skipping."
fi

echo -e "\n${CYAN}=== Complete ===${NC}\n"