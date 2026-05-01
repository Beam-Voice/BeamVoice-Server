local timeoutCounter = 0

local function setTimeout(milliseconds, callback)
    timeoutCounter = timeoutCounter + 1
    local eventName = "BeamVoice_setTimeout_" .. timeoutCounter
    local handlerName = "BeamVoice_setTimeoutHandler_" .. timeoutCounter

    _G[handlerName] = function()
        MP.CancelEventTimer(eventName)
        _G[handlerName] = nil
        callback()
    end

    MP.RegisterEvent(eventName, handlerName)
    MP.CreateEventTimer(eventName, milliseconds)
end

return setTimeout
