ToyField = {}
ToyField.__index = ToyField
--ddddd
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function ToyField:init(e)
    engine = e
    setmetatable(ToyField, engine.classes.map)
end

function ToyField.new()
    local self =  setmetatable(engine.classes.map.new(), ToyField)
    self._modes = {"Disappearing Plates", "Color Run"}
    self._mapTemplate = game.ServerStorage.Maps["Toy Field"]
    self._name = "toy field"
    
    return self
end

return ToyField