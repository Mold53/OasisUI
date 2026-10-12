local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")

-- one InputBegan/InputEnded pair for every bind; keys are read through getters
local UIS = Services.UserInputService
local Keybinds = { Capturing = false, _binds = {}, _capture = nil }

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

-- done(name) on a key, done(false) on Backspace/Delete, done(nil) on Escape / click / timeout
function Keybinds.Capture(done)
    if Keybinds._capture then finish(nil) end
    Keybinds.Capturing = true
    local capture = { done = done }
    capture.connection = UIS.InputBegan:Connect(function(input)
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
            finish(nil)
        elseif kind == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape then
                finish(nil)
            elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
                finish(false)
            elseif key ~= Enum.KeyCode.Unknown then
                finish(key.Name)
            end
        else
            local name = Keybinds.Name(input)
            if name then finish(name) end
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

function Keybinds.Start(maid)
    maid:Give(UIS.InputBegan:Connect(function(input)
        if Keybinds.Capturing or UIS:GetFocusedTextBox() then return end
        local name = Keybinds.Name(input)
        if not name then return end
        for _, entry in table.clone(Keybinds._binds) do
            if entry.Key() == name then Util.Safe(entry.Press) end
        end
    end))
    maid:Give(UIS.InputEnded:Connect(function(input)
        local name = Keybinds.Name(input)
        if not name then return end
        for _, entry in table.clone(Keybinds._binds) do
            if entry.Release and entry.Key() == name then Util.Safe(entry.Release) end
        end
    end))
    maid:Give(function()
        finish(nil)
        table.clear(Keybinds._binds)
    end)
end

return Keybinds
