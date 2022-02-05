Mode = {}
Mode.__index = Mode

function Mode:init(e)
    engine = e
end

function Mode.new(map, participatingPlayers)
    local self = setmetatable({}, Mode)
    self._name = ""
    self._map = map
    self._modeData = {["Active"] = true, ["Alive"] = true}
    self._roundTime = 60
    self._currentRound = 0
    self._roundTotal = 1
    self._hints = {}
    self._participatingPlayers = participatingPlayers
    self._playerModeData = self:getPlayerModeData(participatingPlayers)

    self:initPlayerEvents(participatingPlayers)
    return self
end

function Mode:initPlayerEvents(playerList)
    for _, player in pairs (playerList) do
        player.CharacterAdded:Connect(function()
            local gameStatus = engine.services.game_service._status

            if gameStatus == "Countdown" or gameStatus == "Loading" then
                self:freezePlayers({player})
            end
        end)
    end
end

function Mode:startRound()
    engine.services.timer_service:enable(self._roundTime)
    self._currentRound = self._currentRound + 1
    self:thawPlayers(self._participatingPlayers)
end

function Mode:roundComplete()
    return self._currentRound == self._roundTotal
end

function Mode:getPlayerModeData(participatingPlayers)
    -- overwritten with each mode as tracked data can vary; defaults to players who survive --
    local data = {}

    for _, player in pairs(participatingPlayers) do
        local modeData = {}

        for key, val in pairs (self._modeData) do
            modeData[key] = val
        end

        data[player] = modeData
    end

    print(participatingPlayers, "mode data", data)
    return data
end

function Mode:respawnPlayers()
    -- respawn players who need to; defaults to using "Active" key in player's mode data
    for player, modeData in pairs(self._playerModeData) do
        if player and modeData["Active"] then
            player:LoadCharacter()
        end
    end    
end

function Mode:getWinners()
    -- overwritten with each mode as tracked data can vary; defaults to players who survive --
    local winners = {["Players"] = {}, ["Ordered"] = false}

    for player, modeData in pairs(self._playerModeData) do
        if modeData["Alive"] then
            print(player)
            table.insert(winners.Players, player)
        end
    end

    return winners
end

function Mode:freezePlayers(playerList)
    for _, player in pairs(playerList) do
        if player then
            local c = player.Character or player.CharacterAdded:Wait()
            c.HumanoidRootPart.Anchored = true
        end
    end
end

function Mode:thawPlayers(playerList)
    for _, player in pairs(playerList) do
        if player then
            local c = player.Character
            c.HumanoidRootPart.Anchored = false
        end
    end
end

function Mode:Destroy()
    -- disconnect associated events -- 
end

return Mode