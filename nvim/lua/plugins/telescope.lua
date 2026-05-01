return {
	"nvim-telescope/telescope.nvim",
	tag = "v0.2.1",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find file" },
	},
	config = function()
		require("telescope").setup({})
	end,
}
