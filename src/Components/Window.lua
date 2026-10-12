local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Maid = import("Core/Maid")
local Drag = import("Core/Drag")
local Storage = import("Core/Storage")
local Config = import("Core/Config")
local Binding = import("Core/Binding")
local Layer = import("Components/Layer")
local Popup = import("Components/Popup")
local Tooltip = import("Components/Tooltip")
local Dialog = import("Components/Dialog")
local Notification = import("Components/Notification")
local Page = import("Components/Page")
local Tab = import("Components/Tab")
local Overlays = import("Components/Overlays")
local Acrylic = import("Components/Acrylic")

local UIS = Services.UserInputService
local Window = {}
Window.__index = Window

local TOP = 50
local SIDEBAR = 164
local COMPACT = 56
local MIN_SIZE = Vector2.new(560, 380)

local INTERFACE = {
    Scale = false,           -- false = fit the screen
    AutoExpand = true,
    Compact = false,
    ToggleKey = "RightShift",
    KeybindList = false,
    Watermark = false,
    Acrylic = false,
    HideUser = false,
    NotifyPosition = "BottomRight",
}

-- def: Title, Subtitle, Icon, Folder, Size, Theme, Tags, ToggleKey, User, Settings, AutoLoad, MinSize
function Window.new(library, def)
    local self = setmetatable({
        Library = library,
        Def = def,
        Maid = Maid.new(),
        Tabs = {},
        Entries = {},
        _binds = {},
        Visible = true,
        Minimized = false,
    }, Window)
    self.Folder = def.Folder or (def.Title and def.Title:gsub("[^%w_%- ]", "")) or "OasisUI"
    self.Config = Config.new(self.Folder)
    self:_loadState()

    if self.State.Theme then
        Theme.Import(self.State.Theme)
    elseif def.Theme then
        Theme.UsePalette(def.Theme)
    end
    if def.ThemeOverrides then Theme.Set(def.ThemeOverrides) end
    self.Maid:Give(Theme.Changed:Connect(function() self:SaveState() end))
    Notification.SetPosition(self.Interface.NotifyPosition)

    self:_build()
    self.Favorites = Page.new(self, {
        Id = "favorites",
        Draggable = true,
        Source = true,
        Empty = "No favorites yet.\nClick the star on any module to pin it here.",
        EmptyIcon = "star",
    })
    self.Favorites:UpdateEmpty()
    self.SearchPage = Page.new(self, { Id = "search", Source = true, EmptyIcon = "search" })

    self.MenuBinding = Binding.new({
        Key = self.Interface.ToggleKey,
        Mode = "Toggle",
        Modes = { "Toggle" },
        Press = function() self:Toggle() end,
    })
    self.MenuBinding.Changed:Connect(function()
        self.Interface.ToggleKey = self.MenuBinding.Key or false
        self:SaveState()
    end)
    self.Maid:Give(self.MenuBinding)

    self.Overlays = Overlays.new(self)
    self.Overlays:SetKeybindList(self.Interface.KeybindList)
    self.Overlays:SetWatermark(self.Interface.Watermark)
    if UIS.TouchEnabled then self.Overlays:SetMobileButton(true) end
    self.Acrylic = Acrylic.new(self.Root, self.Maid)
    self.Acrylic:SetEnabled(self.Interface.Acrylic)

    if def.Settings ~= false then
        import("Addons/Settings")(self)
    end
    if self.Interface.Tab == "favorites" then
        self._restored = true
        self:SelectFavorites()
    end

    if def.AutoLoad ~= false then
        task.defer(function() self:LoadAutoload() end)
    end
    self:_open()
    return self
end

-- state -----------------------------------------------------------------------

function Window:_loadState()
    local state = Storage.ReadJSON(self.Folder .. "/ui.json")
    if type(state) ~= "table" then state = {} end
    state.Favorites = type(state.Favorites) == "table" and state.Favorites or {}
    state.Layout = type(state.Layout) == "table" and state.Layout or {}
    state.Interface = type(state.Interface) == "table" and state.Interface or {}
    local defaults = table.clone(INTERFACE)
    if self.Def.ToggleKey then defaults.ToggleKey = Binding.KeyName(self.Def.ToggleKey) end
    for key, value in defaults do
        if state.Interface[key] == nil then state.Interface[key] = value end
    end
    self.State = state
    self.Interface = state.Interface
end

function Window:SaveState()
    if self._saveQueued then return end
    self._saveQueued = true
    task.delay(0.5, function()
        self._saveQueued = false
        if self.Destroyed then return end
        self.State.Theme = Theme.Export()
        Storage.WriteJSON(self.Folder .. "/ui.json", self.State)
    end)
end

-- element changed: config autosave, keybind list
function Window:_touch(binds)
    self.Config:Touch()
    if self.Overlays and (binds or self.Interface.KeybindList) then self.Overlays:RefreshBinds() end
end

function Window:_trackBind(owner)
    table.insert(self._binds, owner)
end

function Window:GetScale()
    return self.Scale or 1
end

-- build -----------------------------------------------------------------------

local function iconButton(parent, icon, order, tip)
    local hover = false
    local button = Util.New("ImageButton", {
        Size = UDim2.fromOffset(28, 28),
        LayoutOrder = order,
        Theme = {
            BackgroundColor3 = "ElevatedHover",
            BackgroundTransparency = function() return hover and 0.3 or 1 end,
        },
        Parent = parent,
    })
    Util.Corner(6, button)
    local image = Util.Icon(icon, {
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Theme = { ImageColor3 = function(t) return hover and t.Text or t.TextDim end },
        Parent = button,
    })
    button.MouseEnter:Connect(function() hover = true; Theme.Refresh(button, 0.12); Theme.Refresh(image, 0.12) end)
    button.MouseLeave:Connect(function() hover = false; Theme.Refresh(button, 0.12); Theme.Refresh(image, 0.12) end)
    if tip then Tooltip.Attach(button, tip) end
    return button, image
end

function Window:_build()
    local def = self.Def
    local size = def.Size or UDim2.fromOffset(780, 520)
    if type(self.Interface.Size) == "table" then size = UDim2.fromOffset(self.Interface.Size[1], self.Interface.Size[2]) end
    self.MinSize = def.MinSize or MIN_SIZE

    local root = self.Maid:Give(Util.New("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        ClipsDescendants = true,
        Active = true,
        Theme = {
            BackgroundColor3 = function(t) return t.Gradient and Color3.new(1, 1, 1) or t.Background end,
            BackgroundTransparency = "WindowTransparency",
        },
        Parent = Layer.Main,
    }))
    if type(self.Interface.Position) == "table" then
        root.Position = UDim2.new(0.5, self.Interface.Position[1], 0.5, self.Interface.Position[2])
    end
    self.Root = root
    Util.Corner("Radius", root)
    Util.Stroke(root)
    Util.New("UIGradient", {
        Theme = {
            Enabled = "Gradient",
            Rotation = "GradientRotation",
            Color = function(t)
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, t.BackgroundAlt),
                    ColorSequenceKeypoint.new(0.55, t.Background),
                    ColorSequenceKeypoint.new(1, t.Background),
                })
            end,
        },
        Parent = root,
    })
    self.UIScale = Util.New("UIScale", { Parent = root })

    -- topbar ------------------------------------------------------------------
    local topbar = Util.New("Frame", { Name = "Topbar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TOP), Parent = root })
    self.Topbar = topbar
    local logo = Util.Icon(def.Icon or "sparkles", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(16, 14),
        Theme = { ImageColor3 = function() return Color3.new(1, 1, 1) end },
        Parent = topbar,
    })
    Util.New("UIGradient", {
        Rotation = 45,
        Theme = { Color = function(t) return ColorSequence.new(t.Accent, t.AccentAlt) end },
        Parent = logo,
    })

    local heading = Util.New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(48, 8), Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, Parent = topbar })
    Util.List(heading, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    local title = Util.Label({
        Text = def.Title or "OasisUI",
        TextSize = 15,
        Weight = Enum.FontWeight.Bold,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        LayoutOrder = 1,
        Theme = { TextColor3 = function(t) return t.AnimatedTitle and Color3.new(1, 1, 1) or t.Text end },
        Parent = heading,
    })
    self.TitleLabel = title
    local titleGradient = Util.New("UIGradient", {
        Theme = {
            Enabled = "AnimatedTitle",
            Color = function(t)
                return ColorSequence.new({
                    ColorSequenceKeypoint.new(0, t.Accent),
                    ColorSequenceKeypoint.new(0.5, t.AccentAlt),
                    ColorSequenceKeypoint.new(1, t.Accent),
                })
            end,
        },
        Parent = title,
    })
    self.Maid:Give(Services.RunService.Heartbeat:Connect(function()
        if Theme.Current.AnimatedTitle and root.Visible then
            titleGradient.Offset = Vector2.new(math.sin(os.clock() * 1.3) * 0.5, 0)
        end
    end))
    for index, tag in def.Tags or {} do
        tag = type(tag) == "string" and { Text = tag } or tag
        local chip = Util.New("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 16),
            LayoutOrder = 1 + index,
            Theme = if tag.Color then nil else { BackgroundColor3 = "Elevated" },
            BackgroundColor3 = tag.Color,
            Parent = heading,
        })
        Util.Corner(4, chip)
        Util.Padding(chip, 0, 6, 0, 6)
        Util.Label({
            Text = tag.Text or tag.Title or "",
            TextSize = 10,
            Weight = Enum.FontWeight.SemiBold,
            Color = tag.Color and "OnAccent" or "TextDim",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            Parent = chip,
        })
    end
    self.SubtitleLabel = Util.Label({
        Text = def.Subtitle or def.SubTitle or "",
        TextSize = 11,
        Color = "TextMuted",
        Position = UDim2.fromOffset(48, 27),
        Size = UDim2.new(0, 260, 0, 14),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topbar,
    })

    local actions = Util.New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 28),
        Parent = topbar,
    })
    Util.List(actions, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
    self.Actions = actions

    -- search
    local searchFocused = false
    local search = Util.New("Frame", {
        Name = "Search",
        Size = UDim2.fromOffset(200, 28),
        LayoutOrder = 1,
        Visible = def.Search ~= false,
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = "ElevatedTransparency" },
        Parent = actions,
    })
    Util.Corner(7, search)
    local searchStroke = Util.Stroke(search, function(t) return searchFocused and t.Accent or t.Stroke end, function(t)
        return searchFocused and 0.3 or t.StrokeTransparency + 0.1
    end)
    Util.Icon("search", { Size = UDim2.fromOffset(13, 13), Position = UDim2.new(0, 9, 0.5, -6), Color = "TextMuted", Parent = search })
    local searchBox = Util.New("TextBox", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(28, 0),
        PlaceholderText = "Search features",
        Text = "",
        TextSize = 12,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "TextMuted", FontFace = Theme.Font(Enum.FontWeight.Medium) },
        Parent = search,
    })
    local hint = Util.Label({
        Text = "Ctrl F",
        TextSize = 10,
        Color = "TextMuted",
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(34, 14),
        Parent = search,
    })
    local clearSearch = Util.New("ImageButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        Image = Util.IconId("x"),
        Visible = false,
        Theme = { ImageColor3 = "TextMuted" },
        Parent = search,
    })
    self.SearchBox = searchBox
    searchBox.Focused:Connect(function() searchFocused = true; Theme.Refresh(searchStroke, 0.15) end)
    searchBox.FocusLost:Connect(function() searchFocused = false; Theme.Refresh(searchStroke, 0.15) end)
    local searchToken = 0
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = searchBox.Text
        hint.Visible = text == ""
        clearSearch.Visible = text ~= ""
        searchToken += 1
        local mine = searchToken
        task.delay(0.12, function()
            if mine == searchToken then self:_search(text) end
        end)
    end)
    clearSearch.MouseButton1Click:Connect(function() searchBox.Text = "" end)
    self.Maid:Give(UIS.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F and root.Visible and not self.Minimized
            and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
            task.defer(function() searchBox:CaptureFocus() end)
        end
    end))

    local minimize, minimizeIcon = iconButton(actions, "minus", 2, "Minimize")
    local close = iconButton(actions, "x", 3, function()
        return "Hide (" .. Util.KeyLabel(self.MenuBinding and self.MenuBinding.Key) .. ")"
    end)
    self.MinimizeIcon = minimizeIcon
    minimize.MouseButton1Click:Connect(function() self:SetMinimized(not self.Minimized) end)
    close.MouseButton1Click:Connect(function()
        self:SetVisible(false)
        local key = self.MenuBinding and self.MenuBinding.Key
        self.Library:Notify({
            Title = "Menu hidden",
            Content = key and ("Press " .. Util.KeyLabel(key) .. " to open it again.") or "Use the menu button to open it again.",
            Duration = 4,
        })
    end)

    local topDivider = Util.New("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.fromOffset(12, TOP),
        Theme = { BackgroundColor3 = "Divider" },
        Parent = root,
    })
    Util.New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = topDivider,
    })
    self.TopDivider = topDivider

    -- sidebar -----------------------------------------------------------------
    local sidebar = Util.New("Frame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, TOP + 1),
        Size = UDim2.new(0, SIDEBAR, 1, -TOP - 1),
        Parent = root,
    })
    self.Sidebar = sidebar
    local bottomHeight = def.User == false and 46 or 94
    local list = Util.New("ScrollingFrame", {
        Name = "Tabs",
        Size = UDim2.new(1, 0, 1, -bottomHeight),
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.5,
        Theme = { ScrollBarImageColor3 = "TextMuted" },
        Parent = sidebar,
    })
    Util.Padding(list, 10, 10, 10, 10)
    Util.List(list, 3)
    self.TabList = list

    local bottom = Util.New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, bottomHeight),
        Parent = sidebar,
    })
    Util.Padding(bottom, 6, 10, 10, 10)
    Util.List(bottom, 6)
    self.SidebarBottom = bottom

    if def.User ~= false then
        self:_userCard(bottom)
    end

    local sideDivider = Util.New("Frame", {
        Position = UDim2.fromOffset(SIDEBAR, TOP + 12),
        Size = UDim2.new(0, 1, 1, -TOP - 24),
        Theme = { BackgroundColor3 = "Divider" },
        Parent = root,
    })
    Util.New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = sideDivider,
    })
    self.SideDivider = sideDivider

    -- content -----------------------------------------------------------------
    self.Content = Util.New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(SIDEBAR + 14, TOP + 12),
        Size = UDim2.new(1, -SIDEBAR - 26, 1, -TOP - 12),
        Parent = root,
    })
    self.DragLayer = Util.New("Frame", {
        Name = "DragLayer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 40,
        Parent = root,
    })

    -- favourites entry
    self.FavoritesEntry = self:_entry(list, "Favorites", "star", -100, function() self:SelectFavorites() end)
    self:_sidebarDivider(-99)

    -- resize grip
    local grip = Util.New("TextButton", {
        Name = "Resize",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = root,
    })
    for index, length in { 10, 5 } do
        Util.New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(10 + index * 1.5, 10 + index * 1.5),
            Size = UDim2.fromOffset(length, 1),
            Rotation = -45,
            Theme = { BackgroundColor3 = "TextMuted" },
            Parent = grip,
        })
    end
    self.Grip = grip
    grip.InputBegan:Connect(function(input)
        if not Util.IsPress(input) or self.Minimized then return end
        local origin = root.AbsoluteSize / self:GetScale()
        Drag.Follow(input, function(_, delta)
            local scale = self:GetScale()
            local viewport = Layer.Bounds() / scale
            local width = math.clamp(origin.X + delta.X / scale, self.MinSize.X, viewport.X - 20)
            local height = math.clamp(origin.Y + delta.Y / scale, self.MinSize.Y, viewport.Y - 20)
            root.Size = UDim2.fromOffset(width, height)
        end, function()
            self.Interface.Size = { math.floor(root.Size.X.Offset), math.floor(root.Size.Y.Offset) }
            self:SaveState()
        end)
    end)

    -- window drag by the topbar, not by its controls
    self.Maid:Give(Drag.Attach(topbar, root, {
        Enabled = function()
            local point = Util.Pointer()
            return not Util.Contains(actions, point)
        end,
        OnEnd = function(moved)
            if not moved then return end
            local viewport = Layer.Bounds()
            local center = root.AbsolutePosition + root.AbsoluteSize / 2
            self.Interface.Position = { math.floor(center.X - viewport.X / 2), math.floor(center.Y - viewport.Y / 2) }
            self:SaveState()
        end,
    }))

    self:SetCompact(self.Interface.Compact, true)
    self:_fitScale()
    self.Maid:Give(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        if not self.Interface.Scale then self:_fitScale() end
    end))
end

function Window:_userCard(parent)
    local player = Services.Players.LocalPlayer
    local card = Util.New("Frame", {
        Name = "User",
        Size = UDim2.new(1, 0, 0, 42),
        LayoutOrder = 2,
        Theme = { BackgroundColor3 = "Elevated", BackgroundTransparency = function(t) return math.min(t.ElevatedTransparency + 0.25, 0.95) end },
        Parent = parent,
    })
    Util.Corner(8, card)
    local avatar = Util.New("ImageLabel", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(0, 7, 0.5, -14),
        BackgroundTransparency = 0,
        Theme = { BackgroundColor3 = "ElevatedHover" },
        Parent = card,
    })
    Util.Corner(UDim.new(1, 0), avatar)
    local name = Util.Label({ TextSize = 12, Weight = Enum.FontWeight.SemiBold, Position = UDim2.fromOffset(42, 7), Size = UDim2.new(1, -48, 0, 15), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
    local handle = Util.Label({ TextSize = 10, Color = "TextMuted", Position = UDim2.fromOffset(42, 22), Size = UDim2.new(1, -48, 0, 12), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
    local image
    task.spawn(function()
        local ok, result = pcall(Services.Players.GetUserThumbnailAsync, Services.Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if ok then
            image = result
            if not self.Interface.HideUser then avatar.Image = result end
        end
    end)
    function self.PaintUser()
        local hidden = self.Interface.HideUser
        name.Text = hidden and "Hidden" or player.DisplayName
        handle.Text = hidden and "@hidden" or ("@" .. player.Name)
        avatar.Image = (not hidden and image) or ""
    end
    self.PaintUser()
    self.UserCard = card
    self.UserLabels = { name, handle }
end

function Window:_sidebarDivider(order)
    local holder = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 9), LayoutOrder = order, Parent = self.TabList })
    Util.New("Frame", { Size = UDim2.new(1, -8, 0, 1), Position = UDim2.new(0, 4, 0.5, 0), Theme = { BackgroundColor3 = "Divider" }, Parent = holder })
    return holder
end

-- sidebar entry: icon + label + optional badge; returns entry table
function Window:_entry(parent, text, icon, order, onClick)
    local entry = { Selected = false, Hover = false }
    local button = Util.New("TextButton", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = order,
        Theme = {
            BackgroundColor3 = "Elevated",
            BackgroundTransparency = function(t)
                if entry.Selected then return t.ElevatedTransparency end
                return entry.Hover and math.min(t.ElevatedTransparency + 0.45, 0.85) or 1
            end,
        },
        Parent = parent,
    })
    Util.Corner(7, button)
    local indicator = Util.New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 0),
        Theme = { BackgroundColor3 = "Accent" },
        Parent = button,
    })
    Util.Corner(2, indicator)
    local image = Util.Icon(icon, {
        Size = UDim2.fromOffset(15, 15),
        Position = UDim2.new(0, 12, 0.5, -7),
        Theme = { ImageColor3 = function(t) return entry.Selected and t.Accent or (entry.Hover and t.TextDim or t.TextMuted) end },
        Parent = button,
    })
    local label = Util.Label({
        Text = text,
        TextSize = 13,
        Weight = Enum.FontWeight.Medium,
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -44, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = function(t) return entry.Selected and t.Text or (entry.Hover and t.TextDim or t.TextMuted) end },
        Parent = button,
    })
    local badge = Util.New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 16),
        Visible = false,
        Theme = { BackgroundColor3 = "Elevated" },
        Parent = button,
    })
    Util.Corner(UDim.new(1, 0), badge)
    Util.Padding(badge, 0, 6, 0, 6)
    local badgeText = Util.Label({ TextSize = 10, Color = "TextDim", Weight = Enum.FontWeight.Bold, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = badge })

    local function paint(animate)
        local time = animate and 0.18 or 0
        Theme.Refresh(button, time)
        Theme.Refresh(image, time)
        Theme.Refresh(label, time)
        Util.Tween(indicator, time, { Size = UDim2.fromOffset(3, entry.Selected and 16 or 0) })
    end
    entry.Button, entry.Label, entry.Icon, entry.Badge = button, label, image, badge
    function entry.SetSelected(on)
        entry.Selected = on
        paint(true)
    end
    function entry.SetBadge(value)
        badge.Visible = value ~= nil and value ~= 0 and not self.Interface.Compact
        badgeText.Text = tostring(value or "")
        entry.BadgeValue = value
    end
    button.MouseEnter:Connect(function() entry.Hover = true; paint(true) end)
    button.MouseLeave:Connect(function() entry.Hover = false; paint(true) end)
    button.MouseButton1Click:Connect(onClick)
    Tooltip.Attach(button, function() return self.Interface.Compact and text or nil end)
    paint(false)
    table.insert(self.Entries, entry)
    return entry
end

-- layout ----------------------------------------------------------------------

function Window:SetCompact(compact, instant)
    self.Interface.Compact = compact and true or false
    local width = compact and COMPACT or SIDEBAR
    local time = instant and 0 or 0.25
    Util.Tween(self.Sidebar, time, { Size = UDim2.new(0, width, 1, -TOP - 1) })
    Util.Tween(self.SideDivider, time, { Position = UDim2.fromOffset(width, TOP + 12) })
    Util.Tween(self.Content, time, { Position = UDim2.fromOffset(width + 14, TOP + 12), Size = UDim2.new(1, -width - 26, 1, -TOP - 12) })
    for _, entry in self.Entries do
        entry.Label.Visible = not compact
        if entry.Badge then entry.Badge.Visible = not compact and entry.BadgeValue ~= nil and entry.BadgeValue ~= 0 end
    end
    for _, header in self._headers or {} do header.Visible = not compact end
    if self.UserLabels then
        for _, label in self.UserLabels do label.Visible = not compact end
    end
end

function Window:_fitScale()
    local scale = self.Interface.Scale
    if not scale then
        local viewport = Layer.Bounds()
        local size = self.Root.Size
        scale = math.min(1, (viewport.X - 24) / size.X.Offset, (viewport.Y - 24) / size.Y.Offset)
        scale = math.clamp(scale, 0.45, 1)
    end
    self:SetScale(scale, true)
end

function Window:SetScale(scale, auto)
    self.Scale = scale
    self.UIScale.Scale = scale
    Layer.SetScale(scale)
    if not auto then
        self.Interface.Scale = scale
        self:SaveState()
    end
end

function Window:SetMinimized(minimized)
    self.Minimized = minimized and true or false
    Popup.CloseAll()
    local root = self.Root
    if self.Minimized then
        self._restoreSize = root.Size
        self.Sidebar.Visible, self.Content.Visible, self.SideDivider.Visible = false, false, false
        self.TopDivider.Visible, self.Grip.Visible = false, false
        self.Actions.Search.Visible = false
        self.SubtitleLabel.Visible = false
        local width = math.max(self.TitleLabel.Parent.AbsoluteSize.X / self:GetScale() + 48 + 90, 240)
        Util.Tween(root, 0.35, { Size = UDim2.fromOffset(width, TOP) })
        self.MinimizeIcon.Image = Util.IconId("maximize-2")
    else
        local tween = Util.Tween(root, 0.35, { Size = self._restoreSize or root.Size })
        local function show()
            self.Sidebar.Visible, self.Content.Visible, self.SideDivider.Visible = true, true, true
            self.TopDivider.Visible, self.Grip.Visible = true, true
            self.Actions.Search.Visible = self.Def.Search ~= false
            self.SubtitleLabel.Visible = true
        end
        if tween then tween.Completed:Once(show) else show() end
        self.MinimizeIcon.Image = Util.IconId("minus")
    end
end

function Window:_open()
    self.Root.Visible = true
    self.UIScale.Scale = self:GetScale() * 0.92
    Util.Tween(self.UIScale, 0.35, { Scale = self:GetScale() }, Enum.EasingStyle.Back)
end

function Window:SetVisible(visible)
    visible = visible and true or false
    if visible == self.Visible then return end
    self.Visible = visible
    Popup.CloseAll()
    Tooltip.Hide()
    if visible then
        self:_open()
    else
        local tween = Util.Tween(self.UIScale, 0.18, { Scale = self:GetScale() * 0.94 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local function hide() if not self.Visible then self.Root.Visible = false end end
        if tween then tween.Completed:Once(hide) else hide() end
    end
    self.Acrylic:SetVisible(visible)
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

function Window:SetTitle(text)
    self.TitleLabel.Text = text
end

function Window:SetSubtitle(text)
    self.SubtitleLabel.Text = text
end

-- tabs ------------------------------------------------------------------------

function Window:Tab(def)
    if type(def) == "string" then def = { Title = def } end
    def = def or {}
    local tab = Tab.new(self, def)
    self._order = (self._order or 0) + 1
    if def.Pinned then
        tab.Entry = self:_entry(self.SidebarBottom, tab.Title, tab.Icon or "settings", 1, function() self:SelectTab(tab) end)
    else
        tab.Entry = self:_entry(self.TabList, tab.Title, tab.Icon or "layout-grid", self._order, function() self:SelectTab(tab) end)
    end
    tab.Button = tab.Entry
    table.insert(self.Tabs, tab)
    if self.Interface.Tab == tab.Id and not self._restored then
        self._restored = true
        self:SelectTab(tab, nil, true)
    elseif not self.SelectedPage and not def.Pinned then
        self:SelectTab(tab, nil, true)
    end
    return tab
end
Window.AddTab = Window.Tab

-- sidebar caption between tab groups
function Window:TabSection(text)
    self._order = (self._order or 0) + 1
    local label = Util.Label({
        Text = string.upper(text),
        TextSize = 10,
        Color = "TextMuted",
        Weight = Enum.FontWeight.Bold,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = self._order,
        Parent = self.TabList,
    })
    Util.Padding(label, 8, 0, 0, 6)
    self._headers = self._headers or {}
    table.insert(self._headers, label)
    label.Visible = not self.Interface.Compact
    return label
end

function Window:Divider()
    self._order = (self._order or 0) + 1
    return self:_sidebarDivider(self._order)
end

function Window:_showPage(page)
    Popup.CloseAll()
    for _, other in { self.Favorites, self.SearchPage } do
        if other and other ~= page then other.Frame.Visible = false end
    end
    for _, tab in self.Tabs do
        if tab.Page ~= page then tab.Page.Frame.Visible = false end
    end
    if not page.Frame.Visible then
        page.Frame.Visible = true
        page.Frame.Position = UDim2.fromOffset(0, 10)
        Util.Tween(page.Frame, 0.3, { Position = UDim2.new() })
    end
end

function Window:_select(entry, page, id)
    for _, other in self.Entries do
        if other.Selected ~= (other == entry) then other.SetSelected(other == entry) end
    end
    self.SelectedPage = page
    if self._searching then
        self.SearchBox.Text = ""
        self._searching = false
        self.Query = nil
        self.SearchPage:Clear()
        task.defer(Theme.Apply)
    end
    self:_showPage(page)
    if id then
        self.Interface.Tab = id
        self:SaveState()
    end
end

-- focus: optional module to scroll to
function Window:SelectTab(tab, focus, silent)
    if type(tab) == "number" then tab = self.Tabs[tab] end
    if not tab then return end
    self.Selected = tab
    self:_select(tab.Entry, tab.Page, not silent and tab.Id or nil)
    if focus then
        task.defer(function()
            local view = tab.Page:Find(focus)
            if not view then return end
            local column = tab.Page.Columns[view.Column]
            local offset = view.Card.AbsolutePosition.Y - column.AbsolutePosition.Y + column.CanvasPosition.Y - 8
            column.CanvasPosition = Vector2.new(0, math.max(offset / self:GetScale(), 0))
        end)
    end
end

function Window:SelectFavorites()
    self.Selected = nil
    self:_select(self.FavoritesEntry, self.Favorites, "favorites")
end

-- favourites / search ---------------------------------------------------------

function Window:_favoriteCount()
    local count = 0
    for _ in self.State.Favorites do count += 1 end
    return count
end

function Window:_addFavoriteView(module)
    if not self.Favorites:Find(module) then self.Favorites:Add(module) end
    self.FavoritesEntry.SetBadge(self:_favoriteCount())
end

function Window:_setFavorite(module, favorite)
    if module.Favorite == favorite then return end
    module.Favorite = favorite
    self.State.Favorites[module.Id] = favorite or nil
    if favorite then
        self:_addFavoriteView(module)
    else
        self.Favorites:Remove(module)
    end
    self.FavoritesEntry.SetBadge(self:_favoriteCount())
    module.StateChanged:Fire("Favorite")
    self:SaveState()
end

function Window:ClearFavorites()
    for _, tab in self.Tabs do
        for _, module in tab.Modules do
            if module.Favorite then self:_setFavorite(module, false) end
        end
    end
    table.clear(self.State.Favorites)
    self:SaveState()
end

function Window:_removeModule(module)
    for _, tab in self.Tabs do
        local index = table.find(tab.Modules, module)
        if index then table.remove(tab.Modules, index) end
        tab.Page:Remove(module)
    end
    self.Favorites:Remove(module)
    self.SearchPage:Remove(module)
    local bind = table.find(self._binds, module)
    if bind then table.remove(self._binds, bind) end
end

function Window:_search(text)
    local query = text:lower():match("^%s*(.-)%s*$")
    self.Query = query ~= "" and query or nil
    task.defer(Theme.Apply)
    if query == "" then
        if self._searching then
            self._searching = false
            self.SearchPage:Clear()
            if self.SelectedPage then self:_showPage(self.SelectedPage) end
        end
        return
    end
    self._searching = true
    self.SearchPage:Clear()
    local found = 0
    for _, tab in self.Tabs do
        for _, module in tab.Modules do
            if module.Visible and module:Matches(query) then
                found += 1
                local direct = (module.Title .. " " .. (module.Description or "")):lower():find(query, 1, true)
                if not direct and #module.Children > 0 then module:SetExpanded(true) end
                self.SearchPage:Add(module)
            end
        end
    end
    self.SearchPage:SetEmpty(found == 0 and ('No results for "' .. text .. '"') or "")
    self.SearchPage:UpdateEmpty()
    self:_showPage(self.SearchPage)
end

-- misc ------------------------------------------------------------------------

function Window:Dialog(options)
    return Dialog.Open(self.Root, options)
end

function Window:Notify(options)
    return self.Library:Notify(options)
end

function Window:LoadAutoload()
    local name = self.Config:GetAutoload()
    if not name then return false end
    local ok, err = self.Config:Load(name)
    if ok then
        self.Library:Notify({ Title = "Config loaded", Content = name, Type = "Success", Duration = 3 })
    else
        self.Library:Notify({ Title = "Autoload failed", Content = err, Type = "Error" })
    end
    return ok
end

function Window:SetInterface(key, value)
    self.Interface[key] = value
    self:SaveState()
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    Popup.CloseAll()
    Tooltip.Hide()
    self.Maid:Clean()
end

return Window
