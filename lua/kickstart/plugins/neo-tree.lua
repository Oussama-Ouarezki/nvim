return {
  "nvim-neo-tree/neo-tree.nvim",
  event = "VeryLazy",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  lazy = false,
  keys = {
    { "\\", ":Neotree reveal<CR>", desc = "NeoTree reveal", silent = true },
  },
  opts = {
    -- open_on_setup = false, -- legacy option (just in case)
    -- open_on_setup_file = false, -- legacy option (just in case)
    filesystem = {
      -- hijack_netrw_behavior = "disabled", -- don't auto open for netrw
      window = {
        mappings = {
          ["\\"] = "close_window",
          ["<leader>Y"] = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path)
            vim.notify("Copied absolute path: " .. path)
          end,
          ["<leader>y"] = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local relative_path = vim.fn.fnamemodify(path, ":~:.")
            vim.fn.setreg("+", relative_path)
            vim.notify("Copied relative path: " .. relative_path)
          end,
        },
      },
    },
  },
}
