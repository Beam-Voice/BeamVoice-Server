local audioManager = require("voice.audioManager")

local M = {}

-- Functions
local function init()
    MP.RegisterEvent("voice_joinDialog", "BeamVoiceJoinDialogHandler")
    MP.RegisterEvent("onPlayerJoin", "BeamVoiceJoinMessageJoinHandler")
end

-- Event Handlers
function BeamVoiceJoinDialogHandler(player_id, interaction_id)
    if audioManager.isPlayerAuthenticated(player_id) then return end

    local success, token = audioManager.authPlayer(player_id)
    if success then
        MP.SendChatMessage(player_id, "You just joined the voice chat !")
        MP.TriggerClientEvent(player_id, "BeamVoice_openLink", "https://audio.beamvoice.net/?token=" .. token)  
    end
end

function BeamVoiceJoinMessageJoinHandler(player_id)
    MP.TriggerClientEventJson(player_id, "BeamVoice_openDialog", {
        title = "This server uses BeamVoice!",
        body = "This server uses BeamVoice, an in-game proximity voice chat. Hear and talk to other players as you drive near them. Want to join?",
        buttons = {{
            label = "YES JOIN !",
            key = "voice_joinDialog",
            default = true
        }, {
            label = "Nah, its okay for me. ",
            key = nil,
            isCancel = true
        }},
        class = "experimental",
        interactionID = "voice_joinDialog",
        reportToServer = true
    })
end

-- Exports
M.init = init

return M
