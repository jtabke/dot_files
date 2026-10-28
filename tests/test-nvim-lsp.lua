-- Exercise the real Neovim LSP configuration API, without loading plugins,
-- downloading tools, starting language servers, or using the live user config.
local mason_setup = false
local lsp_setup = false
package.preload["blink.cmp"] = function()
	return {
		get_lsp_capabilities = function()
			return { textDocument = { completion = { completionItem = { snippetSupport = true } } } }
		end,
	}
end
package.preload["mason"] = function()
	return { setup = function() mason_setup = true end }
end
package.preload["lspconfig"] = function()
	error("Legacy lspconfig.setup must not be used")
end
package.preload["mason-lspconfig"] = function()
	return {
		setup = function(opts)
			assert(mason_setup, "Mason must be initialized first")
			assert(opts.handlers == nil, "Mason v2 does not consume handlers")
			local config = vim.lsp.config.lua_ls
			assert(config.capabilities.textDocument.completion.completionItem.snippetSupport)
			assert(config.settings.Lua.diagnostics.globals[1] == "vim")
			assert(vim.tbl_contains(opts.ensure_installed, "lua_ls"))
			assert(vim.tbl_contains(opts.ensure_installed, "ts_ls"))
			lsp_setup = true
		end,
	}
end
local specs = dofile(os.getenv("DOTFILES_REPO") .. "/home/dot_config/nvim/lua/plugins/lsp.lua")
specs[2].init()
specs[2].config()
assert(lsp_setup, "Language server setup was not invoked")
print("Native LSP configuration checks passed")
