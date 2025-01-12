return {
	"yetone/avante.nvim",
	-- tag = "v0.0.14",
	event = "VeryLazy",
	lazy = false,
	version = false, -- set this if you want to always pull the latest change
	opts = {
		-- add any opts here
		behavior = {
			auto_suggestions = false,
		},
		debug = true,
		provider = "ollama",
		vendors = {
			---@type AvanteProvider
			ollama = {
				api_key_name = "",
				ask = true,
				endpoint = "http://127.0.0.1:11434/api",
				model = "phi4",
				-- model = "qwn2.5-coder:14b",
				-- model = "llama3.1:latest",
				parse_curl_args = function(opts, code_opts)
					return {
						url = opts.endpoint .. "/chat",
						headers = {
							["Accept"] = "application/json",
							["Content-Type"] = "application/json",
						},
						body = {
							model = opts.model,
							options = {
								num_ctx = 16384,
							},
							messages = require("avante.providers").copilot.parse_messages(code_opts), -- you can make your own message, but this is very advanced
							-- max_tokens = 2048,
							stream = true,
						},
					}
				end,
				parse_stream_data = function(data, handler_opts)
					-- Parse the JSON data
					local json_data = vim.fn.json_decode(data)
					-- Check if the response contains a message
					if json_data and json_data.message and json_data.message.content then
						-- Extract the content from the message
						local content = json_data.message.content
						-- Call the handler with the content
						handler_opts.on_chunk(content)
					end
				end,
			},
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		-- "zbirenbaum/copilot.lua", -- for providers='copilot'
		-- {
		-- 	-- support for image pasting
		-- 	"HakonHarnes/img-clip.nvim",
		-- 	event = "VeryLazy",
		-- 	opts = {
		-- 		-- recommended settings
		-- 		default = {
		-- 			embed_image_as_base64 = false,
		-- 			prompt_for_file_name = false,
		-- 			drag_and_drop = {
		-- 				insert_mode = true,
		-- 			},
		-- 			-- required for Windows users
		-- 			use_absolute_path = true,
		-- 		},
		-- 	},
		-- },
		-- {
		-- 	-- Make sure to set this up properly if you have lazy=true
		-- 	"MeanderingProgrammer/render-markdown.nvim",
		-- 	opts = {
		-- 		file_types = { "markdown", "Avante" },
		-- 	},
		-- 	ft = { "markdown", "Avante" },
		-- },
	},
}
