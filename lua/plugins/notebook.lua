-- Jupyter notebooks: .ipynb opens as `# %%` python (jupytext), cells run on a
-- Jupyter kernel (molten), plots render inline when running inside kitty (image.nvim)
local in_kitty = vim.env.KITTY_WINDOW_ID ~= nil or vim.env.TERM == "xterm-kitty"

-- On opening a notebook: start its kernel (if installed) and load saved outputs
local function import_outputs(e)
	vim.schedule(function()
		local kernels = vim.fn.MoltenAvailableKernels()
		local ok, kernel_name = pcall(function()
			return vim.json.decode(io.open(e.file, "r"):read("a")).metadata.kernelspec.name
		end)
		if not ok or not vim.tbl_contains(kernels, kernel_name) then
			local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
			kernel_name = venv and venv:match("/.+/(.+)")
		end
		if kernel_name and vim.tbl_contains(kernels, kernel_name) then
			vim.cmd(("MoltenInit %s"):format(kernel_name))
			vim.cmd("MoltenImportOutput")
		end
	end)
end

local function nn(fn, ...)
	local args = { ... }
	return function()
		require("notebook-navigator")[fn](unpack(args))
	end
end

return {
	{
		"GCBallesteros/jupytext.nvim",
		lazy = false,
		opts = { style = "percent", output_extension = "auto" },
	},
	{
		"3rd/image.nvim",
		enabled = in_kitty,
		opts = {
			backend = "kitty",
			processor = "magick_cli",
			integrations = {},
			max_width = 100,
			max_height = 12,
			max_height_window_percentage = math.huge,
			max_width_window_percentage = math.huge,
			window_overlap_clear_enabled = true,
		},
	},
	{
		"benlubas/molten-nvim",
		version = "^1.0.0",
		lazy = false,
		build = ":UpdateRemotePlugins",
		dependencies = in_kitty and { "3rd/image.nvim" } or {},
		init = function()
			vim.g.molten_image_provider = in_kitty and "image.nvim" or "none"
			vim.g.molten_auto_open_output = false
			vim.g.molten_output_win_max_height = 20
			vim.g.molten_wrap_output = true
			vim.g.molten_virt_text_output = true
			vim.g.molten_virt_lines_off_by_1 = true

			local group = vim.api.nvim_create_augroup("molten-ipynb", { clear = true })
			vim.api.nvim_create_autocmd("BufAdd", { group = group, pattern = "*.ipynb", callback = import_outputs })
			vim.api.nvim_create_autocmd("BufEnter", {
				group = group,
				pattern = "*.ipynb",
				callback = function(e)
					-- BufAdd doesn't fire for the file given on the command line
					if vim.v.vim_did_enter ~= 1 then
						import_outputs(e)
					end
				end,
			})
			-- Save outputs back into the notebook
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = group,
				pattern = "*.ipynb",
				callback = function()
					if require("molten.status").initialized() == "Molten" then
						vim.cmd("MoltenExportOutput!")
					end
				end,
			})
		end,
	},
	{
		"GCBallesteros/NotebookNavigator.nvim",
		opts = { repl_provider = "molten", syntax_highlight = true },
		keys = {
			{ "]h", nn("move_cell", "d"), desc = "Next cell" },
			{ "[h", nn("move_cell", "u"), desc = "Previous cell" },
			{ "<leader>mi", "<cmd>MoltenInit<cr>", desc = "[I]nit kernel" },
			{ "<leader>mx", nn("run_cell"), desc = "Run cell" },
			{ "<leader>mX", nn("run_and_move"), desc = "Run cell and move" },
			{ "<leader>ma", nn("run_all_cells"), desc = "Run [A]ll cells" },
			{ "<leader>mj", nn("run_cells_below"), desc = "Run cells below" },
			{ "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Run [L]ine" },
			{ "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Run selection" },
			{ "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Enter [O]utput" },
			{ "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "[H]ide output" },
			{ "<leader>md", "<cmd>MoltenDelete<cr>", desc = "[D]elete cell output" },
			{ "<leader>mR", "<cmd>MoltenRestart!<cr>", desc = "[R]estart kernel" },
			{ "<leader>mb", nn("add_cell_below"), desc = "Add cell [B]elow" },
			{ "<leader>mB", nn("add_cell_above"), desc = "Add cell above" },
		},
	},
}
