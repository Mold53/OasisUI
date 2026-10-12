local import = ...
local Maid = import("Core/Maid")
local Signal = import("Core/Signal")
local Theme = import("Core/Theme")
local Util = import("Core/Util")
local Keybinds = import("Core/Keybinds")
local Storage = import("Core/Storage")
local Layer = import("Components/Layer")
local Popup = import("Components/Popup")
local Tooltip = import("Components/Tooltip")
local Notification = import("Components/Notification")

local Library = {
    Version = "dev",
    Flags = {},
    Windows = {},
    Theme = Theme,
    Icons = Util.Icons,
    Storage = Storage,
    Util = Util,
    Unloaded = Signal.new(),
    Maid = Maid.new(),
}
Library.Options = Library.Flags

local function registry()
    local env = type(getgenv) == "function" and getgenv() or _G
    env.__OasisUI = env.__OasisUI or {}
    return env.__OasisUI
end

-- def: see Components/Window
function Library:CreateWindow(def)
    def = def or {}
    if not self._started then
        self._started = true
        local name = def.GuiName or "OasisUI"
        -- a previous run with the same gui name gets unloaded first
        local previous = registry()[name]
        if previous then pcall(previous) end
        registry()[name] = function() self:Unload() end
        self._name = name
        Layer.Init(self.Maid, name)
        Keybinds.Start(self.Maid)
        self.Maid:Give(task.spawn(function()
            while true do
                task.wait(20)
                Theme.Sweep()
            end
        end))
    end
    local window = import("Components/Window").new(self, def)
    table.insert(self.Windows, window)
    return window
end

-- options: Title, Content, Type (Info | Success | Warning | Error), Icon, Duration, Buttons
function Library:Notify(options)
    if not self._started then
        warn("[OasisUI] create a window before notifying")
        return nil
    end
    return Notification.Notify(options)
end

function Library:SetTheme(name)
    return Theme.UsePalette(name)
end

function Library:SetAccent(color)
    Theme.Set({ Accent = color })
end

function Library:SetThemeValues(patch)
    Theme.Set(patch)
end

function Library:AddIcons(map)
    for name, id in map do Util.Icons[name] = id end
end

function Library:GetFlag(flag)
    local element = self.Flags[flag]
    return element and element:Get()
end

function Library:SetFlag(flag, value)
    local element = self.Flags[flag]
    if element then element:Set(value) end
end

function Library:Toggle()
    for _, window in self.Windows do window:Toggle() end
end

Library.Destroy = function(self) self:Unload() end

function Library:OnUnload(fn)
    return self.Unloaded:Connect(fn)
end

function Library:Unload()
    if self.IsUnloaded then return end
    self.IsUnloaded = true
    Popup.CloseAll()
    Tooltip.Hide()
    for _, window in self.Windows do window:Destroy() end
    table.clear(self.Windows)
    self.Maid:Clean()
    Theme.Sweep()
    if self._name and registry()[self._name] then registry()[self._name] = nil end
    self.Unloaded:Fire()
end

return Library
