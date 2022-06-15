Mode = {}
Mode.__index = Mode

local events = game.ReplicatedStorage.shared.Events
local modeEvents = events.GameEvents.ModeEvents

function Mode:init(e)
    engine = e
end

function Mode.new(map, participatingPlayers)
    local self = setmetatable({}, Mode)
    self._name = ""
    self._uiType = nil
    self._map = map
    self._modeData = {["Active"] = true, ["Alive"] = true}
    self._walkSpeed = 21
    self._jumpPower = 60
    -- TODO: create RoundHandler obj to store these values
    self._roundTime = 60
    self._currentRound = 0
    self._roundTotal = 1
    self._enabled = false
    self._tool = nil
    self._hints = {}
    self._participatingPlayers = participatingPlayers
    self._playerModeData = self:_getPlayerModeData(participatingPlayers)
    self._events = {}

    return self
end

function Mode:setMovement(player)
    local character = player.Character 

    if character then
        local h = character.Humanoid
        h.WalkSpeed = self._walkSpeed
        h.JumpPower = self._jumpPower
    end
end

function Mode:clearPlayerData(userId)
    self._playerModeData[userId] = nil
end

function Mode:startRound()
    self._enabled = true

    for userId, data in pairs(self._playerModeData) do
        modeEvents.ModeEnabled:FireClient(game.Players:GetPlayerByUserId(userId))
    end

    engine.services.timer_service:enable(self._roundTime)
    self._currentRound = self._currentRound + 1
    self:thawPlayers(engine.services.game_service:getPlayerList())
end

function Mode:roundComplete()
    -- TODO: for modes with multiple rounds, reload map
    self._enabled = false

    return self._currentRound == self._roundTotal
end

function Mode:Destroy()
    for _, e in pairs (self._events) do
        e:Disconnect()
    end

    if self._toolHandler then
        self._toolHandler:Destroy()
    end

    for userId, data in pairs (self._playerModeData) do
        modeEvents.RemoveUI:FireClient(game.Players:GetPlayerByUserId(userId), self._uiType or self._name:gsub(" ", "_"):lower())
    end
end

--[[ GETTERS ]]--
function Mode:getWinners()
    -- overwritten with each mode as tracked data can vary; defaults to players who survive --
    local winners = {["Players"] = {}, ["Ordered"] = false}
    local winnersString = ""
    
    for userId, modeData in pairs(self._playerModeData) do
        local player = game.Players:GetPlayerByUserId(userId)

        if modeData["Alive"] and player then
            if winnersString == "" then
                winnersString = player.Name
            else
                winnersString = winnersString .. player.Name
            end
            
            table.insert(winners.Players, player.userId)
        end
    end

    return winners, winnersString
end

function Mode:_getPlayerModeData(participatingPlayers)
    -- overwritten with each mode as tracked data can vary; defaults to players who survive --
    local data = {}

    for _, userId in pairs(participatingPlayers) do
        local modeData = {}

        for key, val in pairs (self._modeData) do
            modeData[key] = val
        end

        data[userId] = modeData
    end

    return data
end

--[[ EVENTS ]]--
function Mode:eliminate(player)
    -- overwritten and fired when player is eliminated from game -- 
end

function Mode:onGameTick(dt)
    -- fires on every game tick; depends on game_service timerTick event --
end

function Mode:initPlayerEvents(playerList)
    for _, player in pairs (playerList) do
        if player then
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
        end
    end
end

function Mode:initToolHandler()
    if self._tool then
        self._toolHandler = engine.handlers.tool_handler.new(self._tool, self)
    end
end

function Mode:initMapEvents()
    -- initializes events dependent on map obj/model --
end

--[[ MISC ]]--
function Mode:respawnPlayers()
    -- respawn players who need to; defaults to using "Active" key in player's mode data
    for userId, modeData in pairs(self._playerModeData) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player and modeData["Active"] then
            player:LoadCharacter()
        end
    end    
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
        if player and player.Character then
            player.Character.Humanoid.WalkSpeed = self._walkSpeed or 16
            player.Character.Humanoid.JumpPower = self._jumpPower or 50
        end
    end
end

function Mode:_getActivePlayers()
    local players = {}

    for userId, data in pairs (self._playerModeData) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player and data["Active"] then
            table.insert(players, player)
        end
    end

    return players
end

--[[ TILE EVENTS ]]--
function Mode:_initTileEnteredEvent()
    -- sets up tile entered event to be called from client/filters illogical requests --
    local entered = events.GameEvents.TileEvents.TileEntered.OnServerEvent:Connect(function(player, tile)
        if self._enabled then
            -- verify that player position within range of tile --
            local character = player.Character
            
            if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 
                and tile and tile.PrimaryPart then
                local distance = (character.HumanoidRootPart.Position - tile.PrimaryPart.Position).magnitude
                local yDifference = math.abs(character.HumanoidRootPart.Position.Y - tile.PrimaryPart.Position.Y)

                if distance < 20 or yDifference > 20 then
                    self:_onTileEntered(player, tile)
                end
            end
        end
    end)

    table.insert(self._events, entered)
end

function Mode:_initTileExitedEvent()
    -- sets up tile exited event to be called from client --
    local exited = events.GameEvents.TileEvents.TileExited.OnServerEvent:Connect(function(player, tile)
        local character = player.Character

        if character and tile then
            self:_onTileExited(player, tile)
        end
    end)

    table.insert(self._events, exited)
end

function Mode:_initTileClickDetectorActivated()
    -- sets up tile exited event to be called from client --
    local clicked = events.GameEvents.TileEvents.TileClickDetector.OnServerEvent:Connect(function(player, tile)
        self:_onTileClickDetectorActivated(player, tile)
    end)

    table.insert(self._events, clicked)
end

function Mode:_onTileClickDetectorActivated(player, tile)
    -- overwritten by game modes as what is done varies between modes -- 
end

function Mode:_onTileEntered(player, tile)
    -- overwritten by game modes as what is done varies between modes -- 
    -- print(player, "entered tile", tile)
end

function Mode:_onTileExited(player, tile)
    -- overwritten by game modes as what is done varies between modes -- 
    -- print(player, "exited tile", tile)
end

function Mode:_onTileInput(player, tile)
    -- overwritten by game modes as what is done varies between modes -- 
end

return Mode