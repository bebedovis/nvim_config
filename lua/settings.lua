vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- See `:help vim.opt`
--  NOTE: You can change these options as you wish!
--
--  For more options, you can see `:help option-list
vim.o.termguicolors = true
--  relative numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- npi mouse mode
vim.opt.mouse = "a"

-- Don't show mode
vim.opt.showmode = false

-- Copypaste with clipboard
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
-- NOTE: undotree configuration
vim.o.undofile = true
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("v", "<leader>d", '"_d')
-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.api.nvim_set_keymap("n", "<leader>i", "A # type: ignore<Esc>", { noremap = true, silent = true })

-- Exit terminal mode. <C-q> works in every terminal; <Esc> only in plain shells,
-- so CLI agents (claude, llama) still receive <Esc> to cancel a running task.
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("terminal-esc", { clear = true }),
	callback = function(event)
		-- full command line of the job (may be wrapped in a shell, e.g. by snacks)
		local job = vim.b[event.buf].terminal_job_id
		local cmd = job and table.concat(vim.api.nvim_get_chan_info(job).argv or {}, " ") or ""
		if cmd:match("claude") or cmd:match("OllamaCodeCompanion") then
			return
		end
		vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = event.buf, desc = "Exit terminal mode" })
	end,
})

-- Reload buffers changed on disk (e.g. edits made by Claude)
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	group = vim.api.nvim_create_augroup("auto-checktime", { clear = true }),
	command = "silent! checktime",
})

-- Git: VS Code-like autofetch (git.autofetch) every 3 min, async, only inside a repo
local git_fetch_timer = vim.uv.new_timer()
git_fetch_timer:start(5000, 180000, function()
	vim.schedule(function()
		local cwd = vim.fn.getcwd()
		if vim.fn.finddir(".git", cwd .. ";") == "" and vim.fn.findfile(".git", cwd .. ";") == "" then
			return
		end
		vim.system({ "git", "fetch", "--quiet" }, { cwd = cwd, env = { GIT_TERMINAL_PROMPT = "0" } })
	end)
end)
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		git_fetch_timer:stop()
		git_fetch_timer:close()
	end,
})
-- Git: "smart commit" (git.enableSmartCommit) = commit all tracked changes
vim.keymap.set("n", "<leader>gC", "<Cmd>Git commit -a<CR>", { desc = "[G]it [C]ommit all (smart commit)" })

-- Python host for remote plugins (molten-nvim)
vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/nvim/bin/python")

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
-- Same for <C-h>/<C-j> in terminals (Claude has Backspace / Shift+Enter for these).
-- <C-k>/<C-l> stay unmapped in t-mode: kill-line / clear-screen in the terminal.
vim.keymap.set("t", "<C-h>", "<Cmd>wincmd h<CR>", { desc = "Move focus to the left window" })
vim.keymap.set("t", "<C-j>", "<Cmd>wincmd j<CR>", { desc = "Move focus to the lower window" })
-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
