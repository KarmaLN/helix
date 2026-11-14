

local PANEL = {}

local DEFAULT_USERGROUP_COLOR = Color(170, 170, 170)

local function GetUsergroupColor(usergroup)
    if ( istable(usergroup) and IsColor(usergroup.color) ) then
        return usergroup.color
    end

    return DEFAULT_USERGROUP_COLOR
end

local function NotifyClient(message, notificationType)
    message = tostring(message or "")
    if ( message == "" ) then return end

    local client = LocalPlayer()
    if ( ix.util.IsValidPlayer(client) ) then
        client:Notify(message, notificationType)
        return
    end

    ix.util.Print(message)
end

function PANEL:Init()
    ix.gui.admin_usergroups = self

    self:Dock(FILL)
    self:InvalidateParent(true)

    self.usergroups = {}
    self.players = {}
    self.selectedUsergroup = nil

    self:BuildToolbar()
    self:BuildMainPanels()
    self:RefreshData()
end

function PANEL:BuildToolbar()
    self.toolbar = self:Add("EditablePanel")
    self.toolbar:Dock(TOP)
    self.toolbar:SetTall(ScreenScale(26))
    self.toolbar:DockMargin(0, 0, 0, ScreenScale(6))
    self.toolbar.Paint = nil

    self.refreshButton = self.toolbar:Add("DButton")
    self.refreshButton:Dock(RIGHT)
    self.refreshButton:DockMargin(ScreenScale(4), 0, 0, 0)
    self.refreshButton:SetWide(ScreenScale(56))
    self.refreshButton:SetText("Refresh", true)
    self.refreshButton.DoClick = function()
        self:RefreshData()
    end

    self.manageButton = self.toolbar:Add("DButton")
    self.manageButton:Dock(RIGHT)
    self.manageButton:DockMargin(ScreenScale(4), 0, 0, 0)
    self.manageButton:SetWide(ScreenScale(96))
    self.manageButton:SetText("Set Usergroup", true)
    self.manageButton.DoClick = function()
        self:PromptSetUsergroup()
    end

    self.statusLabel = self.toolbar:Add("DLabel")
    self.statusLabel:Dock(FILL)
    self.statusLabel:SetFont("ixSmallFont")
    self.statusLabel:SetText("Loading usergroups...", true)
    self.statusLabel:SetContentAlignment(4)

    self.toolbar:SetTall(math.max(self.refreshButton:GetTall(), self.statusLabel:GetTall()))
end

function PANEL:BuildMainPanels()
    self.content = self:Add("EditablePanel")
    self.content:Dock(FILL)
    self.content.Paint = nil

    self.listPanel = self.content:Add("EditablePanel")
    self.listPanel:Dock(LEFT)
    self.listPanel:SetWide(ScreenScale(260))
    self.listPanel:DockMargin(0, 0, ScreenScale(6), 0)
    self.listPanel.Paint = function(this, width, height)
        ix.admin.theme:DrawGlassPanel(this, 0, 0, width, height, {
            blur = 0.7
        })
    end

    self.listTitle = self.listPanel:Add("DLabel")
    self.listTitle:Dock(TOP)
    self.listTitle:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(2))
    self.listTitle:SetFont("ixMediumFont")
    self.listTitle:SetText("Usergroups", true)
    self.listTitle:SetContentAlignment(4)

    self.listScroll = self.listPanel:Add("DScrollPanel")
    self.listScroll:Dock(FILL)
    self.listScroll:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScale(6))
    self.listScroll:GetVBar():SetWide(0)

    self.detailPanel = self.content:Add("EditablePanel")
    self.detailPanel:Dock(FILL)
    self.detailPanel.Paint = function(this, width, height)
        ix.admin.theme:DrawGlassPanel(this, 0, 0, width, height, {
            blur = 0.7
        })
    end

    self.detailScroll = self.detailPanel:Add("DScrollPanel")
    self.detailScroll:Dock(FILL)
    self.detailScroll:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(6))
    self.detailScroll:GetVBar():SetWide(0)
end

function PANEL:PerformLayout(width)
    local minWidth = ScreenScale(220)
    local maxWidth = math.max(minWidth, width - ScreenScale(240))
    local wantedWidth = math.Clamp(math.floor(width * 0.42), minWidth, maxWidth)

    if ( IsValid(self.listPanel) ) then
        self.listPanel:SetWide(wantedWidth)
    end
end

function PANEL:RefreshData()
    self.usergroups = ix.admin:GetSortedUsergroups()
    self.players = player.GetAll()

    if ( !self.selectedUsergroup and self.usergroups[1] ) then
        self.selectedUsergroup = self.usergroups[1].uniqueID
    elseif ( self.selectedUsergroup and !ix.admin:GetUsergroup(self.selectedUsergroup) ) then
        self.selectedUsergroup = self.usergroups[1] and self.usergroups[1].uniqueID or nil
    end

    self:UpdateStatus()
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:UpdateStatus()
    if ( !IsValid(self.statusLabel) ) then return end

    local groupCount = #self.usergroups
    local playerCount = #self.players
    local text = "Showing " .. tostring(groupCount) .. " usergroups and " .. tostring(playerCount) .. " online players."
    self.statusLabel:SetText(text, true)
end

function PANEL:SelectUsergroup(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then return end

    self.selectedUsergroup = uniqueID
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:GetPlayersInUsergroup(uniqueID)
    local players = {}

    for i = 1, #self.players do
        local client = self.players[i]
        if ( ix.util.IsValidPlayer(client) and ix.admin:GetPlayerUsergroup(client) == uniqueID ) then
            players[#players + 1] = client
        end
    end

    table.sort(players, function(a, b)
        return a:SteamName() < b:SteamName()
    end)

    return players
end

function PANEL:RunAdminCommand(command, ...)
    command = string.Trim(tostring(command or ""))
    if ( command == "" ) then return end

    ix.command.Send(command, ...)
end

function PANEL:PromptSetUsergroup()
    Derma_StringRequest("Set Usergroup", "Enter a SteamID64 or SteamID:", "", function(identifier)
        if ( !IsValid(self) ) then return end

        identifier = string.Trim(tostring(identifier or ""))
        if ( identifier == "" ) then
            NotifyClient("Please enter a valid SteamID64 or SteamID.", "error")
            return
        end

        local defaultGroup = self.selectedUsergroup or "user"
        Derma_StringRequest("Set Usergroup", "Enter the target usergroup:", defaultGroup, function(usergroup)
            if ( !IsValid(self) ) then return end

            usergroup = string.Trim(tostring(usergroup or ""))
            if ( usergroup == "" ) then
                NotifyClient("Please enter a valid usergroup.", "error")
                return
            end

            self:RunAdminCommand("PlySetUsergroupID", identifier, usergroup)
            timer.Simple(0.25, function()
                if ( IsValid(self) ) then
                    self:RefreshData()
                end
            end)
        end)
    end)
end

function PANEL:AddSectionTitle(text)
    local title = self.detailScroll:Add("DLabel")
    title:Dock(TOP)
    title:DockMargin(0, ScreenScale(4), 0, ScreenScale(2))
    title:SetFont("ixMediumFont")
    title:SetText(tostring(text or ""), true)
    title:SetContentAlignment(4)
end

function PANEL:AddDetailRow(label, value)
    local row = self.detailScroll:Add("EditablePanel")
    row:Dock(TOP)

    local left = row:Add("DLabel")
    left:Dock(LEFT)
    left:SetWide(ScreenScale(112))
    left:SetFont("ixSmallFont")
    left:SetText(tostring(label or "") .. ":", true)
    left:SetContentAlignment(4)

    local right = row:Add("DLabel")
    right:Dock(FILL)
    right:SetFont("ixSmallFont")
    right:SetText(tostring(value or ""), true)
    right:SetContentAlignment(6)

    row:SetTall(math.max(left:GetTall(), right:GetTall()))
end

function PANEL:AddActionButton(text, callback, enabled)
    local button = self.detailScroll:Add("DButton")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ScreenScale(4))
    button:SetText(tostring(text or ""), true)
    button:SetFont("ixSmallFont")
    button:SetContentAlignment(4)
    button:SetEnabled(enabled != false)
    button.DoClick = function()
        if ( enabled == false ) then return end

        if ( isfunction(callback) ) then
            callback()
        end
    end
end

function PANEL:RebuildList()
    if ( !IsValid(self.listScroll) ) then return end

    self.listScroll:Clear()

    if ( self.usergroups[1] == nil ) then
        local noResults = self.listScroll:Add("DLabel")
        noResults:Dock(TOP)
        noResults:DockMargin(ScreenScale(8), ScreenScale(8), ScreenScale(8), 0)
        noResults:SetFont("ixMediumFont")
        noResults:SetText("No usergroups registered.", true)
        noResults:SetContentAlignment(4)
        return
    end

    local panel = self
    for i = 1, #self.usergroups do
        local usergroup = self.usergroups[i]
        local uniqueID = tostring(usergroup.uniqueID or "")
        local onlineCount = #self:GetPlayersInUsergroup(uniqueID)

        local row = self.listScroll:Add("EditablePanel")
        row:Dock(TOP)
        row:SetTall(ScreenScale(42))
        row:DockMargin(0, 0, 0, ScreenScale(4))
        row:SetMouseInputEnabled(true)
        row:SetCursor("hand")
        row.usergroup = usergroup

        row.Paint = function(this, width, height)
            local glass = ix.admin.theme:GetGlass()
            local fill = glass.button

            if ( this.usergroup and this.usergroup.uniqueID == panel.selectedUsergroup ) then
                fill = glass.buttonActive
            elseif ( this:IsHovered() ) then
                fill = glass.buttonHover
            end

            ix.admin.theme:DrawGlassPanel(this, 0, 0, width, height, {
                blur = 0.5,
                fill = fill
            })

            surface.SetDrawColor(GetUsergroupColor(this.usergroup))
            surface.DrawRect(0, 0, math.max(2, ScreenScale(2)), height)
        end

        function row:OnMousePressed(code)
            if ( code != MOUSE_LEFT ) then return end
            panel:SelectUsergroup(self.usergroup.uniqueID)
        end

        local title = row:Add("DLabel")
        title:Dock(TOP)
        title:DockMargin(ScreenScale(6), ScreenScale(4), ScreenScale(6), 0)
        title:SetFont("ixMediumFont")
        title:SetText(tostring(usergroup.name or uniqueID) .. "  (" .. uniqueID .. ")", true)
        title:SetContentAlignment(4)

        local meta = row:Add("DLabel")
        meta:Dock(FILL)
        meta:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScale(2))
        meta:SetFont("ixSmallFont")
        meta:SetText("Level " .. tostring(usergroup.level or 0) .. " | Immunity " .. tostring(usergroup.immunity or usergroup.level or 0) .. " | Online " .. tostring(onlineCount), true)
        meta:SetContentAlignment(4)
    end
end

function PANEL:RebuildDetail()
    if ( !IsValid(self.detailScroll) ) then return end

    self.detailScroll:Clear()

    local usergroup = self.selectedUsergroup and ix.admin:GetUsergroup(self.selectedUsergroup) or nil
    if ( !istable(usergroup) ) then
        local info = self.detailScroll:Add("DLabel")
        info:Dock(TOP)
        info:DockMargin(ScreenScale(4), ScreenScale(6), 0, 0)
        info:SetFont("ixMediumFont")
        info:SetText("Select a usergroup to inspect details.", true)
        info:SetContentAlignment(4)
        return
    end

    local uniqueID = tostring(usergroup.uniqueID or self.selectedUsergroup)
    local playersInGroup = self:GetPlayersInUsergroup(uniqueID)

    local header = self.detailScroll:Add("DLabel")
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, ScreenScale(2))
    header:SetFont("ixMediumFont")
    header:SetText(tostring(usergroup.name or uniqueID), true)
    header:SetContentAlignment(4)

    local subHeader = self.detailScroll:Add("DLabel")
    subHeader:Dock(TOP)
    subHeader:DockMargin(0, 0, 0, ScreenScale(4))
    subHeader:SetFont("ixSmallFont")
    subHeader:SetText(uniqueID, true)
    subHeader:SetContentAlignment(4)

    self:AddSectionTitle("Actions")
    self:AddActionButton("Set Player Usergroup", function()
        self:PromptSetUsergroup()
    end, true)
    self:AddActionButton("Copy Usergroup ID", function()
        if ( SetClipboardText ) then
            SetClipboardText(uniqueID)
        end
    end, uniqueID != "")
    self:AddActionButton("Print Usergroup Info", function()
        self:RunAdminCommand("UsergroupInfo", uniqueID)
    end, uniqueID != "")

    self:AddSectionTitle("Details")
    self:AddDetailRow("Name", usergroup.name or uniqueID)
    self:AddDetailRow("Description", usergroup.description != "" and usergroup.description or "No description.")
    self:AddDetailRow("Level", usergroup.level or 0)
    self:AddDetailRow("Immunity", usergroup.immunity or usergroup.level or 0)
    self:AddDetailRow("Inherits", usergroup.inherits or "none")
    self:AddDetailRow("Protected", usergroup.bProtected and "Yes" or "No")
    self:AddDetailRow("Hidden", usergroup.bHidden and "Yes" or "No")
    self:AddDetailRow("Default", usergroup.bDefault and "Yes" or "No")
    self:AddDetailRow("Online Players", #playersInGroup)

    self:AddSectionTitle("Online Members")
    if ( playersInGroup[1] == nil ) then
        local empty = self.detailScroll:Add("DLabel")
        empty:Dock(TOP)
        empty:SetFont("ixSmallFont")
        empty:SetText("No online players are currently assigned to this usergroup.", true)
        empty:SetContentAlignment(4)
        return
    end

    for i = 1, #playersInGroup do
        local client = playersInGroup[i]
        local steamID64 = client:SteamID64()

        local member = self.detailScroll:Add("DButton")
        member:Dock(TOP)
        member:DockMargin(0, 0, 0, ScreenScale(4))
        member:SetText(client:SteamName() .. "  (" .. steamID64 .. ")", true)
        member:SetFont("ixSmallFont")
        member:SetContentAlignment(4)
        member.DoClick = function()
            if ( SetClipboardText ) then
                SetClipboardText(steamID64)
                NotifyClient("Copied " .. client:SteamName() .. "'s SteamID64.", "success")
            end
        end
    end
end

function PANEL:OnRemove()
    if ( ix.gui.admin_usergroups == self ) then
        ix.gui.admin_usergroups = nil
    end
end

vgui.Register("ixAdminUsergroups", PANEL, "EditablePanel")
