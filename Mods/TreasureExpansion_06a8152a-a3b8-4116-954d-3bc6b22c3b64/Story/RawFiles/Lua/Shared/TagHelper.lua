if not TagHelper then
	TagHelper = {}
end

---@param item EsvItem|EclItem
---@param tag string
---@return boolean
function TagHelper:ItemHasTag(item, tag)
	if not item or not tag then
		return false
	end
	if item:HasTag(tag) then
		return true
	end
	if not GameHelpers.Item.IsObject(item) then
		if not StringHelpers.IsNullOrWhitespace(item.Stats.Tags) and Common.TableHasValue(StringHelpers.Split(item.Stats.Tags, ";"), tag) then
			return true
		end
		-- for _,v in pairs(item:GetDeltaMods()) do
		-- 	local deltamod = Ext.GetDeltaMod(v, item.ItemType)
		-- 	if deltamod then
		-- 		for _,boost in pairs(deltamod.Boosts) do
		-- 			local tags = Ext.StatGetAttribute(boost.Boost, "Tags")
		-- 			if not StringHelpers.IsNullOrWhitespace(tags) and Common.TableHasValue(StringHelpers.Split(tags, ";"), tag) then
		-- 				return true
		-- 			end
		-- 		end
		-- 	end
		-- end
		for i,v in pairs(item.Stats.DynamicStats) do
			if not StringHelpers.IsNullOrWhitespace(v.ObjectInstanceName) then
				local tags = Ext.StatGetAttribute(v.ObjectInstanceName, "Tags")
				if not StringHelpers.IsNullOrWhitespace(tags) and Common.TableHasValue(StringHelpers.Split(tags, ";"), tag) then
					return true
				end
			end
		end
	end
	return false
end

---@param char EsvCharacter|EclCharacter
---@return table<string,EsvItem|EclItem>
function TagHelper:GetEquipment(char)
	local tbl = {}
	local isServer = Ext.IsServer()
	for _,slot in Data.VisibleEquipmentSlots:Get() do
		if isServer then
			local uuid = CharacterGetEquippedItem(char.MyGuid, slot)
			if not StringHelpers.IsNullOrEmpty(uuid) then
				local item = Ext.GetItem(uuid)
				if item then
					tbl[slot] = item
				end
			end
		else
			local uuid = char:GetItemBySlot(slot)
			if not StringHelpers.IsNullOrEmpty(uuid) then
				local item = Ext.GetItem(uuid)
				if item then
					tbl[slot] = item
				end
			end
		end
	end
	return tbl
end

---@param char string|EclCharacter
---@param tag string
---@param equipment table<string, EsvItem>
---@return boolean
function TagHelper:HasEquippedItemWithTag(char, tag, equipment)
	if equipment then
		for slot,item in pairs(equipment) do
			if self:ItemHasTag(item, tag) then
				return true
			end
		end
	else
		local isServer = Ext.IsServer()
		for _,slot in Data.VisibleEquipmentSlots:Get() do
			if isServer then
				local uuid = CharacterGetEquippedItem(char, slot)
				if not StringHelpers.IsNullOrEmpty(uuid) then
					local item = Ext.GetItem(uuid)
					if self:ItemHasTag(item, tag) then
						return true
					end
				end
			else
				local uuid = char:GetItemBySlot(slot)
				if not StringHelpers.IsNullOrEmpty(uuid) then
					local item = Ext.GetItem(uuid)
					if item and self:ItemHasTag(item, tag) then
						return true
					end
				end
			end
		end
	end
	return false
end

---@param char string|EclCharacter
---@param bonuses string
---@return table<string,boolean>
function TagHelper:GetActiveBonusTags(char, bonuses)
	local isServer = Ext.IsServer()
	for _,slot in Data.VisibleEquipmentSlots:Get() do
		if isServer then
			local uuid = CharacterGetEquippedItem(char, slot)
			if not StringHelpers.IsNullOrEmpty(uuid) then
				local item = Ext.GetItem(uuid)
				if self:ItemHasTag(item, tag) then
					return true
				end
			end
		else
			local uuid = char:GetItemBySlot(slot)
			if not StringHelpers.IsNullOrEmpty(uuid) then
				local item = Ext.GetItem(uuid)
				if item and self:ItemHasTag(item, tag) then
					return true
				end
			end
		end
	end
	return false
end

---@param item EsvItem
---@return table<string,ItemBonus>
function TagHelper:GetItemBonuses(item)
	local bonuses = {}
	for tag,bonus in pairs(ItemBonusManager.ItemBonuses) do
		if self:ItemHasTag(item, tag) then
			bonuses[tag] = bonus
		end
	end
	return bonuses
end