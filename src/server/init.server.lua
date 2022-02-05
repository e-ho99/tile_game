local framework = {}
local manifest = require(script.manifest)

local function _getFolders(folderName)
    --[[ Gets folder from Common (shared) and Server script (server), returns array ]]--
    local folders = {}

    for _, folder in pairs({game.ReplicatedStorage.Common:FindFirstChild(folderName), script:FindFirstChild(folderName)}) do
        if folder then
            table.insert(folders, folder)
        end
    end    

    return folders
end

local function _addModule(module, root) -- module: ModuleScript, modules: array that holds init modules
    local moduleName = module.Name

    module = require(module)
    module:init(framework)

    if not framework[root] then
        framework[root] = {}
    end
    
    if root and not framework[root][moduleName] then
        framework[root][moduleName] = module
        print("Initializing module:", moduleName, "| Root: ", root)
    elseif not root and not framework[moduleName] then
        framework[moduleName] = module
        print("Initializing module:", moduleName)
    end
end

local function initModules()
    for _, manifestData in pairs(manifest) do 
        local folders = _getFolders(manifestData.objType)

        for _, folder in pairs(folders) do -- do prioritized modules/inherited modules first
            for _, moduleName in pairs(manifestData.priority) do
                local module = folder:FindFirstChild(moduleName, true)
 
                if module and module:IsA("ModuleScript") then
                    _addModule(module, manifestData.objType)
                    -- checking for inherited modules (stored in same folder as base module) -- 
                    local childFolder
                    
                    if module:IsA("Folder") and module.Parent == module.Name .. "s" then
                        childFolder = module.Parent

                        for _, childModule in pairs(childFolder:GetChildren()) do
                            if childModule and childModule:IsA("ModuleScript") then
                                _addModule(childModule, manifestData.objType)
                            end
                        end
                    end
                end
            end
        end
        
        for _, folder in pairs(folders) do -- remaining modules in folder
            for _, module in pairs(folder:GetDescendants()) do
                if module:IsA("ModuleScript") then
                    _addModule(module, module.Parent.Name)
                end
            end    
        end
    end
end

local function startServices()
    for name, service in pairs(framework['services']) do   
        framework['services'][name] = service.new()
        print("started service", name)
    end
end

initModules()
startServices()