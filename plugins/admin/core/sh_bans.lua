--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLUGIN = PLUGIN or {}

if ( !isfunction(PLUGIN.CanAccessBanPrivilege) ) then
    function PLUGIN:CanAccessBanPrivilege(client)
        if ( !ix.util.IsValidPlayer(client) ) then
            return true
        end

        return client:IsAdmin()
    end
end

local function NotifyCaller(client, message, notificationType)
    message = tostring(message or "")
    if ( message == "" ) then return end

    if ( ix.util.IsValidPlayer(client) ) then
        client:Notify(message, notificationType)
        return
    end

    ix.util.Print(message)
end

local function PrintCallerLine(client, message)
    message = tostring(message or "")
    if ( message == "" ) then return end

    if ( ix.util.IsValidPlayer(client) ) then
        client:ChatPrint(message)
        return
    end

    ix.util.Print(message)
end

local function CanUsePrivilege(client, privilege)
    return PLUGIN:CanAccessBanPrivilege(client, privilege)
end

ix.command.Add("PlyBan", {
    description = "Ban a player from the server (minutes; 0 = permanent)",
    adminOnly = true,
    arguments = {
        { name = "player", type = ix.type.player },
        { name = "minutes", type = ix.type.number },
        { name = "reason", type = ix.type.text, optional = true }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - Ban Players")
    end,
    OnRun = function(_, client, target, minutes, reason)
        if ( target == client ) then
            return "You cannot ban yourself"
        end

        if ( !isstring(reason) or reason == "" ) then
            reason = "Banned by " .. (ix.util.IsValidPlayer(client) and client:Nick() or "Console")
        end

        local targetName = target:SteamName()
        target:Ban(minutes, true, reason, client, function(ok, banData, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to ban player.", "error")
                return
            end

            local duration = PLUGIN:FormatBanDuration(banData.duration)
            NotifyCaller(client, "Banned " .. targetName .. " for " .. duration .. " (#" .. tostring(banData.id) .. ").", "success")
        end)
    end
})

ix.command.Add("PlyBanID", {
    description = "Ban an offline player by SteamID64 or SteamID (minutes; 0 = permanent)",
    adminOnly = true,
    arguments = {
        { name = "steamid64", type = ix.type.string },
        { name = "minutes", type = ix.type.number },
        { name = "reason", type = ix.type.text, optional = true }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - Ban Offline Players")
    end,
    OnRun = function(_, client, identifier, minutes, reason)
        reason = isstring(reason) and reason or ""
        if ( reason == "" ) then
            reason = "Banned by " .. (ix.util.IsValidPlayer(client) and client:Nick() or "Console")
        end

        PLUGIN:CreateBanBySteamID64(identifier, client, minutes, reason, function(ok, banData, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to ban SteamID64.", "error")
                return
            end

            local onlineTarget = player.GetBySteamID64(banData.steamid64)
            if ( ix.util.IsValidPlayer(onlineTarget) ) then
                onlineTarget:Kick(PLUGIN:BuildBanKickMessage(banData))
            end

            local duration = PLUGIN:FormatBanDuration(banData.duration)
            NotifyCaller(client, "Banned " .. banData.steamid64 .. " for " .. duration .. " (#" .. tostring(banData.id) .. ").", "success")
        end)
    end
})

ix.command.Add("PlyUnban", {
    description = "Revoke an active ban by SteamID64 or SteamID",
    adminOnly = true,
    arguments = {
        { name = "steamid64", type = ix.type.string },
        { name = "reason", type = ix.type.text, optional = true }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - Unban Players")
    end,
    OnRun = function(_, client, identifier, reason)
        PLUGIN:UnbanSteamID64(identifier, client, reason, function(ok, banData, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to unban player.", "error")
                return
            end

            NotifyCaller(client, "Revoked ban #" .. tostring(banData.id) .. " for " .. banData.steamid64 .. ".", "success")
        end)
    end
})

ix.command.Add("PlyBanModify", {
    description = "Modify an active ban duration/reason (minutes; 0 = permanent)",
    adminOnly = true,
    arguments = {
        { name = "ban id", type = ix.type.number },
        { name = "minutes", type = ix.type.number },
        { name = "reason", type = ix.type.text, optional = true }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - Modify Bans")
    end,
    OnRun = function(_, client, banID, minutes, reason)
        PLUGIN:ModifyBan(banID, client, minutes, reason, function(ok, banData, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to modify ban.", "error")
                return
            end

            local duration = PLUGIN:FormatBanDuration(banData.duration)
            NotifyCaller(client, "Modified ban #" .. tostring(banData.id) .. "; new duration: " .. duration .. ".", "success")
        end)
    end
})

ix.command.Add("PlyBanInfo", {
    description = "View detailed information about a ban",
    adminOnly = true,
    arguments = {
        { name = "ban id", type = ix.type.number }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - View Bans")
    end,
    OnRun = function(_, client, banID)
        PLUGIN:GetBanByID(banID, function(ok, banData, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to fetch ban.", "error")
                return
            end

            PrintCallerLine(client, PLUGIN:FormatBanSummary(banData))
            PrintCallerLine(client, "SteamID64: " .. banData.steamid64)
            PrintCallerLine(client, "Created: " .. PLUGIN:FormatBanTime(banData.created_at))
            PrintCallerLine(client, "Modified: " .. PLUGIN:FormatBanTime(banData.modified_at))
            PrintCallerLine(client, "Revoked: " .. PLUGIN:FormatBanTime(banData.revoked_at))
        end)
    end
})

ix.command.Add("PlyBanHistory", {
    description = "View previous bans for a SteamID64 or SteamID",
    adminOnly = true,
    arguments = {
        { name = "steamid64", type = ix.type.string }
    },
    CanRun = function(_, client)
        return CanUsePrivilege(client, "Helix - View Bans")
    end,
    OnRun = function(_, client, identifier)
        PLUGIN:GetBanHistory(identifier, function(ok, rows, err)
            if ( !ok ) then
                NotifyCaller(client, err or "Failed to fetch ban history.", "error")
                return
            end

            if ( #rows == 0 ) then
                NotifyCaller(client, "No ban history found.", "info")
                return
            end

            PrintCallerLine(client, "Ban history:")
            for i = 1, math.min(#rows, 10) do
                PrintCallerLine(client, PLUGIN:FormatBanSummary(rows[i]))
            end

            if ( #rows > 10 ) then
                PrintCallerLine(client, "Showing 10 of " .. tostring(#rows) .. " bans.")
            end
        end)
    end
})
