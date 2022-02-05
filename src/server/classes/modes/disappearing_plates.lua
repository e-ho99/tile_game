DisppearingPlates = {}
DisppearingPlates.__index = DisppearingPlates

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

return DisppearingPlates