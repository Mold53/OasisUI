local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Theme = import("Core/Theme")
local Drag = import("Core/Drag")
local Keybinds = import("Core/Keybinds")
local Layer = import("Components/Layer")

-- hud panels of a window: keybind list, watermark, mobile menu button
local Overlays = {}
Overlays.__index = Overlays

Overlays.KeybindDefaults = {
    Show = "All",                     -- "All" | "Active"
    Sort = "Added",                   -- "Added" | "Name" | "Key" | "Mode" | "Active first"
    Group = false,                    -- one caption per mode
    Layout = "Name · Key · Mode",     -- column order, see LAYOUTS
    ModeText = "Full",                -- "Full" | "Short" | "Hidden"
    KeyStyle = "Pill",                -- "Pill" | "Brackets" | "Plain"
    Title = true,
    MenuKey = false,
    HideWithMenu = false,
    Scale = 100,
    Width = 210,
    Transparency = 12,
}
Overlays.WatermarkDefaults = {
    Title = true,
    Fps = true,
    Ping = true,
    Time = true,
    User = false,
    Text = "",
    Scale = 100,
}
Overlays.Layouts = { "Name · Key · Mode", "Name · Mode · Key", "Mode · Name · Key", "Key · Name · Mode" }
Overlays.Sorts = { "Added", "Name", "Key", "Mode", "Active first" }
local LAYOUTS = {
    ["Name · Key · Mode"] = { "Name", "Key", "Mode" },
    ["Name · Mode · Key"] = { "Name", "Mode", "Key" },
    ["Mode · Name · Key"] = { "Mode", "Name", "Key" },
    ["Key · Name · Mode"] = { "Key", "Name", "Mode" },
}
local MODE_ORDER = { Toggle = 1, Hold = 2, Always = 3 }

local function defaults(target, source)
    for key, value in source do
        if target[key] == nil then target[key] = value end
    end
    return target
end

function Overlays.new(window)
    local interface = window.Interface
    interface.KeybindStyle = defaults(type(interface.KeybindStyle) == "table" and interface.KeybindStyle or {}, Overlays.KeybindDefaults)
    interface.WatermarkStyle = defaults(type(interface.WatermarkStyle) == "table" and interface.WatermarkStyle or {}, Overlays.WatermarkDefaults)
    local self = setmetatable({ Window = window, _queued = false }, Overlays)
    window.Maid:Give(Keybinds.Activity:Connect(function() self:RefreshBinds() end))
    return self
end

-- keeps a hud frame fully on screen (resolution changes, old saves)
local function clamp(frame)
    local bounds, size = Layer.Bounds(), frame.AbsoluteSize
    local position = frame.AbsolutePosition
    local x = math.clamp(position.X, 0, math.max(0, bounds.X - size.X))
    local y = math.clamp(position.Y, 0, math.max(0, bounds.Y - size.Y))
    frame.Position = UDim2.fromOffset(x, y)
end

-- positions are stored as absolute pixels, so a scale part can never get lost
local function savePosition(window, key, frame)
    clamp(frame)
    window.Interface[key] = { math.floor(frame.AbsolutePosition.X), math.floor(frame.AbsolutePosition.Y) }
    window:SaveState()
end

-- fallback(bounds) -> Vector2 for the first placement
local function restore(window, key, frame, fallback)
    local saved = window.Interface[key]
    local point = type(saved) == "table" and Vector2.new(tonumber(saved[1]) or 0, tonumber(saved[2]) or 0) or fallback(Layer.Bounds())
    frame.Position = UDim2.fromOffset(point.X, point.Y)
    task.defer(function() if frame.Parent then clamp(frame) end end)
    window.Maid:Give(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(function() if frame.Parent then clamp(frame) end end)
    end))
end

local function keybindsHome(bounds) return Vector2.new(14, math.floor(bounds.Y * 0.4)) end
local function watermarkHome() return Vector2.new(14, 14) end
local function mobileHome(bounds) return Vector2.new(14, math.floor(bounds.Y * 0.5) - 23) end

-- keybind list ----------------------------------------------------------------

function Overlays:_buildBinds()
    local window = self.Window
    local style = window.Interface.KeybindStyle
    local frame = window.Maid:Give(Util.New("Frame", {
        Name = "Keybinds",
        Size = UDim2.fromOffset(style.Width, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Active = true,
        Theme = {
            BackgroundColor3 = "Surface",
            BackgroundTransparency = function() return style.Transparency / 100 end,
        },
        Parent = Layer.Hud,
    }))
    Util.Corner(8, frame)
    Util.Stroke(frame)
    Util.Padding(frame, 8, 10, 9, 10)
    Util.List(frame, 4)
    local scale = Util.New("UIScale", { Scale = style.Scale / 100, Parent = frame })

    local head = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, Parent = frame })
    Util.Icon("keyboard", { Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(0, 2), Color = "Accent", Parent = head })
    Util.Label({ Text = "Keybinds", TextSize = 12, Weight = Enum.FontWeight.SemiBold, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -60, 1, 0), Parent = head })
    local counter = Util.Label({
        TextSize = 10,
        Color = "TextMuted",
        Weight = Enum.FontWeight.SemiBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Parent = head,
    })
    local rule = Util.New("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 1, Theme = { BackgroundColor3 = "Divider" }, Parent = frame })
    Util.New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = rule })

    restore(window, "KeybindListPos", frame, keybindsHome)
    window.Maid:Give(Drag.Attach(frame, frame, { OnEnd = function(moved) if moved then savePosition(window, "KeybindListPos", frame) end end }))
    self.Binds, self.BindScale, self.BindHead, self.BindRule, self.BindCounter = frame, scale, head, rule, counter
    self.BindRows = {}
end

function Overlays:SetKeybindList(on)
    local window = self.Window
    window.Interface.KeybindList = on and true or false
    if on and not self.Binds then self:_buildBinds() end
    self:UpdateVisibility()
    self:RefreshBinds()
end

function Overlays:SetKeybindStyle(key, value)
    local style = self.Window.Interface.KeybindStyle
    style[key] = value
    if self.Binds then
        self.Binds.Size = UDim2.fromOffset(style.Width, 0)
        self.BindScale.Scale = style.Scale / 100
        Theme.Refresh(self.Binds)
    end
    self:UpdateVisibility()
    self:RefreshBinds()
    self.Window:SaveState()
end

function Overlays:ResetPosition(which)
    local window = self.Window
    if which == "Keybinds" and self.Binds then
        window.Interface.KeybindListPos = nil
        local home = keybindsHome(Layer.Bounds())
        self.Binds.Position = UDim2.fromOffset(home.X, home.Y)
    elseif which == "Watermark" and self.Watermark then
        window.Interface.WatermarkPos = nil
        self.Watermark.Position = UDim2.fromOffset(14, 14)
    end
    window:SaveState()
end

function Overlays:UpdateVisibility()
    local window = self.Window
    if self.Binds then
        local style = window.Interface.KeybindStyle
        self.Binds.Visible = window.Interface.KeybindList and not (style.HideWithMenu and window.Visible)
    end
    if self.Watermark then self.Watermark.Visible = window.Interface.Watermark end
end

function Overlays:RefreshBinds()
    if not self.Binds or not self.Binds.Visible or self._queued then return end
    self._queued = true
    task.defer(function()
        self._queued = false
        self:_paintBinds()
    end)
end

-- every bound owner as { Title, Binding, Active, Order }
function Overlays:_entries()
    local window = self.Window
    local style = window.Interface.KeybindStyle
    local list = {}
    for order, owner in window._binds do
        local binding = owner.Binding
        if binding and binding.Key and owner.Visible ~= false then
            local title, active = owner:BindInfo()
            table.insert(list, { Title = title, Binding = binding, Active = active or binding.Held, Order = order })
        end
    end
    local menu = window.MenuBinding
    if style.MenuKey and menu and menu.Key then
        table.insert(list, { Title = "Menu", Binding = menu, Active = window.Visible, Order = 0 })
    end
    if style.Show == "Active" then
        for index = #list, 1, -1 do
            if not list[index].Active then table.remove(list, index) end
        end
    end
    local sort = style.Sort
    table.sort(list, function(a, b)
        if style.Group and a.Binding.Mode ~= b.Binding.Mode then
            return (MODE_ORDER[a.Binding.Mode] or 9) < (MODE_ORDER[b.Binding.Mode] or 9)
        end
        if sort == "Name" then return a.Title:lower() < b.Title:lower() end
        if sort == "Key" then return Util.KeyLabel(a.Binding.Key) < Util.KeyLabel(b.Binding.Key) end
        if sort == "Mode" and a.Binding.Mode ~= b.Binding.Mode then
            return (MODE_ORDER[a.Binding.Mode] or 9) < (MODE_ORDER[b.Binding.Mode] or 9)
        end
        if sort == "Active first" and a.Active ~= b.Active then return a.Active end
        return a.Order < b.Order
    end)
    return list
end

local function keyCell(parent, entry, style, order)
    local label = Util.KeyLabel(entry.Binding.Key)
    if style.KeyStyle == "Brackets" then label = "[" .. label .. "]" end
    local color = entry.Active and "Accent" or "TextMuted"
    if style.KeyStyle == "Pill" then
        local pill = Util.New("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 15),
            LayoutOrder = order,
            Theme = {
                BackgroundColor3 = entry.Active and "Accent" or "Elevated",
                BackgroundTransparency = function() return entry.Active and 0.75 or 0.2 end,
            },
            Parent = parent,
        })
        Util.Corner(4, pill)
        Util.Padding(pill, 0, 5, 0, 5)
        Util.Label({ Text = label, TextSize = 10, Weight = Enum.FontWeight.Bold, Color = color, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
        return pill
    end
    return Util.Label({ Text = label, TextSize = 10, Weight = Enum.FontWeight.Bold, Color = color, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = order, Parent = parent })
end

function Overlays:_paintBinds()
    local frame = self.Binds
    if not frame then return end
    local window = self.Window
    local style = window.Interface.KeybindStyle
    for _, row in self.BindRows do row:Destroy() end
    table.clear(self.BindRows)
    self.BindHead.Visible = style.Title
    self.BindRule.Visible = style.Title

    local entries = self:_entries()
    local active = 0
    for _, entry in entries do
        if entry.Active then active += 1 end
    end
    self.BindCounter.Text = active .. "/" .. #entries

    local columns = LAYOUTS[style.Layout] or LAYOUTS[Overlays.KeybindDefaults.Layout]
    local order, group = 2, nil
    for _, entry in entries do
        local mode = entry.Binding.Mode
        if style.Group and mode ~= group then
            group = mode
            local caption = Util.Label({
                Text = string.upper(mode),
                TextSize = 9,
                Weight = Enum.FontWeight.Bold,
                Color = "TextMuted",
                Size = UDim2.new(1, 0, 0, 14),
                LayoutOrder = order,
                Parent = frame,
            })
            table.insert(self.BindRows, caption)
            order += 1
        end
        local row = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 17), LayoutOrder = order, Parent = frame })
        Util.List(row, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        for index, column in columns do
            if column == "Name" then
                local name = Util.Label({
                    Text = entry.Title,
                    TextSize = 11,
                    Weight = Enum.FontWeight.Medium,
                    Color = entry.Active and "Text" or "TextMuted",
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Size = UDim2.new(0, 0, 1, 0),
                    LayoutOrder = index,
                    Parent = row,
                })
                Util.New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = name })
            elseif column == "Key" then
                keyCell(row, entry, style, index)
            elseif column == "Mode" and style.ModeText ~= "Hidden" then
                Util.Label({
                    Text = style.ModeText == "Short" and mode:sub(1, 1) or mode,
                    TextSize = 10,
                    Color = "TextMuted",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.fromScale(0, 1),
                    LayoutOrder = index,
                    Parent = row,
                })
            end
        end
        table.insert(self.BindRows, row)
        order += 1
    end
    if #entries == 0 then
        table.insert(self.BindRows, Util.Label({
            Text = style.Show == "Active" and "Nothing active" or "No keys bound",
            TextSize = 11,
            Color = "TextMuted",
            Size = UDim2.new(1, 0, 0, 17),
            LayoutOrder = 2,
            Parent = frame,
        }))
    end
end

-- watermark -------------------------------------------------------------------

function Overlays:SetWatermark(on)
    local window = self.Window
    window.Interface.Watermark = on and true or false
    if on and not self.Watermark then
        local frame = window.Maid:Give(Util.New("Frame", {
            Name = "Watermark",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 28),
            Active = true,
            Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = function(t) return math.min(t.SurfaceTransparency, 0.12) end },
            Parent = Layer.Hud,
        }))
        Util.Corner(7, frame)
        Util.Stroke(frame)
        Util.Padding(frame, 0, 12, 0, 10)
        Util.List(frame, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        local logo = Util.Icon(window.Def.Icon or "sparkles", { Size = UDim2.fromOffset(14, 14), LayoutOrder = 1, Theme = { ImageColor3 = function() return Color3.new(1, 1, 1) end }, Parent = frame })
        Util.New("UIGradient", { Rotation = 45, Theme = { Color = function(t) return ColorSequence.new(t.Accent, t.AccentAlt) end }, Parent = logo })
        local text = Util.Label({ TextSize = 11, Weight = Enum.FontWeight.Medium, RichText = true, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, Parent = frame })
        local scale = Util.New("UIScale", { Scale = window.Interface.WatermarkStyle.Scale / 100, Parent = frame })
        restore(window, "WatermarkPos", frame, watermarkHome)
        window.Maid:Give(Drag.Attach(frame, frame, { OnEnd = function(moved) if moved then savePosition(window, "WatermarkPos", frame) end end }))

        local frames, elapsed, fps = 0, 0, 0
        local function paint()
            local style = window.Interface.WatermarkStyle
            scale.Scale = style.Scale / 100
            local current = Theme.Current
            local accent = "#" .. current.Accent:ToHex()
            local muted = "#" .. current.TextMuted:ToHex()
            local parts = {}
            if style.Title then table.insert(parts, string.format('<font color="%s"><b>%s</b></font>', accent, window.TitleLabel.Text)) end
            local custom = self.WatermarkText
            if type(custom) == "function" then
                local ok, value = pcall(custom)
                custom = ok and value or nil
            end
            if custom and custom ~= "" then table.insert(parts, tostring(custom)) end
            if style.Text ~= "" then table.insert(parts, style.Text) end
            if style.User then table.insert(parts, Services.Players.LocalPlayer.DisplayName) end
            if style.Fps then table.insert(parts, fps .. " fps") end
            if style.Ping then
                local ping = 0
                pcall(function() ping = math.floor(Services.Players.LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
                table.insert(parts, ping .. " ms")
            end
            if style.Time then table.insert(parts, os.date("%H:%M")) end
            text.Text = table.concat(parts, string.format(' <font color="%s">|</font> ', muted))
        end
        window.Maid:Give(Services.RunService.RenderStepped:Connect(function(dt)
            frames += 1
            elapsed += dt
            if elapsed < 0.5 or not frame.Visible then return end
            fps = math.floor(frames / elapsed + 0.5)
            frames, elapsed = 0, 0
            paint()
        end))
        self.Watermark, self.PaintWatermark = frame, paint
        paint()
    end
    self:UpdateVisibility()
end

function Overlays:SetWatermarkStyle(key, value)
    self.Window.Interface.WatermarkStyle[key] = value
    if self.PaintWatermark then self.PaintWatermark() end
    self.Window:SaveState()
end

-- text or function shown after the title; set by scripts with Window:SetWatermark
function Overlays:SetWatermarkText(value)
    self.WatermarkText = value
    if self.PaintWatermark then self.PaintWatermark() end
end

-- mobile button ---------------------------------------------------------------

function Overlays:SetMobileButton(on)
    local window = self.Window
    if on and not self.Mobile then
        local button = window.Maid:Give(Util.New("ImageButton", {
            Name = "MenuButton",
            Size = UDim2.fromOffset(46, 46),
            Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = function(t) return math.min(t.SurfaceTransparency, 0.1) end },
            Parent = Layer.Hud,
        }))
        Util.Corner(UDim.new(1, 0), button)
        Util.Stroke(button, "Accent", function() return 0.3 end, 1.5)
        local logo = Util.Icon(window.Def.Icon or "sparkles", {
            Size = UDim2.fromOffset(20, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Theme = { ImageColor3 = function() return Color3.new(1, 1, 1) end },
            Parent = button,
        })
        Util.New("UIGradient", { Rotation = 45, Theme = { Color = function(t) return ColorSequence.new(t.Accent, t.AccentAlt) end }, Parent = logo })
        restore(window, "MobilePos", button, mobileHome)
        window.Maid:Give(Drag.Attach(button, button, {
            OnEnd = function(moved)
                if moved then
                    savePosition(window, "MobilePos", button)
                else
                    window:Toggle()
                end
            end,
        }))
        self.Mobile = button
    end
    if self.Mobile then self.Mobile.Visible = on and true or false end
end

return Overlays
