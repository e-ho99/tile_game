PlayerDataHandler = {}
PlayerDataHandler.__index = PlayerDataHandler

function PlayerDataHandler:init(e)
    engine = e
end

function PlayerDataHandler.new(player, datastore)
    local self = setmetatable({}, PlayerDataHandler)
    self._player = player
    self._playerDatastore = datastore
    self._events = {}
    self._folder = self:_initFolder()

    self:_initData()

    print("Created Player Data Handler For", player)
    return self
end

function PlayerDataHandler:save()
    local savedData = {}

    for _, valueObj in pairs (self._folder:GetChildren()) do
        savedData[valueObj.Name] = valueObj.Value
    end
    
    local success, error = pcall(function()
        self._playerDatastore:SetAsync("Player_" .. tostring(self._player.UserId), savedData)
    end)

    if success then
        print("Saved player data for", self._player)
    else
        print(error)
    end
end

function PlayerDataHandler:_initData()
    local data = self._playerDatastore:GetAsync("Player_" .. tostring(self._player.UserId))

    if data then
        for _, valObj in pairs (self._folder:GetChildren()) do
            valObj.Value = data[valObj.Name]
        end

        print("Initialized player data", self._player)
    end
end

function PlayerDataHandler:_initFolder()
    local folder = game.ServerStorage.PlayerData:Clone()
    folder.Parent = self._player 

    return folder
end

function PlayerDataHandler:Destroy()
    print("Destroyed data handler", self._player)
end

return PlayerDataHandler