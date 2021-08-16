local class = require('yara.class')

Time = class(function(self, opts)
  self.seconds = (opts.seconds or 0) + (opts.minutes or 0) * 60 + (opts.hours or 0) * 60 * 60
  self.seconds = math.floor(self.seconds)
  return self
end)

function Time.guess_from_str(s)
  -- lua print(string.find('123h', '%d+h'))
  local seconds = 0
  local dct = {}
  local p = '%S+'
  dct[p .. 'h'] = function(v) return math.floor((tonumber(v) or 0) * 60 * 60) end
  dct[p .. 'm'] = function(v) return math.floor((tonumber(v) or 0) * 60) end
  -- not sure if fractional seconds make sense in jira, but whatever. We'll round it down
  -- anyways
  dct[p .. 's'] = function(v) return math.floor(tonumber(v) or 0) end
  for pat, fn in pairs(dct) do
    local i, j = string.find(s, pat)
    if i ~= nil then
      local v = string.sub(s, i, j - 1) -- remove suffix; only keep number part
      local value = tonumber(v)
      assert(value > 0, string.format('Unable to parse: "%s"', value))
      seconds = seconds + fn(value)
    end
  end
  return Time({seconds=seconds})
end

function Time:minutes()
  return math.floor(self.seconds / 60)
end

function Time:hours()
  return math.floor(self.minutes() / 60)
end

function Time:strftime(format_string)
  local seconds_left = self.seconds % 60
  local seconds = self.seconds % 60
  local minutes = math.floor((self.seconds % (60 * 60)) / 60)
  local hours = math.floor((self.seconds % (60 * 60 * 60)) / (60 * 60))


  local mapping = {}
  mapping['%%s'] = seconds
  mapping['%%m'] = minutes
  mapping['%%h'] = hours
  for k, v in pairs(mapping) do
    mapping[k:upper()] = string.format('%02d', v)
  end

  local res = format_string
  for k, v in pairs(mapping) do
    res = string.gsub(res, k, v)
  end
  return res
end

return { Time = Time }
