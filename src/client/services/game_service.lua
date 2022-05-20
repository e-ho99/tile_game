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
    self._movement = {["WalkSpeed"] = 21, ["JumpPower"] = 75}
    self._handlers = {}
    self._tool = nil

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
        for _, handler in pairs (self._handlers) do
            handler:Destroy()
        end

        if self._tool then
            self._tool = self._tool:Destroy()
        end
    end)

    gameEvents.ModeEvents.ModeEnabled.OnClientEvent:Connect(function()
        for _, handler in pairs (self._handlers) do
            handler:enable()
        end
    end)

    gameEvents.ModeEvents.ModeDisabled.OnClientEvent:Connect(function()
        for _, handler in pairs (self._handlers) do
            handler:disable()
        end
    end)

    gameEvents.ModeEvents.ShowUI.OnClientEvent:Connect(function(uiName)
        engine.services.interface_service:addGui(uiName .. "UI", true)
    end)

    gameEvents.ModeEvents.RemoveUI.OnClientEvent:Connect(function(uiName)
        engine.services.interface_service:removeGui(uiName .. "UI")
    end)

    gameEvents.MapEvents.InitTileRegions.OnClientEvent:Connect(function(events)
        if self._mapModel then
            table.insert(self._handlers, engine.handlers.tile_region_handler.new(self._mapModel))
        end
    end)

    gameEvents.ModeEvents.InitModeHandler.OnClientEvent:Connect(function(mode, args)
        local findHandler = engine.handlers[mode .. "_handler"]

        if findHandler then
            print("created handler", args)
            findHandler.new(args)
        end
    end)

    gameEvents.ToolEvents.SendTool.OnClientEvent:Connect(function(tool)
        local toolObj = engine.classes[tool.Name:lower()]

        if toolObj then
            self._tool = toolObj.new(tool)
        else
            warn("Could not locate tool", tool.Name:lower())
        end
    end)
end

return GameServiceClient