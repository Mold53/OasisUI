local import = ...
local Theme = import("Core/Theme")
local Storage = import("Core/Storage")
local Config = import("Core/Config")
local Notification = import("Components/Notification")

-- built-in settings tab, made with the library's own elements; nothing here lands in configs
return function(window)
    local library = window.Library
    local interface = window.Interface
    local tab = window:Tab({ Title = "Settings", Icon = "settings", Id = "Settings", Pinned = true, Draggable = true })

    local function notify(title, content, kind)
        library:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3 })
    end
    local function clipboard(text)
        if type(setclipboard) ~= "function" then return false end
        return (pcall(setclipboard, text))
    end
    local function readClipboard()
        local get = type(getgenv) == "function" and (getgenv() :: any).getclipboard
        if type(get) == "function" then
            local ok, text = pcall(get)
            if ok then return text end
        end
        return nil
    end

    -- appearance --------------------------------------------------------------
    local look = tab:Section({ Title = "Appearance", Description = "Changes apply live and are remembered.", Icon = "palette", Side = "Left", Id = "settings/appearance" })

    local palettes = {}
    for _, name in Theme.Presets.Order do table.insert(palettes, name) end
    local pickers = {}
    look:Dropdown({
        Title = "Preset",
        Values = palettes,
        Default = Theme.Palette,
        Callback = function(name) Theme.UsePalette(name) end,
    })

    local colors = look:Group({ Title = "Colours", Icon = "paintbrush", Opened = false })
    for _, entry in {
        { "Accent", "Accent" }, { "Accent 2", "AccentAlt" }, { "Background", "Background" }, { "Background 2", "BackgroundAlt" },
        { "Cards", "Surface" }, { "Fields", "Elevated" }, { "Outline", "Stroke" }, { "Text", "Text" }, { "Secondary text", "TextDim" },
    } do
        local token = entry[2]
        pickers[token] = colors:ColorPicker({
            Title = entry[1],
            Default = Theme.Current[token],
            Callback = function(color) Theme.Set({ [token] = color }) end,
        })
    end

    local percent = function(value) return math.floor(value * 100 + 0.5) end
    local sliders = {}
    sliders.WindowTransparency = look:Slider({ Title = "Window transparency", Min = 0, Max = 90, Suffix = "%", Default = percent(Theme.Current.WindowTransparency),
        Callback = function(value) Theme.Set({ WindowTransparency = value / 100 }) end })
    sliders.SurfaceTransparency = look:Slider({ Title = "Card transparency", Min = 0, Max = 95, Suffix = "%", Default = percent(Theme.Current.SurfaceTransparency),
        Callback = function(value) Theme.Set({ SurfaceTransparency = value / 100 }) end })
    sliders.ElevatedTransparency = look:Slider({ Title = "Field transparency", Min = 0, Max = 90, Suffix = "%", Default = percent(Theme.Current.ElevatedTransparency),
        Callback = function(value) Theme.Set({ ElevatedTransparency = value / 100 }) end })
    sliders.Radius = look:Slider({ Title = "Corner radius", Min = 0, Max = 20, Suffix = "px", Default = Theme.Current.Radius, Buttons = true,
        Callback = function(value) Theme.Set({ Radius = value, ElementRadius = math.max(math.floor(value * 0.66 + 0.5), 0) }) end })
    local fonts = {}
    for _, entry in Theme.Fonts do table.insert(fonts, { Title = entry[2], Value = entry[1] }) end
    local font = look:Dropdown({ Title = "Font", Values = fonts, Default = Theme.Current.Font, Callback = function(name) Theme.Set({ Font = name }) end })

    look:Toggle({
        Title = "Fit to screen",
        Description = "Same size on every resolution, always fully on screen.",
        Default = interface.FitScreen ~= false,
        Callback = function(on) window:SetFitScreen(on) end,
    })
    look:Slider({
        Title = "Interface scale",
        Description = "On top of the screen fit.",
        Min = 50, Max = 200, Suffix = "%", Step = 5,
        Default = math.floor((tonumber(interface.Scale) or 1) * 100 + 0.5),
        Live = false,
        Callback = function(value) window:SetScale(value / 100) end,
    })
    sliders.AnimSpeed = look:Slider({ Title = "Animation speed", Min = 0, Max = 300, Step = 10, Suffix = "%", Default = percent(Theme.Current.AnimSpeed),
        Tooltip = "0% turns animations off.", Callback = function(value) Theme.Set({ AnimSpeed = value / 100 }) end })

    local effects = look:Group({ Title = "Effects", Icon = "sparkles", Opened = false })
    local gradient = effects:Toggle({ Title = "Background gradient", Default = Theme.Current.Gradient, Callback = function(on) Theme.Set({ Gradient = on }) end })
    local rotation = effects:Slider({ Title = "Gradient angle", Min = 0, Max = 360, Step = 15, Suffix = "°", Default = Theme.Current.GradientRotation,
        Callback = function(value) Theme.Set({ GradientRotation = value }) end })
    rotation:DependsOn(gradient)
    local animated = effects:Toggle({ Title = "Animated title", Default = Theme.Current.AnimatedTitle, Callback = function(on) Theme.Set({ AnimatedTitle = on }) end })
    local blur = effects:Dropdown({
        Title = "Background blur",
        Values = {
            { Title = "Off", Value = "Off" },
            { Title = "Screen", Value = "Screen", Description = "Blurs the game while the menu is open" },
            { Title = "Window", Value = "Window", Description = "Glass behind the menu, graphics quality 8+" },
        },
        Default = interface.Blur,
        Callback = function(mode)
            window:SetBlur(mode)
            if window.Acrylic:Problem(mode) then
                notify("Window blur can't render here", "See the note under Background blur.", "Warning")
            end
        end,
    })
    local blurHint = effects:Label({ Text = "", Color = "Warning" })
    local function refreshBlurHint()
        local problem = window.Acrylic:Problem(blur:Get())
        blurHint:Set(problem or "")
        blurHint:SetVisible(problem ~= nil)
    end
    blur.Changed:Connect(refreshBlurHint)
    window.Maid:Give(UserSettings().GameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(refreshBlurHint))
    refreshBlurHint()
    effects:Slider({
        Title = "Blur strength",
        Min = 2, Max = 24, Default = interface.BlurStrength,
        Callback = function(value)
            window:SetInterface("BlurStrength", value)
            window.Acrylic:SetStrength(value)
        end,
    }):DependsOn(blur, function(mode) return mode == "Screen" end, "Hide")

    local layout = look:Group({ Title = "Layout", Icon = "layout-dashboard", Opened = false })
    layout:Toggle({ Title = "Expand modules when enabled", Default = interface.AutoExpand, Callback = function(on) window:SetInterface("AutoExpand", on) end })
    layout:Toggle({ Title = "Compact sidebar", Default = interface.Compact, Callback = function(on)
        window:SetCompact(on)
        window:SaveState()
    end })

    -- keep the controls in sync when a preset or an import changes the theme
    window.Maid:Give(Theme.Changed:Connect(function()
        for token, picker in pickers do picker:Set(Theme.Current[token], nil, true) end
        for token, slider in sliders do
            local value = Theme.Current[token]
            if token ~= "Radius" then value = percent(value) end
            slider:Set(value, true)
        end
        font:Set(Theme.Current.Font, true)
        gradient:Set(Theme.Current.Gradient, true)
        rotation:Set(Theme.Current.GradientRotation, true)
        animated:Set(Theme.Current.AnimatedTitle, true)
        window:SaveState()
    end))

    -- themes ------------------------------------------------------------------
    local themesDir = window.Folder .. "/themes"
    local themes = tab:Section({ Title = "Themes", Description = "Save your look and share it.", Icon = "layers", Side = "Left", Id = "settings/themes" })
    local themeName = themes:Input({ Title = "Theme name", Placeholder = "my theme", Finished = false })
    local themeList
    local function refreshThemes()
        themeList:Refresh(Storage.List(themesDir, "json"))
    end
    themes:Buttons({
        { Title = "Save", Icon = "save", Callback = function()
            local ok, name = Config.ValidName(themeName:Get())
            if not ok then notify("Theme not saved", name, "Error"); return end
            if not Storage.WriteJSON(themesDir .. "/" .. name .. ".json", Theme.Export()) then
                notify("Theme not saved", "File access is not supported.", "Error"); return
            end
            refreshThemes()
            themeList:Set(name)
            notify("Theme saved", name, "Success")
        end },
        { Title = "Load", Icon = "download", Callback = function()
            local name = themeList:Get()
            local data = name and Storage.ReadJSON(themesDir .. "/" .. name .. ".json")
            if not data then notify("Theme not loaded", "Select a saved theme.", "Error"); return end
            Theme.Import(data)
            notify("Theme loaded", name, "Success")
        end },
    })
    themeList = themes:Dropdown({ Title = "Saved themes", Values = Storage.List(themesDir, "json"), AllowNone = true, Placeholder = "No saved themes",
        Callback = function(name) if name then themeName:Set(name) end end })
    themes:Buttons({
        { Title = "Delete", Icon = "trash-2", Style = "Danger", Confirm = "Confirm", Callback = function()
            local name = themeList:Get()
            if not name then notify("Nothing deleted", "Select a saved theme.", "Warning"); return end
            Storage.Delete(themesDir .. "/" .. name .. ".json")
            refreshThemes()
            notify("Theme deleted", name, "Success")
        end },
        { Title = "Export", Icon = "copy", Callback = function()
            local text = Storage.Encode(Theme.Export())
            if text and clipboard(text) then notify("Theme copied", "Paste it anywhere to share.", "Success") else notify("Export failed", "Clipboard is not supported.", "Error") end
        end },
        { Title = "Import", Icon = "clipboard-paste", Callback = function()
            local data = Storage.Decode(readClipboard() or "")
            if data and Theme.Import(data) then notify("Theme imported", nil, "Success") else notify("Import failed", "Clipboard does not hold a theme.", "Error") end
        end },
    })
    themes:Button({ Title = "Reset to preset", Icon = "rotate-ccw", Style = "Ghost", Callback = function()
        Theme.Set(table.clone(Theme.StyleDefaults))
        Theme.UsePalette(Theme.Palette)
    end })

    -- configs -----------------------------------------------------------------
    local configs = window.Config
    local section = tab:Section({ Title = "Configs", Description = "Every flagged option and keybind.", Icon = "folder-open", Side = "Right", Id = "settings/configs" })
    local configName = section:Input({ Title = "Config name", Placeholder = "default", Finished = false })
    local configList
    section:Buttons({
        { Title = "Save", Icon = "save", Style = "Primary", Callback = function()
            local name = configName:Get() ~= "" and configName:Get() or configList:Get()
            local ok, result = configs:Save(name)
            if ok then notify("Config saved", result, "Success") else notify("Config not saved", result, "Error") end
        end },
        { Title = "Load", Icon = "download", Callback = function()
            local ok, result = configs:Load(configList:Get() or configName:Get())
            if ok then notify("Config loaded", result, "Success") else notify("Config not loaded", result, "Error") end
        end },
    })
    configList = section:Dropdown({ Title = "Saved configs", Values = configs:List(), AllowNone = true, Placeholder = "No configs yet", Search = true,
        Callback = function(name) if name then configName:Set(name) end end })
    section:Buttons({
        { Title = "Rename", Icon = "pencil", Callback = function()
            local current = configList:Get()
            if not current then notify("Nothing to rename", "Select a config first.", "Warning"); return end
            window:Dialog({
                Title = "Rename config",
                Icon = "pencil",
                Input = { Default = current, Placeholder = "New name" },
                Buttons = {
                    { Title = "Cancel", Style = "Secondary" },
                    { Title = "Rename", Style = "Primary", Callback = function(text, dialog)
                        local ok, result = configs:Rename(current, text)
                        if not ok then
                            dialog:SetError(result)
                            return false
                        end
                        configList:Set(result)
                        notify("Config renamed", result, "Success")
                        return true
                    end },
                },
            })
        end },
        { Title = "Delete", Icon = "trash-2", Style = "Danger", Confirm = "Confirm", Callback = function()
            local current = configList:Get()
            if not current then notify("Nothing deleted", "Select a config first.", "Warning"); return end
            local ok, result = configs:Delete(current)
            if ok then notify("Config deleted", result, "Success") else notify("Config not deleted", result, "Error") end
        end },
    })
    local autoload = section:Label({ Text = "Autoload", Value = configs:GetAutoload() or "none" })
    section:Buttons({
        { Title = "Set autoload", Icon = "pin", Callback = function()
            local current = configList:Get()
            if not current then notify("No autoload set", "Select a config first.", "Warning"); return end
            configs:SetAutoload(current)
            notify("Autoload set", current, "Success")
        end },
        { Title = "Clear", Icon = "x", Callback = function() configs:SetAutoload(nil) end },
    })
    section:Toggle({
        Title = "Auto save",
        Description = "Writes changes into the loaded config.",
        Default = interface.AutoSave == true,
        Callback = function(on)
            configs.AutoSave = on
            window:SetInterface("AutoSave", on)
        end,
    })
    configs.AutoSave = interface.AutoSave == true
    section:Buttons({
        { Title = "Export", Icon = "copy", Callback = function()
            local text = configs:Export()
            if text and clipboard(text) then notify("Config copied", "Share it as text.", "Success") else notify("Export failed", "Clipboard is not supported.", "Error") end
        end },
        { Title = "Import", Icon = "clipboard-paste", Callback = function()
            local ok, err = configs:Import(readClipboard() or "")
            if ok then notify("Config imported", nil, "Success") else notify("Import failed", err, "Error") end
        end },
    })
    window.Maid:Give(configs.Changed:Connect(function()
        configList:Refresh(configs:List())
        if configs.Current and configs:Exists(configs.Current) then configList:Set(configs.Current) end
        autoload:SetValue(configs:GetAutoload() or "none")
    end))

    -- menu --------------------------------------------------------------------
    local menu = tab:Section({ Title = "Menu", Icon = "sliders-horizontal", Side = "Right", Id = "settings/menu" })
    menu:Keybind({ Title = "Menu key", Binding = window.MenuBinding, Tooltip = "Opens and hides the menu." })
    menu:Dropdown({
        Title = "Notifications",
        Values = { "BottomRight", "TopRight", "BottomLeft", "TopLeft" },
        Default = interface.NotifyPosition,
        Callback = function(position)
            Notification.SetPosition(position)
            window:SetInterface("NotifyPosition", position)
        end,
    })
    menu:Buttons({
        { Title = "Test", Icon = "bell", Callback = function()
            notify("Notification", "This is how messages look.", "Info")
        end },
        { Title = "Center", Icon = "move", Callback = function() window:Center() end },
        { Title = "Reset layout", Icon = "layout-grid", Confirm = "Confirm", Callback = function()
            for _, other in window.Tabs do other:ResetLayout() end
            window.Favorites:ResetLayout()
        end },
    })
    menu:Label({ Text = "OasisUI", Value = "v" .. tostring(library.Version) })
    menu:Button({ Title = "Clear favorites", Icon = "star-off", Style = "Ghost", Confirm = "Click again to clear", Callback = function() window:ClearFavorites() end })
    menu:Button({ Title = "Unload", Icon = "power", Style = "Danger", Confirm = "Click again to unload", Callback = function() library:Unload() end })

    -- overlays ----------------------------------------------------------------
    local overlays = window.Overlays
    local hud = tab:Section({ Title = "Overlays", Description = "Keybind list and watermark.", Icon = "layout-list", Side = "Right", Id = "settings/overlays" })
    local style = interface.KeybindStyle
    local function bindStyle(key)
        return function(value) overlays:SetKeybindStyle(key, value) end
    end
    local list = hud:Toggle({ Title = "Keybind list", Default = interface.KeybindList, Callback = function(on)
        overlays:SetKeybindList(on)
        window:SaveState()
    end })
    local listOptions = hud:Group({ Title = "Keybind list options", Icon = "keyboard" })
    listOptions:Dropdown({ Title = "Show", Values = { "All", "Active" }, Default = style.Show, Callback = bindStyle("Show") })
    listOptions:Dropdown({ Title = "Sort by", Values = { "Added", "Name", "Key", "Mode", "Active first" }, Default = style.Sort, Callback = bindStyle("Sort") })
    listOptions:Toggle({ Title = "Group by mode", Description = "Toggle, Hold and Always under their own caption.", Default = style.Group, Callback = bindStyle("Group") })
    listOptions:Dropdown({ Title = "Layout", Values = overlays.Layouts, Default = style.Layout, Callback = bindStyle("Layout") })
    listOptions:Segmented({ Title = "Mode text", Values = { "Full", "Short", "Hidden" }, Default = style.ModeText, Callback = bindStyle("ModeText") })
    listOptions:Segmented({ Title = "Key style", Values = { "Pill", "Brackets", "Plain" }, Default = style.KeyStyle, Callback = bindStyle("KeyStyle") })
    listOptions:Slider({ Title = "Size", Min = 50, Max = 200, Step = 5, Suffix = "%", Default = style.Scale, Callback = bindStyle("Scale") })
    listOptions:Slider({ Title = "Width", Min = 150, Max = 400, Step = 5, Suffix = "px", Default = style.Width, Callback = bindStyle("Width") })
    listOptions:Slider({ Title = "Transparency", Min = 0, Max = 90, Suffix = "%", Default = style.Transparency, Callback = bindStyle("Transparency") })
    listOptions:Toggle({ Title = "Title bar", Default = style.Title, Callback = bindStyle("Title") })
    listOptions:Toggle({ Title = "Include menu key", Default = style.MenuKey, Callback = bindStyle("MenuKey") })
    listOptions:Toggle({ Title = "Hide while the menu is open", Default = style.HideWithMenu, Callback = bindStyle("HideWithMenu") })
    listOptions:Button({ Title = "Reset position", Icon = "rotate-ccw", Style = "Ghost", Callback = function() overlays:ResetPosition("Keybinds") end })
    listOptions:DependsOn(list, nil, "Hide")

    local marks = interface.WatermarkStyle
    local function markStyle(key)
        return function(value) overlays:SetWatermarkStyle(key, value) end
    end
    local watermark = hud:Toggle({ Title = "Watermark", Default = interface.Watermark, Callback = function(on)
        overlays:SetWatermark(on)
        window:SaveState()
    end })
    local markOptions = hud:Group({ Title = "Watermark options", Icon = "tag" })
    markOptions:Toggle({ Title = "Title", Default = marks.Title, Callback = markStyle("Title") })
    markOptions:Toggle({ Title = "Frame rate", Default = marks.Fps, Callback = markStyle("Fps") })
    markOptions:Toggle({ Title = "Ping", Default = marks.Ping, Callback = markStyle("Ping") })
    markOptions:Toggle({ Title = "Time", Default = marks.Time, Callback = markStyle("Time") })
    markOptions:Toggle({ Title = "Display name", Default = marks.User, Callback = markStyle("User") })
    markOptions:Input({ Title = "Custom text", Placeholder = "Shown after the title", Default = marks.Text, MaxLength = 40, Callback = markStyle("Text") })
    markOptions:Slider({ Title = "Size", Min = 50, Max = 200, Step = 5, Suffix = "%", Default = marks.Scale, Callback = markStyle("Scale") })
    markOptions:Button({ Title = "Reset position", Icon = "rotate-ccw", Style = "Ghost", Callback = function() overlays:ResetPosition("Watermark") end })
    markOptions:DependsOn(watermark, nil, "Hide")

    -- behaviour ---------------------------------------------------------------
    local behaviour = tab:Section({ Title = "Behaviour", Icon = "settings-2", Side = "Left", Id = "settings/behaviour" })
    local binding = behaviour:Group({ Title = "Binding keys", Icon = "keyboard", Opened = true })
    binding:Segmented({
        Title = "Click outside while binding",
        Values = { "Keep", "Clear" },
        Default = interface.BindClickOutside,
        Tooltip = "Keep leaves the old key, Clear removes it.",
        Callback = function(value)
            window:SetInterface("BindClickOutside", value)
            window:ApplyBindOptions()
        end,
    })
    binding:Segmented({
        Title = "Escape while binding",
        Values = { "Keep", "Clear" },
        Default = interface.BindEscape,
        Callback = function(value)
            window:SetInterface("BindEscape", value)
            window:ApplyBindOptions()
        end,
    })
    binding:Toggle({
        Title = "Allow mouse buttons",
        Description = "Right and middle mouse button can be bound.",
        Default = interface.BindMouse ~= false,
        Callback = function(on)
            window:SetInterface("BindMouse", on)
            window:ApplyBindOptions()
        end,
    })
    binding:Label({ Text = "Backspace or Delete always clears a key." })
    local profile = behaviour:Group({ Title = "Profile", Icon = "user-round", Opened = true })
    profile:Toggle({ Title = "Profile card", Default = interface.ShowUser ~= false, Callback = function(on)
        window:SetInterface("ShowUser", on)
        window:_layoutSidebar()
    end })
    profile:Toggle({ Title = "Hide avatar", Default = interface.HideAvatar, Callback = function(on)
        window:SetInterface("HideAvatar", on)
        if window.PaintUser then window.PaintUser() end
    end })
    profile:Toggle({ Title = "Streamer mode", Description = "Hides your name in the menu.", Default = interface.HideUser, Callback = function(on)
        window:SetInterface("HideUser", on)
        if window.PaintUser then window.PaintUser() end
    end })

    window.SettingsTab = tab
    return tab
end
