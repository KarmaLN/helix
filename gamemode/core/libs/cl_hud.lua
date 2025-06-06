
ix.hud = {}

function ix.hud.DrawItemPickup()
	local pickupTime = ix.config.Get("itemPickupTime", 0.5)

	if (pickupTime == 0) then
		return
	end

	local client = LocalPlayer()
	local entity = client.ixInteractionTarget
	local startTime = client.ixInteractionStartTime

	if (IsValid(entity) and startTime) then
		local sysTime = SysTime()
		local endTime = startTime + pickupTime

		if (sysTime >= endTime or client:GetEyeTrace().Entity != entity) then
			client.ixInteractionTarget = nil
			client.ixInteractionStartTime = nil

			return
		end

		local fraction = math.min((endTime - sysTime) / pickupTime, 1)
		local x, y = ScrW() / 2, ScrH() / 2
		local radius, thickness = 32, 6
		local startAngle = 90
		local endAngle = startAngle + (1 - fraction) * 360
		local color = ColorAlpha(color_white, fraction * 255)

		ix.util.DrawArc(x, y, radius, thickness, startAngle, endAngle, 2, color)
	end
end

function ix.hud.PopulateItemTooltip(tooltip, item)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(item.GetName and item:GetName() or L(item.name))
	name:SetMaxWidth(math.max(name:GetMaxWidth(), ScrW() * 0.5))
	name:SizeToContents()

	if item:GetDescription() and (item:GetDescription() != "") then
		local description = tooltip:AddRow("description")
		description:SetText(item:GetDescription() or "")
		description:SizeToContents()
	end 

	if (item.PopulateTooltip) then
		item:PopulateTooltip(tooltip)
	end

	hook.Run("PopulateItemTooltip", tooltip, item)
end

function ix.hud.PopulatePlayerTooltip(tooltip, client)
	local name = tooltip:AddRow("name")
	name:SetImportant()
	name:SetText(client:SteamName())
	name:SetBackgroundColor(team.GetColor(client:Team()))
	name:SizeToContents()

	local nameHeight = name:GetTall()
	name:SetTextInset(nameHeight + 4, 0)
	name:SetWide(name:GetWide() + nameHeight + 4)

	local avatar = name:Add("AvatarImage")
	avatar:Dock(LEFT)
	avatar:SetPlayer(client, nameHeight)
	avatar:SetSize(name:GetTall(), name:GetTall())

	local currentPing = client:Ping()

	local ping = tooltip:AddRow("ping")
	ping:SetText(L("ping", currentPing))
	ping.Paint = function(_, width, height)
		surface.SetDrawColor(ColorAlpha(derma.GetColor(
			currentPing < 110 and "Success" or (currentPing < 165 and "Warning" or "Error")
		, tooltip), 22))
		surface.DrawRect(0, 0, width, height)
	end
	ping:SizeToContents()

	hook.Run("PopulatePlayerTooltip", client, tooltip)
end

function ix.hud.DrawAll()
	ix.hud.DrawItemPickup()
end
