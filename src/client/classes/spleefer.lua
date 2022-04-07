Spleefer = {}
Spleefer.__index = Spleefer

local ToolEvents = game.ReplicatedStorage.shared.Events.GameEvents.ToolEvents

function Spleefer:init(e)
    engine = e
    setmetatable(Spleefer, engine.classes.tool)
end

function Spleefer.new(tool)
    local self = setmetatable(engine.classes.tool.new(tool), Spleefer)
    self._range = 20
    self:_initMouseHover()

    print("Spleefer created")
    return self 
end

function Spleefer:_canHover(tile)
    local c = game.Players.LocalPlayer.Character

    if c then
        local xDiff = math.abs(tile.PrimaryPart.Position.X - c.HumanoidRootPart.Position.X)
        local zDiff = math.abs(tile.PrimaryPart.Position.Z - c.HumanoidRootPart.Position.Z)

        return xDiff <= self._range and zDiff <= self._range
    end
end

function Spleefer:_onTileHover(tile)
    self._tool.SelectionBox.Adornee = tile
end

function Spleefer:_onTileLeftHover()
    self._tool.SelectionBox.Adornee = nil
end

function Spleefer:_onActivated(tile)
    --print("Spleefer activated", tile)
    ToolEvents.InputOnTile:FireServer(tile)
end

return Spleefer