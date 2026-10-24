local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if vim.fn.has("nvim-0.11.3") == 0 then
	vim.notify("This configuration requires Neovim >= 0.11.3. Run dotfiles-setup --check.", vim.log.levels.ERROR)
	return
end
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		vim.notify("Plugin manager download failed. Check Git/network access, then retry Neovim.", vim.log.levels.ERROR)
		return
	end
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
