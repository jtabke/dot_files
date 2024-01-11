-- change leader to space
vim.g.mapleader = " "

local keymap = vim.keymap --for conciseness

-- Split navigation
keymap.set("n", "<C-J>", "<C-W><C-J>")
keymap.set("n", "<C-K>", "<C-W><C-K>")
keymap.set("n", "<C-L>", "<C-W><C-L>")
keymap.set("n", "<C-H>", "<C-W><C-H>")

-- Split creation
keymap.set("n", "<leader>h", ":split<Space>")
keymap.set("n", "<leader>v", ":vsplit<Space>")

-- Save with leader S
keymap.set("n", "<Leader>s", ":update<CR>")

-- Edit c configuration file
keymap.set("n", "<Leader>ve", ":e $MYVIMRC<CR>")

-- Reload c configuration file
keymap.set("n", "<C-J>", "<C-W><C-J>")
keymap.set("n", "<C-K>", "<C-W><C-K>")
keymap.set("n", "<C-L>", "<C-W><C-L>")
keymap.set("n", "<C-H>", "<C-W><C-H>")

-- Split creation
keymap.set("n", "<leader>h", ":split<Space>")
keymap.set("n", "<leader>v", ":vsplit<Space>")

-- Easy buffer navigation
keymap.set("n", "<leader>l", ":ls<CR>")
keymap.set("n", "<leader>b", ":bp<CR>")
keymap.set("n", "<leader>n", ":bn<CR>")

-- Save with leader S
keymap.set("n", "<Leader>s", ":update<CR>")

-- Edit vimrc configuration file
keymap.set("n", "<Leader>ve", ":e $MYVIMRC<CR>")
-- Reload vimrc configuration file
keymap.set("n", "<Leader>vr", ":source $MYVIMRC<CR>")

-- Shortcut for file explorer
keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>")

-- Open links
--keymap.set("n", "gx", ":!xdg-open <cWORD><cr>")
