pluginPath = debug.getinfo(1).source:gsub("\\", "/"):match("(.+)/main.lua")

logger = require("logManager")
local config = require("config")
logger.setEnableDebugging(MP.Get(MP.Settings.Debug) or config.debug or false)
local http = require("http")
local authManager = require("voice.authManager")
local audioManager = require("voice.audioManager")
local apiManager = require("voice.apiManager")
local gcManager = require("voice.gcManager")

local joinMessageManager = require("voice.joinMessageManager")

-- Variables
local audioNode = "" -- Audio Node url
serverMap = (MP.Get(MP.Settings.Map) or "/levels/gridmap_v2/info.json"):gsub('/levels/', ''):gsub('/info.json', '')
messagePrefix = "^r[^6^lBeamVoice^r] "

-- Auth Process
local serverKey = config.key or ""

function authenticateServer()
    if serverKey == "" or not authManager.isValidUUIDv4(serverKey) then
        local coloredPath = logger.format("configs/BeamVoice.toml", "purple")
        logger.error(logger.format("Invalid server key provided.", "red") .. " Please set the 'key' variable in the \"" .. coloredPath .. "\" file. Shutting down the plugin...")
        return false
    end

    if not authManager.auth(serverKey) then
        logger.error(logger.format("Failed to authenticate with the Beam Voice service. Shutting down the plugin...", "red"))
        return false
    end

    if not audioManager.init() then
        logger.error(logger.format("Failed to initialize the audio manager.", "red"))
        return false
    end

    if not apiManager.init() then
        logger.error(logger.format("Failed to initialize the API manager.", "red"))
        return false
    end

    if not gcManager.init() then
        logger.error(logger.format("Failed to initialize the Group Chat manager.", "red"))
        return false
    end
    return true
end

if not authenticateServer() then
    logger.error(logger.format("Server authentication failed. Shutting down the plugin.", "red"))
    return false
end
joinMessageManager.init()

-- Event Handlers
function BeamVoiceOnChatMessageHandler(player_id, _, message)
    if message == "/vc" or message == "/voice" then
        if not audioManager.isPlayerAuthenticated(player_id) then
            local success, token = audioManager.authPlayer(player_id)
            if success then
                MP.SendChatMessage(player_id, messagePrefix .. "You just joined the voice chat !")
                MP.TriggerClientEvent(player_id, "BeamVoice_openLink", "https://audio.beamvoice.net/?token=" .. token)
            end
        else
            local success = audioManager.removePlayer(player_id)
            if success then
                MP.SendChatMessage(player_id, messagePrefix .. "You just left the voice chat !")
            else
                MP.SendChatMessage(player_id, messagePrefix .. "Failed to leave the voice chat.")
            end
        end
        return 1
    end

    if message:sub(1, 4) == "/gc " then
        local groupChatId = message:sub(5)
        if gcManager.addPlayer(groupChatId, player_id) then
            MP.SendChatMessage(player_id, messagePrefix .. "You just joined the group chat ^b" .. groupChatId .. "^r !")
        else
            MP.SendChatMessage(player_id, messagePrefix .. "Failed to join the group chat ^b" .. groupChatId .. "^r. Please check the group chat ID and try again.")
        end
        return 1
    end

    if message == "/gcl" or message == "/gcleave" then
        if not gcManager.isPlayerInAnyGroup(player_id) then
            MP.SendChatMessage(player_id, messagePrefix .. "You are not in any group chat.")
            return 1
        end

        local success = gcManager.removePlayer(gcManager.getPlayerGroup(player_id), player_id)
        if success then
            MP.SendChatMessage(player_id, messagePrefix .. "You just left the group chat !")
        else
            MP.SendChatMessage(player_id, messagePrefix .. "Failed to leave the group chat.")
        end
        return 1
    end
end
MP.RegisterEvent("onChatMessage", "BeamVoiceOnChatMessageHandler")

function BeamVoiceOnConsoleInputHandler(cmd)
    if cmd:sub(1, 5) ~= "voice" then
        return nil
    end

    if cmd == "voice reauth" then
        audioManager.disable()
        if authenticateServer() then
            return logger.format("Re-authentication successful!", "green")
        else
            return logger.format("Re-authentication failed. Please check the server key and your connection to the Beam Voice service.", "red")
        end
        return ""
    end

    if cmd == "voice status" then
        if audioManager.isLoggedIn() then
            return logger.format("Audio Manager is currently enabled.", "green")
        else
            return logger.format("Audio Manager is currently disabled.", "red")
        end
    end
end
MP.RegisterEvent("onConsoleInput", "BeamVoiceOnConsoleInputHandler")

for i = 1, authManager.getServerInfos().audio_channels do
    logger.info("Creating test group chat " .. i)
    gcManager.create("Test Group Chat " .. i)
end