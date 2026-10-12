local import = ...
local Signal = import("Core/Signal")
local Keybinds = import("Core/Keybinds")

-- key + activation mode owned by a module, toggle, button or keybind element
local Binding = {}
Binding.__index = Binding

local function keyName(value)
    if typeof(value) == "EnumItem" then return value.Name end
    if type(value) == "string" and value ~= "" and value ~= "None" then return value end
    return nil
end
Binding.KeyName = keyName

-- options: Key, Mode, Modes, Press(binding), Release(binding),
--          Capture = { Blacklist, AllowMouse, CanUnbind, ClickOutside, Escape } (see Keybinds.Capture)
function Binding.new(options)
    local capture = options.Capture or {}
    local self = setmetatable({
        Key = keyName(options.Key),
        Mode = options.Mode or "Toggle",
        Modes = options.Modes or { "Toggle", "Hold" },
        Changed = Signal.new(),
        Held = false,
        CanUnbind = capture.CanUnbind ~= false,
        CaptureOptions = {
            Blacklist = capture.Blacklist,
            AllowMouse = capture.AllowMouse,
            CanUnbind = capture.CanUnbind,
            ClickOutside = capture.ClickOutside,
            Escape = capture.Escape,
        },
    }, Binding)
    if not table.find(self.Modes, self.Mode) then self.Mode = self.Modes[1] end
    self._entry = Keybinds.Add({
        Key = function() return self.Key end,
        Press = function()
            self.Held = true
            if options.Press then options.Press(self) end
        end,
        Release = function()
            if not self.Held then return end
            self.Held = false
            if options.Release then options.Release(self) end
        end,
    })
    return self
end

function Binding:SetKey(key)
    if keyName(key) == nil and not self.CanUnbind then return end
    self.Key = keyName(key)
    self.Held = false
    self.Changed:Fire()
end

-- waits for the next key; Backspace clears, Escape cancels
function Binding:Capture()
    if self.Capturing then return end
    self.Capturing = true
    self.Changed:Fire()
    Keybinds.Capture(function(result)
        self.Capturing = false
        if result == false then
            self.Key = nil
        elseif result then
            self.Key = result
        end
        self.Held = false
        self.Changed:Fire()
    end, self.CaptureOptions)
end

function Binding:SetMode(mode)
    if not table.find(self.Modes, mode) then return end
    self.Mode = mode
    self.Changed:Fire()
end

function Binding:Save()
    return { Key = self.Key or false, Mode = self.Mode }
end

function Binding:Load(data)
    if type(data) ~= "table" then return end
    local key = keyName(data.Key)
    if key or self.CanUnbind then self.Key = key end
    if data.Mode and table.find(self.Modes, data.Mode) then self.Mode = data.Mode end
    self.Changed:Fire()
end

function Binding:Destroy()
    self._entry:Disconnect()
    self.Changed:Destroy()
end

return Binding
