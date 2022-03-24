local manifest = {
    {
        ['objType'] = 'classes',
        ['folderName'] = "classes", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {"map", "mode"}
    },
    {
        ['objType'] = 'services',
        ['folderName'] = "services", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {"data_service", "game_service"}
    },
    {
        ['objType'] = 'handlers',
        ['folderName'] = "handlers", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {}
    },
    
}

return manifest