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

    self:_initEvents()

    print("Created Game Service Client")
    return self
end

function GameServiceClient:_initEvents()
    gameEvents.SetMap.OnClientEvent:Connect(function(mapName, mapModel)
        self._map = mapName
        self._mapModel = mapModel
        print("Client map", self._map, self._mapModel)
    end)

    gameEvents.SetMode.OnClientEvent:Connect(function(modeName)
        self._mode = modeName
        print("Client mode", self._mode)
    end)

    gameEvents.ClearGame.OnClientEvent:Connect(function()
        self._regionHandler = self._regionHandler:Destroy() -- sets _regionHandler to nil
    end)

    gameEvents.ModeEvents.ModeEnabled.OnClientEvent:Connect(function()
        self._regionHandler:enable()
    end)

    gameEvents.ModeEvents.ModeDisabled.OnClientEvent:Connect(function()
        self._regionHandler:disable()
    end)

    gameEvents.ModeEvents.ShowUI.OnClientEvent:Connect(function(mode)
        engine.services.interface_service:addGui(mode .. "UI", true)
    end)

    gameEvents.ModeEvents.RemoveUI.OnClientEvent:Connect(function(mode)
        engine.services.interface_service:removeGui(mode .. "UI")
    end)

    gameEvents.MapEvents.InitTileRegions.OnClientEvent:Connect(function(events)
        if self._mapModel then
            self._regionHandler = engine.handlers.tile_region_handler.new(self._mapModel)
        end
    end)
end

return GameServiceClient