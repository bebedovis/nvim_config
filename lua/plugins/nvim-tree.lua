return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local tree = require("nvim-tree").setup({
			git = {
				enable = true,
				ignore = false,
			},
			filters = {
				git_ignored = false,
			},
		})
		local harp = require("harpoon.mark")
		local api = require("nvim-tree.api")

		-- nvim-tree opens files in the window it was toggled from; never let that be a
		-- terminal (Claude), or the file replaces the Claude split and the layout breaks
		vim.keymap.set("n", "\\", function()
			if vim.bo.buftype == "terminal" then
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.bo[buf].buftype ~= "terminal" and vim.api.nvim_win_get_config(win).relative == "" then
						vim.api.nvim_set_current_win(win)
						break
					end
				end
			end
			vim.cmd.NvimTreeToggle()
		end, { desc = "Toggle file tree" })
	end,
}
