# Neovim config — context for Claude

Personal nvim config (kickstart-derived, lazy.nvim). nvim 0.11.5, Debian 13, GNOME Terminal
(user is switching to **Kitty** for inline notebook images). Python via pyenv, active env `p312`.
Leader = `<space>`, localleader = `<space>` (vimtex override removed on purpose).

## Goals of the ongoing work (started 2026-09-29)
a) Chat comfortably with the Claude CLI from inside nvim.
b) Read/edit/run Jupyter notebooks in nvim.
c) Keep a list of keymaps that interfere with each other.

## What was done
- **Claude**: `lua/plugins/claudecode.lua` — `coder/claudecode.nvim` + `folke/snacks.nvim` terminal,
  right split 40%. snacks' double-Esc→normal mapping disabled (`keys = { term_normal = false }`).
  Snacks terminal winbar disabled (`wo = { winbar = "" }`): claudecode's re-show recreates the split
  without it and Snacks re-adds it, so the pty resized ±1 row and Claude's prompt box shifted/vanished.
  Diffs: `diff_opts.layout="horizontal"` + a `config` wrapper around `diff._create_diff_view_from_window`
  so a diff gets ONE vsplit column (original on top, proposed below) instead of 2 extra vsplits; if the
  file is already shown, that window is split horizontally in place; the plugin's fallback split inside
  the Claude column is replaced by a vsplit left of Claude. Wrapper marks its column
  `target_window_created_by_plugin` so accept/deny closes it. Verified headless (4 cases).
  `:ClaudeDiffLayout [column|stacked|vertical|unified]` switches the diff layout at runtime (not persisted).
  A `User ClaudeCodeDiffClosed` autocmd reopens the file in a split left of Claude when closing the diff
  left no editor window (diff opened with only Claude/tree visible → you were stuck in Claude). Verified headless.
  Keys: `<M-c>` (n+t) ClaudeCodeFocus toggle; `<leader>ac/ar/aC/am/ab`, `<leader>as` (visual send,
  or add file in NvimTree), `<leader>aa/ad` accept/deny diff. These call local `accept_diff/deny_diff`
  (not the plugin commands, which only work from the proposed buffer): they pick the pending diff via
  `diff._get_active_diffs()` from the proposed/original buffer, else the single pending one (ui.select
  if several). Verified headless from original, proposed and unrelated windows.
- **Esc fix** (`lua/settings.lua`): global `t <Esc>` removed. `t <C-q>` exits terminal mode everywhere.
  A `TermOpen` autocmd adds buffer-local `t <Esc>` only when the job argv (via
  `nvim_get_chan_info(terminal_job_id).argv`) does NOT contain `claude`/`OllamaCodeCompanion`.
  (Bufname can't be used: snacks wraps the cmd in bash, and cwd paths may contain "claude".)
  Also `autoread` + `checktime` autocmd; `g:python3_host_prog = ~/.virtualenvs/nvim/bin/python`.
- **toggleterm.lua**: old claude float removed; `<M-h>` (shell) and `<M-l>` (llama) mapped in n+t.
- **Notebooks**: `lua/plugins/notebook.lua` — jupytext.nvim (`style="percent"`, .ipynb opens as `# %%` python),
  molten-nvim (kernel, virt-text output, auto init + `MoltenImportOutput` on open, `MoltenExportOutput!`
  on write), image.nvim (enabled only when `KITTY_WINDOW_ID`/`TERM=xterm-kitty`; magick_cli processor),
  NotebookNavigator (`repl_provider="molten"`). mini.ai gets `ih/ah` cell textobject (mini.lua depends on NN).
  Keys: `]h/[h`; `<leader>m` + `i x X a j l v o h d R b B`.
- **which-key.lua**: migrated `wk.register` → `wk.add`; groups `<leader>a` Claude, `<leader>m` Notebook.
- **vimtext.lua**: removed `maplocalleader='\\'` (clashed with `\` = nvim-tree toggle). vimtex is now `<space>ll` etc.
- **VS Code settings port (2026-10-06)**: conform `format_on_save` is a function that first runs
  `source.organizeImports` + `source.fixAll` LSP code actions synchronously (skipped for python; isort does it),
  then formats. Prettier also for css/scss/html/yaml/markdown. `eslint` LSP added; black/isort via mason;
  `pylint` installed in `p312` (not mason, so it sees project deps) and run by nvim-lint (lint.lua now enabled).
  settings.lua: `git fetch` every 3 min when cwd is a repo (autofetch); `<leader>gC` = `:Git commit -a`.
  Verified headless (py: isort+black+pylint diag; ts: unused import removed + prettier).
- **init.lua**: added `require("plugins.claudecode")`, `require("plugins.notebook")`.
- Python: `~/.virtualenvs/nvim` (pynvim jupyter_client jupytext nbformat cairosvg pillow pyperclip);
  `jupytext` + `ipykernel` in `p312`; kernelspec `p312` installed. `:UpdateRemotePlugins` done.
- lazy-lock: existing plugins pinned to their pre-session commits (an accidental `Lazy! sync` was reverted);
  only the 5 new plugins added. Don't run `Lazy sync`/`update` unasked.

## Still TODO / open
1. **Layout bug (fixed, confirmed by user 2026-09-29)**: open Claude (`<M-c>`) → `<C-q>` → `\` (tree) → Enter on
   a file → `<M-c>` hide/show ⇒ file replaced the Claude split, extra windows, file squeezed to 1 col.
   Root cause: on startup the alpha dashboard window is `buftype=nofile`, which nvim-tree's window picker
   excludes (as it does terminals) ⇒ no usable window ⇒ falls back to `lib.target_winid` = the window `\`
   was pressed in = Claude terminal. Fix in `lua/plugins/nvim-tree.lua`: `\` first moves to a
   non-terminal, non-float window before `NvimTreeToggle`. Still uncovered: clicking into an already-open
   tree from Claude with the mouse (target_winid only set on tree open) — consider a custom
   `actions.open_file.window_picker.picker` if it recurs.
2. User must run: `sudo apt install kitty imagemagick`; in Kitty run `/terminal-setup` inside Claude.
3. Keymap conflicts reported but intentionally left alone: `gr` (LSP refs) shadows 0.11 `grn/gra/grr`;
   mini.surround shadows `s`; Comment.nvim duplicates built-in `gc`; `[d`/`]d` use deprecated
   `goto_prev/next`; `<F1>` (DAP) replaces help. Don't extend harpoon `<M-p>/<M-n>/<M-1..9>` to t-mode
   (Claude uses Alt+P / Alt+T). `<C-h>`/`<C-j>` ARE mapped in t-mode to `wincmd h/j` (user's choice
   2026-09-29; Claude still has Backspace / Shift+Enter). Don't map `<C-k>`/`<C-l>` in t-mode.

## Known notebook caveats
- Running a markdown cell/header makes `MoltenExportOutput` bail ("No cell matching") → `<leader>md` it.
- Running the last cell appends an empty `# %%` cell (NotebookNavigator, Jupyter-like).
- Evaluate only after "[Molten] Kernel ... is ready", otherwise outputs attach to the wrong cells.

## How to test (headless harness)
Lua diagnostics "Undefined global vim" are pre-existing lua_ls noise — ignore.
- Keymap/terminal checks: `nvim --headless "+luafile x.lua" +qa!`; write results with
  `vim.fn.writefile(out, "x.out"); os.exit(0)` when claudecode is loaded (its server keeps nvim alive).
- Fake Claude without starting a real session: after `require("lazy").load({plugins={"claudecode.nvim"}})`,
  call `require("claudecode").setup(vim.tbl_deep_extend("force", require("lazy.core.config").plugins["claudecode.nvim"].opts, {terminal_cmd = "bash -c 'sleep 60' claude"}))`.
- Real keypress replay (reproduces UI bugs): start `nvim --headless --listen nv.sock` in a dir with
  files, attach with `~/.virtualenvs/nvim/bin/python` + `pynvim.attach("socket", path=...)`,
  `nv.ui_attach(180,45,ext_linegrid=True)`, send keys with `nv.input("<M-c>")`, sleep ~1s, and dump
  each window (bufname, buftype, width, float?) + `vim.fn.winlayout()` via `nv.exec_lua`.
  Afterwards `pkill -f "sleep 60' claude"` (never pkill a pattern that matches your own command line).
- Notebook round-trip: build a test .ipynb with `nbformat` (kernelspec name `p312`), open headless,
  wait for `require("molten.status").initialized()=="Molten"` + ~6s, run cells, `:write`, then
  `nbformat.read/validate` and check outputs landed in the right cells.
