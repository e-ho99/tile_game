ModeDescriptionUI = {}
ModeDescriptionUI.__index = ModeDescriptionUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents
local modeEvents = gameEvents.ModeEvents

function ModeDescriptionUI:init(e)
    engine = e
    setmetatable(ModeDescriptionUI, engine.interfaces.gui)
end

function ModeDescriptionUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), ModeDescriptionUI)
    
    self._mainframe = self._gui.GameDescription
    self:initEvents()

    return self
end

function ModeDescriptionUI:initEvents()
    gameEvents.ShowGameDescription.OnClientEvent:Connect(function(map, mode, description)
        self._gui.Enabled = true
        self._mainframe.MapLabel.Text = map:upper()
        self._mainframe.ModeLabel.Text = ("[" .. mode .. "]"):upper()
        self._mainframe.DescriptionLabel.Text = description
    end)

    gameEvents.HideGameDescription.OnClientEvent:Connect(function()
        self._gui.Enabled = false
    end)
end

return ModeDescriptionUI