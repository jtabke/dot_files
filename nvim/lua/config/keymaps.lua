-- Change leader to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap.set

-- Split navigation
keymap("n", "<C-j>", "<C-w><C-j>", { desc = "Move to split below" })
keymap("n", "<C-k>", "<C-w><C-k>", { desc = "Move to split above" })
keymap("n", "<C-l>", "<C-w><C-l>", { desc = "Move to split right" })
keymap("n", "<C-h>", "<C-w><C-h>", { desc = "Move to split left" })

-- Split creation. Keep these off <leader>h because gitsigns uses <leader>h... mappings.
keymap("n", "<leader>sh", "<cmd>split<CR>", { desc = "Horizontal split" })
keymap("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })

-- Buffers
keymap("n", "<leader>l", "<cmd>ls<CR>", { desc = "List buffers" })
keymap("n", "<leader>b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<leader>n", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Config
keymap("n", "<leader>s", "<cmd>update<CR>", { desc = "Save file" })
keymap("n", "<leader>ve", "<cmd>edit $MYVIMRC<CR>", { desc = "Edit Neovim config" })
keymap("n", "<leader>vr", "<cmd>source $MYVIMRC<CR>", { desc = "Reload Neovim config" })

-- Notes
keymap("n", "<leader>ww", "<cmd>edit ~/Documents/Notes<CR>", { desc = "Open notes" })

-- File explorer
keymap("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
