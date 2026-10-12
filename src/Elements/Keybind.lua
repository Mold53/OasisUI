local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Binding = import("Core/Binding")
local Row = import("Components/Row")
local Widgets = import("Components/Widgets")

-- def: Title, Default (KeyCode | name), Mode ("Toggle" | "Hold" | "Always"), Modes,
--      Callback(state) for Toggle / Hold, Pressed() on every press, ChangedCallback(key)
local Keybind = Base.Class("Keybind")

function Keybind.new(container, def)
    local self = setmetatable({}, Keybind)
    Base.Init(self, container, def)
    self.Value = false
    -- def.Binding: show an existing binding (owner handles presses)
    self.Binding = def.Binding or Binding.new({
        Key = def.Default or def.Key or def.Value,
        Mode = def.Mode or "Toggle",
        Modes = def.Modes or { "Toggle", "Hold", "Always" },
        Press = function(binding)
            if self.Locked then return end
            Util.Safe(def.Pressed)
            if binding.Mode == "Toggle" then
                self:_commit(not self.Value)
            elseif binding.Mode == "Hold" then
                self:_commit(true)
            else
                Util.Safe(def.Callback)
            end
        end,
        Release = function(binding)
            if binding.Mode == "Hold" and not self.Locked then self:_commit(false) end
        end,
    })
    self.Binding.Changed:Connect(function()
        if self.Binding.Mode == "Always" and self.Value then self:_commit(false, true) end
        Util.Safe(def.ChangedCallback, self.Binding.Key)
        self.Window:_touch(true)
    end)
    if not def.Binding then self.Window:_trackBind(self) end
    return self
end

function Keybind:Set(state, silent)
    state = state and true or false
    if state == self.Value then return end
    self:_commit(state, silent)
end

function Keybind:GetKey()
    return self.Binding.Key
end

function Keybind:SetKey(key)
    self.Binding:SetKey(key)
end

function Keybind:SetMode(mode)
    self.Binding:SetMode(mode)
end

function Keybind:IsDown()
    return self.Binding.Held
end

function Keybind:BindInfo()
    return self.Title, self.Value
end

function Keybind:Save()
    return self.Binding:Save()
end

function Keybind:Load(data)
    self.Binding:Load(data)
end

function Keybind:Render(parent, maid)
    local row = Row.new(self, parent, maid)
    local _, connection = Widgets.KeyPill(row.Right, self.Binding, { Height = 20 })
    maid:Give(connection)
    return row.Frame
end

return Keybind
