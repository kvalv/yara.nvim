local api = vim.api

local utils = require('yara.utils')
local class = require('yara.class')

ViewState = class(function(self)
  self.win = nil
  self.buf = nil
end)

function ViewState:show(issues_list)
  local opts = {
    relative = 'editor',
    width = vim.o.columns / 2,
    height = vim.o.lines - 10,
    anchor = 'NW',
    style = 'minimal',
    border = 'rounded', -- rounded, solid, shadow, single, double
    row = 5,
    col = vim.o.columns / 4,
  }

  opts.width = 100
  opts.height = 300
  -- opts.width = math.min(longest + 2, vim.o.columns - 2)
  -- opts.height = math.min(#lines + 1, vim.o.lines - 2)
  opts.row = (vim.o.lines - opts.height) / 2
  opts.col = (vim.o.columns - opts.width) / 2

  if self.buf == nil then
    self.buf = api.nvim_create_buf(false, true)
  end
  api.nvim_buf_set_option(self.buf, 'modifiable', true)
  api.nvim_buf_set_name(self.buf, 'yara2')
  api.nvim_buf_set_option(self.buf, 'filetype', 'yara')
  api.nvim_buf_set_option(self.buf, 'bufhidden', 'wipe')

  if self.win == nil then
    self.win = api.nvim_open_win(self.buf, true, opts)
  end

  self.ns_id = api.nvim_create_namespace('yara')
  self.active_issues_list = issues_list

  api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
  local i = 0
  local fmt = _G.yara.config.format.lines
  local transforms = _G.yara.config.format.transforms
  for issue, children in pairs(issues_list:grouped_filtered_issues()) do
    self:redraw_issue(issue, i)
    i = i + (#issue:format(fmt, transforms))

    for _, c in ipairs(children) do
      self:redraw_issue(c, i)
      i = i + (#c:format(fmt, transforms))
    end
  end

  api.nvim_win_set_option(self.win, 'winhl', 'Normal:Normal')
  api.nvim_win_set_option(self.win, 'wrap', false)
  api.nvim_win_set_option(self.win, 'conceallevel', 3)
  api.nvim_win_set_option(self.win, 'concealcursor', 'nvic')
  api.nvim_buf_set_option(self.buf, 'modifiable', false)
  api.nvim_buf_set_var(self.buf, 'indent_blankline_enabled', false)
end

function ViewState:redraw_issue(issue, row)
  local i = row
  if i == nil then
    local pos = api.nvim_buf_get_extmark_by_id(self.buf, self.ns_id, issue.id, {})
    if #pos == 0 then
      utils.echo_warning(string.format('no issue with id %d found', issue.id))
      return
    end
    i = pos[1] -- one-index to zero-index
  end
  api.nvim_buf_set_option(self.buf, 'modifiable', true)

  local fmt = _G.yara.config.format.lines
  local transforms = _G.yara.config.format.transforms
  local format_lines = issue:format(fmt, transforms)
  api.nvim_buf_set_lines(self.buf, i, i + #format_lines, false, format_lines)
  api.nvim_buf_set_extmark(self.buf, self.ns_id, i, 0, { end_line = i + #format_lines, id = issue.id })

  api.nvim_buf_set_option(self.buf, 'modifiable', false)
end

function ViewState:dispose()
  print('disposed! ', self.buf, self.win)
  self.buf = nil
  self.win = nil
  self.ns_id = nil
end

--- Returns the issue id (a number) of the current issue.
function ViewState:get_current_issue()
  local row = api.nvim_win_get_cursor(0)[1]
  local offset = 0
  local marks
  repeat
    -- search repeatedly upwards until we have found our issue.
    marks = api.nvim_buf_get_extmarks(self.buf, self.ns_id, { row - 1 - offset, 0 }, { row - 1 - offset, 100 }, {})
    offset = offset + 1
  until (#marks ~= 0) or (row - 1 - offset < 0)
  assert(#marks == 1, string.format('Expected only a single extended mark to be found, got %d', #marks))
  local issue_id = marks[1][1] -- { { issue_id, row, col } } --> issue_id
  local issue = _G.yara.board.issues.issues[issue_id]
  return issue
end

return { ViewState = ViewState }
