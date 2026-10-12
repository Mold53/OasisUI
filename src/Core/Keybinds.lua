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
        ComboKeys = 3,          -- keys per bind: 2 allows LCtrl + L, 1 turns combos off
    },
    _binds = {},
    _capture = nil,
}

-- held while binding, these wait for the next key; let go alone, they are the bind
Keybinds.Modifiers = {
    LeftControl = Enum.KeyCode.LeftControl, RightControl = Enum.KeyCode.RightControl,
    LeftShift = Enum.KeyCode.LeftShift, RightShift = Enum.KeyCode.RightShift,
    LeftAlt = Enum.KeyCode.LeftAlt, RightAlt = Enum.KeyCode.RightAlt,
}

-- "LeftControl+L" -> { "LeftControl" }, "L"
function Keybinds.Split(name)
    local parts = string.split(name, "+")
    local main = table.remove(parts)
    return parts, main
end

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
    if capture.release then capture.release:Disconnect() end
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
-- options: Blacklist = { names }, AllowMouse, CanUnbind, ClickOutside, Escape, ComboKeys,
--          Progress(text | nil) while modifiers are held
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

    -- combo: modifiers pressed so far, in order; the bind ends at the next key, on a release,
    -- or when the combo is full
    local maxKeys = math.max(1, math.floor(tonumber(option(options, "ComboKeys")) or 1))
    local held = {}
    local function progress()
        if options and options.Progress then Util.Safe(options.Progress, #held > 0 and table.concat(held, "+") or nil) end
    end
    local function combo(last)
        local keys = table.clone(held)
        if last then table.insert(keys, last) end
        return table.concat(keys, "+")
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
                if Keybinds.Modifiers[key.Name] and #held + 1 < maxKeys and not table.find(held, key.Name) then
                    table.insert(held, key.Name)
                    progress()
                else
                    finish(combo(key.Name))
                end
            end
        elseif MOUSE[kind] then
            if option(options, "AllowMouse", "Mouse") ~= false and not blacklist[MOUSE[kind]] then
                finish(combo(MOUSE[kind]))
            end
        else
            local name = Keybinds.Name(input)
            if name and not blacklist[name] then finish(combo(name)) end
        end
    end)
    -- a held modifier let go before another key: the modifiers alone are the bind
    capture.release = UIS.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if table.find(held, input.KeyCode.Name) then finish(combo(nil)) end
    end)
    Keybinds._capture = capture
    task.delay(10, function()
        if Keybinds._capture == capture then finish(nil) end
    end)
end

function Keybinds.CancelCapture()
    finish(nil)
end

local function modifiersDown(keys)
    for _, key in keys do
        local code = Keybinds.Modifiers[key]
        if not (code and UIS:IsKeyDown(code)) then return false end
    end
    return true
end

-- a press fires the binds whose last key it is and whose modifiers are held; the most specific win,
-- so LCtrl + L does not also fire a plain L bind; a release of the last key releases them
local function dispatch(input, release)
    local name = Keybinds.Name(input)
    if not name then return end
    local hits, best = {}, -1
    for _, entry in table.clone(Keybinds._binds) do
        local key = entry.Key()
        if key then
            local modifiers, main = Keybinds.Split(key)
            if main == name then
                if release then
                    table.insert(hits, entry)
                elseif modifiersDown(modifiers) then
                    if #modifiers > best then
                        best, hits = #modifiers, { entry }
                    elseif #modifiers == best then
                        table.insert(hits, entry)
                    end
                end
            end
        end
    end
    for _, entry in hits do
        if release then
            if entry.Release then Util.Safe(entry.Release) end
        else
            Util.Safe(entry.Press)
        end
    end
    if #hits > 0 then Keybinds.Activity:Fire(name, not release) end
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
