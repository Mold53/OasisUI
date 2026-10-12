local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Row = import("Components/Row")

-- one-of-n chips; def: Title, Values, Default, Callback(value)
local Segmented = Base.Class("Segmented")

function Segmented.new(container, def)
    local self = setmetatable({}, Segmented)
    Base.Init(self, container, def)
    self.Options = {}
    for _, value in def.Values or def.Options or {} do table.insert(self.Options, tostring(value)) end
    local default = def.Default or def.Value
    if type(default) == "number" then default = self.Options[default] end
    self.Value = default and tostring(default) or self.Options[1]
    self.Default = self.Value
    return self
end

function Segmented:Set(value, silent)
    value = tostring(value)
    if value == self.Value or not table.find(self.Options, value) then return end
    self:_commit(value, silent)
end

function Segmented:Matches(query)
    if Base.Matches(self, query) then return true end
    for _, option in self.Options do
        if option:lower():find(query, 1, true) then return true end
    end
    return false
end

function Segmented:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    local track = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = "ElevatedTransparency" },
        Parent = row.Below,
    })
    Util.Corner(6, track)
    Util.Stroke(track)
    Util.Padding(track, 3)
    Util.List(track, 3, Enum.FillDirection.Horizontal)
    local chips = {}
    for index, option in self.Options do
        local chip = { hover = false }
        chip.Button = Util.New("TextButton", {
            Size = UDim2.new(0, 0, 1, 0),
            Text = option,
            TextSize = 11,
            LayoutOrder = index,
            Theme = {
                BackgroundColor3 = function(t) return self.Value == option and t.Accent or t.ElevatedHover end,
                BackgroundTransparency = function() return self.Value == option and 0 or (chip.hover and 0.3 or 1) end,
                TextColor3 = function(t) return self.Value == option and t.OnAccent or t.TextDim end,
                FontFace = Theme.Font(Enum.FontWeight.SemiBold),
            },
            Parent = track,
        })
        Util.Corner(4, chip.Button)
        Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = chip.Button })
        chip.Button.MouseEnter:Connect(function() chip.hover = true; Theme.Refresh(chip.Button, 0.1) end)
        chip.Button.MouseLeave:Connect(function() chip.hover = false; Theme.Refresh(chip.Button, 0.1) end)
        chip.Button.MouseButton1Click:Connect(function()
            if not self.Locked then self:Set(option) end
        end)
        table.insert(chips, chip)
    end
    maid:Give(self.Changed:Connect(function()
        for _, chip in chips do Theme.Refresh(chip.Button, 0.15) end
    end))
    return row.Frame
end

return Segmented
