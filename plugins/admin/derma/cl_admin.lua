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
    ax.gui.admin = self

    self:Dock(FILL)
    self:InvalidateParent(true)
end

vgui.Register("ix.tab.admin", PANEL, "EditablePanel")

hook.Add("PopulateTabButtons", "ix.tab.admin", function(buttons)
    if ( !ix.client:IsAdmin() ) then return end -- TODO: Replace with proper permission check

    buttons["admin"] = {
        Populate = function(this, panel)
            panel:Add("ix.tab.admin")
        end,
        Sections = {
            ["activity"] = {
                Populate = function(this, panel)
                    panel:Add("ix.tab.admin.activity")
                end
            },
            ["bans"] = {
                Populate = function(this, panel)
                    panel:Add("ix.tab.admin.bans")
                end
            },
            ["usergroups"] = {
                Populate = function(this, panel)
                    panel:Add("ix.tab.admin.usergroups")
                end
            }
        }
    }
end)

hook.Add("PostPopulateTabButtons", "ix.tab.admin.config", function(buttons)
    local admin = buttons["admin"]
    local config = buttons["config"]

    if ( !istable(admin) or !istable(admin.Sections) or !istable(config) ) then
        return
    end

    admin.Sections["config"] = admin.Sections["config"] or config
    buttons["config"] = nil
end)
