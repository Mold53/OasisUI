local import = ...
local Services = import("Core/Services")
local Util = import("Core/Util")
local Drag = import("Core/Drag")
local Layer = import("Components/Layer")

-- hud panels of a window: keybind list, watermark, mobile menu button
local Overlays = {}
Overlays.__index = Overlays

function Overlays.new(window)
    return setmetatable({ Window = window, _queued = false }, Overlays)
end

local function savePosition(window, key, frame)
    window.Interface[key] = { math.floor(frame.Position.X.Offset), math.floor(frame.Position.Y.Offset) }
    window:SaveState()
end

local function restore(window, key, frame, fallback)
    local saved = window.Interface[key]
    frame.Position = type(saved) == "table" and UDim2.fromOffset(saved[1], saved[2]) or fallback
end

local function panel(window, name, icon, title)
    local frame = window.Maid:Give(Util.New("Frame", {
        Name = name,
        Size = UDim2.fromOffset(200, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Active = true,
        Theme = { BackgroundColor3 = "Surface", BackgroundTransparency = function(t) return math.min(t.SurfaceTransparency, 0.12) end },
        Parent = Layer.Hud,
    }))
    Util.Corner(8, frame)
    Util.Stroke(frame)
    Util.Padding(frame, 8, 10, 9, 10)
    Util.List(frame, 4)
    local head = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = frame })
    Util.Icon(icon, { Size = UDim2.fromOffset(13, 13), Position = UDim2.fromOffset(0, 2), Color = "Accent", Parent = head })
    Util.Label({ Text = title, TextSize = 12, Weight = Enum.FontWeight.SemiBold, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0), Parent = head })
    local rule = Util.New("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 1, Theme = { BackgroundColor3 = "Divider" }, Parent = frame })
    Util.New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = rule })
    return frame
end

-- keybind list ----------------------------------------------------------------

function Overlays:SetKeybindList(on)
    local window = self.Window
    window.Interface.KeybindList = on and true or false
    if on and not self.Binds then
        local frame = panel(window, "Keybinds", "keyboard", "Keybinds")
        restore(window, "KeybindListPos", frame, UDim2.new(0, 14, 0.4, 0))
        window.Maid:Give(Drag.Attach(frame, frame, { OnEnd = function(moved) if moved then savePosition(window, "KeybindListPos", frame) end end }))
        self.Binds = frame
        self.BindRows = {}
    end
    if self.Binds then self.Binds.Visible = window.Interface.KeybindList end
    self:RefreshBinds()
end

function Overlays:RefreshBinds()
    if not self.Binds or not self.Binds.Visible or self._queued then return end
    self._queued = true
    task.defer(function()
        self._queued = false
        self:_paintBinds()
    end)
end

function Overlays:_paintBinds()
    local frame = self.Binds
    if not frame then return end
    for _, row in self.BindRows do row:Destroy() end
    table.clear(self.BindRows)
    local order = 2
    for _, owner in self.Window._binds do
        local binding = owner.Binding
        if binding and binding.Key and owner.Visible ~= false then
            local title, active = owner:BindInfo()
            local row = Util.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 17), LayoutOrder = order, Parent = frame })
            Util.Label({
                Text = title,
                TextSize = 11,
                Weight = Enum.FontWeight.Medium,
                Color = active and "Text" or "TextMuted",
                Size = UDim2.new(1, -70, 1, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row,
            })
            local mode = binding.Mode ~= "Toggle" and (" · " .. binding.Mode:lower()) or ""
            Util.Label({
                Text = "[" .. Util.KeyLabel(binding.Key) .. "]" .. mode,
                TextSize = 10,
                Weight = Enum.FontWeight.SemiBold,
                Color = active and "Accent" or "TextMuted",
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 70, 1, 0),
                Parent = row,
            })
            table.insert(self.BindRows, row)
            order += 1
        end
    end
    if #self.BindRows == 0 then
        table.insert(self.BindRows, Util.Label({ Text = "No keys bound", TextSize = 11, Color = "TextMuted", Size = UDim2.new(1, 0, 0, 17), LayoutOrder = 2, Parent = frame }))
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
        restore(window, "WatermarkPos", frame, UDim2.fromOffset(14, 14))
        window.Maid:Give(Drag.Attach(frame, frame, { OnEnd = function(moved) if moved then savePosition(window, "WatermarkPos", frame) end end }))

        local frames, elapsed = 0, 0
        window.Maid:Give(Services.RunService.RenderStepped:Connect(function(dt)
            frames += 1
            elapsed += dt
            if elapsed < 0.5 or not frame.Visible then return end
            local fps = math.floor(frames / elapsed + 0.5)
            frames, elapsed = 0, 0
            local ping = 0
            pcall(function() ping = math.floor(Services.Players.LocalPlayer:GetNetworkPing() * 1000 + 0.5) end)
            local accent = "#" .. window.Library.Theme.Current.Accent:ToHex()
            local muted = "#" .. window.Library.Theme.Current.TextMuted:ToHex()
            local sep = string.format(' <font color="%s">|</font> ', muted)
            text.Text = string.format('<font color="%s"><b>%s</b></font>%s%d fps%s%d ms%s%s', accent, window.TitleLabel.Text, sep, fps, sep, ping, sep, os.date("%H:%M"))
        end))
        self.Watermark = frame
    end
    if self.Watermark then self.Watermark.Visible = window.Interface.Watermark end
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
        restore(window, "MobilePos", button, UDim2.new(0, 14, 0.5, -23))
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
