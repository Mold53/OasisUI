local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- def: Text (optional caption between two fading lines)
local Divider = Base.Class("Divider")

function Divider.new(container, def)
    local self = setmetatable({}, Divider)
    Base.Init(self, container, def)
    self.Title = def.Text or def.Title
    self.NoSave = true
    return self
end

function Divider:Matches()
    return false
end

local function line(parent, flip, order)
    local frame = Util.New("Frame", {
        Size = UDim2.new(0, 0, 0, 1),
        LayoutOrder = order,
        Theme = { BackgroundColor3 = "Divider" },
        Parent = parent,
    })
    Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = frame })
    Util.New("UIGradient", {
        Transparency = flip and NumberSequence.new(0, 1) or NumberSequence.new(1, 0),
        Parent = frame,
    })
    return frame
end

function Divider:Render(parent, maid)
    local frame = maid:Give(Util.New("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, self.Title and 16 or 7),
        Visible = self.Visible,
        Parent = parent,
    }))
    Util.List(frame, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    if self.Title then
        line(frame, false, 1)
        Util.Label({
            Text = self.Title,
            TextSize = 10,
            Color = "TextMuted",
            Weight = Enum.FontWeight.SemiBold,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            LayoutOrder = 2,
            Parent = frame,
        })
        line(frame, true, 3)
    else
        local single = line(frame, false, 1)
        single:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
    end
    maid:Give(self.StateChanged:Connect(function() frame.Visible = self.Visible end))
    return frame
end

return Divider
