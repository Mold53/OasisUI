local import = ...
local Services = import("Core/Services")
local Theme = import("Core/Theme")
local Icons = import("Core/Icons")

local Util = {}

local DEFAULTS = {
    Frame          = { BorderSizePixel = 0 },
    ScrollingFrame = { BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y },
    TextLabel      = { BorderSizePixel = 0, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left },
    TextButton     = { BorderSizePixel = 0, AutoButtonColor = false, Text = "" },
    TextBox        = { BorderSizePixel = 0, BackgroundTransparency = 1, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left },
    ImageLabel     = { BorderSizePixel = 0, BackgroundTransparency = 1 },
    ImageButton    = { BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false },
}

-- props.Theme binds properties to tokens; props.Parent is set last
function Util.New(class, props, children)
    local inst = Instance.new(class)
    local defaults = DEFAULTS[class]
    if defaults then
        for key, value in defaults do inst[key] = value end
    end
    local theme, parent
    if props then
        for key, value in props do
            if key == "Theme" then
                theme = value
            elseif key == "Parent" then
                parent = value
            else
                inst[key] = value
            end
        end
    end
    if children then
        for _, child in children do child.Parent = inst end
    end
    if theme then Theme.Bind(inst, theme) end
    if parent then inst.Parent = parent end
    return inst
end

function Util.Tween(inst, time, goal, style, direction)
    local speed = Theme.Current.AnimSpeed or 1
    if speed <= 0 or time <= 0 then
        for key, value in goal do inst[key] = value end
        return nil
    end
    local tween = Services.TweenService:Create(inst, TweenInfo.new(time / speed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), goal)
    tween:Play()
    return tween
end

-- radius: number or token name holding a number
function Util.Corner(radius, parent)
    local corner = Util.New("UICorner", { Parent = parent })
    if type(radius) == "string" then
        Theme.Bind(corner, { CornerRadius = function(t) return UDim.new(0, t[radius]) end })
    elseif typeof(radius) == "UDim" then
        corner.CornerRadius = radius
    else
        corner.CornerRadius = UDim.new(0, radius or 6)
    end
    return corner
end

function Util.Stroke(parent, colorToken, transparencyToken, thickness)
    return Util.New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness or 1,
        Theme = { Color = colorToken or "Stroke", Transparency = transparencyToken or "StrokeTransparency" },
        Parent = parent,
    })
end

function Util.Padding(parent, top, right, bottom, left)
    return Util.New("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or right or top or 0),
        Parent = parent,
    })
end

function Util.List(parent, padding, direction, horizontal, vertical)
    return Util.New("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

-- themed text; Color/Weight/Size are shortcuts
function Util.Label(props)
    local color = props.Color or "Text"
    local weight = props.Weight or Enum.FontWeight.Regular
    props.Color, props.Weight = nil, nil
    props.TextSize = props.TextSize or 13
    local theme = props.Theme or {}
    theme.TextColor3 = theme.TextColor3 or color
    theme.FontFace = theme.FontFace or Theme.Font(weight)
    props.Theme = theme
    return Util.New("TextLabel", props)
end

Util.Icons = Icons

function Util.IconId(icon)
    if icon == nil or icon == "" then return nil end
    if type(icon) == "number" then return "rbxassetid://" .. icon end
    if icon:find("^%a+://") then return icon end
    if icon:match("^%d+$") then return "rbxassetid://" .. icon end
    return Icons[icon]
end

function Util.Icon(icon, props)
    props = props or {}
    local color = props.Color or "TextDim"
    props.Color = nil
    props.Image = Util.IconId(icon) or ""
    props.ScaleType = props.ScaleType or Enum.ScaleType.Fit
    local theme = props.Theme or {}
    theme.ImageColor3 = theme.ImageColor3 or color
    props.Theme = theme
    return Util.New("ImageLabel", props)
end

-- product of every UIScale above gui (absolute sizes are scaled, offsets are not)
function Util.ScaleOf(gui)
    local scale = 1
    local node = gui
    while node and not node:IsA("LayerCollector") do
        local uiScale = node:FindFirstChildOfClass("UIScale")
        if uiScale then scale *= uiScale.Scale end
        node = node.Parent
    end
    return scale
end

-- sizes a ScrollingFrame's canvas from its list layout; AutomaticCanvasSize misreads UIScale and
-- frames that were filled while hidden
function Util.AutoCanvas(frame, layout, horizontal)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.None
    local padding = frame:FindFirstChildOfClass("UIPadding")
    local function update()
        if not frame.Parent then return end
        local scale = Util.ScaleOf(frame)
        local content = layout.AbsoluteContentSize / math.max(scale, 0.01)
        if horizontal then
            local extra = padding and (padding.PaddingLeft.Offset + padding.PaddingRight.Offset) or 0
            frame.CanvasSize = UDim2.fromOffset(math.ceil(content.X + extra), 0)
        else
            local extra = padding and (padding.PaddingTop.Offset + padding.PaddingBottom.Offset) or 0
            frame.CanvasSize = UDim2.fromOffset(0, math.ceil(content.Y + extra))
        end
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
    update()
    return update
end

-- a touch screen is in use: a touch-only device, or the last input was a touch
function Util.Touch()
    local UIS = Services.UserInputService
    if UIS.TouchEnabled and not UIS.MouseEnabled then return true end
    return UIS:GetLastInputType() == Enum.UserInputType.Touch
end

-- fn(hovering) on enter and leave; a lifted touch counts as leaving, MouseLeave often never fires on touch
function Util.Hover(gui, fn)
    local hovering = false
    local function set(on)
        if hovering == on then return end
        hovering = on
        fn(on)
    end
    local enter = gui.MouseEnter:Connect(function() set(true) end)
    local leave = gui.MouseLeave:Connect(function() set(false) end)
    local lift = gui.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then set(false) end
    end)
    return {
        Disconnect = function()
            enter:Disconnect()
            leave:Disconnect()
            lift:Disconnect()
        end,
    }
end

-- touch only: holding still on gui for `time` s calls fn(point); returns the connection and consumed(),
-- which a click handler calls to skip the click that ends a long press
function Util.LongPress(gui, fn, time)
    local presses, fired = 0, false
    local connection = gui.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        presses += 1
        fired = false
        local mine, start = presses, input.Position
        task.delay(time or 0.5, function()
            if mine ~= presses or not gui.Parent then return end
            local state = input.UserInputState
            if state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.Change then return end
            if (input.Position - start).Magnitude > 10 then return end
            fired = true
            fn(Vector2.new(input.Position.X, input.Position.Y))
        end)
    end)
    local function consumed()
        if not fired then return false end
        fired = false
        return true
    end
    return connection, consumed
end

-- resize grip: dots in a corner triangle; drawn without Rotation, which does not render inside clipping frames
function Util.Grip(props)
    local grip = Util.New("TextButton", props)
    local size = grip.Size.X.Offset
    local step = math.floor(size / 4)
    local first = size - step * 3 + 1
    for _, dot in { { 2, 0 }, { 1, 1 }, { 2, 1 }, { 0, 2 }, { 1, 2 }, { 2, 2 } } do
        Util.New("Frame", {
            Size = UDim2.fromOffset(2, 2),
            Position = UDim2.fromOffset(first + dot[1] * step, first + dot[2] * step),
            Theme = { BackgroundColor3 = "TextMuted" },
            Parent = grip,
        })
    end
    return grip
end

-- hover state + press scale for any button; state.Hover / state.Down feed its theme functions
function Util.Feedback(button, state, refresh)
    state = state or {}
    local scale = Util.New("UIScale", { Parent = button })
    local function paint()
        if refresh then refresh() else Theme.Refresh(button, 0.12) end
    end
    Util.Hover(button, function(on)
        state.Hover = on
        if not on then
            state.Down = false
            Util.Tween(scale, 0.1, { Scale = 1 })
        end
        paint()
    end)
    button.MouseButton1Down:Connect(function()
        state.Down = true
        Util.Tween(scale, 0.08, { Scale = 0.95 })
    end)
    button.MouseButton1Up:Connect(function()
        state.Down = false
        Util.Tween(scale, 0.14, { Scale = 1 }, Enum.EasingStyle.Back)
    end)
    return state
end

function Util.Safe(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then warn("[OasisUI] callback error: " .. tostring(err)) end
end

function Util.Round(value, step)
    step = step or 1
    if step <= 0 then return value end
    local rounded = math.floor(value / step + 0.5) * step
    local decimals = Util.Decimals(step)
    return tonumber(string.format("%." .. decimals .. "f", rounded)) or rounded
end

function Util.Decimals(step)
    if not step or step >= 1 then return 0 end
    local text = tostring(step)
    local dot = text:find("%.")
    if text:find("e") then return math.clamp(math.ceil(-math.log10(step)), 0, 6) end
    return dot and math.clamp(#text - dot, 0, 6) or 0
end

function Util.Format(value, step)
    local decimals = Util.Decimals(step)
    return string.format("%." .. decimals .. "f", value)
end

-- 1.5k / 2m / 3b
-- 1500 -> 1.5k, 2000000 -> 2m: the suffixes ParseNumber reads back
function Util.Compact(number)
    local size = math.abs(number)
    for _, unit in { { 1e9, "b" }, { 1e6, "m" }, { 1e3, "k" } } do
        if size >= unit[1] then
            return (string.format("%.2f", number / unit[1]):gsub("%.?0+$", "")) .. unit[2]
        end
    end
    return tostring(number)
end

function Util.ParseNumber(text)
    if type(text) ~= "string" then return tonumber(text) end
    text = text:gsub("[%s,]", "")
    local number, suffix = text:match("^(-?[%d%.]+)(%a?)$")
    number = tonumber(number)
    if not number then return nil end
    local scale = ({ [""] = 1, k = 1e3, m = 1e6, b = 1e9 })[suffix:lower()]
    return scale and number * scale or nil
end

local KEY_LABELS = {
    LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt", LeftSuper = "LWin", RightSuper = "RWin", Return = "Enter",
    Backquote = "`", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]", Semicolon = ";",
    Quote = "'", Comma = ",", Period = ".", Slash = "/", BackSlash = "\\", CapsLock = "Caps",
    PageUp = "PgUp", PageDown = "PgDn", Insert = "Ins", Delete = "Del", Backspace = "Bksp",
    MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3", Space = "Space",
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
}

function Util.KeyLabel(name)
    if not name then return "None" end
    if name:find("+", 1, true) then
        local parts = string.split(name, "+")
        for index, part in parts do parts[index] = Util.KeyLabel(part) end
        return table.concat(parts, " + ")
    end
    if KEY_LABELS[name] then return KEY_LABELS[name] end
    local pad = name:match("^Keypad(.+)$")
    if pad then return "Num" .. (KEY_LABELS[pad] or pad) end
    return name
end

function Util.IsPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- pointer in AbsolutePosition space (below the topbar inset)
function Util.Pointer(input)
    if input then return Vector2.new(input.Position.X, input.Position.Y) end
    return Services.UserInputService:GetMouseLocation() - Services.GuiService:GetGuiInset()
end

function Util.Contains(gui, point)
    local position, size = gui.AbsolutePosition, gui.AbsoluteSize
    return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

-- false when the object or any ancestor is hidden
function Util.Shown(gui)
    local node = gui
    while node do
        if node:IsA("GuiObject") then
            if not node.Visible then return false end
        elseif node:IsA("LayerCollector") then
            return node.Enabled
        end
        node = node.Parent
    end
    return false
end

function Util.Truncate(text, max)
    if #text <= max then return text end
    return text:sub(1, max - 1) .. "…"
end

function Util.Lerp(a, b, t)
    return a + (b - a) * t
end

return Util
