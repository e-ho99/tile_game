FallingTiles = {}
FallingTiles.__index = FallingTiles

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents
local events = game.ReplicatedStorage.shared.Events

function FallingTiles:init(e)
    engine = e
    setmetatable(FallingTiles, engine.classes.mode)
end

function FallingTiles.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), FallingTiles)
    self._name = "Falling Tiles"
    self._uiType = "survival"
    self._roundTime = 60
    self._goalPlayerCount = 2
    self._tiles = {}
    self._elapsedTime = 0

    return self
end

function FallingTiles:initMapEvents()
    self._tiles = self._map._model.Tiles:GetChildren()

    for _, userId in pairs(self._participatingPlayers) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player then
            --events.GameEvents.MapEvents.InitTileRegions:FireClient(player)
        end
    end
end

function FallingTiles:onGameTick()
    self._elapsedTime = self._roundTime - engine.services.timer_service._time -- time elapsed
    local multiplier = math.ceil(self._elapsedTime / (self._roundTime / 6))
    local amount = math.ceil(math.random(2, 6) * multiplier)

    for i= 1, amount do
        if #self._tiles > 0 then
            local num = math.random(1, #self._tiles)
            local selectedTile = self._tiles[num]
            table.remove(self._tiles, num)

            if selectedTile and selectedTile.PrimaryPart then
                self:_rumbleAndDestroy(selectedTile, num)
            end
        end
    end
end

function FallingTiles:eliminate(player)
    -- handles elimination of player; defaults to elimination on first death --
    local data = self._playerModeData[player.UserId]

    if data and data["Active"] then
        data["Alive"] = false
        data["Active"] = false

        if #self:_getActivePlayers() <= self._goalPlayerCount then
            engine.services.game_service:toPostgame()
        end

        events.GameEvents.ModeEvents.PlayerEliminated:FireAllClients(player.UserId)
    end
end

function FallingTiles:_rumbleAndDestroy(tile)
    local origin = tile.PrimaryPart.Position
    local dropDistance = 100
    local preDropDistance = 2

    -- pre-drop
    for i = 1, (preDropDistance * 10) / 2 do
        tile:PivotTo(tile:GetPivot() * CFrame.new(0, -.1, 0))
        task.wait(.05)   
    end
    
    task.wait(1)

    -- drop
    for i = 1, dropDistance do
        if tile and tile.PrimaryPart then
            tile:PivotTo(tile:GetPivot() * CFrame.new(0, -1, 0))
            task.wait()    
        end
    end

    if tile then
        tile:Destroy()
    end
end

function FallingTiles:_onTileEntered(player, tile)
    local index = table.find(self._tiles, tile)

    if index then
        table.remove(self._tiles, index)
        self:_rumbleAndDestroy(tile)
    end
end

return FallingTiles