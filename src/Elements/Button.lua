local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Binding = import("Core/Binding")
local Widgets = import("Components/Widgets")
local Tooltip = import("Components/Tooltip")

-- def: Title, Icon, Style ("Default" | "Primary" | "Danger" | "Ghost"), Confirm (true | text), Keybind, Callback()
local Button = Base.Class("Button")

local STYLES = {
    Default = { Bg = "Elevated", Hover = "ElevatedHover", Text = "Text", Icon = "TextDim" },
    Primary = { Bg = "Accent", Hover = "Accent", Text = "OnAccent", Icon = "OnAccent" },
    Danger  = { Bg = "Elevated", Hover = "ElevatedHover", Text = "Danger", Icon = "Danger" },
    Ghost   = { Bg = "Surface", Hover = "Elevated", Text = "TextDim", Icon = "TextMuted" },
}
Button.Styles = STYLES

function Button.new(container, def)
    local self = setmetatable({}, Button)
    Base.Init(self, container, def)
    self.NoSave = not def.Keybind
    self.Armed = false
    if def.Keybind then
        local spec = type(def.Keybind) == "table" and def.Keybind or { Key = def.Keybind ~= true and def.Keybind or nil }
        self.Binding = Binding.new({
            Key = spec.Key or spec.Default,
            Mode = "Always",
            Modes = { "Always" },
            Press = function() self:Press(true) end,
        })
        self.Binding.Changed:Connect(function() self.Window:_touch(true) end)
    end
    return self
end

-- skipConfirm: keybinds fire straight away
function Button:Press(skipConfirm)
    if self.Locked then return end
    local confirm = self.Def.Confirm
    if confirm and not skipConfirm and not self.Armed then
        self.Armed = true
        self.StateChanged:Fire("Armed")
        task.delay(2.5, function()
            if self.Armed then
                self.Armed = false
                self.StateChanged:Fire("Armed")
            end
        end)
        return
    end
    if self.Armed then
        self.Armed = false
        self.StateChanged:Fire("Armed")
    end
    Util.Safe(self.Def.Callback)
end

function Button:Save()
    return self.Binding and self.Binding:Save() or nil
end

function Button:Load(data)
    if self.Binding then self.Binding:Load(data) end
end

-- shared by Button and ButtonRow
function Button.Draw(parent, spec, getState, onPress)
    local style = STYLES[spec.Style or "Default"] or STYLES.Default
    local hover = false
    local button = Util.New("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 0, 30),
        Theme = {
            BackgroundColor3 = function(t)
                local state = getState()
                if state.Armed then return t.Danger end
                return hover and t[style.Hover] or t[style.Bg]
            end,
            BackgroundTransparency = function(t)
                if spec.Style == "Primary" or getState().Armed then return hover and 0 or 0.08 end
                return t.ElevatedTransparency
            end,
        },
        Parent = parent,
    })
    Util.Corner(6, button)
    Util.Stroke(button, function(t) return spec.Style == "Danger" and t.Danger or t.Stroke end, function(t)
        return spec.Style == "Danger" and 0.6 or t.StrokeTransparency + 0.1
    end)
    Util.List(button, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    local icon
    if spec.Icon then
        icon = Util.Icon(spec.Icon, {
            Size = UDim2.fromOffset(14, 14),
            LayoutOrder = 1,
            Theme = { ImageColor3 = function(t) return getState().Armed and t.OnAccent or t[style.Icon] end },
            Parent = button,
        })
    end
    local label = Util.Label({
        Text = spec.Title or "Button",
        TextSize = 12,
        Weight = Enum.FontWeight.SemiBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 2,
        Theme = { TextColor3 = function(t) return getState().Armed and t.OnAccent or t[style.Text] end },
        Parent = button,
    })
    local scale = Util.New("UIScale", { Parent = button })
    button.MouseEnter:Connect(function() hover = true; Theme.Refresh(button, 0.12) end)
    button.MouseLeave:Connect(function() hover = false; Theme.Refresh(button, 0.12) end)
    button.MouseButton1Down:Connect(function() Util.Tween(scale, 0.08, { Scale = 0.97 }) end)
    button.MouseButton1Up:Connect(function() Util.Tween(scale, 0.12, { Scale = 1 }) end)
    button.MouseButton1Click:Connect(onPress)
    local function paint()
        local state = getState()
        label.Text = state.Armed and (type(spec.Confirm) == "string" and spec.Confirm or "Click again to confirm") or (state.Title or spec.Title or "Button")
        label.TextTransparency = state.Locked and 0.55 or 0
        if icon then icon.ImageTransparency = state.Locked and 0.55 or 0 end
        Theme.Refresh(button, 0.15)
        Theme.Refresh(label, 0.15)
        if icon then Theme.Refresh(icon, 0.15) end
    end
    return button, paint
end

function Button:Render(parent, maid)
    local holder = maid:Give(Util.New("Frame", {
        Name = "Button",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Visible = self.Visible,
        Parent = parent,
    }))
    local spec = table.clone(self.Def)
    local button, paint = Button.Draw(holder, spec, function() return self end, function() self:Press() end)
    if self.Binding then
        button.Size = UDim2.new(1, -46, 0, 30)
        local _, connection = Widgets.KeyPill(holder, self.Binding, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Height = 22,
        })
        maid:Give(connection)
    end
    if self.Tooltip then maid:Give(Tooltip.Attach(button, function() return self.Tooltip end)) end
    paint()
    maid:Give(self.StateChanged:Connect(function(what)
        if what == "Visible" then holder.Visible = self.Visible end
        paint()
    end))
    return holder
end

return Button
