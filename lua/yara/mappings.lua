local utils = require('yara.utils')
local mod = {}

function mod.current_issue_prev_state()
  local instance = _G.yara
  local view = instance.view
  local issue = view:get_current_issue()
  issue:prev_state()
  issue:flush_changes('jira')
  view:redraw_issue(issue)
end

function mod.current_issue_next_state()
  local instance = _G.yara
  local view = instance.view
  local issue = view:get_current_issue()
  issue:next_state()
  issue:flush_changes('jira')
  view:redraw_issue(issue)
end

function mod.toggle_filter_only_current_user()
  local instance = _G.yara
  local board = instance.board
  if board.issues.filters.by_assignee == nil then
    board.issues:filter_by_assignee(instance.config.email)
  else
    board.issues.filters.by_assignee = nil -- the toggle part
  end
  instance.view:show(board.issues)
end

function mod.filter_by_user(email)
  local instance = _G.yara
  local board = instance.board
  board.issues:filter_by_assignee(email)
  instance.view:show(board.issues)
end

function mod.toggle_filter_by_active_sprint()
  local instance = _G.yara
  local board = instance.board
  if board.issues.filters.by_sprint == nil then
    board.issues:filter_by_active_sprint()
  else
    board.issues.filters.by_sprint = nil
  end
  instance.view:show(board.issues)
end

function mod.filter_by_sprint()
  local instance = _G.yara
  local board = instance.board

  local choices = utils.unique(vim.tbl_values(utils.map_attribute('sprint', board.issues.issues)), 'name')
  table.sort(choices, function(a, b)
    if a.id == nil then
      return true
    end
    if b.id == nil then
      return false
    end
    return a.id < b.id
  end)

  local items = utils.map(function(s, i)
    return {
      key = tostring(i),
      label = utils.cond(s.name ~= nil, string.format('%s (%s)', s.name, s.state), 'backlog'),
      action = function()
        board.issues:filter_by_sprint(s.id)
        instance.view:show(board.issues)
      end,
    }
  end, choices)

  utils.menu('Choose which sprint', items, 'sprint id')
end

function mod.add_worklog()
  local instance = _G.yara
  local view = instance.view
  local issue = view:get_current_issue()
  local w = vim.fn.input('Please write your hours: ')
  local t = require('yara.time').Time.guess_from_str(w)
  issue:add_worklog(t)
  view:redraw_issue(issue)
end

return mod
