PictureItHandler = {}
PictureItHandler.__index = PictureItHandler

local gameEvents = game.ReplicatedStorage.shared.Events.GameEvents
local TileStates = {["isEntered"] = false}

function PictureItHandler:init(e)
    engine = e
end

-- manages tile regions to calculate entering/leaving of tiles --
function PictureItHandler.new(args) 
    local self = setmetatable({}, PictureItHandler)
    self._model = args.model
    
    self:initEvents()

    print("created picture it handler for client")
    return self
end

function PictureItHandler:initEvents()
    for _, tile in pairs (self._model.TileSets:GetDescendants()) do
        if tile:IsA("BasePart") then
            tile.ClickDetector.MouseClick:Connect(function() -- garbage collected when click detector deleted
                print("client click")
                gameEvents.TileEvents.TileClickDetector:FireServer(tile)
            end)
        end
    end
end

return PictureItHandler