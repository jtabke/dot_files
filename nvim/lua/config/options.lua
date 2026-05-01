local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation defaults
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Avoid changing cwd on every buffer; LSP/Telescope/nvim-tree work better from project roots.
-- opt.autochdir = true

-- Search: lowercase searches ignore case; uppercase searches are case-sensitive.
opt.ignorecase = true
opt.smartcase = true

-- Whitespace display: show tabs/trailing spaces without marking every normal space.
opt.list = true
opt.listchars = {
	tab = "| ",
	trail = "·",
	nbsp = "␣",
}

-- Quality of life
opt.undofile = true
opt.updatetime = 250
