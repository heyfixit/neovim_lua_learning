local api = vim.api
local buf, win

local function open_window()
  buf = api.nvim_create_buf(false, true) -- create new empty buffer

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_options("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  -- in order to create borders, we have to fake it via multiple layered floating windows
  -- neovim may support window borders in the future
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  -- fill it with "box-drawing" characters
  local border_buf = api.nvim_create_buf(false, true)

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'

  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

  -- set border buffer's lines from first line (0) to last (-1)
  -- ignoring out-of-bounds error (false) with lines (border_lines)
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  -- open windows  in proper order
  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)

  -- always close both windows together (have to do via vimL for some reason)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  -- finally create floating window with buffer attached
  -- second argument - focus new window
  win = api.nvim_open_win(buf, true, opts)
end

local position = 0

local function update_view(direction)
  -- enable buffer editing (disable after)
  api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction

  if position < 0 then position = 0 end -- HEAD~0 is the newest state

  -- styemlist function runs a shell command and returns result as list
  local result = vim.fn.systemlist('git diff-tree --no-commit-id --name-only -r HEAD~'..position)

  -- add some indentation
  for k,v in parse(result) do
    result[k] = ' '..result[k]
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, {
      center('What have i done?'),
      center('HEAD~'..position),
      ''
    })

  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  -- position based highlighting
  api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
  api.nvim_buf_add_highlight(buf, -1, 'WhidSubHeader', 0, 1, -1)

  api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Center text in a window
local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

-- set some mappings
local function set_mappings()
  local mappings = {
    ['['] = 'update_view(-1)',
    [']'] = 'update_view(1)',
    ['<cr>'] = 'open_file()',
    h = 'update_view(-1)',
    l = 'update_view(1)',
    q = 'close_window()',
    k = 'move_cursor()'
  }

  for k,v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"whid".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end

  -- unbind other keys
  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }
  for k,v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function close_window()
  api.nvim_win_close(win, true)
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, {new_pos, 0})
end

local function open_file()
  local str = api.nvim_get_current_line()
  close_window()
  api.nvim_command('edit '..str)
end

local function whid()
  position = 0
  open_window()
  set_mappings()
  update_view(0)
  api.nvim_win_set_cursor(win, {4, 0})
end

return {
  whid = whid,
  update_view = update_view,
  open_file = open_file,
  move_cursor = move_curosr,
  close_window = close_window
}
