local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local opts = {
	-- No current plugins require luarocks; disabling avoids hererocks health warnings.
	rocks = {
		enabled = false,
	},
	install = {
		colorscheme = { "catppuccin" },
	},
}

require("lazy").setup("plugins", opts)
