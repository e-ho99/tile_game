InterfaceService = {}
InterfaceService.__index = InterfaceService

function InterfaceService:init(e)
    engine = e
end

function InterfaceService.new()
    local self = setmetatable({}, InterfaceService)

    self._playerGuis = {} -- stores references to gui objects
    self._starterGuis = {{"timerUI", true}, {"winnersUI", false}} -- guis added when player joins
    
    self:initGuis()

    print("Created Game Service")
    return self
end

function InterfaceService:initGuis()
    for _, guiData in pairs(self._starterGuis) do
        self:addGui(guiData[1], guiData[2])
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

function InterfaceService:getGui(guiName)
    local findGui = self._playerGuis[guiName]

    if findGui then
        return findGui
    end
end

return InterfaceService