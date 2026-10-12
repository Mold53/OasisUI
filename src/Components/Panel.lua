local import = ...
local Util = import("Core/Util")
local Maid = import("Core/Maid")
local Drag = import("Core/Drag")
local Layer = import("Components/Layer")
local Container = import("Components/Container")
local Tooltip = import("Components/Tooltip")

-- small floating window that holds elements; Hud panels stay visible while the menu is hidden
-- def: Title, Icon, Id, Size (Vector2 | UDim2), Position (UDim2), Closable, Collapsible, Resizable, Hud, Visible
local Panel = {}
Panel.__index = Panel
Container.Apply(Panel)

local HEAD = 34

function Panel.new(window, def)
    local self = setmetatable({
        Window = window,
        Def = def,
        Kind = "Panel",
        Title = def.Title or "Panel",
        Id = def.Id or def.Title or "Panel",
        Visible = def.Visible ~= false,
        Collapsed = false,
        Maid = Maid.new(),
    }, Panel)
    Container.Setup(self)
    self.Module = self
    window.Maid:Give(self.Maid)

    local size = def.Size or Vector2.new(260, 320)
    if typeof(size) == "Vector2" then size = UDim2.fromOffset(size.X, size.Y) end
    self.Size = size
    local frame = self.Maid:Give(Util.New("Frame", {
        Name = "Panel",
        Size = size,
        ClipsDescendants = true,
        Active = true,
        Visible = false,
        Theme = { BackgroundColor3 = "Background", BackgroundTransparency = function(t) return math.min(t.WindowTransparency, 0.15) end },
        Parent = def.Hud and Layer.Hud or Layer.Main,
    }))
    self.Frame = frame
    Util.Corner("Radius", frame)
    Util.Stroke(frame)
    self.UIScale = Util.New("UIScale", { Scale = def.Hud and 1 or window:GetScale(), Parent = frame })

    local saved = window.Interface.Panels[self.Id]
    if type(saved) == "table" then
        frame.Position = UDim2.fromOffset(saved[1], saved[2])
    elseif def.Position then
        frame.Position = def.Position
    else
        -- next to the window: right side if it fits, else left, always on screen
        local root, bounds = window.Root, Layer.Bounds()
        local scale = self.UIScale.Scale
        local width, height = size.X.Offset * scale, size.Y.Offset * scale
        local x = root.AbsolutePosition.X + root.AbsoluteSize.X + 12
        if x + width > bounds.X - 8 then x = root.AbsolutePosition.X - width - 12 end
        x = math.clamp(x, 8, math.max(8, bounds.X - width - 8))
        local y = math.clamp(root.AbsolutePosition.Y, 8, math.max(8, bounds.Y - height - 8))
        frame.Position = UDim2.fromOffset(x, y)
    end

    local head = Util.New("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEAD), Parent = frame })
    local x = 12
    if def.Icon then
        Util.Icon(def.Icon, { Size = UDim2.fromOffset(15, 15), Position = UDim2.new(0, 12, 0.5, -7), Color = "Accent", Parent = head })
        x = 34
    end
    self.TitleLabel = Util.Label({
        Text = self.Title,
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        Position = UDim2.fromOffset(x, 0),
        Size = UDim2.new(1, -x - 60, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    local actions = Util.New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 22),
        Parent = head,
    })
    Util.List(actions, 2, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local function action(icon, order, tip, fn)
        local state = { Hover = false }
        local button = Util.New("ImageButton", {
            Size = UDim2.fromOffset(22, 22),
            LayoutOrder = order,
            Theme = { BackgroundColor3 = "ElevatedHover", BackgroundTransparency = function() return state.Hover and 0.3 or 1 end },
            Parent = actions,
        })
        Util.Corner(5, button)
        local image = Util.Icon(icon, { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(5, 5), Color = "TextDim", Parent = button })
        Util.Feedback(button, state)
        self.Maid:Give(Tooltip.Attach(button, tip))
        button.MouseButton1Click:Connect(fn)
        return button, image
    end
    if def.Collapsible ~= false then
        local _, image
        _, image = action("chevron-up", 1, "Collapse", function()
            self:SetCollapsed(not self.Collapsed)
            image.Image = Util.IconId(self.Collapsed and "chevron-down" or "chevron-up")
        end)
    end
    if def.Closable ~= false then
        action("x", 2, "Close", function() self:SetVisible(false) end)
    end
    local rule = Util.New("Frame", { Position = UDim2.fromOffset(10, HEAD), Size = UDim2.new(1, -20, 0, 1), Theme = { BackgroundColor3 = "Divider" }, Parent = frame })
    Util.New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = rule })

    local body = Util.New("ScrollingFrame", {
        Name = "Body",
        Position = UDim2.fromOffset(0, HEAD + 1),
        Size = UDim2.new(1, 0, 1, -HEAD - 1),
        ScrollBarThickness = 2,
        Theme = { ScrollBarImageColor3 = "TextMuted" },
        Parent = frame,
    })
    Util.Padding(body, 10, 12, 12, 12)
    Util.AutoCanvas(body, Util.List(body, 9))
    self.Body = body
    self:_mountChildren(body, self.Maid)

    self.Maid:Give(Drag.Attach(head, frame, {
        Enabled = function() return not Util.Contains(actions, Util.Pointer()) end,
        OnEnd = function(moved)
            if not moved then return end
            window.Interface.Panels[self.Id] = { math.floor(frame.AbsolutePosition.X), math.floor(frame.AbsolutePosition.Y) }
            frame.Position = UDim2.fromOffset(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
            window:SaveState()
        end,
    }))

    if def.Resizable then
        local grip = Util.New("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 10, Parent = frame })
        Util.Icon("grip-vertical", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(2, 2), Rotation = 45, Color = "TextMuted", Parent = grip })
        grip.InputBegan:Connect(function(input)
            if not Util.IsPress(input) or self.Collapsed then return end
            local origin = frame.AbsoluteSize / self.UIScale.Scale
            Drag.Follow(input, function(_, delta)
                local scale = self.UIScale.Scale
                frame.Size = UDim2.fromOffset(math.max(origin.X + delta.X / scale, 180), math.max(origin.Y + delta.Y / scale, 120))
            end, function()
                self.Size = frame.Size
            end)
        end)
    end

    self:SetVisible(self.Visible)
    return self
end

function Panel:_add(kind, a, b)
    return Container._add(self, kind, a, b)
end

function Panel:Matches(query)
    return self:_matchesChildren(query)
end

function Panel:_shown()
    return self.Visible and (self.Def.Hud or self.Window.Visible)
end

function Panel:SetVisible(visible)
    self.Visible = visible and true or false
    self.Frame.Visible = self:_shown()
end

function Panel:Show() self:SetVisible(true) end
function Panel:Hide() self:SetVisible(false) end
function Panel:ToggleVisible() self:SetVisible(not self.Visible) end

function Panel:SetCollapsed(collapsed)
    self.Collapsed = collapsed and true or false
    Util.Tween(self.Frame, 0.25, { Size = self.Collapsed and UDim2.new(self.Size.X, UDim.new(0, HEAD)) or self.Size })
end

function Panel:SetTitle(text)
    self.Title = text
    self.TitleLabel.Text = text
end

function Panel:Destroy()
    for _, child in table.clone(self.Children) do child:Destroy() end
    local index = table.find(self.Window.Panels, self)
    if index then table.remove(self.Window.Panels, index) end
    self.Maid:Clean()
end

return Panel
