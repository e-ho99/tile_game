ScorchingTiles = {}
ScorchingTiles.__index = ScorchingTiles

local TweenService = game:GetService("TweenService")
local events = game.ReplicatedStorage.shared.Events
local modeEvents = events.GameEvents.ModeEvents

function ScorchingTiles:init(e)
    engine = e
    setmetatable(ScorchingTiles, engine.classes.mode)
end

function ScorchingTiles.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), ScorchingTiles)
    self._name = "Scorching Tiles"
    self._modeData = {["Active"] = true, ["Alive"] = true, ["Safe"] = false}
    self._playerModeData = self:_getPlayerModeData(participatingPlayers)
    self._uiType = "survival"
    self._canClaimTiles = false
    self._goalPlayerCount = 2
    self._roundTime = 30
    self._tiles = {}
    self._elapsedTime = 0
    self._safeTiles = {}

    return self
end

function ScorchingTiles:initMapEvents()
    self._tiles = self._map._model.Tiles:GetChildren()

    for _, userId in pairs(self._participatingPlayers) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player then
            events.GameEvents.MapEvents.InitTileRegions:FireClient(player)
        end
    end

    self:_initTileEnteredEvent()
end

function ScorchingTiles:eliminate(player)
    -- handles elimination of player; defaults to elimination on first death --
    local data = self._playerModeData[player.UserId]

    if data and data["Active"] then
        data["Alive"] = false
        data["Active"] = false

        events.GameEvents.ModeEvents.PlayerEliminated:FireAllClients(player.UserId)
    end
end

function ScorchingTiles:startRound()
    if not self._enabled then
        self._enabled = true

        for userId, data in pairs(self._playerModeData) do
            modeEvents.ModeEnabled:FireClient(game.Players:GetPlayerByUserId(userId))
        end
    end

    self:_selectSafeTiles()
    
    engine.services.timer_service:enable(self._roundTime)
    self:thawPlayers(self:_getActivePlayers())

    self._currentRound = self._currentRound + 1
    self._canClaimTiles = true
end

function ScorchingTiles:roundComplete()
    self._canClaimTiles = false
    self:_beginScorch()
    
    if #self:_getActivePlayers() <= self._goalPlayerCount then
        return true
    else
        -- clean up round -- 
        for tile, _ in pairs (self._safeTiles) do -- clearing previous tiles
            self._safeTiles[tile] = nil
        end

        for userid, modeData in pairs (self._playerModeData) do
            modeData.Safe = false
        end

        self:startRound()

        return false
    end
end

function ScorchingTiles:_onTileEntered(player, tile)
    local safeTile = self._safeTiles[tile]

    if self._canClaimTiles and safeTile ~= nil and safeTile == false then -- checking if tile is safe and not occupied
        self:_claimTile(tile, player)
    end
end

function ScorchingTiles:_claimTile(tile, player)
    self._safeTiles[tile] = true

    -- lock player
    self:freezePlayers({player})
    player.Character:PivotTo(tile.Base.CFrame + Vector3.new(0, 5, 0))
    self._playerModeData[player.userId].Safe = true
    tile.Plate.Material = Enum.Material.Plastic

    -- check remaining safe tiles and shortcut to end of round if all occupied -- 
    local allOccupied = true

    for tile, state in pairs (self._safeTiles) do
        if not state then
            allOccupied = false
            
            break
        end
    end

    if allOccupied and engine.services.timer_service._time > 10 then
        engine.services.timer_service:setTimer(3)
    end
end

function ScorchingTiles:_beginScorch()
    print("begin scorch")
    local originColor

    for i, tile in pairs (self._tiles) do
        local plate = tile.Plate
        originColor = plate.Color
        
        if (not self._safeTiles[tile]) then
            task.spawn(function()
                plate.Color = Color3.fromRGB(54, 54, 54)
                plate.Material = Enum.Material.Neon
                task.wait(1)
                local t = TweenService:Create(plate, 
                    TweenInfo.new(2, Enum.EasingStyle.Linear), {["Color"] = Color3.fromRGB(167, 90, 38)})
                t:Play()
                task.wait(5)
                local t = TweenService:Create(plate, 
                    TweenInfo.new(2, Enum.EasingStyle.Linear), {["Color"] = Color3.fromRGB(54, 54, 54)})
                t:Play()
                print("disappear")
            end)
        end
    end

    task.wait(4)
    self:_burnPlayers()
    task.wait(6)

    print("plastic")
    for i, tile in pairs (self._tiles) do
        tile.Plate.Color = originColor
        tile.Plate.Material = Enum.Material.Plastic
    end
end

function ScorchingTiles:_burnPlayers()
    for userId, playerData in pairs (self._playerModeData) do
        local player = game.Players:GetPlayerByUserId(userId)

        if playerData.Active and not playerData.Safe then
            self:eliminate(player)
            player.Character.Humanoid.Health = 0

            for _, child in pairs (player.Character:GetChildren()) do
                if child:IsA("BasePart") then
                    child.BrickColor = BrickColor.new("Really black")

                    if child.Name == "Head" then
                        local smoke = game.ReplicatedStorage.assets.environment.BurnSmoke:Clone()
                        smoke.Parent = child
                    end
                elseif child:IsA("Clothing") then
                    child:Destroy()
                end
            end
        end
    end
end

function ScorchingTiles:_selectSafeTiles()
    local activePlayers = self:_getActivePlayers()
    local possibleTiles = self._map._model.Tiles:GetChildren()

    for i = 1, math.clamp(#activePlayers - 1, 1, 30) do -- we want to run atleast once even if only one player for testing purposes
        local num = math.random(1, #possibleTiles)
        local tile = possibleTiles[num]

        self._safeTiles[tile] = false -- defaults to false as tile is not occupied
        table.remove(possibleTiles, num)

        -- TODO: safe tile effect
        tile.Plate.Material = Enum.Material.Neon
    end
end

return ScorchingTiles