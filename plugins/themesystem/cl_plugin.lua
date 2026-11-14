local PLUGIN = PLUGIN

ix.theme = ix.theme or {}
ix.theme.themes = ix.theme.themes or {}

local theme = ix.theme
local requiredColors = {
	"panel", "panelBorder", "header", "button", "buttonHover", "buttonActive", "buttonBorder",
	"input", "inputBorder", "menu", "menuBorder", "overlay", "overlayStrong", "progress",
	"highlight", "gradientTop", "gradientBottom", "gradientLeft", "gradientRight", "tabBackdrop",
	"text", "textHover", "textMuted", "comboboxHoveredArrow"
}

function theme:Register(id, name, glass)
	assert(isstring(id) and id:find("%S"), "theme id must be a non-empty string")
	assert(isstring(name) and name:find("%S"), "theme name must be a non-empty string")
	assert(istable(glass), "theme palette must be a table")

	for _, key in ipairs(requiredColors) do
		assert(IsColor(glass[key]), "theme '" .. id .. "' requires a color for '" .. key .. "'")
	end

	self.themes[id] = {name = name, glass = glass}
end

local function makePalette(base, raised, hover, accent, text, muted, light)
	local border = ColorAlpha(accent, light and 135 or 90)

	return {
		panel = ColorAlpha(base, 205),
		panelBorder = border,
		header = ColorAlpha(raised, 225),
		button = ColorAlpha(raised, 200),
		buttonHover = ColorAlpha(hover, 225),
		buttonActive = ColorAlpha(accent, 220),
		buttonBorder = border,
		input = ColorAlpha(base, 225),
		inputBorder = border,
		menu = ColorAlpha(raised, 235),
		menuBorder = border,
		overlay = ColorAlpha(base, 100),
		overlayStrong = ColorAlpha(base, 165),
		progress = ColorAlpha(accent, 230),
		highlight = ColorAlpha(accent, 150),
		gradientTop = ColorAlpha(accent, 45),
		gradientBottom = ColorAlpha(base, 65),
		gradientLeft = ColorAlpha(accent, 30),
		gradientRight = ColorAlpha(accent, 30),
		tabBackdrop = ColorAlpha(base, 50),
		text = text,
		textHover = text,
		textMuted = muted,
		comboboxHoveredArrow = ColorAlpha(text, 220)
	}
end

theme:Register("dark", "Dark", makePalette(
	Color(20, 24, 30), Color(31, 37, 45), Color(48, 57, 70), Color(100, 145, 190),
	Color(235, 239, 245), Color(175, 185, 198)))
theme:Register("light", "Light", makePalette(
	Color(220, 226, 234), Color(205, 215, 228), Color(185, 200, 218), Color(70, 120, 175),
	Color(25, 30, 40), Color(80, 90, 105), true))
theme:Register("blue", "Blue", makePalette(
	Color(15, 23, 38), Color(22, 33, 52), Color(35, 51, 76), Color(80, 145, 220),
	Color(225, 238, 255), Color(160, 185, 215)))
theme:Register("purple", "Purple", makePalette(
	Color(25, 18, 35), Color(36, 27, 49), Color(53, 40, 70), Color(165, 110, 215),
	Color(240, 228, 255), Color(190, 170, 210)))
theme:Register("green", "Green", makePalette(
	Color(18, 29, 23), Color(26, 40, 32), Color(38, 57, 45), Color(95, 190, 130),
	Color(225, 245, 232), Color(165, 200, 178)))
theme:Register("red", "Red", makePalette(
	Color(32, 19, 22), Color(45, 28, 32), Color(65, 40, 46), Color(215, 100, 115),
	Color(250, 230, 233), Color(205, 170, 175)))
theme:Register("orange", "Orange", makePalette(
	Color(35, 24, 15), Color(48, 33, 21), Color(70, 47, 29), Color(225, 150, 75),
	Color(255, 237, 220), Color(220, 190, 160)))

function theme:GetThemeId()
	return ix.option.Get("themeSystemTheme", "dark")
end

local warnedTheme
function theme:Get(id)
	if (id != nil) then
		return assert(self.themes[id], "unknown theme '" .. tostring(id) .. "'")
	end

	id = self:GetThemeId()
	if (!self.themes[id]) then
		if (warnedTheme != id) then
			ErrorNoHalt("[Theme System] Unknown saved theme '" .. tostring(id) .. "'; using dark.\n")
			warnedTheme = id
		end
		return self.themes.dark
	end

	warnedTheme = nil
	return self.themes[id]
end

function theme:GetGlass()
	return self:Get().glass
end

function theme:GetMetrics()
	return {
		blur = ix.option.Get("themeSystemBlur", 1),
		roundness = ix.option.Get("themeSystemRoundness", 8),
		opacity = ix.option.Get("themeSystemOpacity", 1),
		borderOpacity = ix.option.Get("themeSystemBorderOpacity", 1),
		gradientOpacity = ix.option.Get("themeSystemGradientOpacity", 1)
	}
end

function theme:ScaleAlpha(color, scale)
	return Color(color.r, color.g, color.b, math.Clamp(color.a * scale, 0, 255))
end

-- Blur uses Helix's panel blur, which is rectangular even when the surface is rounded.
function theme:DrawGlassPanel(panel, x, y, width, height, options)
	options = options or {}
	local glass = self:GetGlass()
	local metrics = self:GetMetrics()
	local radius = options.radius
	if (radius == nil) then radius = metrics.roundness end
	local blur = options.blur
	if (blur == nil) then blur = 1 end
	local fill = options.fill or glass.panel
	local border = options.border or glass.panelBorder

	if (panel and blur > 0 and metrics.blur > 0) then
		ix.util.DrawBlur(panel, blur * metrics.blur * 5)
	end

	radius = math.max(0, math.min(radius, width * 0.5, height * 0.5))
	draw.RoundedBox(radius, x, y, width, height, self:ScaleAlpha(border, metrics.borderOpacity))
	if (width > 2 and height > 2) then
		draw.RoundedBox(math.max(radius - 1, 0), x + 1, y + 1, width - 2, height - 2,
			self:ScaleAlpha(fill, metrics.opacity))
	end
end

function theme:DrawGlassButton(panel, x, y, width, height, options)
	options = options or {}
	local glass = self:GetGlass()
	self:DrawGlassPanel(panel, x, y, width, height, {
		radius = options.radius,
		blur = options.blur or 0,
		fill = options.fill or glass.button,
		border = options.border or glass.buttonBorder
	})
end

function theme:DrawGlassBackdrop(panel, x, y, width, height, options)
	options = options or {}
	local glass = self:GetGlass()
	self:DrawGlassPanel(panel, x, y, width, height, {
		radius = options.radius or 0,
		blur = options.blur,
		fill = options.fill or glass.overlay,
		border = options.border or Color(0, 0, 0, 0)
	})
end

local gradients = {
	top = Material("vgui/gradient-d"),
	bottom = Material("vgui/gradient-u"),
	left = Material("vgui/gradient-r"),
	right = Material("vgui/gradient-l")
}

function theme:DrawGlassGradients(x, y, width, height)
	local glass = self:GetGlass()
	local opacity = self:GetMetrics().gradientOpacity
	for direction, material in pairs(gradients) do
		local key = "gradient" .. direction:sub(1, 1):upper() .. direction:sub(2)
		surface.SetMaterial(material)
		surface.SetDrawColor(self:ScaleAlpha(glass[key], opacity))
		surface.DrawTexturedRect(x, y, width, height)
	end
end

local helixSkin = derma.GetNamedSkin("helix")
local SKIN = table.Copy(helixSkin)
SKIN.Colours = table.Copy(helixSkin.Colours)
SKIN.Colours.Area = helixSkin.Colours.Area

local function updateSkin()
	local glass = theme:GetGlass()
	SKIN.Colours.Window.TitleActive = glass.text
	SKIN.Colours.Window.TitleInactive = glass.textMuted
	SKIN.Colours.Label.Default = glass.text
	SKIN.Colours.Label.Dark = glass.text
	SKIN.Colours.Label.Bright = glass.text
	SKIN.Colours.Button.Normal = glass.text
	SKIN.Colours.Button.Hover = glass.textHover
	SKIN.Colours.Button.Down = glass.textHover
	SKIN.Colours.Button.Disabled = glass.textMuted
	SKIN.Colours.Tab.Active.Normal = glass.text
	SKIN.Colours.Tab.Active.Hover = glass.textHover
	SKIN.Colours.Tab.Active.Down = glass.textHover
	SKIN.Colours.Tab.Inactive.Normal = glass.textMuted
	SKIN.Colours.Tab.Inactive.Hover = glass.textHover
	SKIN.Colours.Tab.Inactive.Down = glass.textHover
	SKIN.colTextEntryText = glass.text
	SKIN.colTextEntryTextPlaceholder = glass.textMuted
	SKIN.colTextEntryTextHighlight = glass.highlight
	SKIN.colTextEntryTextCursor = glass.text
	SKIN.colNumSliderNotch = glass.textMuted
	derma.RefreshSkins()

	for _, panel in ipairs(vgui.GetAll()) do
		if (IsValid(panel) and panel.ApplySchemeSettings and panel:GetSkin() == SKIN) then
			panel:ApplySchemeSettings()
		end
	end
end

ix.option.Add("themeSystemTheme", ix.type.array, "dark", {
	category = "appearance",
	populate = function()
		local choices = {}
		for id, definition in pairs(theme.themes) do
			choices[id] = definition.name
		end
		return choices
	end,
	OnChanged = updateSkin
})

local function addMetric(key, default, min, max, decimals)
	ix.option.Add(key, ix.type.number, default, {
		category = "appearance", min = min, max = max, decimals = decimals
	})
end

addMetric("themeSystemBlur", 1, 0, 2, 2)
addMetric("themeSystemRoundness", 8, 0, 24, 0)
addMetric("themeSystemOpacity", 1, 0.2, 1.5, 2)
addMetric("themeSystemBorderOpacity", 1, 0, 1.5, 2)
addMetric("themeSystemGradientOpacity", 1, 0, 1.5, 2)

function SKIN:PaintFrame(panel, width, height)
	local glass = theme:GetGlass()
	theme:DrawGlassPanel(panel, 0, 0, width, height, {blur = panel.bNoBackgroundBlur and 0 or 1})
	theme:DrawGlassGradients(1, 1, width - 2, height - 2)
	if (panel:GetTitle() != "" or panel.btnClose:IsVisible()) then
		draw.RoundedBoxEx(theme:GetMetrics().roundness, 1, 1, width - 2, 23,
			theme:ScaleAlpha(glass.header, theme:GetMetrics().opacity), true, true, false, false)
	end
end

function SKIN:PaintPanel(panel, width, height)
	if (panel.m_bBackground) then
		theme:DrawGlassPanel(nil, 0, 0, width, height, {blur = 0, fill = panel.m_bgColor})
	end
end

function SKIN:PaintButton(panel, width, height)
	if (!panel.m_bBackground) then return end
	local glass = theme:GetGlass()
	local fill = glass.button
	if (!panel:IsEnabled()) then
		fill = glass.panel
	elseif (panel.Depressed or panel:IsSelected() or panel:GetToggle()) then
		fill = glass.buttonActive
	elseif (panel.Hovered) then
		fill = glass.buttonHover
	end
	theme:DrawGlassButton(nil, 0, 0, width, height, {fill = fill})
end

function SKIN:PaintTextEntry(panel, width, height)
	local glass = theme:GetGlass()
	if (panel.m_bBackground) then
		theme:DrawGlassPanel(nil, 0, 0, width, height, {
			blur = 0, fill = glass.input, border = panel:HasFocus() and glass.progress or glass.inputBorder
		})
	end

	local placeholder = panel:GetPlaceholderText()
	panel:DrawTextEntryText(panel:GetTextColor(), panel:GetHighlightColor(), panel:GetCursorColor())
	if (placeholder and placeholder:Trim() != "" and panel:GetText() == "") then
		if (placeholder:StartsWith("#")) then placeholder = placeholder:sub(2) end
		draw.SimpleText(language.GetPhrase(placeholder), panel:GetFont(), 4, height * 0.5,
			panel:GetPlaceholderColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

function SKIN:PaintComboBox(panel, width, height)
	self:PaintButton(panel, width, height)
end

function SKIN:PaintComboDownArrow(panel, width, height)
	surface.SetFont("ixIconsSmall")
	local textWidth, textHeight = surface.GetTextSize("r")
	surface.SetTextColor(theme:GetGlass().text)
	surface.SetTextPos((width - textWidth) * 0.5, (height - textHeight) * 0.5)
	surface.DrawText("r")
end

function SKIN:PaintMenu(panel, width, height)
	local glass = theme:GetGlass()
	theme:DrawGlassPanel(panel, 0, 0, width, height, {fill = glass.menu, border = glass.menuBorder})
end

function SKIN:PaintMenuOption(panel, width, height)
	local glass = theme:GetGlass()
	if (panel.m_bBackground and panel:IsEnabled() and (panel.Hovered or panel.Highlight)) then
		theme:DrawGlassButton(nil, 0, 0, width, height, {fill = glass.buttonHover})
	end
	if (panel:GetChecked()) then
		draw.SimpleText(panel:GetRadio() and "o" or "x", "DermaDefault", 8, height * 0.5,
			panel:IsEnabled() and glass.text or glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function SKIN:PaintListView(panel, width, height)
	if (panel.m_bBackground) then
		theme:DrawGlassPanel(nil, 0, 0, width, height, {blur = 0})
	end
end

function SKIN:PaintListViewLine(panel, width, height)
	local glass = theme:GetGlass()
	local fill = panel:IsLineSelected() and glass.highlight or panel.Hovered and glass.buttonHover
		or panel.m_bAlt and glass.button
	if (fill) then
		surface.SetDrawColor(theme:ScaleAlpha(fill, theme:GetMetrics().opacity))
		surface.DrawRect(0, 0, width, height)
	end
end

function SKIN:PaintCheckBox(panel, width, height)
	local glass = theme:GetGlass()
	theme:DrawGlassButton(nil, 0, 0, width, height)
	if (panel:GetChecked()) then
		surface.SetDrawColor(panel:IsEnabled() and glass.progress or glass.textMuted)
		surface.DrawRect(3, 3, math.max(width - 6, 0), math.max(height - 6, 0))
	end
end

function SKIN:PaintProgress(panel, width, height)
	theme:DrawGlassPanel(nil, 0, 0, width, height, {blur = 0})
	surface.SetDrawColor(theme:GetGlass().progress)
	surface.DrawRect(1, 1, math.max(width - 2, 0) * math.Clamp(panel:GetFraction(), 0, 1), math.max(height - 2, 0))
end

derma.DefineSkin("ixUnified", "An opt-in glass theme for Helix.", SKIN)
updateSkin()

function PLUGIN:InitPostEntity()
	updateSkin()
end

concommand.Add("ix_theme_preview", function()
	local frame = vgui.Create("DFrame")
	frame:SetSkin("ixUnified")
	frame:SetSize(520, 440)
	frame:Center()
	frame:SetTitle("Theme System Preview")
	frame:MakePopup()

	local content = vgui.Create("DPanel", frame)
	content:Dock(FILL)
	content:DockPadding(10, 10, 10, 10)
	content:SetPaintBackground(false)

	local themes = vgui.Create("DComboBox", content)
	themes:Dock(TOP)
	themes:DockMargin(0, 0, 0, 6)
	for id, definition in SortedPairs(theme.themes) do
		themes:AddChoice(definition.name, id, id == theme:GetThemeId())
	end
	themes.OnSelect = function(_, _, _, id)
		ix.option.Set("themeSystemTheme", id)
	end

	local entry = vgui.Create("DTextEntry", content)
	entry:Dock(TOP)
	entry:DockMargin(0, 0, 0, 6)
	entry:SetPlaceholderText("Enter text...")

	local check = vgui.Create("DCheckBoxLabel", content)
	check:Dock(TOP)
	check:DockMargin(0, 0, 0, 6)
	check:SetText("Example checkbox")
	check:SetValue(true)

	local button = vgui.Create("DButton", content)
	button:Dock(TOP)
	button:DockMargin(0, 0, 0, 6)
	button:SetText("Example button")

	local list = vgui.Create("DListView", content)
	list:Dock(FILL)
	list:AddColumn("Name")
	list:AddColumn("Value")
	list:AddLine("First row", "One")
	list:AddLine("Second row", "Two")
end)
