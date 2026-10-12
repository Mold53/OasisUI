local import = ...
local Services = import("Core/Services")

-- executor file api; everything degrades to no-ops when it is missing
local Storage = {}

Storage.Available = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    and type(makefolder) == "function" and type(isfolder) == "function"

function Storage.Ensure(path)
    if not Storage.Available then return false end
    local built = ""
    for part in path:gmatch("[^/]+") do
        built = built == "" and part or (built .. "/" .. part)
        if not isfolder(built) then pcall(makefolder, built) end
    end
    return true
end

function Storage.Read(path)
    if not Storage.Available then return nil end
    local ok, exists = pcall(isfile, path)
    if not ok or not exists then return nil end
    local read, content = pcall(readfile, path)
    return read and content or nil
end

function Storage.Write(path, content)
    if not Storage.Available then return false end
    local folder = path:match("^(.*)/[^/]+$")
    if folder then Storage.Ensure(folder) end
    local ok, err = pcall(writefile, path, content)
    if not ok then warn("[OasisUI] write " .. path .. ": " .. tostring(err)) end
    return ok
end

function Storage.Delete(path)
    if not Storage.Available or type(delfile) ~= "function" then return false end
    local ok = pcall(delfile, path)
    return ok
end

function Storage.Exists(path)
    if not Storage.Available then return false end
    local ok, exists = pcall(isfile, path)
    return ok and exists
end

-- file names in folder with extension, without the extension
function Storage.List(folder, extension)
    if not Storage.Available or type(listfiles) ~= "function" then return {} end
    local ok, files = pcall(listfiles, folder)
    if not ok or type(files) ~= "table" then return {} end
    local out = {}
    for _, file in files do
        local name = tostring(file):gsub("\\", "/"):match("([^/]+)%." .. extension .. "$")
        if name then table.insert(out, name) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

function Storage.ReadJSON(path)
    local content = Storage.Read(path)
    if not content then return nil end
    local ok, data = pcall(Services.HttpService.JSONDecode, Services.HttpService, content)
    if not ok then
        warn("[OasisUI] invalid json in " .. path)
        return nil
    end
    return data
end

function Storage.WriteJSON(path, data)
    local ok, content = pcall(Services.HttpService.JSONEncode, Services.HttpService, data)
    if not ok then
        warn("[OasisUI] could not encode " .. path .. ": " .. tostring(content))
        return false
    end
    return Storage.Write(path, content)
end

function Storage.Encode(data)
    local ok, content = pcall(Services.HttpService.JSONEncode, Services.HttpService, data)
    return ok and content or nil
end

function Storage.Decode(content)
    local ok, data = pcall(Services.HttpService.JSONDecode, Services.HttpService, content)
    return ok and data or nil
end

return Storage
