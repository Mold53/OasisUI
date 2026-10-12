local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Signal = import("Core/Signal")

-- one InputBegan/InputEnded pair for every bind; keys are read through getters
local UIS = Services.UserInputService
local Keybinds = {
    Capturing = false,
    Activity = Signal.new(),    -- a bound key went down or up
    -- defaults for every capture; a binding can override each field
    Options = {
        ClickOutside = "Keep",  -- "Keep" | "Clear": clicking elsewhere while binding
        Escape = "Keep",        -- "Keep" | "Clear"
        Mouse = true,           -- mouse buttons 2 and 3 can be bound
    },
    _binds = {},
    _capture = nil,
}

local MOUSE = {
    [Enum.UserInputType.MouseButton2] = "MouseButton2",
    [Enum.UserInputType.MouseButton3] = "MouseButton3",
}

function Keybinds.Name(input)
    local kind = input.UserInputType
    if kind == Enum.UserInputType.Keyboard or kind.Name:find("^Gamepad") then
        local name = input.KeyCode.Name
        return name ~= "Unknown" and name or nil
    end
    return MOUSE[kind]
end

-- entry: { Key = function() -> name?, Press = function, Release = function? }
function Keybinds.Add(entry)
    table.insert(Keybinds._binds, entry)
    return {
        Disconnect = function()
            local index = table.find(Keybinds._binds, entry)
            if index then table.remove(Keybinds._binds, index) end
        end,
    }
end

local function finish(result)
    local capture = Keybinds._capture
    if not capture then return end
    Keybinds._capture = nil
    capture.connection:Disconnect()
    -- the captured press must not reach the dispatcher in the same frame
    task.defer(function()
        if not Keybinds._capture then Keybinds.Capturing = false end
    end)
    Util.Safe(capture.done, result)
end

local function option(options, key, global)
    if options and options[key] ~= nil then return options[key] end
    return Keybinds.Options[global or key]
end

-- done(name) on a key, done(false) to clear, done(nil) to keep the old key
-- options: Blacklist = { names }, AllowMouse, CanUnbind, ClickOutside, Escape
function Keybinds.Capture(done, options)
    if Keybinds._capture then finish(nil) end
    Keybinds.Capturing = true
    local canUnbind = not options or options.CanUnbind ~= false
    local blacklist = {}
    for _, key in options and options.Blacklist or {} do
        blacklist[typeof(key) == "EnumItem" and key.Name or tostring(key)] = true
    end
    local function clearOrKeep(setting)
        finish(if setting == "Clear" and canUnbind then false else nil)
    end

    local capture = { done = done }
    capture.connection = UIS.InputBegan:Connect(function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            clearOrKeep(option(options, "ClickOutside"))
        elseif kind == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape then
                clearOrKeep(option(options, "Escape"))
            elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
                finish(if canUnbind then false else nil)
            elseif key ~= Enum.KeyCode.Unknown and not blacklist[key.Name] then
                finish(key.Name)
            end
        elseif MOUSE[kind] then
            if option(options, "AllowMouse", "Mouse") ~= false and not blacklist[MOUSE[kind]] then
                finish(MOUSE[kind])
            end
        else
            local name = Keybinds.Name(input)
            if name and not blacklist[name] then finish(name) end
        end
    end)
    Keybinds._capture = capture
    task.delay(10, function()
        if Keybinds._capture == capture then finish(nil) end
    end)
end

function Keybinds.CancelCapture()
    finish(nil)
end

local function dispatch(input, release)
    local name = Keybinds.Name(input)
    if not name then return end
    local hit = false
    for _, entry in table.clone(Keybinds._binds) do
        if entry.Key() == name then
            if release then
                if entry.Release then Util.Safe(entry.Release) end
            else
                Util.Safe(entry.Press)
            end
            hit = true
        end
    end
    if hit then Keybinds.Activity:Fire(name, not release) end
end

function Keybinds.Start(maid)
    maid:Give(UIS.InputBegan:Connect(function(input)
        if Keybinds.Capturing or UIS:GetFocusedTextBox() then return end
        dispatch(input, false)
    end))
    maid:Give(UIS.InputEnded:Connect(function(input)
        dispatch(input, true)
    end))
    maid:Give(function()
        finish(nil)
        table.clear(Keybinds._binds)
    end)
end

return Keybinds
