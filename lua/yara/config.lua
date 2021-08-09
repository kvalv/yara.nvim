local class = require('yara.class')

local Config = class(function(self)
  self.jira_executable = nil
  self.email = nil
end)

local defaults = {
  jira_executable = 'jira',
}

function Config.new(opts)
  local out = Config()
  for k, v in pairs(vim.tbl_extend('keep', opts, defaults)) do
    out[k] = v
  end
  return out
end

return { Config = Config }
