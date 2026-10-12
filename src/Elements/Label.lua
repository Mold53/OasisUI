local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- def: Text, Value (right aligned text), Color (token), Size, RichText; Set(text), SetValue(text)
local Label = Base.Class("Label")

function Label.new(container, def)
    local self = setmetatable({}, Label)
    Base.Init(self, container, def)
    self.Title = def.Text or def.Title or ""
    self.Value = def.Value
    self.NoSave = true
    return self
end

function Label:Set(text)
    self:SetTitle(tostring(text))
end

function Label:SetValue(text)
    self.Value = text ~= nil and tostring(text) or nil
    self.Changed:Fire(self.Value)
end

function Label:Render(parent, maid)
    local frame = maid:Give(Util.New("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Parent = parent,
    }))
    local text = Util.Label({
        Text = self.Title,
        TextSize = self.Def.Size or 12,
        Color = self.Def.Color or "TextDim",
        RichText = self.Def.RichText ~= false,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })
    local value = Util.Label({
        TextSize = self.Def.Size or 12,
        Color = "Text",
        Weight = Enum.FontWeight.SemiBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = frame,
    })
    local function paint()
        text.Text = self.Title
        value.Text = self.Value or ""
        value.Visible = self.Value ~= nil
        text.Size = UDim2.new(1, self.Value and -(value.AbsoluteSize.X + 10) or 0, 0, 0)
        frame.Visible = self.Visible
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(paint))
    maid:Give(value:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint))
    return frame
end

return Label
