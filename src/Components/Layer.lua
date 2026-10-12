local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")

-- screen guis: Main (windows), Hud (watermark, keybind list), Overlay (popups, tooltips, toasts)
local Layer = { Scale = 1 } :: any

local function parent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and typeof(hui) == "Instance" then return hui end
    end
    local ok = pcall(function() return Services.CoreGui:FindFirstChild("RobloxGui") end)
    if ok then return Services.CoreGui end
    return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function screen(name, order)
    local gui = Util.New("ScreenGui", {
        Name = name,
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = order,
    })
    local protect = type(getgenv) == "function" and (getgenv() :: any).protectgui
    if type(protect) == "function" then pcall(protect, gui) end
    gui.Parent = Layer.Parent
    return gui
end

function Layer.Init(maid, name)
    Layer.Parent = parent()
    Layer.Main = maid:Give(screen(name, 1000))
    Layer.Hud = maid:Give(screen(name .. "_Hud", 999))
    Layer.Overlay = maid:Give(screen(name .. "_Overlay", 1001))
    -- scaled root covering the screen; children use the same scale as the window
    Layer.Root = Util.New("Frame", {
        Name = "Root",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = Layer.Overlay,
    })
    Layer.RootScale = Util.New("UIScale", { Parent = Layer.Root })
end

function Layer.SetScale(scale)
    Layer.Scale = scale
    if Layer.Root then
        Layer.RootScale.Scale = scale
        Layer.Root.Size = UDim2.fromScale(1 / scale, 1 / scale)
    end
end

-- usable gui area (screen minus the topbar inset); AbsolutePosition and input positions share this space
function Layer.Bounds()
    if Layer.Main then return Layer.Main.AbsoluteSize end
    return workspace.CurrentCamera.ViewportSize
end

return Layer
