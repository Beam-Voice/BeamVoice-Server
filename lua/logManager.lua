-- Made by Neptnium (https://gist.github.com/Neptnium/35fc474ef5061052a66ee3db00097cd9)
local logName = "BeamVoice"

local M = {}

local colors = {
  ["black"] = "16",
  ["white"] = "7",

  ["red"] = "1",
  ["green"] = "2",
  ["yellow"] = "3",
  ["blue"] = "4",
  ["purple"] = "5",
  ["cyan"] = "6",
  ["orange"] = "202",
  ["pink"] = "13",
}

local accents = {
  ["reset"] = "\27[0m",
  ["bold"] = "\27[1m",
  ["italic"] = "\27[3m",
  ["underline"] = "\27[4m",
  ["strike"] = "\27[9m",
}

local debugLogs = false

function fgColor(code)
  if not code then return nil end
  return "\27[38;5;" .. code .. "m"
end

function bgColor(code)
  if not code then return nil end
  return "\27[48;5;" .. code .. "m"
end

logName = fgColor(colors.orange) .. logName .. accents.reset

function getFormatedTime()
  time = os.time()
  return os.date("%d", time) .. "/" .. os.date("%m", time) .. "/" .. os.date("%y", time) .. " " .. os.date("%X", time)
end

function log(msg)
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] [LOG] " .. msg)
end

function infoLog(msg)
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] " .. fgColor(colors.green) .. "[INFO] " .. accents.reset.. msg)
end

function debugLog(msg)
  if(not debugLogs) then return end
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] " .. fgColor(colors.blue) .. "[DEBUG] " .. accents.reset.. msg)
end

function warningLog(msg)
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] " .. bgColor(colors.orange) .. "[WARNING]" .. accents.reset .. " " .. msg)
end

function debugWarningLog(msg)
  if(not debugLogs) then return end
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] " .. fgColor(colors.blue) .. "[DEBUG]" .. accents.reset .. "-" .. bgColor(colors.orange) .. "[WARNING]" .. accents.reset .. " " .. msg)
end

function errorLog(msg)
  printRaw("[" .. getFormatedTime() .. "] [" .. logName .. "] " .. bgColor(colors.red) .. "[ERROR]" .. accents.reset .. " " .. msg)
end

function format(msg, color)
  return (fgColor(colors[color]) or accents.reset) .. msg .. accents.reset
end


-- Exports
M.log = log
M.info = infoLog
M.debug = debugLog
M.warning = warningLog
M.debugWarning = debugWarningLog
M.error = errorLog
M.format = format

M.fgColor = fgColor
M.bgColor = bgColor
M.colors = colors
M.accents = accents

M.setEnableDebugging = function(enableDebugging) debugLogs = enableDebugging end

return M