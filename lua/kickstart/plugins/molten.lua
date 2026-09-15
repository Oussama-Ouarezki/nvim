return {
  -- Image.nvim for rendering images in terminal
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty", -- Use kitty backend for Pop OS + Kitty
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki", "quarto" }, -- Added quarto
        },
        neorg = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "norg" },
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = 70,  -- Make images bigger
      max_height_window_percentage = 60, -- Make images bigger
      kitty_method = "normal", -- Use normal method for kitty
    },
  },

  -- Molten-nvim with Quarto support
  {
    'benlubas/molten-nvim',
    dependencies = { "3rd/image.nvim" },
    build = function()
      vim.cmd('UpdateRemotePlugins')
    end,
    ft = { "python", "markdown", "quarto" }, -- Load for these filetypes
    config = function()
      vim.defer_fn(function()
        if vim.fn.exists(':MoltenInit') == 0 then
          vim.notify("Molten commands not available. Run :UpdateRemotePlugins and restart Neovim", vim.log.levels.WARN)
          return
        end
        
        -- Configuration options for plotting with image.nvim
        vim.g.molten_auto_open_output = true
        vim.g.molten_image_provider = "image.nvim"  -- Use image.nvim for better rendering
        vim.g.molten_output_win_border = { "", "", "", "" }
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_lines_off_by_1 = true
        vim.g.molten_tick_rate = 150
        vim.g.molten_auto_image_popup = false  -- Keep images inline with image.nvim
        vim.g.molten_virt_text_output = true
        vim.g.molten_image_location = "float"  -- Show images in float window
        vim.g.molten_output_virt_lines = false
        vim.g.molten_auto_init_behavior = "init"  -- Auto init without asking
        
        -- Key mappings using 'f' prefix - auto-init without choosing kernel
        vim.keymap.set("n", "<leader>fi", function()
          -- Auto-detect and initialize appropriate kernel
          local ft = vim.bo.filetype
          if ft == "python" then
            vim.cmd("MoltenInit python3")
          elseif ft == "quarto" or ft == "markdown" then
            vim.cmd("MoltenInit python3")  -- Default to python3 for QMD
          else
            vim.cmd("MoltenInit")  -- Let user choose for other filetypes
          end
        end, { silent = true, desc = "Initialize Molten (auto-detect kernel)" })
        
        vim.keymap.set("n", "<leader>fr", ":MoltenEvaluateLine<CR>", { silent = true, desc = "Evaluate line" })
        vim.keymap.set("x", "<leader>f", ":<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate visual selection" })
        vim.keymap.set("n", "<leader>fc", ":MoltenReevaluateCell<CR>", { silent = true, desc = "Re-evaluate cell" })
        vim.keymap.set("n", "<leader>fd", ":MoltenDelete<CR>", { silent = true, desc = "Delete cell" })
        vim.keymap.set("n", "<leader>fo", ":MoltenShowOutput<CR>", { silent = true, desc = "Show output" })
        vim.keymap.set("n", "<leader>fq", ":noautocmd MoltenEnterOutput<CR>", { silent = true, desc = "Enter output window" })
        vim.keymap.set("n", "<leader>fI", ":MoltenInterrupt<CR>", { silent = true, desc = "Interrupt execution" })
        vim.keymap.set("n", "<leader>fR", ":MoltenRestart<CR>", { silent = true, desc = "Restart kernel" })
        vim.keymap.set("n", "<leader>fF", ":MoltenInfo<CR>", { silent = true, desc = "Molten Info" })
        vim.keymap.set("n", "<leader>fP", ":MoltenImagePopup<CR>", { silent = true, desc = "Open image popup" })
        
        -- Text objects and motion-based evaluation
        vim.keymap.set("n", "<leader>fw", "viw:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate word" })
        vim.keymap.set("n", "<leader>fW", "viW:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate WORD" })
        vim.keymap.set("n", "<leader>fp", "vip:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate paragraph" })
        vim.keymap.set("n", "<leader>fa", "vap:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate around paragraph" })
        vim.keymap.set("n", "<leader>fb", "vib:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate inside ()" })
        vim.keymap.set("n", "<leader>fB", "viB:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate inside {}" })
        vim.keymap.set("n", "<leader>f[", "vi[:<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate inside []" })
        vim.keymap.set("n", "<leader>f'", "vi':<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate inside ''" })
        vim.keymap.set("n", "<leader>f\"", "vi\":<C-u>MoltenEvaluateVisual<CR>", { silent = true, desc = "Evaluate inside \"\"" })
        
        -- Function to add cell markers
        local function add_cell_marker(above)
          local ft = vim.bo.filetype
          local marker = ""
          
          if ft == "python" then
            marker = "# %%"
          elseif ft == "quarto" or ft == "markdown" then
            marker = "```{python}\n# Cell\n```"
          else
            marker = "# %% Cell"
          end
          
          local line_num = vim.api.nvim_win_get_cursor(0)[1]
          if above then
            vim.api.nvim_buf_set_lines(0, line_num - 1, line_num - 1, false, {marker})
          else
            vim.api.nvim_buf_set_lines(0, line_num, line_num, false, {marker})
          end
        end
        
        -- Cell creation mappings
        vim.keymap.set("n", "<leader>fca", function() add_cell_marker(true) end, { silent = true, desc = "Add cell above" })
        vim.keymap.set("n", "<leader>fcb", function() add_cell_marker(false) end, { silent = true, desc = "Add cell below" })
        
        -- Quarto-specific mappings
        vim.keymap.set("n", "<leader>fC", function()
          -- Execute current code chunk in qmd files
          local line = vim.api.nvim_get_current_line()
          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
          
          -- Find the start and end of the current code chunk
          local start_line = nil
          local end_line = nil
          
          -- Search backwards for ```{python} or ```python
          for i = cursor_line, 1, -1 do
            local current_line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1] or ""
            if current_line:match("^```{?python}?") then
              start_line = i + 1  -- Start after the ``` line
              break
            end
          end
          
          -- Search forwards for ```
          for i = cursor_line, vim.api.nvim_buf_line_count(0) do
            local current_line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1] or ""
            if current_line:match("^```%s*$") and i > cursor_line then
              end_line = i - 1  -- End before the ``` line
              break
            end
          end
          
          if start_line and end_line and start_line <= end_line then
            -- Select the code chunk and evaluate
            vim.api.nvim_win_set_cursor(0, {start_line, 0})
            vim.cmd("normal! V")
            vim.api.nvim_win_set_cursor(0, {end_line, 0})
            vim.cmd("MoltenEvaluateVisual")
          else
            vim.notify("No Python code chunk found at cursor", vim.log.levels.WARN)
          end
        end, { silent = true, desc = "Execute current code chunk (QMD)" })
        
        -- Navigate between code chunks in QMD
        vim.keymap.set("n", "<leader>fn", function()
          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
          for i = cursor_line + 1, vim.api.nvim_buf_line_count(0) do
            local line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1] or ""
            if line:match("^```{?python}?") then
              vim.api.nvim_win_set_cursor(0, {i + 1, 0})
              return
            end
          end
          vim.notify("No next Python code chunk found", vim.log.levels.INFO)
        end, { silent = true, desc = "Next code chunk (QMD)" })
        
        vim.keymap.set("n", "<leader>fN", function()
          local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
          for i = cursor_line - 1, 1, -1 do
            local line = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1] or ""
            if line:match("^```{?python}?") then
              vim.api.nvim_win_set_cursor(0, {i + 1, 0})
              return
            end
          end
          vim.notify("No previous Python code chunk found", vim.log.levels.INFO)
        end, { silent = true, desc = "Previous code chunk (QMD)" })
        
        -- Add new QMD code chunk
        vim.keymap.set("n", "<leader>fcc", function()
          local line_num = vim.api.nvim_win_get_cursor(0)[1]
          local new_chunk = {
            "",
            "```{python}",
            "# New cell",
            "",
            "```",
            ""
          }
          vim.api.nvim_buf_set_lines(0, line_num, line_num, false, new_chunk)
          -- Move cursor inside the new chunk
          vim.api.nvim_win_set_cursor(0, {line_num + 3, 0})
        end, { silent = true, desc = "Create new QMD code chunk" })
        
        -- Test plotting functionality
        vim.keymap.set("n", "<leader>fT", function()
          vim.cmd("MoltenEvaluateArgument import sys; print('Python:', sys.version)")
          vim.defer_fn(function()
            vim.cmd("MoltenEvaluateArgument import matplotlib; print('Matplotlib:', matplotlib.__version__)")
          end, 500)
          vim.defer_fn(function()
            vim.cmd("MoltenEvaluateArgument import matplotlib.pyplot as plt; print('Backend:', plt.get_backend())")
          end, 1000)
        end, { silent = true, desc = "Test plotting setup" })
        
        -- Toggle output window
        vim.keymap.set("n", "<leader>ft", function()
          local wins = vim.api.nvim_list_wins()
          local molten_win = nil
          
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
            if ft == "molten-output" then
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
        
        -- Auto-initialize Molten for QMD files
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "quarto", "markdown" },
          callback = function()
            if vim.fn.search("```{python}", "nw") > 0 or vim.fn.search("```python", "nw") > 0 then
              vim.notify("QMD file with Python code detected. Use <leader>fi to initialize Molten", vim.log.levels.INFO)
            end
          end,
        })
        
        -- Enhanced highlighting for QMD code chunks
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "quarto", "markdown" },
          callback = function()
            -- Highlight Python code chunks differently
            vim.cmd([[
              syntax region qmdPythonChunk start=/^```{python}/ end=/^```/ contains=@python
              syntax region qmdPythonChunk start=/^```python/ end=/^```/ contains=@python
              highlight link qmdPythonChunk Special
            ]])
          end,
        })
        
      end, 1000)
    end
  },

  -- Optional: Quarto support plugin
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter"
    },
    ft = { "quarto", "markdown" },
    config = function()
      require('quarto').setup({
        lspFeatures = {
          enabled = true,
          languages = { "python", "bash", "html" },
        },
        codeRunner = {
          enabled = false, -- We'll use Molten instead
        },
      })
    end,
  },
}
