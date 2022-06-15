GameDescriptionUI = {}
GameDescriptionUI.__index = GameDescriptionUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents
local modeEvents = gameEvents.ModeEvents

function GameDescriptionUI:init(e)
    engine = e
    setmetatable(GameDescriptionUI, engine.interfaces.gui)
end

function GameDescriptionUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), GameDescriptionUI)
    
    self._mainframe = self._gui.GameDescription
    self:initEvents()

    return self
end

function GameDescriptionUI:initEvents()
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

return GameDescriptionUI