local config = function()
	require("nvim-treesitter.configs").setup({
		indent = {
			enable = true,
		},
		-- autotag = {
		-- 	--enable = true,
		-- },
		ensure_installed = {
			"markdown",
			"json",
			"javascript",
			"typescript",
			"yaml",
			"html",
			"css",
			"bash",
			"lua",
			"python",
		},
		auto_install = true,
		highlight = {
			enable = true,
		},
	})
	require("nvim-ts-autotag").setup()
end

return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = config,
}
