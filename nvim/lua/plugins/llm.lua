local function local_llm_streaming_handler(chunk, ctx, F)
	if not chunk then
		return ctx.assistant_output
	end
	local tail = chunk:sub(-1, -1)
	if tail:sub(1, 1) ~= "}" then
		ctx.line = ctx.line .. chunk
	else
		ctx.line = ctx.line .. chunk
		local status, data = pcall(vim.fn.json_decode, ctx.line)
		if not status or not data.message.content then
			return ctx.assistant_output
		end
		ctx.assistant_output = ctx.assistant_output .. data.message.content
		F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
		ctx.line = ""
	end
	return ctx.assistant_output
end

local function local_llm_parse_handler(chunk)
	local assistant_output = chunk.message.content
	return assistant_output
end

return {
	{
		"Kurama622/llm.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
		cmd = { "LLMSessionToggle", "LLMSelectedTextHandler" },
		config = function()
			local tools = require("llm.tools")
			vim.env.LLM_KEY = "" -- Set llm_key to an empty string
			require("llm").setup({
				url = "http://localhost:11434/api/chat", -- your url
				model = "qwen2.5-coder:14b",
				streaming_handler = local_llm_streaming_handler,
				app_handler = {
					Ask = {
						handler = tools.disposable_ask_handler,
						opts = {
							position = {
								row = 2,
								col = 0,
							},
							title = " Ask ",
						},
					},
					CodeExplain = {
						handler = tools.flexi_handler,
						prompt = "Explain the following code, please only return the explanation.",
						opts = {
							enter_flexible_window = true,
						},
					},
					OptimizeCode = {
						handler = tools.side_by_side_handler,
						opts = {
							left = {
								focusable = false,
							},
						},
					},
					-- 	WordTranslate = {
					-- 		handler = tools.flexi_handler,
					-- 		prompt = "Translate the following text to Chinese, please only return the translation",
					-- 		opts = {
					-- 			parse_handler = local_llm_parse_handler,
					-- 			exit_on_move = true,
					-- 			enter_flexible_window = false,
					-- 		},
					-- 	},
				},
			})
		end,
		keys = {
			{ "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
			{ "<leader>aa", mode = "v", "<cmd>LLMAppHandler Ask<cr>" },
			{ "<leader>ec", mode = "v", "<cmd>LLMAppHandler CodeExplain<cr>" },
			{ "<leader>oc", mode = "v", "<cmd>LLMAppHandler OptimizeCode<cr>" },
		},
	},
}
