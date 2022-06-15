PictureIt = {}
PictureIt.__index = PictureIt

local events = game.ReplicatedStorage.shared.Events
local modeEvents = events.GameEvents.ModeEvents

function PictureIt:init(e)
    engine = e
    setmetatable(PictureIt, engine.classes.map)
end

function PictureIt.new()
    local self =  setmetatable(engine.classes.map.new(), PictureIt)
    self._modes = {"Picture It"}
    self._mapTemplate = game.ServerStorage.Maps["Picture It"]
    self._name = "Picture It Arena"
    self._stations = {}
    
    return self
end

function PictureIt:loadMap()
    self._model = self._mapTemplate:Clone()
    self._model.Parent = workspace

    for i = 1, 3 do
        if i > 1 then
            self:hidePortrait(i)
        end
        
        self:clearPortrait(i)
    end

    for _, station in pairs (self._model.Stations:GetChildren()) do
        for _, tileSet in pairs (station.TileSets:GetChildren()) do

            if tileSet.Name == "1" then
                tileSet:PivotTo(station.Main.CFrame)

                for _, child in pairs (tileSet:GetChildren()) do
                    child.Transparency = true
                    child.CanCollide = true
                end
            else 
                tileSet:PivotTo(station.Main.CFrame * CFrame.new(0, -10, 0))

                for _, child in pairs (tileSet:GetChildren()) do
                    child.Transparency = false
                    child.CanCollide = false
                end
            end
        end
    end

    events.GameEvents.SetMap:FireAllClients(self._name, self._model)
end

function PictureIt:clearPortrait(stageNum)
    local portrait = self._model.Portraits["Portrait_" .. tostring(stageNum)]

    for _, tile in pairs (portrait.Tiles:GetChildren()) do
        tile.BrickColor = BrickColor.new("Light grey metallic")
    end
end

function PictureIt:hidePortrait(stageNum)
    local portrait = self._model.Portraits["Portrait_" .. tostring(stageNum)]

    for _, part in pairs (portrait:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("UnionOperation") then
            part.Transparency = 1
        end
    end
end

function PictureIt:showPortrait(stageNum)
    local portrait = self._model.Portraits["Portrait_" .. tostring(stageNum)]

    for _, part in pairs (portrait:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("UnionOperation") then
            part.Transparency = 0
        end
    end
end 

function PictureIt:spawnPlayers(playerList)
    for _, station in pairs (self._stations) do
        station:spawnPlayer()
    end
end

return PictureIt