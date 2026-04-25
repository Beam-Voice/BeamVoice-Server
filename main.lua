pluginPath = debug.getinfo(1).source:gsub("\\", "/"):match("(.+)/main.lua")

logger = require("logManager")
local config = require("config")
logger.setEnableDebugging(MP.Get(0) or config.debug or false)
local http = require("http")
local authManager = require("voice.authManager")
local audioManager = require("voice.audioManager")
local authManager = require("voice.authManager")
local joinMessageManager = require("voice.joinMessageManager")

-- Variables
local authToken = "" -- Server's auth token
local audioNode = "" -- Audio Node url
serverMap = (MP.Get(4) or "/levels/gridmap_v2/info.json"):gsub('/levels/', ''):gsub('/info.json', '')

-- Auth Process
local serverKey = config.key or ""

if serverKey == "" or not authManager.isValidUUIDv4(serverKey) then
    local coloredPath = logger.format("configs/BeamVoice.toml", "purple")
    logger.error(logger.format("Invalid server key provided.", "red") .. " Please set the 'key' variable in the \"" .. coloredPath .. "\" file. Shutting down the plugin...")
    return false
end

local success, newAuthToken = authManager.auth(serverKey)
if not success then
    logger.error(logger.format("Failed to authenticate with the Beam Voice service. Shutting down the plugin...", "red"))
    return false
end

authToken = newAuthToken

-- Init Voicechat
if not audioManager.init(authToken) then
    logger.error(logger.format("Failed to initialize the audio manager. Shutting down the plugin...", "red"))
    return false
end

function BeamVoiceOnChatMessageHandler(player_id, _, message)
    if message == "/vc" or message == "/voice" then
        if not audioManager.isPlayerAuthenticated(player_id) then
            local success, token = audioManager.authPlayer(player_id)
            if success then
                MP.SendChatMessage(player_id, "You just joined the voice chat !")
                MP.TriggerClientEvent(player_id, "BeamVoice_openLink", "https://audio.beamvoice.net/?token=" .. token)  
            end
        else
            local success = audioManager.removePlayer(player_id)
            if success then
                MP.SendChatMessage(player_id, "You just left the voice chat !")
            else
                MP.SendChatMessage(player_id, "Failed to leave the voice chat.")
            end
        end
        return 1
    end
end

MP.RegisterEvent("onChatMessage", "BeamVoiceOnChatMessageHandler")

joinMessageManager.init()