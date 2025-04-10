local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
	install = {
		--    colorscheme = { "catppuccin" },
	},
}

require("lazy").setup("plugins", opts)

require("colorizer").setup({
    css = { rgb_fn = true; }; -- Enable parsing rgb(...) functions in css.
})
