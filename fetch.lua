--- ffetch (All right reserved), that dummy package manager.
--- ffetch is free and open-source

---(extension) Returns a list of string where each elements is a line.
---@param self string
---@return string[]
string.lines = function (self)
  local ar = {}
  for e in self:gmatch("([^\n]*)\n?") do ar[#ar+1] = e end
  return ar
end

---(extension) Returns the percentage of differences between two strings.
---@param self string
---@param other string
---@return number
string.diffp = function(self, other)
  local max_len = math.max(#self, #other)

  if max_len == 0 then return 0 end

  local diffs = math.abs(#self - #other)
  local min_len = math.min(#self, #other)

  for i = 1, min_len do
    if self:sub(i, i) ~= other:sub(i, i) then
      if self:sub(i, i):lower() == other:sub(i, i):lower() then
        diffs = diffs + 0.5
      end
      diffs = diffs + 1
    end
  end

  return diffs / max_len * 100
end

---(extension) Returns true whenever the given table has at least one element that is the KINDA the same as the given string key.
---@param self string[]
---@param like string
---@param lim number?
---@return boolean found, integer[] indexes
string.containslike = function (self, like, lim)
  lim = lim or 0.2
  local okays = {}
  for key, value in ipairs(self) do
    if value:diffp(like) >= lim then
      okays[#okays+1] = key
    end
  end

  return #okays > 0, okays
end

---(extension) Selects elements by traits, which are defined as selected when the 'pred' predicate returns true.
---@generic T
---@param self T[]
---@param pred fun(pos: integer, val: T?):boolean
---@return integer[] Indexes
table.select = function (self, pred)
  local indexes = {}
  for index, value in ipairs(self) do
    if pred(index, value) then
      indexes[#indexes+1] = index
    end
  end

  return indexes
end

---(extension) Returns the index of all elements that has the same value than "val"
---@generic T
---@param self T[]
---@param val T
---@return integer[] Indexes
table.indexof = function (self, val)
  local indexes = {}
  for index, value in ipairs(self) do
    if value == val then
      indexes[#indexes+1] = index
    end
  end

  return indexes
end

---(extension) Returns keys that LOOK like 'lik'
---@generic T
---@param self table<string, T>
---@param like string
---@param lim number?
table.haskeylike = function (self, like, lim)
  lim = lim or 0.6
  local okays = {}
  for key, _ in pairs(self) do
    if tostring(key):diffp(like) >= lim then
      okays[#okays+1] = key
    end
  end

  return #okays > 0, okays
end

---(extension) Returns the first index of the element that is the same as "val"
---@generic T
---@param self T[]
---@param val T
---@return integer index
table.firstof = function (self, val)
  for index, value in ipairs(self) do
    if value == val then
      return index
    end
  end

  return -1
end

---(extension) Duplicates a table.
---@generic K, V
---@param self table<K, V>
---@return table<K, V>
table.duplicate = function (self)
  local new = {}
  for key, value in pairs(self) do
    new[key] = value
  end

  return new
end

---(extension) Joins multiple tables together.
---@generic K, V
---@param self table<K, V> First table.
---@param ... table<K, V>? Other tables.
---@return table<K, V> result Resulting table that contains a merge of all tables including 'self'.
table.join = function (self, ...)
  local tables = { ... }
  local mine = table.duplicate(self)

  for _, table in ipairs(tables) do
    for key, value in pairs(table) do
      mine[key] = value
    end
  end

  return mine
end

---(extension) Returns the key that has a value like the given traits, if any. Otherwise, returns nil.
---@generic K, V
---@param self table<K, V> Table on which the reseach has to perform on.
---@param traits V Traits
---@return K? key
table.contains = function (self, traits)
  for key, value in pairs(self) do
    if value == traits then return key end
  end
end

local ffetch = {}

---Expects eval to be true, otherwise it calls fun with forwarded arguments.
---@generic Args... Forwarded arguments' type.
---@param eval boolean|nil|any Evaluation.
---@param fun fun(fargs: Args...):any|nil Function called when the evaluation evaluates to an equivalent to "false"
---@param ...Args... Forwarded arguments.
ffetch.expect = function (eval, fun, ...)
  if not eval or eval == nil then
    fun(...)
  end
end

---@generic Args..., R...
---@param fun fun(...:Args...):...: R... Function object.
---@param ... Args...  Arguments to forward.
---@return fun():...: R... forwarded Forwarded function object.
ffetch.forward = function (fun, ...)
  local forwarded = {...}
  return function ()
    return fun(table.unpack(forwarded))
  end
end

---@generic Args..., R...
---@param fun fun(...: Args...):...: R... Function object.
---@param ... Args... Arguments to forward.
---@return string bin Packed function, that you may call without arguments.
ffetch.fwrdbin = function (fun, ...)
  local pack = { ... }
  return string.dump(function ()
    return fun(table.unpack(pack))
  end)
end

local forward = ffetch.forward
local expect = ffetch.expect

local sys = {}
ffetch.sys = sys

---Checks wether you're on a UNIX System or a MS-DOS-like system.
---@return boolean
sys.isunix = function ()
  return package.cpath:find('\\') == nil
end

---Returns true when you're running this code on a Windows computer.
---@return boolean
sys.iswindows = function ()
  return package.cpath:find('\\') ~= nil
end

---Returns true when you're on macOS.
---@return boolean
sys.ismacos = function ()
  if not sys.isunix() then return false end
  local p = io.popen("uname -s 2>/dev/null", "r")
  if not p then return false end

  local result = p:read("*l")
  p:close()
  return result == "Darwin"
end

---Returns true when you're on Linux.
---@return boolean
sys.islinux = function ()
  return not (sys.ismacos() or sys.iswindows())
end

---Launches a process with Lua's io.popen function.
---@param prun string Program to run.
---@param ... any Extra arguments
---@return {
---suc: boolean,
---exitcode: 'exit'|'signal'|'unknown', 
---code: integer, 
---stdout: string} Output
sys.launch = function (prun, ...)
  local pcmd = prun .. " "
  for i, v in ipairs({...}) do
    pcmd = pcmd .. (' "%s" '):format(tostring(v))
  end

  pcmd = pcmd .. ' 2>&1'

  local prog, err = io.popen(pcmd, 'r')
  local close, stdout
  if prog then
    stdout = prog:read("a")
    close = {prog:close()}
  else
    stdout = err
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

sys.fs = {}

---@param ...string Directories to create. This also creates parents.
---@return boolean success
sys.fs.mkdir = function (...)
  local p = 'mkdir'
  if sys.isunix() then p = 'mkdir -p' end
  return sys.launch(p, ...).suc
end

---Returns what I use as home directory.
---@return string path
sys.fs.usrhome = function ()
  if sys.isunix() then
    return (os.getenv('HOME') or './')
  else
    return (os.getenv('USERPROFILE') or './')
  end
end

---Returns the base directory for ffetch. This directory would ALWAYS exists.
---@return string path
sys.fs.home = function ()
  local p
  if sys.isunix() then
    p = (os.getenv('HOME') or './') .. '/.ffetch/'
  else
    p = (os.getenv('USERPROFILE') or './') .. '/.ffetch/'
  end

  if not sys.fs.exists(p) then
    sys.fs.mkdir(p)
  end

  return p
end

---Returns true when the element 'p' exists
---@param p string file to test
---@return boolean exists
sys.fs.exists = function (p)
  local f = io.open(p, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

---Removes the given elements.
---@param ... string Elements to remove
sys.fs.rm = function (...)
  if sys.isunix() then
    sys.launch('rm', '-rf', ...)
  else
    sys.launch('rmdir', ...)
  end
end

---Returns all entries (files and directories) at one depth level in a given directory.
---@param dir string The directory in which the blob is made.
---@return string[]
sys.fs.entries = function (dir)
  if sys.isunix() then
    return sys.launch('ls', dir).stdout:lines()
  else
    return sys.launch('dir', '/b', dir).stdout:lines()
  end
end

---Returns all files at one depth level in a given directory.
---@param dir string The directory in which the blob is made.
---@return string[]
sys.fs.files = function (dir)
  if sys.isunix() then
    return sys.launch(('ls -p %s | grep -v "/$"'):format(dir)).stdout:lines()
  else
    return sys.launch('dir', '/b', '/a-d', dir).stdout:lines()
  end
end

---Returns all folders at one depth level in a given directory.
---@param dir string The directory in which the blob is made.
---@return string[]
sys.fs.folders = function (dir)
  if sys.isunix() then
    return sys.launch(('ls -d */ %s'):format(dir)).stdout:lines()
  else
    return sys.launch('dir', '/b', '/ad', dir).stdout:lines()
  end
end

---Represents the famous Git CLI, but in a Lua-ish way. It uses system command injections internally.
local git = {}
ffetch.git = git
git.git = 'git'

---@param pwd string? Path where the Git command happens.
---@param err proghandler? Error handler or extra arguments
---@param ... any? Extra arguments
---@return boolean sucess
git.fetch = function (pwd, err, ...)
  ---@type any
  local extra = ''
  if type(err) ~= "function" then extra = err end
  pwd = pwd or '.'

  local r = sys.launch(git.git, '-C', pwd, 'fetch', extra, ...)
  if not r.suc and type(err) == "function" then
    err(r.suc, r.exitcode, r.code, r.stdout)
    return false
  end

  return r.suc
end

---@param repo string Git repository to clone.
---@param path string Where the repository has to be cloned.
---@param err proghandler? Error handler? Or extra arguments.
---@param ... any? Extra arguments.
---@return boolean success
git.clone = function (repo, path, err, ...)
  local r = sys.launch(git.git, 'clone', repo, path, ...)
  if not r.suc and type(err) == "function" then
    err(r.suc, r.exitcode, r.code, r.stdout)
    return false
  end

  return r.suc
end

---@alias git.branch.mode 'list'|'current'

---Operates a git branch command. This function has shortcuts, such as a given argument 'list' that will list all branches, or
---'current' that will return the current Git branch.
---@param pwd string? Path where the Git command happens.
---@param errh proghandler<nil>|string|git.branch.mode|any|nil Error handler, or, extra arguments.
---@param mode string|git.branch.mode|any|nil Mode (see git.branch.mode) or extra arguments.
---@param ... any? Extra arguments.
---@return boolean success, string output
git.branch = function (pwd, errh, mode, ...)
  if type(errh) ~= "nil" then mode = nil
  elseif type(errh) ~= "function" then mode = tostring(errh) end

  if mode == 'list' then
    mode = "--format=%(refname:short)"
  elseif mode == 'current' then
    mode = "--show-current"
  elseif not mode then
    mode = ''
  end

  local out = sys.launch(git.git, '-C', pwd, 'branch', mode, ...)

  if not out.suc and type(errh) == "function" then
    errh(out.suc, out.exitcode, out.code, out.stdout)
    return false, ''
  end

  return out.suc, out.stdout
end

---@param branch string
---@param pwd string?
---@param ... any
---@return boolean, string, integer, 'exit'|'signal'|'unknown'
git.switch = function (branch, pwd,  ...)
  pwd = pwd or '.'
  local ret = sys.launch(git.git, '-C', pwd, 'switch', branch, ...)
  return ret.suc, ret.stdout, ret.code, ret.exitcode
end

ffetch.pkg = {}
local pkg = ffetch.pkg

---Returns a path to a possible config file.
---@param rel string? If you you want to load from another directory
---@return string path The configuration file path.
pkg.config = function (rel)
  local filename = 'config.fetch'
  if rel and rel ~= '' then
    return rel .. '/' .. filename
  end

  return sys.fs.home() .. '/' .. filename
end

---Loads the config file and returns all lines that are Git repositories. They can be a server, or, local servers. Idc.
---@param config string Configuration file path
---@return string[] lines Lines of this file.
pkg.load = function (config)
  local file = io.open(config, "r")
  if not file then return {} end
  local lines = {}

  for l in file:lines() do
    table.insert(lines, l)
  end

  file:close()
  return lines
end

---Returns available packages of a package file. This file must be a Lua file returning a table.
---@generic T
---@param pkgfile string
---@param env table?
---@return boolean sucess, table resources
pkg.packagesof = function (pkgfile, env)
  local fn = assert(loadfile(pkgfile, "bt", env))
  if not fn then return false, {} end
  local ok, obj = pcall(fn)
  if not ok then return assert(ok, obj) end

  if type(obj) ~= "table" then
    return assert(false, 'Package file must return a table')
  end

  return true, obj
end

---Searches a package amoung the servers
---@param modname string The package that you're searching for
---@param servers string[]? Servers where ffetch will search for. If none is given, it'll load from the default configuration.
---@param print (fun(...:any?):nil)? A verbose callback. By default, it is assigned to the '_G.print' function.
---@return string? server Nil when the package is not found.
pkg.search = function (modname, servers, print)
  print = print or _G.print
  print(("searching for package '%s'"):format(modname))
  for _, server in ipairs(servers or {}) do
    print(("searching in server '%s'"):format(server))
    local suc, out = git.branch('list', '-C', server)
    if suc and table.contains(out:lines(), modname) then
      return server
    end
  end

  print(("package '%s' not found!"):format(modname))
end

---Downloads a package
---@param modname string
---@param modpath string
---@param print fun(...)?
pkg.download = function (modname, modpath, print)
  ---@todo version?
  print = print or _G.print
  if not git.switch(modname, modpath) then
    print('failed to switch on the correct branch!')
    return false
  end

  -- idk

  return true
end

---Installs a package
---@param modname string
---@param servers string[]?
---@param print fun(...)?
pkg.install = function (modname, servers, print)
  print = print or _G.print
end

---@param repo string
---@param name string
---@return boolean
pkg.add = function (name, repo)
  local path = ('%s/%s/%s'):format(sys.fs.home(), 'servers', name)
  if not git.clone(repo, path, function (suc, exitcode, code, stdout)
    print(("failed to add server '%s' (%d - %s):\n%s"):format(repo, code, exitcode, stdout))
    return nil
  end) then return false end

  local file = io.open(pkg.config(), "a")
  if not file then return false end

  file:write(path, '\n'):close()

  return true
end

---Fetches updates
---@param rel string?
---@param print fun(...)?
pkg.fetch = function (rel, print)
  print = print or _G.print
  local servers = pkg.load(pkg.config(rel))

  for index, value in ipairs(servers) do
    print(("fetching changes for server '%s'"):format(value))
    if not git.fetch(value, function (suc, exitcode, code, stdout)
      print(suc, exitcode, code, stdout)
      return nil
    end) then
      print(("failed to fetch changes for server '%s'"):format(value))
    end
  end
end

pkg.fetch()

return ffetch