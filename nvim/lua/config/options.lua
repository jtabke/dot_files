local opt = vim.opt -- For conciseness

-- Set hybrid absolute/relative line numbers
opt.number = true
opt.relativenumber = true

-- Show hybrid absolute/relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Show existing tab with 4 spaces width
vim.opt.tabstop = 4

-- When indenting with '>', use 4 spaces width
vim.opt.shiftwidth = 4

-- On pressing tab, insert 4 spaces
vim.opt.expandtab = true

-- Make backspace work like most other programs
-- vim.opt.backspace = '2' 

-- Use system clipboard
vim.opt.clipboard = 'unnamedplus'

-- Copy indent from current line when starting a new line
-- vim.opt.autoindent = true --already default in nvim

-- Enable mouse use
--vim.opt.mouse = 'a' --already default in nvim

-- Automatically set working directory to current file location
vim.opt.autochdir = true

-- Searches with no capitals are case insensitive, searches with caps are case-sensitive
vim.opt.smartcase = true
vim.opt.ignorecase = true
