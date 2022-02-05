MapService = {}
MapService.__index = MapService

function MapService:init(e)
    engine = e
end

function MapService.new()
    local self = setmetatable({}, MapService)
    self._mapNames = {}
    self._mapToModes = {}
    self._modesToMap = {}

    self:gatherData()
    
    print("Created Map Service")
    return self
end

function MapService:selectMap()
    local map = self._mapNames[math.random(1, #self._mapNames)]
    return map
end

function MapService:selectMode(map)
    local possibleModes = self._mapToModes[map]
    return possibleModes[math.random(1, #possibleModes)]
end

function MapService:gatherData()
    for _, map in pairs(game.ServerScriptService.Server.classes.maps:GetChildren()) do
        print(map)
        local map = map.Name
        local mapObj = engine.maps[map]
            
        if mapObj then
            mapObj = mapObj.new()
            table.insert(self._mapNames, map)
            self._mapToModes[map] = mapObj._modes
            
            for _, mode in pairs(mapObj._modes) do
                self._modesToMap[mode] = self._modesToMap[mode] or {}
                self._modesToMap[mode][map] = true
                print(map, "has mode", mode)
            end
            
            print("Added map data for", map, "to Map Service")
        end
    end
end

return MapService