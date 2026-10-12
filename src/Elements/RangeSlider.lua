local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Drag = import("Core/Drag")
local Row = import("Components/Row")
local Slider = import("Elements/Slider")

-- two handles on one track; def: Title, Min, Max, Default = { lo, hi } | { Min, Max }, Step, MinGap,
--      Prefix, Suffix, Format, Input, Buttons, Icons, ShowRange, Live, Callback(lo, hi)
local RangeSlider = Base.Class("RangeSlider")

function RangeSlider.new(container, def)
    local self = setmetatable({}, RangeSlider)
    Base.Init(self, container, def)
    self.Min = def.Min or 0
    self.Max = def.Max or 100
    self.Step = def.Step or (def.Rounding and 10 ^ -def.Rounding) or 1
    self.Gap = def.MinGap or 0
    local default = def.Default or def.Value or {}
    local lo = default.Min or default[1] or self.Min
    local hi = default.Max or default[2] or self.Max
    self.Value = self:_clamp(lo, hi)
    self.Default = table.clone(self.Value)
    return self
end

RangeSlider.Text = Slider.Text

function RangeSlider:_clamp(lo, hi, moving)
    lo = math.clamp(Util.Round(tonumber(lo) or self.Min, self.Step), self.Min, self.Max)
    hi = math.clamp(Util.Round(tonumber(hi) or self.Max, self.Step), self.Min, self.Max)
    if hi - lo < self.Gap then
        if moving == "Max" then
            lo = math.max(self.Min, hi - self.Gap)
            hi = lo + self.Gap
        else
            hi = math.min(self.Max, lo + self.Gap)
            lo = hi - self.Gap
        end
    end
    return { Min = lo, Max = hi }
end

function RangeSlider:_args()
    return self.Value.Min, self.Value.Max
end

-- Set(lo, hi) or Set({ lo, hi })
function RangeSlider:Set(lo, hi, silent, moving)
    if type(lo) == "table" then
        lo, hi, silent = lo.Min or lo[1], lo.Max or lo[2], hi
    end
    local value = self:_clamp(lo, hi, moving)
    if value.Min == self.Value.Min and value.Max == self.Value.Max then return end
    self:_commit(value, silent)
end

function RangeSlider:Reset()
    self:Set(self.Default.Min, self.Default.Max)
end

function RangeSlider:Save()
    return { self.Value.Min, self.Value.Max }
end

function RangeSlider:Load(data)
    if type(data) == "table" then self:Set(data[1] or data.Min, data[2] or data.Max) end
end

function RangeSlider:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    local _, low = Slider.ValueBox(row.Right, self, 1, function() return self.Value.Min end, function(number)
        self:Set(number, self.Value.Max, false, "Min")
    end)
    Util.Label({ Text = "–", TextSize = 11, Color = "TextMuted", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, Parent = row.Right })
    local _, high = Slider.ValueBox(row.Right, self, 3, function() return self.Value.Max end, function(number)
        self:Set(self.Value.Min, number, false, "Max")
    end)

    Util.List(row.Below, 3)
    local track = Slider.Track(row.Below, self, 1)
    local knobLow, scaleLow = Slider.Knob(track.Rail)
    local knobHigh, scaleHigh = Slider.Knob(track.Rail)
    local paintRange = self.Def.ShowRange and Slider.RangeLabels(row.Below, self, 2)

    local dragging = nil
    local function alpha(value)
        local span = self.Max - self.Min
        return span > 0 and (value - self.Min) / span or 0
    end
    local function paint(animate)
        local a, b = alpha(self.Value.Min), alpha(self.Value.Max)
        local time = animate and not dragging and 0.12 or 0
        Util.Tween(track.Fill, time, { Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1) })
        Util.Tween(knobLow, time, { Position = UDim2.fromScale(a, 0.5) })
        Util.Tween(knobHigh, time, { Position = UDim2.fromScale(b, 0.5) })
        if not low:IsA("TextBox") or not low:IsFocused() then low.Text = self:Text(self.Value.Min) end
        if not high:IsA("TextBox") or not high:IsFocused() then high.Text = self:Text(self.Value.Max) end
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
        local a = math.clamp((point.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        return self.Min + (self.Max - self.Min) * a
    end
    local function move(which, value, silent)
        if which == "Min" then
            self:Set(math.min(value, self.Value.Max), self.Value.Max, silent, "Min")
        else
            self:Set(self.Value.Min, math.max(value, self.Value.Min), silent, "Max")
        end
    end
    track.Bar.InputBegan:Connect(function(input)
        if self.Locked or not Util.IsPress(input) then return end
        local value = fromPoint(Util.Pointer(input))
        local which = math.abs(value - self.Value.Min) <= math.abs(value - self.Value.Max) and "Min" or "Max"
        if self.Value.Min == self.Value.Max then which = value < self.Value.Min and "Min" or "Max" end
        dragging = which
        local scale = which == "Min" and scaleLow or scaleHigh
        Util.Tween(scale, 0.1, { Scale = 1.15 })
        move(which, value, not live)
        Drag.Follow(input, function(point)
            move(which, fromPoint(point), not live)
        end, function()
            dragging = nil
            Util.Tween(scale, 0.12, { Scale = 0.85 })
            if not live then self:_notify() end
        end)
    end)
    if track.Minus then
        track.Minus.MouseButton1Click:Connect(function()
            if not self.Locked then self:Set(self.Value.Min - self.Step, self.Value.Max - self.Step) end
        end)
        track.Plus.MouseButton1Click:Connect(function()
            if not self.Locked then self:Set(self.Value.Min + self.Step, self.Value.Max + self.Step) end
        end)
    end
    return row.Frame
end

return RangeSlider
