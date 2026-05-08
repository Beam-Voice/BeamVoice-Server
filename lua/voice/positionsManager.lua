local schemaUtils = require("impl.schemaUtils")

local M = {}
local initialized = false
local timeoutDeleteSeconds = 30 -- In case of stale clients due to events

-- Variables
local playersPositions = {}

local positionSchema = {
    camX = "number",
    camY = "number",
    camZ = "number",
    camRot = "number",
    playerX = "number",
    playerY = "number",
    playerZ = "number"
}

-- Helpers
local function existsPlayer(player_id)
    if(playersPositions[tostring(player_id)] == nil) then return false end
    return true
end

-- Functions
local function init()
    logger.debug("Initializing Positions Manager...")

    if initialized then return end
    MP.RegisterEvent("voice_updatePos", "BeamVoiceUpdatePositionHandler")
    initialized = true
end

local function addPlayer(player_id)
    playersPositions[tostring(player_id)] = {
        pos = {
            camX = 0,
            camY = 0,
            camZ = 0,
            camRot = 0,
            playerX = 0,
            playerY = 0,
            playerZ = 0
        },
        lastUpdated = os.time()
    }
end

local function removePlayer(player_id)
    if not existsPlayer(player_id) then return end
    playersPositions[tostring(player_id)] = nil
end

local function checkForTimeouts()
    for playerId, playerData in pairs(playersPositions) do
        if(os.time() - playerData.lastUpdated > timeoutDeleteSeconds) then
            playersPositions[tostring(playerId)] = nil
        end
    end
end

-- Event Handlers
function BeamVoiceUpdatePositionHandler(player_id, data_string)
    local positionData = Util.JsonDecode(data_string)
    if not existsPlayer(player_id) then return end
    if not schemaUtils.validateObject(positionData, positionSchema) then return end

    playersPositions[tostring(player_id)].pos = positionData
    playersPositions[tostring(player_id)].lastUpdated = os.time()
end

-- Exports
M.init = init
M.addPlayer = addPlayer
M.removePlayer = removePlayer
M.existsPlayer = existsPlayer
M.checkForTimeouts = checkForTimeouts

M.getPositions = function() return playersPositions end
M.clearPositions = function() playersPositions = {} end

return M