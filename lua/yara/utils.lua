local uv = vim.loop
local utils = {}

---@param file string
---@param callback function
function utils.readfile(file, callback)
  uv.fs_open(file, 'r', 438, function(err1, fd)
    if err1 then
      return callback(err1)
    end
    uv.fs_fstat(fd, function(err2, stat)
      if err2 then
        return callback(err2)
      end
      uv.fs_read(fd, stat.size, 0, function(err3, data)
        if err3 then
          return callback(err3)
        end
        uv.fs_close(fd, function(err4)
          if err4 then
            return callback(err4)
          end
          local lines = vim.split(data, '\n')
          table.remove(lines, #lines)
          return callback(nil, lines)
        end)
      end)
    end)
  end)
end

---@param msg string
function utils.echo_warning(msg)
  vim.cmd([[redraw!]])
  vim.cmd([[echohl WarningMsg]])
  vim.cmd(string.format('echom "%s"', msg))
  vim.cmd([[echohl None]])
end

---@param msg string
function utils.echo_info(msg)
  vim.cmd([[redraw!]])
  vim.cmd(string.format('echom "%s"', msg))
end

---@param word string
---@return string
function utils.capitalize(word)
  return (word:gsub('^%l', string.upper))
end

---@param isoweekday number
---@return number
function utils.convert_from_isoweekday(isoweekday)
  if isoweekday == 7 then
    return 1
  end
  return isoweekday + 1
end

---@param weekday number
---@return number
function utils.convert_to_isoweekday(weekday)
  if weekday == 1 then
    return 7
  end
  return weekday - 1
end

---@param tbl table
---@param callback function
---@param acc any
---@return table
function utils.reduce(tbl, callback, acc)
  for i, v in pairs(tbl) do
    acc = callback(acc, v, i)
  end
  return acc
end

--- Concat one table at the end of another table
---@param first table
---@param second table
---@return table
function utils.concat(first, second)
  for _, v in ipairs(second) do
    table.insert(first, v)
  end
  return first
end

function utils.menu(title, items, prompt)
  local content = { title .. ':' }
  local valid_keys = {}
  for _, item in ipairs(items) do
    if item.separator then
      table.insert(content, string.rep(item.separator or '-', item.length or 80))
    else
      valid_keys[item.key] = item
      table.insert(content, string.format('%s %s', item.key, item.label))
    end
  end
  prompt = prompt or 'key'
  table.insert(content, prompt .. ': ')
  vim.cmd(string.format('echon "%s"', table.concat(content, '\\n')))
  local char = vim.fn.nr2char(vim.fn.getchar())
  vim.cmd([[redraw!]])
  local entry = valid_keys[char]
  if not entry or not entry.action then
    return
  end
  return entry.action()
end

function utils.keymap(mode, lhs, rhs, opts)
  return vim.api.nvim_set_keymap(
    mode,
    lhs,
    rhs,
    vim.tbl_extend('keep', opts or {}, {
      nowait = true,
      silent = true,
      noremap = true,
    })
  )
end

function utils.buf_keymap(buf, mode, lhs, rhs, opts)
  return vim.api.nvim_buf_set_keymap(
    buf,
    mode,
    lhs,
    rhs,
    vim.tbl_extend('keep', opts or {}, {
      nowait = true,
      silent = true,
      noremap = true,
    })
  )
end

function utils.esc(cmd)
  return vim.api.nvim_replace_termcodes(cmd, true, false, true)
end

function utils.parse_tags_string(tags)
  local parsed_tags = {}
  for _, tag in ipairs(vim.split(tags or '', ':')) do
    if tag:find('^[%w_%%@#]+$') then
      table.insert(parsed_tags, tag)
    end
  end
  return parsed_tags
end

function utils.tags_to_string(taglist)
  local tags = ''
  if #taglist > 0 then
    tags = ':' .. table.concat(taglist, ':') .. ':'
  end
  return tags
end

function utils.lookup(t, ...)
  for _, k in ipairs({ ... }) do
    if t == nil or t == vim.NIL then
      return
    end
    t = t[k]
    -- if not t then
    --     return nil
    -- end
  end
  return t
end

---Returns the first index where `predicate` evaluates to true,
--or -1 if none found
function utils.tbl_index(t, predicate)
  for i, v in ipairs(t) do
    if predicate(v) then
      return i
    end
  end
  return -1
end

--- replace every occurence of %key in the str `str` with `obj.key`
--example: str="today it is %(day)", obj={day="saturday"} --> "today it is saturday"
function utils.string_replace(str, obj, default)
  while true do
    local lower, upper, v = string.find(str, '%$%(([%w_]*)%)')
    if v == nil then
      break
    end
    str = string.sub(str, 1, lower - 1) .. (obj[v] or default) .. string.sub(str, upper + 1)
  end
  return str
end

function utils.cond(test_expr, then_expr, else_expr)
  if test_expr then
    return then_expr
  end
  return else_expr
end

function utils.filter(func, items)
  local out = {}
  for _, v in pairs(items) do
    if func(v) then
      table.insert(out, v)
    end
  end
  return out
end

function utils.ifilter(func, items)
  local out = {}
  for _, v in ipairs(items) do
    if func(v) then
      table.insert(out, v)
    end
  end
  return out
end

function utils.map(func, items)
  local out = {}
  local i = 0
  for k, v in pairs(items) do
    out[k] = func(v, i)
    i = i + 1
  end
  return out
end

-- utility function to get the attribute from each object in `items`
-- map_attribute('foo', [{foo=123}, {foo=234}]) --> {123, 234}
function utils.map_attribute(attr, items, missing)
  return utils.map(function(e)
    return e[attr] or missing
  end, items)
end

function utils.unique(items, key)
  local hash = {}
  local res = {}

  for _, v in ipairs(items) do
    local h = (utils.cond(key == nil, v, v[key])) or "nil"
    if not hash[h] then
      res[#res + 1] = v
      hash[h] = true
    end
  end
  return res
end

return utils
