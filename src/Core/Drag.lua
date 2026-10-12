local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Layer = import("Components/Layer")

local UIS = Services.UserInputService
local Drag = {}

-- follows the press that started it (that touch, or the mouse) until it ends or is cancelled;
-- owner (optional): the dragged gui, its scrolling ancestors hold still while a touch drags it
function Drag.Follow(input, onMove, onEnd, owner)
    local touch = input.UserInputType == Enum.UserInputType.Touch
    local start = Util.Pointer(input)
    local moved = false
    local finished = false
    local connections = {}
    local locked = {}

    -- a scrolling frame would take the touch over and cancel it
    if touch and owner then
        local node = owner.Parent
        while node and not node:IsA("LayerCollector") do
            if node:IsA("ScrollingFrame") and node.ScrollingEnabled then
                node.ScrollingEnabled = false
                table.insert(locked, node)
            end
            node = node.Parent
        end
    end

    local function stop()
        for _, connection in connections do connection:Disconnect() end
        table.clear(connections)
        for _, frame in locked do frame.ScrollingEnabled = true end
        table.clear(locked)
    end

    local function finish()
        if finished then return end
        finished = true
        stop()
        if onEnd then onEnd(moved) end
    end

    table.insert(connections, UIS.InputChanged:Connect(function(change)
        local follows = touch and change == input or (not touch and change.UserInputType == Enum.UserInputType.MouseMovement)
        if not follows then return end
        local point = Util.Pointer(touch and change or nil)
        if not moved and (point - start).Magnitude > 3 then moved = true end
        onMove(point, point - start, moved)
    end))
    table.insert(connections, UIS.InputEnded:Connect(function(finishInput)
        local ends = touch and finishInput == input or (not touch and finishInput.UserInputType == Enum.UserInputType.MouseButton1)
        if ends then finish() end
    end))
    -- a cancelled touch fires no InputEnded; a drag left running would follow the next touch that reuses
    -- this input object and drag the element along like a magnet
    if touch then
        table.insert(connections, input.Changed:Connect(function(property)
            if property ~= "UserInputState" then return end
            local state = input.UserInputState
            if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then finish() end
        end))
    end
    return function()
        finished = true
        stop()
    end
end

-- every attached handle -> the frame it moves; a press starts only the one drawn on top, so stacked
-- panels move one at a time
local handles = {}

-- the handle whose moved frame is drawn on top at point (AbsolutePosition space)
function Drag.Topmost(candidates, point)
    if #candidates < 2 then return candidates[1] end
    local root = candidates[1]:FindFirstAncestorWhichIsA("BasePlayerGui")
    if root then
        local inset = Services.GuiService:GetGuiInset()
        local ok, objects = pcall(root.GetGuiObjectsAtPosition, root, point.X + inset.X, point.Y + inset.Y)
        if ok then
            -- topmost first; any part of a moved frame (its background too) covers what lies below
            for _, object in objects do
                for _, candidate in candidates do
                    local target = handles[candidate] or candidate
                    if object == target or object:IsDescendantOf(target) then return candidate end
                end
            end
        end
    end
    return candidates[#candidates]
end

-- moves `target` (offset position) while `handle` is dragged; keeps `margin` px on screen
function Drag.Attach(handle, target, options)
    options = options or {}
    local margin = options.Margin or 48
    handles[handle] = target
    local connection = handle.InputBegan:Connect(function(input)
        if not Util.IsPress(input) then return end
        if options.Enabled and not options.Enabled() then return end
        local point = Util.Pointer(input)
        local here = {}
        for other in handles do
            if other.Parent and Util.Shown(other) and Util.Contains(other, point) then table.insert(here, other) end
        end
        if #here > 1 and Drag.Topmost(here, point) ~= handle then return end
        Drag._start(input, target, options, margin)
    end)
    local gone = handle.Destroying:Connect(function() handles[handle] = nil end)
    return {
        Disconnect = function()
            connection:Disconnect()
            gone:Disconnect()
            handles[handle] = nil
        end,
    }
end

function Drag._start(input, target, options, margin)
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
end

return Drag
