-- Ollama API Documentation https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion
local role_map = {
	user = "user",
	assistant = "assistant",
	system = "system",
	tool = "tool",
}

---@param opts AvantePromptOptions
local parse_messages = function(self, opts)
	local messages = {}
	local has_images = opts.image_paths and #opts.image_paths > 0
	-- Ensure opts.messages is always a table
	local msg_list = opts.messages or {}
	-- Convert Avante messages to Ollama format
	for _, msg in ipairs(msg_list) do
		local role = role_map[msg.role] or "assistant"
		local content = msg.content or "" -- Default content to empty string
		-- Handle multimodal content if images are present
		-- *Experimental* not tested
		if has_images and role == "user" then
			local message_content = {
				role = role,
				content = content,
				images = {},
			}
			for _, image_path in ipairs(opts.image_paths) do
				local base64_content = vim.fn.system(string.format("base64 -w 0 %s", image_path)):gsub("\n", "")
				table.insert(message_content.images, "data:image/png;base64," .. base64_content)
			end
			table.insert(messages, message_content)
		else
			table.insert(messages, {
				role = role,
				content = content,
			})
		end
	end
	return messages
end

local function parse_curl_args(self, code_opts)
	-- Create the messages array starting with the system message
	local messages = {
		{ role = "system", content = code_opts.system_prompt },
	}
	-- Extend messages with the parsed conversation messages
	vim.list_extend(messages, self:parse_messages(code_opts))
	-- Construct options separately for clarity
	local options = {
		num_ctx = (self.options and self.options.num_ctx) or 4096,
		temperature = code_opts.temperature or (self.options and self.options.temperature) or 0,
	}
	-- Check if tools table is empty
	local tools = (code_opts.tools and next(code_opts.tools)) and code_opts.tools or nil
	-- Return the final request table
	return {
		url = self.endpoint .. "/api/chat",
		headers = {
			Accept = "application/json",
			["Content-Type"] = "application/json",
		},
		body = {
			model = self.model,
			messages = messages,
			options = options,
			-- tools = tools, -- Optional tool support
			stream = false, -- Keep streaming enabled
		},
	}
end

local function parse_stream_data(data, handler_opts)
	local json_data = vim.fn.json_decode(data)
	if json_data then
		-- Handle content first
		if json_data.message then
			local content = json_data.message.content
			if content and content ~= "" then
				print("Calling on_chunk with content:", content)

				if handler_opts.on_chunk then
					handler_opts.on_chunk(content)
				else
					print("Warning: handler_opts.on_chunk is nil")
				end
			end
		end

		-- Handle done after processing content
		if json_data.done then
			print("inside json_data.done")
			if handler_opts and handler_opts.on_stop then
				print("handler_opts on stop")
				handler_opts.on_stop({ reason = json_data.done_reason or "stop" })
			else
				print("Warning: handler_opts.on_stop is nil")
			end
			return
		end

		-- Handle tool calls if present
		if json_data.tool_calls then
			for _, tool in ipairs(json_data.tool_calls) do
				handler_opts.on_tool(tool)
			end
		end
	end
end

local function parse_response_without_stream(data, _, handler_opts)
	local json_data = vim.fn.json_decode(data)
	if json_data then
		if json_data.message then
			local content = json_data.message.content
			if content and content ~= "" then
				handler_opts.on_chunk(content)
			end
		end
		-- Handle tool calls if present
		if json_data.message.tool_calls then
			local ctx = {
				reason = "tool_use",
			}
			ctx.tool_use_list = {}

			for id, tool_call in ipairs(json_data.message.tool_calls) do
				local tool_use = {
					name = tool_call["function"].name,
					id = id,
					input_json = vim.json.encode(tool_call["function"].arguments),
				}
				table.insert(ctx.tool_use_list, tool_use)
			end

			handler_opts.on_stop(ctx)
			return
		end
		if json_data.done then
			handler_opts.on_stop({ reason = json_data.done_reason or "stop" })
			return
		end
	end
end
---@type AvanteProvider
local ollama = {
	api_key_name = "",
	endpoint = "http://127.0.0.1:11434",
	model = "qwen2.5-coder:14b",
	-- model = "phi4",
	-- model = "deepseek-r1:14b",
	-- model = "llama3.1:latest",
	options = {
		num_ctx = 8192,
		temperature = 0.7,
	},
	disable_tools = true,
	parse_messages = parse_messages,
	parse_curl_args = parse_curl_args,
	parse_stream_data = parse_stream_data,
	parse_response_without_stream = parse_response_without_stream,
}

return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	version = false, -- Always pull the latest change
	opts = {
		behavior = {
			auto_suggestions = true,
			auto_focus_sidebar = false,
		},
		auto_suggestions_provider = "ollama",
		debug = true,
		provider = "ollama",
		vendors = {
			ollama = ollama,
			ollama2 = {
				__inherited_from = "openai",
				api_key_name = "",
				endpoint = "http://127.0.0.1:11434/v1",
				model = "qwen2.5-coder:14b",
			},
		},
	},

	build = "make",
	dependencies = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"echasnovski/mini.pick", -- for file_selector provider mini.pick
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"ibhagwan/fzf-lua", -- for file_selector provider fzf
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = true,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
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
