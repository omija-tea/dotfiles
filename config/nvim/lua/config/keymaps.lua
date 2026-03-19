-- i: insert mode, jk: 입력할 키, <Esc>: 실행될 키

-- 1. jk 눌러서 일반모드로 탈출
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })

-- Neo-tree 단축키 추가
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Neo-tree" })
