local gcManager = require("voice.gcManager")

local M = {}
local initialized = false

-- Variables
local compatibleApiVersions = {
    "1.0.0"
}

-- Helpers
local function isCompatibleVersion(version, versions)
    version = version:gsub("^v", "")

    -- Check each version in the list
    for _, v in ipairs(versions) do
        local pattern = v:gsub("^v", "")
        pattern = pattern:gsub("x", "%%d+")
        pattern = pattern:gsub("%.", "%%.")
        pattern = "^" .. pattern .. "$"

        if version:match(pattern) then
            return true
        end
    end

    -- If no match is found, return false
    return false
end

-- Functions
local function init()
    logger.debug("Initializing API Manager...")
    if initialized then return true end

    MP.RegisterEvent("BeamVoiceAPI_checkApiCompatibility", "BeamVoiceAPI_checkApiCompatibilityHandler")
    MP.RegisterEvent("BeamVoiceAPI_createGroupChat", "BeamVoiceAPI_createGroupChatHandler")
    MP.RegisterEvent("BeamVoiceAPI_deleteGroupChat", "BeamVoiceAPI_deleteGroupChat")
    MP.RegisterEvent("BeamVoiceAPI_addPlayerToGroupChat", "BeamVoiceAPI_addPlayerToGroupChatHandler")
    MP.RegisterEvent("BeamVoiceAPI_removePlayerFromGroupChat", "BeamVoiceAPI_removePlayerFromGroupChatHandler")
    MP.RegisterEvent("BeamVoiceAPI_getPlayerInfos", "BeamVoiceAPI_getPlayerInfosHandler")
    MP.RegisterEvent("BeamVoiceAPI_getGroupsChat", "BeamVoiceAPI_getGroupsChatHandler")

    initialized = true
    return true
end

-- Event Handlers
function BeamVoiceAPI_checkApiCompatibilityHandler(apiVersion)
    return isCompatibleVersion(apiVersion, compatibleApiVersions)
end

function BeamVoiceAPI_createGroupChatHandler(name)
    local groupChatId, errorCode = gcManager.create(name)
    return {groupChatId, errorCode}
end

function BeamVoiceAPI_deleteGroupChat(groupChatId)
    local success, errorCode = gcManager.delete(groupChatId)
    return {success, errorCode}
end

function BeamVoiceAPI_addPlayerToGroupChatHandler(groupChatId, playerId)
    local success, errorCode = gcManager.addPlayer(groupChatId, playerId)
    return {success, errorCode}
end

function BeamVoiceAPI_removePlayerFromGroupChatHandler(groupChatId, playerId)
    local success, errorCode = gcManager.removePlayer(groupChatId, playerId)
    return {success, errorCode}
end

function BeamVoiceAPI_getPlayerInfosHandler(playerId)
    local playerInfos, errorCode = gcManager.getPlayerInfos(playerId)
    return {playerInfos, errorCode}
end

function BeamVoiceAPI_getGroupsChatHandler()
    local groups, errorCode = gcManager.getGroups()
    return {groups, errorCode}
end

-- Exports
M.init = init

return M