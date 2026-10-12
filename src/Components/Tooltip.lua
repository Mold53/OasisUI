local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Layer = import("Components/Layer")

-- one shared hover label; shows after a short delay and follows the mouse
local Tooltip = {}
local frame, label, follow
local token = 0

local function ensure()
    if frame and frame.Parent then return end
    frame = Util.New("Frame", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 200,
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = Layer.Root,
    })
    Util.Corner(5, frame)
    Util.Stroke(frame)
    Util.Padding(frame, 5, 8, 5, 8)
    Util.New("UISizeConstraint", { MaxSize = Vector2.new(240, math.huge), Parent = frame })
    label = Util.Label({
        TextSize = 11,
        Color = "TextDim",
        AutomaticSize = Enum.AutomaticSize.XY,
        TextWrapped = true,
        ZIndex = 201,
        Parent = frame,
    })
end

local function hide()
    token += 1
    if follow then follow:Disconnect(); follow = nil end
    if frame then frame.Visible = false end
end

local function show(text)
    ensure()
    label.Text = text
    frame.Visible = true
    if follow then follow:Disconnect() end
    follow = Services.RunService.RenderStepped:Connect(function()
        local mouse = Util.Pointer()
        local viewport = Layer.Bounds()
        local size = frame.AbsoluteSize
        local x = math.min(mouse.X + 14, viewport.X - size.X - 6)
        local y = mouse.Y + 18
        if y + size.Y > viewport.Y - 6 then y = mouse.Y - size.Y - 8 end
        frame.Position = UDim2.fromOffset(x / Layer.Scale, y / Layer.Scale)
    end)
end

-- text may be a function evaluated on hover; returns connections for a maid
function Tooltip.Attach(gui, text)
    local enter = gui.MouseEnter:Connect(function()
        token += 1
        local mine = token
        task.delay(0.35, function()
            if mine ~= token then return end
            local value = type(text) == "function" and text() or text
            if value and value ~= "" then show(value) end
        end)
    end)
    local leave = gui.MouseLeave:Connect(hide)
    local gone = gui.AncestryChanged:Connect(function(_, parent)
        if not parent then hide() end
    end)
    return {
        Disconnect = function()
            enter:Disconnect()
            leave:Disconnect()
            gone:Disconnect()
        end,
    }
end

Tooltip.Hide = hide

return Tooltip
