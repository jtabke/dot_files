return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	keys = {
		{
			"<leader>ac",
			"<cmd>CodeCompanionChat Toggle<CR>",
			mode = { "n", "v" },
			desc = "Toggle CodeCompanion chat",
		},
		{
			"<leader>at",
			"<cmd>CodeCompanionAction<CR>",
			mode = { "n", "v" },
			desc = "CodeCompanion action",
		},
	},
	opts = {
		strategies = {
			chat = {
				adapter = {
					name = "ollama",
					-- model = "qwen3:30b-a3b",
					model = "deepseek-r1:14b",
				},
			},
		},
	},
}
