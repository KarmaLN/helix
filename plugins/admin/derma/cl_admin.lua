
local PANEL = {}

function PANEL:Init()
    ix.gui.admin = self

    ix.admin.theme:ApplySkin(self)
    self:Dock(FILL)
    self:InvalidateParent(true)
end

vgui.Register("ixAdmin", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "ixAdmin", function(buttons)
    local client = LocalPlayer()
    local canViewActivity = ix.admin:CanAccessPrivilege(client, "Helix - Admin Activity")
    local canViewBans = ix.admin:CanAccessPrivilege(client, "Helix - View Bans")
    local canManageUsergroups = ix.admin:CanAccessPrivilege(client, "Helix - Manage Usergroups", "superadmin")

    if ( !canViewActivity and !canViewBans and !canManageUsergroups ) then return end

    buttons["admin"] = {
        Create = function(this, panel)
            panel:Add("ixAdmin")
        end,
        Sections = {}
    }

    local sections = buttons["admin"].Sections
    if ( canViewActivity ) then
        sections["activity"] = {
            Create = function(this, panel)
                panel:Add("ixAdminActivity")
            end
        }
    end
    if ( canViewBans ) then
        sections["bans"] = {
            Create = function(this, panel)
                panel:Add("ixAdminBans")
            end
        }
    end
    if ( canManageUsergroups ) then
        sections["usergroups"] = {
            Create = function(this, panel)
                panel:Add("ixAdminUsergroups")
            end
        }
    end
end)
