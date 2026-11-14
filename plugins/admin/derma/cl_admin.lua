--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    ix.gui.admin = self

    ix.admin.theme:ApplySkin(self)
    self:Dock(FILL)
    self:InvalidateParent(true)
end

vgui.Register("ix.tab.admin", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "ix.tab.admin", function(buttons)
    local client = LocalPlayer()
    local canViewActivity = ix.admin:CanAccessPrivilege(client, "Helix - Admin Activity")
    local canViewBans = ix.admin:CanAccessPrivilege(client, "Helix - View Bans")
    local canManageUsergroups = ix.admin:CanAccessPrivilege(client, "Helix - Manage Usergroups", "superadmin")

    if ( !canViewActivity and !canViewBans and !canManageUsergroups ) then return end

    buttons["admin"] = {
        Create = function(this, panel)
            panel:Add("ix.tab.admin")
        end,
        Sections = {}
    }

    local sections = buttons["admin"].Sections
    if ( canViewActivity ) then
        sections["activity"] = {
            Create = function(this, panel)
                panel:Add("ix.tab.admin.activity")
            end
        }
    end
    if ( canViewBans ) then
        sections["bans"] = {
            Create = function(this, panel)
                panel:Add("ix.tab.admin.bans")
            end
        }
    end
    if ( canManageUsergroups ) then
        sections["usergroups"] = {
            Create = function(this, panel)
                panel:Add("ix.tab.admin.usergroups")
            end
        }
    end
end)
