local import = ...
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Menu = import("Components/Menu")
local Tooltip = import("Components/Tooltip")

-- small controls shared by modules and elements
local Widgets = {}

-- returns frame, paint(on, animate)
function Widgets.Switch(parent, props)
    local state = { on = false }
    local track = Util.New("Frame", {
        Name = "Switch",
        Size = UDim2.fromOffset(30, 16),
        AnchorPoint = props and props.AnchorPoint or Vector2.new(1, 0.5),
        Position = props and props.Position or UDim2.new(1, 0, 0.5, 0),
        LayoutOrder = props and props.LayoutOrder or 0,
        Theme = { BackgroundColor3 = function(t) return state.on and t.Accent or t.Elevated end },
        Parent = parent,
    })
    Util.Corner(UDim.new(1, 0), track)
    Util.Stroke(track, function(t) return state.on and t.Accent or t.Stroke end, function(t) return state.on and 1 or t.StrokeTransparency end)
    local knob = Util.New("Frame", {
        Size = UDim2.fromOffset(10, 10),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Theme = { BackgroundColor3 = function(t) return state.on and t.OnAccent or t.TextDim end },
        Parent = track,
    })
    Util.Corner(UDim.new(1, 0), knob)
    local function paint(on, animate)
        state.on = on
        local time = animate and 0.22 or 0
        Theme.Refresh(track, time)
        Theme.Refresh(track:FindFirstChildOfClass("UIStroke"), time)
        Theme.Refresh(knob, time)
        Util.Tween(knob, time, { Position = on and UDim2.new(1, -13, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
    end
    return track, paint
end

function Widgets.Checkbox(parent, props)
    local state = { on = false }
    local box = Util.New("Frame", {
        Name = "Checkbox",
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = props and props.AnchorPoint or Vector2.new(1, 0.5),
        Position = props and props.Position or UDim2.new(1, 0, 0.5, 0),
        LayoutOrder = props and props.LayoutOrder or 0,
        Theme = {
            BackgroundColor3 = function(t) return state.on and t.Accent or t.Elevated end,
        },
        Parent = parent,
    })
    Util.Corner(4, box)
    Util.Stroke(box, function(t) return state.on and t.Accent or t.Stroke end)
    local check = Util.Icon("check", {
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Color = "OnAccent",
        ImageTransparency = 1,
        Parent = box,
    })
    local scale = Util.New("UIScale", { Scale = 0.6, Parent = check })
    local function paint(on, animate)
        state.on = on
        local time = animate and 0.18 or 0
        Theme.Refresh(box, time)
        Theme.Refresh(box:FindFirstChildOfClass("UIStroke"), time)
        Util.Tween(check, time, { ImageTransparency = on and 0 or 1 })
        Util.Tween(scale, time, { Scale = on and 1 or 0.6 }, Enum.EasingStyle.Back)
    end
    return box, paint
end

-- sapphire style key pill for a Binding; click binds, right click opens modes
function Widgets.KeyPill(parent, binding, props)
    props = props or {}
    local hover = false
    local pill = Util.New("TextButton", {
        Name = "KeyPill",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, props.Height or 18),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5),
        Position = props.Position or UDim2.new(0, 0, 0.5, 0),
        LayoutOrder = props.LayoutOrder or 0,
        Theme = {
            BackgroundColor3 = function(t) return hover and t.ElevatedHover or t.Elevated end,
            BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency, 0.2) end,
        },
        Parent = parent,
    })
    Util.Corner(4, pill)
    Util.Padding(pill, 0, 7, 0, 7)
    Util.New("UISizeConstraint", { MinSize = Vector2.new(30, 0), Parent = pill })
    Util.List(pill, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    local stroke = Util.Stroke(pill, function(t) return binding.Capturing and t.Accent or t.Stroke end, function(t)
        return binding.Capturing and 0 or t.StrokeTransparency + 0.15
    end)
    local label = Util.Label({
        TextSize = 10,
        Weight = Enum.FontWeight.SemiBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 1,
        Theme = { TextColor3 = function(t) return (binding.Capturing or binding.Key) and t.Text or t.TextMuted end },
        Parent = pill,
    })
    local mode = Util.Label({
        TextSize = 9,
        Color = "Accent",
        Weight = Enum.FontWeight.Bold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 2,
        Parent = pill,
    })

    local function paint()
        label.Text = binding.Capturing and "..." or Util.KeyLabel(binding.Key)
        local showMode = not binding.Capturing and binding.Key and #binding.Modes > 1 and binding.Mode ~= binding.Modes[1]
        mode.Visible = showMode and true or false
        mode.Text = showMode and binding.Mode:sub(1, 1) or ""
        Theme.Refresh(label)
        Theme.Refresh(stroke, 0.15)
    end
    paint()

    local connections = {}
    table.insert(connections, binding.Changed:Connect(paint))
    table.insert(connections, Tooltip.Attach(pill, function()
        if binding.Capturing then return "Press a key · Esc cancels · Backspace clears" end
        local text = "Click to bind"
        if #binding.Modes > 1 then text ..= " · right-click for mode" end
        return text .. (binding.Key and ("\nMode: " .. binding.Mode) or "")
    end))

    pill.MouseEnter:Connect(function() hover = true; Theme.Refresh(pill, 0.12) end)
    pill.MouseLeave:Connect(function() hover = false; Theme.Refresh(pill, 0.12) end)
    pill.MouseButton1Click:Connect(function() binding:Capture() end)
    pill.MouseButton2Click:Connect(function()
        local items: { any } = {}
        if #binding.Modes > 1 then
            for _, name in binding.Modes do
                table.insert(items, {
                    Title = name,
                    Checked = binding.Mode == name,
                    Callback = function() binding:SetMode(name) end,
                })
            end
            table.insert(items, "-")
        end
        table.insert(items, { Title = "Change key", Icon = "keyboard", Callback = function() binding:Capture() end })
        table.insert(items, { Title = "Clear key", Icon = "x", Danger = true, Disabled = binding.Key == nil, Callback = function() binding:SetKey(nil) end })
        Menu.Open({ Anchor = pill, Items = items, Width = 150, Title = "Keybind" })
    end)

    return pill, {
        Disconnect = function()
            for _, connection in connections do connection:Disconnect() end
        end,
    }
end

return Widgets
