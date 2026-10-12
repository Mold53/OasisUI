local import = ...
local Base = import("Elements/Base")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Row = import("Components/Row")
local Popup = import("Components/Popup")

-- def: Title, Values = { "A", { Title, Value, Description, Icon } }, Default, Multi, Search (true / false, auto above 8),
--      AllowNone, Placeholder, MaxVisible, Callback(value | list)
local Dropdown = Base.Class("Dropdown")

local function normalize(values)
    local out = {}
    for _, value in values or {} do
        if type(value) == "table" then
            local key = value.Value or value.Title or value.Name
            table.insert(out, { Value = tostring(key), Title = value.Title or value.Name or tostring(key), Description = value.Description or value.Desc, Icon = value.Icon })
        else
            table.insert(out, { Value = tostring(value), Title = tostring(value) })
        end
    end
    return out
end

function Dropdown.new(container, def)
    local self = setmetatable({}, Dropdown)
    Base.Init(self, container, def)
    self.Multi = def.Multi == true
    self.Options = normalize(def.Values or def.Options)
    local default = def.Default
    if default == nil then default = def.Value end
    if self.Multi then
        local list = {}
        if type(default) == "table" then
            -- accepts { "A", "B" } and { A = true }
            for key, value in default do
                if type(key) == "number" then table.insert(list, tostring(value)) elseif value == true then table.insert(list, tostring(key)) end
            end
        elseif default ~= nil then
            table.insert(list, tostring(default))
        end
        self.Value = self:_order(list)
    else
        if default == nil and not def.AllowNone and self.Options[1] then default = self.Options[1].Value end
        if type(default) == "number" and self.Options[default] then default = self.Options[default].Value end
        self.Value = default ~= nil and tostring(default) or nil
    end
    self.Default = self.Multi and table.clone(self.Value) or self.Value
    return self
end

function Dropdown:_find(value)
    for index, option in self.Options do
        if option.Value == value then return option, index end
    end
    return nil
end

-- multi selection follows option order
function Dropdown:_order(list)
    local set = {}
    for _, value in list do set[value] = true end
    local out = {}
    for _, option in self.Options do
        if set[option.Value] then
            table.insert(out, option.Value)
            set[option.Value] = nil
        end
    end
    for _, value in list do
        if set[value] then table.insert(out, value); set[value] = nil end
    end
    return out
end

function Dropdown:IsSelected(value)
    if self.Multi then return table.find(self.Value, value) ~= nil end
    return self.Value == value
end

function Dropdown:Set(value, silent)
    if self.Multi then
        local list = {}
        if type(value) == "table" then
            for key, entry in value do
                if type(key) == "number" then table.insert(list, tostring(entry)) elseif entry == true then table.insert(list, tostring(key)) end
            end
        elseif value ~= nil then
            table.insert(list, tostring(value))
        end
        list = self:_order(list)
        if table.concat(list, "\0") == table.concat(self.Value, "\0") then return end
        self:_commit(list, silent)
    else
        value = value ~= nil and tostring(value) or nil
        if value == self.Value then return end
        self:_commit(value, silent)
    end
end
Dropdown.Select = Dropdown.Set

function Dropdown:Toggle(value)
    if not self.Multi then
        self:Set(value)
        return
    end
    local list = table.clone(self.Value)
    local index = table.find(list, value)
    if index then table.remove(list, index) else table.insert(list, value) end
    self:Set(list)
end

-- replaces the options; keep = true keeps selected values that still exist
function Dropdown:Refresh(values, keep)
    self.Options = normalize(values)
    self.StateChanged:Fire("Options")
    if self.Multi then
        local list = {}
        if keep ~= false then
            for _, value in self.Value do
                if self:_find(value) then table.insert(list, value) end
            end
        end
        self:Set(list)
    elseif not (keep ~= false and self.Value and self:_find(self.Value)) then
        self:Set((not self.Def.AllowNone and self.Options[1]) and self.Options[1].Value or nil)
    end
end
Dropdown.SetValues = Dropdown.Refresh

function Dropdown:Add(value)
    local values = {}
    for _, option in self.Options do table.insert(values, option) end
    table.insert(values, value)
    self:Refresh(values)
end

function Dropdown:Remove(value)
    local values = {}
    for _, option in self.Options do
        if option.Value ~= tostring(value) then table.insert(values, option) end
    end
    self:Refresh(values)
end

function Dropdown:GetValues()
    local out = {}
    for _, option in self.Options do table.insert(out, option.Value) end
    return out
end

function Dropdown:Save()
    return self.Multi and table.clone(self.Value) or (self.Value or false)
end

function Dropdown:Load(data)
    if data == false then data = nil end
    self:Set(data)
end

function Dropdown:Matches(query)
    if Base.Matches(self, query) then return true end
    for _, option in self.Options do
        if option.Title:lower():find(query, 1, true) then return true end
    end
    return false
end

function Dropdown:DisplayText()
    if self.Multi then
        if #self.Value == 0 then return nil end
        local titles = {}
        for _, value in self.Value do
            local option = self:_find(value)
            table.insert(titles, option and option.Title or value)
        end
        return table.concat(titles, ", ")
    end
    if self.Value == nil then return nil end
    local option = self:_find(self.Value)
    return option and option.Title or self.Value
end

function Dropdown:_open(field, chevron)
    local search = self.Def.Search
    if search == nil then search = #self.Options > 8 end
    local maxVisible = self.Def.MaxVisible or 7
    Util.Tween(chevron, 0.18, { Rotation = 180 })

    Popup.Open({
        Anchor = field,
        MinWidth = 170,
        Padding = 5,
        OnClose = function() Util.Tween(chevron, 0.18, { Rotation = 0 }) end,
        Build = function(frame, popup)
            Util.List(frame, 4)
            local query = ""
            local box
            if search then
                local holder, api = Row.Field(frame, { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Radius = 5 })
                holder.ZIndex = 101
                Util.Icon("search", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 8, 0.5, -6), Color = "TextMuted", ZIndex = 102, Parent = holder })
                box = Util.New("TextBox", {
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.fromOffset(26, 0),
                    PlaceholderText = "Search...",
                    Text = "",
                    TextSize = 12,
                    ZIndex = 102,
                    Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
                    Parent = holder,
                })
                box.Focused:Connect(function() api.SetFocused(true) end)
                box.FocusLost:Connect(function() api.SetFocused(false) end)
            end

            if self.Multi then
                local actions = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 2, ZIndex = 101, Parent = frame })
                Util.List(actions, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
                Util.Padding(actions, 0, 4, 0, 4)
                local function action(text, order, fn)
                    local button = Util.New("TextButton", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.fromScale(0, 1),
                        BackgroundTransparency = 1,
                        Text = text,
                        TextSize = 11,
                        LayoutOrder = order,
                        ZIndex = 102,
                        Theme = { TextColor3 = "Accent", FontFace = Theme.Font(Enum.FontWeight.SemiBold) },
                        Parent = actions,
                    })
                    button.MouseButton1Click:Connect(fn)
                end
                action("Select all", 1, function()
                    local list = {}
                    for _, option in self.Options do
                        if query == "" or option.Title:lower():find(query, 1, true) then table.insert(list, option.Value) end
                    end
                    for _, value in self.Value do table.insert(list, value) end
                    self:Set(list)
                end)
                action("Clear", 2, function() self:Set({}) end)
            end

            local list = Util.New("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, 0),
                LayoutOrder = 3,
                ZIndex = 101,
                ScrollBarThickness = 2,
                Theme = { ScrollBarImageColor3 = "TextMuted" },
                Parent = frame,
            })
            Util.List(list, 1)
            local empty = Util.Label({
                Text = "No results",
                TextSize = 11,
                Color = "TextMuted",
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.new(1, 0, 0, 24),
                Visible = false,
                LayoutOrder = 4,
                ZIndex = 101,
                Parent = frame,
            })

            local rows = {}
            local function paintRows()
                for _, entry in rows do
                    local selected = self:IsSelected(entry.Option.Value)
                    entry.Selected = selected
                    Theme.Refresh(entry.Title, 0.1)
                    Theme.Refresh(entry.Mark, 0.1)
                    Theme.Refresh(entry.Button, 0.1)
                end
            end

            local function layout()
                local visible, height = 0, 0
                for _, entry in rows do
                    local show = query == "" or entry.Option.Title:lower():find(query, 1, true) ~= nil
                        or (entry.Option.Description and entry.Option.Description:lower():find(query, 1, true) ~= nil)
                    entry.Button.Visible = show
                    if show then
                        visible += 1
                        if visible <= maxVisible then height += entry.Button.Size.Y.Offset + 1 end
                    end
                end
                list.Size = UDim2.new(1, 0, 0, height)
                empty.Visible = visible == 0
            end

            local function build()
                for _, entry in rows do entry.Button:Destroy() end
                table.clear(rows)
                for index, option in self.Options do
                    local entry = { Option = option, Selected = false, Hover = false }
                    local tall = option.Description ~= nil
                    local button = Util.New("TextButton", {
                        Size = UDim2.new(1, -4, 0, tall and 38 or 26),
                        LayoutOrder = index,
                        ZIndex = 102,
                        Theme = {
                            BackgroundColor3 = "ElevatedHover",
                            BackgroundTransparency = function() return entry.Hover and 0 or (entry.Selected and 0.55 or 1) end,
                        },
                        Parent = list,
                    })
                    Util.Corner(5, button)
                    entry.Button = button
                    local x = 26
                    entry.Mark = Util.Icon("check", {
                        Size = UDim2.fromOffset(12, 12),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0, 13, 0, tall and 13 or 13),
                        ZIndex = 103,
                        Theme = {
                            ImageColor3 = "Accent",
                            ImageTransparency = function() return entry.Selected and 0 or 1 end,
                        },
                        Parent = button,
                    })
                    if option.Icon then
                        Util.Icon(option.Icon, { Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(x, 6), Color = "TextDim", ZIndex = 103, Parent = button })
                        x += 20
                    end
                    entry.Title = Util.Label({
                        Text = option.Title,
                        TextSize = 12,
                        Weight = Enum.FontWeight.Medium,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Size = UDim2.new(1, -x - 6, 0, 26),
                        Position = UDim2.fromOffset(x, 0),
                        ZIndex = 103,
                        Theme = { TextColor3 = function(t) return entry.Selected and t.Text or t.TextDim end },
                        Parent = button,
                    })
                    if tall then
                        Util.Label({
                            Text = option.Description,
                            TextSize = 10,
                            Color = "TextMuted",
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            Size = UDim2.new(1, -x - 6, 0, 12),
                            Position = UDim2.fromOffset(x, 21),
                            ZIndex = 103,
                            Parent = button,
                        })
                    end
                    button.MouseEnter:Connect(function() entry.Hover = true; Theme.Refresh(button, 0.08) end)
                    button.MouseLeave:Connect(function() entry.Hover = false; Theme.Refresh(button, 0.08) end)
                    button.MouseButton1Click:Connect(function()
                        if self.Locked then return end
                        if self.Multi then
                            self:Toggle(option.Value)
                        else
                            if self.Value == option.Value and self.Def.AllowNone then
                                self:Set(nil)
                            else
                                self:Set(option.Value)
                            end
                            popup:Close()
                        end
                    end)
                    table.insert(rows, entry)
                end
                paintRows()
                layout()
            end
            build()

            popup.Maid:Give(self.Changed:Connect(paintRows))
            popup.Maid:Give(self.StateChanged:Connect(function(what)
                if what == "Options" then build() end
            end))
            if box then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    query = box.Text:lower()
                    layout()
                end)
                box.FocusLost:Connect(function(enter)
                    if not enter or self.Multi then return end
                    for _, entry in rows do
                        if entry.Button.Visible then
                            self:Set(entry.Option.Value)
                            popup:Close()
                            return
                        end
                    end
                end)
                task.defer(function() if box.Parent then box:CaptureFocus() end end)
            end
        end,
    })
end

function Dropdown:Render(parent, maid)
    local row = Row.new(self, parent, maid, { Below = true })
    local field = Row.Field(row.Below, { Button = true, Size = UDim2.new(1, 0, 0, 28) })
    local text = Util.Label({
        TextSize = 12,
        Weight = Enum.FontWeight.Medium,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, -54, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        Theme = { TextColor3 = function(t) return self:DisplayText() and t.Text or t.TextMuted end },
        Parent = field,
    })
    local badge = Util.New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Visible = false,
        Theme = { BackgroundColor3 = "Accent" },
        Parent = field,
    })
    Util.Corner(UDim.new(1, 0), badge)
    Util.Padding(badge, 0, 5, 0, 5)
    local count = Util.Label({
        TextSize = 10,
        Color = "OnAccent",
        Weight = Enum.FontWeight.Bold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = badge,
    })
    Util.New("UISizeConstraint", { MinSize = Vector2.new(16, 16), Parent = badge })
    local chevron = Util.Icon("chevron-down", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Color = "TextMuted",
        Parent = field,
    })

    local function paint()
        text.Text = self:DisplayText() or (self.Def.Placeholder or (self.Multi and "None selected" or "Select..."))
        Theme.Refresh(text)
        local many = self.Multi and #self.Value > 0
        badge.Visible = many
        count.Text = many and tostring(#self.Value) or ""
        text.Size = UDim2.new(1, many and -76 or -54, 1, 0)
    end
    paint()
    maid:Give(self.Changed:Connect(paint))
    maid:Give(self.StateChanged:Connect(function(what) if what == "Options" then paint() end end))

    field.MouseButton1Click:Connect(function()
        if self.Locked then return end
        if Popup.Current and Popup.Current.Anchor == field then
            Popup.Current:Close()
            return
        end
        self:_open(field, chevron)
    end)
    return row.Frame
end

return Dropdown
