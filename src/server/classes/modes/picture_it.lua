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
    self._modeData = {["Active"] = true, ["Alive"] = true, ["Completed"] = false, ["Station"] = nil}
    self._colors = {
        BrickColor.new("Storm blue"), BrickColor.new("Bright red"), BrickColor.new("Neon orange"),
        BrickColor.new("Shamrock"), BrickColor.new("Bright violet"), BrickColor.new("Bright yellow"), 
        BrickColor.new("Carnation pink"),
    }
    self._solution = {}
    self._stations = {}
    self._uiType = "survival"
    self._totalRounds = 6
    self._roundTime = 30
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
            self._playerModeData[player.UserId].Station = position
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

        if #self:_getActivePlayers() == 0 then
            engine.services.game_service:toPostgame()
        end

        events.GameEvents.ModeEvents.PlayerEliminated:FireAllClients(player.UserId)
    end
end

function PictureIt:roundComplete()
    self._solution = {}
    -- eliminate/clean up empty stations
end

function PictureIt:startRound()
    local roundToNum = {1, 1, 2, 2, 3, 3}
    self._currentRound = self._currentRound + 1
    
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
    
    engine.services.timer_service:enable(self._roundTime)
    self:thawPlayers(self:_getActivePlayers())

    for _, station in pairs (self._stations) do -- clear all tiles
        station:enable()
    end
end

function PictureIt:checkSolution(player, answer)
    local playerData = self._playerModeData[player.UserId]
    local incorrect = false

    for i = 1, #self._solution do
        if self._solution[i] ~= answer[i] then
            incorrect = true
        end
    end

    if not incorrect and playerData and not playerData.Completed then
        print(player, "completed puzzle!")
        playerData.Completed = true
    end 

    return playerData.Completed
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

    print("SOLUTION", solution)
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
    local offset = 40

    print(position)
    x = offset * ((position - 1) % 4)
    z = offset * math.min((position - 1) / 4)

    return originCF * CFrame.new(x, 0, z)
end

function PictureIt:_onTileClickDetectorActivated(player, tile)
    local station = self._stations[player.UserId]
    
    if tile and station then
        station:onTileClicked(tile)
    end
end

return PictureIt