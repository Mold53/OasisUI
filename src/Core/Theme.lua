local import = ...
local Signal = import("Core/Signal")
local Services = import("Core/Services")
local Presets = import("Themes/Presets")

-- tokens: colour palette (from a preset) + style values the user tunes on top
local Theme = {
    Presets = Presets,
    Changed = Signal.new(),
    Palette = "Sapphire",
    Current = {} :: { [string]: any },
}

Theme.PaletteKeys = {
    "Accent", "AccentAlt", "Background", "BackgroundAlt", "Surface", "SurfaceHover", "Elevated", "ElevatedHover",
    "Stroke", "Divider", "Text", "TextDim", "TextMuted", "OnAccent", "Success", "Warning", "Danger",
}

Theme.StyleDefaults = {
    WindowTransparency   = 0.06,
    SurfaceTransparency  = 0.3,
    ElevatedTransparency = 0.15,
    StrokeTransparency   = 0.55,
    Radius               = 12,
    ElementRadius        = 8,
    Font                 = "Montserrat",
    AnimSpeed            = 1,
    Gradient             = true,
    GradientRotation     = 45,
    AnimatedTitle        = true,
}

-- { family, display name }; only families that render differently (GothamSSm draws Montserrat, Arial draws Arimo)
Theme.Fonts = {
    { "Montserrat", "Montserrat" },
    { "BuilderSans", "Builder Sans" },
    { "Ubuntu", "Ubuntu" },
    { "Nunito", "Nunito" },
    { "Roboto", "Roboto" },
    { "SourceSansPro", "Source Sans" },
    { "Arimo", "Arimo" },
    { "JosefinSans", "Josefin Sans" },
    { "TitilliumWeb", "Titillium" },
    { "Oswald", "Oswald" },
    { "Jura", "Jura" },
    { "Zekton", "Zekton" },
    { "Michroma", "Michroma" },
    { "Merriweather", "Merriweather" },
    { "FredokaOne", "Fredoka" },
    { "RobotoMono", "Roboto Mono" },
}

-- strong keys: roblox recycles instance wrappers, so a weak table would lose live bindings;
-- unparented (destroyed) instances are dropped by Apply and Sweep
local registry = {}
local pending = false

local function resolve(token)
    if type(token) == "function" then return token(Theme.Current) end
    return Theme.Current[token]
end
Theme.Resolve = resolve

local function paint(inst, map)
    for prop, token in map do
        local ok, value = pcall(resolve, token)
        if ok and value ~= nil then
            pcall(function() inst[prop] = value end)
        end
    end
end

-- map: property -> token name or function(current) -> value
function Theme.Bind(inst, map)
    local bound = registry[inst]
    if not bound then
        bound = {}
        registry[inst] = bound
    end
    for prop, token in map do bound[prop] = token end
    paint(inst, map)
    return inst
end

function Theme.Unbind(inst, prop)
    local bound = registry[inst]
    if bound then
        if prop then bound[prop] = nil else registry[inst] = nil end
    end
end

-- re-resolves an instance after its state changed; tweens when time > 0
function Theme.Refresh(inst, time)
    local bound = registry[inst]
    if not bound then return end
    local speed = Theme.Current.AnimSpeed or 1
    if not time or time <= 0 or speed <= 0 then
        paint(inst, bound)
        return
    end
    local goal = {}
    for prop, token in bound do
        local ok, value = pcall(resolve, token)
        if ok and value ~= nil then
            local kind = typeof(value)
            if kind == "Color3" or kind == "number" or kind == "UDim" or kind == "UDim2" or kind == "Vector2" then
                goal[prop] = value
            else
                pcall(function() inst[prop] = value end)
            end
        end
    end
    Services.TweenService:Create(inst, TweenInfo.new(time / speed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal):Play()
end

function Theme.Apply()
    for inst, map in registry do
        if inst.Parent == nil then
            registry[inst] = nil
        else
            paint(inst, map)
        end
    end
end

function Theme.Sweep()
    for inst in registry do
        if inst.Parent == nil then registry[inst] = nil end
    end
end

local function schedule()
    if pending then return end
    pending = true
    task.defer(function()
        pending = false
        Theme.Apply()
    end)
end

function Theme.Set(patch)
    for key, value in patch do Theme.Current[key] = value end
    schedule()
    Theme.Changed:Fire(patch)
end

function Theme.Get(key)
    return Theme.Current[key]
end

function Theme.UsePalette(name)
    local palette = Presets[name]
    if type(palette) ~= "table" or name == "Order" then return false end
    Theme.Palette = name
    Theme.Set(table.clone(palette))
    return true
end

function Theme.Font(weight, style)
    return function(current)
        return Font.new("rbxasset://fonts/families/" .. tostring(current.Font) .. ".json", weight or Enum.FontWeight.Regular, style or Enum.FontStyle.Normal)
    end
end

-- json-safe copy: colours as hex
function Theme.Export()
    local out = { Palette = Theme.Palette, Tokens = {} }
    for key, value in Theme.Current do
        -- "_" tokens are runtime state, not part of a theme
        if key:sub(1, 1) ~= "_" then
            out.Tokens[key] = typeof(value) == "Color3" and ("#" .. value:ToHex()) or value
        end
    end
    return out
end

function Theme.Import(data)
    if type(data) ~= "table" or type(data.Tokens) ~= "table" then return false end
    local patch = {}
    for key, value in data.Tokens do
        local current = Theme.Current[key]
        if typeof(current) == "Color3" and type(value) == "string" then
            local ok, color = pcall(Color3.fromHex, value)
            if ok then patch[key] = color end
        elseif current == nil or type(current) == type(value) then
            patch[key] = value
        end
    end
    if type(data.Palette) == "string" then Theme.Palette = data.Palette end
    Theme.Set(patch)
    return true
end

do
    for key, value in Presets.Sapphire do Theme.Current[key] = value end
    for key, value in Theme.StyleDefaults do Theme.Current[key] = value end
end

return Theme
