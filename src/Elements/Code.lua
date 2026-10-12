local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Tooltip = import("Components/Tooltip")

-- monospace block: a short preview, a click opens the whole text in a scrolling dialog
-- def: Title, Code, Lines (preview lines, default 6), Editable, OnSave(text) -> ok, message, OnCopy()
local Code = Base.Class("Code")

local MONO = "rbxasset://fonts/families/RobotoMono.json"

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

local function copy(text)
    if type(setclipboard) ~= "function" then return false end
    return (pcall(setclipboard, text))
end

-- the whole text in a dialog; Editable: a Save button runs OnSave first, a false keeps the dialog open
function Code:Open()
    local editable = self.Def.Editable == true and not self.Locked
    local buttons = {
        { Title = "Copy", Style = "Secondary", Callback = function(text)
            copy(text)
            Util.Safe(self.Def.OnCopy)
            return false
        end },
    }
    if editable then
        table.insert(buttons, { Title = "Cancel", Style = "Secondary" })
        table.insert(buttons, { Title = "Save", Style = "Primary", Callback = function(text, dialog)
            if self.Def.OnSave then
                local ok, valid, message = pcall(self.Def.OnSave, text)
                if not ok then
                    dialog:SetError(tostring(valid))
                    return false
                end
                if valid == false then
                    dialog:SetError(message or "Not saved.")
                    return false
                end
            end
            self:Set(text)
            return true
        end })
    else
        table.insert(buttons, { Title = "Close", Style = "Primary" })
    end
    -- "<card> · <title>": the dialog covers the card it came from
    local owner = self.Module and self.Module.Title
    local title = self.Title ~= "" and self.Title or "Code"
    if owner and owner ~= "" and owner ~= title then title = owner .. " · " .. title end
    return self.Window:Dialog({
        Title = title,
        Icon = editable and "pencil" or "file-code",
        Width = 480,
        Input = { Default = self.Value, Multiline = true, Height = 300, Monospace = true, ReadOnly = not editable },
        Buttons = buttons,
    })
end

function Code:Render(parent, maid)
    local lines = self.Def.Lines or 6
    local box = maid:Give(Util.New("TextButton", {
        Name = "Code",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Visible = self.Visible,
        Theme = { BackgroundColor3 = "Background", BackgroundTransparency = function() return 0.2 end },
        Parent = parent,
    }))
    Util.Corner(6, box)
    local stroke = Util.Stroke(box)
    Util.List(box, 2)
    Util.Padding(box, 0, 10, 10, 10)
    local head = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, Parent = box })
    Util.Label({
        Text = self.Title,
        TextSize = 11,
        Color = "TextMuted",
        Weight = Enum.FontWeight.SemiBold,
        Size = UDim2.new(1, -50, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    local actions = Util.New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 14),
        Parent = head,
    })
    Util.List(actions, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local function action(icon, order, tip)
        local button = Util.New("ImageButton", {
            Size = UDim2.fromOffset(13, 13),
            Image = Util.IconId(icon),
            LayoutOrder = order,
            Theme = { ImageColor3 = "TextMuted" },
            Parent = actions,
        })
        maid:Give(Tooltip.Attach(button, tip))
        return button
    end
    local open = action(self.Def.Editable and "pencil" or "maximize-2", 1, function()
        return self.Def.Editable and "Edit" or "View all"
    end)
    local copyButton = action("copy", 2, "Copy")

    -- the preview: whole lines only, cut at the right edge instead of wrapped
    local text = Util.New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = 11,
        TextWrapped = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        FontFace = Font.new(MONO),
        LayoutOrder = 2,
        Theme = { TextColor3 = "TextDim" },
        Parent = box,
    })
    local more = Util.Label({
        TextSize = 10,
        Color = "TextMuted",
        Weight = Enum.FontWeight.Medium,
        Size = UDim2.new(1, 0, 0, 16),
        TextYAlignment = Enum.TextYAlignment.Bottom,
        LayoutOrder = 3,
        Parent = box,
    })

    local function paint()
        local all = string.split(self.Value, "\n")
        local shown = math.min(#all, lines)
        text.Text = table.concat(all, "\n", 1, shown)
        local hidden = #all - shown
        more.Visible = hidden > 0
        more.Text = hidden > 0 and ("+ " .. hidden .. (hidden == 1 and " more line" or " more lines")) or ""
    end
    paint()
    maid:Give(self.Changed:Connect(paint))

    maid:Give(Util.Hover(box, function(on)
        Theme.Bind(stroke, { Color = on and "Accent" or "Stroke" })
    end))
    maid:Give(Tooltip.Attach(box, function() return self.Def.Editable and "Click to edit" or "Click to view all" end))
    box.MouseButton1Click:Connect(function() self:Open() end)
    open.MouseButton1Click:Connect(function() self:Open() end)
    copyButton.MouseButton1Click:Connect(function()
        copy(self.Value)
        copyButton.Image = Util.IconId("check")
        task.delay(1.2, function() if copyButton.Parent then copyButton.Image = Util.IconId("copy") end end)
        Util.Safe(self.Def.OnCopy)
    end)
    return box
end

return Code
