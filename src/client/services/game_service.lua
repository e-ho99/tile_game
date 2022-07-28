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

    gameEvents.MapEvents.InitTileRegions.OnClientEvent:Connect(function(listenEntered, listenExited)
        if self._mapModel then
            table.insert(self._handlers, engine.handlers.tile_region_handler.new(self._mapModel, listenEntered, listenExited))
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

    gameEvents.CameraEvents.LoadingMap.OnClientEvent:Connect(function(cf)
        gameEvents.CameraEvents.SetCamera:Fire({
            CameraType = Enum.CameraType.Scriptable,
            CFrame = cf
        })
    end)

    gameEvents.CameraEvents.ResetCamera.OnClientEvent:Connect(function()
        local camera = workspace.CurrentCamera
        local character = game.Players.LocalPlayer.Character
        
        if character then
            gameEvents.CameraEvents.SetCamera:Fire({
                CameraSubject = character.Humanoid,
                CameraType = Enum.CameraType.Custom,
                CFrame = character.Head.CFrame
            })
        end
    end)
end

return GameServiceClient