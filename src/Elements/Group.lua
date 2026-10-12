local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Container = import("Components/Container")

-- collapsible sub-list inside a module; holds elements like a module does
-- def: Title, Description, Icon, Opened (default false)
local Group = Base.Class("Group")
Container.Apply(Group)

function Group.new(container, def)
    local self = setmetatable({}, Group)
    Base.Init(self, container, def)
    Container.Setup(self)
    self.Module = container.Module or container
    self.Opened = def.Opened == true or def.Open == true
    self.NoSave = true
    return self
end

function Group:_add(kind, a, b)
    local element = Container._add(self, kind, a, b)
    self.StateChanged:Fire("Children")
    return element
end

function Group:SetOpened(opened)
    self.Opened = opened and true or false
    self.StateChanged:Fire("Opened")
end

function Group:Matches(query)
    return Base.Matches(self, query) or self:_matchesChildren(query)
end

function Group:Destroy()
    for _, child in table.clone(self.Children) do child:Destroy() end
    Base.Destroy(self)
end

function Group:Render(parent, maid)
    local frame = maid:Give(Util.New("Frame", {
        Name = "Group",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Parent = parent,
    }))
    Util.List(frame, 6)

    local hover = false
    local head = Util.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 1,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t) return hover and t.ElevatedTransparency or 1 end,
        },
        Parent = frame,
    })
    Util.Corner(5, head)
    -- an image swap: Rotation does not render inside the clipping columns
    local chevron = Util.Icon(self.Opened and "chevron-down" or "chevron-right", {
        Size = UDim2.fromOffset(13, 13),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 9, 0.5, 0),
        Color = "TextMuted",
        Parent = head,
    })
    local x = 20
    if self.Def.Icon then
        Util.Icon(self.Def.Icon, { Size = UDim2.fromOffset(13, 13), Position = UDim2.new(0, 20, 0.5, -6), Color = "Accent", Parent = head })
        x = 39
    end
    local title = Util.Label({
        Text = self.Title,
        TextSize = 12,
        Weight = Enum.FontWeight.SemiBold,
        Color = "TextDim",
        Size = UDim2.new(1, -x - 30, 1, 0),
        Position = UDim2.fromOffset(x, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    local count = Util.Label({
        TextSize = 10,
        Color = "TextMuted",
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -36, 0, 0),
        Parent = head,
    })

    local body = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Opened,
        LayoutOrder = 2,
        Parent = frame,
    })
    Util.New("Frame", {
        Size = UDim2.new(0, 1, 1, -4),
        Position = UDim2.fromOffset(8, 2),
        Theme = { BackgroundColor3 = "Divider" },
        Parent = body,
    })
    local list = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -18, 0, 0),
        Position = UDim2.fromOffset(18, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = body,
    })
    Util.List(list, 8)
    Util.Padding(list, 2, 0, 4, 0)
    self:_mountChildren(list, maid)

    local function paint(animate)
        title.Text = self.Title
        body.Visible = self.Opened
        count.Text = tostring(#self.Children)
        count.Visible = not self.Opened
        chevron.Image = Util.IconId(self.Opened and "chevron-down" or "chevron-right")
        frame.Visible = self.Visible
    end
    paint(false)
    maid:Give(self.StateChanged:Connect(function() paint(true) end))
    Util.Hover(head, function(on) hover = on; Theme.Refresh(head, 0.1) end)
    head.MouseButton1Click:Connect(function() self:SetOpened(not self.Opened) end)
    return frame
end

return Group
