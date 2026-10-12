local _ = ...

-- palettes only hold colours; style tokens (radius, font, transparency, ...) live in Core/Theme
local rgb = Color3.fromRGB

local function palette(p)
    return {
        Accent        = p.Accent,
        AccentAlt     = p.AccentAlt,
        Background    = p.Background,
        BackgroundAlt = p.BackgroundAlt,
        Surface       = p.Surface,
        SurfaceHover  = p.SurfaceHover,
        Elevated      = p.Elevated,
        ElevatedHover = p.ElevatedHover,
        Stroke        = p.Stroke,
        Divider       = p.Divider,
        Text          = p.Text or rgb(232, 233, 240),
        TextDim       = p.TextDim or rgb(152, 154, 168),
        TextMuted     = p.TextMuted or rgb(98, 100, 114),
        OnAccent      = p.OnAccent or rgb(255, 255, 255),
        Success       = p.Success or rgb(74, 200, 122),
        Warning       = p.Warning or rgb(244, 182, 62),
        Danger        = p.Danger or rgb(236, 88, 88),
    }
end

return {
    Order = { "Sapphire", "Obsidian", "Midnight", "Ocean", "Emerald", "Amber", "Crimson", "Rose", "Paper" },

    Sapphire = palette({
        Accent = rgb(78, 132, 255), AccentAlt = rgb(140, 205, 255),
        Background = rgb(6, 6, 9), BackgroundAlt = rgb(36, 38, 46),
        Surface = rgb(12, 12, 16), SurfaceHover = rgb(20, 20, 26),
        Elevated = rgb(24, 25, 32), ElevatedHover = rgb(33, 34, 43),
        Stroke = rgb(88, 92, 110), Divider = rgb(52, 54, 66),
    }),

    -- greyscale, closest to the original sapphire look
    Obsidian = palette({
        Accent = rgb(222, 222, 228), AccentAlt = rgb(120, 120, 130),
        Background = rgb(5, 5, 6), BackgroundAlt = rgb(48, 48, 52),
        Surface = rgb(11, 11, 12), SurfaceHover = rgb(20, 20, 22),
        Elevated = rgb(24, 24, 27), ElevatedHover = rgb(34, 34, 38),
        Stroke = rgb(92, 92, 100), Divider = rgb(55, 55, 60),
        OnAccent = rgb(12, 12, 14),
    }),

    Midnight = palette({
        Accent = rgb(146, 112, 255), AccentAlt = rgb(206, 172, 255),
        Background = rgb(8, 7, 14), BackgroundAlt = rgb(34, 26, 58),
        Surface = rgb(14, 12, 24), SurfaceHover = rgb(22, 19, 36),
        Elevated = rgb(27, 23, 44), ElevatedHover = rgb(37, 32, 58),
        Stroke = rgb(96, 84, 140), Divider = rgb(55, 48, 84),
        Text = rgb(236, 232, 248), TextDim = rgb(160, 152, 186), TextMuted = rgb(104, 97, 132),
    }),

    Ocean = palette({
        Accent = rgb(38, 192, 232), AccentAlt = rgb(132, 232, 255),
        Background = rgb(4, 8, 11), BackgroundAlt = rgb(16, 36, 48),
        Surface = rgb(9, 15, 20), SurfaceHover = rgb(15, 24, 31),
        Elevated = rgb(19, 30, 39), ElevatedHover = rgb(26, 40, 52),
        Stroke = rgb(70, 104, 124), Divider = rgb(40, 60, 74),
        OnAccent = rgb(4, 16, 22),
    }),

    Emerald = palette({
        Accent = rgb(62, 204, 134), AccentAlt = rgb(156, 242, 194),
        Background = rgb(5, 9, 8), BackgroundAlt = rgb(18, 40, 31),
        Surface = rgb(9, 15, 13), SurfaceHover = rgb(15, 24, 21),
        Elevated = rgb(19, 30, 26), ElevatedHover = rgb(26, 40, 35),
        Stroke = rgb(70, 112, 96), Divider = rgb(40, 64, 55),
        OnAccent = rgb(4, 20, 12),
    }),

    Amber = palette({
        Accent = rgb(246, 172, 52), AccentAlt = rgb(255, 222, 134),
        Background = rgb(10, 8, 5), BackgroundAlt = rgb(42, 31, 16),
        Surface = rgb(16, 13, 9), SurfaceHover = rgb(25, 21, 15),
        Elevated = rgb(31, 26, 19), ElevatedHover = rgb(42, 35, 25),
        Stroke = rgb(118, 98, 66), Divider = rgb(66, 55, 38),
        OnAccent = rgb(24, 16, 4),
    }),

    Crimson = palette({
        Accent = rgb(232, 62, 82), AccentAlt = rgb(255, 144, 122),
        Background = rgb(10, 6, 7), BackgroundAlt = rgb(44, 18, 23),
        Surface = rgb(16, 10, 12), SurfaceHover = rgb(26, 16, 19),
        Elevated = rgb(32, 20, 24), ElevatedHover = rgb(44, 28, 33),
        Stroke = rgb(122, 72, 82), Divider = rgb(70, 40, 46),
    }),

    Rose = palette({
        Accent = rgb(242, 112, 172), AccentAlt = rgb(255, 184, 216),
        Background = rgb(10, 6, 9), BackgroundAlt = rgb(44, 20, 36),
        Surface = rgb(16, 10, 15), SurfaceHover = rgb(26, 16, 24),
        Elevated = rgb(32, 20, 30), ElevatedHover = rgb(44, 28, 41),
        Stroke = rgb(122, 76, 108), Divider = rgb(70, 42, 62),
    }),

    Paper = palette({
        Accent = rgb(52, 104, 242), AccentAlt = rgb(116, 168, 255),
        Background = rgb(238, 240, 245), BackgroundAlt = rgb(255, 255, 255),
        Surface = rgb(255, 255, 255), SurfaceHover = rgb(246, 247, 251),
        Elevated = rgb(236, 238, 244), ElevatedHover = rgb(226, 229, 238),
        Stroke = rgb(176, 182, 198), Divider = rgb(214, 218, 228),
        Text = rgb(24, 26, 34), TextDim = rgb(92, 98, 116), TextMuted = rgb(146, 152, 168),
    }),
}
