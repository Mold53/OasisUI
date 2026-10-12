local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Layer = import("Components/Layer")

local UIS = Services.UserInputService
local Drag = {}

-- follows the press that started it (that touch, or the mouse) until it ends
function Drag.Follow(input, onMove, onEnd)
    local touch = input.UserInputType == Enum.UserInputType.Touch
    local start = Util.Pointer(input)
    local moved = false
    local changed, ended

    local function stop()
        if changed then changed:Disconnect() end
        if ended then ended:Disconnect() end
        changed, ended = nil, nil
    end

    changed = UIS.InputChanged:Connect(function(change)
        local follows = touch and change == input or (not touch and change.UserInputType == Enum.UserInputType.MouseMovement)
        if not follows then return end
        local point = Util.Pointer(touch and change or nil)
        if not moved and (point - start).Magnitude > 3 then moved = true end
        onMove(point, point - start, moved)
    end)
    ended = UIS.InputEnded:Connect(function(finish)
        local ends = touch and finish == input or (not touch and finish.UserInputType == Enum.UserInputType.MouseButton1)
        if not ends then return end
        stop()
        if onEnd then onEnd(moved) end
    end)
    return stop
end

-- moves `target` (offset position) while `handle` is dragged; keeps `margin` px on screen
function Drag.Attach(handle, target, options)
    options = options or {}
    local margin = options.Margin or 48
    return handle.InputBegan:Connect(function(input)
        if not Util.IsPress(input) then return end
        if options.Enabled and not options.Enabled() then return end
        local origin = target.Position
        Drag.Follow(input, function(_, delta)
            local scale = options.Scale and options.Scale() or 1
            local goal = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X / scale, origin.Y.Scale, origin.Y.Offset + delta.Y / scale)
            target.Position = goal
            if options.Clamp ~= false then
                local viewport = Layer.Bounds()
                local position, size = target.AbsolutePosition, target.AbsoluteSize
                local dx = math.clamp(position.X, margin - size.X, viewport.X - margin) - position.X
                local dy = math.clamp(position.Y, 0, viewport.Y - margin) - position.Y
                if dx ~= 0 or dy ~= 0 then
                    target.Position = goal + UDim2.fromOffset(dx / scale, dy / scale)
                end
            end
        end, function(moved)
            if options.OnEnd then options.OnEnd(moved) end
        end)
    end)
end

return Drag
