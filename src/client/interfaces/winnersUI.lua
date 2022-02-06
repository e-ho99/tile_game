WinnerUI = {}
WinnerUI.__index = WinnerUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents

function WinnerUI:init(e)
    engine = e
    setmetatable(WinnerUI, engine.interfaces.gui)
end

function WinnerUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), WinnerUI)
    
    self:initEvents()
    return self
end

function WinnerUI:initEvents()
    gameEvents.SendWinners.OnClientEvent:Connect(function(winners)
        self._gui.Frame.Winners = winners
        self._gui.Enabled = true

        task.wait(5)

        self._gui.Enabled = false
    end)
end

return WinnerUI