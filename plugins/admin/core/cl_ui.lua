

ix.gui = ix.gui or {}

ix.admin.theme = ix.admin.theme or {}

local fallbackGlass = {
    button = Color(45, 50, 60, 220),
    buttonActive = Color(65, 90, 120, 235),
    buttonHover = Color(60, 68, 80, 235),
    progress = Color(110, 170, 230, 255)
}

function ix.admin.theme:GetGlass()
    local theme = ix.theme
    if ( istable(theme) and isfunction(theme.GetGlass) ) then
        return theme:GetGlass()
    end

    return fallbackGlass
end

function ix.admin.theme:GetMetrics()
    local theme = ix.theme
    if ( istable(theme) and isfunction(theme.GetMetrics) ) then
        return theme:GetMetrics()
    end

    return {
        opacity = 1,
        roundness = 8
    }
end

function ix.admin.theme:ApplySkin(panel)
    if ( IsValid(panel) and istable(ix.theme) and derma.GetNamedSkin("ixUnified") and isfunction(panel.SetSkin) ) then
        panel:SetSkin("ixUnified")
    end
end

function ix.admin.theme:ScaleAlpha(color, opacity)
    local theme = ix.theme
    if ( istable(theme) and isfunction(theme.ScaleAlpha) ) then
        return theme:ScaleAlpha(color, opacity)
    end

    local result = Color(color.r, color.g, color.b, color.a)
    result.a = math.Clamp(result.a * (tonumber(opacity) or 1), 0, 255)

    return result
end

function ix.admin.theme:DrawGlassPanel(panel, x, y, width, height, options)
    options = istable(options) and options or {}
    local theme = ix.theme
    if ( istable(theme) and isfunction(theme.DrawGlassPanel) ) then
        return theme:DrawGlassPanel(panel, x, y, width, height, options)
    end

    local color = options.fill or Color(35, 40, 48, 220)
    local radius = options.radius
    if ( radius == nil ) then
        radius = self:GetMetrics().roundness
    end

    draw.RoundedBox(radius or 0, x, y, width, height, color)
end
