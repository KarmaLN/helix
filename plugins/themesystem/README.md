# Theme System

This client-side Helix plugin provides selectable glass-inspired themes for
panels that opt into the `ixUnified` Derma skin. It does not replace Helix's
global skin or automatically restyle panels with their own paint functions.

Enable the plugin, then run `ix_theme_preview` to see and select a theme.
The Appearance options also offer dark, light, blue, purple, green, red and
orange palettes, plus blur, roundness, surface opacity, border opacity and
gradient opacity. These settings are saved per client.

```lua
local frame = vgui.Create("DFrame")
frame:SetSkin("ixUnified")
frame:SetSize(500, 400)
frame:Center()
frame:SetTitle("My menu")
frame:MakePopup()

local button = vgui.Create("DButton", frame)
button:Dock(TOP)
button:SetText("Hello")
```

Children inherit the skin; popup menus may need the skin set explicitly if
they are not parented to the themed panel. Frames, panels, buttons, text
entries, combo boxes, menus, list views, checkboxes and progress bars have
theme-aware painting. Other controls use the inherited Helix skin.

Custom panels can use `ix.theme:GetGlass()`, `ix.theme:GetMetrics()`,
`ix.theme:ScaleAlpha(color, multiplier)`, `ix.theme:DrawGlassPanel(panel, x,
y, width, height, options)`, `ix.theme:DrawGlassButton(...)`,
`ix.theme:DrawGlassBackdrop(...)`, and `ix.theme:DrawGlassGradients(x, y,
width, height)` in their paint functions.
Read colors at paint time so changes apply immediately. Panel, button and
backdrop options accept `fill`, `border`, `radius`, and `blur`; pass the
panel for background blur or `nil` to omit it. Blur covers the entire panel
using Helix's rectangular blur, even when the colored surface is rounded.

To register another theme after this plugin loads, call
`ix.theme:Register(id, displayName, palette)`. The palette must contain all
the color keys returned by `ix.theme:GetGlass()`; copy an existing palette
with `table.Copy` and change its colors. Register custom themes before opening
the options menu so they appear in its selector.
