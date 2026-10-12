local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Maid = import("Core/Maid")

-- modal over a window; a button callback returning false keeps the dialog open
local Dialog = {}

local STYLES = {
    Primary   = { Bg = "Accent", Text = "OnAccent" },
    Secondary = { Bg = "ElevatedHover", Text = "Text" },
    Danger    = { Bg = "Danger", Text = "OnAccent" },
}

-- options: Title, Content, Icon, Width, OnClose,
--          Input = { Placeholder, Default, Multiline, Height, Monospace, ReadOnly },
--          Buttons = { { Title, Style, Callback(text, dialog) } }
function Dialog.Open(root, options)
    local maid = Maid.new()
    local handle = {}
    local closed = false

    local shade = maid:Give(Util.New("TextButton", {
        Name = "Shade",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 80,
        Parent = root,
    }))
    Util.Corner("Radius", shade)

    -- never wider or taller than the window it covers
    local inner = root.AbsoluteSize / math.max(Util.ScaleOf(root), 0.01)
    local card = Util.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(math.min(options.Width or 340, inner.X - 24), 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 81,
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = shade,
    })
    Util.Corner("Radius", card)
    Util.Stroke(card)
    Util.Padding(card, 16)
    Util.List(card, 10)
    local scale = Util.New("UIScale", { Scale = 0.94, Parent = card })

    local head = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, ZIndex = 82, Parent = card })
    local titleX = 0
    if options.Icon then
        Util.Icon(options.Icon, { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(0, 1), Color = "Accent", ZIndex = 83, Parent = head })
        titleX = 26
    end
    Util.Label({
        Text = options.Title or "Dialog",
        TextSize = 15,
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, -titleX, 1, 0),
        Position = UDim2.fromOffset(titleX, 0),
        ZIndex = 83,
        Parent = head,
    })

    if options.Content then
        Util.Label({
            Text = options.Content,
            TextSize = 12,
            Color = "TextDim",
            RichText = true,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 82,
            Parent = card,
        })
    end

    local box
    local input = options.Input
    if input then
        local multiline = input.Multiline == true
        local height = multiline and math.min(input.Height or 160, inner.Y - 170) or 30
        local field = Util.New("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            LayoutOrder = 3,
            ZIndex = 82,
            Theme = { BackgroundColor3 = "Surface" },
            Parent = card,
        })
        Util.Corner("ElementRadius", field)
        local stroke = Util.Stroke(field)
        local font = input.Monospace and function() return Font.new("rbxasset://fonts/families/RobotoMono.json") end
            or Theme.Font(Enum.FontWeight.Medium)
        local holder = field
        if multiline then
            -- long text scrolls inside the field
            holder = Util.New("ScrollingFrame", {
                Size = UDim2.new(1, -8, 1, -12),
                Position = UDim2.fromOffset(4, 6),
                ScrollBarThickness = 3,
                ZIndex = 83,
                Theme = { ScrollBarImageColor3 = "TextMuted" },
                Parent = field,
            })
            Util.Padding(holder, 0, 6, 2, 6)
            Util.AutoCanvas(holder, Util.List(holder, 0))
        end
        box = Util.New("TextBox", {
            Size = multiline and UDim2.new(1, 0, 0, 0) or UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(multiline and 0 or 10, 0),
            AutomaticSize = multiline and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            Text = input.Default or "",
            PlaceholderText = input.Placeholder or "",
            TextSize = 12,
            MultiLine = multiline,
            TextWrapped = multiline,
            TextEditable = input.ReadOnly ~= true,
            TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            ZIndex = 84,
            Theme = { TextColor3 = input.ReadOnly and "TextDim" or "Text", PlaceholderColor3 = "TextMuted", FontFace = font },
            Parent = holder,
        })
        box.Focused:Connect(function() Theme.Bind(stroke, { Color = "Accent" }) end)
        box.FocusLost:Connect(function() Theme.Bind(stroke, { Color = "Stroke" }) end)
        handle.Input = box
    end

    local errorLabel = Util.Label({
        Text = "",
        TextSize = 11,
        Color = "Danger",
        Visible = false,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 4,
        ZIndex = 82,
        Parent = card,
    })

    local row = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 5, ZIndex = 82, Parent = card })
    Util.List(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

    function handle:Close()
        if closed then return end
        closed = true
        Util.Tween(shade, 0.15, { BackgroundTransparency = 1 })
        Util.Tween(scale, 0.15, { Scale = 0.94 })
        task.delay(0.16 / math.max(Theme.Current.AnimSpeed or 1, 0.05), function() maid:Clean() end)
        Util.Safe(options.OnClose)
    end

    function handle:SetError(text)
        errorLabel.Text = text or ""
        errorLabel.Visible = text ~= nil and text ~= ""
    end

    local buttons = options.Buttons or { { Title = "OK", Style = "Primary" } }
    local submit
    for index, spec in buttons do
        local style = STYLES[spec.Style or (index == #buttons and "Primary" or "Secondary")] or STYLES.Secondary
        local state = { Hover = false }
        local button = Util.New("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(72, 30),
            Text = spec.Title or "OK",
            TextSize = 12,
            LayoutOrder = index,
            ZIndex = 83,
            Theme = {
                BackgroundColor3 = function(t) return state.Hover and t[style.Bg]:Lerp(t.Text, 0.1) or t[style.Bg] end,
                TextColor3 = style.Text,
                FontFace = Theme.Font(Enum.FontWeight.SemiBold),
            },
            Parent = row,
        })
        Util.Corner("ElementRadius", button)
        Util.Padding(button, 0, 14, 0, 14)
        Util.Feedback(button, state)
        local function press()
            if closed then return end
            local keep = false
            if spec.Callback then
                local ok, result = pcall(spec.Callback, box and box.Text or nil, handle)
                if not ok then warn("[OasisUI] dialog callback: " .. tostring(result)) end
                keep = result == false
            end
            if not keep then handle:Close() end
        end
        button.MouseButton1Click:Connect(press)
        if style == STYLES.Primary or style == STYLES.Danger then submit = press end
    end
    -- Enter in the text field presses the primary button
    if box then
        box.FocusLost:Connect(function(enter)
            if enter and submit then submit() end
        end)
    end

    maid:Give(Services.UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Escape then handle:Close() end
    end))

    Util.Tween(shade, 0.18, { BackgroundTransparency = 0.45 })
    Util.Tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
    -- touch: no keyboard popping up by itself, a tap on the field focuses it
    if box and not input.ReadOnly and not Util.Touch() then task.defer(function() box:CaptureFocus() end) end
    return handle
end

return Dialog
