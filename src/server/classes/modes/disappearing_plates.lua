DisppearingPlates = {}
DisppearingPlates.__index = DisppearingPlates

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents
local events = game.ReplicatedStorage.shared.Events

function DisppearingPlates:init(e)
    engine = e
    setmetatable(DisppearingPlates, engine.classes.mode)
end

function DisppearingPlates.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), DisppearingPlates)
    self._name = "Disappearing Plates"
    self._roundTime = 60
    self._goalPlayerCount = 2
    self._tiles = {}
    self._elapsedTime = 0

    return self
end

function DisppearingPlates:initMapEvents()
    self._tiles = self._map._model.Tiles:GetChildren()

    for _, player in pairs(self._participatingPlayers) do
        if player then
            events.GameEvents.MapEvents.InitTileRegions:FireClient(player)
        end
    end

    self:_initTileEnteredEvent()
    self:_initTileExitedEvent()
end

function DisppearingPlates:onGameTick()
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

function DisppearingPlates:eliminate(player)
    -- handles elimination of player; defaults to elimination on first death --
    local data = self._playerModeData[player]

    if data and data["Active"] then
        data["Alive"] = false
        data["Active"] = false
        
        print("Eliminated", player)

        if self:_countActivePlayers() <= self._goalPlayerCount then
            engine.services.game_service:toPostgame()
        end
    end
end

function DisppearingPlates:_rumbleAndDestroy(tile)
    local origin = tile.PrimaryPart.Position
    local dropDistance = 100
    local riseDistance = 3
    local riseTime = (1.5 - ((self._elapsedTime / (self._roundTime - 10)) * .75))
    
    -- rise
    for i = 1, riseDistance * 10 do
        tile:PivotTo(CFrame.new(origin + Vector3.new(0, i / 10, 0)))
        task.wait(riseTime / (riseDistance * 10))   
    end

    -- drop
    for i = 1, dropDistance do
        if tile and tile.PrimaryPart then
            tile:PivotTo(CFrame.new(tile.PrimaryPart.Position + Vector3.new(0, -1, 0)))
            task.wait()    
        end
    end

    if tile then
        tile:Destroy()
    end
end

function DisppearingPlates:_onTileEntered(player, tile)
    local index = table.find(self._tiles, tile)
    print(index)

    if index then
        table.remove(self._tiles, index)
        self:_rumbleAndDestroy(tile)
    end
end

return DisppearingPlates