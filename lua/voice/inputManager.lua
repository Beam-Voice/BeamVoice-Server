local http = require("http")
local authManager = require("voice.authManager")
local positionsManager = require("voice.positionsManager")

local M = {}
local initialized = false

-- Helpers
local function sendKeyEvent(player_id, key)
    if not positionsManager.existsPlayer(player_id) then return false end
    local authToken = authManager.getToken()
    if not authToken or authToken == "" then return false end
    local serverInfos = authManager.getServerInfos()
    if not serverInfos then return false end

    local headers = {
        ["Authorization"] = "Bearer " .. authToken
    }

    local success, response, code = http.post("http://" .. serverInfos.http_url .. "/key_event", headers, {
        playerid = player_id,
        key = key
    })
    return success
end

-- Functions
local function init()
    logger.debug("Initializing Input Manager...")

    if initialized then return end
    MP.RegisterEvent("voice_keyEvent", "BeamVoiceInputKeyEventHandler")
    initialized = true
end

-- Event Handlers
function BeamVoiceInputKeyEventHandler(player_id, data)
    sendKeyEvent(player_id, data)
end

-- Exports
M.init = init

return M