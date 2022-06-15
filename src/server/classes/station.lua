Station = {}
Station.__index = Station

local UserInputService = game:GetService("UserInputService")

function Station:init(e)
    engine = e
end

function Station.new(player, colorChoices)
    local self = setmetatable({}, Station)
    self._owner = player
    self._colors = colorChoices
    self._station = game.ServerStorage.Models.StationTemplate:Clone()
    self._enabled = false
    self._currentStatus = {0, 0, 0, 0}
    self._events = {}

    return self
end

function Station:enable()
    self._enabled = true
end

function Station:disable()
    self._enabled = false
end

function Station:clear()
    self._currentStatus = {}

    for i = 1, 25 do
        table.insert(self._currentStatus, 0)
    end

    self._station.Outline.Material = Enum.Material.SmoothPlastic
    self._station.Outline.BrickColor = BrickColor.new("Smoky grey")
end

function Station:Destroy()
    self._station:Destroy()
end

function Station:spawnPlayer()
    local c = self._owner.Character

    if c then
        c:PivotTo(self._station.Main.CFrame * CFrame.new(0, 10, 0))
    end
end

function Station:addToWorld(cf, map)
    self._station:PivotTo(cf)
    self._station.Parent = map._model.Stations
    self:_initClientHandler()
end

function Station:onTileClicked(tile)
    if self._enabled and self._owner.Character and self._owner.Character.Humanoid.Health > 0 then
        local index = tonumber(tile.Name)
        local newIndex = self._currentStatus[index] + 1

        if newIndex > #self._colors then -- resetting to start
            newIndex = 1
        end

        self._currentStatus[index] = newIndex
        tile.BrickColor = self._colors[newIndex] -- apply new color
        local success = engine.services.game_service._mode:checkSolution(self._owner, self._currentStatus)

        if success then
            self:_puzzleSolved()
        end
    end
end

function Station:showTileSet(num)
    local tileset = self._station.TileSets:FindFirstChild(tostring(num))
    tileset:PivotTo(self._station.Main.CFrame)

    for _, p in pairs (tileset:GetChildren()) do
        p.Transparency = 0
    end
end

function Station:hideTileSet(num)
    if not num then 
        for i = 1, 3 do
            self:hideTileSet(i) -- hide all recursively
        end
    else
        local tileset = self._station.TileSets:FindFirstChild(tostring(num))
        tileset:PivotTo(self._station.Main.CFrame * CFrame.new(0, -500, 0))
        
        for _, p in pairs (tileset:GetChildren()) do
            p.Transparency = 1
            p.BrickColor = BrickColor.new("Light grey metallic")
        end
    end
end

function Station:_puzzleSolved()
    self:disable()
    self._station.Outline.Color = Color3.fromRGB(68, 188, 78)
    self._station.Outline.Material = Enum.Material.Neon
end

function Station:_initClientHandler()
    local e = game.ReplicatedStorage.shared.Events.GameEvents.ModeEvents.InitModeHandler

    e:FireClient(self._owner, "picture_it", {model = self._station})
end

return Station