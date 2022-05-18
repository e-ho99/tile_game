DataService = {}
DataService.__index = DataService

local DataStoreService = game:GetService("DataStoreService")
local DataStore2 = require(game.ServerScriptService.DataStore2)

function DataService:init(e)
    engine = e
end

function DataService.new()
    local self = setmetatable({}, DataService)
    self._dataHandlers = {} -- stores dictionary of player obj mapped to their data handlers
    self._dataStores = {
        ["PlayerData"] = DataStoreService:GetDataStore("PlayerData_001")
    }
    self._masterKey = "0001"
    self:_initDatastore()
    self:_initEvents()
    print("Created Game Service")
    return self
end

function DataService:getHandler(userId, handlerKey)
    return self._dataHandlers[userId][handlerKey]
end

function DataService:_initDatastore()
    DataStore2.Combine(self._masterKey, "Coins", "Experience", "Level", "Gems")
end

function DataService:_initEvents()
    game.Players.PlayerAdded:Connect(function(player)
        self:_initDataHandlers(player)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        local userId = player.userId
        self:_removeData(userId)
    end)
end

function DataService:_initDataHandlers(player)
    local dataHandlers = {}
    dataHandlers.PlayerData = engine.handlers.player_data_handler.new(player)

    self._dataHandlers[player.userId] = dataHandlers

    print("Initialized data handlers for", player)
end

function DataService:_removeData(userId)  
    for _, handler in pairs (self._dataHandlers[userId]) do
        handler:Destroy()
    end

    self._dataHandlers[userId] = nil

    print("Removed data handlers for", userId)
end

return DataService