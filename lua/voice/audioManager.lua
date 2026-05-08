local http = require("http")

local authManager = require("voice.authManager")
local positionsManager = require("voice.positionsManager")
local inputManager = require("voice.inputManager")
local persistentHttp = require("impl.persistentHttp")
local setTimeout = require("impl.setTimeout")

local M = {}

-- Variables
local positionsHttpClient = nil
local loggedIn = false
local consecutiveFailures = 0
local maxFailureSeonds = 5
local reauthAfterSeconds = 60

-- Helpers
local function toStr(v)
    if type(v) == "table" then return Util.JsonEncode(v) end
    if type(v) == "string" then return v end
    return tostring(v)
end

-- Functions
local function loginAudioNode()
    local headers = {
        ["Authorization"] = "Bearer " .. authManager.getToken()
    }

    logger.debug("Logging in to the audio node...")

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/auth", headers, {})

    if success then
        logger.info(logger.format("Logged in to the audio node successfully!", "green"))
        MP.SendChatMessage(-1, messagePrefix .. "^bVoice chat is enabled on this server! Use ^6/vc ^bto join the voice chat.")
        loggedIn = true
        return true
    end

    logger.error(logger.format("Failed to log in to the audio node: " .. (toStr(response) or "No response") .. " (HTTP " .. code .. ")", "red"))
    return false
end

local function logoutAudioNode()
    if not loggedIn then return true end

    local headers = {
        ["Authorization"] = "Bearer " .. authManager.getToken()
    }

    logger.debug("Logging out of the audio node...")

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/shutdown", headers, {})

    if success then
        logger.info(logger.format("Successfully logged out of the audio node!", "green"))
        return true
    end

    logger.error(logger.format("Failed to log out of the audio node: " .. (toStr(response) or "No response") .. " (HTTP " .. code .. ")", "red"))
    return false
end

local function disableAudioManager()
    logger.warning("Disabling Audio Manager due to previous errors...")
    MP.SendChatMessage(-1, messagePrefix .. "^cVoice chat has been temporarily disabled due to issues.")
    MP.CancelEventTimer("BeamVoicePositionUpdateTimer")
    if positionsHttpClient then
        positionsHttpClient:close()
        positionsHttpClient = nil
    end
    positionsManager.clearPositions()
    loggedIn = false
    return true
end

local function authPlayer(player_id)
    if not loggedIn then return false end

    positionsManager.addPlayer(player_id)

    local headers = {
        ["Authorization"] = "Bearer " .. authManager.getToken()
    }

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/join", headers, {
        playerid = player_id,
        beammp_id = MP.GetPlayerIdentifiers(0).beammp or -1,
        name = MP.GetPlayerName(player_id),
        map = serverMap
    })

    if success and response and type(response.token) == "string" then
        logger.info("Player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " joined the voice chat!")
        return true, response.token
    end

    positionsManager.removePlayer(player_id)
    if code == 400 then
        logger.warning("Player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " failed to join the voice chat: " .. (response and response.error or "Unknown error"))
        MP.SendChatMessage(player_id, messagePrefix .. "^cYou are already in the voice chat!")
        return false
    end

    if code == 403 and response and response.error == "Server full" then
        logger.warning("Player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " failed to join the voice chat: Server is full")
        MP.SendChatMessage(player_id, messagePrefix .. "^cThe voice chat is currently full. Please try again later.")
        return false
    end

    logger.error("Failed to authenticate player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " with the audio node: " .. (toStr(response) or "No response") .. logger.format(" (HTTP " .. code .. ")", "red"))
    MP.SendChatMessage(player_id, messagePrefix .. "^cFailed to join the voice chat, please try again later.")
    return false
end

local function removePlayer(player_id)
    if not positionsManager.existsPlayer(player_id) then return false end
    positionsManager.removePlayer(player_id)

    if not loggedIn then return false end

    local headers = {
        ["Authorization"] = "Bearer " .. authManager.getToken()
    }

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/leave", headers, {
        playerid = player_id
    })

    if success then
        logger.info("Player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " left the voice chat.")
        return true
    end

    logger.error("Failed to remove player " .. logger.format(MP.GetPlayerName(player_id), "cyan") .. " from the audio node: " .. (toStr(response) or "No response") .. logger.format(" (HTTP " .. code .. ")", "red"))
    return false
end

local function init()
    logger.info("Initializing Audio Manager...")

    local serverInfos = authManager.getServerInfos()
    if not serverInfos then
        logger.error(logger.format("Failed to initialize Audio Manager: missing server infos", "red"))
        return false
    end

    logger.info("The voice chat positions will be updated every " .. logger.format(serverInfos.min_update_interval .. "ms", "cyan"))
    if serverInfos.max_players < MP.Get(MP.Settings.MaxPlayers) then
        logger.warning("The audio node allows up to " .. logger.format(serverInfos.max_players, "cyan") .. " players, but the server max player count is set to " .. logger.format(MP.Get(MP.Settings.MaxPlayers), "cyan") .. ".")
    end

    -- Login trough the audio node
    if not loginAudioNode() then return false end
    positionsManager.init()
    inputManager.init()

    -- Create persistent HTTP client for position updates
    if not positionsHttpClient then
        local err
        positionsHttpClient, err = persistentHttp.fromUrl(serverInfos.http_url)
        if not positionsHttpClient then
            logger.error(logger.format("Failed to connect to audio node HTTP: " .. (err or "unknown error"), "red"))
            disableAudioManager()
            return false
        end
    end

    -- Register Events
    MP.RegisterEvent("onShutdown", "BeamVoiceServerShutdownHandler")
    MP.RegisterEvent("onPlayerDisconnect", "BeamVoicePlayerDisconnectHandler")

    -- Start functions loop
    MP.RegisterEvent("BeamVoicePositionUpdateTimer", "BeamVoicePositionUpdateTimerHandler")
    MP.CreateEventTimer("BeamVoicePositionUpdateTimer", serverInfos.min_update_interval)

    logger.info(logger.format("Audio Manager Initialized", "green"))
    return true
end

-- Events Handlers
function BeamVoicePositionUpdateTimerHandler()
    local serverInfos = authManager.getServerInfos()
    if not serverInfos then return end
    if not loggedIn then return end
    positionsManager.checkForTimeouts()

    local headers = {
        ["Authorization"] = "Bearer " .. authManager.getToken()
    }

    local success, response, code = positionsHttpClient:json_post("/positions", headers, {
        positions = positionsManager.getPositions()
    })

    if not success then
        if code == 429 then
            logger.debug("Rate limited by the audio node (" .. (response.retry_after_ms or "?") .. "ms too early), skipping this update")
            return
        end

        if code == 401 and (response.error == "Stale server JWT" or response.error == "Server JWT was revoked") then
            logger.error(logger.format("Another server instance has logged in with the same token!", "red"))
            logger.warning(logger.format("If you belive this is an error, please rotate your auth key.", "red"))
            logger.warning("If you are running multiple server instances for the same game, make sure each one has its own unique auth token.")
            disableAudioManager()
            return
        end

        if code == 401 then
            logger.error(logger.format("Failed to send positions data to the audio node (Not authenticated, retrying to authenticate...)", "red"))
            loggedIn = false
            positionsManager.clearPositions()
            MP.SendChatMessage(-1, messagePrefix .. "^cVoice chat has been temporarily disabled due to issues. Should be back shortly...")
            setTimeout(10 * 1000, function()
                if loggedIn then return end
                logger.info(logger.format("Attempting to re-authenticate with the audio node...", "yellow"))
                if not loginAudioNode() then
                    logger.error(logger.format("Re-authentication failed, disabling audio manager.", "red"))
                    disableAudioManager()
                end
            end)
            return
        end

        if code == 502 then
            consecutiveFailures = consecutiveFailures + 1
            if (consecutiveFailures * serverInfos.min_update_interval / 1000 > maxFailureSeonds) then
                logger.error(logger.format("Audio node is unavailable for more than " .. maxFailureSeonds .. " seconds, disabling audio manager.", "red"))
                disableAudioManager()
                logger.info(logger.format("Will try to re-auth the audio manager after a cooldown of " .. reauthAfterSeconds .. " seconds...", "yellow"))
                setTimeout(reauthAfterSeconds * 1000, function()
                    logger.info(logger.format("Re-enabling audio manager after cooldown...", "green"))
                    authenticateServer()
                end)
                return
            end
            return
        end

        if type(response) == "string" then
            logger.debugWarning(logger.format("Failed to send positions data to the audio node: " .. response .. " (HTTP " .. code .. ")", "red"))
        else
            logger.error(logger.format("Failed to send positions data to the audio node: " .. (toStr(response) or "No response") .. " (HTTP " .. code .. ")", "red"))
        end
    end
    consecutiveFailures = 0
end

function BeamVoicePlayerDisconnectHandler(player_id)
    removePlayer(player_id)
end

function BeamVoiceServerShutdownHandler()
    if positionsHttpClient then
        positionsHttpClient:close()
        positionsHttpClient = nil
    end
    logoutAudioNode()
end

-- Exports
M.init = init
M.disable = disableAudioManager
M.authPlayer = authPlayer
M.removePlayer = removePlayer

M.isPlayerAuthenticated = function(player_id) return positionsManager.existsPlayer(player_id) end
M.isLoggedIn = function() return loggedIn end

return M