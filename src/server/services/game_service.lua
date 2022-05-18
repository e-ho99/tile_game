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
    self._participatingPlayers = {} -- list of Player obj
    self._movement = {["WalkSpeed"] = 21, ["JumpPower"] = 60}
    self._rewardsTable = {70, 55, 40, 25} 
    self._minimumPlayers = 1
    self._intermissionTime = 10

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
        self._status = "Loading"
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, "Intermission")
        self._map:loadMap()
        self._mode:initMapEvents()
        self._mode:initPlayerEvents(self:getPlayerList())
        gameEvents.SendPlayers:FireAllClients(self._participatingPlayers)
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
        self._status = "Countdown"   
        sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status, self._mode._name)
        engine.services.timer_service:enable(5)
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
        sharedEvents.GameEvents.SendWinners:FireAllClients(winnersString)
        self:clear()
        self:toIntermission()
        
        print("Winners:", winners)
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

function GameService:_giveRewards(winners)
    for placement, userId in pairs (winners.Players) do
        local dataHandler = engine.services.data_service:getHandler(userId, "PlayerData")

        if winners.Ordered then
            placement = math.clamp(placement, 1, 4)
        else
            placement = 2
        end

        local coinsAwarded = self._rewardsTable[placement]
        local expAwarded = 100

        dataHandler:incrementCoins(coinsAwarded)
        dataHandler:incrementExperience(expAwarded)
    end
end

return GameService