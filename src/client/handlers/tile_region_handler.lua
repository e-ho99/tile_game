TileRegionHandler = {}
TileRegionHandler.__index = TileRegionHandler

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents
local TileStates = {["isEntered"] = false}

function TileRegionHandler:init(e)
    engine = e
end

-- manages tile regions to calculate entering/leaving of tiles --
function TileRegionHandler.new(map) 
    local self = setmetatable({}, TileRegionHandler)
    self._map = map
    self._regions = {}
    self._enabled = false
    self._tiles = map.Tiles:GetChildren()
    self._tileStates = {}
    self._events = {}

    self:_initializeTiles()
    self:onEnterLoop()
    print("tile region handler created")
    return self
end

function TileRegionHandler:onEnterLoop()
    local mapChildren = self._map:GetDescendants()
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    
    print(overlapParams.FilterDescendantsInstances)
    local e = game:GetService("RunService").RenderStepped:Connect(function()
        if self._enabled then
            for _, tile in pairs (self._tiles) do
                local base = tile.PrimaryPart
                local parts = workspace:GetPartBoundsInBox(base.CFrame * CFrame.new(0, 100 + (base.Size.Y / 2), 0), Vector3.new(base.Size.X, 200, base.Size.Z), overlapParams)
                
                if #parts > 1 and not self._tileStates[tile].isEntered then -- on first entrance
                    print(parts)
                    self._tileStates[tile].isEntered = true
                    gameEvents.TileEvents.TileEntered:FireServer(tile)
                elseif #parts < 1 and self._tileStates[tile].isEntered then -- on first exit
                    self._tileStates[tile].isEntered = false
                    gameEvents.TileEvents.TileExited:FireServer(tile)
                end
            end
        end
    end)

    table.insert(self._events, e)
    -- LOOPED VERSION IN CASE RENDERSTEPPED IS TOO EXPENSIVE --
    -- while task.wait(.1) do
        -- if self._enabled then
        --     for _, tile in pairs (self._tiles) do
        --         local base = tile.PrimaryPart
        --         local parts = workspace:GetPartBoundsInBox(base.CFrame, Vector3.new(base.Size.X, 200, base.Size.Z), overlapParams)

        --         if parts and #parts > 1 then
        --             gameEvents.TileEvents.TileEntered:FireServer(tile)
        --         end
        --     end
        -- end
    -- end
end

function TileRegionHandler:enable()
    self._enabled = true
end

function TileRegionHandler:disable()
    self._enabled = false
    self:_initializeTiles()
end

function TileRegionHandler:Destroy()
    for _, event in pairs(self._events) do
        event:Disconnect()
    end

    return nil
end

function TileRegionHandler:_initializeTiles()
    self._tileStates = {} -- clearing out in case we make call again

    for _, tile in pairs (self._tiles) do
        -- initializing state of tile --
        local newState = {}

        for property, value in pairs(TileStates) do
            newState[property] = value    
        end

        self._tileStates[tile] = newState
        
        -- TODO: remove for release version
        --self:_showRegion(tile)
    end
end

function TileRegionHandler:_showRegion(tile)
    -- show bounds of tile for debugging purposes --
    local base = tile.PrimaryPart
    local halfX, halfZ = base.Size.X / 2, base.Size.Z / 2
    local minBounds = (base.CFrame * CFrame.new(halfX, -1 + (base.Size.Y / 2), halfZ)).Position
    local maxBounds = (base.CFrame * CFrame.new(-halfX, 199 + (base.Size.Y / 2), -halfZ)).Position
    local p1 = Instance.new("Part", tile)
    p1.Size = Vector3.new(1,1,1)
    p1.Anchored = true
    p1.CFrame = CFrame.new(minBounds)
    p1.BrickColor = BrickColor.new("Really red")
    p1.Name = "P1"
    local p2 = Instance.new("Part", tile)
    p2.Size = Vector3.new(1,1,1)
    p2.Anchored = true
    p2.CFrame = CFrame.new(maxBounds)
    p2.BrickColor = BrickColor.new("Really blue")
    p2.Name = "P2"
end

return TileRegionHandler