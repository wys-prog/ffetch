--- ffetch
--- A free and open source project.
--- Users shall know what they are doing with this code, and ffetch's developpers do not
--- provide ANY WARRANTY to anything that happens to users.

local sys = {}

---@param self string
---@param with string
---@return boolean
string.starts = function(self, with)
  return self:sub(1, with:len()) == with
end

---@generic T
---@param self T[]
---@param pred fun(index: integer, value: T):boolean
table.rmif = function(self, pred)
  for i = #self, 1, -1 do
    if pred(i, self[i]) then
      table.remove(self, i)
    end
  end
end

---@generic T
---@param self T[]
---@param from integer?
---@param till integer?
---@return T[]
table.take = function (self, from, till)
  local arr = {}
  from = from or 1
  till = till or #self

  for i = from, till, 1 do
    arr[#arr+1] = self[i]
  end

  return arr
end

sys.iswindows = package.config:sub(1, 1) == "\\"
sys.isunix = not sys.iswindows

---@param cmd string
---@return file*?
local function popen(cmd, ...)
  for _, value in ipairs({ ... }) do
    cmd = cmd .. (" '%s'"):format(tostring(value))
  end

  local p = io.popen(cmd .. " 2>&1", "r")
  if not p then return nil end

  return p
end

if sys.iswindows then
  sys.os = "Windows"
  sys.arch = popen("echo %PROCESSOR_ARCHITECTURE%"):read('l')
else
  sys.os = popen("uname -s"):read('l')
  sys.arch = popen("uname -m"):read('l')
end

local architectures = {
  ["AMD64"] = "x86_64",
  ["x86_64"] = "x86_64",
  ["x64"] = "x86_64",
  ["i386"] = "x86",
  ["i686"] = "x86",
  ["x86"] = "x86",
  ["ARM64"] = "arm64",
  ["arm64"] = "arm64",
  ["aarch64"] = "arm64",
  ["armv7l"] = "arm",
  ["armv6l"] = "arm",
}

if sys.arch then
  sys.arch = architectures[sys.arch] or sys.arch
end

sys.ismacos = sys.os == "Darwin"
sys.islinux = sys.os == "Linux"
sys.is32 = (sys.arch == "x86" or sys.arch == "arm")
sys.is64 = not sys.is32
sys.isarm = sys.arch == "arm" or sys.arch == "arm64"

---@enum ANSI
local ANSI = {
  reset            = "\27[0m",
  black            = "\27[0;30m",
  red              = "\27[0;31m",
  green            = "\27[0;32m",
  yellow           = "\27[0;33m",
  blue             = "\27[0;34m",
  purple           = "\27[0;35m",
  cyan             = "\27[0;36m",
  white            = "\27[0;37m",
  bold_black       = "\27[1;30m",
  bold_red         = "\27[1;31m",
  bold_green       = "\27[1;32m",
  bold_yellow      = "\27[1;33m",
  bold_blue        = "\27[1;34m",
  bold_purple      = "\27[1;35m",
  bold_cyan        = "\27[1;36m",
  bold_white       = "\27[1;37m",
  underline_black  = "\27[4;30m",
  underline_red    = "\27[4;31m",
  underline_green  = "\27[4;32m",
  underline_yellow = "\27[4;33m",
  underline_blue   = "\27[4;34m",
  underline_purple = "\27[4;35m",
  underline_cyan   = "\27[4;36m",
  underline_white  = "\27[4;37m",
  bg_black         = "\27[40m",
  bg_red           = "\27[41m",
  bg_green         = "\27[42m",
  bg_yellow        = "\27[43m",
  bg_blue          = "\27[44m",
  bg_purple        = "\27[45m",
  bg_cyan          = "\27[46m",
  bg_white         = "\27[47m",
  bright_black     = "\27[0;90m",
  bright_red       = "\27[0;91m",
  bright_green     = "\27[0;92m",
  bright_yellow    = "\27[0;93m",
  bright_blue      = "\27[0;94m",
  bright_purple    = "\27[0;95m",
  bright_cyan      = "\27[0;96m",
  bright_white     = "\27[0;97m",
  bg_bright_black  = "\27[100m",
  bg_bright_red    = "\27[101m",
  bg_bright_green  = "\27[102m",
  bg_bright_yellow = "\27[103m",
  bg_bright_blue   = "\27[104m",
  bg_bright_purple = "\27[105m",
  bg_bright_cyan   = "\27[106m",
  bg_bright_white  = "\27[107m",
  bold             = "\27[1m",
  italic           = "\27[3m",
  underline        = "\27[4m",
  strikethrough    = "\27[9m",
}

---@return string path
sys.usrhome = function()
  if sys.isunix then
    return (os.getenv('HOME') or './')
  else
    return (os.getenv('USERPROFILE') or './')
  end
end

sys.home = function()
  return sys.usrhome() .. '/.ffetch/'
end

---@param p string
---@return boolean
sys.hasdir = function(p)
  local suc = os.rename(p .. '/', p .. '/')
  return suc or false
end

---@param p string
sys.mkdir = function (p)
  popen('mkdir', sys.isunix and '-p', p):close()
end

---@param p string
---@return boolean
sys.hasfile = function (p)
  local f = io.open(p, "r")
  return f ~= nil
end

---@param p string
sys.createfile = function (p)
  local f = io.open(p, "w")
  if f then
    f:close()
  end
end

---@param name string
---@return string? path, string? errmsg
local find = function(name)
  local command
  if name:find("[;&|<>\"'`$()%%!\r\n]") then
    return nil, "Aren't you trying to inject shell metacharacters??"
  end

  if sys.iswindows then
    command = 'where "' .. name .. '" 2>NUL'
  else
    command = "command -v -- '" .. name:gsub("'", "'\\''") .. "' 2>/dev/null"
  end

  local pipe = io.popen(command, "r")
  if not pipe then
    return nil, name .. ': not found! (pipe failed)'
  end

  local path = pipe:read("*l")
  pipe:close()

  if not path or path == "" then return nil, name .. ': not found!' end

  if not sys.iswindows and path:sub(1, 1) ~= "/" then
    local pwd = os.getenv("PWD")
    if pwd and pwd:sub(1, 1) == "/" then
      path = pwd .. "/" .. path
    end
  end

  return path
end

local __error = error

---@param message any
---@param level integer?
local error = function(message, level)
  __error(
    ('%s%s%s'):format(ANSI.red, message, ANSI.reset),
    level
  )
end

local pkg = {
  git = 'git',
  curl = 'curl'
}

local inicheck = function()
  assert(find(pkg.git))
  assert(find(pkg.curl))
end

local url = {}

---@param name string
---@return boolean
url.isurl = function(name)
  return name:starts('https://') or name:starts('http://')
end

---@param url string
---@return boolean
url.isvalid = function(url)
  local null = sys.iswindows and "NUL" or "/dev/null"
  local out = popen(pkg.curl, '-L', '-s', '-o', null, '-w', '%{http_code}', '--max-time', 10, url):read("a")
  local code = tonumber(out) or 0

  return code >= 200 and code < 400
end

local path = {}

---@param p string
---@return string
path.normalize = function (p)
  local s = p:gsub('/+', '/')
  return s
end

local sfmt = {}

---@class sfmt.progress
---@field name string? The name associated with this progress entry, supplied by the caller (e.g. repository name).
---@field phase string? The current Git operation or phase (e.g. "Receiving objects", "Resolving deltas").
---@field percent number? Completion percentage reported by Git, from 0 to 100.
---@field total number? Total number of objects involved in the current phase.
---@field current number? Number of objects processed so far in the current phase.
---@field objleft number? Number of objects remaining (total - current).
---@field objfraction number? Fraction of objects processed (current / total), from 0 to 1.
---@field transferred number? Amount of data transferred, parsed from the progress line.
---@field transferredunit string? Unit of transferred data (e.g. "KiB", "MiB").
---@field speed number? Transfer speed, parsed from the progress line.
---@field speedunit string? Unit of transfer speed (e.g. "KiB/s", "MiB/s").

---@param name string Name associated with this progress entry.
---@param line string A line of Git clone progress output.
---@return sfmt.progress? progress Parsed progress data, or nil if the line doesn't match.
sfmt.parseprogresse = function(name, line)
  if not line then return {} end
  local phase, percent, current, total = line:match("^([^:]+):%s*(%d+)%%%s*%((%d+)/(%d+)%)")

  if not phase then return nil end

  local amount, unit, speed, speed_unit = line:match("([%d%.]+)%s*(%S+)%s*|%s*([%d%.]+)%s*(%S+)")

  current = tonumber(current)
  total = tonumber(total)
  percent = tonumber(percent)

  return {
    name = name,
    phase = phase,
    percent = percent,
    current = current,
    total = total,
    objleft = total - current,
    objfraction = current / total,
    transferred = tonumber(amount),
    transferredunit = unit,
    speed = tonumber(speed),
    speedunit = speed_unit,
  }
end

---@param len integer
---@param percentage number
---@return string
sfmt.progressbar = function(len, percentage)
  percentage = math.max(0, math.min(100, percentage))

  local done = math.floor(len * percentage / 100)
  local bar = ('━'):rep(done)
  .. (done < len and '╸' or '')
  .. ('─'):rep(len - done - (done < len and 1 or 0))

  return bar
end

local files = {
  config = 'config.lua',
  packages = 'packages.txt',
}

---@param name string
---@param servers string[]
---@return string[]
pkg.search = function(name, servers)
  local results = {}

  for _, value in ipairs(servers) do
    local link = value .. '/' .. name
    if url.isurl(link) and url.isvalid(link) then
      results[#results + 1] = link
      io.write(ANSI.green, ("found server '%s'\n"):format(link), ANSI.reset)
    else
      if sys.hasdir(link) then
        results[#results + 1] = link
        io.write(ANSI.green, ("found server '%s'\n"):format(link), ANSI.reset)
      end
    end
  end

  return results
end

---@return string[]
pkg.servers = function()
  local home = path.normalize(sys.home() .. '/config.lua')
  if not sys.hasfile(home) then
    sys.createfile(home)
  end

  local fun = assert(loadfile(home, "bt", {}))
  local ret = fun()
  if type(ret) ~= "table" then
    error(("ill-formed configuration file! (Should return a table): %s"):format(home))
  end

  local list = {}
  for index, value in ipairs(ret.servers) do
    list[index] = tostring(value)
  end

  return list
end

---@param name string
---@param link string
pkg.unpack = function(name, link)
  local home = sys.home()
  local indir = home .. '/installed/' .. name .. '/'
  if sys.hasdir(indir) then
    error(("cannot install '%s' because it would require to install data in '%s', which is not empty."):format(name, indir))
  end

  local handle = popen(pkg.git, 'clone', '--verbose', '--progress', link, indir)
  assert(handle, ("cannot clone %s (Git pipe not created!)"):format(name))
  handle:setvbuf("no", 256)

  local line = handle:read(256)
  while line do
    line = handle:read(256)
    local value = sfmt.parseprogresse(name, line)
    if type(value) == "table" then
      local percent = value.percent or 0
      local progress = sfmt.progressbar(24, percent)
      io.write(("installing %s%s%s [%s] %.0f%% | %.2f %s | %d/%d"):format(
        ANSI.bg_bright_cyan, value.name, ANSI.reset,
        progress,
        percent,
        value.speed or 0,
        value.speedunit or "B",
        (value.total or 0) - (value.objleft or 0),
        value.total or 0
      ), '\r'):flush()
    end
  end

  io.write('\27[2K', ANSI.cyan, name, ': ', ANSI.green, 'done', ANSI.reset, '\n'):flush()

  local suc, kind, code = handle:close()
  assert(suc, ("Git failed to install '%s' (%s: %d)"):format(name, kind, code))
end

---@param name string
---@param conflicts (fun(package: string, sources: string[]):integer)?
pkg.installone = function(name, conflicts)
  local researches = pkg.search(name, pkg.servers())
  local i = 1

  if #researches < 1 then
    pcall(error, ('%s: not found!'):format(name))
  elseif #researches > 1 then
    if conflicts then
      i = conflicts(name, researches)
    else
      io.write(ANSI.yellow, ("conflicts! Found %d packages for research '%s'.\n"):format(#researches, name))
      for index, value in ipairs(researches) do
        io.write(ANSI.blue, index, '\t', ANSI.bg_bright_purple, value, '\n')
      end

      io.write(ANSI.reset, "please, select one (default: 1): ")
      i = io.read("n") or 1
    end
  end

  io.write(ANSI.white, "unpacking '", name, "'...\n", ANSI.reset)
  pkg.unpack(name, researches[i])
end

---@param name string
---@return boolean, string
pkg.isinstalled = function (name)
  local path = sys.home() .. '/installed/' .. name
  return sys.hasdir(path), path
end

---@param ... string
pkg.install = function(...)
  for _, name in ipairs({...}) do
    local installed, path = pkg.isinstalled(name)
    if installed then
      io.write(ANSI.yellow, ("package '%s' already installed at "):format(name), ANSI.underline_yellow, path, ANSI.reset, '\n')
    else
      pkg.installone(name)
    end
  end
end

---@param p string
---@param strict boolean?
local check = function (p, strict)
  io.write(("checking for dependency '%s': "):format(p)):flush()
  local found = find(p)
  if found then
    io.write(("%sfound%s at '%s'\n"):format(ANSI.green, ANSI.reset, found))
  else
    io.write(("%snot found%s\n"):format(ANSI.red, ANSI.reset))
    if strict then 
      error('a required dependency was not found!')
    end
  end
end

pkg.init = function ()
  if not sys.hasdir(sys.home()) then
    io.write('It seems like this is your first time launching ffetch.\n')
    io.write('Creating home directory'):flush()
    sys.mkdir(sys.home())
    local config = io.open(sys.home() .. '/config.lua', "w")
    if config then
      config:write("-- auto-generated configuration file. You may modify its content manually, or through the CLI.\nreturn {\n\tservers = {}\n}")
      config:close()
    end
  end

  check('git', true)
  check('curl', true)
  check('gcc')
  check('g++')
  check('lua')
  check('make')
  check('cmake')
  check(os.getenv('EDITOR') or 'micro')
end

pkg.help = function ()
  for key, value in pairs(pkg) do
    if type(value) == "function" then
      io.write(ANSI.blue, key, '\t', ANSI.green, tostring(value), ANSI.reset, '\n')
    end
  end
end

arg = arg or {}

local argument = arg[1] or 'help'

if argument ~= 'help' then
  pkg.init()
end

if type(pkg[argument]) == "function" then
  pkg[argument](table.unpack(table.take(arg, 2)))
end

---@TODO: pkg.config ++update
return {
  pkg = pkg,
  utils = {
    find = find,
    ANSI = ANSI,
  },
  sys = sys,
  check = inicheck,
}
