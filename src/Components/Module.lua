local import = ...
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Signal = import("Core/Signal")
local Binding = import("Core/Binding")
local Container = import("Components/Container")
local Widgets = import("Components/Widgets")
local Menu = import("Components/Menu")
local Tooltip = import("Components/Tooltip")

-- feature card: switch + key in the header, settings fold out below
-- def: Title, Description, Icon, Flag, Default, Toggle (false = section), Keybind (false | key | { Key, Mode }),
--      Opened, Side ("Left" | "Right"), Risky (red title), Locked, Visible, Callback(enabled)
local Module = {}
Module.__index = Module
Container.Apply(Module)

function Module.new(tab, def)
    local self = setmetatable({}, Module)
    Container.Setup(self)
    local window = tab.Window
    self.Kind = "Module"
    self.Tab = tab
    self.Window = window
    self.Module = self
    self.Def = def
    self.Title = def.Title or def.Name or "Module"
    self.Description = def.Description or def.Desc
    self.Icon = def.Icon
    self.Flag = def.Flag
    self.Id = def.Id or def.Flag or (tab.Id .. "/" .. self.Title)
    self.Toggleable = def.Toggle ~= false
    self.Enabled = self.Toggleable and def.Default == true
    self.Default = self.Enabled
    self.Locked = def.Locked == true
    self.Visible = def.Visible ~= false
    self.NoSave = def.Flag == nil
    self.Changed = Signal.new()
    self.StateChanged = Signal.new()
    self._listeners = {}
    self._mounts = {}
    if def.Opened ~= nil then
        self.Expanded = def.Opened == true
    else
        self.Expanded = not self.Toggleable or (self.Enabled and window.Interface.AutoExpand)
    end

    if self.Toggleable and def.Keybind ~= false then
        local spec = type(def.Keybind) == "table" and def.Keybind or { Key = def.Keybind ~= true and def.Keybind or def.Key }
        self.Binding = Binding.new({
            Key = spec.Key or spec.Default,
            Mode = spec.Mode,
            Modes = spec.Modes or { "Toggle", "Hold" },
            Capture = spec,
            Press = function(binding)
                if self.Locked then return end
                self:SetEnabled(binding.Mode == "Hold" or not self.Enabled)
            end,
            Release = function(binding)
                if binding.Mode == "Hold" and not self.Locked then self:SetEnabled(false) end
            end,
        })
        self.Binding.Changed:Connect(function() window:_touch(true) end)
        window:_trackBind(self)
    end
    if self.Flag then
        window.Config:Register(self.Flag, self)
        window.Library.Flags[self.Flag] = self
    end
    self.Favorite = window.State.Favorites[self.Id] == true
    return self
end

function Module:_add(kind, a, b)
    local element = Container._add(self, kind, a, b)
    self.StateChanged:Fire("Children")
    return element
end

-- state -----------------------------------------------------------------------

function Module:SetEnabled(enabled, silent)
    if not self.Toggleable then return end
    enabled = enabled and true or false
    if enabled == self.Enabled then return end
    self.Enabled = enabled
    self.Changed:Fire(enabled)
    if not silent then
        Util.Safe(self.Def.Callback, enabled)
        for _, fn in self._listeners do Util.Safe(fn, enabled) end
    end
    if self.Window.Interface.AutoExpand and #self.Children > 0 then self:SetExpanded(enabled) end
    self.Window:_touch(true)
end

function Module:ToggleEnabled()
    self:SetEnabled(not self.Enabled)
end

function Module:Get()
    return self.Enabled
end

function Module:Set(value, silent)
    self:SetEnabled(value, silent)
end

function Module:OnChanged(fn)
    table.insert(self._listeners, fn)
    return self
end

function Module:SetExpanded(expanded)
    expanded = expanded and true or false
    if expanded == self.Expanded then return end
    self.Expanded = expanded
    self.StateChanged:Fire("Expanded")
end

function Module:SetFavorite(favorite)
    self.Window:_setFavorite(self, favorite and true or false)
end

function Module:SetTitle(text)
    self.Title = text
    self.StateChanged:Fire("Title")
end

function Module:SetDescription(text)
    self.Description = text
    self.StateChanged:Fire("Description")
end

function Module:SetLocked(locked)
    self.Locked = locked and true or false
    self.StateChanged:Fire("Locked")
end

function Module:SetVisible(visible)
    self.Visible = visible and true or false
    self.StateChanged:Fire("Visible")
end

-- Settings > Layout can hide card descriptions for a calmer, smaller window
function Module:_showDescription()
    return self.Description ~= nil and self.Description ~= "" and self.Window.Interface.Descriptions ~= false
end

function Module:Matches(query)
    local text = (self.Title .. " " .. (self.Description or "")):lower()
    return text:find(query, 1, true) ~= nil or self:_matchesChildren(query)
end

function Module:Reset()
    self:SetEnabled(self.Default)
    self:_eachElement(function(element)
        if element.Reset then pcall(element.Reset, element) end
    end)
end

function Module:BindInfo()
    return self.Title, self.Enabled
end

function Module:Save()
    return { Enabled = self.Enabled, Bind = self.Binding and self.Binding:Save() or nil }
end

function Module:Load(data)
    if type(data) == "boolean" then
        self:SetEnabled(data)
    elseif type(data) == "table" then
        if self.Binding and data.Bind then self.Binding:Load(data.Bind) end
        if data.Enabled ~= nil then self:SetEnabled(data.Enabled) end
    end
end

function Module:Destroy()
    for _, mount in table.clone(self._mounts) do mount:Clean() end
    for _, child in table.clone(self.Children) do child:Destroy() end
    if self.Binding then self.Binding:Destroy() end
    if self.Flag then self.Window.Config:Unregister(self.Flag, self) end
    self.Window:_removeModule(self)
end

-- view ------------------------------------------------------------------------

function Module:_menu(view, point)
    local window = self.Window
    local items: { any } = {}
    if self.Toggleable then
        table.insert(items, { Title = self.Enabled and "Disable" or "Enable", Icon = "power", Disabled = self.Locked, Callback = function() self:ToggleEnabled() end })
    end
    table.insert(items, { Title = self.Favorite and "Remove favorite" or "Add to favorites", Icon = "star", Callback = function() self:SetFavorite(not self.Favorite) end })
    if #self.Children > 0 then
        table.insert(items, { Title = self.Expanded and "Collapse" or "Expand", Icon = "chevrons-up-down", Callback = function() self:SetExpanded(not self.Expanded) end })
    end
    if self.Binding then
        table.insert(items, "-")
        table.insert(items, { Title = "Bind key", Icon = "keyboard", Hint = Util.KeyLabel(self.Binding.Key), Callback = function() self:_capture() end })
        for _, mode in self.Binding.Modes do
            table.insert(items, { Title = mode, Checked = self.Binding.Mode == mode, Callback = function() self.Binding:SetMode(mode) end })
        end
    end
    table.insert(items, "-")
    table.insert(items, { Title = self.Locked and "Unlock" or "Lock", Icon = self.Locked and "lock-open" or "lock", Callback = function() self:SetLocked(not self.Locked) end })
    if view.Page and view.Page.Draggable and #view.Page.Columns > 1 then
        table.insert(items, { Title = "Move to other column", Icon = "columns-2", Callback = function() view.Page:MoveToOther(view) end })
    end
    if view.Source then
        table.insert(items, { Title = "Open in " .. (self.Tab.Path or self.Tab.Title), Icon = "external-link", Callback = function() window:SelectTab(self.Tab, self) end })
    end
    table.insert(items, { Title = "Reset settings", Icon = "rotate-ccw", Danger = true, Callback = function() self:Reset() end })
    Menu.Open({ Point = point, Items = items, Title = self.Title, Width = 190 })
end

function Module:_capture()
    if self.Binding and not self.Locked then self.Binding:Capture() end
end

-- view: { Page, Source (show the tab tag), Maid }
function Module:Render(parent, maid, view)
    view = view or {}
    local window = self.Window
    local hover = false
    table.insert(self._mounts, maid)
    maid:Give(function()
        local index = table.find(self._mounts, maid)
        if index then table.remove(self._mounts, index) end
    end)

    local card = maid:Give(Util.New("Frame", {
        Name = "Module",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self.Visible,
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = "SurfaceTransparency" },
        Parent = parent,
    }))
    Util.Corner("ElementRadius", card)
    local stroke = Util.Stroke(card, function(t) return self.Enabled and t.Accent or t.Stroke end, function(t)
        if self.Enabled then return math.clamp(t.StrokeTransparency + 0.1, 0.35, 0.75) end
        return hover and t.StrokeTransparency - 0.15 or t.StrokeTransparency
    end)
    Util.List(card, 0)

    -- header ------------------------------------------------------------------
    local header = Util.New("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = card,
    })
    local hit = Util.New("TextButton", {
        Name = "Hit",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Parent = header,
    })
    local stack = Util.New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = header,
    })
    Util.Padding(stack, 11, 12, 10, 12)
    Util.List(stack, 3)

    local line = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = stack })
    Util.List(line, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local left = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), LayoutOrder = 1, Parent = line })
    Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = left })
    Util.List(left, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    if self.Icon then
        Util.Icon(self.Icon, { Size = UDim2.fromOffset(15, 15), Color = "Accent", LayoutOrder = 1, Parent = left })
    end
    local title = Util.Label({
        Text = self.Title,
        TextSize = 13,
        Weight = Enum.FontWeight.SemiBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = 2,
        Theme = { TextColor3 = function(t)
            if self.Locked then return t.TextDim end
            return self.Def.Risky and t.Danger or t.Text
        end },
        Parent = left,
    })
    Util.New("UISizeConstraint", { MaxSize = Vector2.new(view.Source and 140 or 190, 18), Parent = title })
    if view.Source then
        local tag = Util.New("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 16),
            LayoutOrder = 3,
            Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = "ElevatedTransparency" },
            Parent = left,
        })
        Util.Corner(4, tag)
        Util.Padding(tag, 0, 6, 0, 6)
        Util.Label({ Text = self.Tab.Path or self.Tab.Title, TextSize = 10, Color = "TextMuted", Weight = Enum.FontWeight.Medium, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = tag })
    end
    local lockIcon = Util.Icon("lock", { Size = UDim2.fromOffset(12, 12), Color = "Danger", LayoutOrder = 4, Visible = self.Locked, Parent = left })

    local right = Util.New("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, Parent = line })
    Util.List(right, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    local star = Util.New("ImageButton", {
        Size = UDim2.fromOffset(14, 14),
        Image = Util.IconId("star"),
        LayoutOrder = 1,
        Theme = {
            ImageColor3 = function(t) return self.Favorite and t.Warning or t.TextMuted end,
            -- touch has no hover: the star stays faintly visible
            ImageTransparency = function() return (self.Favorite and 0) or (hover and 0.25) or (Util.Touch() and 0.55) or 1 end,
        },
        Parent = right,
    })
    maid:Give(Tooltip.Attach(star, function() return self.Favorite and "Remove from favorites" or "Add to favorites" end))
    local grip
    if view.Page and view.Page.Draggable then
        grip = Util.New("ImageButton", {
            Size = UDim2.fromOffset(14, 14),
            Image = Util.IconId("grip-vertical"),
            LayoutOrder = 2,
            Theme = {
                ImageColor3 = "TextMuted",
                ImageTransparency = function() return (hover and 0.25) or (Util.Touch() and 0.55) or 1 end,
            },
            Parent = right,
        })
        maid:Give(Tooltip.Attach(grip, "Drag to rearrange"))
    end
    local headChevron
    if not self.Toggleable then
        headChevron = Util.Icon("chevron-down", { Size = UDim2.fromOffset(14, 14), Color = "TextMuted", LayoutOrder = 3, Parent = right })
    end

    local desc = Util.Label({
        Text = self.Description or "",
        TextSize = 11,
        Color = "TextMuted",
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = self:_showDescription(),
        LayoutOrder = 2,
        Parent = stack,
    })

    local switchPaint, chevron
    if self.Toggleable then
        local divider = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 11), LayoutOrder = 3, Parent = stack })
        local rule = Util.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 24, 0, 1),
            Theme = { BackgroundColor3 = "Divider" },
            Parent = divider,
        })
        Util.New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.6),
            }),
            Parent = rule,
        })

        local bottom = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 4, Parent = stack })
        if self.Binding then
            local pill, connection = Widgets.KeyPill(bottom, self.Binding, { Position = UDim2.new(0, 0, 0.5, 0) })
            maid:Give(connection)
            pill.Name = "Key"
        end
        local controls = Util.New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            Parent = bottom,
        })
        Util.List(controls, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
        chevron = Util.New("ImageButton", {
            Size = UDim2.fromOffset(16, 16),
            Image = Util.IconId("chevron-down"),
            LayoutOrder = 1,
            Visible = #self.Children > 0,
            Theme = { ImageColor3 = "TextMuted" },
            Parent = controls,
        })
        local switchHit = Util.New("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromOffset(30, 16), LayoutOrder = 2, Parent = controls })
        local _, paint = Widgets.Switch(switchHit, { AnchorPoint = Vector2.zero, Position = UDim2.fromScale(0, 0) })
        switchPaint = paint
        switchPaint(self.Enabled, false)
        switchHit.MouseButton1Click:Connect(function() if not self.Locked then self:ToggleEnabled() end end)
        chevron.MouseButton1Click:Connect(function() self:SetExpanded(not self.Expanded) end)
    end

    -- body --------------------------------------------------------------------
    local body = Util.New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = 2,
        Parent = card,
    })
    local options = Util.New("Frame", {
        Name = "Options",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = body,
    })
    -- 2 px on top: the body clips, a first control's outline would lose its top edge
    Util.Padding(options, 2, 12, 12, 12)
    Util.List(options, 9)
    self:_mountChildren(options, maid)

    local lockShade = Util.New("TextButton", {
        Name = "Lock",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 30,
        Visible = self.Locked,
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = function() return 0.45 end },
        Parent = body,
    })
    local function lockText()
        return Util.Touch() and "Locked. Hold the header to unlock." or "Locked. Right-click the header to unlock."
    end
    maid:Give(Tooltip.Attach(lockShade, lockText))
    lockShade.MouseButton1Click:Connect(function() Tooltip.Show(lockText()) end)

    local animating = 0
    local function height()
        return options.AbsoluteSize.Y / window:GetScale()
    end
    local function paintBody(animate)
        local open = self.Expanded and #self.Children > 0
        local goal = open and height() or 0
        if animate then
            animating += 1
            local mine = animating
            Util.Tween(body, 0.28, { Size = UDim2.new(1, 0, 0, goal) })
            task.delay(0.3 / math.max(Theme.Current.AnimSpeed or 1, 0.05), function()
                if mine ~= animating then return end
                animating = 0
                -- content that resized during the animation (wrapped text, late layouts) is caught up here
                if self.Expanded and #self.Children > 0 then body.Size = UDim2.new(1, 0, 0, height()) end
            end)
        else
            body.Size = UDim2.new(1, 0, 0, goal)
        end
        -- up while open: a click folds it; an image swap, Rotation does not render inside the clipping columns
        local arrow = Util.IconId(self.Expanded and "chevron-up" or "chevron-down")
        if chevron then
            chevron.Image = arrow
            chevron.Visible = #self.Children > 0
        end
        if headChevron then
            headChevron.Image = arrow
            headChevron.Visible = #self.Children > 0
        end
    end
    paintBody(false)
    maid:Give(options:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        -- no children: the padding alone would open an empty strip under the header
        if animating == 0 and self.Expanded and #self.Children > 0 then body.Size = UDim2.new(1, 0, 0, height()) end
    end))

    local function paint(what)
        if what == nil or what == "Title" then title.Text = self.Title end
        if what == nil or what == "Description" then
            desc.Text = self.Description or ""
            desc.Visible = self:_showDescription()
        end
        if what == nil or what == "Locked" then
            lockIcon.Visible = self.Locked
            lockShade.Visible = self.Locked
            Theme.Refresh(title, 0.15)
        end
        if what == "Visible" then card.Visible = self.Visible end
        if what == "Expanded" or what == "Children" then paintBody(what == "Expanded") end
        if what == "Favorite" then Theme.Refresh(star, 0.15) end
    end
    maid:Give(self.StateChanged:Connect(paint))
    maid:Give(self.Changed:Connect(function(enabled)
        if switchPaint then switchPaint(enabled, true) end
        Theme.Refresh(stroke, 0.2)
    end))

    maid:Give(Util.Hover(card, function(on)
        hover = on
        Theme.Refresh(star, 0.12)
        if grip then Theme.Refresh(grip, 0.12) end
        Theme.Refresh(stroke, 0.12)
    end))

    star.MouseButton1Click:Connect(function() self:SetFavorite(not self.Favorite) end)
    if grip then
        grip.InputBegan:Connect(function(input)
            if Util.IsPress(input) then view.Page:BeginDrag(view, input) end
        end)
    end
    -- touch: a long press opens the menu that right-click opens with a mouse
    local press, consumed = Util.LongPress(hit, function(point) self:_menu(view, point) end)
    maid:Give(press)
    hit.MouseButton1Click:Connect(function()
        if consumed() then return end
        if self.Toggleable then
            if not self.Locked then self:ToggleEnabled() end
        else
            self:SetExpanded(not self.Expanded)
        end
    end)
    hit.MouseButton2Click:Connect(function()
        self:_menu(view, Util.Pointer())
    end)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton3 then self:_capture() end
    end)

    view.Card = card
    return card
end

return Module
