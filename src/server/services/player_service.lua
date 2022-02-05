PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService:init(e)
    engine = e
end

function PlayerService.new()
    local self = setmetatable({}, PlayerService)
    self._playerData = {}
    
    self:initEvents()
    print("Created Player Service")
    return self
end

function PlayerService:initEvents()
    game.Players.PlayerAdded:Connect(function(player)
        print(player, "has joined")

        if #game.Players:GetPlayers() >= engine.services.game_service._minimumPlayers and
         engine.services.game_service._status == "Locked" then
            engine.services.game_service:activate()
        elseif #game.Players:GetPlayers() < engine.services.game_service._minimumPlayers and
         engine.services.game_service._status ~= "Locked" then
            engine.services.game_service:deactivate()
        end 
    end)
end

return PlayerService