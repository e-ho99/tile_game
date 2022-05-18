PlayerDataHandler = {}
PlayerDataHandler.__index = PlayerDataHandler

local DataStore2 = require(game.ServerScriptService.DataStore2)

function PlayerDataHandler:init(e)
    engine = e
end

function PlayerDataHandler.new(player)
    local self = setmetatable({}, PlayerDataHandler)
    self._player = player
    self._datastores = {
        Coins = DataStore2("Coins", self._player),
        Gems = DataStore2("Gems", self._player),
        Experience = DataStore2("Experience", self._player),
        Level = DataStore2("Level", self._player),
    }
    self._defaultValues = {
        Coins = 100,
        Gems = 25,
        Level = 1,
        Experience = 0
    }
    self._events = {}

    self:_initData()

    print("Created Player Data Handler For", player)
    return self
end

function PlayerDataHandler:_initData()
    for dataType, datastore in pairs (self._datastores) do
        local e = game.ReplicatedStorage.shared.Events.DataEvents:FindFirstChild(dataType .. "Updated")

        datastore:OnUpdate(function(value) 
            if e then
                e:FireClient(self._player, value)
            else
                warn("Could not locate", dataType .. "Updated")
            end
        end)

        local value = datastore:Get(self._defaultValues[dataType]) -- updating client ui
        e:FireClient(self._player, value)
    end
end

function PlayerDataHandler:incrementCoins(amount)
    self._datastores.Coins:Update(function(oldValue)
        return math.clamp(oldValue + amount, 0, math.huge)
    end)
end

function PlayerDataHandler:incrementExperience(amount)
    self._datastores.Experience:Update(function(oldValue)
        return math.clamp(oldValue + amount, 0, math.huge)
    end)
end

function PlayerDataHandler:Destroy()
    print("Destroyed data handler", self._player)
end

return PlayerDataHandler