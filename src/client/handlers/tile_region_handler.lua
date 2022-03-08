TileRegionHandler = {}
TileRegionHandler.__index = TileRegionHandler

function TileRegionHandler:init(e)
    engine = e
end

-- manages tile regions to calculate entering/leaving of tiles --
function TileRegionHandler.new() 
    local self = setmetatable({}, TileRegionHandler)

    return self
end

return TileRegionHandler