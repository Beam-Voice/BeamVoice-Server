local TOML = require("libs.toml")

-- Helpers
local function readToml(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = TOML.parse(file:read("*all"))
    file:close()
    return content
end

local function deepMerge(base, override)
    for k, v in pairs(override) do
        if type(v) == "table" and type(base[k]) == "table" then
            deepMerge(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end

-- Functions
local function loadConfig()
    FS.CreateDirectory("configs")
    logger.info("Loading configuration...")

    if not FS.Exists("configs/BeamVoice.toml") then
        logger.info("Creating Default Configuration")
        FS.Copy(pluginPath .. "/defaultConfig.toml", "configs/BeamVoice.toml")
    end

    local defaults = readToml(pluginPath .. "/defaultConfig.toml")
    if not defaults then
        logger.error("Failed to read default configuration")
        return nil
    end

    local userConfig = readToml("configs/BeamVoice.toml")
    if not userConfig then
        logger.error("Failed to parse configs/BeamVoice.toml, please check the file for syntax errors.")
        return defaults
    end

    logger.info("Configuration Loaded Successfully")
    return deepMerge(defaults, userConfig)
end

-- Exports
return loadConfig()