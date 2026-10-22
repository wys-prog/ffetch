--- ffetch (All right reserved), that dummy package manager.
--- ffetch is free and open-source

local sys = {}

sys.iswindows = package.config:sub(1, 1) == "\\"
sys.isunix = not sys.iswindows

---@param cmd string
---@return string?
local function command(cmd, ...)
  for _, value in ipairs({...}) do cmd = cmd .. (" '%s'"):format(tostring(value)) end

  local p = io.popen(cmd, "r")
  if not p then return nil end
  local result = p:read("*l")
  p:close()
  if result then
    result = result:match("^%s*(.-)%s*$")
  end

  return result
end

if sys.iswindows then
  sys.os = "Windows"
  sys.arch = command("echo %PROCESSOR_ARCHITECTURE%")
else
  sys.os = command("uname -s")
  sys.arch = command("uname -m")
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
sys.is32 = (sys.arch == 'x86' or sys.arch == 'arm')
sys.is64 = not sys.is32
sys.isarm = sys.arch == 'arm' or sys.arch == 'arm64'

---@generic T
---@alias proghandler fun(suc: boolean,
---exitcode:'exit'|'signal'|'unknown',
---code: integer, stdout: string):T

if not pcall(debug.getlocal, 4, 1) then

end

