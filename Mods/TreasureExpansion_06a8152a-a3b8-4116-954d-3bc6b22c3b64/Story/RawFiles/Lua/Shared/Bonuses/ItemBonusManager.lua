if ItemBonusManager == nil then
	ItemBonusManager = {}
end

ItemBonusManager.__index = ItemBonusManager

---@type ItemBonus
local ItemBonus = Ext.Require("Shared/Bonuses/ItemBonus.lua")
ItemBonusManager.ItemBonusClass = ItemBonus

---@type table<string, ItemBonus>
ItemBonusManager.ItemBonuses = {}
---@type table<string, table<string,ItemBonus>>
ItemBonusManager.SkillBonusTags = {}

if Ext.IsServer() then
	ItemBonusManager.EventListeners = {}
	ItemBonusManager.SkillListeners = {}
	---@type table<string,ItemBonus[]>
	ItemBonusManager.EventItemBonuses = {}
	---@type table<string,ItemBonus[]>
	ItemBonusManager.SkillItemBonuses = {}
	
	function ItemBonusManager:OnEvent(event, ...)
		local bonuses = self.EventItemBonuses[event]
		if bonuses then
			local length = #bonuses
			if length > 0 then
				for i=1,length do
					local bonus = bonuses[i]
					if bonus:CanApply(event, ...) then
						bonus:Apply(event, ...)
					end
				end
			end
		end
	end
	function ItemBonusManager:OnSkill(skill, ...)
		local bonuses = self.SkillItemBonuses[skill]
		if bonuses then
			local length = #bonuses
			if length > 0 then
				for i=1,length do
					local bonus = bonuses[i]
					if bonus then
						print(skill, bonus.Tag)
						if bonus:CanApply(skill, ...) then
							bonus:Apply(skill, ...)
						end
					end
				end
			end
		end
	end
	
	---@param event string The osiris event to listen for.
	---@param bonus ItemBonus
	function ItemBonusManager:RegisterToOsirisEvent(bonus, event)
		if self.EventListeners[event] == nil then
			local arity = Data.OsirisEvents[event]
			if arity then
				self.EventListeners[event] = function(...)
					self:OnEvent(event, ...)
				end
				Ext.RegisterOsirisListener(event, arity, "after", self.EventListeners[event])
			end
		end
		if self.EventItemBonuses[event] == nil then
			self.EventItemBonuses[event] = {}
		end
		table.insert(self.EventItemBonuses[event], bonus)
	end
	
	---@param event string The LeaderLib event to listen for.
	---@param bonus ItemBonus
	function ItemBonusManager:RegisterToLeaderLibEvent(bonus, event, extraParam)
		if self.EventListeners[event] == nil then
			self.EventListeners[event] = function(...)
				self:OnEvent(event, ...)
			end
			LeaderLib.RegisterListener(event, self.EventListeners[event], extraParam)
		end
		if self.EventItemBonuses[event] == nil then
			self.EventItemBonuses[event] = {}
		end
		table.insert(self.EventItemBonuses[event], bonus)
	end
	
	---@param bonus ItemBonus
	---@param skill string|string[]
	---@param hideFromTooltip boolean
	function ItemBonusManager:RegisterToSkillListener(bonus, skill, hideFromTooltip)
		if not bonus.Callbacks.CanApply then
			bonus.Callbacks.CanApply = function(self, skill, caster, state, data)
				return IsTagged(caster, bonus.Tag) == 1
			end
		end
		if type(skill) == "table" then
			for i,v in pairs(skill) do
				self:RegisterToSkillListener(bonus, v)
			end
		else
			if self.SkillListeners[skill] == nil then
				self.SkillListeners[skill] = function(usedSkill, ...)
					self:OnSkill(usedSkill, ...)
				end
				LeaderLib.RegisterSkillListener(skill, self.SkillListeners[skill])
			end
			if self.SkillItemBonuses[skill] == nil then
				self.SkillItemBonuses[skill] = {}
			end
			table.insert(self.SkillItemBonuses[skill], bonus)
		end
	end
	
	---@param bonus ItemBonus
	---@param event string|string[]
	function ItemBonusManager:RegisterToEvent(bonus, event)
		if type(event) == "table" then
			for i,v in pairs(event) do
				if LeaderLib.Listeners[v] then
					self:RegisterToLeaderLibEvent(bonus, v)
				elseif Data.OsirisEvents[v] then
					self:RegisterToOsirisEvent(bonus, v)
				else
					Ext.PrintError(string.format("[SEUO:ItemBonus:Create] Event %s does not exist.", v))
				end
			end
		elseif type(event) == "string" then
			if LeaderLib.Listeners[event] then
				self:RegisterToLeaderLibEvent(bonus, event)
			elseif Data.OsirisEvents[event] then
				self:RegisterToOsirisEvent(bonus, event)
			else
				Ext.PrintError(string.format("[SEUO:ItemBonus:Create] Event %s does not exist.", event))
			end
		end
	end

	function ItemBonusManager:IgnoreTooltipSkill(skill) end
else
	ItemBonusManager.IgnoreSkillFromTooltip = {}
	
	---@param event string The osiris event to listen for.
	---@param bonus ItemBonus
	function ItemBonusManager:RegisterToOsirisEvent(bonus, event) end
	
	---@param event string The LeaderLib event to listen for.
	---@param bonus ItemBonus
	function ItemBonusManager:RegisterToLeaderLibEvent(bonus, event, extraParam) end
	
	function ItemBonusManager:IgnoreTooltipSkill(skill)
		self.SkillBonusTags[skill] = nil
		self.IgnoreSkillFromTooltip[skill] = true
	end

	---@param bonus ItemBonus
	---@param skill string|string[]
	---@param hideFromTooltip boolean
	function ItemBonusManager:RegisterToSkillListener(bonus, skill, hideFromTooltip)
		if hideFromTooltip then
			return
		end
		if type(skill) == "table" then
			for i,v in pairs(skill) do
				self:RegisterToSkillListener(bonus, v)
			end
		else
			if self.IgnoreSkillFromTooltip[skill] then
				return
			end
			bonus.Skills[skill] = true
			if not self.SkillBonusTags[skill] then
				self.SkillBonusTags[skill] = {}
			end
			self.SkillBonusTags[skill][bonus.Tag] = bonus
		end
	end
	
	---@param bonus ItemBonus
	---@param event string|string[]
	function ItemBonusManager:RegisterToEvent(bonus, event) end
end

---@param skill string
---@param sort boolean
---@param character EsvCharacter|EclCharacter
---@return ItemBonus[]|table<string,ItemBonus>|nil
function ItemBonusManager:GetSkillBonuses(skill, sort, character)
	local bonuses = self.SkillBonusTags[skill]
	if bonuses then
		if sort or character then
			local tbl = {}
			for tag,bonus in pairs(bonuses) do
				if not character or (character and TagHelper:HasEquippedItemWithTag(character, tag)) then
					tbl[#tbl+1] = bonus
				end
			end
			if sort then
				---@param a ItemBonus
				---@param b ItemBonus
				table.sort(tbl, function(a,b)
					return a:GetSortingValue() < b:GetSortingValue()
				end)
			end
			return tbl
		else
			return bonuses
		end
	end
	return nil
end

---@param tag string
---@param callbacks ItemBonusCallbacks
---@param params table<string,any>
---@return ItemBonus
function ItemBonusManager:CreateBonus(tag, callbacks, params)
	local bonus = ItemBonus:Create(tag, callbacks, params)
	self.ItemBonuses[tag] = bonus
	return bonus
end

if Ext.IsClient() then
	function ItemBonusManager:RegisterTags()
		for tag,bonus in pairs(self.ItemBonuses) do
			--local name,desc = bonus:GetText()
			LeaderLib.UI.RegisterItemTooltipTag(tag, function(...) return bonus:GetDisplayName(...) end, function(...) return bonus:GetDescription(...) end)
			--print("LeaderLib.UI.RegisterItemTooltipTag", tag, name, desc)
		end
	end
	Ext.RegisterListener("SessionLoaded", function()
		ItemBonusManager:RegisterTags()
	end)
	RegisterListener("LuaReset", function()
		ItemBonusManager:RegisterTags()
	end)
end