ColorRunUI = {}
ColorRunUI.__index = ColorRunUI

local modeEvents = game.ReplicatedStorage.shared.Events.GameEvents.ModeEvents

function ColorRunUI:init(e)
    engine = e
    setmetatable(ColorRunUI, engine.interfaces.gui)
end

function ColorRunUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), ColorRunUI)
    
    self:initEvents()

    return self
end

function ColorRunUI:initEvents()
    local e = modeEvents.UpdateScore.OnClientEvent:Connect(function(team, newScore)
        local teamFrame = self._gui.Frame:FindFirstChild(team, true)

        if teamFrame then
            teamFrame.Holder.Score.Text = newScore
        end
    end)

    table.insert(self._events, e)
end

return ColorRunUI