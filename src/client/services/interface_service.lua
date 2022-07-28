InterfaceService = {}
InterfaceService.__index = InterfaceService

local UIEvents = game.ReplicatedStorage.shared.Events.UIEvents

function InterfaceService:init(e)
    engine = e
end

function InterfaceService.new()
    local self = setmetatable({}, InterfaceService)

    self._playerGuis = {} -- stores references to gui objects, key is name of gui
    self._lobbyGuis = {"timerUI", "currencyUI"}
    self._starterGuis = {
        {"timerUI", true}, {"winnersUI", false}, {"currencyUI", true}, {"mode_descriptionUI", false},
        {"fadeUI", true}} -- guis added when player joins {guiName, enabled}
    
    self:_initGuis()

    print("Created Game Service")
    return self
end

function InterfaceService:_initGuis()
    for _, guiData in pairs(self._starterGuis) do
        self:addGui(guiData[1], guiData[2])
    end

    UIEvents.ShowUI.OnClientEvent:Connect(function(uiName)
        self:addGui(uiName .. "UI", true)
    end)

    UIEvents.RemoveUI.OnClientEvent:Connect(function(uiName)
        self:removeGui(uiName .. "UI")
    end)
end

function InterfaceService:setLobbyGuis(show)
    -- show guis that are shown in lobby -- 
    for _, name in pairs (self._lobbyGuis) do
        local gui = self:getGui(name)
        
        if show then
            gui:enable()
            game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        else
            gui:disable()
            game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        end
    end
end

function InterfaceService:addGui(guiName, enabled)
    local findGui = engine.interfaces[guiName]

    if findGui then
        local gui = findGui.new()
        self._playerGuis[guiName] = gui
        gui:addGui()
        
        if enabled then
            gui:enable()
        end

        print("Added gui", guiName)
    else
        warn("Could not add", guiName)
    end
end

function InterfaceService:removeGui(guiName)
    local gui = self._playerGuis[guiName]
    
    if gui then
        gui:Destroy()
        self._playerGuis[guiName] = nil
    else
        warn("Could not find gui,", guiName)
    end
end

function InterfaceService:getGui(guiName)
    local findGui = self._playerGuis[guiName]

    if findGui then
        return findGui
    end
end

return InterfaceService