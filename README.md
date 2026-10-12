# OasisUI

[![Release](https://img.shields.io/github/v/release/Mold53/OasisUI?label=release&color=4e84ff)](https://github.com/Mold53/OasisUI/releases/latest)
[![CI](https://github.com/Mold53/OasisUI/actions/workflows/ci.yml/badge.svg)](https://github.com/Mold53/OasisUI/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/Mold53/OasisUI?color=4e84ff)](LICENSE)

OasisUI is a Roblox UI library for executor scripts, built for large hubs: module cards with a switch and a
key pill whose settings fold out below, two scrolling columns per tab with drag-to-rearrange cards, sub-tabs,
favorites, global search, floating panels, a live theme editor, a config manager and overlays.

## Showcase

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mold53/OasisUI/main/examples/Example.lua"))()
```

The showcase ([examples/Example.lua](examples/Example.lua)) is a mock script hub (aimbot, ESP, player and
world features as dummies) plus a tab for every element group with each option. It does not change anything
in the game.

## Installation

Pin a version for scripts you ship. The release file never changes after it is published:

```lua
local OasisUI = loadstring(game:HttpGet("https://github.com/Mold53/OasisUI/releases/download/v1.4.0/OasisUI.lua"))()
```

| Source | URL |
| --- | --- |
| Pinned release | `https://github.com/Mold53/OasisUI/releases/download/v1.4.0/OasisUI.lua` |
| Latest release | `https://github.com/Mold53/OasisUI/releases/latest/download/OasisUI.lua` |
| Development (`main`) | `https://raw.githubusercontent.com/Mold53/OasisUI/main/dist/OasisUI.lua` |

`OasisUI.Version` holds the loaded version (`"1.4.0"`).

## Quick start

```lua
local OasisUI = loadstring(game:HttpGet("https://github.com/Mold53/OasisUI/releases/download/v1.4.0/OasisUI.lua"))()

local Window = OasisUI:CreateWindow({ Title = "Oasis", Subtitle = "Universal", Folder = "Oasis" })
local Combat = Window:Tab({ Title = "Combat", Icon = "crosshair" })

local Aimbot = Combat:Module({
    Title = "Aimbot",
    Description = "Locks onto the closest target while you hold the key.",
    Flag = "Aimbot",
    Keybind = { Key = "MouseButton2", Mode = "Hold" },
    Callback = function(enabled) end,
})
Aimbot:Slider({ Title = "FOV", Min = 10, Max = 500, Default = 120, Suffix = " px", Flag = "AimFov" })
```

## Features

- **Module cards**: title, description, key pill, switch. Settings fold out when the module is enabled
  (configurable) or with the chevron. Right-click a header for its menu, middle-click to bind a key.
  `Risky = true` marks dangerous features with a red title.
- **Layouts**: two independent scrolling columns per tab, or one (`Columns = 1`). Tabs can be split into
  **sub-tabs** with their own pages. Drag a card by its grip to reorder it or move it to the other column;
  the layout is saved per page.
- **Favorites**: the star on a card pins it to the Favorites page. Cards there are live mirrors of the
  originals, and that page can be rearranged too.
- **Search** across every tab and sub-tab (Ctrl+F, or `SearchShortcut = false`). Matching cards are shown with their tab name, cards
  that only match through a child element open automatically, and matching rows are highlighted.
- **Keybinds** as pills on cards and rows. Click a pill and press a key, right-click it to choose Toggle, Hold
  or Always. **Combos** such as `LCtrl + L`: hold Ctrl, Shift or Alt (left or right) while binding and the
  next key completes the bind; let go and the modifier alone is the key. `ComboKeys` sets how many keys a
  bind may have (1 turns combos off), globally, per window and per bind. A press fires the most specific
  match, so `LCtrl + L` does not also fire a plain `L`. `Listed = false` keeps a bind out of the keybind
  list. Mouse buttons 2 and 3 and gamepad buttons work. What clicking outside or Escape does while binding
  (keep or clear), whether mouse buttons are allowed, blacklisted keys and unclearable keys are all
  configurable, globally and per bind.
- **Elements**: Toggle and Checkbox (both can have a key and a value box in the same row), Button (styles,
  confirm, key), ButtonRow,
  Slider and RangeSlider, Dropdown (single or multi, search, descriptions, icons, refresh), Input (text or
  number, validation, multiline), Keybind, ColorPicker (HSV, alpha, hex, RGB, rainbow, copy/paste),
  Segmented, Group (collapsible sub-list), Label (with a live, coloured value), Paragraph, Divider, Spacer,
  ProgressBar, Image, Code (a short preview; a click opens the whole text, optionally editable) and Log
  (scrolling list of lines).
  - **Slider extras**: the value is editable in the title line, `−`/`+` steppers, `From`/`To` icons, and
    min/max labels.
- **Element states**: every element supports `Locked` (with a reason tooltip), `Visible`, and
  `DependsOn(otherElement)`.
- **Panels**: small floating windows that hold any element. They can be dragged, collapsed, resized and
  closed, and remember their position. HUD panels stay visible while the menu is hidden and size themselves
  to their content; scale and transparency are adjustable per panel.
- **Theme editor** in the Settings tab: presets, nine colours, window, card and field transparency,
  corner radius, font, screen fit and scale, animation speed, background gradient, animated title,
  background blur, compact sidebar and card descriptions. Themes can be saved, loaded, exported and imported.
  Tooltips can be turned off in Behaviour.
- **Config manager**: save, load, rename, delete, autoload, auto save, and export/import through the
  clipboard. Keybinds are stored in the config too.
- **Keybind list overlay** with its own settings: all or active binds, sort order, grouping by mode, column
  layout (name, key and mode in any order), mode text (full, short or hidden), key style, size, width,
  transparency, title bar, menu key, hide while the menu is open.
- **Other overlays**: watermark (title, custom text, FPS, ping, time, name), notifications (four types,
  buttons with hover and press feedback, pause on hover), dialogs with an optional text input (Enter
  submits), context menus, tooltips.
- **Window**: drag, resize, minimize to a title pill, hide with the menu key, fit to small screens, and a
  menu button on touch devices. Profile card with custom name, subtitle and avatar, or hidden; streamer
  mode. The menu remembers its position, size, last tab and sub-tab.
- **Touch screens**: drags hold the scroll area still and end cleanly when the system cancels a touch,
  tooltips show on a tap of the info icon or a locked control, a long press opens the menus that right-click
  opens with a mouse, stars and grips stay visible without hover, and the window keeps its text readable on
  phones by shrinking instead of scaling down.
- **Re-running a script** unloads the previous instance (same `GuiName`).

## Window

```lua
local Window = OasisUI:CreateWindow({
    Title = "Oasis",                      -- animated accent gradient unless disabled in the theme
    Subtitle = "Universal",
    Icon = "sparkles",                    -- lucide name, rbxassetid://…, rbxthumb://… or a number
    Folder = "Oasis",                     -- <Folder>/configs, <Folder>/themes, <Folder>/ui.json
    Size = UDim2.fromOffset(780, 520),
    MinSize = Vector2.new(560, 380),
    SidebarWidth = 164,
    Theme = "Sapphire",                   -- used until the user picks something else
    ThemeOverrides = { Accent = Color3.fromRGB(255, 120, 60) },
    Tags = { "beta", { Text = "v1.2", Color = Color3.fromRGB(70, 200, 120) } },
    ToggleKey = Enum.KeyCode.RightShift,
    Search = true,
    SearchShortcut = true,                -- false: the bar stays, Ctrl+F is not taken
    ComboKeys = 3,                        -- keys per bind until the user changes it in Settings
    Resizable = true,
    Draggable = true,
    Minimizable = true,
    CloseAction = "Hide",                 -- "Hide" | "Unload" | "Confirm" (asks before unloading)
    User = { Name = nil, Subtitle = nil, Avatar = nil, Callback = nil },  -- false hides the profile card
    Settings = true,                      -- built-in Settings tab
    AutoLoad = true,                      -- loads the autoload config after the script finished building
    GuiName = "OasisUI",
})
```

| Method | |
| --- | --- |
| `Window:Tab(def)` | new tab (`Title`, `Icon`, `Columns = 1 \| 2`, `Id`, `Draggable`, `Empty`) |
| `Window:TabSection(text)` / `Window:Divider()` | caption or line in the sidebar |
| `Window:SelectTab(tab \| subTab \| index \| title, focusModule?)` / `Window:SelectFavorites()` | |
| `Window:Panel(def)` | floating panel (below) |
| `Window:Dialog({ Title, Content, Icon, Width, Input = { Default, Placeholder, Multiline, Height, Monospace, ReadOnly }, Buttons = { { Title, Style, Callback(text, dialog) } } })` | return `false` from a callback to keep it open; `dialog:SetError(text)`; a multiline input scrolls |
| `Window:Menu(items, { Title, Anchor, Width })` | context menu; items `{ Title, Icon, Callback, Checked, Danger, Disabled, Hint }` or `"-"` |
| `Window:Notify(options)` | same as `OasisUI:Notify` |
| `Window:SetVisible(bool)`, `:Toggle()`, `:SetMinimized(bool)`, `:SetCompact(bool)` | |
| `Window:SetFitScreen(bool)`, `:SetScale(n)` | the fit scales with the resolution (1080p = 1) and keeps the window on screen; `SetScale` is a multiplier on top (1 = 100 %) |
| `Window:SetBlur("Off" \| "Screen" \| "Window")` | background blur, see Notes |
| `Window:SetSize(UDim2 \| Vector2)`, `:Center()` | |
| `Window:SetTitle(text)`, `:SetSubtitle(text)`, `:SetUser(def \| false)` | |
| `Window:SetWatermark(text \| fn)` | extra watermark text after the title; a function is called twice a second |
| `Window:Modules()` | every module of every tab and sub-tab |
| `Window:LoadAutoload()` | call it yourself if your script yields before the UI is complete |
| `Window.Config` | config manager (below) |

## Tabs, sub-tabs, modules, sections

```lua
local Tab = Window:Tab({ Title = "Combat", Icon = "crosshair" })

local Aimbot = Tab:SubTab({ Title = "Aimbot", Icon = "target" })   -- optional; a chip bar appears above the page

local Module = Aimbot:Module({
    Title = "Aimbot",
    Description = "…",
    Icon = "target",                      -- optional, shown before the title
    Flag = "Aimbot",                      -- saves enabled state + key
    Default = false,
    Keybind = { Key = "MouseButton2", Mode = "Hold" },  -- false hides the pill
    Risky = false,                        -- red title
    Side = "Left",                        -- first placement; the user's layout wins afterwards
    Opened = nil,                         -- force the settings open/closed initially
    Callback = function(enabled) end,
})

local Section = Aimbot:Section({ Title = "Info", Icon = "info", Side = "Right" })  -- no switch, open by default
```

Sub-tabs have the same `Module` / `Section` API as tabs. Modules added straight to a tab that later gets
sub-tabs move into a first sub-tab named `MainTitle` (default "General"). `Tab:SetVisible(bool)` hides a tab
or sub-tab without removing it.

Module methods: `Get()`, `Set(bool)`, `SetEnabled(bool)`, `ToggleEnabled()`, `OnChanged(fn)`,
`SetExpanded(bool)`, `SetFavorite(bool)`, `SetLocked(bool)`, `SetVisible(bool)`, `SetTitle`,
`SetDescription`, `Reset()` (module and all of its elements), `Destroy()`, `Binding` (see Keybinds).

Modules, sections, groups and panels take elements with `Module:Toggle({...})` or `Module:AddToggle({...})`.
The Fluent style `Module:AddToggle("Flag", {...})` works as well.

## Elements

Shared options: `Title`, `Description`, `Tooltip`, `Flag` (saved in configs, reachable through
`OasisUI.Flags[flag]`), `Callback`, `Locked`, `LockedReason`, `Visible`, `Risky`.
Shared methods: `Get()`, `Set(value, silent?)`, `Reset()`, `OnChanged(fn)`, `SetTitle`, `SetDescription`,
`SetLocked(bool, reason?)`, `SetVisible(bool)`, `DependsOn(element, predicate?, "Lock" | "Hide")`, `Destroy()`.

| Element | Options | Extra methods |
| --- | --- | --- |
| `Toggle` / `Checkbox` | `Default`, `Style = "Switch" \| "Checkbox"`, `Keybind = true \| key \| { Key, Mode, Modes, … }`, `Listed`, `Field = { Input options, Width }` (a value box in the row, settable while off, with its own `Flag`) | `Binding`, `Field` (the value box, an Input) |
| `Button` | `Icon`, `Style = "Default" \| "Primary" \| "Danger" \| "Ghost"`, `Confirm = true \| text`, `Keybind` | `Press()` |
| `Buttons` | list of `{ Title, Icon, Style, Confirm, Callback }` | `SetButtonTitle(i, text)`, `SetButtonLocked(i, bool)` |
| `Slider` | `Min`, `Max`, `Default`, `Step` or `Rounding`, `Prefix`, `Suffix`, `Format(v)`, `Input` (editable value, default on), `Buttons` (−/+), `Icons = { From, To }`, `ShowRange`, `Live` (default on) | `SetMin`, `SetMax` |
| `Range` | as Slider, `Default = { lo, hi }`, `MinGap`; callback gets `(lo, hi)` | |
| `Dropdown` | `Values` (strings or `{ Title, Value, Description, Icon }`), `Default`, `Multi`, `Search` (auto above 8), `AllowNone`, `Placeholder`, `MaxVisible`, `Action = { Icon, Tooltip, Callback(value) }` (a square button after the field) | `Refresh(values, keep?)`, `Add`, `Remove`, `Toggle(value)`, `IsSelected`, `GetValues` |
| `Input` | `Default`, `Placeholder`, `Numeric`, `Min`, `Max`, `Step`, `MaxLength`, `Finished` (default on), `Validate(text) -> ok, message`, `Icon`, `Multiline`, `Height`, `ClearOnFocus` | `Submit(text)` |
| `Keybind` | `Default`, `Mode = "Toggle" \| "Hold" \| "Always"`, `Modes`, `Listed`, capture options (below), `Callback(state)`, `Pressed()`, `ChangedCallback(key)` | `GetKey`, `SetKey`, `SetMode`, `IsDown` |
| `ColorPicker` | `Default`, `Transparency` (enables alpha), `Rainbow`; callback gets `(color, transparency)` | `SetRainbow(bool)` |
| `Segmented` | `Values`, `Default` | |
| `Group` | `Opened`, `Icon` (holds elements itself) | `SetOpened(bool)` |
| `Label` | `Text`, `Value` (right aligned), `Color` (theme token), `ValueColor` (token or Color3), `Size` | `Set(text)`, `SetValue(text)`, `SetValueColor(color)` |
| `Paragraph` | `Title`, `Content` (rich text), `Icon` | `SetContent(text)` |
| `ProgressBar` | `Value`, `Max`, `Suffix`, `Format(v, max)`, `Color` | `SetMax` |
| `Log` | `Height` (default 140), `MaxLines`, `Monospace`, `Timestamps`, `AutoScroll` | `Add(text, colorToken?)`, `Clear()`, `Set(lines)` |
| `Divider` | `Text` | |
| `Spacer` | `Height` | |
| `Image` | `Image`, `Height` or `AspectRatio`, `Radius`, `ScaleType` | |
| `Code` | `Code`, `Lines` (preview, default 6), `Editable`, `OnSave(text) -> ok, message` (`false` keeps the editor open), `OnCopy()` | `Open()` |

## Panels

```lua
local Panel = Window:Panel({
    Title = "Quick panel",
    Icon = "zap",
    Id = "quick",                         -- the saved position is keyed by this
    Size = Vector2.new(260, 320),
    Position = nil,                       -- default: next to the window
    Closable = true,
    Collapsible = true,
    Resizable = false,
    Hud = false,                          -- true: stays visible while the menu is hidden
    AutoSize = nil,                       -- height follows the content, no scrolling (default: on for Hud panels)
    Scale = 1,                            -- 1 = 100 %; Hud panels use it alone, others on top of the window scale
    Transparency = nil,                   -- 0-1 background, nil = from the theme
    OnClose = nil,                        -- the user closed it with its x
})
Panel:Toggle({ Title = "Option" })
Panel:Show(); Panel:Hide(); Panel:ToggleVisible(); Panel:SetCollapsed(true); Panel:SetTitle("…"); Panel:Destroy()
Panel:SetScale(1.25); Panel:SetTransparency(0.4); Panel.Closed:Connect(fn)
```

## Keybinds

Modules, toggles, buttons and keybind elements own a `Binding`:
`Binding.Key` (KeyCode name or `nil`), `Binding.Mode`, `Binding:SetKey(key)`, `Binding:SetMode(mode)`,
`Binding:Capture()`, `Binding.Changed`.
Keys are ignored while a text box has focus. Every bound key shows up in the keybind list overlay.

Capture options, per bind (`Keybind = { … }` on toggles, modules and buttons, or directly on a Keybind element):

| Option | |
| --- | --- |
| `ClickOutside = "Keep" \| "Clear"` | clicking elsewhere while binding keeps the old key or removes it |
| `Escape = "Keep" \| "Clear"` | the same for Escape |
| `AllowMouse = false` | right and middle mouse button cannot be bound |
| `Blacklist = { "W", Enum.KeyCode.A, … }` | keys that are ignored while binding |
| `CanUnbind = false` | the bind always keeps a key; Backspace and "Clear key" do nothing |
| `ComboKeys = n` | keys per bind, e.g. 2 allows `LCtrl + L` and `LCtrl + LShift`; at n keys the bind ends |

Combo keys are stored as `"LeftControl+L"` (`Binding.Key`), shown as `LCtrl + L`.

The global defaults for `ClickOutside`, `Escape`, mouse buttons and combo keys live in Settings → Behaviour.

## Themes

```lua
OasisUI:SetTheme("Midnight")              -- Sapphire, Obsidian, Midnight, Ocean, Emerald, Amber, Crimson, Rose, Paper
OasisUI:SetAccent(Color3.fromRGB(255, 120, 60))
OasisUI.Theme.Set({ SurfaceTransparency = 0.5, Radius = 8, Font = "Nunito" })
```

Colour tokens: `Accent`, `AccentAlt`, `Background`, `BackgroundAlt`, `Surface`, `SurfaceHover`, `Elevated`,
`ElevatedHover`, `Stroke`, `Divider`, `Text`, `TextDim`, `TextMuted`, `OnAccent`, `Success`, `Warning`, `Danger`.

Style tokens: `WindowTransparency`, `SurfaceTransparency`, `ElevatedTransparency`, `StrokeTransparency`,
`Radius`, `ElementRadius`, `Font`, `AnimSpeed` (0 turns animations off), `Gradient`, `GradientRotation`,
`AnimatedTitle`.

`Font` takes a Roblox font family name. The Settings list offers the families that render differently:
Ubuntu (default), Montserrat, BuilderSans, Nunito, Roboto, SourceSansPro, Arimo, JosefinSans, TitilliumWeb,
Oswald, Jura, Zekton, Michroma, Merriweather, FredokaOne, RobotoMono. `GothamSSm` draws Montserrat and
`Arial` draws Arimo, so they are not listed.

Everything the user changes in Settings (theme, layout, favorites, overlays, behaviour) is stored in
`<Folder>/ui.json`, separate from configs. `OasisUI.Theme.Export()` and `Theme.Import(data)` work with
plain tables (colours as hex).

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

`OasisUI:Notify({ Title, Content, Type = "Info" | "Success" | "Warning" | "Error", Icon, Duration, Buttons = { { Title, Style, Callback, KeepOpen } } })`,
`OasisUI:GetFlag(flag)`, `OasisUI:SetFlag(flag, value)`, `OasisUI:AddIcons({ name = "rbxassetid://…" })`,
`OasisUI:SetTheme(name)`, `OasisUI:SetAccent(color)`, `OasisUI:Toggle()`, `OasisUI:Unload()` (alias `Destroy`),
`OasisUI:OnUnload(fn)`, `OasisUI.Flags`, `OasisUI.Version`.

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
                        Overlays (keybind list, watermark, mobile button), Panel, Acrylic (background blur),
                        Layer (screen guis)
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

- Background blur is off by default. `Screen` adds a `BlurEffect` to Lighting while the menu is open and works
  on every graphics level. `Window` blurs only what is behind the window with a glass part in front of the
  camera and a `DepthOfFieldEffect`. Roblox draws glass from graphics quality 8 up, and a
  `DFIntDebugFRMQualityLevelOverride` FFlag set by a bootstrapper overrides the menu level. The game's own
  depth of field effects are switched off while it shows and restored afterwards.
- Guis go to `gethui()` when the executor has it, otherwise to CoreGui, otherwise to PlayerGui.
- Without file functions (`writefile`, `readfile`, …) everything works, but nothing is saved.

## License

[MIT](LICENSE) © 2026 Mold53
