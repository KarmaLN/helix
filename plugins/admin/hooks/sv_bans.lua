

local PLUGIN = PLUGIN or {}

function PLUGIN:CheckPasswordBan(steamID64)
    local banData = self:GetCachedActiveBan(steamID64)
    if ( !banData ) then return end

    return false, self:BuildBanKickMessage(banData)
end

function PLUGIN:ValidateAuthedBan(client)
    self:ValidateClientBan(client, "PlayerAuthed")
end

function PLUGIN:ValidateInitialSpawnBan(client)
    self:ValidateClientBan(client, "PlayerInitialSpawn")
end

hook.Add("CheckPassword", "ix.admin.bans.CheckPassword", function(steamID64)
    if ( !istable(PLUGIN) or !isfunction(PLUGIN.CheckPasswordBan) ) then return end

    return PLUGIN:CheckPasswordBan(steamID64)
end)

hook.Add("PlayerAuthed", "ix.admin.bans.PlayerAuthed", function(client)
    if ( !istable(PLUGIN) or !isfunction(PLUGIN.ValidateAuthedBan) ) then return end

    PLUGIN:ValidateAuthedBan(client)
end)

hook.Add("PlayerInitialSpawn", "ix.admin.bans.PlayerInitialSpawn", function(client)
    if ( !istable(PLUGIN) or !isfunction(PLUGIN.ValidateInitialSpawnBan) ) then return end

    PLUGIN:ValidateInitialSpawnBan(client)
end)
