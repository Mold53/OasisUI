local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Row = import("Components/Row")
local Tooltip = import("Components/Tooltip")
local TextArea = import("Components/TextArea")

-- def: Title, Default, Placeholder, Numeric, Min, Max, Step, MaxLength, Finished (default true: commit on enter / focus lost),
--      Validate(text) -> ok, message, Icon, Multiline, Height, ClearOnFocus, Callback(value)
local Input = Base.Class("Input")

function Input.new(container, def)
    local self = setmetatable({}, Input)
    Base.Init(self, container, def)
    self.Numeric = def.Numeric == true
    local default = def.Default
    if default == nil then default = def.Value end
    self.Value = self:_coerce(default == nil and (self.Numeric and (def.Min or 0) or "") or default)
    self.Default = self.Value
    self.Error = nil
    return self
end

function Input:_coerce(value)
    if self.Numeric then
        local number = tonumber(value) or Util.ParseNumber(tostring(value)) or 0
        if self.Def.Step then number = Util.Round(number, self.Def.Step) end
        if self.Def.Min then number = math.max(number, self.Def.Min) end
        if self.Def.Max then number = math.min(number, self.Def.Max) end
        return number
    end
    local text = tostring(value)
    if self.Def.MaxLength then text = text:sub(1, self.Def.MaxLength) end
    return text
end

function Input:Set(value, silent)
    value = self:_coerce(value)
    self.Error = nil
    if value == self.Value then
        self.StateChanged:Fire("Error")
        return
    end
    self:_commit(value, silent)
end

-- user text: parse + validate, keeps an error message instead of committing
function Input:Submit(text)
    if self.Numeric then
        local number = Util.ParseNumber(text)
        if not number then
            self.Error = "Enter a number."
            self.StateChanged:Fire("Error")
            return false
        end
        if (self.Def.Min and number < self.Def.Min) or (self.Def.Max and number > self.Def.Max) then
            local min, max = self.Def.Min, self.Def.Max
            self.Error = string.format("Allowed: %s – %s", min and Util.Compact(min) or "-∞", max and Util.Compact(max) or "∞")
            self.StateChanged:Fire("Error")
            return false
        end
        text = number
    end
    if self.Def.Validate then
        local ok, valid, message = pcall(self.Def.Validate, text)
        if not ok or valid == false or valid == nil then
            self.Error = ok and (message or "Invalid value.") or tostring(valid)
            self.StateChanged:Fire("Error")
            return false
        end
    end
    self:Set(text)
    return true
end

function Input:Text()
    if self.Numeric then return Util.Format(self.Value, self.Def.Step or (math.floor(self.Value) == self.Value and 1 or 0.01)) end
    return self.Value
end

-- a compact box inside another element's row (Toggle Field); a rejected entry flashes the message and
-- the last valid value comes back
function Input:RenderInline(parent, maid, props)
    props = props or {}
    local field, api = Row.Field(parent, { Size = UDim2.fromOffset(props.Width or 96, 22), LayoutOrder = props.LayoutOrder or 0, Radius = 5 })
    local box = Util.New("TextBox", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Text = self:Text(),
        PlaceholderText = self.Def.Placeholder or "",
        TextSize = 11,
        ClearTextOnFocus = self.Def.ClearOnFocus == true,
        ClipsDescendants = true,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
        Parent = field,
    })
    local function paint()
        if not box:IsFocused() then box.Text = self:Text() end
        api.SetStroke(self.Error and "Danger" or nil)
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(function(what) if what == "Error" or what == "Locked" then paint() end end))
    if self.Tooltip then maid:Give(Tooltip.Attach(field, function() return self.Error or self.Tooltip end)) end
    box.Focused:Connect(function() api.SetFocused(true) end)
    box.FocusLost:Connect(function()
        api.SetFocused(false)
        if self.Locked then box.Text = self:Text(); return end
        if not self:Submit(box.Text) then
            local message = self.Error
            Tooltip.Show(message)
            task.delay(2, function()
                if self.Error ~= message then return end
                self.Error = nil
                self.StateChanged:Fire("Error")
            end)
        end
        box.Text = self:Text()
        paint()
    end)
    return field
end

function Input:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    Util.List(row.Below, 3)
    local height = self.Def.Multiline and (self.Def.Height or 72) or 28
    local field, api = Row.Field(row.Below, { Size = UDim2.new(1, 0, 0, height), LayoutOrder = 1 })
    local left = 10
    if self.Def.Icon then
        Util.Icon(self.Def.Icon, { Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(9, height == 28 and 7 or 8), Color = "TextMuted", Parent = field })
        left = 28
    end
    local box
    if self.Def.Multiline then
        -- long text scrolls inside the field and follows the caret
        local _
        _, box = TextArea.new({
            Size = UDim2.new(1, -left - 22, 1, -4),
            Position = UDim2.fromOffset(left - 6, 2),
            Parent = field,
            Box = {
                Text = self:Text(),
                PlaceholderText = self.Def.Placeholder or "",
                TextSize = 12,
                ClearTextOnFocus = self.Def.ClearOnFocus == true,
                Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
            },
        })
    else
        box = Util.New("TextBox", {
            Size = UDim2.new(1, -left - 28, 1, 0),
            Position = UDim2.fromOffset(left, 0),
            Text = self:Text(),
            PlaceholderText = self.Def.Placeholder or "",
            TextSize = 12,
            TextYAlignment = Enum.TextYAlignment.Center,
            ClearTextOnFocus = self.Def.ClearOnFocus == true,
            ClipsDescendants = true,
            Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
            Parent = field,
        })
    end
    local clear = Util.New("ImageButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, height == 28 and 8 or 8),
        Size = UDim2.fromOffset(12, 12),
        Image = Util.IconId("x"),
        Theme = { ImageColor3 = "TextMuted" },
        Parent = field,
    })
    local errorLabel = Util.Label({
        TextSize = 10,
        Color = "Danger",
        Size = UDim2.new(1, 0, 0, 12),
        Visible = false,
        LayoutOrder = 2,
        Parent = row.Below,
    })

    local finished = self.Def.Finished ~= false
    local function paint()
        if not box:IsFocused() then box.Text = self:Text() end
        clear.Visible = box.Text ~= "" and not self.Locked and not self.Numeric
        errorLabel.Visible = self.Error ~= nil
        errorLabel.Text = self.Error or ""
        api.SetStroke(self.Error and "Danger" or nil)
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(function(what) if what == "Error" or what == "Locked" then paint() end end))

    box.Focused:Connect(function() api.SetFocused(true) end)
    box.FocusLost:Connect(function()
        api.SetFocused(false)
        if self.Locked then box.Text = self:Text(); return end
        if finished or self.Numeric then self:Submit(box.Text) end
        paint()
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        clear.Visible = box.Text ~= "" and not self.Locked and not self.Numeric
        if not finished and not self.Numeric and box:IsFocused() then self:Submit(box.Text) end
    end)
    clear.MouseButton1Click:Connect(function()
        if self.Locked then return end
        box.Text = ""
        self:Submit("")
    end)
    return row.Frame
end

return Input
