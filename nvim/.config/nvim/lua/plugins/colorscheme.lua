return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("config.noctalia").setup()
      end,
    },
  },
}
