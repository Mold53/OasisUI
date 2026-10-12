local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")

-- monospace block with a copy button; def: Title, Code, OnCopy()
local Code = Base.Class("Code")

function Code.new(container, def)
    local self = setmetatable({}, Code)
    Base.Init(self, container, def)
    self.Title = def.Title or ""
    self.Value = def.Code or def.Content or ""
    self.NoSave = true
    return self
end

function Code:Set(code)
    self.Value = tostring(code)
    self.Changed:Fire(self.Value)
end

function Code:Render(parent, maid)
    local box = maid:Give(Util.New("Frame", {
        Name = "Code",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Theme = { BackgroundColor3 = "Background", BackgroundTransparency = function() return 0.2 end },
        Parent = parent,
    }))
    Util.Corner(6, box)
    Util.Stroke(box)
    local head = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Parent = box })
    Util.Label({
        Text = self.Title,
        TextSize = 11,
        Color = "TextMuted",
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        Parent = head,
    })
    local copy = Util.New("ImageButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(13, 13),
        Image = Util.IconId("copy"),
        Theme = { ImageColor3 = "TextMuted" },
        Parent = head,
    })
    local text = Util.New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.fromOffset(10, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = self.Value,
        TextSize = 11,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json"),
        Theme = { TextColor3 = "TextDim" },
        Parent = box,
    })
    Util.Padding(text, 0, 0, 10, 0)
    copy.MouseButton1Click:Connect(function()
        if type(setclipboard) == "function" then pcall(setclipboard, self.Value) end
        copy.Image = Util.IconId("check")
        task.delay(1.2, function() if copy.Parent then copy.Image = Util.IconId("copy") end end)
        Util.Safe(self.Def.OnCopy)
    end)
    maid:Give(self.Changed:Connect(function() text.Text = self.Value end))
    return box
end

return Code
