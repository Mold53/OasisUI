local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Layer = import("Components/Layer")

local Notification = { Position = "BottomRight", Max = 5 }
local holder, layout

local KINDS = {
    Info    = { Color = "Accent", Icon = "info" },
    Success = { Color = "Success", Icon = "circle-check" },
    Warning = { Color = "Warning", Icon = "triangle-alert" },
    Error   = { Color = "Danger", Icon = "circle-x" },
}

local CORNERS = {
    BottomRight = { Vector2.new(1, 1), UDim2.new(1, -14, 1, -14), Enum.VerticalAlignment.Bottom, 1 },
    TopRight    = { Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), Enum.VerticalAlignment.Top, 1 },
    BottomLeft  = { Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), Enum.VerticalAlignment.Bottom, -1 },
    TopLeft     = { Vector2.new(0, 0), UDim2.new(0, 14, 0, 14), Enum.VerticalAlignment.Top, -1 },
}

local function ensure()
    if holder and holder.Parent then return end
    holder = Util.New("Frame", {
        Name = "Toasts",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 1, -28),
        ZIndex = 150,
        Parent = Layer.Root,
    })
    layout = Util.List(holder, 8)
    Notification.SetPosition(Notification.Position)
end

function Notification.SetPosition(name)
    local corner = CORNERS[name] or CORNERS.BottomRight
    Notification.Position = CORNERS[name] and name or "BottomRight"
    if not holder then return end
    holder.AnchorPoint = corner[1]
    holder.Position = corner[2]
    layout.VerticalAlignment = corner[3]
end

-- options: Title, Content, Type (Info|Success|Warning|Error), Icon, Duration, Buttons = { { Title, Callback } }
function Notification.Notify(options)
    ensure()
    options = type(options) == "string" and { Title = options } or options
    local kind = KINDS[options.Type or "Info"] or KINDS.Info
    local duration = options.Duration or 5
    local side = CORNERS[Notification.Position][4]

    local toasts = {}
    for _, child in holder:GetChildren() do
        if child:IsA("Frame") then table.insert(toasts, child) end
    end
    if #toasts >= Notification.Max then
        table.sort(toasts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        toasts[1]:Destroy()
    end

    local wrapper = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = math.floor(os.clock() * 1000),
        ZIndex = 150,
        Parent = holder,
    })
    local card = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(side * 330, 0),
        ZIndex = 151,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency, 0.08) end,
        },
        Parent = wrapper,
    })
    Util.Corner("ElementRadius", card)
    Util.Stroke(card)

    Util.New("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        ZIndex = 152,
        Theme = { BackgroundColor3 = kind.Color },
        Parent = card,
    }, { Util.Corner(2) })
    Util.Icon(options.Icon or kind.Icon, {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(21, 12),
        Color = kind.Color,
        ZIndex = 152,
        Parent = card,
    })

    local body = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 152,
        Parent = card,
    })
    Util.Padding(body, 11, 30, 13, 46)
    Util.List(body, 3)
    Util.Label({
        Text = options.Title or "Notification",
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, 0, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
        ZIndex = 153,
        Parent = body,
    })
    if options.Content and options.Content ~= "" then
        Util.Label({
            Text = options.Content,
            TextSize = 12,
            Color = "TextDim",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            RichText = true,
            LayoutOrder = 2,
            ZIndex = 153,
            Parent = body,
        })
    end

    local progress = Util.New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -3),
        Size = UDim2.new(1, -20, 0, 2),
        ZIndex = 153,
        Theme = { BackgroundColor3 = kind.Color, BackgroundTransparency = function() return 0.35 end },
        Parent = card,
    }, { Util.Corner(1) })

    local closed = false
    local handle = {}
    function handle:Close()
        if closed then return end
        closed = true
        Util.Tween(card, 0.35, { Position = UDim2.fromOffset(side * 330, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.36 / math.max(Theme.Current.AnimSpeed or 1, 0.05), function() wrapper:Destroy() end)
    end

    if options.Buttons and #options.Buttons > 0 then
        local row = Util.New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            LayoutOrder = 3,
            ZIndex = 153,
            Parent = body,
        })
        Util.List(row, 6, Enum.FillDirection.Horizontal)
        for index, spec in options.Buttons do
            local button = Util.New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 22),
                LayoutOrder = index,
                ZIndex = 154,
                Theme = {
                    BackgroundColor3 = index == 1 and "Accent" or "ElevatedHover",
                    TextColor3 = index == 1 and "OnAccent" or "Text",
                    FontFace = Theme.Font(Enum.FontWeight.Medium),
                },
                Text = spec.Title,
                TextSize = 11,
                Parent = row,
            })
            Util.Corner(5, button)
            Util.Padding(button, 0, 10, 0, 10)
            button.MouseButton1Click:Connect(function()
                Util.Safe(spec.Callback)
                handle:Close()
            end)
        end
    end

    local close = Util.New("ImageButton", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new(1, -22, 0, 13),
        Image = Util.IconId("x"),
        ZIndex = 154,
        Theme = { ImageColor3 = "TextMuted" },
        Parent = card,
    })
    close.MouseButton1Click:Connect(function() handle:Close() end)

    Util.Tween(card, 0.45, { Position = UDim2.fromOffset(0, 0) })

    if duration ~= math.huge and duration > 0 then
        local hovered = false
        card.MouseEnter:Connect(function() hovered = true end)
        card.MouseLeave:Connect(function() hovered = false end)
        task.spawn(function()
            local left = duration
            while left > 0 and not closed and wrapper.Parent do
                local dt = Services.RunService.Heartbeat:Wait()
                if not hovered then
                    left -= dt
                    progress.Size = UDim2.new(math.max(left / duration, 0), -20 * math.max(left / duration, 0), 0, 2)
                end
            end
            handle:Close()
        end)
    else
        progress.Visible = false
    end
    return handle
end

return Notification
