Map = {}
Map.__index = Map

local events = game.ReplicatedStorage.shared.Events

function Map:init(e)
    engine = e
end

function Map.new()
    local self = setmetatable({}, Map)
    self._name = ""
    self._modes = {}
    self._mapTemplate = nil
    self._model = nil
    self._offsetCF = CFrame.new(0, 0, 0)

    return self
end

function Map:loadMap()
    self._model = self._mapTemplate:Clone()
    self._model.Parent = workspace

    events.GameEvents.SetMap:FireAllClients(self._name, self._model)
end

function Map:getLoadingCameraCF()
    return CFrame.new((self._model.Focus.CFrame * self._offsetCF).Position, self._model.Focus.CFrame.Position)
end

function Map:spawnPlayers(playerList, spawnType)
    local tiles = self._model.Tiles:GetChildren()

    if spawnType == "random" then
        for _, player in pairs(playerList) do
            if player then
                local character = player.Character or player.CharacterAdded:Wait()
                local num = math.random(1, #tiles)
                local selectedTile = tiles[num]

                character.HumanoidRootPart.CFrame = selectedTile.PrimaryPart.CFrame * CFrame.new(0, (
                    character:GetExtentsSize().Y / 2) + (selectedTile.PrimaryPart.Size.Y / 2), 0)

                table.remove(tiles, num)
            end
        end
    end
end

function Map:Destroy()
    self._model:Destroy()
end

return Map