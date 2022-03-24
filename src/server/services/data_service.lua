DataService = {}
DataService.__index = DataService

local DataStoreService = game:GetService("DataStoreService")

function DataService:init(e)
    engine = e
end

function DataService.new()
    local self = setmetatable({}, DataService)
    self._dataHandlers = {} -- stores dictionary of player obj mapped to their data handlers
    self._dataStores = {
        ["PlayerData"] = DataStoreService:GetDataStore("PlayerData_001")
    }
    self:_initEvents()
    print("Created Game Service")
    return self
end

function DataService:_initEvents()
    game.Players.PlayerAdded:Connect(function(player)
        self:_initData(player)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        self:_saveData(player)
        self:_removeData(player)
    end)
end

function DataService:_initData(player)
    local dataHandlers = {}
    dataHandlers.PlayerData = engine.handlers.player_data_handler.new(player, self._dataStores.PlayerData)

    self._dataHandlers[player] = dataHandlers

    print("Initialized data handlers for", player)
end

function DataService:_saveData(player, specific)
    if not specific then
        for _, dataHandler in pairs (self._dataHandlers[player]) do
            dataHandler:save()
        end
    end
end

function DataService:_removeData(player)  
    for _, handler in pairs (self._dataHandlers[player]) do
        handler:Destroy()
    end

    self._dataHandlers[player] = nil

    print("Removed data handlers for", player)
end

return DataService