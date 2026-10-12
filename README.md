# OasisUI

[![Release](https://img.shields.io/github/v/release/Mold53/OasisUI?label=release&color=4e84ff)](https://github.com/Mold53/OasisUI/releases/latest)
[![CI](https://github.com/Mold53/OasisUI/actions/workflows/ci.yml/badge.svg)](https://github.com/Mold53/OasisUI/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/Mold53/OasisUI?color=4e84ff)](LICENSE)

OasisUI is a Roblox UI library for executor scripts. The look starts from the Sapphire layout: module cards
with a switch and a key pill, settings that fold out below, and two scrolling columns. On top of that it adds
what large hubs need: drag-to-rearrange cards, favorites, global search, a live theme editor, a config manager
and overlays.

## Showcase

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mold53/OasisUI/main/examples/Example.lua"))()
```

The showcase ([examples/Example.lua](examples/Example.lua)) has a tab for every element group and shows each
option. It does not change anything in the game.

## Installation

Pin a version for scripts you ship. The release file never changes after it is published:

```lua
local OasisUI = loadstring(game:HttpGet("https://github.com/Mold53/OasisUI/releases/download/v1.0.0/OasisUI.lua"))()
```

| Source | URL |
| --- | --- |
| Pinned release | `https://github.com/Mold53/OasisUI/releases/download/v1.0.0/OasisUI.lua` |
| Latest release | `https://github.com/Mold53/OasisUI/releases/latest/download/OasisUI.lua` |
| Development (`main`) | `https://raw.githubusercontent.com/Mold53/OasisUI/main/dist/OasisUI.lua` |

`OasisUI.Version` holds the loaded version (`"1.0.0"`).

## Quick start

```lua
local OasisUI = loadstring(game:HttpGet("https://github.com/Mold53/OasisUI/releases/download/v1.0.0/OasisUI.lua"))()

local Window = OasisUI:CreateWindow({ Title = "Oasis", Subtitle = "Blade Ball", Folder = "Oasis" })
local Combat = Window:Tab({ Title = "Combat", Icon = "swords" })

local AutoParry = Combat:Module({
    Title = "Auto Parry",
    Description = "Parries the ball right before it hits you.",
    Flag = "AutoParry",
    Callback = function(enabled) end,
})
AutoParry:Slider({ Title = "Accuracy", Min = 1, Max = 100, Default = 90, Suffix = "%", Flag = "Accuracy" })
```

## Features

- **Module cards**: title, description, key pill, switch. Settings fold out when the module is enabled
  (configurable) or with the chevron. Right-click a header for its menu, middle-click to bind a key.
- **Two independent scrolling columns** per tab. Drag a card by its grip to reorder it or move it to the
  other column. The layout is saved.
- **Favorites**: the star on a card pins it to the Favorites page. Cards there are live mirrors of the
  originals, and that page can be rearranged too.
- **Search** across every tab (Ctrl+F). Matching cards are shown with their tab name, cards that only match
  through a child element open automatically, and matching rows are highlighted.
- **Keybinds** in the Sapphire style. Click the pill and press a key. Backspace clears the key and Esc
  cancels. Right-click the pill to choose a mode: Toggle, Hold or Always. Mouse buttons 2 and 3 and
  gamepad buttons also work.
- **Elements**: Toggle and Checkbox (both can have a key), Button (styles, confirm, key), ButtonRow,
  Slider and RangeSlider, Dropdown (single or multi, search, descriptions, icons, refresh), Input (text or
  number, validation, multiline), Keybind, ColorPicker (HSV, alpha, hex, RGB, rainbow, copy/paste),
  Segmented, Group (collapsible sub-list), Label (with a live value), Paragraph, Divider, Spacer,
  ProgressBar, Image and Code.
  - **Slider extras**: the value is editable in the title line, `−`/`+` steppers, `From`/`To` icons, and
    min/max labels.
- **Element states**: every element supports `Locked` (with a reason tooltip), `Visible`, and
  `DependsOn(otherElement)`.
- **Theme editor** in the Settings tab: presets, nine colours, window, card and field transparency,
  corner radius, font, scale, animation speed, background gradient, animated title, acrylic blur and
  compact sidebar. Themes can be saved, loaded, exported and imported.
- **Config manager**: save, load, rename, delete, autoload, auto save, and export/import through the
  clipboard. Keybinds are stored in the config too.
- **Overlays**: keybind list, watermark (FPS, ping, time), notifications (four types, buttons, pause on
  hover), dialogs with an optional text input, tooltips.
- **Window**: drag, resize, minimize to a title pill, hide with the menu key, fit to small screens, and a
  menu button on touch devices. The menu remembers its position, size and last tab.
- **Re-running a script** unloads the previous instance (same `GuiName`).

## Window

```lua
local Window = OasisUI:CreateWindow({
    Title = "Oasis",                      -- animated accent gradient unless disabled in the theme
    Subtitle = "Blade Ball",
    Icon = "sparkles",                    -- lucide name, rbxassetid://… or a number
    Folder = "Oasis",                     -- <Folder>/configs, <Folder>/themes, <Folder>/ui.json
    Size = UDim2.fromOffset(780, 520),
    MinSize = Vector2.new(560, 380),
    Theme = "Sapphire",                   -- used until the user picks something else
    ThemeOverrides = { Accent = Color3.fromRGB(255, 120, 60) },
    Tags = { "beta", { Text = "v1.2", Color = Color3.fromRGB(70, 200, 120) } },
    ToggleKey = Enum.KeyCode.RightShift,
    Search = true,
    User = true,                          -- avatar card at the bottom of the sidebar
    Settings = true,                      -- built-in Settings tab
    AutoLoad = true,                      -- loads the autoload config after the script finished building
    GuiName = "OasisUI",
})
```

| Method | |
| --- | --- |
| `Window:Tab(def)` | new tab (`Title`, `Icon`, `Columns = 1 \| 2`, `Id`) |
| `Window:TabSection(text)` / `Window:Divider()` | caption or line in the sidebar |
| `Window:SelectTab(tab \| index, focusModule?)` / `Window:SelectFavorites()` | |
| `Window:Dialog({ Title, Content, Icon, Input = { Default, Placeholder }, Buttons = { { Title, Style, Callback(text, dialog) } } })` | return `false` from a callback to keep it open; `dialog:SetError(text)` |
| `Window:Notify(options)` | same as `OasisUI:Notify` |
| `Window:SetVisible(bool)`, `:Toggle()`, `:SetMinimized(bool)`, `:SetScale(n)`, `:SetCompact(bool)` | |
| `Window:SetTitle(text)`, `:SetSubtitle(text)` | |
| `Window:LoadAutoload()` | call it yourself if your script yields before the UI is complete |
| `Window.Config` | config manager (below) |

## Tabs, modules, sections

```lua
local Tab = Window:Tab({ Title = "Combat", Icon = "swords" })

local Module = Tab:Module({
    Title = "Auto Parry",
    Description = "…",
    Icon = "shield",                      -- optional, shown before the title
    Flag = "AutoParry",                   -- saves enabled state + key
    Default = false,
    Keybind = { Key = Enum.KeyCode.F, Mode = "Toggle" },  -- false hides the pill
    Side = "Left",                        -- first placement; the user's layout wins afterwards
    Opened = nil,                         -- force the settings open/closed initially
    Callback = function(enabled) end,
})

local Section = Tab:Section({ Title = "Info", Icon = "info", Side = "Right" })  -- no switch, open by default
```

Module methods: `Get()`, `Set(bool)`, `SetEnabled(bool)`, `ToggleEnabled()`, `OnChanged(fn)`,
`SetExpanded(bool)`, `SetFavorite(bool)`, `SetLocked(bool)`, `SetVisible(bool)`, `SetTitle`,
`SetDescription`, `Reset()` (module and all of its elements), `Destroy()`, `Binding` (see Keybind).

Modules, sections and groups take elements with `Module:Toggle({...})` or `Module:AddToggle({...})`.
The Fluent style `Module:AddToggle("Flag", {...})` works as well.

## Elements

Shared options: `Title`, `Description`, `Tooltip`, `Flag` (saved in configs, reachable through
`OasisUI.Flags[flag]`), `Callback`, `Locked`, `LockedReason`, `Visible`.
Shared methods: `Get()`, `Set(value, silent?)`, `Reset()`, `OnChanged(fn)`, `SetTitle`, `SetDescription`,
`SetLocked(bool, reason?)`, `SetVisible(bool)`, `DependsOn(element, predicate?, "Lock" | "Hide")`, `Destroy()`.

| Element | Options | Extra methods |
| --- | --- | --- |
| `Toggle` / `Checkbox` | `Default`, `Style = "Switch" \| "Checkbox"`, `Keybind = true \| key \| { Key, Mode, Modes }` | `Binding` |
| `Button` | `Icon`, `Style = "Default" \| "Primary" \| "Danger" \| "Ghost"`, `Confirm = true \| text`, `Keybind` | `Press()` |
| `Buttons` | list of `{ Title, Icon, Style, Confirm, Callback }` | `SetButtonTitle(i, text)`, `SetButtonLocked(i, bool)` |
| `Slider` | `Min`, `Max`, `Default`, `Step` or `Rounding`, `Prefix`, `Suffix`, `Format(v)`, `Input` (editable value, default on), `Buttons` (−/+), `Icons = { From, To }`, `ShowRange`, `Live` (default on) | `SetMin`, `SetMax` |
| `Range` | as Slider, `Default = { lo, hi }`, `MinGap`; callback gets `(lo, hi)` | |
| `Dropdown` | `Values` (strings or `{ Title, Value, Description, Icon }`), `Default`, `Multi`, `Search` (auto above 8), `AllowNone`, `Placeholder`, `MaxVisible` | `Refresh(values, keep?)`, `Add`, `Remove`, `Toggle(value)`, `IsSelected`, `GetValues` |
| `Input` | `Default`, `Placeholder`, `Numeric`, `Min`, `Max`, `Step`, `MaxLength`, `Finished` (default on), `Validate(text) -> ok, message`, `Icon`, `Multiline`, `Height`, `ClearOnFocus` | `Submit(text)` |
| `Keybind` | `Default`, `Mode = "Toggle" \| "Hold" \| "Always"`, `Modes`, `Callback(state)`, `Pressed()`, `ChangedCallback(key)` | `GetKey`, `SetKey`, `SetMode`, `IsDown` |
| `ColorPicker` | `Default`, `Transparency` (enables alpha), `Rainbow`; callback gets `(color, transparency)` | `SetRainbow(bool)` |
| `Segmented` | `Values`, `Default` | |
| `Group` | `Opened`, `Icon` (holds elements itself) | `SetOpened(bool)` |
| `Label` | `Text`, `Value` (right aligned), `Color` (theme token), `Size` | `Set(text)`, `SetValue(text)` |
| `Paragraph` | `Title`, `Content` (rich text), `Icon` | `SetContent(text)` |
| `ProgressBar` | `Value`, `Max`, `Suffix`, `Format(v, max)`, `Color` | `SetMax` |
| `Divider` | `Text` | |
| `Spacer` | `Height` | |
| `Image` | `Image`, `Height` or `AspectRatio`, `Radius`, `ScaleType` | |
| `Code` | `Code`, `OnCopy()` | |

## Keybinds

Modules, toggles, buttons and keybind elements own a `Binding`:
`Binding.Key` (KeyCode name or `nil`), `Binding.Mode`, `Binding:SetKey(key)`, `Binding:SetMode(mode)`,
`Binding:Capture()`, `Binding.Changed`.
Keys are ignored while a text box has focus. Every bound key shows up in the keybind list overlay.

## Themes

```lua
OasisUI:SetTheme("Midnight")              -- Sapphire, Obsidian, Midnight, Ocean, Emerald, Amber, Crimson, Rose, Paper
OasisUI:SetAccent(Color3.fromRGB(255, 120, 60))
OasisUI.Theme.Set({ SurfaceTransparency = 0.5, Radius = 8, Font = "Montserrat" })
```

Colour tokens: `Accent`, `AccentAlt`, `Background`, `BackgroundAlt`, `Surface`, `SurfaceHover`, `Elevated`,
`ElevatedHover`, `Stroke`, `Divider`, `Text`, `TextDim`, `TextMuted`, `OnAccent`, `Success`, `Warning`, `Danger`.

Style tokens: `WindowTransparency`, `SurfaceTransparency`, `ElevatedTransparency`, `StrokeTransparency`,
`Radius`, `ElementRadius`, `Font`, `AnimSpeed` (0 turns animations off), `Gradient`, `GradientRotation`,
`AnimatedTitle`.

Everything the user changes in Settings is stored in `<Folder>/ui.json`, separate from configs.
`OasisUI.Theme.Export()` and `Theme.Import(data)` work with plain tables (colours as hex).

## Configs

```lua
local Config = Window.Config
Config:Save("pvp")          -- ok, nameOrError
Config:Load("pvp")
Config:Rename("pvp", "pvp main")
Config:Delete("pvp main")
Config:List()
Config:SetAutoload("pvp")   -- Config:GetAutoload()
Config.AutoSave = true      -- writes changes into the loaded config
Config:Export()             -- json text; Config:Import(text)
```

Only elements with a `Flag` are saved. Unknown flags in a file are ignored, so configs keep working when
features are added or removed.

## Library

`OasisUI:Notify({ Title, Content, Type = "Info" | "Success" | "Warning" | "Error", Icon, Duration, Buttons })`,
`OasisUI:GetFlag(flag)`, `OasisUI:SetFlag(flag, value)`, `OasisUI:AddIcons({ name = "rbxassetid://…" })`,
`OasisUI:Toggle()`, `OasisUI:Unload()`, `OasisUI:OnUnload(fn)`, `OasisUI.Flags`, `OasisUI.Version`.

Icons are a lucide subset (`src/Core/Icons.lua`). Add more names to `build/icon-names.txt` and run
`node build/icons.mjs <lucide-icons.lua>`.

## Development

```
src/
  init.lua              library entry (CreateWindow, Notify, Unload, …)
  Core/                 Services, Signal, Maid, Util, Theme, Icons, Storage, Config, Keybinds, Binding, Drag
  Themes/Presets.lua    colour palettes
  Components/           Window, Tab, Page (columns + drag), Module (card), Container (element mixin), Row,
                        Widgets (switch, checkbox, key pill), Popup, Menu, Tooltip, Dialog, Notification,
                        Overlays (keybind list, watermark, mobile button), Acrylic, Layer (screen guis)
  Elements/             one file per element, Base.lua is the shared model
  Addons/Settings.lua   the built-in Settings tab
build/
  bundle.mjs            src -> dist/OasisUI.lua
  icons.mjs             regenerates src/Core/Icons.lua
  harness.sh            bundle + showcase in one file for testing in an executor
dist/OasisUI.lua        the bundled library (generated, committed)
examples/Example.lua    showcase
```

Each source file is a chunk that starts with `local import = ...` and returns its module. `import("Core/Util")`
loads another file. The bundler wraps every file in a function and adds the `import` resolver.

```
npm run build                   # bundles src/ into dist/OasisUI.lua (needs Node 18+)
sh build/harness.sh out.lua     # library + showcase in one file, errors land in getgenv().OasisTestErr
```

Elements are models. `Render` builds a view that subscribes to `Changed` and `StateChanged`, so a module can have
several live views at once (its tab, Favorites, search results) that all follow the same state.

CI rebuilds the bundle on every push and fails when `dist/OasisUI.lua` is out of date, then compiles the bundle
and the showcase with `luau-compile`.

## Versioning and releases

OasisUI follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`. A major bump breaks the API,
a minor bump adds features, a patch fixes bugs. Every change is listed in [CHANGELOG.md](CHANGELOG.md).

To release:

1. Set `version` in `package.json` and add a `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md`.
2. `npm run build` and commit, including `dist/OasisUI.lua`.
3. Tag the commit `vx.y.z` and push the tag.

The release workflow checks that the tag matches `package.json` and that the bundle is current. It then publishes
a GitHub release with `OasisUI.lua` attached and the changelog section as notes.

## Notes

- Acrylic blur is off by default. It adds a `DepthOfFieldEffect` to Lighting and a glass part to the camera.
- Guis go to `gethui()` when the executor has it, otherwise to CoreGui, otherwise to PlayerGui.
- Without file functions (`writefile`, `readfile`, …) everything works, but nothing is saved.

## License

[MIT](LICENSE) © 2026 Mold53
