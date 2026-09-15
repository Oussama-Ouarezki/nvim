-- Add this to your vim-jukit configuration
return{
  'luk400/vim-jukit',
  ft = { 'python', 'julia', 'r', 'ipynb' },
  config = function()
    -- Force reload the plugin
    vim.cmd('runtime! plugin/jukit.vim')
    vim.cmd('runtime! autoload/jukit.vim')
    
    -- Your normal configuration
    vim.g.jukit_shell_cmd = 'ipython3'
    vim.g.jukit_terminal = 'kitty'  -- Since you're using kitty
    vim.g.jukit_mappings = 0
    vim.g.jukit_save_output = 1
    vim.g.jukit_show_prompt = 0
    vim.g.jukit_inline_plotting = 1  -- Enable for kitty
    
    -- Custom keymaps (defined below)
    vim.defer_fn(function()
      -- Set up keymaps after plugin loads
      local function setup_jukit_keymaps()
        local opts = { buffer = true, noremap = true, silent = true }
        
        -- Test with a simple function first
        vim.keymap.set('n', '<leader>jtest', function()
          local ok, result = pcall(function()
            vim.cmd('call jukit#splits#output()')
          end)
          if not ok then
            print("Error: " .. result)
            print("Trying alternative method...")
            -- Alternative approach
            vim.cmd('split | terminal ipython3')
          end
        end, opts)
        
        -- Other keymaps...
      end
      
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python', 'julia', 'r', 'ipynb' },
        callback = setup_jukit_keymaps,
      })
    end, 100)  -- Delay execution
  end,
}
