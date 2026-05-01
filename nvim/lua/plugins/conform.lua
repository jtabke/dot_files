return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_organize_imports", "ruff_format" },
				javascript = { "prettier" },
				css = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				json = { "prettier" },
				astro = { "prettier" },
			},
			format_on_save = {
				lsp_format = "fallback",
				async = false,
				timeout_ms = 1000,
			},
		})
	end,
}
