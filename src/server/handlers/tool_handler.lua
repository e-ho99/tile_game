ToolHandler = {}
ToolHandler.__index = ToolHandler

local toolEvents = game.ReplicatedStorage.shared.Events.GameEvents.ToolEvents

function ToolHandler:init(e)
    engine = e
end

function ToolHandler.new(tool, mode)
    local self = setmetatable({}, ToolHandler)
    self._baseTool = tool
    self._mode = mode
    self._participatingPlayers = mode._participatingPlayers
    self._tools = {}
    self._events = {}

    self:_initEvents()
    self:_createTools()
    print("Created Tool Handler")
    return self
end

function ToolHandler:_initEvents()
    local e = toolEvents.InputOnTile.OnServerEvent:Connect(function(player, tile)
         -- verify that player position within range of tile --
         local character = player.Character
  
         if character and tile and tile.PrimaryPart then
            local xDiff = math.abs(tile.PrimaryPart.Position.X - character.HumanoidRootPart.Position.X)
            local zDiff = math.abs(tile.PrimaryPart.Position.Z - character.HumanoidRootPart.Position.Z)

            if xDiff <= 20 and zDiff <= 20 then
                self._mode:_onTileInput(player, tile)
            end
         end
    end)

    table.insert(self._events, e)
end

function ToolHandler:_createTools()
    for _, userId in pairs (self._participatingPlayers) do
        local player = game.Players:GetPlayerByUserId(userId)

        if player then
            local tool = self._baseTool:Clone()
            self._tools[userId] = tool
            tool.Parent = player.Backpack
            toolEvents.SendTool:FireClient(player, tool)
        else 
            warn(player, "nil")
        end
    end
end

function ToolHandler:Destroy()
    for _, e in pairs (self._events) do
        e:Disconnect()
        self._mode = nil
    end
end

return ToolHandler