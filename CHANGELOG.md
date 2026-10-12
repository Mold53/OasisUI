# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-10-12

### Added

- Toggle `Field`: a value box in the toggle's own row, settable while the toggle is off, with its own `Flag`,
  validation and number shorthand (`toggle.Field` is an Input).
- Code: a preview of `Lines` lines (default 6) with a "+ n more lines" hint; a click opens the whole text in a
  scrolling dialog with Copy. `Editable = true` turns it into an editor whose Save runs `OnSave(text)` first
  (`false, message` keeps it open and shows the message). `Code:Open()`.
- Dialog input options `Multiline`, `Height`, `Monospace` and `ReadOnly`; a multiline input scrolls. Dialogs are
  never wider or taller than their window.
- Panels: `AutoSize` (the height follows the content, no scroll area; default for Hud panels), `Scale` and
  `Panel:SetScale(n)`, `Transparency` and `Panel:SetTransparency(n)`, `OnClose` and `Panel.Closed` for a close
  by its x.
- Label `ValueColor` and `Label:SetValueColor(color)` (theme token or Color3).
- `Listed = false` on modules, toggles and keybinds keeps a bind out of the keybind list.
- Range errors of number inputs use short numbers (`0 – 1000b`).
- Touch screens:
  - Tooltips show on a tap of an info icon or a locked control, at the finger, and hide after a moment or with
    the next touch.
  - A long press on a module header or a key pill opens the menu that right-click opens with a mouse.
  - Stars and drag grips on cards stay faintly visible, there is no hover to reveal them.
  - The window keeps its text readable on phones: it shrinks to the screen (down to `MinSize`) instead of
    scaling down with the resolution.
  - Dropdown search and dialogs no longer pop up the keyboard by themselves.

### Changed

- The default font is Ubuntu. Montserrat set letter pairs such as "as" too tight at small sizes; it stays in
  the font list.

### Fixed

- Chevrons never turned: Roblox does not render `Rotation` inside clipping frames, so an open card, group or
  dropdown still showed a down arrow. Open cards and dropdowns now show an up arrow, groups a down arrow.
  The resize grips are drawn without rotation for the same reason.
- A card whose content changed size while it unfolded (wrapped text, code) stayed cut off at the height it had
  when the animation started.
- The first control of a section lost the top edge of its outline.
- Touch: a drag the system cancelled (a scroll area taking the touch over) never ended and dragged its element
  along with the next touch. Drags now end on cancel, and scroll areas hold still while a slider, colour
  picker or card is dragged by touch.
- Touch: hover highlights stayed on after a tap; they end when the touch lifts.
- Card drag autoscroll followed the mouse position instead of the dragging finger.

## [1.2.2] - 2026-10-12

### Fixed

- The mouse wheel did not scroll any page after starting on a tab with sub-tabs (the first tab, or the tab
  remembered from the last run). That tab's own page stayed visible on top of every page once its sub-tabs
  took over, and its empty columns took the mouse wheel. It is hidden now.

## [1.2.1] - 2026-10-12

### Fixed

- Resizing drifted: the window grew around its centre, so the corner ran away from the pointer. The top-left
  corner now stays put and the grip stays under the pointer at every interface scale.
- The outline of the first sub-tab chip was cut off on the left.
- Window blur only made the window more see-through without blurring anything:
  - The game's own depth of field effects overrode it. They are switched off while Window blur is shown and
    restored afterwards.
  - The window only gets more see-through while the blur actually renders.
  - The graphics check also reads the `DFIntDebugFRMQualityLevelOverride` FFlag that bootstrappers set,
    since it overrides the Roblox menu.
  - Settings shows why Window blur cannot render: graphics quality below 8 or that FFlag.

## [1.2.0] - 2026-10-12

### Added

- `Window:SetBlur("Off" | "Screen" | "Window")` and `Window:SetFitScreen(bool)`.

### Changed

- "Acrylic blur" is now "Background blur" with three modes: Off, Screen (a BlurEffect while the menu is open,
  works on every graphics level) and Window (glass behind the window, needs graphics quality 8+; Settings
  warns when it cannot render). A strength slider controls the Screen blur, and Window mode keeps the window
  background see-through enough to show the glass.
- "Fit to screen" scales with the resolution (1080p = 100 %) and keeps the window on screen.
  "Interface scale" is a multiplier on top of it and is never locked. `Window:SetScale(n)` sets that multiplier.
- The font list holds 16 families that render differently, with readable names; the default font is
  Montserrat.
- Documentation and comments no longer refer to other UI libraries.

### Fixed

- The keybind list, the watermark and the mobile button reopened far above their saved spot after
  re-running a script, so the keybind list could vanish off screen: only the pixel part of their position
  was saved. Positions are now stored as absolute pixels and kept on screen, also after a resolution
  change. The window is pulled back on screen the same way.
- Choosing GothamSSm or Montserrat looked identical (Roblox draws Gotham as Montserrat).
- Tooltips of controls under an open dropdown or menu no longer appear or stick to the mouse.
- Scroll areas are sized from the real content height instead of AutomaticCanvasSize, and guis left behind
  by an earlier run with the same name are removed on start.

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
- Module cards: switch, key pill, star, drag grip, settings that fold out, a context
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

[1.3.0]: https://github.com/Mold53/OasisUI/compare/v1.2.2...v1.3.0
[1.2.2]: https://github.com/Mold53/OasisUI/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/Mold53/OasisUI/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/Mold53/OasisUI/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Mold53/OasisUI/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Mold53/OasisUI/releases/tag/v1.0.0
