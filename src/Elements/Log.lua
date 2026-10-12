local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- scrolling list of lines with its own height; def: Title, Height (default 140), MaxLines (default 200),
-- Monospace, Timestamps, AutoScroll (default true); Add(text, colorToken?), Clear(), Set(lines)
local Log = Base.Class("Log")

function Log.new(container, def)
    local self = setmetatable({}, Log)
    Base.Init(self, container, def)
    self.Title = def.Title or ""
    self.Value = {}
    self.NoSave = true
    return self
end

function Log:Add(text, color)
    local line = { Text = tostring(text), Color = color }
    if self.Def.Timestamps then line.Text = os.date("%H:%M:%S") .. "  " .. line.Text end
    table.insert(self.Value, line)
    local max = self.Def.MaxLines or 200
    while #self.Value > max do table.remove(self.Value, 1) end
    self.Changed:Fire("Add", line)
end

function Log:Clear()
    table.clear(self.Value)
    self.Changed:Fire("Clear")
end

function Log:Set(lines)
    table.clear(self.Value)
    for _, text in lines do table.insert(self.Value, { Text = tostring(text) }) end
    self.Changed:Fire("Clear")
    for _, line in self.Value do self.Changed:Fire("Add", line) end
end

function Log:Matches(query)
    return self.Title ~= "" and Base.Matches(self, query)
end

function Log:Render(parent, maid)
    local frame = maid:Give(Util.New("Frame", {
        Name = "Log",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Parent = parent,
    }))
    Util.List(frame, 6)
    if self.Title ~= "" then
        Util.Label({ Text = self.Title, TextSize = 12, Weight = Enum.FontWeight.Medium, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = frame })
    end
    local box = Util.New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, self.Def.Height or 140),
        BackgroundTransparency = 0,
        ScrollBarThickness = 3,
        LayoutOrder = 2,
        Theme = {
            BackgroundColor3 = "Background",
            BackgroundTransparency = function() return 0.25 end,
            ScrollBarImageColor3 = "TextMuted",
        },
        Parent = frame,
    })
    Util.Corner(6, box)
    Util.Stroke(box)
    Util.Padding(box, 6, 8, 6, 8)
    Util.AutoCanvas(box, Util.List(box, 2))
    local font = self.Def.Monospace and Font.new("rbxasset://fonts/families/RobotoMono.json") or nil
    local count = 0
    local lines = {}
    local function add(line)
        count += 1
        local label = Util.Label({
            Text = line.Text,
            TextSize = 11,
            Color = line.Color or "TextDim",
            TextWrapped = true,
            RichText = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = count,
            Theme = font and { FontFace = function() return font end } or nil,
            Parent = box,
        })
        table.insert(lines, label)
        while #lines > (self.Def.MaxLines or 200) do
            local oldest = table.remove(lines, 1)
            if oldest then oldest:Destroy() end
        end
        if self.Def.AutoScroll ~= false then
            task.defer(function()
                if box.Parent then box.CanvasPosition = Vector2.new(0, math.huge) end
            end)
        end
    end
    for _, line in self.Value do add(line) end
    maid:Give(self.Changed:Connect(function(what, line)
        if what == "Clear" then
            for _, label in lines do label:Destroy() end
            table.clear(lines)
        elseif what == "Add" then
            add(line)
        end
    end))
    maid:Give(self.StateChanged:Connect(function() frame.Visible = self.Visible end))
    return frame
end

return Log
