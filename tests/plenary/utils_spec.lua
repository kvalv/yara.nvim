local utils = require('yara.utils')

describe('string variable substitution', function()

  it('inserts simple values', function()
    local v = utils.string_replace('I am $(key1)', { key1 = 'key1' })
    assert.equals('I am key1', v)
  end)

  it('transforms a field to uppercase', function()
    local mods = {}
    mods['outer.day'] = function(s, m) return s:upper() .. m end 
    local v= utils.string_replace('today is $(outer.day:!!)', {outer={day='sunday'}}, mods)
    assert.equals('today is SUNDAY!!', v)
  end)
end)
