return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettier" },
				css = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				json = { "prettier" },
				astro = { "prettier" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				-- timeout_ms = 500,
			},
		})
	end,
}
