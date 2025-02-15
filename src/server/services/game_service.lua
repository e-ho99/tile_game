GameService = {}
GameService.__index = GameService

local sharedEvents = game.ReplicatedStorage.shared.Events
local gameEvents = sharedEvents.GameEvents

function GameService:init(e)
    engine = e
end

function GameService.new()
    local self = setmetatable({}, GameService)
    self._status = "Locked" -- {"Locked" -> "Intermission" -> "Selection" -> "Loading" -> 
                            -- "Countdown" -> "Playing" -> "Postgame"}
    
    self._mode = nil -- mode object
    self._map = nil -- map object
    self._participatingPlayers = {} -- list of user id
    self._movement = {["WalkSpeed"] = 21, ["JumpPower"] = 60}
    self._rewardsTable = {70, 55, 40, 25} 
    self._minimumPlayers = 1
    self._intermissionTime = 15

    self:_initEvents()
    print("Created Game Service")
    return self
end

function GameService:_initEvents()
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            local h = character.Humanoid
            
            if self._mode then
                self._mode:setMovement(player)
            else
                h.WalkSpeed = self._movement.WalkSpeed
                h.JumpPower = self._movement.JumpPower
            end
        end)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        if self._mode then
            self._mode:clearPlayerData(player.UserId)
        end

        for i, userId in pairs (self._participatingPlayers) do
            if userId == player.UserId then
                table.remove(self._participatingPlayers, i)
                gameEvents.ParticipatingPlayerRemoved:FireAllClients(player.UserId)

                print("Removed", player, "from participating players for leaving")
            end
        end
    end)

    gameEvents.GetMap.OnServerInvoke = function()
        if self._map then
            return self._map._name, self._map._model
        else
            return "", nil
        end
    end

    gameEvents.GetMode.OnServerInvoke = function()
        if self._mode then
            return self._mode._name
        else
            return ""
        end
    end

    sharedEvents.GetStatus.OnServerInvoke = function()
        return self._status
    end
end

function GameService:activate()
    print("Activating game!")
    self:toIntermission()
end

function GameService:deactivate()
    print("Deactivating game!")
    self._status = "Locked"

    -- end game modes
end

function GameService:clear()
    self._mode:respawnPlayers()
    self._map:Destroy()
    self._mode:Destroy()
    self._participatingPlayers = {}

    self._map, self._mode = nil, nil
    gameEvents.SetMap:FireAllClients("", nil)
    gameEvents.SetMode:FireAllClients("")
    gameEvents.ClearGame:FireAllClients()

    print("Cleaned up game service flow")
end

function GameService:selectMap()
    local mapName = engine.services.map_service:selectMap()
    mapName = mapName:gsub(" ", "_"):lower()
    local map = engine.maps[mapName]
    self._map = map.new()
    
    print("Selected map:", mapName)
end

function GameService:selectMode(map)
    local modeName = engine.services.map_service:selectMode(map)
    modeName = modeName:gsub(" ", "_"):lower()
    local mode = engine.modes[modeName]
    self._mode = mode.new(map, self._participatingPlayers)

    gameEvents.SetMode:FireAllClients(modeName)
    print("Selected mode:", modeName)
end

function GameService:updateParticipatingPlayers()
    -- TODO: if afk feature installed, need to expand logic
    local players = {}

    for _, player in pairs (game.Players:GetPlayers()) do
        table.insert(players, player.UserId)

        if player.Character == nil or player.Character.Humanoid.Health <= 0 then
            player:LoadCharacter()
        end
    end

    self._participatingPlayers = players
end

function GameService:getPlayerList()
    -- returns player obj list from self._participatingPlayers
    local players = {}

    for _, userId in pairs (self._participatingPlayers) do
        table.insert(players, game.Players:GetPlayerByUserId(userId))
    end

    return players
end

--[[ Status Setters ]]--
function GameService:toIntermission()
    if self._status ~= "Intermission" then
        self._status = "Intermission"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
        engine.services.timer_service:enable(self._intermissionTime)
    end
end

function GameService:toGameSelect()
    if self._status ~= "Selection" then
        self._status = "Selection"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, "Intermission")
        self:updateParticipatingPlayers()
        self:selectMap()
        self:selectMode(self._map)
        self:toLoading()
    end
end

function GameService:toLoading()
    if self._status ~= "Loading" then
        math.randomseed(tick()) -- resetting random seed
        self._status = "Loading"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, "Intermission")
        self:_fadeIn()
        task.wait(1)
        self._map:loadMap()
        self._mode:initMapEvents()
        self._mode:initPlayerEvents(self:getPlayerList())
        gameEvents.SendPlayers:FireAllClients(self._participatingPlayers) -- send players to ui layer
        task.wait(1.5)
        local playerList = self:getPlayerList()
        self._map:spawnPlayers(playerList, "random")
        self._mode:freezePlayers(playerList)
        self._mode:initToolHandler()
        self:toCountdown()
    end
end

function GameService:toCountdown()
    if self._status ~= "Countdown" then
        -- TODO: incorporate game description ui with countdown, 
        -- extend time and return cam to player at 5s remaining

        self._status = "Countdown"   
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, self._mode._name)
        engine.services.timer_service:enable(13)
        self:_gameDescriptionEffect()
    end
end

function GameService:toPlaying()
    if self._status ~= "Playing" then
        self._status = "Playing"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, self._mode._name)
        self._mode:startRound()
    end
end

function GameService:toPostgame()
    if self._status ~= "Postgame" then
        self._status = "Postgame"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, "Intermission")
        local winners, winnersString = self._mode:getWinners()
        self:_giveRewards(winners)
        self:clear()
        
        -- sending results to client --
        for _, player in pairs (game.Players:GetPlayers()) do
            sharedEvents.GameEvents.SendWinners:FireClient(player, winners.Players, winners.Ordered, winners.Rewards[player.UserId])
        end
        
        self:toIntermission()
    end
end

--[[ Timer Events ]]--
function GameService:timerTick(dt)
    -- fires every time timer is updated (1s) -- 
    if self._status == "Playing" then
        self._mode:onGameTick(dt)    
    end

    --print("Timer tick")
end

function GameService:timerComplete()
    -- check current status, move to next flow/logic -- 
    if self._status == "Intermission" then
        self:toGameSelect()
    elseif self._status == "Countdown" then
        self:toPlaying()
    elseif self._status == "Playing" then
        local finalRoundDone = self._mode:roundComplete()
        
        if finalRoundDone then
            self:toPostgame()
        end
    end
end

function GameService:_gameDescriptionEffect()
    self:_showGameDescription()
    task.wait(1)
    self:_fadeOut()
    task.wait(7)
    self:_fadeIn()
    task.wait(1)
    self:_hideGameDescription()
    task.wait(1)
    self:_fadeOut()
end

function GameService:_showGameDescription()
    --[[ Shows Game Description UI/Camera effects before game begins ]]--
    -- TODO: camera work
    for _, player in pairs (self:getPlayerList()) do
        sharedEvents.GameEvents.ShowGameDescription:FireClient(player, self._map._name, self._mode._name, self._mode._description)
    end
end

function GameService:_hideGameDescription()
    -- [[ Hides Game Description UI/Returns camera to player ]]--
    -- TODO: return camera to player
    sharedEvents.GameEvents.HideGameDescription:FireAllClients()
end

function GameService:_fadeIn()
    for _, player in pairs (self:getPlayerList()) do
        sharedEvents.UIEvents.FadeIn:FireClient(player, 1)
    end
end

function GameService:_fadeOut()
    for _, player in pairs (self:getPlayerList()) do
        sharedEvents.UIEvents.FadeOut:FireClient(player, 1)
    end
end

function GameService:_giveRewards(winners)
    winners.Rewards = {} -- storing player rewards here

    if self._mode.giveRewards then
        self._mode:giveRewards(winners) -- case for custom rewards for mode
    else
        if not winners.Order then -- ordered winners should have placements of ALL participants
            for _, userId in pairs (self._participatingPlayers) do
                local dataHandler = engine.services.data_service:getHandler(userId, "PlayerData")

                dataHandler:incrementCoins(25)
                dataHandler:incrementExperience(50)

                winners.Rewards[userId] = {}
                table.insert(winners.Rewards[userId], {Description = "Played a Game", Type = "Coins", Amount = 25})
            end
        end

        for placement, userId in pairs (winners.Players) do
            local dataHandler = engine.services.data_service:getHandler(userId, "PlayerData")
            local coinsAwarded = 0
    
            if winners.Ordered then
                coinsAwarded = self._rewardsTable[math.clamp(placement, 1, 4)] -- give 1st, 2nd, 3rd better rewards and all others 4th place reward
            else
                coinsAwarded = self._rewardsTable[2] -- give everyone second place money for non-ordered modes
            end
            
            local coinsAwarded = self._rewardsTable[placement]
            local expAwarded = 50
    
            dataHandler:incrementCoins(coinsAwarded)
            dataHandler:incrementExperience(expAwarded)
            
            if not winners.Rewards[userId] then
                winners.Rewards[userId] = {}
            end

            if winners.Ordered then
                local ordinals = {"st", "nd", "rd"}
                local desc = (tostring(placement) .. (ordinals[placement] or "th"))
                
                table.insert(winners.Rewards[userId], {Description = desc, Type = "Coins", Amount = coinsAwarded})
            else
                table.insert(winners.Rewards[userId], {Description = "Win Bonus", Type = "Coins", Amount = coinsAwarded})
            end
        end
    end
end

return GameService