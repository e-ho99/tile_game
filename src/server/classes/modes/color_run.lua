ColorRun = {}
ColorRun.__index = ColorRun

local TweenService = game:GetService("TweenService")
local timerEvents = game.ReplicatedStorage.shared.Events.TimerEvents
local events = game.ReplicatedStorage.shared.Events

function ColorRun:init(e)
    engine = e
    setmetatable(ColorRun, engine.classes.mode)
end

function ColorRun.new(map, participatingPlayers)
    local self =  setmetatable(engine.classes.mode.new(map, participatingPlayers), ColorRun)
    self._name = "Color Run"
    self._modeData = {["Active"] = true, ["Alive"] = true, ["Team"] = BrickColor.new("Bright blue")}
    self._score = {
        ["Bright blue"] = 0,
        ["Bright red"] = 0,
        ["Bright yellow"] = 0,
        ["Bright green"] = 0
    }
    self._playerModeData = self:_getPlayerModeData(participatingPlayers)
    self._tileOwnership = {}
    self._roundTime = 60
    self._tiles = {}
    self._elapsedTime = 0

    return self
end

function ColorRun:initMapEvents()
    self._tiles = self._map._model.Tiles:GetChildren()

    for _, player in pairs(self._participatingPlayers) do
        if player then
            events.GameEvents.MapEvents.InitTileRegions:FireClient(player)
        end
    end

    self:_initTileEnteredEvent()
    self:_initTileExitedEvent()
end

function ColorRun:initPlayerEvents(playerList)
    for i, player in pairs (playerList) do
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
        
        self:_assignTeam(player, i)
        table.insert(self._events, event)
    end
end

function ColorRun:_assignTeam(player, index)
    local team = BrickColor.new("Bright blue")

    if index % 4 == 0 then
        team = BrickColor.new("Bright green")
    elseif index % 3 == 0 then
        team = BrickColor.new("Bright yellow")
    elseif index % 2 == 0 then
        team = BrickColor.new("Bright red")
    end

    self._playerModeData[player].Team = team
end

function ColorRun:onGameTick()
    
end

function ColorRun:_initTileOwnership(map)
    for _, tile in pairs (map.Tiles:GetChildren()) do
        self._tileOwnership[tile] = nil
    end
end

function ColorRun:_onTileEntered(player, tile)
    local index = table.find(self._tiles, tile)

    if index then
        local color = self._playerModeData[player].Team
        local currentColor = self._tileOwnership[tile]

        if not currentColor or currentColor ~= color then
            print("Claim tile", self._score)
            self._tileOwnership[tile] = color
            self._score[color.Name] = self._score[color.Name] + 1 

            if currentColor then
                self._score[currentColor.Name] = self._score[currentColor.Name] - 1
            end  

            for _, child in pairs (tile:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("UnionOperation") then
                    child.BrickColor = color
                end
            end
        else
            print("Already claimed")
        end
    end
end

return ColorRun