local http = require("http")
local positionsManager = require("voice.positionsManager")

local M = {}

-- Variables
local authToken = ""
local serverInfos = nil
local initialized = false

-- Helpers
local function sendKeyEvent(player_id, key)
    if not positionsManager.existsPlayer(player_id) then return false end
    if not authToken or authToken == "" then return false end

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
local function init(newAuthToken, newServerInfos)
    logger.debug("Initializing Input Manager...")

    authToken = newAuthToken
    serverInfos = newServerInfos

    if initialized then return end
    MP.RegisterEvent("voice_toggleMute", "BeamVoiceInputToggleMuteHandler")
    MP.RegisterEvent("voice_toggleMuteGroup", "BeamVoiceInputToggleMuteGroupHandler")
    MP.RegisterEvent("voice_toggleDeafenGroup", "BeamVoiceInputToggleDeafenGroupHandler")
    initialized = true
end

-- Event Handlers
function BeamVoiceInputToggleMuteHandler(player_id)
    sendKeyEvent(player_id, "mute")
end

function BeamVoiceInputToggleMuteGroupHandler(player_id)
    sendKeyEvent(player_id, "group_mute")
end

function BeamVoiceInputToggleDeafenGroupHandler(player_id)
    sendKeyEvent(player_id, "group_deafen")
end

-- Exports
M.init = init

return M