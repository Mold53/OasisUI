local import = ...
local Base = import("Elements/Base")
local Row = import("Components/Row")
local Widgets = import("Components/Widgets")
local Binding = import("Core/Binding")
local Input = import("Elements/Input")
local ColorPicker = import("Elements/ColorPicker")

-- def: Title, Description, Default, Style ("Switch" | "Checkbox"), Keybind (true | key | { Key, Mode }),
--      Field (a value box in the same row, set while off too: Input options plus Width),
--      Color (a colour swatch in the same row: ColorPicker options with their own Flag), Listed, Callback(value)
local Toggle = Base.Class("Toggle")

function Toggle.new(container, def)
    local self = setmetatable({}, Toggle)
    Base.Init(self, container, def)
    self.Default = (def.Default or def.Value) == true
    self.Value = self.Default
    self.Style = def.Style or "Switch"
    if def.Keybind then
        local spec = type(def.Keybind) == "table" and def.Keybind or { Key = def.Keybind ~= true and def.Keybind or nil }
        self.Binding = Binding.new({
            Key = spec.Key or spec.Default,
            Mode = spec.Mode,
            Modes = spec.Modes or { "Toggle", "Hold" },
            Capture = spec,
            Press = function(binding)
                if self.Locked then return end
                self:Set(binding.Mode == "Hold" or not self.Value)
            end,
            Release = function(binding)
                if binding.Mode == "Hold" and not self.Locked then self:Set(false) end
            end,
        })
        self.Binding.Changed:Connect(function() self.Window:_touch(true) end)
        self.Window:_trackBind(self)
    end
    if def.Field then
        -- its own element model: own Flag, callback, validation; toggle.Field:Get() reads it
        local spec = table.clone(def.Field)
        spec.Title = spec.Title or self.Title
        self.Field = Input.new(container, spec)
    end
    if def.Color then
        local spec = table.clone(def.Color)
        spec.Title = spec.Title or (self.Title .. " colour")
        self.Color = ColorPicker.new(container, spec)
    end
    return self
end

function Toggle:Reset()
    Base.Reset(self)
    if self.Field then self.Field:Reset() end
    if self.Color then self.Color:Reset() end
end

function Toggle:Destroy()
    if self.Field then self.Field:Destroy() end
    if self.Color then self.Color:Destroy() end
    Base.Destroy(self)
end

function Toggle:Set(value, silent)
    value = value and true or false
    if value == self.Value then return end
    self:_commit(value, silent)
end

function Toggle:Save()
    if self.Binding then return { Value = self.Value, Bind = self.Binding:Save() } end
    return self.Value
end

function Toggle:Load(data)
    if type(data) == "table" then
        if self.Binding and data.Bind then self.Binding:Load(data.Bind) end
        self:Set(data.Value)
    else
        self:Set(data)
    end
end

function Toggle:BindInfo()
    return self.Title, self.Value
end

function Toggle:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Click = true })
    if self.Field then
        self.Field:RenderInline(row.Right, maid, { Width = self.Def.Field.Width, LayoutOrder = 0 })
    end
    if self.Color then self.Color:RenderInline(row.Right, maid, { LayoutOrder = 1 }) end
    if self.Binding then
        local _, connection = Widgets.KeyPill(row.Right, self.Binding, { LayoutOrder = 2 })
        maid:Give(connection)
    end
    local _, paint = (self.Style == "Checkbox" and Widgets.Checkbox or Widgets.Switch)(row.Right, { LayoutOrder = 3 })
    paint(self.Value, false)
    maid:Give(self.Changed:Connect(function(value) paint(value, true) end))
    row.Button.MouseButton1Click:Connect(function()
        if not self.Locked then self:Set(not self.Value) end
    end)
    return row.Frame
end

return Toggle
