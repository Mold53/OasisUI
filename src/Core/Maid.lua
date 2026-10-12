local _ = ...

-- collects connections, instances, functions and objects; Clean releases them newest first
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item)
    table.insert(self._tasks, item)
    return item
end

local function release(item)
    local kind = typeof(item)
    if kind == "RBXScriptConnection" then
        item:Disconnect()
    elseif kind == "Instance" then
        item:Destroy()
    elseif kind == "function" then
        item()
    elseif kind == "thread" then
        pcall(task.cancel, item)
    elseif kind == "table" then
        if item.Disconnect then
            item:Disconnect()
        elseif item.Clean then
            item:Clean()
        elseif item.Destroy then
            item:Destroy()
        end
    end
end

function Maid:Clean()
    local tasks = self._tasks
    self._tasks = {}
    for i = #tasks, 1, -1 do
        local ok, err = pcall(release, tasks[i])
        if not ok then warn("[OasisUI] cleanup: " .. tostring(err)) end
    end
end

Maid.Destroy = Maid.Clean

return Maid
