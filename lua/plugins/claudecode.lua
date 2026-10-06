-- The plugin's :ClaudeCodeDiffAccept/Deny only work with the cursor in the *proposed* buffer
-- (the only one carrying b:claudecode_diff_tab_name). Resolve the pending diff from wherever the
-- cursor is: the proposed or original window, or any other window when only one diff is pending.
local function with_pending_diff(fn)
	local diff = require("claudecode.diff")
	local cur = vim.api.nvim_get_current_buf()
	local pending, visible = {}, {}
	for name, d in pairs(diff._get_active_diffs()) do
		if d.status == "pending" then
			if cur == d.new_buffer or cur == d.original_buffer then
				return fn(diff, name, d)
			end
			table.insert(pending, name)
			if d.new_window and vim.api.nvim_win_is_valid(d.new_window)
				and vim.api.nvim_win_get_tabpage(d.new_window) == vim.api.nvim_get_current_tabpage() then
				table.insert(visible, name)
			end
		end
	end
	local candidates = #visible > 0 and visible or pending
	if #candidates == 0 then
		return vim.notify("No pending Claude diff", vim.log.levels.WARN)
	elseif #candidates == 1 then
		return fn(diff, candidates[1], diff._get_active_diffs()[candidates[1]])
	end
	vim.ui.select(candidates, {
		prompt = "Which Claude diff?",
		format_item = function(name)
			local d = diff._get_active_diffs()[name]
			return d and vim.fn.fnamemodify(d.new_file_path or name, ":~:.") or name
		end,
	}, function(name)
		local d = name and diff._get_active_diffs()[name]
		if d and d.status == "pending" then
			fn(diff, name, d)
		end
	end)
end

local function accept_diff()
	with_pending_diff(function(diff, name, d)
		diff._resolve_diff_as_saved(name, d.new_buffer)
	end)
end

local function deny_diff()
	with_pending_diff(function(diff, name)
		diff._resolve_diff_as_rejected(name)
	end)
end

return { -- Claude Code IDE integration (selection context, diffs, @-mentions)
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = {
		terminal = {
			split_side = "right",
			split_width_percentage = 0.40,
			provider = "snacks",
			snacks_win_opts = {
				-- Let <Esc><Esc> reach Claude (rewind) instead of switching to normal mode;
				-- use <C-q> to leave terminal mode
				keys = { term_normal = false },
				-- No "1: term_title" winbar: claudecode recreates the split on re-show without it,
				-- then Snacks re-adds it, so the pty grows+shrinks one row and Claude's prompt
				-- box gets shifted/lost on every hide/show
				wo = { winbar = "" },
				-- For a floating window instead of a split:
				-- position = "float", width = 0.9, height = 0.9, border = "rounded",
			},
		},
		-- Proposed changes open *below* the original file instead of beside it
		diff_opts = { layout = "horizontal" },
	},
	config = function(_, opts)
		require("claudecode").setup(opts)

		-- Diff layout modes, switchable at runtime with :ClaudeDiffLayout / <leader>aL (not persisted;
		-- change `diff_mode` below to make one the default):
		--   column   original on top, proposed below, in ONE extra vsplit column (wrapper below)
		--   stacked  plugin's horizontal: splits whichever window the plugin picked
		--   vertical plugin default: original | proposed side by side
		--   unified  VS Code-style single buffer with inline +/- lines
		local modes = { column = "horizontal", stacked = "horizontal", vertical = "vertical", unified = "unified" }
		local order = { "column", "stacked", "vertical", "unified" }
		local diff_mode = "column"
		local function set_mode(mode)
			diff_mode = mode
			require("claudecode").state.config.diff_opts.layout = modes[mode]
			vim.notify("Claude diff layout: " .. mode .. " (applies to the next diff)")
		end
		set_mode(diff_mode)
		vim.api.nvim_create_user_command("ClaudeDiffLayout", function(a)
			if modes[a.args] then
				return set_mode(a.args)
			end
			vim.ui.select(order, {
				prompt = "Claude diff layout (now: " .. diff_mode .. ")",
			}, function(choice)
				if choice then
					set_mode(choice)
				end
			end)
		end, { nargs = "?", complete = function() return order end })

		-- With layout="horizontal" the plugin splits the window it picked for the diff, i.e. it would
		-- stack the diff under whatever file you had open (or under the Claude terminal when no
		-- editor window exists). Instead give the diff its own column: one vsplit holding the
		-- original on top and the proposed version below.
		local diff = require("claudecode.diff")
		local create = diff._create_diff_view_from_window
		diff._create_diff_view_from_window = function(target, old_path, new_buf, tab, is_new, term_tab_win, existing)
			local own_column = false
			if diff_mode == "column" and target and vim.api.nvim_win_is_valid(target) and not term_tab_win then
				local buf = vim.api.nvim_win_get_buf(target)
				local name = vim.api.nvim_buf_get_name(buf)
				local empty = name == "" and not vim.bo[buf].modified
				-- Fallback scratch split the plugin made inside the terminal column: drop it
				local fallback = empty and vim.bo[buf].buftype == "nofile" and vim.bo[buf].bufhidden == "wipe"
				if fallback or (name ~= old_path and not empty) then
					if fallback then
						vim.api.nvim_win_close(target, true)
						target = vim.api.nvim_get_current_win()
					end
					vim.api.nvim_set_current_win(target)
					vim.cmd(fallback and "leftabove vsplit" or "rightbelow vsplit")
					target = vim.api.nvim_get_current_win()
					local scratch = vim.api.nvim_create_buf(false, true)
					vim.bo[scratch].bufhidden = "wipe"
					vim.api.nvim_win_set_buf(target, scratch)
					own_column = true
				end
			end
			local info = create(target, old_path, new_buf, tab, is_new, term_tab_win, existing)
			if own_column then
				info.target_window_created_by_plugin = true -- closed again on accept/deny
			end
			return info
		end

		-- When the diff was opened with no editor window around (only Claude, maybe the tree), accept/
		-- deny closes the diff column and leaves Claude as the only window. Put the file back in an
		-- editor window left of Claude instead.
		local sidebars = { NvimTree = true, ["neo-tree"] = true, oil = true, aerial = true }
		vim.api.nvim_create_autocmd("User", {
			pattern = "ClaudeCodeDiffClosed",
			callback = function(a)
				vim.schedule(function()
					local term
					for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
						if vim.api.nvim_win_get_config(w).relative == "" then
							local b = vim.api.nvim_win_get_buf(w)
							if vim.bo[b].buftype == "terminal" then
								term = term or w
							elseif not sidebars[vim.bo[b].filetype] then
								return -- an editor window is still there
							end
						end
					end
					if not term then
						return
					end
					local scratch = vim.api.nvim_create_buf(false, true)
					vim.bo[scratch].bufhidden = "wipe"
					local win = vim.api.nvim_open_win(scratch, false, { split = "left", win = term })
					local path = a.data and a.data.file_path
					if path and vim.fn.filereadable(path) == 1 then
						vim.api.nvim_win_call(win, function()
							vim.cmd.edit(vim.fn.fnameescape(path))
						end)
					end
					vim.api.nvim_win_set_width(term, math.floor(vim.o.columns * opts.terminal.split_width_percentage))
				end)
			end,
		})
	end,
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeAdd",
		"ClaudeCodeSend",
		"ClaudeCodeTreeAdd",
		"ClaudeCodeStatus",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
		"ClaudeCodeCloseAllDiffs",
	},
	keys = {
		{ "<M-c>", "<cmd>ClaudeCodeFocus<cr>", mode = { "n", "t" }, desc = "Toggle/focus Claude" },
		{ "<leader>a", nil, desc = "[A]I/Claude" },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle [C]laude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "[R]esume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "[C]ontinue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select [M]odel" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current [B]uffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "[S]end selection to Claude" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file to Claude",
			ft = { "NvimTree", "neo-tree", "oil" },
		},
		{ "<leader>aa", accept_diff, desc = "[A]ccept diff" },
		{ "<leader>ad", deny_diff, desc = "[D]eny diff" },
	},
}
