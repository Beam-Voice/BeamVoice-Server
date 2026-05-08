local http = require("http")
local jwt = require("jwt")
local socket = require("libs.socket")
local schemaUtils = require("impl.schemaUtils")

local M = {}

-- Variables
local authServers = { "auth1.beamvoice.net", "auth2.beamvoice.net", "auth3.beamvoice.net" }
local authToken = nil
local serverInfos = nil

local tokenSchema = {
    http_url = "string",
    url = "string",
    server_id = "string",
    max_players = "number",
    min_update_interval = "number",
    audio_channels = "number",
    theme = "?table",
    iat = "number"
}

-- Helpers
local function isValidUUIDv4(uuid)
    if type(uuid) ~= "string" or #uuid ~= 36 then return false end
    local pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[89abAB]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

    return string.match(uuid, pattern) ~= nil
end

local function randomizeTable(t)
    local randomized = {}

    math.randomseed(os.time())
    for i, v in ipairs(t) do
        local randIndex = math.random(1, #randomized + 1)
        table.insert(randomized, randIndex, v)
    end
    return randomized
end

-- Ping Related Functions
local function pingServer(server)
    local startTime = socket.gettime()
    local success, response, code = http.get("http://" .. server .. "/ping")
    local elapsedTime = (socket.gettime() - startTime) * 1000

    if success and code == 200 then
        logger.debug("Pinged server " .. logger.format(server, "purple") .. " in " .. logger.format(string.format("%.2f ms", elapsedTime), "cyan"))
        return elapsedTime
    else
        return -1
    end
end

local function pingServers(servers)
    if type(servers) ~= "table" or #servers == 0 then
        logger.error(logger.format("No servers provided for pinging.", "red"))
        return {}
    end

    local results = {}
    for _, server in ipairs(servers) do
        local ping = pingServer(server.httpUrl)
        if ping >= 0 then
            table.insert(results, { id = server.id, httpUrl = server.httpUrl, ping = ping })
        else
            logger.debug("Failed to ping server " .. logger.format(server.httpUrl, "purple") .. ". It may be unresponsive.")
        end
    end
    table.sort(results, function(a, b) return a.ping < b.ping end)
    return results
end

local function getServersToPing(authServer) -- return list of {id, httpUrl}
    local success, response, code = http.get("http://" .. authServer .. "/servers-to-ping")
    if not success then
        logger.error(logger.format("Failed to get the list of servers to ping from auth server " .. logger.format(authServer, "purple") .. ".", "red"))
        return nil
    end
    return response
end

-- AuthServer Related Functions
local function getAuthServer()
    local servers = randomizeTable(authServers)
    local unresponsiveCount = 0

    for _, server in ipairs(servers) do
        local serverColoredText = logger.format(server, "purple")
        local success = http.get("http://" .. server .. "/health")
        if success then
            logger.info("Selected auth server: " .. serverColoredText)
            return server
        else
            logger.debugWarning("Auth server " .. serverColoredText .. " is not responding. Trying another one...")
        end
    end

    logger.error("All auth servers are unresponsive.")
    return nil
end

-- Functions
local function auth(serverKey)
    logger.info("Authenticating with Beam Voice service...")
    local usedAuthServer = getAuthServer()
    if not usedAuthServer then
        logger.error(logger.format("Failed to find a valid auth server. Please check your network connection and try again. Shutting down the plugin...", "red"))
        return false
    end

    local serversPing = pingServers(getServersToPing(usedAuthServer))
    -- print(serversPing)

    -- AUTH
    local headers = {
        ["Authorization"] = "Bearer " .. serverKey
    }

    local success, response, code = http.post("http://" .. usedAuthServer .. "/auth", headers, {})
    if success and type(response) == "table" and jwt.isValid(response.token) then
        local payload = jwt.parse(response.token).payload
        if not payload or not schemaUtils.validateObject(payload, tokenSchema) then
            logger.error(logger.format("Authentication failed: invalid token payload.", "red"))
            return false
        end
        authToken = response.token
        serverInfos = payload
        return true
    else
        logger.error(logger.format("Authentication failed.", "red"))
        return false
    end
end

-- Exports
M.auth = auth
M.getToken = function() return authToken end
M.getServerInfos = function() return serverInfos end

M.isValidUUIDv4 = isValidUUIDv4

return M