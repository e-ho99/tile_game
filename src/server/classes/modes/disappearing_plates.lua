DisppearingPlates = {}
DisppearingPlates.__index = DisppearingPlates

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents

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

    return self
end

function DisppearingPlates:initMapEvents()
    self._tiles = self._map._model.Tiles:GetChildren()

    for _, tile in pairs (self._tiles) do
        
    end
end

function DisppearingPlates:onGameTick()
    local dT = self._roundTime - engine.services.timer_service._time -- time elapsed
    local multiplier = math.ceil(dT / (self._roundTime / 6))
    local amount = math.ceil(math.random(2, 6) * multiplier)

    for i= 1, amount do
        if #self._tiles > 0 then
            local num = math.random(1, #self._tiles)
            local selectedTile = self._tiles[num]
            table.remove(self._tiles, num)

            if selectedTile and selectedTile.PrimaryPart then
                self:_rumbleAndDestroy(selectedTile)
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
    local dropDistance = 200
    local riseDistance = 20

    -- rise
    for i = 1, riseDistance do
        tile:PivotTo(CFrame.new(origin + Vector3.new(0, i / 10, 0)))
        task.wait(.025)    
    end

    -- drop
    for i = 1, dropDistance do
        if tile and tile.PrimaryPart then
            tile:PivotTo(CFrame.new(tile.PrimaryPart.Position + Vector3.new(0, -1, 0)))
            task.wait(.025)    
        end
    end

    if tile then
        tile:Destroy()
    end
end

return DisppearingPlates