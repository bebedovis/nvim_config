return {
	"akinsho/toggleterm.nvim",
	version = "*",
	config = function()
		local Terminal = require("toggleterm")
		-- Mapped in terminal mode too, so terminals can be toggled without leaving them
		local map = function(keys, func, desc)
			vim.keymap.set({ "n", "t" }, keys, func, { desc = desc })
		end

		local llama_term = require("toggleterm.terminal").Terminal:new({
			cmd = "cd ~/git/OllamaCodeCompanion && python main.py",
			direction = "float",
			dir = vim.loop.cwd(),
			id = 3,
		})

		map("<M-h>", function()
			Terminal.toggle(1, 15, vim.loop.cwd(), "horizontal")
		end, "toggle horizontal terminal")

		map("<M-l>", function()
			llama_term:toggle()
		end, "toggle floating terminal with llama")
	end,
}
