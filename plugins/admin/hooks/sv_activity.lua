--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLUGIN = PLUGIN or {}

local PING_SAMPLE_INTERVAL = 20

local function EnsureSession(client)
    if ( !ix.util.IsValidPlayer(client) ) then return nil end

    local clientTable = client:GetTable()
    local session = clientTable.ixAdminActivitySession
    if ( !istable(session) ) then
        session = {
            joinUnix = os.time(),
            pingSum = 0,
            pingSamples = 0,
            joinHour = os.date("*t").hour or 0
        }

        clientTable.ixAdminActivitySession = session
    end

    return session
end

local function RecordSessionStart(plugin, client)
    if ( !ix.util.IsValidPlayer(client) ) then return end

    local session = EnsureSession(client)
    if ( !istable(session) or session.started == true ) then
        return
    end

    local now = os.time()
    local dateData = os.date("*t", now) or {}
    local joinHour = math.Clamp(tonumber(dateData.hour) or 0, 0, 23)

    session.joinUnix = now
    session.joinHour = joinHour
    session.started = true

    local activityData = plugin:GetPlayerActivityData(client)
    activityData.last_join = now
    activityData.total_sessions = math.max(0, tonumber(activityData.total_sessions) or 0) + 1
    activityData.join_hour_sum = (tonumber(activityData.join_hour_sum) or 0) + joinHour
    activityData.join_hour_samples = math.max(0, tonumber(activityData.join_hour_samples) or 0) + 1

    local lastLeave = tonumber(activityData.last_leave) or 0
    if ( lastLeave > 0 and now > lastLeave ) then
        activityData.join_interval_sum = math.max(0, tonumber(activityData.join_interval_sum) or 0) + (now - lastLeave)
        activityData.join_interval_samples = math.max(0, tonumber(activityData.join_interval_samples) or 0) + 1
    end

    plugin:SetPlayerActivityData(client, activityData)
    plugin:InvalidateActivityCache()
end

function PLUGIN:PlayerReady(client)
    if ( !ix.util.IsValidPlayer(client) ) then return end

    RecordSessionStart(PLUGIN, client)
end

function PLUGIN:PlayerDisconnected(client)
    if ( !ix.util.IsValidPlayer(client) ) then return end

    local clientTable = client:GetTable()
    local session = EnsureSession(client)
    if ( !istable(session) ) then return end

    local now = os.time()
    local joinUnix = tonumber(session.joinUnix) or now
    local sessionSeconds = math.max(0, now - joinUnix)

    local activityData = self:GetPlayerActivityData(client)
    local basePlaytime = math.max(0, tonumber(activityData.total_playtime) or tonumber(client:GetPlayTime()) or 0)
    activityData.total_playtime = basePlaytime + sessionSeconds
    activityData.total_ping = math.max(0, tonumber(activityData.total_ping) or 0) + math.max(0, tonumber(session.pingSum) or 0)
    activityData.ping_samples = math.max(0, tonumber(activityData.ping_samples) or 0) + math.max(0, tonumber(session.pingSamples) or 0)
    activityData.last_session_duration = sessionSeconds
    activityData.last_leave = now

    self:SetPlayerActivityData(client, activityData)

    clientTable.ixAdminActivitySession = nil

    self:InvalidateActivityCache()
end

timer.Create("ix.admin.activity.ping", PING_SAMPLE_INTERVAL, 0, function()
    for _, client in player.Iterator() do
        if ( !ix.util.IsValidPlayer(client) ) then continue end

        local session = EnsureSession(client)
        if ( !istable(session) ) then continue end

        session.pingSum = math.max(0, tonumber(session.pingSum) or 0) + math.max(0, tonumber(client:Ping()) or 0)
        session.pingSamples = math.max(0, tonumber(session.pingSamples) or 0) + 1
    end
end)

hook.Add("OnReloaded", "ix.admin.activity.bootstrap", function()
    for _, client in player.Iterator() do
        if ( !ix.util.IsValidPlayer(client) ) then continue end
        if ( !client:GetCharacter() ) then continue end

        RecordSessionStart(PLUGIN, client)
    end
end)
