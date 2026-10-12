local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Row = import("Components/Row")

-- def: Title, Value, Max (default 100), Suffix, Format(value, max) -> text, Color (token, default Accent)
local ProgressBar = Base.Class("ProgressBar")

function ProgressBar.new(container, def)
    local self = setmetatable({}, ProgressBar)
    Base.Init(self, container, def)
    self.Max = def.Max or 100
    self.Value = math.clamp(def.Value or def.Default or 0, 0, self.Max)
    self.NoSave = true
    return self
end

function ProgressBar:Set(value)
    value = math.clamp(tonumber(value) or 0, 0, self.Max)
    if value == self.Value then return end
    self.Value = value
    self.Changed:Fire(value)
end

function ProgressBar:SetMax(max)
    self.Max = math.max(max, 0.0001)
    self:Set(self.Value)
    self.Changed:Fire(self.Value)
end

function ProgressBar:Text()
    if self.Def.Format then
        local ok, text = pcall(self.Def.Format, self.Value, self.Max)
        if ok then return tostring(text) end
    end
    if self.Def.Suffix then return Util.Format(self.Value, 0.1):gsub("%.0$", "") .. self.Def.Suffix end
    return math.floor(self.Value / self.Max * 100 + 0.5) .. "%"
end

function ProgressBar:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    local value = Util.Label({
        TextSize = 11,
        Color = "TextDim",
        Weight = Enum.FontWeight.SemiBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        Parent = row.Right,
    })
    local rail = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = row.Below,
    })
    Util.Corner(UDim.new(1, 0), rail)
    local fill = Util.New("Frame", {
        Size = UDim2.fromScale(0, 1),
        Theme = { BackgroundColor3 = self.Def.Color or "Accent" },
        Parent = rail,
    })
    Util.Corner(UDim.new(1, 0), fill)
    local function paint(animate)
        value.Text = self:Text()
        Util.Tween(fill, animate and 0.25 or 0, { Size = UDim2.fromScale(self.Max > 0 and self.Value / self.Max or 0, 1) })
    end
    paint(false)
    maid:Give(self.Changed:Connect(function() paint(true) end))
    return row.Frame
end

return ProgressBar
