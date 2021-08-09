local issue = require('yara.issue')
local view = require('yara.view')
local _config = require('yara.config')

_G.yara = _G.yara or {}

local function setup(config)
  _G.yara.config = _config.Config.new(config)
  _G.yara.board = issue.Board(_G.yara.config, nil)
  _G.yara.view = view.ViewState()
end

local function show()
  if _G.yara.board == nil then
    setup()
  end
  local board = _G.yara.board
  board:load_issues()
  _G.yara.view:show(board.issues)
end

return { show = show, setup = setup }
