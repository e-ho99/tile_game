GameServiceClient = {}
GameServiceClient.__index = GameServiceClient

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents

function GameServiceClient:init(e)
    engine = e
end

function GameServiceClient.new()
    local self = setmetatable({}, GameServiceClient)
    self._map, self._mapModel = gameEvents.GetMap:InvokeServer()
    self._mode = gameEvents.GetMode:InvokeServer()
    self._regionHandler = nil

    self:initEvents()

    print("Created Game Service Client")
    return self
end

function GameServiceClient:initEvents()
    gameEvents.SetMap.OnClientEvent:Connect(function(mapName, mapModel)
        self._map = mapName
        self._mapModel = mapModel
        print("Client map", self._map, self._mapModel)
    end)

    gameEvents.SetMode.OnClientEvent:Connect(function(modeName)
        self._mode = modeName
        print("Client mode", self._mode)
    end)

    gameEvents.MapEvents.InitTileRegions.OnClientEvent:Connect(function(events)
        if self._mapModel then
            self._regionHandler = engine.handlers.tile_region_handler.new(self._mapModel)
        end
    end)
end

return GameServiceClient