Spleef = {}
Spleef.__index = Spleef

local events = game.ReplicatedStorage.shared.Events
local modeEvents = events.GameEvents.ModeEvents

function Spleef:init(e)
    engine = e
    setmetatable(Spleef, engine.classes.mode)
end

function Spleef.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), Spleef)
    self._name = "Spleef"
    self._uiType = "survival"
    self._modeData = {["Active"] = true, ["Alive"] = true}
    self._tiles = {} -- stores array of active tiles
    self._tileState = {} -- stores dict that maps tiles to index of active tiles
    self._tool = game.ServerStorage.Tools.Spleefer
    self._goalPlayerCount = 1
    self._roundTime = 5
    self._elapsedTime = 0

    return self
end

function Spleef:initMapEvents()
    for index, tile in pairs (self._map._model.Tiles:GetChildren()) do
        table.insert(self._tiles, tile)   
        self._tileState[tile] = index
    end

    for _, userId in pairs(self._participatingPlayers) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player then
            events.GameEvents.MapEvents.InitTileRegions:FireClient(player)
        end
    end

    self:_initTileEnteredEvent()
    self:_initTileExitedEvent()
end

function Spleef:eliminate(player)
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

function Spleef:onGameTick()
    self._elapsedTime = self._roundTime - engine.services.timer_service._time -- time elapsed
    local multiplier = math.ceil(self._elapsedTime / (self._roundTime / 6))
    local amount = math.ceil(math.random(2, 6) * multiplier)

    for i= 1, amount do
        if #self._tiles > 0  then
            task.spawn(function()
                task.wait(math.random(0, 10) / 10)
                local num = math.random(1, #self._tiles)
                local selectedTile = self._tiles[num]
                self._tileState[selectedTile] = nil
                table.remove(self._tiles, num)

                if selectedTile and selectedTile.PrimaryPart then
                    self:_rumbleAndDestroy(selectedTile) 
                end
            end)
        else
            break
        end
    end
end

function Spleef:_onTileInput(player, tile)
    local tilePos = self._tileState[tile]

    if self._enabled and tilePos then
        self._tileState[tile] = nil
        table.remove(self._tiles, tilePos)
        task.spawn(function() 
            self:_rumbleAndDestroy(tile) 
        end)
    end
end

function Spleef:_rumbleAndDestroy(tile)
    local origin = tile.PrimaryPart.Position
    local dropDistance = 100
    local preDropDistance = 2

    -- pre-drop
    for i = 1, (preDropDistance * 10) / 2 do
        tile:PivotTo(tile:GetPivot() * CFrame.new(0, -.1, 0))
        task.wait()   
    end
    
    task.wait(.25)

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

return Spleef