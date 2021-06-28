Ext.Require("Shared/_InitShared.lua")
Ext.Require("Server/EquipEvents.lua")

-- Ext.RegisterListener("ModuleLoading", function()

-- end)
-- Ext.RegisterListener("SessionLoading", function()

-- end)
-- Ext.RegisterListener("SessionLoaded", function()

-- end)


Ext.RegisterConsoleCommand("llte_tagtest", function(cmd)
	local host = CharacterGetHostCharacter()
	local item = GameHelpers.Item.CreateItemByStat("WPN_Spear", {
		DeltaMods = {
			"LLTREASURE_Boost_Weapon_Spear_PiercingStab"
		}
	})
	if item then
		ItemToInventory(item, host, 1, 1, 1)
		-- StartOneshotTimer("", 250, function()
		-- 	CharacterEquipItem(host, item)
		-- 	StartOneshotTimer("", 250, function()
		-- 		print("Is tagged with LLTREASURE_TagTest:", Ext.GetCharacter(host):HasTag("LLTREASURE_TagTest"))
		-- 	end)
		-- end)
	else
		error("Failed to create item from WPN_Staff_Air stat")
	end
end)

Ext.RegisterConsoleCommand("llte_tagcheck", function(cmd)
	local host = Ext.GetCharacter(CharacterGetHostCharacter())
	print("Is tagged with LLTREASURE_TagTest:", host:HasTag("LLTREASURE_TagTest"))
	local weapon = Ext.GetItem(CharacterGetEquippedWeapon(host.MyGuid))
	if weapon then
		for i,v in pairs(weapon:GetDeltaMods()) do
			print(i,v)
			local deltamod = Ext.GetDeltaMod(v, "Weapon")
			if deltamod then
				local stat = Ext.GetStat(deltamod.Boosts[1].Boost)
				if stat then
					print(stat.Name, "Tags:", stat.Tags)
				end
			end
		end
	end
end)

Ext.RegisterConsoleCommand("llte_radiustest", function(cmd)
	local host = Ext.GetCharacter(CharacterGetHostCharacter())
	local x,y,z = table.unpack(host.WorldPos)
	local radius = 6
	local characters = host:GetNearbyCharacters(radius)
	local characters2 = Ext.GetCharactersAroundPosition(x,y,z,radius)
	local characters3 = {}
	for i,v in pairs(Ext.GetAllCharacters(SharedData.RegionData.Current)) do
		if GetDistanceToPosition(v, x, y, z) < radius then
			characters3[#characters3+1] = v
		end
	end

	local function printChar(i,v)
		return string.format("[%s](%sm) = %s (%s)", i, GameHelpers.Math.Round(GetDistanceToPosition(v, x, y, z), 2), Ext.GetCharacter(v).DisplayName, v)
	end

	fprint(LOGLEVEL.TRACE, "[llte_radiustest] x(%s) y(%s) z(%s)", x, y, z)
	print("")
	fprint(LOGLEVEL.TRACE, "[EsvCharacter:GetNearbyCharacters(%sm)] Total(%s)\n%s", radius, characters and #characters or "nil", StringHelpers.Join("\n", characters, false, printChar))
	print("")
	fprint(LOGLEVEL.TRACE, "[Ext.GetCharactersAroundPosition(%sm)] Total(%s)\n%s", radius, characters2 and #characters2 or "nil", StringHelpers.Join("\n", characters2, false, printChar))
	print("")
	fprint(LOGLEVEL.TRACE, "[Ext.GetAllCharacters(%sm)] Total(%s)\n%s", radius, characters3 and #characters3 or "nil", StringHelpers.Join("\n", characters3, false, printChar))
end)