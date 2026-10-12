local import = ...
local Services = import("Core/Services")

-- background blur behind the window (depth of field + a glass plate in front of the camera)
-- off by default: it adds a DepthOfFieldEffect to Lighting and a part to the camera
local Acrylic = {}
Acrylic.__index = Acrylic

function Acrylic.new(frame, maid)
    local self = setmetatable({ Frame = frame, Enabled = false, Shown = true, _maid = nil, _parent = maid }, Acrylic)
    maid:Give(function() self:SetEnabled(false) end)
    return self
end

local function toWorld(point, distance)
    local ray = workspace.CurrentCamera:ViewportPointToRay(point.X, point.Y)
    return ray.Origin + ray.Direction * distance
end

function Acrylic:_start()
    local camera = workspace.CurrentCamera
    local connections = {}
    local blur = Instance.new("DepthOfFieldEffect")
    blur.Name = "OasisAcrylic"
    blur.FarIntensity = 0
    blur.FocusDistance = 0.05
    blur.InFocusRadius = 0.1
    blur.NearIntensity = 1
    blur.Parent = Services.Lighting

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
        local inset = 8
        local position = frame.AbsolutePosition + Vector2.new(inset, inset) + Services.GuiService:GetGuiInset()
        local size = frame.AbsoluteSize - Vector2.new(inset * 2, inset * 2)
        local distance = 0.001
        local topLeft = toWorld(position, distance)
        local topRight = toWorld(position + Vector2.new(size.X, 0), distance)
        local bottomRight = toWorld(position + size, distance)
        local cf = camera.CFrame
        part.CFrame = CFrame.fromMatrix((topLeft + bottomRight) / 2, cf.XVector, cf.YVector, cf.ZVector)
        mesh.Scale = Vector3.new((topRight - topLeft).Magnitude, (topRight - bottomRight).Magnitude, 0)
        part.Transparency = (self.Shown and self.Frame.Visible) and 0.98 or 1
    end
    table.insert(connections, camera:GetPropertyChangedSignal("CFrame"):Connect(update))
    table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(update))
    table.insert(connections, self.Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(update))
    table.insert(connections, self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
    update()
    self._stop = function()
        for _, connection in connections do connection:Disconnect() end
        part:Destroy()
        blur:Destroy()
    end
    self._update = update
end

function Acrylic:SetEnabled(enabled)
    enabled = enabled and true or false
    if enabled == self.Enabled then return end
    self.Enabled = enabled
    if enabled then
        local ok, err = pcall(self._start, self)
        if not ok then
            warn("[OasisUI] acrylic: " .. tostring(err))
            self.Enabled = false
        end
    elseif self._stop then
        self._stop()
        self._stop, self._update = nil, nil
    end
end

function Acrylic:SetVisible(visible)
    self.Shown = visible
    if self._update then self._update() end
end

return Acrylic
