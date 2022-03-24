CurrencyUI = {}
CurrencyUI.__index = CurrencyUI

function CurrencyUI:init(e)
    engine = e
    setmetatable(CurrencyUI, engine.interfaces.gui)
end

function CurrencyUI.new()
    local self = setmetatable(engine.interfaces.gui.new(script.Name), CurrencyUI)

    self._coinFrame = self._gui.Frame.CoinFrame
    self._gemFrame = self._gui.Frame.GemFrame
    self._initialStates = {
        ["Coins"] = 0,
        ["Gems"] = 0
    }
    self:initUI()
    self:initEvents()
    
    return self
end

function CurrencyUI:initEvents()
    local folder = game.Players.LocalPlayer:WaitForChild("PlayerData")

    folder.Coins.Changed:Connect(function()
        local newVal = folder.Coins.Value

        self._initialStates.Coins = newVal
        self._coinFrame.Amount.Text = tostring(newVal)
    end)

    folder.Gems.Changed:Connect(function()
        local newVal = folder.Gems.Value

        self._initialStates.Gems = newVal
        self._gemFrame.Amount.Text = tostring(newVal)
    end)
end

function CurrencyUI:initUI()
    local folder = game.Players.LocalPlayer:WaitForChild("PlayerData")
    self._initialStates.Coins = folder.Coins.Value
    self._initialStates.Gems = folder.Gems.Value
    self._coinFrame.Amount.Text = tostring(folder.Coins.Value)
    self._gemFrame.Amount.Text = tostring(folder.Gems.Value)
end

return CurrencyUI