Gui = {}
Gui.__index = Gui

function Gui:init(e)
    engine = e
end

function Gui.new(guiName) -- accepts script as argument to locate physical gui obj
    local self = setmetatable({}, Gui)
    self._gui = game.ReplicatedStorage.interfaces:FindFirstChild(guiName):Clone()
    self._events = {}

    return self
end

function Gui:enable()
    self._gui.Enabled = true
end

function Gui:disable()
    self._gui.Enabled = false
end

function Gui:addGui()
    self._gui.Parent = game.Players.LocalPlayer.PlayerGui
    self._gui.Enabled = false
    
    return self._gui
end

function Gui:Destroy()
    print("DESTROY GUI", self._gui)
    self._gui:Destroy()

    for _, e in pairs (self._events) do
        e:Disconnect()
    end
end

return Gui