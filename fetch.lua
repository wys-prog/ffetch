--- ffetch (All right reserved), that dummy package manager.
--- ffetch is free and open-source

local sys = {}

sys.iswindows = package.config:sub(1, 1) == "\\"
sys.isunix = not sys.iswindows

local function strip_newline(value)
  if type(value) ~= "string" then return value end
  return (value:gsub("%s+$", ""))
end

---@param cmd string
---@return string?, integer
local function command(cmd, ...)
  for _, value in ipairs({ ... }) do
    cmd = cmd .. (" '%s'"):format(tostring(value))
  end

  local p = io.popen(cmd .. " 2>&1", "r")
  if not p then return nil, -1 end

  local result = p:read("a")
  local _, _, code = p:close()
  return strip_newline(result), code or -1
end

local function syscheck(prog)

end

if sys.iswindows then
  sys.os = "Windows"
  sys.arch = strip_newline(command("echo %PROCESSOR_ARCHITECTURE%"))
else
  sys.os = strip_newline(command("uname -s"))
  sys.arch = strip_newline(command("uname -m"))
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
    return nil, name .. ': not found!'
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


---@param c ANSI|any
---@param ... any
local function cwrite(c, ...)
  io.write(c, ...)
  io.write(ANSI.reset, "\n")
end

local pkg = {
  git = 'git'
}

local inicheck = function()
  assert(find(pkg.git))
end

pkg.install = function(link)
  
end

return {
  pkg = pkg,
  utils = {
    find = find,
    ANSI = ANSI,
  },
  sys = sys,
  check = inicheck,
  cwrite = cwrite,
}