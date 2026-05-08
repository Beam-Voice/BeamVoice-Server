local M = {}
local initialized = false

-- Variables

-- Helpers

-- Functions
local function init()
    logger.debug("Initializing API Manager...")
    if initialized then return true end



    initialized = true
    return true
end

-- Event Handlers

-- Exports
M.init = init

return M