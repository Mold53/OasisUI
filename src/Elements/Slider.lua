local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Drag = import("Core/Drag")
local Row = import("Components/Row")
local Menu = import("Components/Menu")

-- def: Title, Min, Max, Default, Step | Rounding, Prefix, Suffix, Format(value) -> text,
--      Input (editable value in the title line, default true), Buttons (- / + steppers),
--      Icons = { From, To } (symbols at both ends), ShowRange (min / max under the track), Live (default true)
local Slider = Base.Class("Slider")

function Slider.new(container, def)
    local self = setmetatable({}, Slider)
    Base.Init(self, container, def)
    self.Min = def.Min or 0
    self.Max = def.Max or 100
    if self.Max < self.Min then self.Min, self.Max = self.Max, self.Min end
    self.Step = def.Step or (def.Rounding and 10 ^ -def.Rounding) or 1
    self.Default = self:_clamp(def.Default or def.Value or self.Min)
    self.Value = self.Default
    return self
end

function Slider:_clamp(value)
    value = tonumber(value) or self.Min
    return math.clamp(Util.Round(value, self.Step), self.Min, self.Max)
end

function Slider:Set(value, silent)
    value = self:_clamp(value)
    if value == self.Value then return end
    self:_commit(value, silent)
end

function Slider:SetMin(min)
    self.Min = min
    self.StateChanged:Fire("Range")
    self:Set(self.Value)
end

function Slider:SetMax(max)
    self.Max = max
    self.StateChanged:Fire("Range")
    self:Set(self.Value)
end

function Slider:Text(value)
    if self.Def.Format then
        local ok, text = pcall(self.Def.Format, value)
        if ok and text then return tostring(text) end
    end
    return (self.Def.Prefix or "") .. Util.Format(value, self.Step) .. (self.Def.Suffix or "")
end

local function stepper(parent, icon, order)
    local button = Util.New("ImageButton", {
        Size = UDim2.fromOffset(16, 16),
        Image = Util.IconId(icon),
        LayoutOrder = order,
        Theme = { ImageColor3 = "TextMuted" },
        Parent = parent,
    })
    Util.Hover(button, function(on) Theme.Bind(button, { ImageColor3 = on and "Text" or "TextMuted" }) end)
    return button
end

-- the track used by Slider and RangeSlider: returns holder, bar, fill
function Slider.Track(parent, element, order)
    local def = element.Def
    local line = Util.New("Frame", {
        Name = "Track",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = order or 1,
        Parent = parent,
    })
    Util.List(line, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local parts = {}
    if def.Buttons then parts.Minus = stepper(line, "minus", 1) end
    if def.Icons and def.Icons.From then
        Util.Icon(def.Icons.From, { Size = UDim2.fromOffset(14, 14), Color = "TextMuted", LayoutOrder = 2, Parent = line })
    end
    local bar = Util.New("TextButton", {
        Name = "Bar",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        LayoutOrder = 3,
        Parent = line,
    })
    Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = bar })
    local rail = Util.New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 4),
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency, 0.3) end },
        Parent = bar,
    })
    Util.Corner(UDim.new(1, 0), rail)
    local fill = Util.New("Frame", {
        Size = UDim2.fromScale(0, 1),
        Theme = { BackgroundColor3 = "Accent" },
        Parent = rail,
    })
    Util.Corner(UDim.new(1, 0), fill)
    Util.New("UIGradient", {
        Theme = { Color = function(t) return ColorSequence.new(t.Accent, t.AccentAlt) end },
        Parent = fill,
    })
    if def.Icons and def.Icons.To then
        Util.Icon(def.Icons.To, { Size = UDim2.fromOffset(14, 14), Color = "TextMuted", LayoutOrder = 4, Parent = line })
    end
    if def.Buttons then parts.Plus = stepper(line, "plus", 5) end
    parts.Line, parts.Bar, parts.Rail, parts.Fill = line, bar, rail, fill
    return parts
end

function Slider.Knob(rail)
    local knob = Util.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        ZIndex = 2,
        Theme = { BackgroundColor3 = "Text" },
        Parent = rail,
    })
    Util.Corner(UDim.new(1, 0), knob)
    Util.Stroke(knob, "Accent", function() return 0 end, 2)
    local scale = Util.New("UIScale", { Scale = 0.85, Parent = knob })
    return knob, scale
end

function Slider.RangeLabels(parent, element, order)
    local labels = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 10),
        LayoutOrder = order,
        Parent = parent,
    })
    local low = Util.Label({ TextSize = 10, Color = "TextMuted", Size = UDim2.fromScale(0.5, 1), Parent = labels })
    local high = Util.Label({ TextSize = 10, Color = "TextMuted", Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = labels })
    local function paint()
        low.Text = element:Text(element.Min)
        high.Text = element:Text(element.Max)
    end
    paint()
    return paint
end

-- value box in the title line; editable unless Input == false
function Slider.ValueBox(parent, element, order, getValue, onSubmit)
    local field, api = Row.Field(parent, {
        Size = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = order,
        Radius = 5,
    })
    Util.Padding(field, 0, 7, 0, 7)
    Util.New("UISizeConstraint", { MinSize = Vector2.new(34, 20), Parent = field })
    local editable = element.Def.Input ~= false
    local box = Util.New(editable and "TextBox" or "TextLabel", {
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        Theme = { TextColor3 = "Text", FontFace = Theme.Font(Enum.FontWeight.SemiBold) },
        Parent = field,
    })
    if editable then
        box.ClearTextOnFocus = false
        box.Focused:Connect(function()
            api.SetFocused(true)
            box.Text = Util.Format(getValue(), element.Step)
            box.SelectionStart = 1
            box.CursorPosition = #box.Text + 1
        end)
        box.FocusLost:Connect(function()
            api.SetFocused(false)
            local number = Util.ParseNumber(box.Text)
            if number and not element.Locked then onSubmit(number) end
            box.Text = element:Text(getValue())
        end)
    end
    box.Text = element:Text(getValue())
    return field, box
end

function Slider:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    local _, box = Slider.ValueBox(row.Right, self, 1, function() return self.Value end, function(number) self:Set(number) end)

    local below = row.Below
    Util.List(below, 3)
    local track = Slider.Track(below, self, 1)
    local knob, knobScale = Slider.Knob(track.Rail)
    local paintRange = self.Def.ShowRange and Slider.RangeLabels(below, self, 2)

    local dragging = false
    local function paint(animate)
        local span = self.Max - self.Min
        local alpha = span > 0 and (self.Value - self.Min) / span or 0
        local time = animate and not dragging and 0.12 or 0
        Util.Tween(track.Fill, time, { Size = UDim2.fromScale(alpha, 1) })
        Util.Tween(knob, time, { Position = UDim2.fromScale(alpha, 0.5) })
        if not box:IsA("TextBox") or not box:IsFocused() then box.Text = self:Text(self.Value) end
    end
    paint(false)
    maid:Give(self.Changed:Connect(function() paint(true) end))
    maid:Give(self.StateChanged:Connect(function(what)
        if what == "Range" then
            paint(false)
            if paintRange then paintRange() end
        end
    end))

    local live = self.Def.Live ~= false
    local function fromPoint(point)
        local bar = track.Bar
        local alpha = math.clamp((point.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        return self.Min + (self.Max - self.Min) * alpha
    end
    track.Bar.InputBegan:Connect(function(input)
        if self.Locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Menu.Open({
                Point = Util.Pointer(input),
                Width = 150,
                Items = {
                    { Title = "Reset to default", Icon = "rotate-ccw", Hint = self:Text(self.Default), Callback = function() self:Set(self.Default) end },
                    { Title = "Set to min", Icon = "chevron-left", Callback = function() self:Set(self.Min) end },
                    { Title = "Set to max", Icon = "chevron-right", Callback = function() self:Set(self.Max) end },
                },
            })
            return
        end
        if not Util.IsPress(input) then return end
        dragging = true
        Util.Tween(knobScale, 0.1, { Scale = 1.15 })
        self:Set(fromPoint(Util.Pointer(input)), not live)
        Drag.Follow(input, function(point)
            self:Set(fromPoint(point), not live)
        end, function()
            dragging = false
            Util.Tween(knobScale, 0.12, { Scale = 0.85 })
            if not live then self:_notify() end
        end, track.Bar)
    end)
    Util.Hover(track.Bar, function(on) if not dragging then Util.Tween(knobScale, 0.1, { Scale = on and 1 or 0.85 }) end end)
    if track.Minus then
        track.Minus.MouseButton1Click:Connect(function() if not self.Locked then self:Set(self.Value - self.Step) end end)
        track.Plus.MouseButton1Click:Connect(function() if not self.Locked then self:Set(self.Value + self.Step) end end)
    end
    return row.Frame
end

return Slider
