local opt = vim.opt -- For conciseness

-- Set hybrid absolute/relative line numbers
opt.number = true
opt.relativenumber = true

-- Show hybrid absolute/relative line numbers
opt.number = true
opt.relativenumber = true

-- Show existing tab with 4 spaces width
opt.tabstop = 4

-- When indenting with '>', use 4 spaces width
opt.shiftwidth = 4

-- On pressing tab, insert 4 spaces
opt.expandtab = true

-- Make backspace work like most other programs
-- opt.backspace = '2'

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Copy indent from current line when starting a new line
-- opt.autoindent = true --already default in nvim

-- set termguicolors to enable highlight groups
opt.termguicolors = true

-- Enable mouse use
--opt.mouse = 'a' --already default in nvim

-- Default splits to the right
opt.splitright = true

-- Automatically set working directory to current file location
opt.autochdir = true

-- Searches with no capitals are case insensitive, searches with caps are case-sensitive
opt.smartcase = true
opt.ignorecase = true

-- display whitespace
opt.list = true
-- Define how special characters are displayed
-- WARNING: 'space:·' shows *every* space as '·', which is usually too noisy.
opt.listchars = "tab:| ,space:·"
-- opt.listchars = "tab:|"

-- Reload files on change automatically
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})
vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
	command = 'echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None',
	pattern = { "*" },
})
