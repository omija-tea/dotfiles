return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- 테마는 가장 먼저 로드되어야 하므로 우선순위를 높게
  config = function()
    -- 1. Catppuccin 설정
    require("catppuccin").setup({
      flavour = "latte",
      background = { 
        light = "latte", 
        dark = "mocha" 
      },
      transparent_background = false, -- 배경 투명화
      show_end_of_buffer = false, -- 버퍼 끝의 '~' 표시 숨기기
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        -- 사용하는 다른 플러그인들이 생기면 여기서 true로
      },
    })

    -- 2. Neovim 배경 설정
    vim.opt.background = "light"

    -- 3. 테마 적용 실행
    vim.cmd.colorscheme "catppuccin"
  end,
}
