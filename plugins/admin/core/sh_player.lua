local playerMeta = FindMetaTable("Player")

if ( SERVER ) then
    function playerMeta:GetUsergroup()
        return self:GetData("admin_usergroup", "user")
    end

    function playerMeta:SetUsergroup(usergroup, options)
        options = istable(options) and options or {}
        self:SetData("admin_usergroup", usergroup, options.bNoNetworking == true)

        if ( !options.bNoDBUpdate and isfunction(self.SaveData) ) then
            self:SaveData()
        end
    end
else
    function playerMeta:GetUsergroup()
        return self:GetUserGroup()
    end
end
