local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- def: Title, Content, Icon; Set({ Title, Content }) or SetContent(text)
local Paragraph = Base.Class("Paragraph")

function Paragraph.new(container, def)
    local self = setmetatable({}, Paragraph)
    Base.Init(self, container, def)
    self.Title = def.Title or ""
    self.Value = def.Content or def.Text or ""
    self.NoSave = true
    return self
end

function Paragraph:Set(data)
    if type(data) == "table" then
        if data.Title then self.Title = data.Title end
        self.Value = data.Content or self.Value
    else
        self.Value = tostring(data)
    end
    self.Changed:Fire(self.Value)
end

function Paragraph:SetContent(text)
    self:Set(tostring(text))
end

function Paragraph:Matches(query)
    return Base.Matches(self, query) or tostring(self.Value):lower():find(query, 1, true) ~= nil
end

function Paragraph:Render(parent, maid)
    local box = maid:Give(Util.New("Frame", {
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency + 0.2, 0.9) end },
        Parent = parent,
    }))
    Util.Corner(6, box)
    if self.Def.Icon then
        Util.Icon(self.Def.Icon, { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(11, 10), Color = "Accent", Parent = box })
    end
    local content = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = box,
    })
    Util.Padding(content, 9, 10, 10, self.Def.Icon and 32 or 10)
    Util.List(content, 3)
    local title = Util.Label({
        Text = self.Title,
        TextSize = 12,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        LayoutOrder = 1,
        Parent = content,
    })
    local body = Util.Label({
        Text = self.Value,
        TextSize = 11,
        Color = "TextDim",
        RichText = true,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = content,
    })
    local function paint()
        title.Text = self.Title
        title.Visible = self.Title ~= ""
        body.Text = self.Value
        body.Visible = self.Value ~= ""
        box.Visible = self.Visible
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(paint))
    return box
end

return Paragraph
