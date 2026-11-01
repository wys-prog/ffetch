local fmt = {}

---@param len integer
---@param percentage number
---@return string
fmt.progressbar = function(len, percentage)
  percentage = math.max(0, math.min(100, percentage))

  local done = math.floor(len * percentage / 100)
  local bar = ('━'):rep(done)
  .. (done < len and '╸' or '')
  .. ('─'):rep(len - done - (done < len and 1 or 0))

  return bar
end

local rendering = {
  ---@type { id: integer, line: integer, content: string }[]
  lines = {},
  lastline = 1,
  ids = math.mininteger,
}

---@return integer
rendering.newid = function ()
  rendering.ids = rendering.ids + 1
  return rendering.ids
end

---@param content any
---@return integer
rendering.line = function (content)
  local id = rendering.newid()
  rendering.lines[#rendering.lines+1] = { id = id, line = rendering.lastline, content = tostring(content) }
  rendering.lastline = rendering.lastline + 1
  return id
end

---@param id integer
rendering.remove = function (id)
  for i = #rendering.lines, 1, -1 do
    if rendering.lines[i].id == id then
      table.remove(rendering.lines, i)
      return
    end
  end

  table.sort(rendering.lines, function (a, b)
    io.write(("\x1B[%d;1H\x1B[2K"):format(a.line)):flush()
    return a.line < b.line
  end)

  local i = 0
  for _, value in ipairs(rendering.lines) do
    value.line = i
    i = i + 1
    rendering.lastline = i+1
  end
end

---@param v any
---@overload fun(v: any, type: 'string'): string
---@overload fun(v: any, type: 'number'): number
---@overload fun(v: any, type: 'boolean'): boolean
---@overload fun(v: any, type: 'userdata'): userdata
---@overload fun(v: any, type: 'table'): table
---@overload fun(v: any, type: 'thread'): thread
---@overload fun(v: any, type: 'nil'): nil
local argcheck = function (v, type)
  assert(_G.type(v) == type, ("expected type '%s' for value 'v', got '%s'"):format(type, _G.type(v)))
  return v
end

rendering.update = function (...)
  local fargs = { ... }
  if #fargs == 0 then
    for _, value in ipairs(rendering.lines) do
      io.write(("\x1B[%d;1H\x1B[2K"):format(value.line)):flush()
      io.write(value.content, '\n'):flush()
    end
    io.flush()
  else
    local id = argcheck(fargs[1], 'number')
    local content = argcheck(fargs[2], 'string')

    for _, value in ipairs(rendering.lines) do
      if value.id == id then
        value.content = content
      end
    end
  end
end

io.write('\x1B[2J\x1B[H')

local title = rendering.line('=== RENDERING TEST ===')
local status = rendering.line('Status: Initialisation...')
local progress = rendering.line('Progress: ' .. fmt.progressbar(30, 0))
local info = rendering.line('Informations: En attente')
local footer = rendering.line('Appuyez sur Ctrl+C pour quitter')

rendering.update()

for i = 0, 100 do
  rendering.update(progress, 'Progress: ' .. fmt.progressbar(30, i))
  rendering.update(status, ('Status: %d%%'):format(i))
  rendering.update(info, ('Informations: étape %d / 100'):format(i))

  rendering.update()

  os.execute('sleep 0.05')

  if math.random() >= 0.0298388 then
    rendering.remove(title)
  end
end

-- Suppression de lignes
os.execute('sleep 1')

rendering.remove(status)
rendering.remove(info)

rendering.update()

-- Ajout d'une nouvelle ligne après suppression
local result = rendering.line('Terminé !')
rendering.update()

os.execute('sleep 2')

