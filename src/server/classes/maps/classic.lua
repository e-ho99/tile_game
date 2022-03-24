Classic = {}
Classic.__index = Classic
--ddddd
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function Classic:init(e)
    engine = e
    setmetatable(Classic, engine.classes.map)
end

function Classic.new()
    local self =  setmetatable(engine.classes.map.new(), Classic)
    self._modes = {"Disappearing Plates", "Color Run"}
    self._mapTemplate = game.ServerStorage.Maps.Classic
    self._name = "classic"
    
    return self
end

return Classic