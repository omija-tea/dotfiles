return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      -- neo-tree 기본 설정
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = { enabled = true }, -- 현재 파일을 탐색기에서 자동으로 찾아줌
          filtered_items = {
            hide_dotfiles = false, -- 숨김 파일도 보이게
            hide_gitignored = false, -- git ignore 된 파일도 보이게
          },
        },
        window = {
          width = 30,
        }
      })
   end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
