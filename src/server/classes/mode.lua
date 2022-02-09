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
    -- TODO: create RoundHandler obj to store these values
    self._roundTime = 60
    self._currentRound = 0
    self._roundTotal = 1
    self._enabled = false
    self._hints = {}
    self._participatingPlayers = participatingPlayers
    self._playerModeData = self:getPlayerModeData(participatingPlayers)
    self._events = {}

    self:initCountdownEvents(participatingPlayers)
    return self
end

function Mode:clearPlayerData(player)
    self._playerModeData[player] = nil
end

function Mode:eliminate(player)
    -- handles elimination of player; defaults to elimination on first death --
    local data = self._playerModeData[player]

    if data and data["Active"] then
        data["Alive"] = false
        data["Active"] = false

        print("Eliminated", player)
    end
end

function Mode:startRound()
    self._enabled = true
    engine.services.timer_service:enable(self._roundTime)
    self._currentRound = self._currentRound + 1
    self:thawPlayers(self._participatingPlayers)
end

function Mode:roundComplete()
    -- TODO: for modes with multiple rounds, reload map
    self._enabled = false

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
    local winnersString = ""
    for player, modeData in pairs(self._playerModeData) do
        if modeData["Alive"] then
            print(player)
            if winnersString == "" then
                winnersString = player.Name
            else
                winnersString = winnersString .. player.Name
            end
            
            table.insert(winners.Players, player)
        end
    end

    return winners, winnersString
end

function Mode:freezePlayers(playerList)
    for _, player in pairs(playerList) do
        if player then
            local c = player.Character or player.CharacterAdded:Wait()
            c.Humanoid.WalkSpeed = 0
            c.Humanoid.JumpPower = 0
        end
    end
end

function Mode:thawPlayers(playerList)
    for _, player in pairs(playerList) do
        if player then
            local c = player.Character
            c.Humanoid.WalkSpeed = self._walkSpeed or 16
            c.Humanoid.JumpPower = self._jumpPower or 50
        end
    end
end

function Mode:Destroy()
    for _, e in pairs (self._events) do
        e:Disconnect()
    end
end

--[[ EVENTS ]]--
function Mode:initCountdownEvents(playerList)
    for _, player in pairs (playerList) do
        local event = player.CharacterAdded:Connect(function()
            local gameStatus = engine.services.game_service._status

            if gameStatus == "Countdown" or gameStatus == "Loading" then
                self:freezePlayers({player})
            end
        end)

        table.insert(self._events, event)
    end
end

function Mode:initPlayerEvents(playerList)
    for _, player in pairs (playerList) do
        local c = player.Character

        if c then
            c.Humanoid.Died:Connect(function()
                self:eliminate(player)
            end)
        end

        local event = player.CharacterAdded:Connect(function(char)
            local character = char
            character.Humanoid.Died:Connect(function()
                self:eliminate(player)
            end)
        end)

        table.insert(self._events, event)
    end
end

function Mode:_countActivePlayers()
    local count = 0

    for _, data in pairs (self._playerModeData) do
        if data["Active"] then
            count = count + 1
        end
    end

    return count
end

return Mode