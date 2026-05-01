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

-- Switching Neovim versions: lazy.nvim won't auto-swap branches.
-- Run `:Lazy clean nvim-treesitter` then `:Lazy sync` after upgrading/downgrading.
-- 0.12+ also requires `tree-sitter-cli` (>=0.26.1) on PATH:
--   macOS:        brew install tree-sitter-cli
--   Arch:         pacman -S tree-sitter-cli
--   Linux (any):  brew install tree-sitter-cli  OR  cargo install tree-sitter-cli
--                 OR download from github.com/tree-sitter/tree-sitter/releases
--   Do NOT use `npm install -g tree-sitter-cli` — npm build lacks features.
local is_nvim_012 = vim.fn.has("nvim-0.12") == 1

local treesitter_spec
if is_nvim_012 then
	treesitter_spec = {
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})
			require("nvim-treesitter").install(ensure_installed)

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					if pcall(vim.treesitter.start, args.buf) then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	}
else
	treesitter_spec = {
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
end

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
