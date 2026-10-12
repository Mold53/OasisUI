local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")

-- background blur, off by default
--   "Screen": a BlurEffect in Lighting while the menu is open; works on every graphics level
--   "Window": a glass plate in front of the camera plus a DepthOfFieldEffect, blurring only what is behind
--             the window; Roblox draws glass from graphics quality 8 up
local Acrylic = {}
Acrylic.__index = Acrylic
Acrylic.Modes = { "Off", "Screen", "Window" }

function Acrylic.new(frame, maid)
    local self = setmetatable({ Frame = frame, Mode = "Off", Shown = true, Strength = 12 }, Acrylic)
    maid:Give(function() self:SetMode("Off") end)
    return self
end

local function qualityLevel()
    local ok, level = pcall(function() return UserSettings().GameSettings.SavedQualityLevel.Value end)
    return ok and level or 0
end

-- 0 = automatic, the engine decides; anything from 8 up renders glass
function Acrylic:Supported()
    local level = qualityLevel()
    return level == 0 or level >= 8
end

function Acrylic:_screen()
    local blur = Instance.new("BlurEffect")
    blur.Name = "OasisBlur"
    blur.Size = 0
    blur.Parent = Services.Lighting
    local function update()
        Util.Tween(blur, 0.3, { Size = self.Shown and self.Strength or 0 })
    end
    self._update = update
    self._stop = function() blur:Destroy() end
    update()
end

local function toWorld(point, distance)
    local ray = workspace.CurrentCamera:ViewportPointToRay(point.X, point.Y)
    return ray.Origin + ray.Direction * distance
end

function Acrylic:_window()
    local camera = workspace.CurrentCamera
    local connections = {}
    local depth = Instance.new("DepthOfFieldEffect")
    depth.Name = "OasisAcrylic"
    depth.FarIntensity = 0
    depth.FocusDistance = 0.05
    depth.InFocusRadius = 0.1
    depth.NearIntensity = 1
    depth.Parent = Services.Lighting

    local part = Instance.new("Part")
    part.Name = "OasisAcrylic"
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)
    part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
    part.Transparency = 0.98
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Offset = Vector3.new(0, 0, -0.000001)
    mesh.Parent = part
    part.Parent = camera

    local function update()
        local frame = self.Frame
        local inset = 6
        -- AbsolutePosition sits below the topbar inset, viewport rays start above it
        local position = frame.AbsolutePosition + Vector2.new(inset, inset) + Services.GuiService:GetGuiInset()
        local size = frame.AbsoluteSize - Vector2.new(inset * 2, inset * 2)
        local topLeft = toWorld(position, 0.001)
        local topRight = toWorld(position + Vector2.new(size.X, 0), 0.001)
        local bottomRight = toWorld(position + size, 0.001)
        local cf = camera.CFrame
        part.CFrame = CFrame.fromMatrix((topLeft + bottomRight) / 2, cf.XVector, cf.YVector, cf.ZVector)
        mesh.Scale = Vector3.new((topRight - topLeft).Magnitude, (topRight - bottomRight).Magnitude, 0)
        local visible = self.Shown and frame.Visible and self:Supported()
        part.Transparency = visible and 0.98 or 1
        depth.Enabled = visible
    end
    table.insert(connections, camera:GetPropertyChangedSignal("CFrame"):Connect(update))
    table.insert(connections, camera:GetPropertyChangedSignal("FieldOfView"):Connect(update))
    table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
    table.insert(connections, self.Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
    table.insert(connections, self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
    table.insert(connections, UserSettings().GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(update))
    update()
    self._update = update
    self._stop = function()
        for _, connection in connections do connection:Disconnect() end
        part:Destroy()
        depth:Destroy()
    end
end

function Acrylic:SetMode(mode)
    if not table.find(Acrylic.Modes, mode) then mode = "Off" end
    if mode == self.Mode then return end
    if self._stop then
        self._stop()
        self._stop, self._update = nil, nil
    end
    self.Mode = mode
    -- glass needs a see-through window background to show anything
    Theme.Set({ _windowBlur = mode == "Window" })
    local start = if mode == "Screen" then self._screen elseif mode == "Window" then self._window else nil
    if start then
        local ok, err = pcall(start, self)
        if not ok then
            warn("[OasisUI] blur: " .. tostring(err))
            self.Mode = "Off"
        end
    end
end

function Acrylic:SetStrength(strength)
    self.Strength = strength
    if self.Mode == "Screen" and self._update then self._update() end
end

function Acrylic:SetVisible(visible)
    self.Shown = visible
    if self._update then self._update() end
end

return Acrylic
