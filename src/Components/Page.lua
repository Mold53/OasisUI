local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Maid = import("Core/Maid")
local Drag = import("Core/Drag")

-- one or two scrolling columns of module cards; cards can be dragged between them
local Page = {}
Page.__index = Page

local GAP = 10

-- options: Id, Columns (1 | 2), Draggable, Source (cards show their tab), Empty (text), EmptyIcon, Parent
function Page.new(window, options)
    local self = setmetatable({
        Window = window,
        Id = options.Id,
        Draggable = options.Draggable == true,
        Source = options.Source == true,
        Views = {},
        Columns = {},
        _counter = 0,
    }, Page)

    self.Frame = Util.New("Frame", {
        Name = "Page",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = options.Parent or window.Content,
    })

    local count = math.clamp(options.Columns or 2, 1, 2)
    for index = 1, count do
        local column = Util.New("ScrollingFrame", {
            Name = "Column" .. index,
            Size = count == 1 and UDim2.fromScale(1, 1) or UDim2.new(0.5, -GAP / 2, 1, 0),
            Position = index == 1 and UDim2.new() or UDim2.new(0.5, GAP / 2, 0, 0),
            ScrollBarThickness = 2,
            ScrollingEnabled = true,
            Theme = { ScrollBarImageColor3 = "TextMuted" },
            Parent = self.Frame,
        })
        column.ScrollBarImageTransparency = 0.4
        local layout = Util.List(column, GAP)
        Util.Padding(column, 1, 6, 14, 1)
        Util.AutoCanvas(column, layout)
        self.Columns[index] = column
    end

    self.EmptyLabel = Util.Label({
        Text = options.Empty or "",
        TextSize = 12,
        Color = "TextMuted",
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.42),
        Size = UDim2.new(0.8, 0, 0, 40),
        Visible = false,
        Parent = self.Frame,
    })
    self.EmptyIcon = Util.Icon(options.EmptyIcon or "layers", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0.42, -24),
        Size = UDim2.fromOffset(28, 28),
        Color = "TextMuted",
        ImageTransparency = 0.4,
        Visible = false,
        Parent = self.Frame,
    })
    return self
end

function Page:_saved()
    return self.Window.State.Layout[self.Id]
end

function Page:SetEmpty(text)
    self.EmptyLabel.Text = text
end

function Page:UpdateEmpty()
    local empty = #self.Views == 0
    self.EmptyLabel.Visible = empty and self.EmptyLabel.Text ~= ""
    self.EmptyIcon.Visible = self.EmptyLabel.Visible
end

-- side: "Left" | "Right" | 1 | 2 | nil (fewest cards)
function Page:Add(module, side)
    local saved = self:_saved()
    local column, order
    if saved and self.Draggable then
        for index, ids in saved do
            local position = table.find(ids, module.Id)
            if position and self.Columns[index] then
                column, order = index, position
                break
            end
        end
    end
    if not column then
        if side == "Right" or side == 2 then
            column = 2
        elseif side == "Left" or side == 1 then
            column = 1
        else
            local counts = {}
            for index in self.Columns do counts[index] = 0 end
            for _, view in self.Views do counts[view.Column] = (counts[view.Column] or 0) + 1 end
            column = 1
            for index, count in counts do
                if count < counts[column] then column = index end
            end
        end
        column = math.min(column, #self.Columns)
        self._counter += 1
        order = 10000 + self._counter
    end

    local maid = Maid.new()
    local view = { Module = module, Page = self, Column = column, Maid = maid, Source = self.Source }
    local card = module:Render(self.Columns[column], maid, view)
    card.LayoutOrder = order
    view.Card = card
    table.insert(self.Views, view)
    self:UpdateEmpty()
    return view
end

function Page:Find(module)
    for index, view in self.Views do
        if view.Module == module then return view, index end
    end
    return nil
end

function Page:Remove(module)
    local view, index = self:Find(module)
    if not view then return end
    table.remove(self.Views, index)
    view.Maid:Clean()
    self:UpdateEmpty()
end

function Page:Clear()
    for _, view in self.Views do view.Maid:Clean() end
    table.clear(self.Views)
    self:UpdateEmpty()
end

local function sorted(page, column)
    local list = {}
    for _, view in page.Views do
        if view.Column == column then table.insert(list, view) end
    end
    table.sort(list, function(a, b) return a.Card.LayoutOrder < b.Card.LayoutOrder end)
    return list
end

function Page:SaveLayout()
    if not self.Draggable then return end
    local layout = {}
    for index in self.Columns do
        layout[index] = {}
        for position, view in sorted(self, index) do
            view.Card.LayoutOrder = position
            table.insert(layout[index], view.Module.Id)
        end
    end
    self.Window.State.Layout[self.Id] = layout
    self.Window:SaveState()
end

function Page:MoveToOther(view)
    local target = view.Column == 1 and 2 or 1
    if not self.Columns[target] then return end
    view.Column = target
    view.Card.Parent = self.Columns[target]
    view.Card.LayoutOrder = 1e6
    self:SaveLayout()
end

function Page:ResetLayout()
    self.Window.State.Layout[self.Id] = nil
    local modules = {}
    for _, view in self.Views do table.insert(modules, view.Module) end
    self:Clear()
    self._counter = 0
    for _, module in modules do self:Add(module, not self.Source and module.Def.Side or nil) end
    self.Window:SaveState()
end

-- drag a card by its grip; a placeholder marks where it lands
function Page:BeginDrag(view, input)
    if self.Dragging then return end
    local card = view.Card
    local window = self.Window
    local start = Util.Pointer(input)
    local started = false
    local placeholder, ghostOffset, autoscroll
    local target = view.Column

    local function columnAt(point)
        local best, distance = nil, math.huge
        for index, column in self.Columns do
            local left, width = column.AbsolutePosition.X, column.AbsoluteSize.X
            local d = point.X < left and left - point.X or (point.X > left + width and point.X - left - width or 0)
            if d < distance then best, distance = index, d end
        end
        return best
    end

    local function place(point)
        target = columnAt(point)
        local column = self.Columns[target]
        if placeholder.Parent ~= column then placeholder.Parent = column end
        -- even orders for the cards, the odd slot after the last card above the pointer
        local above = 0
        local position = 0
        for _, other in sorted(self, target) do
            if other ~= view then
                position += 1
                other.Card.LayoutOrder = position * 2
                local middle = other.Card.AbsolutePosition.Y + other.Card.AbsoluteSize.Y / 2
                if point.Y > middle then above = position end
            end
        end
        placeholder.LayoutOrder = above * 2 + 1
    end

    local function begin()
        started = true
        self.Dragging = true
        local scale = window:GetScale()
        placeholder = Util.New("Frame", {
            Name = "Placeholder",
            Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y / scale),
            LayoutOrder = card.LayoutOrder,
            Theme = { BackgroundColor3 = "Accent", BackgroundTransparency = function() return 0.88 end },
            Parent = card.Parent,
        })
        Util.Corner("ElementRadius", placeholder)
        Util.Stroke(placeholder, "Accent", function() return 0.45 end)
        ghostOffset = (start - card.AbsolutePosition) / scale
        local width = card.AbsoluteSize.X / scale
        card.Parent = window.DragLayer
        card.Size = UDim2.fromOffset(width, 0)
        autoscroll = Services.RunService.Heartbeat:Connect(function()
            local point = Util.Pointer()
            local column = self.Columns[target]
            if not column then return end
            local top, bottom = column.AbsolutePosition.Y, column.AbsolutePosition.Y + column.AbsoluteSize.Y
            if point.Y < top + 36 then
                column.CanvasPosition -= Vector2.new(0, 9)
            elseif point.Y > bottom - 36 then
                column.CanvasPosition += Vector2.new(0, 9)
            end
        end)
    end

    Drag.Follow(input, function(point)
        if not started then
            if (point - start).Magnitude < 5 then return end
            begin()
        end
        local layer = window.DragLayer.AbsolutePosition
        local scale = window:GetScale()
        card.Position = UDim2.fromOffset((point.X - layer.X) / scale - ghostOffset.X, (point.Y - layer.Y) / scale - ghostOffset.Y)
        place(point)
    end, function()
        if not started then return end
        self.Dragging = false
        if autoscroll then autoscroll:Disconnect() end
        view.Column = target
        card.Parent = self.Columns[target]
        card.Position = UDim2.new()
        card.Size = UDim2.new(1, 0, 0, 0)
        card.LayoutOrder = placeholder.LayoutOrder
        placeholder:Destroy()
        self:SaveLayout()
    end)
end

return Page
