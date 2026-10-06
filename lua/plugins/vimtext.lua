return {
  'lervag/vimtex',
  lazy = false, -- we don't want to lazy load VimTeX
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- Enable filetype detection, plugin, and indent
    vim.cmd 'filetype plugin indent on'

    -- enable syntax highlighting
    vim.cmd 'syntax enable'

    -- viewer options
    vim.g.vimtex_view_method = 'zathura'

    -- or with a generic interface
    vim.g.vimtex_view_general_viewer = 'okular'
    vim.g.vimtex_view_general_options = '--unique file:@pdf\\#src:@line@tex'

    -- compiler options
    vim.g.vimtex_compiler_method = 'latexmk'

  end,
}
