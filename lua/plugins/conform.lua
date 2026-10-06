-- VS Code "editor.codeActionsOnSave": run organizeImports + fixAll code actions
-- synchronously (ts_ls, eslint, ...) before conform formats the buffer.
local function code_actions_on_save(bufnr)
	for _, kind in ipairs({ "source.organizeImports", "source.fixAll" }) do
		local params = vim.lsp.util.make_range_params(0, "utf-16")
		params.context = { only = { kind }, diagnostics = {} }
		local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
		for client_id, res in pairs(results or {}) do
			local client = vim.lsp.get_client_by_id(client_id)
			for _, action in ipairs(client and res.result or {}) do
				if action.edit then
					vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
				end
				if type(action.command) == "table" then
					client:exec_cmd(action.command, { bufnr = bufnr })
				end
			end
		end
	end
end

return { -- Autoformat
	"stevearc/conform.nvim",
	lazy = false,
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Python: pyright has no fixAll; isort already organizes imports
			if vim.bo[bufnr].filetype ~= "python" then
				code_actions_on_save(bufnr)
			end
			return { timeout_ms = 1000, lsp_format = "fallback" }
		end,
		-- format_on_save = function(bufnr)
		-- 	-- Disable "format_on_save lsp_fallback" for languages that don't
		-- 	-- have a well standardized coding style. You can add additional
		-- 	-- languages here or re-enable it for the disabled ones.
		-- 	local disable_filetypes = {}
		-- 	return {
		-- 		timeout_ms = 500,
		-- 		lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
		-- 	}
		-- end,
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform can also run multiple formatters sequentially
			python = { "isort", "black" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			--
			-- stop_after_first tells conform to run only the first formatter
			-- in the list that is available.
			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			css = { "prettierd", "prettier", stop_after_first = true },
			scss = { "prettierd", "prettier", stop_after_first = true },
			html = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
		},
		formatters = {
			c = { args = '--style="{BasedOnStyle: llvm, IndentWidth: 8}"' },
		},
	},
}
