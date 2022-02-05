local manifest = {
    {
        ['objType'] = 'interfaces',
        ['folderName'] = "UI", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {"gui"}
    },
    {
        ['objType'] = 'classes',
        ['folderName'] = "classes", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {}
    },
    {
        ['objType'] = 'services',
        ['folderName'] = "services", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {}
    },
    {
        ['objType'] = 'handlers',
        ['folderName'] = "handlers", -- checks game.ReplicatedStorage.Common & game.ServerScriptService.Server
        ['priority'] = {}
    },
}

return manifest