WinnersUI = {}
WinnersUI.__index = WinnersUI

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents
local TweenService = game:GetService("TweenService")

function WinnersUI:init(e)
    engine = e
    setmetatable(WinnersUI, engine.interfaces.gui)
end

function WinnersUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), WinnersUI)
    
    self._mainframe = self._gui.Mainframe
    self._templates = self._gui.Templates
    self._winnersTitle = self._mainframe.WinnersTitle
    self._resultsTitle = self._mainframe.ScorecardTitle
    self._winnersContent = self._mainframe.Container
    self._resultsContent = self._mainframe.ScorecardContainer
    
    self._rewardIcons = {
        Coins = "rbxassetid://9178958834",
        Experience = "rbxassetid://9178959260",
        Gems = "rbxassetid://9178959260"
    }

    self:initEvents()
    return self
end

function WinnersUI:initEvents()
    local e = gameEvents.SendWinners.OnClientEvent:Connect(function(winners, ordered, rewards)
        self._winnersTitle.Position = UDim2.new(.5, 0, 0.06, 0)
        self._winnersContent.Position = UDim2.new(.5, 0, .202, 0)
        self._resultsTitle.Position = UDim2.new(-.5, 0, .06, 0)
        self._resultsContent.Position = UDim2.new(-.5, 0, .202, 0)

        --[[ Generate Winners Content ]]--
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

        --[[ Generate Results Content ]]--
        print("REWARDS", rewards)
        if rewards then
            for _, data in pairs (rewards) do
                local frame = self._templates.ScoreFrame:Clone()
                print(frame:GetChildren())
                frame.Description.Text = data.Description
                frame.CurrencyIcon.Image = self._rewardIcons[data.Type]
                frame.CurrencyIcon.CurrencyAmount.Text = tostring(data.Amount)
                self:_adjustFrame(frame)
                frame.Parent = self._resultsContent
                frame.Visible = true
            end
        else
            -- TODO: case when there are no rewards
        end

        self._gui.Enabled = true
        task.wait(4)
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local titleOut = TweenService:Create(self._winnersTitle, tweenInfo, {Position = self._winnersTitle.Position + UDim2.new(1, 0, 0, 0)})
        local containerOut = TweenService:Create(self._winnersContent, tweenInfo, {Position = self._winnersContent.Position + UDim2.new(1, 0, 0, 0)})
        titleOut:Play()
        containerOut:Play()
        task.wait(1)
        local titleIn = TweenService:Create(self._resultsTitle, tweenInfo, {Position = self._resultsTitle.Position + UDim2.new(1, 0, 0, 0)})
        local containerIn = TweenService:Create(self._resultsContent, tweenInfo, {Position = self._resultsContent.Position + UDim2.new(1, 0, 0, 0)})
        titleIn:Play()
        containerIn:Play()
        
        task.wait(4)
        self._gui.Enabled = false

        for _, playerGrid in pairs (self._winnersContent:GetChildren()) do
            if playerGrid:IsA("GuiBase2d") then
                playerGrid:Destroy()
            end
        end

        for _, playerGrid in pairs (self._resultsContent:GetChildren()) do
            if playerGrid:IsA("GuiBase2d") then
                playerGrid:Destroy()
            end
        end
    end)

    table.insert(self._events, e)
end

function WinnersUI:_convertOffsetToScale(offset, frame)
    local x = offset
	local total_x = frame.AbsoluteSize.x
	local final_x = x / total_x 

	return final_x
end

function WinnersUI:_adjustFrame(frame)
	local desc = frame:FindFirstChild("Description")
	local line = frame:FindFirstChild("Line")
	local currencyIcon = frame:FindFirstChild("CurrencyIcon")
	local descXScale = self:_convertOffsetToScale(desc.TextBounds.X, frame)
	line.Position = UDim2.new(desc.Position.X.Scale + descXScale + 0.025, 0, line.Position.Y.Scale, 0)
	local newLineSize = (currencyIcon.Position.X.Scale - 0.025) - (desc.Position.X.Scale + descXScale + 0.025)
	line.Size = UDim2.new(newLineSize, 0, line.Size.Y.Scale, 0)
end

return WinnersUI