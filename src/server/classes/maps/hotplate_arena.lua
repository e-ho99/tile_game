HotplateArena = {}
HotplateArena.__index = HotplateArena
--ddddd
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function HotplateArena:init(e)
    engine = e
    setmetatable(HotplateArena, engine.classes.map)
end

function HotplateArena.new()
    local self =  setmetatable(engine.classes.map.new(), HotplateArena)
    self._modes = {"Scorching Tiles"}
    self._mapTemplate = game.ServerStorage.Maps["Hotplate Arena"]
    self._name = "hotplate arena"
    
    return self
end

return HotplateArena