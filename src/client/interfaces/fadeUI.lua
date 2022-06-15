FadeUI = {}
FadeUI.__index = FadeUI

local TweenService = game:GetService("TweenService")
local UIEvents = game.ReplicatedStorage.shared.Events.UIEvents

function FadeUI:init(e)
    engine = e
    setmetatable(FadeUI, engine.interfaces.gui)
end

function FadeUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), FadeUI)

    self:_initEvents()
    self._tween = nil
    self._frame = self._gui.Frame

    return self
end

function FadeUI:_initEvents()
    UIEvents.FadeIn.OnClientEvent:Connect(function(duration)
        if self._tween then
            self._tween:Pause()
        end

        self._frame.BackgroundTransparency = 1
        self._gui.Enabled = true
        self._tween = TweenService:Create(self._frame, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {BackgroundTransparency = 0})
        self._tween:Play()
    end)

    UIEvents.FadeOut.OnClientEvent:Connect(function(duration)
        if self._tween then
            self._tween:Pause()
        end
        
        self._frame.BackgroundTransparency = 0
        self._tween = TweenService:Create(self._frame, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        self._tween:Play()
    end)
end

return FadeUI