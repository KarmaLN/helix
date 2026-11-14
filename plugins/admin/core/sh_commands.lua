--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local savedPositions = savedPositions or {}

local function AddCommand(name, command)
    if ( istable(command.arguments) ) then
        local argumentNames = {}
        local argumentTypes = {}

        for i = 1, #command.arguments do
            local argument = command.arguments[i]
            argumentNames[i] = argument.name
            argumentTypes[i] = argument.optional and bit.bor(argument.type, ix.type.optional) or argument.type
        end

        command.arguments = argumentTypes
        command.argumentNames = argumentNames
    end

    command.OnCheckAccess = command.OnCheckAccess or command.CanRun
    command.CanRun = nil
    ix.command.Add(name, command)
end

local function getIdentifier(player)
    return ix.util.IsValidPlayer(player) and player:SteamID64() or nil
end

local function savePosition(player)
    local id = getIdentifier(player)
    if ( !id ) then return end

    if ( !player:Alive() ) then
        player:Spawn()
    end

    savedPositions[id] = {
        pos = player:GetPos(),
        ang = player:EyeAngles()
    }
end

local function restorePosition(player)
    local id = getIdentifier(player)
    if ( !id ) then
        return false, "Invalid player reference"
    end

    local data = savedPositions[id]
    if ( !data or !data.pos or !data.ang ) then
        return false, "No saved position for that player"
    end

    player:SetPos(data.pos)
    player:SetEyeAngles(data.ang)
    return true
end

local function placeNearPlayer(target, reference)
    local forward = reference:EyeAngles():Forward()
    forward.z = 0

    local offset = forward * 64 + Vector(0, 0, 8)
    local destination = target:GetPos() + offset

    reference:SetPos(destination)
    reference:SetEyeAngles(target:EyeAngles())
end

local function bringToPlayer(target, reference)
    local forward = reference:EyeAngles():Forward()
    forward.z = 0

    local offset = forward * 64 + Vector(0, 0, 8)
    local destination = reference:GetPos() + offset

    target:SetPos(destination)
    target:SetEyeAngles(reference:EyeAngles())
end

local function traceDestination(client)
    local trace = util.TraceHull({
        start = client:EyePos(),
        endpos = client:EyePos() + client:EyeAngles():Forward() * 16384,
        filter = client,
        mins = Vector(-16, -16, -4),
        maxs = Vector(16, 16, 64)
    })

    if ( trace.Hit ) then
        return trace.HitPos + trace.HitNormal * 10
    end
end

local function canManageUsergroups(client)
    return ix.admin:CanAccessPrivilege(client, "Helix - Manage Usergroups", "superadmin")
end

local function notifyCaller(client, message, notificationType)
    message = tostring(message or "")
    if ( message == "" ) then return end

    if ( ix.util.IsValidPlayer(client) ) then
        client:Notify(message, notificationType)
        return
    end

    ix.util.Print(message)
end

local function printCallerLine(client, message)
    message = tostring(message or "")
    if ( message == "" ) then return end

    if ( ix.util.IsValidPlayer(client) ) then
        client:ChatPrint(message)
        return
    end

    ix.util.Print(message)
end

AddCommand("PlySetUsergroup", {
    description = "Set an online player's usergroup",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "usergroup", type = ix.type.string }
    },
    CanRun = function(def, client)
        return canManageUsergroups(client)
    end,
    OnRun = function(def, client, target, usergroup)
        ix.admin:SetPlayerUsergroup(client, target, usergroup, function(ok, result, err)
            if ( !ok ) then
                notifyCaller(client, err or "Failed to set usergroup.", "error")
                return
            end

            local actorName = ix.util.IsValidPlayer(client) and client:SteamName() or "Console"
            target:Notify(Format("Your usergroup has been set to %s by %s.", result.new, actorName), "info")
            notifyCaller(client, Format("Set %s's usergroup from %s to %s.", target:SteamName(), result.old, result.new), "success")
        end)
    end
})

AddCommand("PlySetUsergroupID", {
    description = "Set an offline player's usergroup by SteamID64 or SteamID",
    adminOnly = true,
    arguments = {
        { name = "steamid64", type = ix.type.string },
        { name = "usergroup", type = ix.type.string }
    },
    CanRun = function(def, client)
        return canManageUsergroups(client)
    end,
    OnRun = function(def, client, steamID64, usergroup)
        ix.admin:SetSteamIDUsergroup(client, steamID64, usergroup, function(ok, result, err)
            if ( !ok ) then
                notifyCaller(client, err or "Failed to set offline usergroup.", "error")
                return
            end

            notifyCaller(client, Format("Set %s's usergroup from %s to %s.", result.steamid64, result.old, result.new), "success")
        end)
    end
})

AddCommand("PlyGetUsergroup", {
    description = "View a player's current usergroup",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    CanRun = function(def, client)
        return canManageUsergroups(client)
    end,
    OnRun = function(def, client, target)
        local usergroupID = ix.admin:GetPlayerUsergroup(target)
        local group = ix.admin:GetUsergroup(usergroupID)
        local groupName = istable(group) and group.name or usergroupID

        return Format("%s is in usergroup %s (%s).", target:SteamName(), groupName, usergroupID)
    end
})

AddCommand("UsergroupList", {
    description = "List registered usergroups",
    adminOnly = true,
    CanRun = function(def, client)
        return canManageUsergroups(client)
    end,
    OnRun = function(def, client)
        printCallerLine(client, "Registered usergroups:")

        local usergroups = ix.admin:GetSortedUsergroups()
        for i = 1, #usergroups do
            local group = usergroups[i]
            local inherits = group.inherits or "none"
            local line = Format("- %s (%s): level %s, immunity %s, inherits %s", group.name, group.uniqueID, tostring(group.level or 0), tostring(group.immunity or group.level or 0), inherits)
            printCallerLine(client, line)
        end
    end
})

AddCommand("UsergroupInfo", {
    description = "View details for a registered usergroup",
    adminOnly = true,
    arguments = {
        { name = "usergroup", type = ix.type.string }
    },
    CanRun = function(def, client)
        return canManageUsergroups(client)
    end,
    OnRun = function(def, client, usergroup)
        local uniqueID, group, err = ix.admin:NormalizeUsergroup(usergroup)
        if ( !uniqueID or !istable(group) ) then
            return err or "Unknown usergroup."
        end

        printCallerLine(client, Format("Usergroup: %s (%s)", group.name, uniqueID))
        printCallerLine(client, "Description: " .. (group.description != "" and group.description or "No description."))
        printCallerLine(client, "Level: " .. tostring(group.level or 0))
        printCallerLine(client, "Immunity: " .. tostring(group.immunity or group.level or 0))
        printCallerLine(client, "Inherits: " .. tostring(group.inherits or "none"))
        printCallerLine(client, "Protected: " .. (group.bProtected and "yes" or "no"))
    end
})

AddCommand("PlyGoto", {
    description = "Teleport yourself to a player",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        if ( client == target ) then
            return "You cannot teleport to yourself"
        end

        savePosition(client)
        placeNearPlayer(target, client)

        return "Teleported to " .. target:Nick()
    end
})

AddCommand("PlyBring", {
    description = "Bring a player to you",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        if ( client == target ) then
            return "You cannot bring yourself"
        end

        savePosition(target)
        bringToPlayer(target, client)

        return "Brought " .. target:Nick() .. " to your position"
    end
})

AddCommand("PlyTeleport", {
    description = "Teleport to where you're looking",
    adminOnly = true,
    OnRun = function(def, client)
        local destination = traceDestination(client)

        if ( !destination ) then
            return "Could not find a valid location to teleport to"
        end

        savePosition(client)
        client:SetPos(destination)

        return "Teleported to target location"
    end
})

AddCommand("PlyReturn", {
    description = "Return a player to their previous position",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player, optional = true }
    },
    OnRun = function(def, client, target)
        target = target or client

        local ok, err = restorePosition(target)
        if ( !ok ) then
            return err or "Unable to return that player"
        end

        return "Returned " .. target:Nick() .. " to their previous position"
    end
})

AddCommand("PlySetHealth", {
    description = "Set a player's health",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "amount", type = ix.type.number }
    },
    OnRun = function(def, client, target, amount)
        amount = math.Clamp(amount, 0, 2147483647)
        target:SetHealth(amount)

        if ( target == client ) then
            return "Set your health to " .. amount
        else
            return "Set " .. target:Nick() .. "'s health to " .. amount
        end
    end
})

AddCommand("CharSetBodygroup", {
	description = "@cmdCharSetBodygroup",
	adminOnly = true,
	arguments = {
        { name = "target", type = ix.type.player },
        { name = "bodygroup", type = ix.type.string, min = 0 },
        { name = "value", type = ix.type.number, min = 0 }
	},
	OnRun = function(def, client, target, bodygroup, value)
		local index = target:FindBodygroupByName(bodygroup)

		if (index > -1) then
			if (value and value < 1) then
				value = nil
			end

			target:SetBodygroup(index, value or 0)

		else
			return "@invalidArg", 2
		end
	end
})

AddCommand("PlySetArmor", {
    description = "Set a player's armor",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "amount", type = ix.type.number }
    },
    OnRun = function(def, client, target, amount)
        amount = math.Clamp(amount, 0, 2147483647)
        target:SetArmor(amount)

        if ( target == client ) then
            return "Set your armor to " .. amount
        else
            return "Set " .. target:Nick() .. "'s armor to " .. amount
        end
    end
})

AddCommand("PlyGiveAmmo", {
    description = "Give ammo to a player",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "amount", type = ix.type.number },
        { name = "ammo type", type = ix.type.string, optional = true }
    },
    OnRun = function(def, client, target, amount, ammoType)
        local weapon = target:GetActiveWeapon()

        if ( type(weapon) != "Weapon" ) then
            return target:Nick() .. " has no active weapon"
        end

        ammoType = ammoType or weapon:GetPrimaryAmmoType()

        if ( ammoType == -1 ) then
            return "Invalid ammo type"
        end

        target:GiveAmmo(amount, ammoType, true)

        if ( target == client ) then
            return "Gave yourself " .. amount .. " ammo"
        else
            return "Gave " .. target:Nick() .. " " .. amount .. " ammo"
        end
    end
})

AddCommand("PlyFreeze", {
    description = "Freeze or unfreeze a player",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        if ( target == client ) then
            return "You cannot freeze yourself"
        end

        target:Freeze(!target:IsFrozen())

        local state = target:IsFrozen() and "frozen" or "unfrozen"
        return target:Nick() .. " has been " .. state
    end
})

AddCommand("PlyRespawn", {
    description = "Respawn a player",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        target:Spawn()
        return "Respawned " .. target:Nick()
    end
})

AddCommand("PlySlay", {
    description = "Kill a player",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        target:TakeDamage(target:Health(), client, nil)

        return "Killed " .. target:Nick()
    end
})

AddCommand("PlyExit", {
    description = "Force a player to exit their vehicle or chair",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player }
    },
    OnRun = function(def, client, target)
        if ( !ix.util.IsValidPlayer(target) ) then return end

        if ( target:InVehicle() ) then
            target:ExitVehicle()
            return "Forced " .. target:Nick() .. " to exit their vehicle/seat."
        end

        return target:Nick() .. " is not in a vehicle or chair."
    end
})

AddCommand("PlyKick", {
    description = "Kick a player from the server",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "reason", type = ix.type.text, optional = true }
    },
    OnRun = function(def, client, target, reason)
        if ( target == client ) then
            return "You cannot kick yourself"
        end

        if ( !isstring(reason) or reason == "" ) then
            reason = "Kicked by " .. (ix.util.IsValidPlayer(client) and client:Nick() or "Console")
        end

        local targetName = target:Nick()
        target:Kick(reason)

        return "Kicked " .. targetName .. " (" .. reason .. ")"
    end
})

AddCommand("Map", {
    description = "Change the map",
    adminOnly = true,
    arguments = {
        { name = "map", type = ix.type.string, required = true },
        { name = "time", type = ix.type.number, required = false }
    },
    OnRun = function(self, client, map, delay)
        if ( !map or map == "" ) then
            return "You must specify a map."
        end

        -- Normalize map name
        map = string.lower(string.Trim(map))

        delay = delay or 15

        -- Check if map exists
        if ( !file.Exists("maps/" .. map .. ".bsp", "GAME") ) then
            return "Map '" .. map .. "' does not exist on the server."
        end

        -- Prevent changing to current map
        if ( game.GetMap() == map ) then
            return "You are already on this map."
        end

        -- Notify players
        for _, other in player.Iterator() do
            other:ChatPrint(client:Nick() .. " is changing the map to " .. map .. " in " .. tostring(delay) .. " second(s)")
        end

        -- Delay slightly to ensure messages send
        timer.Simple(delay, function()
            RunConsoleCommand("changelevel", map)
        end)

        return
    end
})

AddCommand("StopSounds", {
    description = "Immediately stops all sounds.",
    adminOnly = true,
    OnRun = function(self, client)
        for _, other in player.Iterator() do
            other:ConCommand("stopsound")
        end
    end
})

ix.chat.Register("admin", {
    displayName = "Radio",
    description = "Talk in Radio",
    prefix = {"@", "/admin"},

    OnRun = function(this, client, message)
        local formattedMessage = ix.chat:FormatWithMarkdown(message, "ix.small")
		local usergroupTable = ix.admin:GetUsergroup(ix.admin:GetPlayerUsergroup(client))
        return (usergroupTable and usergroupTable.color) or color_white, "[Staff Chat] " .. ((usergroupTable and usergroupTable.name) or "Staff") .. " | " .. client:SteamName(), ": ", formattedMessage
    end,

    CanSay = function(this, speaker, text)
        return speaker:IsAdmin()
    end,

    CanHear = function(this, speaker, listener)
        return listener:IsAdmin()
    end
})
