return {
  'benlubas/molten-nvim',
  build = ':UpdateRemotePlugins',
  config = function()
    -- Configuration options for better appearance (similar to your Magma config)
    vim.g.molten_auto_open_output = true
    vim.g.molten_image_provider = "kitty"
    vim.g.molten_output_win_border = { "", "", "", "" }
    vim.g.molten_wrap_output = true
    vim.g.molten_copy_output = true
    
    -- Enhanced output appearance
    vim.g.molten_show_mimetype_debug = false
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_output_win_cover_gutter = false
    vim.g.molten_output_win_max_height = 20
    vim.g.molten_tick_rate = 150
    
    -- Set up better highlight groups for output
    vim.api.nvim_set_hl(0, "MoltenOutputWin", { link = "Normal" })
    vim.api.nvim_set_hl(0, "MoltenOutputWinNC", { link = "Normal" })
    vim.api.nvim_set_hl(0, "MoltenCell", { link = "CursorLine" })
    
    -- Enhanced syntax highlighting for Python output
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "molten-output",
      callback = function()
        vim.bo.syntax = "python"
        -- Enable better colors for output
        vim.cmd("highlight! link MoltenOutputBorder FloatBorder")
      end,
    })
    
    -- Key mappings - adapted from your working Magma config using 'f' prefix
    vim.keymap.set("n", "<leader>fr", ":MoltenEvaluateLine<CR>", { silent = true, desc = "Evaluate line" })
    vim.keymap.set("x", "<leader>f", ":<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate visual selection" })
    vim.keymap.set("n", "<leader>fc", ":MoltenReevaluateCell<CR>", { silent = true, desc = "Re-evaluate cell" })
    vim.keymap.set("n", "<leader>fd", ":MoltenDelete<CR>", { silent = true, desc = "Delete cell" })
    vim.keymap.set("n", "<leader>fo", ":MoltenShowOutput<CR>", { silent = true, desc = "Show output" })
    vim.keymap.set("n", "<leader>fi", ":MoltenInit python3<CR>", { silent = true, desc = "Initialize Molten" })
    
    -- Text object mappings for paragraphs and other vim motions
    vim.keymap.set("n", "<leader>fp", "vip:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate paragraph" })
    vim.keymap.set("n", "<leader>ff", "vaf:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate function" })
    vim.keymap.set("n", "<leader>fb", "vi{:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate block {}" })
    vim.keymap.set("n", "<leader>fB", "vi[:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate block []" })
    vim.keymap.set("n", "<leader>fw", "viw:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate word" })
    
    -- Additional useful mappings
    vim.keymap.set("n", "<leader>fq", ":noautocmd MoltenEnterOutput<CR>", { silent = true, desc = "Enter output window" })
    vim.keymap.set("n", "<leader>fI", ":MoltenInterrupt<CR>", { silent = true, desc = "Interrupt execution" })
    vim.keymap.set("n", "<leader>fR", ":MoltenRestart<CR>", { silent = true, desc = "Restart kernel" })
    vim.keymap.set("n", "<leader>fs", ":MoltenSave<CR>", { silent = true, desc = "Save session" })
    vim.keymap.set("n", "<leader>fl", ":MoltenLoad<CR>", { silent = true, desc = "Load session" })
    
    -- Enhanced output window styling
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "molten-output" then
          -- Set better options for output window
          vim.wo.number = false
          vim.wo.relativenumber = false
          vim.wo.signcolumn = "no"
          vim.wo.foldcolumn = "0"
          vim.wo.wrap = true
          vim.wo.linebreak = true
          
          -- Add syntax highlighting for common output formats
          vim.cmd([[
            syntax match MoltenOutputNumber '\v<\d+(\.\d+)?>'
            syntax match MoltenOutputString '\v"[^"]*"'
            syntax match MoltenOutputBracket '\v[\[\](){}]'
            syntax match MoltenOutputComma '\v,'
            syntax match MoltenOutputError '\v(Error|Exception|Traceback).*'
            
            highlight! link MoltenOutputNumber Number
            highlight! link MoltenOutputString String
            highlight! link MoltenOutputBracket Delimiter
            highlight! link MoltenOutputComma Delimiter
            highlight! link MoltenOutputError ErrorMsg
          ]])
        end
      end,
    })
    
    -- Function to toggle output window with better formatting
    vim.keymap.set("n", "<leader>ft", function()
      local wins = vim.api.nvim_list_wins()
      local molten_win = nil
      
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_get_option(buf, "filetype") == "molten-output" then
          molten_win = win
          break
        end
      end
      
      if molten_win then
        vim.api.nvim_win_close(molten_win, false)
      else
        vim.cmd("MoltenShowOutput")
      end
    end, { silent = true, desc = "Toggle output window" })
    
    -- Clear all outputs
    vim.keymap.set("n", "<leader>fC", function()
      vim.cmd("MoltenDelete!")
      vim.notify("All outputs cleared!", vim.log.levels.INFO)
    end, { silent = true, desc = "Clear all outputs" })
    
    -- Info command
    vim.keymap.set("n", "<leader>fF", ":MoltenInfo<CR>", { silent = true, desc = "Molten Info" })
  end
}
