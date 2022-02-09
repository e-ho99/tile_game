WinnersUI = {}
WinnersUI.__index = WinnersUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents

function WinnersUI:init(e)
    engine = e
    setmetatable(WinnersUI, engine.interfaces.gui)
end

function WinnersUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), WinnersUI)
    
    self:initEvents()
    return self
end

function WinnersUI:initEvents()
    gameEvents.SendWinners.OnClientEvent:Connect(function(winners)
        print("SHOW WINNERS")

        if winners == "" then
            winners = "No winners"
        end

        self._gui.Frame.Winners.Text = winners
        self._gui.Enabled = true

        task.wait(5)

        self._gui.Enabled = false
    end)
end

return WinnersUI