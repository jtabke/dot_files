return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format" },
				javascript = { "prettier" },
				css = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				json = { "prettier" },
				astro = { "prettier" },
			},
			-- format_on_save = false, -- Disable format on save
			format_on_save = {
				lsp_fallback = true,
				async = false,
				-- timeout_ms = 500,
			},
		})
		vim.keymap.set({ "n", "x" }, "<leader>f", function()
			conform.format({ async = true, lsp_fallback = true, timeout_ms = 500 })
		end, { desc = "Format buffer with conform.nvim" })
	end,
}
