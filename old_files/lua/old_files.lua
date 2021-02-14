-- main function
local function oldfiles()
  -- prevent opening multiple navigation windows
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  else
    create_win()
  end

  redraw()
end

-- Window Setup
local function create_win()
  -- get handle to window we were in before opening new window
  start_win = vim.api.nvim_get_current_win()

  -- open a new vert split on the farthest right
  vim.api.nvim_command('botright vnew')

  -- get handle to this new nav window
  win = vim.api.nvim_get_current_win()

  -- get handle to its buffer
  buf = vim.api.nvim_get_current_buf()

  -- all vim buffers must have unique identifiers
  -- can use the buffer handle which is just a number
  vim.api.nvim_buf_set_name(buf, 'Oldfiles #' .. buf)

  -- no file prevents marking buffer as modified to avoid unsaved changes warnings
  -- some plugins treat nofile buffers different i.e. coc.nvim skips autocompletion
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- don't need swap file
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  -- destroy buffer on hide
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- good practice to set custom filetypes
  -- allows users to create their own autocommands/colorschemes on the filetype
  -- prevents collisions with other plugins
  vim.api.nvim_buf_set_option(buf, 'filetype', 'nvim-oldfile')

  -- turn off line wrap and tun on current line highlight
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- setup mappings
  set_mappings()
end

-- Drawing Function
local function redraw()
  -- first allow changes to buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- get window height
  local items_count = vim.api.nvim_win_get_height(win) - 1
  local list = {}

  -- nightly build way of getting old files
  local oldfiles = vim.v.oldfiles
  -- stable version way
  local oldfiles = vim.api.nvim_get_vvar('oldfiles')

  -- populate list with X last items from oldfiles
  for i = #oldfiles, #oldfiles - items_count, -1 do
    -- built-in vim function fnamemodify makes paths relative
    -- nightly way to call
    local path = vim.fn.fnamemodify(oldfiles[i], ':.')

    -- stable way
    local path = vim.api.nvim_call_function('fnamemodify', {oldfiles[i], ':.'})

    -- since iterating backwards, insert backwards to keep order
    table.insert(list, #list + 1, path)
  end

  -- set buffers lines from results
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)

  -- finish with turning off buffer modifiable state
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Opening Files
-- Will allow users to open files in 5 different ways
-- In a new tab
-- In a horizontal split
-- In a vertical split
-- In the current window
-- In preview mode (keep focus on nav window)

local function open()
  -- get path from line user pressed enter on
  local path = vim.api.nvim_get_current_line()

  -- if starting window exists
  if vim.api.nvim_win_is_valid(start_win) then
    -- move to it
    vim.api.nvim_set_current_win(start_win)
    -- and edit chosen file
    vim.api.nvim_command('edit ' .. path)
  else
    -- no starting window, create a new one from left side
    vim.api.nvim_command('leftabove vsplit ' .. path)
    -- set it as new starting window
    start_win = vim.api.nvim_get_current_win()
  end
end

-- close window after opening desired file
local function close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- now ready to make two first opening functions
local function open_and_close()
  open() -- open new file
  close() -- close nav window
end

local function preview()
  open() -- open new file
  -- since preview mode is meant to keep focus on nav,
  -- re-focus nav window
  vim.api.nvim_set_current_win(win)
end

-- make splits
local function split(axis)
  local path = vim.api.nvim_get_current_line()

  -- two scenarios
  if vim.api.nvim_win_is_valid(start_win) then
    vim.api.nvim_set_current_win(start_win)
    -- v is passed in axis arg if split is vertical
    -- nothing otherwise
    vim.api.nvim_command(axis .. 'split ' .. path)
  else
    -- if no starting window, make one on left
    vim.api.nvim_command('leftabove ' .. axis .. 'split ' .. path)
    -- do not need to set starting window since splits always close nav
  end
end

-- open in new tab
local function open-in_tab()
  local path = vim.api.nvim_get_current_line()
  vim.api.nvim_command('tabnew ' .. path)
  close()
end

-- add key mappings, export all public functions, add a command to trigger nav
local function set_mappings()
  local mappings = {
    q = 'close()',
    ['<cr>'] = 'open_and_close()',
    v = 'split("v")',
    s = 'split("")',
    p = 'preview()',
    t = 'open_in_tab()'
  }

  for k,v in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"nvim-oldfile".' .. v .. '<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
end

-- export functions
return {
  oldfiles = oldfiles,
  close = close,
  open_and_close = open_and_close,
  preview = preview,
  open_in_tab = open_in_tab,
  split = split
}
