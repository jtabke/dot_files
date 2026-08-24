local ensure_installed = {
	"bash",
	"css",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

-- The main branch is a full, incompatible rewrite. Keep the legacy API pinned
-- to master until this configuration is deliberately migrated with its new
-- tree-sitter-cli requirement.
local treesitter_spec = {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = ensure_installed,
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}

return {
	treesitter_spec,
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
}
