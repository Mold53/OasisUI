local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Maid = import("Core/Maid")
local Signal = import("Core/Signal")
local Layer = import("Components/Layer")
local Tooltip = import("Components/Tooltip")

-- one floating panel at a time, anchored to a gui object or a screen point
local UIS = Services.UserInputService
local Popup = { Current = nil }

local function scrollParent(gui)
    local node = gui.Parent
    while node do
        if node:IsA("ScrollingFrame") then return node end
        node = node.Parent
    end
    return nil
end

-- options: Anchor | Point, Width, Align ("Start" | "End"), Build(frame, popup), OnClose, Padding
function Popup.Open(options)
    if Popup.Current then Popup.Current:Close() end

    local maid = Maid.new()
    local popup = { Closed = Signal.new(), Maid = maid, Anchor = options.Anchor }
    local anchor = options.Anchor
    local scroller = anchor and scrollParent(anchor)
    local padding = options.Padding or 6

    local frame = maid:Give(Util.New("Frame", {
        Name = "Popup",
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 100,
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = Layer.Root,
    }))
    Util.Corner("ElementRadius", frame)
    Util.Stroke(frame, "Stroke", function(t) return math.max(t.StrokeTransparency - 0.15, 0) end)
    Util.Padding(frame, padding)
    local scale = Util.New("UIScale", { Scale = 0.96, Parent = frame })
    popup.Frame = frame

    local function width()
        if options.Width then return options.Width end
        if anchor then return math.max(anchor.AbsoluteSize.X / Layer.Scale, options.MinWidth or 150) end
        return 180
    end

    local function place()
        local w = width()
        frame.Size = UDim2.fromOffset(w, 0)
        local viewport = Layer.Bounds()
        local size = frame.AbsoluteSize
        local x, y
        if anchor then
            local position, anchorSize = anchor.AbsolutePosition, anchor.AbsoluteSize
            x = options.Align == "End" and position.X + anchorSize.X - size.X or position.X
            y = position.Y + anchorSize.Y + 4
            if y + size.Y > viewport.Y - 8 and position.Y - size.Y - 4 > 8 then
                y = position.Y - size.Y - 4
            end
        else
            x, y = options.Point.X, options.Point.Y
            if y + size.Y > viewport.Y - 8 then y = y - size.Y end
        end
        x = math.clamp(x, 8, math.max(8, viewport.X - size.X - 8))
        y = math.clamp(y, 8, math.max(8, viewport.Y - size.Y - 8))
        frame.Position = UDim2.fromOffset(x / Layer.Scale, y / Layer.Scale)
    end

    local closed = false
    function popup:Close()
        if closed then return end
        closed = true
        if Popup.Current == popup then Popup.Current = nil end
        if Tooltip.Owner == frame then Tooltip.Owner = nil end
        Tooltip.Hide()
        maid:Clean()
        Util.Safe(options.OnClose)
        popup.Closed:Fire()
        popup.Closed:Destroy()
    end

    -- tooltips of things under the popup would stick to the mouse
    Tooltip.Hide()
    Tooltip.Owner = frame
    if options.Build then options.Build(frame, popup) end
    place()
    Util.Tween(scale, 0.14, { Scale = 1 })

    maid:Give(Services.RunService.RenderStepped:Connect(function()
        if anchor then
            if not anchor:IsDescendantOf(game) or anchor.AbsoluteSize.X == 0 or not Util.Shown(anchor) then
                popup:Close()
                return
            end
            if scroller then
                local center = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y / 2
                local top = scroller.AbsolutePosition.Y
                if center < top or center > top + scroller.AbsoluteSize.Y then
                    popup:Close()
                    return
                end
            end
        end
        place()
    end))

    -- the opening click is still being processed; ignore presses this frame
    local armed = false
    task.defer(function() armed = true end)
    maid:Give(UIS.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Escape then
            popup:Close()
            return
        end
        if not armed then return end
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.Touch then
            local point = Util.Pointer(input)
            if Util.Contains(frame, point) then return end
            if anchor and Util.Contains(anchor, point) then return end
            popup:Close()
        end
    end))

    Popup.Current = popup
    return popup
end

function Popup.CloseAll()
    if Popup.Current then Popup.Current:Close() end
end

return Popup
