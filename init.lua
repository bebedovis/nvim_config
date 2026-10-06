-- Run initial settings
require("settings")

-- Initialization of lazy plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

--Installation of different plugins using lazy
require("lazy").setup({
	require("plugins.colorscheme"),
	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
	{ "numToStr/Comment.nvim", opts = {} }, -- "gc" to comment visual regions/lines
	require("plugins.gitsigns"),
	require("plugins.which-key"),
	require("plugins.telescope"),
	require("plugins.lspconfig"),
	require("plugins.conform"), --autoformating
	require("plugins.nvim-cmp"), --autocompletion
	require("plugins.colorizer"),
	require("plugins.todo-comments"),
	require("plugins.mini"),
	require("plugins.nvim-treesitter"),
	require("plugins.debug"),
	require("plugins.indent_line"),
	require("plugins.lint"),
	-- require 'plugins.autopairs',
	-- require 'plugins.neo-tree',
	-- NOTE: My pluggins
	"mbbill/undotree",
	"kikofmas/grammarous.nvim",
	require("plugins.vimtext"),
	require("plugins.toggleterm"),
	require("plugins.claudecode"),
	require("plugins.notebook"),
	require("plugins.hlslens"),
	require("plugins.harpoon"),
	require("plugins.nvim-tree"),
	require("plugins.alpha-nvim"),
	require("plugins.lsp-file-operations"),
	-- "github/copilot.vim",
	"tpope/vim-fugitive",
	-- require("plugins.markdown_prev"),
}, {
	ui = {
		icons = vim.g.have_nerd_font and {},
	},
})
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
