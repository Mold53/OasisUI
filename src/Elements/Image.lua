local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- def: Image (asset id, url or icon name), Height (default 120) or AspectRatio (number | "16:9"), Radius, ScaleType
local Image = Base.Class("Image")

function Image.new(container, def)
    local self = setmetatable({}, Image)
    Base.Init(self, container, def)
    self.Value = def.Image or ""
    self.NoSave = true
    return self
end

function Image:Set(image)
    self.Value = image
    self.Changed:Fire(image)
end

function Image:Matches()
    return false
end

function Image:Render(parent, maid)
    local frame = maid:Give(Util.New("ImageLabel", {
        Name = "Image",
        Size = UDim2.new(1, 0, 0, self.Def.Height or 120),
        Image = Util.IconId(self.Value) or "",
        ScaleType = self.Def.ScaleType or Enum.ScaleType.Crop,
        BackgroundTransparency = 0,
        Visible = self.Visible,
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = parent,
    }))
    Util.Corner(self.Def.Radius or 6, frame)
    local ratio = self.Def.AspectRatio
    if type(ratio) == "string" then
        local w, h = ratio:match("(%d+)%s*:%s*(%d+)")
        ratio = if w and h then (tonumber(w) or 1) / (tonumber(h) or 1) else nil
    end
    if ratio then
        Util.New("UIAspectRatioConstraint", { AspectRatio = ratio, DominantAxis = Enum.DominantAxis.Width, Parent = frame })
        frame.Size = UDim2.fromScale(1, 1)
    end
    maid:Give(self.Changed:Connect(function() frame.Image = Util.IconId(self.Value) or "" end))
    return frame
end

return Image
