local import = ...
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Tooltip = import("Components/Tooltip")

-- standard element layout: title (+ description) left, widgets right, optional full-width area below
local Row = {}

-- options: Click (whole top line is a button), Below (create the below area), TopHeight
function Row.new(element, parent, maid, options)
    options = options or {}
    local row = {} :: any

    local frame = maid:Give(Util.New("Frame", {
        Name = element.Kind,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = element.Visible,
        Parent = parent,
    }))
    row.Frame = frame

    local content = Util.New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame,
    })
    Util.List(content, 6)
    row.Content = content

    local top = Util.New("Frame", {
        Name = "Top",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, options.TopHeight or 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = content,
    })
    local topLayout = Util.List(top, 8, Enum.FillDirection.Horizontal)
    topLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    row.Top = top

    local block = Util.New("Frame", {
        Name = "Text",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, options.TopHeight or 20),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = top,
    })
    Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = block })
    Util.List(block, 1)

    local titleLine = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, options.TopHeight or 20),
        LayoutOrder = 1,
        Parent = block,
    })
    Util.List(titleLine, 5, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local title = Util.Label({
        Text = element.Title,
        TextSize = 12,
        Weight = Enum.FontWeight.Medium,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = {
            TextColor3 = function(t)
                if element.Locked then return t.TextMuted end
                -- matches of the running search stand out
                local query = element.Window.Query
                if query and element:Matches(query) then return t.Accent end
                return element.Def.Risky and t.Danger or t.Text
            end,
        },
        LayoutOrder = 1,
        Parent = titleLine,
    })
    Util.New("UISizeConstraint", { MaxSize = Vector2.new(options.TitleMax or 220, math.huge), Parent = title })
    row.Title = title

    local lockIcon = Util.Icon("lock", {
        Size = UDim2.fromOffset(11, 11),
        Color = "TextMuted",
        LayoutOrder = 3,
        Visible = element.Locked,
        Parent = titleLine,
    })

    local info
    if element.Tooltip then
        -- a button: a tap shows the text on touch and does not reach the row's own click
        info = Util.New("ImageButton", {
            Size = UDim2.fromOffset(11, 11),
            Image = Util.IconId("info"),
            ScaleType = Enum.ScaleType.Fit,
            LayoutOrder = 2,
            Theme = { ImageColor3 = "TextMuted" },
            Parent = titleLine,
        })
        maid:Give(Tooltip.Attach(info, function() return element.Tooltip end))
        info.MouseButton1Click:Connect(function() Tooltip.Show(element.Tooltip) end)
    end

    local desc = Util.Label({
        Text = element.Description or "",
        TextSize = 11,
        Color = "TextMuted",
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = element.Description ~= nil and element.Description ~= "",
        LayoutOrder = 2,
        Parent = block,
    })
    row.Description = desc

    local right = Util.New("Frame", {
        Name = "Right",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, options.TopHeight or 20),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
        Parent = top,
    })
    Util.List(right, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    row.Right = right

    if options.Below then
        row.Below = Util.New("Frame", {
            Name = "Below",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = content,
        })
    end

    if options.Click then
        -- sits under the content; labels and frames let presses through
        row.Button = Util.New("TextButton", {
            Name = "Hit",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0,
            Parent = frame,
        })
    end

    local overlay = Util.New("TextButton", {
        Name = "Lock",
        Size = UDim2.new(1, 8, 1, 6),
        Position = UDim2.fromOffset(-4, -3),
        ZIndex = 20,
        Visible = element.Locked,
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = function() return 0.35 end },
        Parent = frame,
    })
    Util.Corner(6, overlay)
    maid:Give(Tooltip.Attach(overlay, function() return element.LockReason or "Locked" end))
    overlay.MouseButton1Click:Connect(function() Tooltip.Show(element.LockReason or "Locked") end)

    local function sync(what)
        if what == nil or what == "Title" then title.Text = element.Title end
        if what == nil or what == "Description" then
            desc.Text = element.Description or ""
            desc.Visible = element.Description ~= nil and element.Description ~= ""
        end
        if what == nil or what == "Locked" then
            overlay.Visible = element.Locked
            lockIcon.Visible = element.Locked
            Theme.Refresh(title, 0.15)
        end
        if what == nil or what == "Visible" then frame.Visible = element.Visible end
        if row.OnState then row.OnState(what) end
    end
    maid:Give(element.StateChanged:Connect(sync))

    return row
end

-- small rounded field used by inputs, dropdowns and value boxes
function Row.Field(parent, props)
    local hover = false
    local focused = false
    local field = Util.New(props.Button and "TextButton" or "Frame", {
        Name = props.Name or "Field",
        Size = props.Size or UDim2.new(1, 0, 0, 28),
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        LayoutOrder = props.LayoutOrder or 0,
        AutomaticSize = props.AutomaticSize,
        Theme = {
            BackgroundColor3 = function(t) return hover and t.ElevatedHover or t.Elevated end,
            BackgroundTransparency = "ElevatedTransparency",
        },
        Parent = parent,
    })
    Util.Corner(props.Radius or 6, field)
    local stroke = Util.Stroke(field, function(t) return focused and t.Accent or t.Stroke end, function(t) return focused and 0.2 or t.StrokeTransparency + 0.1 end)
    Util.Hover(field, function(on) hover = on; Theme.Refresh(field, 0.12) end)
    local api = {}
    function api.SetFocused(on)
        focused = on
        Theme.Refresh(stroke, 0.15)
    end
    function api.SetStroke(token)
        Theme.Bind(stroke, { Color = function(t) return token and t[token] or (focused and t.Accent or t.Stroke) end })
    end
    return field, api
end

return Row
