Timer = {}
Timer.__index = Timer

function Timer:init(e)
    engine = e
end

function Timer.new()
    local self = setmetatable({}, Timer)
    self._startTime = 0
    self._timer = 0

    return self
end

function Timer:setTime(seconds)
    self._timer = seconds    
end

function Timer:update(tickDiff)
    self._timer = self._timer - tickDiff

    return self._timer
end

return Timer