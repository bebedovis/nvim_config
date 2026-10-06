-- Highlights color codes (#rrggbb, rgb(), etc.) with their actual color
return {
  'norcalli/nvim-colorizer.lua',
  config = function()
    require('colorizer').setup()
  end,
}
