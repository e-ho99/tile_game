CurrencyUI = {}
CurrencyUI.__index = CurrencyUI

local DataEvents = game.ReplicatedStorage.shared.Events.DataEvents

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
    self:_initEvents()
    
    return self
end

function CurrencyUI:_initEvents()
    DataEvents.CoinsUpdated.OnClientEvent:Connect(function(newVal)
        self._initialStates.Coins = newVal
        self._coinFrame.Amount.Text = tostring(newVal)
    end)

    DataEvents.GemsUpdated.OnClientEvent:Connect(function(newVal)
        self._initialStates.Gems = newVal
        self._gemFrame.Amount.Text = tostring(newVal)
    end)
end

return CurrencyUI