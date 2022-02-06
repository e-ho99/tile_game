DisppearingPlates = {}
DisppearingPlates.__index = DisppearingPlates

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function DisppearingPlates:init(e)
    engine = e
    setmetatable(DisppearingPlates, engine.classes.mode)
end

function DisppearingPlates.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), DisppearingPlates)
    self._name = "Disappearing Plates"
    self._roundTime = 10

    return self
end

function DisppearingPlates:initMapEvents()
    local tileTweens = {
        ["Disppear"] = {},
        ["Show"] = {}
    }

    for _, tile in pairs (self._map._model.Tiles:GetChildren()) do
        local base = tile.PrimaryPart
        local parts = tile:GetChildren()
        local active = true

        for _, part in pairs (parts) do
            local disappear = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0), {["Transparency"] = 1})
            disappear.Completed:Connect(function()
                part.CanCollide = false
            end)

            local show = TweenService:Create(part, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0), {["Transparency"] = 0})
            tileTweens.Disppear[part] = disappear
            tileTweens.Show[part] = show
        end

        base.Touched:Connect(function()
            if active then
                active = false
                for _, part in pairs (parts) do
                    tileTweens.Disppear[part]:Play()
                    task.wait(5)
                    part.CanCollide = true
                    tileTweens.Show[part]:Play()
                end
                task.wait(1)
                active = true
            end
        end) 
    end
end

return DisppearingPlates