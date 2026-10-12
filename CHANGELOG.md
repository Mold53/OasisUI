# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-12

### Added

- Sub-tabs: `Tab:SubTab({ Title, Icon })` adds a chip bar with one page per sub-tab; the last sub-tab is
  remembered, and search, favorites and "Open in" work across sub-tabs.
- Floating panels: `Window:Panel(def)` holds any element and can be dragged, collapsed, resized and closed;
  HUD panels stay visible while the menu is hidden. New panels open next to the window.
- Keybind list settings: all or active binds, sort order, grouping by mode, column layout, mode text (full,
  short, hidden), key style, size, width, transparency, title bar, menu key, hide while the menu is open,
  reset position. Hold and Always binds light up while their key is down.
- Keybind capture options: `ClickOutside` and `Escape` (`"Keep"` or `"Clear"`), `AllowMouse`, `Blacklist`
  and `CanUnbind`, per bind and as global defaults in Settings → Behaviour.
- Watermark settings (title, frame rate, ping, time, display name, custom text, size) and
  `Window:SetWatermark(text | fn)`.
- Profile card options: `User = { Name, Subtitle, Avatar, Callback }` or `false`, `Window:SetUser`, and
  Settings toggles for the card, the avatar and a streamer mode.
- Window options `SidebarWidth`, `Resizable`, `Draggable`, `Minimizable` and `CloseAction`
  (`"Hide"`, `"Unload"` or `"Confirm"`), plus `Window:SetSize`, `Window:Center`, `Window:Menu`,
  `Window:Modules`.
- `Risky = true` for modules and elements (red title).
- `Log` element: a scrolling list of lines with its own height, optional timestamps and monospace text.
- `Tab:SetVisible`, `Window:SelectTab` by title, `OasisUI:Destroy` as an alias of `Unload`.
- Hover and press feedback on notification, dialog, panel and topbar buttons; notification buttons take a
  `Style` and `KeepOpen`. Enter in a dialog's text field presses its primary button.

### Changed

- The showcase is now a game-independent mock hub (aimbot, silent aim, triggerbot, FOV circle, hitbox, ESP,
  chams, world, crosshair, movement, server tools) with sub-tabs, an event log and a Layouts tab for panels
  and context menus.
- Settings are split into Appearance, Themes, Behaviour, Configs, Menu and Overlays.

### Fixed

- Hovering a sidebar entry outside compact mode raised "Unable to assign property Text. string expected,
  got function": a tooltip callback that returned nothing fell back to the function itself.

## [1.0.0] - 2026-10-12

First public release.

### Added

- Window with a topbar (animated title gradient, tags, global search, minimize, hide), a sidebar (favorites
  with a counter, tab captions, pinned Settings tab, user card, compact mode), resizing, dragging, fit-to-screen
  scaling and a menu button on touch devices.
- Module cards in the Sapphire layout: switch, key pill, star, drag grip, settings that fold out, a context
  menu, middle-click binding and a lock. Sections are cards without a switch.
- Two scrolling columns per tab with drag and drop between them; the layout is saved per tab.
- Favorites page with live mirrors of the pinned modules.
- Search across every tab with highlighted matches.
- Elements: Toggle, Checkbox, Button, ButtonRow, Slider, RangeSlider, Dropdown (single, multi, search,
  icons, descriptions), Input (text, numbers, validation, multiline), Keybind (Toggle, Hold, Always),
  ColorPicker (HSV, alpha, hex, RGB, rainbow), Segmented, Group, Label, Paragraph, Divider, Spacer,
  ProgressBar, Image, Code.
- Locked and hidden states for every element, `DependsOn` for conditional options.
- Theme engine with nine presets and live editing of colours, transparency, corner radius, font, scale,
  animation speed, background gradient and acrylic blur; themes can be saved, exported and imported.
- Config manager: save, load, rename, delete, autoload, auto save, clipboard export and import.
- Keybind list and watermark overlays, notifications, dialogs with text input, tooltips.
- Settings tab built from the library's own elements.
- Build tooling: `build/bundle.mjs`, `build/icons.mjs`, `build/harness.sh`, CI and release workflows.

[1.1.0]: https://github.com/Mold53/OasisUI/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Mold53/OasisUI/releases/tag/v1.0.0
