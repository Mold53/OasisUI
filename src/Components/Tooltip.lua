local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Layer = import("Components/Layer")

-- one shared hover label; shows after a short delay and follows the mouse
-- touch: placed once at the finger, hidden after a moment or by the next touch
local Tooltip = {}
local TOUCH_TIME = 2.5
local frame, label, follow, touchHide
local token = 0
-- while a popup is open only its own controls show tooltips (set by Popup)
Tooltip.Owner = nil

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
    if touchHide then touchHide:Disconnect(); touchHide = nil end
    if frame then frame.Visible = false end
end

local function place()
    local mouse = Util.Pointer()
    local viewport = Layer.Bounds()
    local size = frame.AbsoluteSize
    local x = math.clamp(mouse.X + 14, 6, math.max(6, viewport.X - size.X - 6))
    local y = mouse.Y + 18
    if y + size.Y > viewport.Y - 6 then y = mouse.Y - size.Y - 8 end
    frame.Position = UDim2.fromOffset(x / Layer.Scale, y / Layer.Scale)
end

local function show(text)
    ensure()
    label.Text = text
    frame.Visible = true
    if follow then follow:Disconnect(); follow = nil end
    if touchHide then touchHide:Disconnect(); touchHide = nil end
    if Util.Touch() then
        place()
        task.defer(place)                            -- again once the label has its size
        local mine = token
        task.delay(TOUCH_TIME, function() if mine == token then hide() end end)
        touchHide = Services.UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then hide() end
        end)
    else
        follow = Services.RunService.RenderStepped:Connect(place)
    end
end

-- text may be a function evaluated on hover; returns connections for a maid
-- touch has no hover: taps on info icons and locks call Tooltip.Show instead
function Tooltip.Attach(gui, text)
    local enter = gui.MouseEnter:Connect(function()
        if Util.Touch() then return end
        token += 1
        local mine = token
        task.delay(0.35, function()
            if mine ~= token then return end
            local owner = Tooltip.Owner
            if owner and owner.Parent and not gui:IsDescendantOf(owner) then return end
            -- a function may return nil (no tooltip right now)
            local value = if type(text) == "function" then text() else text
            if type(value) == "string" and value ~= "" then show(value) end
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

-- shows text right away, e.g. for a tap on an info icon
function Tooltip.Show(text)
    token += 1
    if type(text) == "string" and text ~= "" then show(text) end
end

return Tooltip
