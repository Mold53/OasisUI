local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Drag = import("Core/Drag")
local Services = import("Core/Services")
local Row = import("Components/Row")
local Popup = import("Components/Popup")
local Tooltip = import("Components/Tooltip")

-- def: Title, Default (Color3), Transparency (0..1, enables the alpha bar), Rainbow, Callback(color, transparency)
local ColorPicker = Base.Class("ColorPicker")
ColorPicker.Clipboard = nil

local HUES = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
    ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
    ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
    ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
    ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
    ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

function ColorPicker.new(container, def)
    local self = setmetatable({}, ColorPicker)
    Base.Init(self, container, def)
    self.HasAlpha = def.Transparency ~= nil
    self.Value = { Color = def.Default or def.Value or Color3.new(1, 1, 1), Alpha = def.Transparency or 0 }
    self.Default = table.clone(self.Value)
    self.Rainbow = false
    if def.Rainbow then self:SetRainbow(true) end
    return self
end

function ColorPicker:_args()
    return self.Value.Color, self.Value.Alpha
end

-- Set(color, transparency) or Set({ Color, Alpha })
function ColorPicker:Set(color, alpha, silent)
    if type(color) == "table" then
        color, alpha, silent = color.Color, color.Alpha, alpha
    end
    if typeof(color) ~= "Color3" then return end
    alpha = math.clamp(alpha or self.Value.Alpha, 0, 1)
    if color == self.Value.Color and alpha == self.Value.Alpha then return end
    self:_commit({ Color = color, Alpha = alpha }, silent)
end
ColorPicker.SetValueRGB = ColorPicker.Set

function ColorPicker:Reset()
    self:SetRainbow(false)
    self:Set(self.Default.Color, self.Default.Alpha)
end

function ColorPicker:SetRainbow(on)
    on = on and true or false
    if on == self.Rainbow then return end
    self.Rainbow = on
    if self._rainbow then self._rainbow:Disconnect(); self._rainbow = nil end
    if on then
        self._rainbow = Services.RunService.Heartbeat:Connect(function()
            local _, s, v = self.Value.Color:ToHSV()
            self:Set(Color3.fromHSV((os.clock() * 0.15) % 1, math.max(s, 0.6), math.max(v, 0.8)), self.Value.Alpha)
        end)
        self.Window.Maid:Give(self._rainbow)
    end
    self.StateChanged:Fire("Rainbow")
end

function ColorPicker:Save()
    return { Hex = self.Value.Color:ToHex(), Alpha = self.Value.Alpha, Rainbow = self.Rainbow or nil }
end

function ColorPicker:Load(data)
    if type(data) ~= "table" then return end
    local ok, color = pcall(Color3.fromHex, data.Hex or "ffffff")
    if ok then self:Set(color, data.Alpha) end
    self:SetRainbow(data.Rainbow == true)
end

local function cursor(parent, size)
    local dot = Util.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 106,
        Parent = parent,
    })
    Util.Corner(UDim.new(1, 0), dot)
    Util.New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.35, Thickness = 1, Parent = dot })
    return dot
end

local function smallField(parent, width, order, placeholder)
    local field, api = Row.Field(parent, { Size = UDim2.new(0, width, 0, 24), LayoutOrder = order, Radius = 5 })
    field.ZIndex = 103
    local box = Util.New("TextBox", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.fromOffset(4, 0),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        PlaceholderText = placeholder,
        ZIndex = 104,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
        Parent = field,
    })
    box.Focused:Connect(function() api.SetFocused(true) end)
    box.FocusLost:Connect(function() api.SetFocused(false) end)
    return field, box
end

function ColorPicker:_open(anchor)
    Popup.Open({
        Anchor = anchor,
        Width = 236,
        Align = "End",
        Padding = 8,
        Build = function(frame, popup)
            Util.List(frame, 8)
            local h, s, v = self.Value.Color:ToHSV()

            local sv = Util.New("TextButton", {
                Size = UDim2.new(1, 0, 0, 132),
                LayoutOrder = 1,
                ZIndex = 102,
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                Parent = frame,
            })
            Util.Corner(5, sv)
            local white = Util.New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 103, Parent = sv })
            Util.Corner(5, white)
            Util.New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
            local black = Util.New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 104, Parent = sv })
            Util.Corner(5, black)
            Util.New("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
            local svCursor = cursor(sv, UDim2.fromOffset(10, 10))

            local hue = Util.New("TextButton", { Size = UDim2.new(1, 0, 0, 10), LayoutOrder = 2, ZIndex = 102, BackgroundColor3 = Color3.new(1, 1, 1), Parent = frame })
            Util.Corner(UDim.new(1, 0), hue)
            Util.New("UIGradient", { Color = HUES, Parent = hue })
            local hueCursor = cursor(hue, UDim2.fromOffset(6, 14))
            hueCursor.Position = UDim2.fromScale(h, 0.5)

            local alphaBar, alphaFill, alphaCursor
            if self.HasAlpha then
                alphaBar = Util.New("TextButton", { Size = UDim2.new(1, 0, 0, 10), LayoutOrder = 3, ZIndex = 102, Theme = { BackgroundColor3 = "Surface" }, Parent = frame })
                Util.Corner(UDim.new(1, 0), alphaBar)
                alphaFill = Util.New("Frame", { Size = UDim2.fromScale(1, 1), ZIndex = 103, BackgroundColor3 = self.Value.Color, Parent = alphaBar })
                Util.Corner(UDim.new(1, 0), alphaFill)
                Util.New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = alphaFill })
                alphaCursor = cursor(alphaBar, UDim2.fromOffset(6, 14))
            end

            local inputs = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 4, ZIndex = 102, Parent = frame })
            Util.List(inputs, 4, Enum.FillDirection.Horizontal)
            local hexField, hex = smallField(inputs, 0, 1, "#hex")
            Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = hexField })
            local _, red = smallField(inputs, 34, 2, "R")
            local _, green = smallField(inputs, 34, 3, "G")
            local _, blue = smallField(inputs, 34, 4, "B")
            local alphaBox
            if self.HasAlpha then
                local _, box = smallField(inputs, 38, 5, "A%")
                alphaBox = box
            end

            local tools = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 5, ZIndex = 102, Parent = frame })
            Util.List(tools, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
            local function tool(icon, order, tip)
                local button = Util.New("ImageButton", {
                    Size = UDim2.fromOffset(22, 22),
                    LayoutOrder = order,
                    ZIndex = 103,
                    Theme = { BackgroundColor3 = "ElevatedHover", BackgroundTransparency = function() return 0.4 end },
                    Parent = tools,
                })
                Util.Corner(5, button)
                Util.Icon(icon, { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(5, 5), Color = "TextDim", ZIndex = 104, Parent = button })
                popup.Maid:Give(Tooltip.Attach(button, tip))
                return button
            end
            local rainbow = tool("sparkles", 1, "Rainbow")
            local copy = tool("copy", 2, "Copy colour")
            local paste = tool("clipboard-paste", 3, "Paste colour")
            local reset = tool("rotate-ccw", 4, "Reset")
            local preview = Util.New("Frame", { Size = UDim2.fromOffset(0, 22), LayoutOrder = 5, ZIndex = 103, Parent = tools })
            Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = preview })
            Util.Corner(5, preview)
            Util.Stroke(preview)

            local function paint(fromHsv)
                local color = self.Value.Color
                if not fromHsv then
                    local nh, ns, nv = color:ToHSV()
                    if ns > 0.001 and nv > 0.001 then h = nh end
                    s, v = ns, nv
                end
                sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position = UDim2.fromScale(s, 1 - v)
                hueCursor.Position = UDim2.fromScale(h, 0.5)
                if alphaBar then
                    alphaFill.BackgroundColor3 = color
                    alphaCursor.Position = UDim2.fromScale(1 - self.Value.Alpha, 0.5)
                end
                preview.BackgroundColor3 = color
                preview.BackgroundTransparency = self.Value.Alpha
                if not hex:IsFocused() then hex.Text = "#" .. color:ToHex():upper() end
                if not red:IsFocused() then red.Text = tostring(math.round(color.R * 255)) end
                if not green:IsFocused() then green.Text = tostring(math.round(color.G * 255)) end
                if not blue:IsFocused() then blue.Text = tostring(math.round(color.B * 255)) end
                if alphaBox and not alphaBox:IsFocused() then alphaBox.Text = tostring(math.round((1 - self.Value.Alpha) * 100)) end
                rainbow.BackgroundTransparency = self.Rainbow and 0 or 0.4
                Theme.Bind(rainbow, { BackgroundColor3 = self.Rainbow and "Accent" or "ElevatedHover" })
            end
            paint(false)

            local function apply()
                self:SetRainbow(false)
                self:Set(Color3.fromHSV(h, s, v), self.Value.Alpha)
                paint(true)
            end
            local function track(button, onPoint)
                button.InputBegan:Connect(function(input)
                    if not Util.IsPress(input) or self.Locked then return end
                    onPoint(Util.Pointer(input))
                    Drag.Follow(input, function(point) onPoint(point) end, nil, button)
                end)
            end
            local function relative(gui, point)
                local position, size = gui.AbsolutePosition, gui.AbsoluteSize
                return math.clamp((point.X - position.X) / size.X, 0, 1), math.clamp((point.Y - position.Y) / size.Y, 0, 1)
            end
            track(sv, function(point)
                local x, y = relative(sv, point)
                s, v = x, 1 - y
                apply()
            end)
            track(hue, function(point)
                h = (relative(hue, point))
                apply()
            end)
            if alphaBar then
                track(alphaBar, function(point)
                    local x = relative(alphaBar, point)
                    self:Set(self.Value.Color, 1 - x)
                    paint(true)
                end)
            end

            hex.FocusLost:Connect(function()
                local ok, color = pcall(Color3.fromHex, (hex.Text:gsub("#", "")))
                if ok and not self.Locked then
                    self:SetRainbow(false)
                    self:Set(color, self.Value.Alpha)
                end
                paint(false)
            end)
            local function channel(box, index)
                box.FocusLost:Connect(function()
                    local number = tonumber(box.Text)
                    if number and not self.Locked then
                        local color = self.Value.Color
                        local parts = { color.R * 255, color.G * 255, color.B * 255 }
                        parts[index] = math.clamp(math.round(number), 0, 255)
                        self:SetRainbow(false)
                        self:Set(Color3.fromRGB(parts[1], parts[2], parts[3]), self.Value.Alpha)
                    end
                    paint(false)
                end)
            end
            channel(red, 1)
            channel(green, 2)
            channel(blue, 3)
            if alphaBox then
                alphaBox.FocusLost:Connect(function()
                    local number = tonumber((alphaBox.Text:gsub("%%", "")))
                    if number and not self.Locked then self:Set(self.Value.Color, 1 - math.clamp(number, 0, 100) / 100) end
                    paint(false)
                end)
            end

            rainbow.MouseButton1Click:Connect(function() if not self.Locked then self:SetRainbow(not self.Rainbow) end end)
            copy.MouseButton1Click:Connect(function()
                ColorPicker.Clipboard = table.clone(self.Value)
                if type(setclipboard) == "function" then pcall(setclipboard, "#" .. self.Value.Color:ToHex():upper()) end
            end)
            paste.MouseButton1Click:Connect(function()
                if ColorPicker.Clipboard and not self.Locked then
                    self:SetRainbow(false)
                    self:Set(ColorPicker.Clipboard.Color, self.HasAlpha and ColorPicker.Clipboard.Alpha or self.Value.Alpha)
                end
            end)
            reset.MouseButton1Click:Connect(function() if not self.Locked then self:Reset() end end)

            popup.Maid:Give(self.Changed:Connect(function() paint(false) end))
            popup.Maid:Give(self.StateChanged:Connect(function(what) if what == "Rainbow" then paint(false) end end))
        end,
    })
end

function ColorPicker:Render(parent, maid)
    local row = Row.new(self, parent, maid)
    local swatch = Util.New("TextButton", {
        Size = UDim2.fromOffset(32, 18),
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = row.Right,
    })
    Util.Corner(5, swatch)
    Util.Stroke(swatch)
    local fill = Util.New("Frame", { Size = UDim2.fromScale(1, 1), Parent = swatch })
    Util.Corner(5, fill)
    local function paint()
        fill.BackgroundColor3 = self.Value.Color
        fill.BackgroundTransparency = self.Value.Alpha
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    swatch.MouseButton1Click:Connect(function()
        if self.Locked then return end
        if Popup.Current and Popup.Current.Anchor == swatch then
            Popup.Current:Close()
            return
        end
        self:_open(swatch)
    end)
    return row.Frame
end

return ColorPicker
