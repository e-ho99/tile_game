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
    timerEvents.SendTime.OnClientEvent:Connect(function(newTime)
        self:updateTime(newTime)
    end)

    timerEvents.SendTimeLength.OnClientEvent:Connect(function(newLength)
        self._timeLength = newLength
    end)

    timerEvents.SetStatus.OnClientEvent:Connect(function(newStatus)
        self._gui.Frame.Type.Text = newStatus
    end)
end

function TimerUI:updateTime(newTime)
    self._gui.Frame.Time.Text = tostring(newTime)
    self._time = newTime
end

function TimerUI:updateStatus(newStatus)
    self._gui.Frame.Type.Text = tostring(newStatus)
end

return TimerUI