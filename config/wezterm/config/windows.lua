local wezterm = require 'wezterm'
local act = wezterm.action
local config = {}

config.default_prog = { 'pwsh.exe', '-NoLogo' }
config.window_decorations = 'TITLE | RESIZE'

-- Windows 11 Acrylic 배경 (macOS의 window_background_blur에 대응)
config.win32_system_backdrop = 'Acrylic'
config.window_background_opacity = 0.9

-- 새 탭 드롭다운(+ 버튼)에서 고를 셸 목록. WSL 배포판은 설치되어 있으면
-- wezterm이 자동으로 감지해서 이 목록/도메인에 추가해주므로 따로 등록할 필요 없음.
config.launch_menu = {
  { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' } },
  { label = 'Command Prompt', args = { 'cmd.exe' } },
}

-- 스크롤바 + 스크롤백
config.enable_scroll_bar = true
config.scrollback_lines = 10000

-- 탭이 하나뿐일 땐 탭바 숨기기, 폰트 크기 바꿔도 창 크기 유지
config.hide_tab_bar_if_only_one_tab = true
config.adjust_window_size_when_changing_font_size = false

config.keys = {
  -- 붙여넣기. wezterm이 키를 먼저 처리하므로 로컬 pwsh든 ssh 세션이든 동일하게 동작한다.
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

  -- 선택 영역이 있으면 복사, 없으면 Ctrl+C를 그대로 전달해 SIGINT를 살려둔다.
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local selection = window:get_selection_text_for_pane(pane)
      if selection and selection ~= '' then
        window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },

  -- pane 분할 (좌우: Alt+Shift+D, 상하: Ctrl+Shift+Alt+D)
  { key = 'd', mods = 'ALT', action = act.SplitPane { direction = 'Right' } },
  { key = 'd', mods = 'SHIFT|ALT', action = act.SplitPane { direction = 'Down' } },

  -- pane 이동 (vim 스타일)
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- pane 크기 조절
  { key = 'LeftArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },

  -- pane 줌 토글 / 닫기
  { key = 'z', mods = 'ALT|SHIFT', action = act.TogglePaneZoomState },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
}

return config