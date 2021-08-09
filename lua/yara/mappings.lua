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

return mod
