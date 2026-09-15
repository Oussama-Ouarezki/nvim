return {
	{
		"g0t4/iron.nvim",
		branch = "fix-clear-repl",
		enabled = true,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local iron = require("iron.core")
			local ll = require("iron.lowlevel")
			local map = vim.keymap.set
			
			-- Flash highlight function
			local function flash_range(start_pos, end_pos)
				local bufnr = vim.api.nvim_get_current_buf()
				local ns_id = vim.api.nvim_create_namespace("iron_flash")
				
				-- Create highlight group if it doesn't exist
				vim.api.nvim_set_hl(0, "IronFlash", { bg = "#3e4451", fg = "#e06c75" })
				
				-- Add highlight
				vim.api.nvim_buf_add_highlight(bufnr, ns_id, "IronFlash", start_pos[1] - 1, start_pos[2], end_pos[2])
				
				-- Remove highlight after 200ms
				vim.defer_fn(function()
					vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
				end, 200)
			end
			
			-- Flash current line
			local function flash_line()
				local line_num = vim.api.nvim_win_get_cursor(0)[1]
				local line_content = vim.api.nvim_get_current_line()
				flash_range({line_num, 0}, {line_num, #line_content})
			end
			
			-- Flash visual selection
			local function flash_visual_selection()
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				for line = start_pos[2], end_pos[2] do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					local start_col = (line == start_pos[2]) and start_pos[3] - 1 or 0
					local end_col = (line == end_pos[2]) and end_pos[3] or #line_content
					flash_range({line, start_col}, {line, end_col})
				end
			end
			
			-- Flash current word
			local function flash_word()
				local cursor_pos = vim.api.nvim_win_get_cursor(0)
				local line_num = cursor_pos[1]
				local col_num = cursor_pos[2]
				local line_content = vim.api.nvim_get_current_line()
				
				-- Find word boundaries
				local word_start = col_num
				local word_end = col_num
				
				-- Find start of word
				while word_start > 0 and line_content:sub(word_start, word_start):match("[%w_]") do
					word_start = word_start - 1
				end
				word_start = word_start + 1
				
				-- Find end of word
				while word_end <= #line_content and line_content:sub(word_end + 1, word_end + 1):match("[%w_]") do
					word_end = word_end + 1
				end
				
				flash_range({line_num, word_start - 1}, {line_num, word_end})
			end
			
			-- Flash from current position to end of file
			local function flash_to_end()
				local cursor_pos = vim.api.nvim_win_get_cursor(0)
				local start_line = cursor_pos[1]
				local total_lines = vim.api.nvim_buf_line_count(0)
				
				for line = start_line, math.min(start_line + 10, total_lines) do -- Flash first 10 lines as indicator
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then
						flash_range({line, 0}, {line, #line_content})
					end
				end
			end
			
			-- Flash from current position to beginning of file
			local function flash_to_beginning()
				local cursor_pos = vim.api.nvim_win_get_cursor(0)
				local end_line = cursor_pos[1]
				
				for line = math.max(1, end_line - 10), end_line do -- Flash last 10 lines as indicator
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then
						flash_range({line, 0}, {line, #line_content})
					end
				end
			end
			
			-- Flash and send function definition
			local function flash_and_send_function()
				local current_line = vim.api.nvim_win_get_cursor(0)[1]
				
				-- Find function start (look backwards for 'def ' or 'class ')
				local func_start = current_line
				for line = current_line, 1, -1 do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("^%s*def ") or line_content:match("^%s*class ") then
						func_start = line
						break
					end
				end
				
				-- Find function end (next line with same or less indentation that's not empty)
				local base_indent = vim.api.nvim_buf_get_lines(0, func_start - 1, func_start, false)[1]:match("^%s*")
				local func_end = vim.api.nvim_buf_line_count(0)
				
				for line = func_start + 1, vim.api.nvim_buf_line_count(0) do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then -- Non-empty line
						local line_indent = line_content:match("^%s*")
						if #line_indent <= #base_indent and not line_content:match("^%s*#") then
							func_end = line - 1
							break
						end
					end
				end
				
				-- Flash the function
				for line = func_start, func_end do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then
						flash_range({line, 0}, {line, #line_content})
					end
				end
				
				-- Select and send the function
				vim.api.nvim_win_set_cursor(0, {func_start, 0})
				vim.cmd("normal! V")
				vim.api.nvim_win_set_cursor(0, {func_end, 0})
				
				vim.schedule(function()
					iron.visual_send()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end
			
			-- Flash and send loop/control structure
			local function flash_and_send_loop()
				local current_line = vim.api.nvim_win_get_cursor(0)[1]
				
				-- Find loop start (look backwards for control structures)
				local loop_start = current_line
				for line = current_line, 1, -1 do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("^%s*for ") or line_content:match("^%s*while ") or 
					   line_content:match("^%s*if ") or line_content:match("^%s*with ") or
					   line_content:match("^%s*try:") then
						loop_start = line
						break
					end
				end
				
				-- Find loop end
				local base_indent = vim.api.nvim_buf_get_lines(0, loop_start - 1, loop_start, false)[1]:match("^%s*")
				local loop_end = vim.api.nvim_buf_line_count(0)
				
				for line = loop_start + 1, vim.api.nvim_buf_line_count(0) do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then -- Non-empty line
						local line_indent = line_content:match("^%s*")
						if #line_indent <= #base_indent and not line_content:match("^%s*#") then
							loop_end = line - 1
							break
						end
					end
				end
				
				-- Flash the loop
				for line = loop_start, loop_end do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then
						flash_range({line, 0}, {line, #line_content})
					end
				end
				
				-- Select and send the loop
				vim.api.nvim_win_set_cursor(0, {loop_start, 0})
				vim.cmd("normal! V")
				vim.api.nvim_win_set_cursor(0, {loop_end, 0})
				
				vim.schedule(function()
					iron.visual_send()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end
			
			local function get_or_open_repl()
				local meta = vim.b.repl
				if not meta or not ll.repl_exists(meta) then
					local ft = ll.get_buffer_ft(0)
					meta = ll.get(ft)
				end
				if not ll.repl_exists(meta) then
					return nil
				end
				return meta
			end
			
			-- Ensure REPL is open before sending
			local function ensure_repl_open()
				local meta = get_or_open_repl()
				if not meta then
					iron.repl_for(vim.api.nvim_buf_get_option(0, "filetype"))
				end
			end
			
			local function toggle_repl()
				local meta = vim.b.repl
				if meta and ll.repl_exists(meta) then
					iron.hide_repl()
				else
					iron.repl_for(vim.api.nvim_buf_get_option(0, "filetype"))
				end
			end
			
			local function my_clear()
				ensure_repl_open()
				iron.clear_repl()
			end
			
			local function send_visual_and_jump()
				ensure_repl_open()
				flash_visual_selection()
				iron.visual_send()
				vim.schedule(function()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
					vim.cmd("normal! j")
				end)
			end
			
			-- Send current word
			local function send_word()
				ensure_repl_open()
				flash_word()
				-- Select the word and send it
				vim.cmd("normal! viw")
				vim.schedule(function()
					iron.visual_send()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end
			
			-- Send from current position to end of file
			local function send_to_end()
				ensure_repl_open()
				flash_to_end()
				-- Select from current position to end
				vim.cmd("normal! vG")
				vim.schedule(function()
					iron.visual_send()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end
			
			-- Send from current position to beginning of file
			local function send_to_beginning()
				ensure_repl_open()
				flash_to_beginning()
				-- Select from current position to beginning
				vim.cmd("normal! vgg")
				vim.schedule(function()
					iron.visual_send()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end
			
			-- New function to setup pandas display options
			local function setup_pandas_display()
				ensure_repl_open()
				local pandas_config = {
					"import pandas as pd",
					"pd.set_option('display.max_columns', None)",
					"pd.set_option('display.width', None)", 
					"pd.set_option('display.max_colwidth', 50)",
					"pd.set_option('display.max_rows', 20)",
					"print('Pandas display configured for full output')"
				}
				
				-- Send each configuration line
				for _, line in ipairs(pandas_config) do
					iron.send_line(line)
				end
			end
			
			-- Simplified keybindings with leader r
			map("n", "<leader>rt", toggle_repl, { desc = "Toggle REPL" })
			map("n", "<leader>rx", my_clear, { desc = "Clear REPL" })
			map("n", "<leader>rs", iron.repl_restart, { desc = "Restart REPL" })
			map("n", "<leader>rd", setup_pandas_display, { desc = "Setup pandas display options" })
			
			-- Main execution keybindings
			map("v", "<leader>r", send_visual_and_jump, { desc = "Send visual selection" })
			map("n", "<leader>rr", function()
				ensure_repl_open()
				flash_line()
				iron.send_line()
				vim.schedule(function()
					vim.cmd("normal! j")
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end, { desc = "Send current line and jump" })
			
			-- Range execution keybindings
			map("n", "<leader>rgg", send_to_beginning, { desc = "Send from cursor to top of file" })
			map("n", "<leader>rG", send_to_end, { desc = "Send from cursor to bottom of file" })
			
			-- Python-specific execution keybindings
			map("n", "<leader>rf", flash_and_send_function, { desc = "Send current function/class" })
			map("n", "<leader>rl", flash_and_send_loop, { desc = "Send current loop/control structure" })
			
			-- Additional useful keybindings
			map("n", "<leader>rw", send_word, { desc = "Send current word" })
			map("n", "<leader>rF", function()
				ensure_repl_open()
				-- Flash entire file
				local total_lines = vim.api.nvim_buf_line_count(0)
				for line = 1, math.min(total_lines, 10) do -- Flash first 10 lines as indicator
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					flash_range({line, 0}, {line, #line_content})
				end
				iron.send_file()
			end, { desc = "Send entire file" })
			
			map("n", "<leader>rp", function()
				ensure_repl_open()
				-- Flash paragraph
				local start_line = vim.fn.search("^$", "bnW") + 1
				local end_line = vim.fn.search("^$", "nW")
				if end_line == 0 then end_line = vim.api.nvim_buf_line_count(0) end
				end_line = end_line - 1
				
				for line = start_line, end_line do
					local line_content = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1] or ""
					if line_content:match("%S") then -- Only flash non-empty lines
						flash_range({line, 0}, {line, #line_content})
					end
				end
				
				iron.send_paragraph()
				vim.schedule(function()
					vim.cmd("normal! }")
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
				end)
			end, { desc = "Send paragraph and jump" })
			
			iron.setup({
				config = {
					scratch_repl = true,
					-- Smaller REPL window that stays fixed size
					repl_open_cmd = "vertical botright 70 split | setlocal winfixwidth",
					repl_definition = {
						_DEFAULT = {
							command = { "bash" },
						},
						sh = {
							command = { "fish" },
						},
						lua = {
							command = { "lua" },
							block_deviders = { "-- %%", "--%%" },
						},
						python = {
							command = { "/home/oussama/miniconda3/envs/pyml/bin/ipython", "--no-autoindent" },
							format = function(lines, extras)
								local result = require("iron.fts.common").bracketed_paste_python(lines, extras)
								return vim.tbl_filter(function(line)
									return not string.match(line, "^%s*#")
								end, result)
							end,
						},
					},
				},
			})
			
			-- Auto-command to maintain REPL window size
			vim.api.nvim_create_autocmd("WinEnter", {
				pattern = "*",
				callback = function()
					if vim.bo.filetype == "iron" then
						vim.cmd("vertical resize 70")
						vim.cmd("setlocal winfixwidth")
					end
				end,
			})
		end,
	},
}
