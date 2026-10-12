local import = ...
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Popup = import("Components/Popup")

-- context menu; items: { Title, Icon, Callback, Checked, Danger, Disabled, Hint } or "-"
local Menu = {}

function Menu.Open(options)
    return Popup.Open({
        Anchor = options.Anchor,
        Point = options.Point,
        Width = options.Width or 184,
        Align = options.Align,
        Padding = 4,
        Build = function(frame, popup)
            Util.List(frame, 1)
            if options.Title then
                local title = Util.Label({
                    Text = options.Title,
                    TextSize = 11,
                    Color = "TextMuted",
                    Weight = Enum.FontWeight.SemiBold,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Size = UDim2.new(1, 0, 0, 20),
                    LayoutOrder = 0,
                    Parent = frame,
                    ZIndex = 101,
                })
                Util.Padding(title, 0, 6, 0, 6)
            end
            for index, item in options.Items do
                if item == "-" then
                    local holder = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = index, Parent = frame, ZIndex = 101 })
                    Util.New("Frame", {
                        Size = UDim2.new(1, -8, 0, 1),
                        Position = UDim2.new(0, 4, 0.5, 0),
                        Theme = { BackgroundColor3 = "Divider" },
                        Parent = holder,
                        ZIndex = 101,
                    })
                    continue
                end
                local color = item.Danger and "Danger" or "Text"
                local hover = false
                local button = Util.New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    LayoutOrder = index,
                    ZIndex = 101,
                    Theme = {
                        BackgroundColor3 = "ElevatedHover",
                        BackgroundTransparency = function() return hover and 0 or 1 end,
                    },
                    Parent = frame,
                })
                Util.Corner(5, button)
                local x = 8
                if item.Icon then
                    Util.Icon(item.Icon, {
                        Size = UDim2.fromOffset(14, 14),
                        Position = UDim2.new(0, 8, 0.5, -7),
                        Color = item.Danger and "Danger" or "TextDim",
                        ZIndex = 102,
                        Parent = button,
                    })
                    x = 30
                end
                Util.Label({
                    Text = item.Title,
                    TextSize = 12,
                    Color = color,
                    Weight = Enum.FontWeight.Medium,
                    Size = UDim2.new(1, -x - 28, 1, 0),
                    Position = UDim2.fromOffset(x, 0),
                    TextTransparency = item.Disabled and 0.6 or 0,
                    ZIndex = 102,
                    Parent = button,
                })
                if item.Checked ~= nil then
                    Util.Icon("check", {
                        Size = UDim2.fromOffset(13, 13),
                        Position = UDim2.new(1, -21, 0.5, -6),
                        Color = "Accent",
                        ImageTransparency = item.Checked and 0 or 1,
                        ZIndex = 102,
                        Parent = button,
                    })
                elseif item.Hint then
                    Util.Label({
                        Text = item.Hint,
                        TextSize = 11,
                        Color = "TextMuted",
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Size = UDim2.new(0, 60, 1, 0),
                        Position = UDim2.new(1, -68, 0, 0),
                        ZIndex = 102,
                        Parent = button,
                    })
                end
                Util.Hover(button, function(on) hover = on; Theme.Refresh(button, 0.1) end)
                button.MouseButton1Click:Connect(function()
                    if item.Disabled then return end
                    popup:Close()
                    Util.Safe(item.Callback)
                end)
            end
        end,
    })
end

return Menu
