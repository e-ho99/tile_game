GameService = {}
GameService.__index = GameService

local sharedEvents = game.ReplicatedStorage.shared.Events

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

    self._minimumPlayers = 1

    self:initEvents()
    print("Created Game Service")
    return self
end

function GameService:initEvents()
    game.Players.PlayerRemoving:Connect(function(player)
        if self._mode then
            self._mode:clearPlayerData(player)
        end

        for i, p in pairs (self._participatingPlayers) do
            if p == player then
                table.remove(self._participatingPlayer, i)
            end
        end
    end)

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

    print("Cleaned up game service flow")
end

function GameService:selectMap()
    local mapName = engine.services.map_service:selectMap()
    local map = engine.maps[mapName]
    self._map = map.new()

    print("Selected map:", mapName)
end

function GameService:selectMode(map)
    local modeName = engine.services.map_service:selectMode(map)
    modeName = modeName:gsub(" ", "_"):lower()
    local mode = engine.modes[modeName]
    self._mode = mode.new(map, game.Players:GetPlayers())

    print("Selected mode:", modeName)
end

function GameService:updateParticipatingPlayers()
    -- TODO: if afk feature installed, need to expand logic
    self._participatingPlayers = game.Players:GetPlayers()
end

--[[ Status Setters ]]--
function GameService:toIntermission()
    self._status = "Intermission"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    engine.services.timer_service:enable(10)
end

function GameService:toGameSelect()
    self._status = "Selection"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    self:selectMap()
    self:selectMode(self._map)
    self:toLoading()
end

function GameService:toLoading()
    self._status = "Loading"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    self:updateParticipatingPlayers()
    self._map:loadMap()
    self._mode:initMapEvents()
    self._mode:initPlayerEvents(self._participatingPlayers)
    self._map:spawnPlayers(self._participatingPlayers, "random")
    self._mode:freezePlayers(self._participatingPlayers)
    self:toCountdown()
end

function GameService:toCountdown()
    self._status = "Countdown"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    engine.services.timer_service:enable(10)
end

function GameService:toPlaying()
    self._status = "Playing"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    self._mode:startRound()
end


function GameService:toPostgame()
    self._status = "Postgame"
    sharedEvents.TimerEvents.SetStatus:FireAllClients(self._status)
    local winners, winnersString = self._mode:getWinners()
    sharedEvents.GameEvents.SendWinners:FireAllClients(winnersString)
    self:clear()
    self:toIntermission()
    
    print("Winners:", winners)
end

--[[ Timer Events ]]--
function GameService:timerTick()
    -- fires every time timer is updated (1s) -- 
    print("Timer tick")
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

return GameService