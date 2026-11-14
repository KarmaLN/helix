local PLUGIN = PLUGIN or {}

function PLUGIN:LoadFonts()
    surface.CreateFont("ixAdminSmall", {
        font = "Courier New",
        size = 11,
        weight = 500
    })
    surface.CreateFont("ixAdminRegular", {
        font = "Courier New",
        size = 13,
        weight = 500
    })
    surface.CreateFont("ixAdminRegularBold", {
        font = "Courier New",
        size = 13,
        weight = 800
    })
    surface.CreateFont("ixAdminHugeBold", {
        font = "Courier New",
        size = 21,
        weight = 800
    })
end

function PLUGIN:HUDPaint()
    local client = LocalPlayer()
    if ( !ix.util.IsValidPlayer(client) or !ix.admin:CanAccessPrivilege(client, "Helix - Observer") ) then return end

    if ( !ix.option.Get("admin.esp") ) then return end
    if ( client:InVehicle() or !client:InNoclip() ) then return end

    self:DrawItems()
    self:DrawPlayers()
    self:DrawEntities()

    hook.Run("HUDPaintAdminESP")
end

function PLUGIN:DrawItems()
    local THRESHOLD = ScreenScale(12) * 2

    local stacks_by_class = {}

    local items = ents.FindByClass("ix_item")
    for _ = 1, #items do
        local item = items[_]
        local itemTable = item:GetItemTable()
        if ( !istable(itemTable) ) then continue end

        local scr = item:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local cls = itemTable.uniqueID
        stacks_by_class[cls] = stacks_by_class[cls] or {}

        local placed = false
        for _ = 1, #stacks_by_class[cls] do
            local stack = stacks_by_class[cls][_]
            local dx = scr.x - stack.x
            local dy = scr.y - stack.y
            if ( math.sqrt(dx * dx + dy * dy) <= THRESHOLD ) then
                stack.items[#stack.items + 1] = item
                -- update stack anchor to running average so it follows visual cluster
                local n = #stack.items
                stack.x = (stack.x * (n - 1) + scr.x) / n
                stack.y = (stack.y * (n - 1) + scr.y) / n
                placed = true
                break
            end
        end

        if ( !placed ) then
            stacks_by_class[cls][#stacks_by_class[cls] + 1] = { x = scr.x, y = scr.y, items = { item } }
        end
    end

    -- Draw stacks: single label per visual cluster, add count if > 1
    for cls, stacks in pairs(stacks_by_class) do
        for _ = 1, #stacks do
            local stack = stacks[_]
            local x, y = stack.x, stack.y
            local count = #stack.items

            local stored = ix.item.list[cls]
            if ( !stored ) then continue end

            local displayName = stored:GetName() or "Unknown Item"
            draw.SimpleTextOutlined(displayName, "ixAdminRegular", x, y + 4, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))

            if ( count > 1 ) then
                draw.SimpleTextOutlined("x" .. tostring(count), "ixAdminSmall", x, y - 4, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
            end
        end
    end
end

local OUTLINE = Color(0, 0, 0)
local CHARACTER_NAME_COLOR = Color(255, 255, 255)
local STEAM_NAME_COLOR = Color(170, 215, 255)
local STEAM_NAME_FALLBACK_COLOR = Color(255, 255, 255)
local HEALTH_COLOR = Color(120, 235, 120)
local ARMOR_COLOR = Color(120, 185, 255)
local WEAPON_COLOR = Color(255, 220, 130)

function PLUGIN:DrawPlayers()
    local client = LocalPlayer()
    if ( !ix.util.IsValidPlayer(client) or !ix.admin:CanAccessPrivilege(client, "Helix - Observer") ) then return end

    local nameFont = "ixAdminHugeBold"
    local subFont = "ixAdminRegularBold"
    local detailFont = "ixAdminSmall"
    local nameLineHeight = draw.GetFontHeight(nameFont) * 0.95
    local subLineHeight = draw.GetFontHeight(subFont) * 1.0
    local detailLineHeight = draw.GetFontHeight(detailFont) * 1.05

    for _, target in player.Iterator() do
        if ( target == client or !ix.util.IsValidPlayer(target) ) then continue end

        local scr = target:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local steamName = target:SteamName()
        local teamName = team.GetName(target:Team()) or "Unknown"
        local character = target:GetCharacter()
        local characterName = nil

        if ( character ) then
            characterName = character:GetName()

            local class = character:GetClass()
            if ( class ) then
                local classTable = ix.class.instances[class]
                if ( classTable ) then
                    teamName = teamName .. " (" .. (classTable.name or "Unknown") .. ")"
                end
            end
        end

        local primaryName = characterName or steamName
        local primaryColor = characterName and CHARACTER_NAME_COLOR or STEAM_NAME_FALLBACK_COLOR
        local secondaryLine = string.format("@%s  [%d]", steamName, target:EntIndex())

        local yOffset = 0

        draw.SimpleTextOutlined(primaryName, nameFont, scr.x, scr.y + yOffset, primaryColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
        yOffset = yOffset + nameLineHeight

        if ( characterName ) then
            draw.SimpleTextOutlined(secondaryLine, subFont, scr.x, scr.y + yOffset, STEAM_NAME_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            yOffset = yOffset + subLineHeight
        else
            draw.SimpleTextOutlined("[" .. target:EntIndex() .. "]", subFont, scr.x, scr.y + yOffset, STEAM_NAME_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            yOffset = yOffset + subLineHeight
        end

        draw.SimpleTextOutlined(teamName, detailFont, scr.x, scr.y + yOffset, team.GetColor(target:Team()) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
        yOffset = yOffset + detailLineHeight

        local health = target:Health() or 0
        local armor = target:Armor() or 0
        local statusParts = { { text = "HP " .. health, color = HEALTH_COLOR } }
        if ( armor > 0 ) then
            statusParts[#statusParts + 1] = { text = "AR " .. armor, color = ARMOR_COLOR }
        end

        local weapon = target:GetActiveWeapon()
        if ( type(weapon) == "Weapon" ) then
            statusParts[#statusParts + 1] = { text = weapon:GetPrintName() or "Unknown", color = WEAPON_COLOR }
        end

        surface.SetFont(detailFont)
        local separator = "   "
        local separatorWidth = surface.GetTextSize(separator)
        local totalWidth = 0

        for i = 1, #statusParts do
            local partWidth = surface.GetTextSize(statusParts[i].text)
            totalWidth = totalWidth + partWidth
            if ( i < #statusParts ) then
                totalWidth = totalWidth + separatorWidth
            end
        end

        local cursorX = scr.x - totalWidth * 0.5
        for i = 1, #statusParts do
            local part = statusParts[i]
            local partWidth = surface.GetTextSize(part.text)
            draw.SimpleTextOutlined(part.text, detailFont, cursorX, scr.y + yOffset, part.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            cursorX = cursorX + partWidth + separatorWidth
        end
    end
end

-- Search for Helix entities and draw their name.
local blacklist = {
    ["ix_item"] = true,
    ["ix_hands"] = true,
}

function PLUGIN:DrawEntities()
    local client = LocalPlayer()
    if ( !ix.util.IsValidPlayer(client) or !ix.admin:CanAccessPrivilege(client, "Helix - Observer") ) then return end

    local gamemodeItems = ents.FindByClass("ix_*")

    for _ = 1, #gamemodeItems do
        local ent = gamemodeItems[_]
        if ( !IsValid(ent) or blacklist[ent:GetClass()] or ent:GetOwner() ) then continue end

        local scr = ent:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local class = ent:GetClass() or "Unknown"
        local name = ent.PrintName or class

        draw.SimpleTextOutlined(name, "ixAdminRegularBold", scr.x, scr.y + 4, Color(255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined(class, "ixAdminSmall", scr.x, scr.y - 4, Color(200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end
