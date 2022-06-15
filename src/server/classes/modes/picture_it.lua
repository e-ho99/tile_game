PictureIt = {}
PictureIt.__index = PictureIt

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents
local events = game.ReplicatedStorage.shared.Events
local modeEvents = events.GameEvents.ModeEvents

function PictureIt:init(e)
    engine = e
    setmetatable(PictureIt, engine.classes.mode)
end

function PictureIt.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), PictureIt)
    self._name = "Picture It"
    self._modeData = {["Active"] = true, ["Alive"] = true, ["Completed"] = false, 
        ["Position"] = nil, ["RoundPeak"] = 0}
    self._colors = {
        BrickColor.new("Storm blue"), BrickColor.new("Bright red"),
        BrickColor.new("Shamrock"), BrickColor.new("Bright violet"), BrickColor.new("Bright yellow"), 
    }
    self._solution = {}
    self._stations = {}
    self._uiType = "survival"
    self._totalRounds = 6
    self._roundTimes = {30, 20, 40, 30, 40, 30}
    self._goalPlayerCount = 0
    self._elapsedTime = 0
    self._playerModeData = self:_getPlayerModeData(participatingPlayers)

    self._map._stations = self._stations -- passing reference of mode's stations to map
    self:_initTileClickDetectorActivated()

    return self
end

function PictureIt:initPlayerEvents(playerList)
    for position, player in pairs (playerList) do
        if player then
            self._playerModeData[player.UserId].Position = position
            local c = player.Character

            if c then
                c.Humanoid.Died:Connect(function()
                    self:eliminate(player)
                end)
            else
                local event = player.CharacterAdded:Connect(function(char)
                    local character = char
                    character.Humanoid.Died:Connect(function()
                        self:eliminate(player)
                    end)
                end)

                table.insert(self._events, event)
            end

            modeEvents.ShowUI:FireClient(player, self._uiType or self._name:gsub(" ", "_"):lower())

            self:_createStation(player, position)
        end
    end
end

function PictureIt:eliminate(player)
    local data = self._playerModeData[player.UserId]

    if data and data["Active"] then
        data["Alive"] = false
        data["Active"] = false

        if #self:_getActivePlayers() == 0 and engine.services.timer_service._time > 3 then
            engine.services.timer_service:setTimer(3)
        end

        events.GameEvents.ModeEvents.PlayerEliminated:FireAllClients(player.UserId)
    end
end

function PictureIt:roundComplete()
    self._solution = {}
    
    -- eliminate/clean up empty stations --
    for userId, playerData in pairs (self._playerModeData) do
        if playerData.Active then
            local station = self._stations[userId]
            
            if playerData.Completed then
                playerData.RoundPeak = playerData.RoundPeak + 1
                station:clear()
            else
                local p = game.Players:GetPlayerByUserId(userId)
                self:eliminate(p)
                p:LoadCharacter()
                station:Destroy()
                self._stations[userId] = nil
            end
        end
    end

    
    if #self:_getActivePlayers() <= self._goalPlayerCount then
        return true
    else
        for userid, modeData in pairs (self._playerModeData) do
            modeData.Completed = false
        end
        
        self:startRound()

        return false
    end
end

function PictureIt:getWinners(winners)
    local winners = {["Players"] = {}, ["Ordered"] = false}
    local winnersString = ""
    local maximum = 1

    for userId, modeData in pairs(self._playerModeData) do
        local player = game.Players:GetPlayerByUserId(userId)
        
        if player then
            print(modeData.RoundPeak, maximum, self._currentRound)
            if modeData.RoundPeak == maximum then
                table.insert(winners.Players, player.UserId)
                winnersString = winnersString .. player.Name .. ", "
            elseif modeData.RoundPeak > maximum then
                maximum = modeData.RoundPeak
                winners.Players = {player.UserId}
                winnersString = player.Name .. ", "
            end
        end
    end

    return winners, winnersString
end

function PictureIt:giveRewards()
    for userId, playerData in pairs (self._playerModeData) do
        local dataHandler = engine.services.data_service:getHandler(userId, "PlayerData")
        local roundPeak = playerData.RoundPeak
        local multiplier = roundPeak * 15 
        local coinsAwarded = 25 + multiplier
        local expAwarded = 100 + multiplier
        
        print("Coins", coinsAwarded)
        dataHandler:incrementCoins(coinsAwarded)
        dataHandler:incrementExperience(expAwarded)
    end
end

function PictureIt:startRound()
    local roundToNum = {1, 1, 2, 2, 3, 3}
    local oldSet = roundToNum[self._currentRound]
    self._currentRound = self._currentRound + 1
    
    if oldSet > 0 and oldSet ~= roundToNum[self._currentRound] then
        self._map:hidePortrait(oldSet)
    end

    for _, station in pairs (self._stations) do -- clear all tiles
        station:hideTileSet()
        station:clear()
    end

    self._map:clearPortrait(roundToNum[self._currentRound])

    -- if (roundToNum[self._currentRound - 1] ~= nil and roundToNum[self._currentRound] ~= roundToNum[self._currentRound - 1]) then
    --     self._map:hidePortrait(roundToNum[self._currentRound - 1]) -- hide previous portrait
    -- end

    self._solution = self:_getSolution()
    self._map:showPortrait(roundToNum[self._currentRound])
    
    for _, station in pairs (self._stations) do -- clear all tiles
        station:showTileSet(roundToNum[self._currentRound])
    end

    if not self._enabled then
        self._enabled = true

        for userId, data in pairs(self._playerModeData) do
            modeEvents.ModeEnabled:FireClient(game.Players:GetPlayerByUserId(userId))
        end
    end
    
    engine.services.timer_service:enable(self._roundTimes[self._currentRound])
    self:thawPlayers(self:_getActivePlayers())

    for _, station in pairs (self._stations) do -- clear all tiles
        station:enable()
    end
end

function PictureIt:checkSolution(player, answer)
    local playerData = self._playerModeData[player.UserId]
    local incorrect = false

    if #self._solution == 0 then
        return false
    end

    for i = 1, #self._solution do
        if self._solution[i] ~= answer[i] then
            incorrect = true
            return false
        end
    end

    if not incorrect and playerData and not playerData.Completed then
        print(player, "completed puzzle!")
        playerData.Completed = true

        -- check if all players are completed --
        local allCompleted = true

        for userId, playerData in pairs (self._playerModeData) do
            if playerData.Active and not playerData.Completed then
                allCompleted = false
            end    
        end

        if allCompleted and engine.services.timer_service._time > 3 then
            engine.services.timer_service:setTimer(3)
        end

        return true
    end 
end

function PictureIt:_getSolution()
    --[[ gets solution and applies solution to portrait of map ]]--
    local solution = {}
    local portrait = self:_getPortrait(self._currentRound)

    for i = 1, #portrait.Tiles:GetChildren() do
        local tile = portrait.Tiles:FindFirstChild("Base" .. tostring(i))
        local color = self._colors[math.random(1, #self._colors)]
        tile.BrickColor = color
        table.insert(solution, table.find(self._colors, color))
    end

    return solution
end

function PictureIt:_getPortrait(roundNum)
    local roundToNum = {1, 1, 2, 2, 3, 3}

    return self._map._model.Portraits["Portrait_" .. tostring(roundToNum[roundNum])]
end

function PictureIt:_createStation(player, position)
    local station = engine.classes.station.new(player, self._colors)
    station:addToWorld(self:_getStationCF(position), self._map)
    station:hideTileSet()
    station:showTileSet(1)
    self._stations[player.UserId] = station
end

function PictureIt:_getStationCF(position)
    local originCF = game.ServerStorage.Models.StationTemplate:GetPivot()
    local x, z = 0, 0
    local offset = 60

    x = offset * ((position - 1) % 4)
    z = offset * math.floor((position - 1) / 4)

    return originCF * CFrame.new(x, 0, z)
end

function PictureIt:_onTileClickDetectorActivated(player, tile)
    local station = self._stations[player.UserId]
    
    if tile and station then
        station:onTileClicked(tile)
    end
end

return PictureIt