return { -- Useful plugin to show you pending keybinds.
	"folke/which-key.nvim",
	event = "VimEnter", -- Load on VimEnter
	config = function()
		local wk = require("which-key")

		-- Setup with default options
		wk.setup()

		wk.register({
			["<leader>c"] = { group = "[C]ode" },
			["<leader>d"] = { group = "[D]ocument" },
			["<leader>r"] = { group = "[R]ename" },
			["<leader>s"] = { group = "[S]earch" },
			["<leader>w"] = { group = "[W]orkspace" },
			["<leader>t"] = { group = "[T]oggle" },
			["<leader>h"] = { group = "Git [H]unk" },
		}, { mode = "n" })

		-- Visual mode mappings (no array table)
		wk.register({
			["<leader>h"] = { desc = "Git [H]unk" },
		}, { mode = "v" })
	end,
}
