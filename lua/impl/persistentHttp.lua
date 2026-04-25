local socket = require("libs.socket")

-- Define Class Attributes
local PersistentHttp = {
    host = nil,
    port = 80,
    sock = nil,
}

-- Helpers
local function buildRequest(method, path, headers, body)
    local parts = { method .. " " .. path .. " HTTP/1.1\r\n" }
    for k, v in pairs(headers) do
        parts[#parts + 1] = k .. ": " .. v .. "\r\n"
    end
    parts[#parts + 1] = "\r\n"
    if body then parts[#parts + 1] = body end
    return table.concat(parts)
end

local function readResponse(sock)
    local statusLine, err = sock:receive("*l")
    if not statusLine then return nil, nil, err end

    local code = tonumber(statusLine:match("HTTP/%d%.%d (%d+)"))
    if not code then return nil, nil, "invalid status line" end

    local headers = {}
    while true do
        local line = sock:receive("*l")
        if not line or line == "" then break end
        local k, v = line:match("^(.-):%s*(.*)")
        if k then headers[k:lower()] = v end
    end

    local body = ""
    local len = tonumber(headers["content-length"])
    if len and len > 0 then
        body = sock:receive(len) or ""
    end

    return code, body, headers
end

-- Define Class Methods
function PersistentHttp:connect()
    if self.sock then
        self.sock:close()
        self.sock = nil
    end

    local sock = socket.tcp()
    sock:settimeout(10)

    local ok, err = sock:connect(self.host, self.port)
    if not ok then return false, err end

    self.sock = sock
    return true
end

function PersistentHttp:close()
    if not self.sock then return end
    self.sock:close()
    self.sock = nil
end

function PersistentHttp:request(method, path, headers, body)
    if not self.sock then return nil, nil, "connection closed" end

    local ok, err = self.sock:send(buildRequest(method, path, headers, body))
    if not ok then return nil, nil, err end

    local code, respBody, respHeaders = readResponse(self.sock)
    if not code then return nil, nil, respBody end

    if respHeaders["connection"] and respHeaders["connection"]:lower() == "close" then
        self:close()
    end

    return code, respBody, respHeaders
end

function PersistentHttp:json_post(path, customHeaders, jsonBody)
    local body = Util.JsonEncode(jsonBody or {})

    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#body),
        ["Host"] = self.host .. ":" .. self.port,
        ["Connection"] = "keep-alive",
    }
    for k, v in pairs(customHeaders or {}) do
        headers[k] = v
    end

    local code, response = self:request("POST", path, headers, body)
    if not code then return false, response, 0 end

    if response and response ~= "" and (response:sub(1, 1) == "{" or response:sub(1, 1) == "[") then
        response = Util.JsonDecode(response)
    end

    return code == 200, response, code
end

-- Define Class Constructor
function PersistentHttp:new(host, port)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.host = host
    o.port = port or 80
    o.sock = nil

    return o
end

function PersistentHttp.fromUrl(url)
    local host, port = url:match("^(.+):(%d+)$")
    if not host then
        host = url
        port = 80
    else
        port = tonumber(port)
    end

    local instance = PersistentHttp:new(host, port)
    local ok, err = instance:connect()
    if not ok then return nil, err end
    return instance
end

return PersistentHttp
