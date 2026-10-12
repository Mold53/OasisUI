--[[
    OasisUI showcase: every element, every option, module cards, favorites, search, themes and configs.

    loadstring(game:HttpGet("https://raw.githubusercontent.com/Mold53/OasisUI/main/examples/Example.lua"))()

    Nothing here touches the game; callbacks only update the "Last event" line on the Overview tab.
]]

local SOURCE = "https://raw.githubusercontent.com/Mold53/OasisUI/main/dist/OasisUI.lua"
local OasisUI = getgenv().OasisUI_Dev or loadstring(game:HttpGet(SOURCE))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local Window = OasisUI:CreateWindow({
    Title = "OasisUI",
    Subtitle = "Showcase · v" .. OasisUI.Version,
    Icon = "sparkles",
    Folder = "OasisUI-Showcase",
    Tags = { "v" .. OasisUI.Version },
    Theme = "Sapphire",
    ToggleKey = Enum.KeyCode.RightShift,
})

-- every callback reports here; shown on the Overview tab
local lastEvent
local function event(name, ...)
    local parts = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if typeof(value) == "Color3" then
            value = "#" .. value:ToHex():upper()
        elseif type(value) == "table" then
            value = "{ " .. table.concat(value, ", ") .. " }"
        end
        table.insert(parts, tostring(value))
    end
    if lastEvent then lastEvent:SetValue(name .. " → " .. table.concat(parts, ", ")) end
end
local function report(name)
    return function(...) event(name, ...) end
end
local function notify(title, content, kind)
    OasisUI:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 4 })
end

-- ── Overview ────────────────────────────────────────────────────────────────
local Overview = Window:Tab({ Title = "Overview", Icon = "house" })
local live = {}
do
    local welcome = Overview:Section({ Title = "Welcome", Icon = "sparkles", Side = "Left" })
    welcome:Paragraph({
        Title = "OasisUI " .. OasisUI.Version,
        Content = "A UI library for big script hubs. Every tab on the left shows a part of it; the "
            .. "<b>Elements</b> group covers each element with all of its options.",
        Icon = "info",
    })
    welcome:Paragraph({
        Title = "Things to try",
        Content = "• Click a module header to switch it on, its settings fold out.\n"
            .. "• Middle-click a header or click the key pill to bind a key, right-click the pill for Hold.\n"
            .. "• Right-click a header for the module menu.\n"
            .. "• Drag the grip (top right of a card) to rearrange, also between the columns.\n"
            .. "• Click the star to pin a module to Favorites.\n"
            .. "• Ctrl+F searches every tab.\n"
            .. "• Settings (bottom left) has the theme editor and the config manager.",
    })
    lastEvent = welcome:Label({ Text = "Last event", Value = "—" })

    local stats = Overview:Section({ Title = "Live", Icon = "activity", Side = "Right" })
    live.Fps = stats:Label({ Text = "Frame rate", Value = "—" })
    live.Ping = stats:Label({ Text = "Ping", Value = "—" })
    live.Memory = stats:Label({ Text = "Memory", Value = "—" })
    live.Session = stats:Label({ Text = "Session", Value = "0s" })
    live.Load = stats:ProgressBar({ Title = "Frame budget", Value = 0, Suffix = "%" })

    local quick = Overview:Section({ Title = "Quick actions", Icon = "zap", Side = "Right" })
    local presets = OasisUI.Theme.Presets.Order
    quick:Dropdown({
        Title = "Theme preset",
        Values = presets,
        Default = OasisUI.Theme.Palette,
        Callback = function(name)
            OasisUI:SetTheme(name)
            event("Theme preset", name)
        end,
    })
    quick:Buttons({
        { Title = "Random accent", Icon = "palette", Callback = function()
            local color = Color3.fromHSV(math.random(), 0.65, 1)
            OasisUI:SetAccent(color)
            event("Accent", color)
        end },
        { Title = "Settings", Icon = "settings", Callback = function() Window:SelectTab(Window.SettingsTab) end },
    })
    quick:Code({
        Title = "Load this showcase",
        Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Mold53/OasisUI/main/examples/Example.lua"))()',
    })
end

-- ── Example hub ─────────────────────────────────────────────────────────────
Window:TabSection("Example hub")

local Combat = Window:Tab({ Title = "Combat", Icon = "swords" })
do
    local autoParry = Combat:Module({
        Title = "Auto Parry",
        Description = "Parries the ball right before it reaches you.",
        Flag = "AutoParry",
        Keybind = { Key = Enum.KeyCode.F },
        Side = "Left",
        Callback = report("Auto Parry"),
    })
    autoParry:Segmented({ Title = "Parry mode", Values = { "Remote", "Keypress" }, Flag = "ParryMode", Callback = report("Parry mode") })
    local randomize = autoParry:Toggle({ Title = "Randomize accuracy", Flag = "RandomizeAccuracy", Callback = report("Randomize accuracy") })
    autoParry:Slider({ Title = "Accuracy", Min = 1, Max = 100, Default = 92, Suffix = "%", Buttons = true, Flag = "Accuracy", Callback = report("Accuracy") })
        :DependsOn(randomize, function(on) return not on end)
    autoParry:Range({ Title = "Accuracy range", Min = 1, Max = 100, Default = { 80, 95 }, MinGap = 5, Suffix = "%", Flag = "AccuracyRange", Callback = report("Accuracy range") })
        :DependsOn(randomize)
    autoParry:Dropdown({
        Title = "Aim",
        Values = {
            { Title = "Camera", Description = "Where you look", Icon = "eye" },
            { Title = "Closest", Description = "Nearest player", Icon = "crosshair" },
            { Title = "Random", Description = "A new target each parry", Icon = "sparkles" },
            { Title = "Straight", Icon = "arrow-up" },
            { Title = "Backwards", Icon = "arrow-down" },
        },
        Flag = "Aim",
        Callback = report("Aim"),
    })
    local detections = autoParry:Group({ Title = "Detections", Icon = "radar" })
    detections:Checkbox({ Title = "Infinity", Default = true, Flag = "DetectInfinity", Callback = report("Infinity") })
    detections:Checkbox({ Title = "Singularity", Default = true, Flag = "DetectSingularity", Callback = report("Singularity") })
    detections:Checkbox({ Title = "Time Hole", Flag = "DetectTimeHole", Callback = report("Time Hole") })
    local fury = detections:Toggle({ Title = "Slashes of Fury", Flag = "DetectFury", Callback = report("Slashes of Fury") })
    detections:Slider({ Title = "Hit delay", Min = 20, Max = 250, Default = 50, Suffix = " ms", Flag = "FuryDelay", Callback = report("Hit delay") })
        :DependsOn(fury, nil, "Hide")

    local spam = Combat:Module({
        Title = "Auto Spam",
        Description = "Spams parry during close clashes. Hold mode by default.",
        Flag = "AutoSpam",
        Keybind = { Key = Enum.KeyCode.E, Mode = "Hold" },
        Side = "Right",
        Callback = report("Auto Spam"),
    })
    spam:Slider({ Title = "Rate", Min = 1, Max = 1000, Default = 30, Suffix = " cps", Icons = { From = "minus", To = "zap" }, Flag = "SpamRate", Callback = report("Rate") })
    spam:Slider({ Title = "Threshold", Min = 0.5, Max = 5, Step = 0.1, Default = 2, ShowRange = true, Flag = "SpamThreshold", Callback = report("Threshold") })

    local trigger = Combat:Module({ Title = "Triggerbot", Description = "One parry per approach with a human delay.", Flag = "Triggerbot", Side = "Right", Callback = report("Triggerbot") })
    trigger:Range({ Title = "Reaction", Min = 0, Max = 500, Default = { 40, 120 }, Suffix = " ms", ShowRange = true, Flag = "Reaction", Callback = report("Reaction") })

    Combat:Module({ Title = "Auto Ability", Description = "Uses your ability as soon as it is ready.", Flag = "AutoAbility", Side = "Left", Callback = report("Auto Ability") })
end

local Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
do
    local esp = Visuals:Module({ Title = "ESP", Description = "Names and timers above players.", Flag = "ESP", Default = true, Side = "Left", Callback = report("ESP") })
    esp:Toggle({ Title = "Names", Default = true, Flag = "EspNames", Callback = report("Names") })
    esp:ColorPicker({ Title = "Name colour", Default = Color3.fromRGB(255, 255, 255), Flag = "EspNameColor", Callback = report("Name colour") })
    esp:Toggle({ Title = "Ability timer", Default = true, Flag = "EspTimer", Callback = report("Ability timer") })
    esp:ColorPicker({ Title = "Timer colour", Default = Color3.fromRGB(80, 180, 255), Transparency = 0.2, Flag = "EspTimerColor", Callback = report("Timer colour") })

    local world = Visuals:Section({ Title = "World", Description = "Client side only.", Icon = "globe", Side = "Right" })
    world:Dropdown({
        Title = "Hide effects",
        Multi = true,
        Values = { "Sparkles", "Trails", "Explosions", "Smoke", "Fire", "Beams", "Particles", "Decals", "Sky", "Fog", "Shadows", "Bloom" },
        Default = { "Smoke", "Fog" },
        Flag = "HideEffects",
        Callback = report("Hide effects"),
    })
    world:Slider({ Title = "Brightness", Min = 0, Max = 5, Step = 0.25, Default = 1, Icons = { From = "sun-dim", To = "sun" }, Flag = "Brightness", Callback = report("Brightness") })
end

local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
do
    local spoof = PlayerTab:Module({ Title = "Spoofer", Description = "Client side stat overrides.", Flag = "Spoofer", Keybind = false, Side = "Left", Callback = report("Spoofer") })
    spoof:Input({ Title = "Display name", Default = "OASIS", MaxLength = 20, Flag = "SpoofName", Callback = report("Display name") })
    spoof:Input({ Title = "Coins", Numeric = true, Min = 0, Max = 1e12, Default = 9999, Tooltip = "Accepts 1.5k, 2m, 3b.", Flag = "SpoofCoins", Callback = report("Coins") })

    local binds = PlayerTab:Section({ Title = "Hotkeys", Icon = "keyboard", Side = "Right" })
    binds:Keybind({ Title = "Sprint", Default = Enum.KeyCode.LeftShift, Mode = "Hold", Flag = "SprintKey", Callback = report("Sprint") })
    binds:Keybind({ Title = "Panic", Default = Enum.KeyCode.End, Mode = "Always", Flag = "PanicKey", Callback = function() notify("Panic", "Always-mode key pressed.", "Warning") end })
end

-- ── Elements ────────────────────────────────────────────────────────────────
Window:TabSection("Elements")

local Toggles = Window:Tab({ Title = "Controls", Icon = "toggle-right" })
do
    local toggles = Toggles:Section({ Title = "Toggle", Icon = "toggle-right", Side = "Left" })
    toggles:Toggle({ Title = "Switch", Callback = report("Switch") })
    toggles:Toggle({ Title = "On by default", Description = "Default = true", Default = true, Callback = report("On by default") })
    toggles:Checkbox({ Title = "Checkbox", Callback = report("Checkbox") })
    toggles:Toggle({ Title = "Checkbox style", Description = "Style = \"Checkbox\"", Style = "Checkbox", Default = true, Callback = report("Checkbox style") })
    toggles:Toggle({ Title = "With a key", Description = "Keybind = true, Toggle or Hold", Keybind = true, Flag = "ToggleWithKey", Callback = report("With a key") })
    toggles:Toggle({ Title = "With a tooltip", Tooltip = "Hover the i for help text.", Callback = report("With a tooltip") })

    local buttons = Toggles:Section({ Title = "Button", Icon = "mouse-pointer-click", Side = "Right" })
    buttons:Button({ Title = "Default", Icon = "rocket", Callback = function() event("Button", "Default") end })
    buttons:Button({ Title = "Primary", Icon = "check", Style = "Primary", Callback = function() event("Button", "Primary") end })
    buttons:Button({ Title = "Ghost", Icon = "layers", Style = "Ghost", Callback = function() event("Button", "Ghost") end })
    buttons:Button({ Title = "Danger with confirm", Icon = "trash-2", Style = "Danger", Confirm = true, Callback = function() event("Button", "Danger confirmed") end })
    buttons:Button({ Title = "Bound to a key", Icon = "keyboard", Keybind = true, Flag = "ButtonKey", Tooltip = "Click the pill to bind; the key presses the button.", Callback = function() event("Button", "Key press") end })
    buttons:Divider("Rows")
    buttons:Buttons({
        { Title = "Left", Callback = function() event("Row", "Left") end },
        { Title = "Right", Callback = function() event("Row", "Right") end },
    })
    buttons:Buttons({
        { Title = "One", Icon = "hash", Callback = function() event("Row", "One") end },
        { Title = "Two", Style = "Primary", Callback = function() event("Row", "Two") end },
        { Title = "Three", Style = "Danger", Confirm = "Sure?", Callback = function() event("Row", "Three") end },
    })

    local cards = Toggles:Module({
        Title = "Module card",
        Description = "A module: switch, key pill, star, grip. Its settings fold out below.",
        Icon = "layers",
        Keybind = { Key = Enum.KeyCode.G },
        Side = "Left",
        Callback = report("Module card"),
    })
    cards:Label({ Text = "Settings live here. Turn \"Expand modules when enabled\" off in Settings to open them with the chevron instead." })
    cards:Toggle({ Title = "Nested option", Callback = report("Nested option") })

    Toggles:Module({ Title = "No key pill", Description = "Keybind = false", Keybind = false, Side = "Right", Callback = report("No key pill") })
    Toggles:Section({ Title = "Section", Description = "Toggle = false: a card without switch, open by default. Useful for grouping.", Side = "Right" })
        :Label({ Text = "Sections hold elements like modules do." })
end

local Sliders = Window:Tab({ Title = "Sliders", Icon = "sliders-horizontal" })
do
    local single = Sliders:Section({ Title = "Slider", Icon = "sliders-horizontal", Side = "Left" })
    single:Slider({ Title = "Basic", Min = 0, Max = 100, Default = 40, Callback = report("Basic") })
    single:Slider({ Title = "Decimals", Description = "Step = 0.05", Min = 0, Max = 1, Step = 0.05, Default = 0.35, Callback = report("Decimals") })
    single:Slider({ Title = "Prefix and suffix", Min = 0, Max = 500, Default = 120, Prefix = "~", Suffix = " studs", Callback = report("Prefix and suffix") })
    single:Slider({ Title = "Steppers", Description = "Buttons = true", Min = 0, Max = 20, Default = 10, Buttons = true, Callback = report("Steppers") })
    single:Slider({ Title = "End icons", Min = 0, Max = 100, Default = 70, Icons = { From = "volume-2", To = "music" }, Callback = report("End icons") })
    single:Slider({ Title = "Range labels", Min = -50, Max = 50, Default = 0, ShowRange = true, Callback = report("Range labels") })
    single:Slider({
        Title = "Custom format",
        Min = 1, Max = 4, Step = 0.25, Default = 1,
        Format = function(value) return value .. "×" end,
        Callback = report("Custom format"),
    })
    single:Slider({ Title = "Read-only value", Description = "Input = false", Min = 0, Max = 100, Default = 25, Input = false, Callback = report("Read-only value") })
    single:Slider({ Title = "On release", Description = "Live = false: callback after you let go", Min = 0, Max = 100, Default = 50, Live = false, Callback = report("On release") })

    local range = Sliders:Section({ Title = "Range slider", Icon = "arrow-up-down", Side = "Right" })
    range:Range({ Title = "Basic", Min = 0, Max = 100, Default = { 20, 80 }, Callback = report("Range basic") })
    range:Range({ Title = "Minimum gap", Description = "MinGap = 20", Min = 0, Max = 100, Default = { 30, 60 }, MinGap = 20, Callback = report("Minimum gap") })
    range:Range({ Title = "Milliseconds", Min = 0, Max = 500, Default = { 40, 120 }, Suffix = " ms", ShowRange = true, Callback = report("Milliseconds") })
    range:Range({ Title = "Shift both", Description = "Buttons move the whole range", Min = 0, Max = 10, Step = 0.5, Default = { 2, 5 }, Buttons = true, Callback = report("Shift both") })
end

local Selection = Window:Tab({ Title = "Selection", Icon = "list" })
do
    local single = Selection:Section({ Title = "Dropdown", Icon = "list", Side = "Left" })
    single:Dropdown({ Title = "Single", Values = { "Low", "Medium", "High" }, Default = "Medium", Callback = report("Single") })
    single:Dropdown({
        Title = "Icons and descriptions",
        Values = {
            { Title = "Sword", Description = "Close range", Icon = "sword" },
            { Title = "Shield", Description = "Blocks a hit", Icon = "shield" },
            { Title = "Crown", Description = "Rare", Icon = "crown" },
            { Title = "Gem", Description = "Very rare", Icon = "gem" },
        },
        Callback = report("Icons and descriptions"),
    })
    single:Dropdown({ Title = "Allow none", Description = "Click the selected entry to clear it", Values = { "Red", "Green", "Blue" }, AllowNone = true, Placeholder = "No colour", Callback = report("Allow none") })

    local many = {}
    for index = 1, 60 do table.insert(many, string.format("Item %02d", index)) end
    local multi = Selection:Section({ Title = "Multi select", Icon = "check-check", Side = "Right" })
    multi:Dropdown({ Title = "Multi", Multi = true, Values = { "Apples", "Pears", "Plums", "Cherries" }, Default = { "Pears" }, Callback = report("Multi") })
    multi:Dropdown({ Title = "Search", Description = "Search turns on by itself above 8 entries", Multi = true, Values = many, Callback = report("Search") })

    local dynamic = Selection:Section({ Title = "Dynamic values", Icon = "refresh-cw", Side = "Left" })
    local players = dynamic:Dropdown({ Title = "Players", Multi = true, Values = {}, Placeholder = "Press refresh", Callback = report("Players") })
    local count = 0
    dynamic:Buttons({
        { Title = "Refresh", Icon = "refresh-cw", Callback = function()
            local names = {}
            for _, player in Players:GetPlayers() do table.insert(names, player.Name) end
            players:Refresh(names)
            event("Refresh", #names .. " players")
        end },
        { Title = "Add", Icon = "plus", Callback = function()
            count += 1
            players:Add("Bot " .. count)
        end },
        { Title = "Clear", Icon = "x", Callback = function() players:Refresh({}) end },
    })

    local segments = Selection:Section({ Title = "Segmented", Icon = "columns-2", Side = "Right" })
    segments:Segmented({ Title = "Two", Values = { "Remote", "Keypress" }, Callback = report("Two") })
    segments:Segmented({ Title = "Four", Values = { "Low", "Medium", "High", "Ultra" }, Default = "High", Callback = report("Four") })
end

local Inputs = Window:Tab({ Title = "Input", Icon = "type" })
do
    local text = Inputs:Section({ Title = "Text", Icon = "type", Side = "Left" })
    text:Input({ Title = "Basic", Placeholder = "Type and press Enter", Callback = report("Basic input") })
    text:Input({ Title = "Icon and limit", Placeholder = "Max 12 characters", Icon = "user", MaxLength = 12, Callback = report("Icon and limit") })
    text:Input({
        Title = "Validated",
        Description = "Letters only",
        Placeholder = "abc",
        Validate = function(value)
            if value:match("^%a*$") then return true end
            return false, "Only letters are allowed."
        end,
        Callback = report("Validated"),
    })
    local mirror = text:Label({ Text = "Typed", Value = "" })
    text:Input({ Title = "Live", Description = "Finished = false: fires on every keystroke", Finished = false, Callback = function(value)
        mirror:SetValue(value)
    end })
    text:Input({ Title = "Multiline", Multiline = true, Height = 64, Placeholder = "Notes…", Callback = report("Multiline") })

    local numbers = Inputs:Section({ Title = "Numbers", Icon = "hash", Side = "Left" })
    numbers:Input({ Title = "Range 0 to 100", Numeric = true, Min = 0, Max = 100, Default = 50, Callback = report("Range 0 to 100") })
    numbers:Input({ Title = "Shorthand", Description = "1.5k, 2m and 3b work", Numeric = true, Default = 1500, Callback = report("Shorthand") })

    local keys = Inputs:Section({ Title = "Keybind", Icon = "keyboard", Side = "Right" })
    keys:Keybind({ Title = "Toggle", Default = Enum.KeyCode.T, Mode = "Toggle", Callback = report("Toggle key") })
    keys:Keybind({ Title = "Hold", Default = Enum.KeyCode.H, Mode = "Hold", Callback = report("Hold key") })
    keys:Keybind({ Title = "Always", Description = "Fires on every press", Default = Enum.KeyCode.J, Mode = "Always", Callback = function() event("Always key", "pressed") end })
    keys:Keybind({ Title = "Hold only", Description = "Modes = { \"Hold\" }", Mode = "Hold", Modes = { "Hold" }, Callback = report("Hold only") })
    keys:Keybind({ Title = "Unbound", ChangedCallback = function(key) notify("Key changed", "Unbound → " .. tostring(key)) end })

    local colors = Inputs:Section({ Title = "Colour picker", Icon = "palette", Side = "Right" })
    colors:ColorPicker({ Title = "Colour", Default = Color3.fromRGB(78, 132, 255), Callback = report("Colour") })
    colors:ColorPicker({ Title = "With transparency", Default = Color3.fromRGB(240, 110, 170), Transparency = 0.3, Callback = report("With transparency") })
    colors:ColorPicker({ Title = "Rainbow", Default = Color3.fromRGB(255, 0, 0), Rainbow = true, Tooltip = "The sparkle button in the picker toggles rainbow." })
end

local Display = Window:Tab({ Title = "Display", Icon = "layout-dashboard" })
do
    local text = Display:Section({ Title = "Text", Icon = "type", Side = "Left" })
    text:Label({ Text = "A plain label wraps when the text gets longer than the card is wide." })
    text:Label({ Text = "Label with a value", Value = "42" })
    text:Label({ Text = 'Rich text: <b>bold</b>, <i>italic</i>, <font color="#4E84FF">coloured</font>' })
    text:Paragraph({ Title = "Paragraph", Content = "A title and a body on a soft background.", Icon = "info" })
    text:Paragraph({ Content = "A paragraph without a title." })

    local layout = Display:Section({ Title = "Layout", Icon = "layers", Side = "Left" })
    layout:Label({ Text = "Above a divider" })
    layout:Divider()
    layout:Label({ Text = "Between dividers" })
    layout:Divider("Caption")
    layout:Spacer({ Height = 12 })
    local group = layout:Group({ Title = "Group", Icon = "folder-open", Opened = true })
    group:Toggle({ Title = "Inside a group", Callback = report("Inside a group") })
    local inner = group:Group({ Title = "Nested group" })
    inner:Slider({ Title = "Deep slider", Min = 0, Max = 10, Default = 3, Callback = report("Deep slider") })

    local media = Display:Section({ Title = "Media", Icon = "image", Side = "Right" })
    media:Image({ Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420", Height = 140, ScaleType = Enum.ScaleType.Fit })
    media:Image({ Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=512&h=512", AspectRatio = "16:9" })
    media:Code({ Title = "Code", Code = 'local Tab = Window:Tab({ Title = "Combat", Icon = "swords" })\nlocal Module = Tab:Module({ Title = "Auto Parry", Flag = "AutoParry" })\nModule:Slider({ Title = "Accuracy", Min = 1, Max = 100 })' })

    local progress = Display:Section({ Title = "Progress", Icon = "gauge", Side = "Right" })
    live.Download = progress:ProgressBar({ Title = "Percent", Value = 0 })
    live.Stamina = progress:ProgressBar({ Title = "Custom colour and suffix", Value = 70, Max = 100, Suffix = " hp", Color = "Success" })
    live.Steps = progress:ProgressBar({ Title = "Custom format", Value = 3, Max = 8, Format = function(value, max) return string.format("%d of %d", value, max) end })
end

local Feedback = Window:Tab({ Title = "Feedback", Icon = "bell" })
do
    local toasts = Feedback:Section({ Title = "Notifications", Icon = "bell", Side = "Left" })
    toasts:Buttons({
        { Title = "Info", Callback = function() notify("Info", "Something happened.") end },
        { Title = "Success", Callback = function() notify("Saved", "Everything went fine.", "Success") end },
    })
    toasts:Buttons({
        { Title = "Warning", Callback = function() notify("Careful", "Something looks off.", "Warning") end },
        { Title = "Error", Callback = function() notify("Failed", "Something went wrong.", "Error") end },
    })
    toasts:Button({ Title = "With buttons", Icon = "message-square", Callback = function()
        OasisUI:Notify({
            Title = "Update available",
            Content = "Hover a notification to pause its timer.",
            Duration = 10,
            Buttons = {
                { Title = "Install", Callback = function() event("Notification", "Install") end },
                { Title = "Later", Callback = function() event("Notification", "Later") end },
            },
        })
    end })
    toasts:Label({ Text = "The position is set in Settings → Menu." })

    local dialogs = Feedback:Section({ Title = "Dialogs", Icon = "message-square", Side = "Left" })
    dialogs:Button({ Title = "Confirm", Callback = function()
        Window:Dialog({
            Title = "Reset everything?",
            Icon = "triangle-alert",
            Content = "Dialogs block the menu until you choose.",
            Buttons = {
                { Title = "Cancel", Style = "Secondary" },
                { Title = "Reset", Style = "Danger", Callback = function() event("Dialog", "Reset") end },
            },
        })
    end })
    dialogs:Button({ Title = "Text prompt", Callback = function()
        Window:Dialog({
            Title = "Rename",
            Icon = "pencil",
            Content = "Returns false from the callback to keep the dialog open.",
            Input = { Default = LocalPlayer.DisplayName, Placeholder = "Name" },
            Buttons = {
                { Title = "Cancel", Style = "Secondary" },
                { Title = "Apply", Style = "Primary", Callback = function(value, dialog)
                    if #value < 3 then
                        dialog:SetError("Use at least 3 characters.")
                        return false
                    end
                    event("Dialog", value)
                    return true
                end },
            },
        })
    end })

    local states = Feedback:Section({ Title = "States", Icon = "lock", Side = "Right" })
    states:Toggle({ Title = "Locked", Locked = true, LockedReason = "Locked elements explain why on hover." })
    local master = states:Toggle({ Title = "Enable advanced", Description = "Unlocks the slider below", Callback = report("Enable advanced") })
    states:Slider({ Title = "Advanced value", Min = 0, Max = 100, Default = 50, Callback = report("Advanced value") }):DependsOn(master)
    local reveal = states:Toggle({ Title = "Show hidden option", Callback = report("Show hidden option") })
    states:Input({ Title = "Hidden until enabled", Placeholder = "Hello" }):DependsOn(reveal, nil, "Hide")
    local renamed = 0
    local rename
    rename = states:Button({ Title = "Rename me", Icon = "pencil", Callback = function()
        renamed += 1
        rename:SetTitle("Renamed " .. renamed .. "×")
    end })

    Feedback:Module({ Title = "Locked module", Description = "Right-click the header and choose Unlock.", Locked = true, Side = "Right" })
        :Toggle({ Title = "Option behind the lock" })
end

-- ── live values ─────────────────────────────────────────────────────────────
local started = os.clock()
local frames, elapsed, download = 0, 0, 0
local connection = RunService.RenderStepped:Connect(function(dt)
    frames += 1
    elapsed += dt
    if elapsed < 0.5 then return end
    local fps = frames / elapsed
    live.Fps:SetValue(math.floor(fps + 0.5) .. " fps")
    live.Ping:SetValue(math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5) .. " ms")
    live.Memory:SetValue(math.floor(Stats:GetTotalMemoryUsageMb()) .. " MB")
    live.Session:SetValue(math.floor(os.clock() - started) .. "s")
    live.Load:Set(math.clamp(math.floor((elapsed / frames) / (1 / 60) * 100), 0, 100))
    download = (download + 7) % 107
    live.Download:Set(math.min(download, 100))
    live.Steps:Set((live.Steps:Get() % 8) + 1)
    frames, elapsed = 0, 0
end)
OasisUI:OnUnload(function() connection:Disconnect() end)

task.delay(1, function()
    notify("OasisUI " .. OasisUI.Version, "RightShift hides the menu. Settings are at the bottom left.", "Success")
end)
