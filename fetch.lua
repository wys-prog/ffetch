--- lua fetch: a simple package manager.

local fetch = {}
local sys = {}
fetch.sys = sys

sys.isunix = function ()
  return not package.cpath:find('\\')
end

---runs a program
---@param prun string
---@param ... any
---@return {
---suc: boolean, 
---exitcode: 'exit'|'signal'|'unknown', 
---code: integer, 
---stdout: string}
sys.launch = function (prun, ...)
  local pcmd = prun .. " "
  for i, v in ipairs({...}) do
    pcmd = pcmd .. ('"%s"'):format(tostring(v))
  end

  local prog = io.popen(pcmd, "r")
  local close, stdout
  if prog then
    stdout = prog:read("a")
    close = {prog:close()}
  end

  return {
    suc = close[1] or false,
    exitcode = close[2] or 'unknown',
    code = close[3] or 1,
    stdout = stdout or '',
  }
end

---@generic T
---@alias proghandler fun(suc: boolean, 
---exitcode:'exit'|'signal'|'unknown', 
---code: integer, stdout: string):T

local git = {}
fetch.git = git

---@param err proghandler?
---@param ... any? Extra args
---@return boolean
git.fetch = function (err, ...)
  local r = sys.launch('git', 'fetch', ...)
  if not r.suc and type(err) == "function" then
    err(table.unpack(r))
    return false
  end

  return r.suc
end

---@param repo string
---@param err proghandler?
---@param ... any?
---@return boolean, string?
git.clone = function (repo, err, ...)
  local r = sys.launch('git', 'clone', repo, ...)
  if not r.suc and type(err) == "function" then
    err(table.unpack(r))
    return false
  end

  return r.suc, r.stdout:match("Cloning into '([^']+)'")
             or r.stdout:match('Cloning into "([^"]+)"')
end



return fetch