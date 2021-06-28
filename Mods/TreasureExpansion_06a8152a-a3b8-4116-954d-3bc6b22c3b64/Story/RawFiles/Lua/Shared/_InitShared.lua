Mods.LeaderLib.ImportUnsafe(Mods.LLTreasureExpansion)

Ext.Require("Shared/TagHelper.lua")
Ext.Require("Shared/Bonuses/ItemBonusManager.lua")
Ext.Require("Shared/Bonuses/SkillBonuses.lua")

local defaultFrequency = 10

---@class DeltaModStat
---@field ModifierType string
---@field Name string

local function AdjustDeltamodFrequency(reset)
	---@type DeltaModStat[]
	local deltamods = Ext.GetStatEntries("DeltaMod")
	for i,v in pairs(deltamods) do
		if not string.find(v.Name, "LLTREASURE", nil, true) then
			local deltamod = Ext.GetDeltaMod(v.Name, v.ModifierType)
			if deltamod and (deltamod.Frequency == 1 or reset) then
				deltamod.Frequency = defaultFrequency
				Ext.UpdateDeltaMod(deltamod)
			end
		end
	end
end

Ext.RegisterListener("StatsLoaded", function()
	AdjustDeltamodFrequency()
end)

RegisterListener("LuaReset", function()
	AdjustDeltamodFrequency(true)
end)