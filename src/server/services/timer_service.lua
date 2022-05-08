TimerService = {}
TimerService.__index = TimerService
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

function TimerService:init(e)
    engine = e
end

function TimerService.new()
    local self = setmetatable({}, TimerService)

    self._enabled = false
    self._time = 0
    self._startTime = 0
    self._lastTick = nil
    self._timeElapsed = 0 -- time elapsed since _time was updated

    self:onTickLoop()
    self:initEvents()
    print("Created Timer Service")
    return self
end

function TimerService:disable()
    self._enabled = false
end

function TimerService:enable(seconds) -- optional seconds parameter to set time
    if seconds then
        self:setTimer(seconds)
    end

    self._lastTick = tick()
    self._enabled = true

    print("Timer enabled", seconds)
end

function TimerService:setTimer(seconds)
    self._time = seconds
    self._startTime = seconds

    timerEvents.SendTime:FireAllClients(self._time)
    timerEvents.SendTimeLength:FireAllClients(self._startTime)
end

function TimerService:updateTimer(newTime)
    self._time = newTime
    timerEvents.SendTime:FireAllClients(self._time)
end

function TimerService:initEvents()
    timerEvents.GetTime.OnServerInvoke = function()
        return self._time
    end

    timerEvents.GetTimeLength.OnServerInvoke = function()
        return self._startTime
    end
end

function TimerService:onTickLoop()
    game:GetService("RunService").Stepped:Connect(function()
        if self._enabled then
            local currentTick = tick()
            local dt = currentTick - self._lastTick

            self._timeElapsed = self._timeElapsed + dt
            self._lastTick = currentTick

            if self._timeElapsed >= 1 then
                self._timeElapsed = 0
                self:updateTimer(math.clamp(self._time - 1, 0, math.huge))
                engine.services.game_service:timerTick(self._timeElapsed) -- notify game service 

                --print(self._time)
                if self._time == 0 and self._enabled then
                    self._enabled = false
                    engine.services.game_service:timerComplete()
                end
            end
        end
    end)
end

return TimerService