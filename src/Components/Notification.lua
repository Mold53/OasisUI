local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Layer = import("Components/Layer")

-- Scale multiplies every duration (Settings > Notifications); Max is how many show at once
local Notification = { Position = "BottomRight", Max = 5, Scale = 1 }
local holder, layout
local live = {}                                   -- Id -> handle while it is on screen

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

-- oldest first past Max
local function trim(keep)
    local toasts = {}
    for _, child in holder:GetChildren() do
        if child:IsA("Frame") and child ~= keep then table.insert(toasts, child) end
    end
    table.sort(toasts, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    for i = 1, #toasts - math.max(Notification.Max - 1, 0) do toasts[i]:Destroy() end
end

-- the look an update can change: kind (colour, icon) or explicit Color / Icon
local function look(options)
    local kind = KINDS[options.Type or "Info"] or KINDS.Info
    return options.Color or kind.Color, options.Icon or kind.Icon
end

-- options: Title, Content, Type (Info|Success|Warning|Error), Icon, Color (theme token or Color3), Duration,
--          Id (a toast with the same Id still on screen is updated in place: text, look and a fresh timer),
--          Buttons = { { Title, Callback } }
function Notification.Notify(options)
    ensure()
    options = type(options) == "string" and { Title = options } or options
    local current = options.Id ~= nil and live[options.Id]
    if current then
        current:Update(options)
        return current
    end
    trim()
    local side = CORNERS[Notification.Position][4]
    local state = {}
    state.Color, state.Icon = look(options)
    local function tint(t)
        return typeof(state.Color) == "Color3" and state.Color or t[state.Color] or t.Accent
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

    local bar = Util.New("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        ZIndex = 152,
        Theme = { BackgroundColor3 = tint },
        Parent = card,
    }, { Util.Corner(2) })
    local icon = Util.Icon(state.Icon, {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(21, 12),
        Theme = { ImageColor3 = tint },
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
    local title = Util.Label({
        Text = options.Title or "Notification",
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, 0, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 1,
        ZIndex = 153,
        Parent = body,
    })
    local content = Util.Label({
        Text = options.Content or "",
        TextSize = 12,
        Color = "TextDim",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        RichText = true,
        Visible = options.Content ~= nil and options.Content ~= "",
        LayoutOrder = 2,
        ZIndex = 153,
        Parent = body,
    })

    local progress = Util.New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -3),
        Size = UDim2.new(1, -20, 0, 2),
        ZIndex = 153,
        Theme = { BackgroundColor3 = tint, BackgroundTransparency = function() return 0.35 end },
        Parent = card,
    }, { Util.Corner(1) })

    local closed = false
    local handle = { Id = options.Id }
    -- seconds left and the full span, restarted by Update
    local duration, left = 0, 0
    local function arm(seconds)
        seconds = seconds or 5
        duration = (seconds == math.huge or seconds <= 0) and seconds or seconds * Notification.Scale
        left = duration
        progress.Visible = duration ~= math.huge and duration > 0
        progress.Size = UDim2.new(1, -20, 0, 2)
    end
    arm(options.Duration)
    if options.Id ~= nil then live[options.Id] = handle end

    function handle:Close()
        if closed then return end
        closed = true
        if options.Id ~= nil and live[options.Id] == handle then live[options.Id] = nil end
        Util.Tween(card, 0.35, { Position = UDim2.fromOffset(side * 330, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.36 / math.max(Theme.Current.AnimSpeed or 1, 0.05), function() wrapper:Destroy() end)
    end

    -- same toast, new text and look; the timer starts over
    function handle:Update(patch)
        if closed then return end
        if patch.Title then title.Text = patch.Title end
        if patch.Content ~= nil then
            content.Text = patch.Content
            content.Visible = patch.Content ~= ""
        end
        if patch.Type or patch.Color or patch.Icon then
            state.Color, state.Icon = look(patch)
            icon.Image = Util.IconId(state.Icon)
            Theme.Refresh(bar, 0.15)
            Theme.Refresh(icon, 0.15)
            Theme.Refresh(progress, 0.15)
        end
        arm(patch.Duration or options.Duration)
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
            local style = spec.Style or (index == 1 and "Primary" or "Secondary")
            local hover = { Hover = false }
            local button = Util.New("TextButton", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 22),
                LayoutOrder = index,
                ZIndex = 154,
                Theme = {
                    BackgroundColor3 = function(t)
                        local base = style == "Primary" and t.Accent or (style == "Danger" and t.Danger or t.ElevatedHover)
                        return hover.Hover and base:Lerp(t.Text, 0.12) or base
                    end,
                    TextColor3 = (style == "Primary" or style == "Danger") and "OnAccent" or "Text",
                    FontFace = Theme.Font(Enum.FontWeight.Medium),
                },
                Text = spec.Title,
                TextSize = 11,
                Parent = row,
            })
            Util.Corner(5, button)
            Util.Padding(button, 0, 10, 0, 10)
            Util.Feedback(button, hover)
            button.MouseButton1Click:Connect(function()
                Util.Safe(spec.Callback)
                if spec.KeepOpen ~= true then handle:Close() end
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

    local hovered = false
    Util.Hover(card, function(on) hovered = on end)
    task.spawn(function()
        while not closed and wrapper.Parent do
            local dt = Services.RunService.Heartbeat:Wait()
            if not hovered and duration ~= math.huge and duration > 0 then
                left -= dt
                local share = math.max(left / duration, 0)
                progress.Size = UDim2.new(share, -20 * share, 0, 2)
                if left <= 0 then break end
            end
        end
        handle:Close()
    end)
    return handle
end

return Notification
