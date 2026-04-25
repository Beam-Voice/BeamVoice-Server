local M = {}

local mime = require("libs.mime")

local function base64url_decode(input)
    input = input:gsub("-", "+"):gsub("_", "/")
    local padding = #input % 4
    if padding > 0 then
        input = input .. string.rep("=", 4 - padding)
    end
    return mime.unb64(input)
end

local function isValidJWT(token)
    if type(token) ~= "string" then return false end
    local parts = {}
    for part in token:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    return #parts == 3
end

local function parseJwt(token)
    if not isValidJWT(token) then
        return nil
    end

    local parts = {}
    for part in token:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    local header = base64url_decode(parts[1])
    local payload = base64url_decode(parts[2])

    return {
        header = Util.JsonDecode(header),
        payload = Util.JsonDecode(payload),
        signature = parts[3]
    }
end

-- Exports
M.isValid = isValidJWT
M.parse = parseJwt

return M