local piercingForwardVector = {}

local PiercingStab = ItemBonusManager:CreateBonus("LLTREASURE_PiercingStab",{
	---@param data HitData
	Apply = function(self, skill, caster, state, data)
		if state == SKILL_STATE.USED then
			piercingForwardVector[caster] = Common.CloneTable(Ext.GetCharacter(caster).Stats.Rotation)
		elseif state == SKILL_STATE.HIT then
			if ObjectIsCharacter(data.Target) == 1 then
				local target = Ext.GetCharacter(data.Target)

				local range = Ext.ExtraData.LLTREASURE_PiercingStab_Range or 2.0
				local radius = Ext.ExtraData.LLTREASURE_PiercingStab_Radius or 0.5
				local damageReduction = Ext.ExtraData.LLTREASURE_PiercingStab_DamageMult or 0.75
				local damageMult = Ext.Round(Ext.StatGetAttribute(skill, "Damage Multiplier") * damageReduction)

				--local tx,ty,tz = table.unpack(GameHelpers.Math.ExtendPositionWithForwardDirection(target, -range))
				local x,y,z = table.unpack(target.WorldPos)
				local tx,ty,tz = table.unpack(GameHelpers.Math.ExtendPositionWithForwardDirection(caster, range, x,y,z, piercingForwardVector[caster]))
				print(Common.Dump(piercingForwardVector[caster]))
				piercingForwardVector[caster] = nil
				local characters = Ext.GetCharactersAroundPosition(tz, ty, tz, radius)

				if not characters or #characters == 0 then
					characters = {}
					for i,v in pairs(Ext.GetAllCharacters(SharedData.RegionData.Current)) do
						if GetDistanceToPosition(v, tx, ty, tz) < radius then
							print(GetDistanceToPosition(v, tx, ty, tz))
							characters[#characters+1] = v
						end
					end
				end

				local targetEffects = {}
				for i,v in pairs(StringHelpers.Split(Ext.StatGetAttribute(skill, "TargetEffect"), ";")) do
					local effect,bone = table.unpack(StringHelpers.Split(v, ":"))
					if effect then
						targetEffects[#targetEffects+1] = {Effect = effect, Bone = bone or ""}
					end
				end

				for i,v in pairs(characters) do
					print(i,v,Ext.GetCharacter(v).DisplayName)
					if v ~= target.MyGuid and v ~= caster then
						if CharacterIsDead(v) == 0 and CharacterIsEnemy(v, caster) == 1 then
							GameHelpers.Damage.ApplySkillDamage(caster, v, skill, nil, nil, nil, true, nil, {
								["Damage Multiplier"] = damageMult
							})
							for _,fx in pairs(targetEffects) do
								PlayEffect(v, fx.Effect, fx.Bone)
							end
						end
					end
				end
			end
		end
	end
})
ItemBonusManager:RegisterToSkillListener(PiercingStab, {"Target_CripplingBlow", "Target_EnemyCripplingBlow"})

local TornadoVolley = ItemBonusManager:CreateBonus("LLTREASURE_TornadoVolley",{
	---@param data SkillEventData
	Apply = function(self, skill, caster, state, data)
		if state == SKILL_STATE.CAST then
			local character = Ext.GetCharacter(caster)
			local x,y,z = table.unpack(character.WorldPos)
			local handle = NRD_CreateTornado(caster, "Tornado_LLTREASURE_TornadoVolley", x, y, z, x, y, z)
			local radius = Ext.StatGetAttribute("Tornado_LLTREASURE_TornadoVolley", "HitRadius") or 2
			local pushDistance = Ext.ExtraData.LLTREASURE_TornadoVolley_PushDistance or 1.5
			for i,v in pairs(character:GetNearbyCharacters(radius)) do
				if v ~= caster and CharacterIsEnemy(caster, v) == 1 and CharacterIsDead(v) == 0 then
					local obj = Ext.GetGameObject(v)
					if obj and GameHelpers.CanForceMove(obj, character) then
						GameHelpers.ForceMoveObject(character, obj, pushDistance)
					end
				end
			end
		end
		-- elseif state == SKILL_STATE.HIT then
		-- 	print(caster, data.Target)
		-- 	if data.Target ~= caster and CharacterIsEnemy(caster, data.Target) == 1 then
		-- 		local character = Ext.GetCharacter(caster)
		-- 		local obj = Ext.GetGameObject(data.Target)
		-- 		print("GameHelpers.CanForceMove(obj, character)", GameHelpers.CanForceMove(obj, character))
		-- 		if obj and GameHelpers.CanForceMove(obj, character) then
		-- 			GameHelpers.ForceMoveObject(character, obj, 2.0)
		-- 		end
		-- 	end
		-- end
	end
})

ItemBonusManager:IgnoreTooltipSkill("Tornado_LLTREASURE_TornadoVolley")
ItemBonusManager:RegisterToSkillListener(TornadoVolley, "Shout_RecoverArmour")
--ItemBonusManager:RegisterToSkillListener(TornadoVolley, {"Shout_RecoverArmour", "Tornado_LLTREASURE_TornadoVolley"})