local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Services = import("Core/Services")

local TextService = Services.TextService

-- def: Text, Value (right aligned text), Color (token), ValueColor (token | Color3), Size, RichText;
--      Set(text), SetValue(text), SetValueColor(token | Color3 | nil)
local Label = Base.Class("Label")

function Label.new(container, def)
    local self = setmetatable({}, Label)
    Base.Init(self, container, def)
    self.Title = def.Text or def.Title or ""
    self.Value = def.Value
    self.ValueColor = def.ValueColor
    self.NoSave = true
    return self
end

function Label:SetValueColor(color)
    if color == self.ValueColor then return end
    self.ValueColor = color
    self.StateChanged:Fire("ValueColor")
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
        Theme = { TextColor3 = function(t)
            local color = self.ValueColor
            if typeof(color) == "Color3" then return color end
            return t[color or "Text"] or t.Text
        end },
        Weight = Enum.FontWeight.SemiBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = frame,
    })
    -- the value takes what the title leaves on its line (at least 40 %), a longer one ends in "…"
    local limit = Util.New("UISizeConstraint", { Parent = value })

    -- the title's one-line width in offset units, measured once per text and font
    local measured, titleWidth = nil, 0
    local paint
    local function measure()
        local key = self.Title .. "|" .. tostring(text.FontFace) .. "|" .. text.TextSize
        if key == measured then return end
        measured = key
        task.spawn(function()
            local params = Instance.new("GetTextBoundsParams")
            params.Text = self.Title ~= "" and self.Title or " "
            params.Font = text.FontFace
            params.Size = text.TextSize
            params.Width = math.huge
            pcall(function() params.RichText = text.RichText end)
            local ok, bounds = pcall(TextService.GetTextBoundsAsync, TextService, params)
            if ok and measured == key then
                titleWidth = math.ceil(bounds.X)
                paint()
            end
        end)
    end

    paint = function()
        text.Text = self.Title
        value.Text = self.Value or ""
        value.Visible = self.Value ~= nil
        if self.Value then
            measure()
            local width = frame.AbsoluteSize.X / math.max(Util.ScaleOf(frame), 0.01)
            local room = math.max(width - titleWidth - 10, width * 0.4)
            if width > 0 and limit.MaxSize.X ~= room then limit.MaxSize = Vector2.new(room, math.huge) end
        end
        text.Size = UDim2.new(1, self.Value and -(value.AbsoluteSize.X / math.max(Util.ScaleOf(value), 0.01) + 10) or 0, 0, 0)
        frame.Visible = self.Visible
        Theme.Refresh(value)
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(paint))
    maid:Give(value:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint))
    maid:Give(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(paint))
    return frame
end

return Label
