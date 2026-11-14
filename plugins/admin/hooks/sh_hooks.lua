local PLUGIN = PLUGIN or {}

function PLUGIN:PlayerNoClip(client, desiredState)
    if ( !CAMI.PlayerHasAccess(client, "Helix - Observer", nil) ) then return false end

    if ( desiredState ) then
        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:DrawShadow(false)

        if ( SERVER ) then
            client:SetNoTarget(true)
            client:DrawWorldModel(false)
        end

        return true
    else
        client:SetNoDraw(false)
        client:SetNotSolid(false)
        client:DrawShadow(true)

        if ( SERVER ) then
            client:SetNoTarget(false)
            client:DrawWorldModel(true)
        end

        return true
    end

    return false
end
