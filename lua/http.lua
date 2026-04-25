local M = {}

local http = require("libs.socket.http")
local ltn12 = require("libs.ltn12")

-- Header
local function enum(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function()
            error("cannot modify enum")
        end,
    })
end

local BodyType = enum {
    JSON = "application/json",
    TEXT = "text/plain",
    XML = "application/xml",
}

-- Helpers
local function mergeTables(baseTable, extraTable)
    if not extraTable or type(extraTable) ~= "table" then return baseTable end
    for k, v in pairs(extraTable) do
        baseTable[k] = v
    end
    return baseTable
end

local function httpRequest(url, method, headers, body)
    local response = {}
    local res, code, responseHeaders = http.request({
        url = url,
        method = method,
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response)
    })

    local rawResponse = table.concat(response or {})
    local returnResponse = rawResponse ~= "" and rawResponse or nil

    if returnResponse and (returnResponse:sub(1, 1) == "{" or returnResponse:sub(1, 1) == "[") then
        returnResponse = Util.JsonDecode(returnResponse)
    end

    return code == 200, returnResponse, code
end

local function sendRequest(url, method, customHeaders, body)
    customHeaders = customHeaders or {}
    body = body or ""
    local bodyString = type(body) == "table" and Util.JsonEncode(body) or tostring(body or "")
    local headers = mergeTables({
        ["Content-Type"] = type(body) == "table" and BodyType.JSON or BodyType.TEXT,
        ["Content-Length"] = bodyString and #bodyString or 0
    }, customHeaders)

    return httpRequest(url, method, headers, bodyString)
end

-- Http Requests
local function get(url, customHeaders, body)
    return sendRequest(url, "GET", customHeaders, body)
end

local function post(url, customHeaders, body)
    return sendRequest(url, "POST", customHeaders, body)
end

local function put(url, customHeaders, body)
    return sendRequest(url, "PUT", customHeaders, body)
end

local function delete(url, customHeaders, body)
    return sendRequest(url, "DELETE", customHeaders, body)
end

-- Exports
M.BodyType = BodyType
M.get = get
M.post = post
M.put = put
M.delete = delete

return M