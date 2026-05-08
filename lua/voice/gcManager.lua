local http = require("http")
local authManager = require("voice.authManager")

local M = {}

-- Variables
local groupChats = {} -- { [groupChatId] = name }

-- Helpers

-- Functions
local function createGroupChat(name) -- return groupChatId or nil, and error code if failed, -1 for auth error, -2 for cap reached, or http code
    if not authManager.getToken() then
        logger.error(logger.format("Cannot create group chat without a valid authentication token.", "red"))
        return nil, -1
    end

    local headers = { ["Authorization"] = "Bearer " .. authManager.getToken() }

    if type(name) ~= "string" or name:len() == 0 or name:len() > 100 then
        logger.error(logger.format("Invalid group chat name. It must be a non-empty string with a maximum length of 100 characters.", "red"))
        return nil, 400
    end

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/group_create", headers, {
        name = name
    })

    if success and response and response.group_id then
        groupChats[response.group_id] = name
        return response.group_id, code
    end

    if code == 403 then -- invalid token or cap reached
        logger.error(logger.format("Failed to create group chat: " .. (response or "Unknown error"), "red"))
        if response and response.error and response.error:lower():find("cap") then
            return nil, -2
        end
        return nil, code
    end

    return nil, code
end

local function deleteGroupChat(groupChatId)
    if not authManager.getToken() then
        logger.error(logger.format("Cannot delete group chat without a valid authentication token.", "red"))
        return false, -1
    end

    local headers = { ["Authorization"] = "Bearer " .. authManager.getToken() }

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/group_delete", headers, {
        group_id = groupChatId
    })

    if success then
        groupChats[groupChatId] = nil
        return true, code
    end

    if code == 404 then -- group not found
        logger.error("Failed to delete group chat :" .. logger.format(groupChatId, "cyan") .. "): Not found.")
        return false, code
    end

    logger.error("Failed to delete group chat :" .. logger.format(groupChatId, "cyan") .. "): " .. (response or "Unknown error"))
    return false, code
end

local function addPlayer(groupChatId, playerId)
    if not authManager.getToken() then
        logger.error(logger.format("Cannot add player to group chat without a valid authentication token.", "red"))
        return false, -1
    end

    local headers = { ["Authorization"] = "Bearer " .. authManager.getToken() }

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/group_add_player", headers, {
        group_id = groupChatId,
        playerid = playerId
    })

    if success then
        return true, code
    end

    if code == 404 then -- group not found
        return false, code
    end

    logger.error("Failed to add player " .. logger.format(playerId, "cyan") .. " to group chat " .. logger.format(groupChatId, "cyan") .. ": " .. (response or "Unknown error"))
    return false, code
end

local function removePlayer(groupChatId, playerId)
    if not authManager.getToken() then
        logger.error(logger.format("Cannot remove player from group chat without a valid authentication token.", "red"))
        return false, -1
    end

    local headers = { ["Authorization"] = "Bearer " .. authManager.getToken() }

    local success, response, code = http.post("http://" .. authManager.getServerInfos().http_url .. "/group_remove_player", headers, {
        group_id = groupChatId,
        playerid = playerId
    })

    if success then
        return true, code
    end

    if code == 404 then -- group not found
        return false, code
    end

    logger.error("Failed to remove player " .. logger.format(playerId, "cyan") .. " from group chat " .. logger.format(groupChatId, "cyan") .. ": " .. (response or "Unknown error"))
    return false, code
end

local function getPlayerInfos(playerId)
    if not authManager.getToken() then
        logger.error(logger.format("Cannot get player infos without a valid authentication token.", "red"))
        return nil, -1
    end

    local headers = { ["Authorization"] = "Bearer " .. authManager.getToken() }

    local success, response, code = http.get("http://" .. authManager.getServerInfos().http_url .. "/group_player/" .. playerId, headers)

    if success and response then
        return response, code
    end

    if code ~= 404 then -- 404 just means the player is not in a group, it's not an error
        logger.error("Failed to get group chat informationsfor player " .. logger.format(playerId, "cyan") .. ": " .. (response or "Unknown error"))
    end

    return nil, code
end

local function init()
    logger.debug("Initializing GroupChats...")
    groupChats = {}
    return true
end

-- Exports
M.init = init

M.create = createGroupChat
M.delete = deleteGroupChat
M.addPlayer = addPlayer
M.removePlayer = removePlayer
M.getPlayerInfos = getPlayerInfos

M.getName = function(groupChatId) return groupChats[groupChatId] end

M.isPlayerInAnyGroup = function(playerId)
    local infos, _ = getPlayerInfos(playerId)
    return infos and infos.in_group
end

M.getPlayerGroup = function(playerId)
    local infos, _ = getPlayerInfos(playerId)
    return infos and infos.group_id or nil
end

return M