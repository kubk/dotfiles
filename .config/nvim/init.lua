vim.g.mapleader = " "

-- nvim-tree replaces Neovim's built-in directory browser.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.splitright = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  severity_sort = true,
})

local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        hijack_directories = { enable = true, auto_open = true },
        sync_root_with_cwd = true,
        view = { side = "left", width = 32 },
        renderer = { group_empty = true },
        actions = { open_file = { resize_window = false } },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "super-tab" },
      completion = {
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
      },
      signature = { enabled = true },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local function go_to_definition()
        vim.lsp.buf.definition({
          on_list = function(options)
            vim.fn.setqflist({}, " ", options)
            if #options.items == 1 then
              vim.cmd("silent cfirst")
              vim.cmd("normal! zvzz")
            else
              vim.cmd("botright copen")
            end
          end,
        })
      end

      local lsp_keymaps = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_keymaps,
        callback = function(event)
          vim.keymap.set("n", "gd", go_to_definition, { buffer = event.buf, desc = "Go to definition" })
          vim.keymap.set("n", "<C-]>", go_to_definition, { buffer = event.buf, desc = "Go to definition" })
          vim.keymap.set("n", "grr", vim.lsp.buf.references, { buffer = event.buf, desc = "Show all usages" })
        end,
      })

      vim.lsp.config("vtsls", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })
      vim.lsp.enable("vtsls")
    end,
  },
  {
    "dmtrKovalenko/fff",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {},
    lazy = false,
    keys = {
      {
        "<leader>p",
        function()
          require("fff").find_files()
        end,
        desc = "Find project files",
      },
    },
  },
})

vim.keymap.set("n", "<leader>e", function()
  local tree = require("nvim-tree.api").tree
  if vim.bo.filetype == "NvimTree" then
    tree.close()
  else
    tree.find_file({ open = true, focus = true })
  end
end, { desc = "Reveal current file in tree" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("x", "<D-c>", '"+y', { desc = "Copy to system clipboard" })
