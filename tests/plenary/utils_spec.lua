local utils = require('yara.utils')

describe('string variable substitution', function()

  it('inserts simple values', function()
    local v = utils.string_replace('I am $(key1) and I should be default: $(key2)', { key1 = 'key1' }, 'default')
    assert.equals('I am key1 and I should be default: default', v)
  end)

  it('transforms a field to uppercase', function()
    local mods = {}
    mods['outer.day'] = function(s, m) return s:upper() .. m end 
    local v= utils.string_replace('today is $(outer.day:!!)', {outer={day='sunday'}}, 'default', mods)
    assert.equals('today is SUNDAY!!', v)
  end)
end)
