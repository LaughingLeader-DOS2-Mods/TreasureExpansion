RegisterProtectedOsirisListener("ItemEquipped", Data.OsirisEvents.ItemEquipped, "after", function(uuid, char)
	if ObjectExists(char) == 0 or ObjectExists(uuid) == 0 then
		return
	end
	uuid = StringHelpers.GetUUID(uuid)
	char = StringHelpers.GetUUID(char)
	local item = Ext.GetItem(uuid)
	local bonuses = TagHelper:GetItemBonuses(item)
	for tag,bonus in pairs(bonuses) do
		bonus:OnEquipped(char, uuid)
	end
end)

RegisterProtectedOsirisListener("ItemUnEquipped", Data.OsirisEvents.ItemUnEquipped, "after", function(uuid, char)
	if ObjectExists(char) == 0 or ObjectExists(uuid) == 0 then
		return
	end
	uuid = StringHelpers.GetUUID(uuid)
	char = StringHelpers.GetUUID(char)
	local item = Ext.GetItem(uuid)
	local bonuses = TagHelper:GetItemBonuses(item)
	for tag,bonus in pairs(bonuses) do
		bonus:OnUnEquipped(char, uuid)
	end
end)

function SendClientItemName(item, id)
	local name = item.DisplayName
	if not StringHelpers.IsNullOrEmpty(item.CustomDisplayName) then
		name = item.CustomDisplayName
	end
	if not id then
		Ext.BroadcastMessage("LLTREASURE_SaveItemName", Ext.JsonStringify({NetID=item.NetID, DisplayName=name}))
	else
		Ext.PostMessageToUser(id, "LLTREASURE_SaveItemName", Ext.JsonStringify({NetID=item.NetID, DisplayName=name}))
	end
end

local function SendClientEquippedItemNames(id)
	local db = Osi.DB_IsPlayer:Get(nil)
	if db and #db > 0 then
		local names = {}
		for i,v in pairs(db) do
			for _,slot in Data.VisibleEquipmentSlots:Get() do
				local uuid = CharacterGetEquippedItem(v[1], slot)
				if not StringHelpers.IsNullOrEmpty(uuid) then
					local item = Ext.GetItem(uuid)
					if item then
						local name = item.DisplayName
						if not StringHelpers.IsNullOrEmpty(item.CustomDisplayName) then
							name = item.CustomDisplayName
						end
						names[#names+1] = {NetID=item.NetID, DisplayName=name}
					end
				end
			end
		end
		if #names > 0 then
			if not id then
				Ext.BroadcastMessage("LLTREASURE_SaveItemName", Ext.JsonStringify(names))
			else
				Ext.PostMessageToUser(id, "LLTREASURE_SaveItemName", Ext.JsonStringify(names))
			end
		end
	end
end

RegisterListener("Initialized", function()
	SendClientEquippedItemNames()
end)

Ext.RegisterOsirisListener("UserConnected", 3, "after", function(id, username, profileId)
	SendClientEquippedItemNames(id)
end)

RegisterSkillListener("Cone_Flamebreath", function(skill, char, state, data)
	if state == SKILL_STATE.CANCEL then
		TurnCounter.CountDown("TestCounter", 2, CombatGetIDForCharacter(char),
		{
			Target = char,
			Position = Ext.GetCharacter(char).WorldPos
		})
	end
end)

--local SKILL_STATE = Mods.LeaderLib.SKILL_STATE
--local RegisterSkillListener = Mods.LeaderLib.RegisterSkillListener

local rangeReduction = {
	Modified = false,
	Keys = {
		SkillHeightRangeMultiplier = 0,
		HighGroundRangeMultiplier = 0,
	}
}

-- RegisterSkillListener({"Target_ChickenResurrect", "Projectile_EnemyFireball"}, function(skill, char, state, data)
-- 	if state == SKILL_STATE.PREPARE then
-- 		if not rangeReduction.Modified then
-- 			for k,_ in pairs(rangeReduction.Keys) do
-- 				rangeReduction.Keys[k] = Ext.ExtraData[k]
-- 				Ext.ExtraData[k] = 0
-- 			end
-- 			rangeReduction.Modified = true
-- 		end
-- 	elseif state == SKILL_STATE.CANCEL 
-- 	or state == SKILL_STATE.USED then
-- 		if rangeReduction.Modified then
-- 			for k,v in pairs(rangeReduction.Keys) do
-- 				Ext.ExtraData[k] = v
-- 			end
-- 		end
-- 		rangeReduction.Modified = false
-- 	end
-- end)

RegisterListener("OnNamedTurnCounter", "TestCounter", function(id, turn, lastTurns, finished, data)
	print(id, turn, lastTurns, finished, Ext.JsonStringify(data))
	if finished then
		local nextVit = math.min(100, CharacterGetHitpointsPercentage(data.Target) + 20)
		CharacterSetHitpointsPercentage(data.Target, nextVit)
	elseif turn == 1 and CharacterIsDead(data.Target) == 0 then
		ApplyStatus(data.Target, "HASTED", 12.0, 0, data.Target)
	end
end)

---@type CharacterData
local cdata = Classes.CharacterData

local BeachVoidling1 = cdata:Create("08348b3a-bded-4811-92ce-f127aa4310e0")

local function OnGameStarted(region, isEditor)
    if region == "FJ_FortJoy_Main" or SharedData.RegionData.Current == "FJ_FortJoy_Main" then
		--local level = Ext.Random(1,6)
        --fprint(LOGLEVEL.DEFAULT, "BeachVoidling1 level set to %s: %s", level, BeachVoidling1:SetLevel(level))
        fprint(LOGLEVEL.DEFAULT, "BeachVoidling1 NetID(%s)", BeachVoidling1.NetID)
    end
end

Ext.RegisterOsirisListener("GameStarted", Data.OsirisEvents.GameStarted, "after", OnGameStarted)
if Ext.IsDeveloperMode() then
    RegisterListener("LuaReset", OnGameStarted)
end