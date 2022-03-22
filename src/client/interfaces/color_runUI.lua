TimerUI = {}
TimerUI.__index = TimerUI

local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function TimerUI:init(e)
    engine = e
    setmetatable(TimerUI, engine.interfaces.gui)
end

function TimerUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), TimerUI)

    self._time = 0
    self._timeLength = timerEvents.GetTimeLength:InvokeServer()
    
    self:initEvents()
    self:updateTime(timerEvents.GetTime:InvokeServer())
    self:updateStatus(timerEvents.Parent.GetStatus:InvokeServer())
    return self
end

function TimerUI:initEvents()
 
end

return TimerUI