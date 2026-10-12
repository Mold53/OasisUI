local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- def: Height (px, default 6)
local Spacer = Base.Class("Spacer")

function Spacer.new(container, def)
    local self = setmetatable({}, Spacer)
    Base.Init(self, container, def)
    self.NoSave = true
    return self
end

function Spacer:Matches()
    return false
end

function Spacer:Render(parent, maid)
    return maid:Give(Util.New("Frame", {
        Name = "Spacer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, self.Def.Height or 6),
        Parent = parent,
    }))
end

return Spacer
