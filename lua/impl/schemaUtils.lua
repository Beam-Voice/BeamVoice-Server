local M = {}

function M.validateObject(obj, schema)
    if type(obj) ~= "table" then
        return false, string.format("Expected a table, got %s", type(obj))
    end

    for key, expected in pairs(schema) do
        if type(expected) ~= "string" then
            return false, string.format("'%s': invalid schema (expected string, got %s)", key, type(expected))
        end
        local optional = expected:sub(1, 1) == "?"
        if optional then expected = expected:sub(2) end

        local value = obj[key]
        if value == nil then
            if not optional then
                return false, string.format("'%s': missing (expected %s)", key, expected)
            end
        elseif type(value) ~= expected then
            return false, string.format("'%s': expected %s, got %s", key, expected, type(value))
        end
    end
    return true, nil
end

return M