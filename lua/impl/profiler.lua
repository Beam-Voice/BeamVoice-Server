local socket = require("libs.socket")

local now = function() return socket.gettime() end 

-- Define Class Attributes
local Profiler = {
  startTime = 0,
  lastTime = 0,
  profiles = {},
}

-- Define Class Methods
function Profiler:profile(partName)
  local elapsedTime = (now() - self.lastTime) * 1000
  self.lastTime = now()
  self.profiles[partName] = elapsedTime
  return elapsedTime, (now() - self.startTime) * 1000
end

-- Define Class Contructor
function Profiler:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.startTime = now()
  o.lastTime = o.startTime
  o.profiles = {}

  return o
end

return Profiler