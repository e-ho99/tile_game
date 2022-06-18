WinnersUI = {}
WinnersUI.__index = WinnersUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents

function WinnersUI:init(e)
    engine = e
    setmetatable(WinnersUI, engine.interfaces.gui)
end

function WinnersUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), WinnersUI)
    
    self._mainframe = self._gui.Winners
    self._templates = self._gui.Templates

    self:initEvents()
    return self
end

function WinnersUI:initEvents()
    local e = gameEvents.SendWinners.OnClientEvent:Connect(function(winners, ordered)
        if #winners == 0 then
            -- show no winners label
            
        else
            -- TODO: have ordered condition + 1st, 2nd, 3rd place icons
            for index, userid in pairs (winners) do
                local template = self._templates.WinnerPlayer:Clone()
                template.PlayerImage.Image = game.Players:GetUserThumbnailAsync(userid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                template.PlayerName.Text = game.Players:GetPlayerByUserId(userid).Name
                template.Parent = self._mainframe.Container
                template.Visible = true
            end
        end

        self._gui.Enabled = true
        task.wait(5)
        self._gui.Enabled = false

        for _, playerGrid in pairs (self._mainframe.Container:GetChildren()) do
            if playerGrid:IsA("GuiBase2d") then
                playerGrid:Destroy()
            end
        end
    end)

    table.insert(self._events, e)
end

return WinnersUI