Tool = {}
Tool.__index = Tool

local UserInputService = game:GetService("UserInputService")

function Tool:init(e)
    engine = e
end

function Tool.new(tool) 
    local self = setmetatable({}, Tool)
    self._tool = tool
    self._selectionBox = Instance.new("SelectionBox", game.Players.LocalPlayer.PlayerGui)
    self._equipped = false
    self._events = {}
    
    self:_initActionEvents()

    return self
end

function Tool:Destroy()
    for _, e in pairs (self._events) do
        e:Disconnect()
        self._tool:Destroy()
    end
end

function Tool:_initActionEvents()
    UserInputService.InputBegan:Connect(function(input, gameprocessed)
        if self._equipped and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local tile = self:_getTileFromPart(game.Players.LocalPlayer:GetMouse().Target)
            
            if tile then
                self:_onActivated(tile)
                --print("tile clicked")
            end
        end
    end)

    UserInputService.TouchTapInWorld:Connect(function(pos, processedUI)
        if self._equipped then
            local tile = self:_getTileFromPosition(pos)
        end
    end)

    self._tool.Equipped:Connect(function()
        self._equipped = true
    end)

    self._tool.Unequipped:Connect(function()
        self._equipped = false
    end)
end

function Tool:_getTileFromPart(part)
    local tile = part:FindFirstAncestor("Tile")

    if tile then
        return tile
    end
end

function Tool:_getTileFromPosition(pos)

end

function Tool:_initMouseHover()
    local mouse = game.Players.LocalPlayer:GetMouse()

    local e = game:GetService("RunService").RenderStepped:Connect(function()
        if self._equipped and mouse.Target then
            local tile = mouse.Target:FindFirstAncestor("Tile")

            if tile and self._hover ~= tile and self:_canHover(tile) then
                self._hover = tile
                self:_onTileHover(tile)
            elseif (self._hover and not tile) or (tile and not self:_canHover(tile)) then
                self._hover = nil
                self:_onTileLeftHover()
            end
        end
    end)

    table.insert(self._events, e)
end

function Tool:_canHover(tile)
    -- overwritten to add logic for tiles that can be hovered (ex: within range) --

    return true
end

function Tool:_onTileHover(tile)
    -- overwrriten by specific tool --
end

function Tool:_onTileLeftHover()
    -- overwrriten by specific tool --
end

function Tool:_onActivated(tile)
    print("client clicked with tool")
end

return Tool