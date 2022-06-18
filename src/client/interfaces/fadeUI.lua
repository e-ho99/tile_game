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
    self._holder = self._gui.Holder

    return self
end

function FadeUI:_initEvents()
    UIEvents.FadeIn.OnClientEvent:Connect(function(duration)
        for i = 1,#self._holder:GetChildren() do
            if self._holder:FindFirstChild(tostring(i))then
                local Bar = self._holder:FindFirstChild(tostring(i))
                Bar:TweenPosition(Bar.Position + UDim2.new(0,0,1,0),Enum.EasingDirection.InOut,nil,0.3)
                task.wait(0.03)
            end
        end

        --[[ FADE TRANSPARENCY ]]--
        -- if self._tween then
        --     self._tween:Pause()
        -- end

        -- self._frame.BackgroundTransparency = 1
        -- self._gui.Enabled = true
        -- self._tween = TweenService:Create(self._frame, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {BackgroundTransparency = 0})
        -- self._tween:Play()
    end)

    UIEvents.FadeOut.OnClientEvent:Connect(function(duration)
        for i = 1,#self._holder:GetChildren() do
            if self._holder:FindFirstChild(tostring(i))then
                local Bar = self._holder:FindFirstChild(tostring(i))
                Bar:TweenPosition(Bar.Position + UDim2.new(0,0,-1,0),Enum.EasingDirection.InOut,nil,0.3)
                task.wait(0.03)
            end
        end

        --[[ FADE TRANSPARENCY ]]--
        -- if self._tween then
        --     self._tween:Pause()
        -- end
        
        -- self._frame.BackgroundTransparency = 0
        -- self._tween = TweenService:Create(self._frame, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        -- self._tween:Play()
    end)
end

return FadeUI