return {
	"brenoprata10/nvim-highlight-colors",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		render = "background",
		enable_named_colors = false,
		enable_tailwind = false,
	},
}
