FallingTiles = {}
FallingTiles.__index = FallingTiles

local modeEvents = game.ReplicatedStorage.shared.Events.GameEvents.ModeEvents
local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents

function FallingTiles:init(e)
    engine = e
    setmetatable(FallingTiles, engine.interfaces.gui)
end

function FallingTiles.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), FallingTiles)
    self._playerToElement = {}
    self._elementsStorage = self._gui.Elements
    self._mainframe = self._gui.Holder
    self._leftFrame, self._rightFrame = self._mainframe.LFrame, self._mainframe.RFrame
    self._playerContainers = {self._leftFrame.TopList, self._rightFrame.TopList, 
        self._leftFrame.BottomList, self._rightFrame.BottomList}
        
    self:_clear()
    self:_initEvents()

    return self
end

function FallingTiles:_addPlayers(playerlist)
    for index, player in pairs (playerlist) do
        local parentFrame = self._playerContainers[math.ceil(index / 3)]
        local newIcon = self._elementsStorage[parentFrame.Parent.Name .. "Player"]:Clone()
        self._playerToElement[player] = newIcon
        newIcon.Holder.PlayerImage.Image = game.Players:GetUserThumbnailAsync(player.UserId, 
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        newIcon.Visible = true
        newIcon.Parent = parentFrame
        
        print(index, player, parentFrame, parentFrame.Parent)
    end
end

function FallingTiles:_clear()
    for _, frame in pairs ({self._leftFrame, self._rightFrame}) do
        for _, descendant in pairs (frame:GetDescendants()) do
            if descendant:IsA("ImageLabel") then
                descendant:Destroy()
            end
        end
    end
end

function FallingTiles:_initEvents()
    -- self:_addPlayers({game.Players.LocalPlayer, game.Players.LocalPlayer, game.Players.LocalPlayer, 
    --                 game.Players.LocalPlayer, game.Players.LocalPlayer, game.Players.LocalPlayer,
    --                 game.Players.LocalPlayer, game.Players.LocalPlayer, game.Players.LocalPlayer,
    --                 game.Players.LocalPlayer, game.Players.LocalPlayer, game.Players.LocalPlayer})
    local e = gameEvents.SendPlayers.OnClientEvent:Connect(function(playerlist)
        self:_addPlayers(playerlist)
    end)

    local elim = modeEvents.PlayerEliminated.OnClientEvent:Connect(function(player)
        local icon = self._playerToElement[player]

        if icon then
            icon.Holder.ImageColor3 = Color3.fromRGB(116, 116, 116)
            icon.Holder.PlayerImage.ImageColor3 = Color3.fromRGB(107, 107, 107)
        end
    end)

    table.insert(self._events, e)
    table.insert(self._events, elim)
end

return FallingTiles