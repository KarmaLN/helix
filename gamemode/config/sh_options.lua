
if (CLIENT) then
	ix.option.Add("animationScale", ix.type.number, 1, {
		category = "appearance", min = 0.3, max = 2, decimals = 1
	})

	ix.option.Add("24hourTime", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("altLower", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("alwaysShowBars", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("minimalTooltips", ix.type.bool, false, {
		category = "appearance"
	})

	ix.option.Add("noticeDuration", ix.type.number, 8, {
		category = "appearance", min = 0.1, max = 20, decimals = 1
	})

	ix.option.Add("noticeMax", ix.type.number, 4, {
		category = "appearance", min = 1, max = 20
	})

	ix.option.Add("cheapBlur", ix.type.bool, false, {
		category = "performance"
	})

	ix.option.Add("disableAnimations", ix.type.bool, false, {
		category = "performance"
	})

	ix.option.Add("openBags", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("showIntro", ix.type.bool, true, {
		category = "general"
	})

	ix.option.Add("escCloseMenu", ix.type.bool, false, {
		category = "general"
	})
end

ix.option.Add("language", ix.type.array, ix.config.language or "english", {
	category = "general",
	bNetworked = true,
	populate = function()
		local entries = {}

		for k, _ in SortedPairs(ix.lang.stored) do
			local name = ix.lang.names[k]
			local name2 = k:utf8sub(1, 1):utf8upper() .. k:utf8sub(2)

			if (name) then
				name = name .. " (" .. name2 .. ")"
			else
				name = name2
			end

			entries[k] = name
		end

		return entries
	end
})

 ix.option.Add("MultiCore", ix.type.bool, GetConVar("gmod_mcore_test"):GetInt(), {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("gmod_mcore_test 1")
                LocalPlayer():ConCommand("mat_queue_mode  -1")
                LocalPlayer():ConCommand("cl_threaded_bone_setup 1")
            elseif !newValue then
                LocalPlayer():ConCommand("gmod_mcore_test 0")
                LocalPlayer():ConCommand("mat_queue_mode  0")
                LocalPlayer():ConCommand("cl_threaded_bone_setup 0")
            end
        end
    })
    ix.option.Add("MapSpecular", ix.type.bool, GetConVar("mat_specular"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("mat_specular 1")
            else
                LocalPlayer():ConCommand("mat_specular 0")
            end
        end
    })
    ix.option.Add("MapBloomScale", ix.type.bool, GetConVar("mat_bloomscale"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("mat_bloomscale 1")
            elseif !newValue then
                LocalPlayer():ConCommand("mat_bloomscale 0")
            end
        end
    })
    ix.option.Add("DrawModelDecals", ix.type.bool, GetConVar("r_drawmodeldecals"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("r_drawmodeldecals 1")
            elseif !newValue then
                LocalPlayer():ConCommand("r_drawmodeldecals 0")
            end
        end
    })
    ix.option.Add("MipMapTextures", ix.type.bool, GetConVar("mat_mipmaptextures"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("mat_mipmaptextures 1")
            elseif !newValue then
                LocalPlayer():ConCommand("mat_mipmaptextures 0")
            end
        end
    })
    ix.option.Add("Skybox", ix.type.bool, GetConVar("r_3dsky"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("r_3dsky 1")
            elseif !newValue then
                LocalPlayer():ConCommand("r_3dsky 0")
            end
        end
    })
    ix.option.Add("AIExpressionOpt", ix.type.bool, GetConVar("ai_expression_optimization"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("ai_expression_optimization 1")
            elseif !newValue then
                LocalPlayer():ConCommand("ai_expression_optimization 0")
            end
        end
    })
    ix.option.Add("DetailDistance", ix.type.number, GetConVar("cl_detaildist"):GetInt(), {
        category = "Performance", 
        min = 0, 
        max = 10000,
        OnChanged = function(oldValue, newValue)
            if newValue and tonumber(newValue) then
                LocalPlayer():ConCommand("cl_detailfade " .. math.Clamp(newValue, 0, 10000))
            end
        end
    })
    ix.option.Add("DetailFade", ix.type.number, GetConVar("cl_detailfade"):GetInt(), {
        category = "Performance", 
        min = 0, 
        max = 10000,
        OnChanged = function(oldValue, newValue)
            if newValue and tonumber(newValue) then
                LocalPlayer():ConCommand("cl_detailfade " .. math.Clamp(newValue, 0, 10000))
            end
        end
    })

    ix.option.Add("Bloom", ix.type.bool, GetConVar("pp_bloom"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("pp_bloom 1")
            elseif !newValue then
                LocalPlayer():ConCommand("pp_bloom 0")
            end
        end
    })
    ix.option.Add("FilterLightMaps", ix.type.bool, GetConVar("mat_filterlightmaps"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("mat_filterlightmaps 1")
            elseif !newValue then
                LocalPlayer():ConCommand("mat_filterlightmaps 0")
            end
        end
    })
    ix.option.Add("FilterTextures", ix.type.bool, GetConVar("mat_filtertextures"):GetInt() ~= 0, {
        category = "Performance",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():ConCommand("mat_filtertextures 1")
            elseif !newValue then
                LocalPlayer():ConCommand("mat_filtertextures 0")
            end
        end
    })
    ix.option.Add("MaxDecals", ix.type.number, GetConVar("r_decals"):GetInt(), {
        category = "Performance",
        min = 0, 
        max = 10000,
        OnChanged = function(oldValue, newValue)
            if newValue and tonumber(newValue) then
                LocalPlayer():ConCommand("r_decals " .. math.Clamp(newValue, 0, 10000))
            end
        end
    })
    ix.option.Add("MaxModelDecals", ix.type.number, GetConVar("r_maxmodeldecal"):GetInt(), {
        category = "Performance",
        min = 0,
        max = 100,
        OnChanged = function(oldValue, newValue)
            if newValue and tonumber(newValue) then
                LocalPlayer():ConCommand("r_maxmodeldecal " .. math.Clamp(newValue, 0, 100))
            end
        end
    })
    ix.option.Add("MaxDynamicLights", ix.type.number, GetConVar("r_maxdlights"):GetInt(), {
        category = "Performance", 
        min = 0, 
        max = 100,
        OnChanged = function(oldValue, newValue)
            if newValue and tonumber(newValue) then
                LocalPlayer():ConCommand("r_maxdlights " .. math.Clamp(newValue, 0, 100))
            end
        end
    })
