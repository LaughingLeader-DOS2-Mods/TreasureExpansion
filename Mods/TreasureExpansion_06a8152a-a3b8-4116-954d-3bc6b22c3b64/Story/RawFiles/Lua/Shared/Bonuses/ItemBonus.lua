---@class ItemBonusCallbacks:table
local defaultCallbacks = {
	---@type ItemBonusConditionCheckCallback
	CanApply = nil,
	---@type ItemBonusActionCallback
	Apply = nil,
	---@type fun(self:ItemBonus, char:string, item:string):void
	Equip = nil,
	---@type fun(self:ItemBonus, char:string, item:string):void
	UnEquip = nil
}

---Basically a wrapper around a function to see if a bonus can be applied, and a function to call if it can.
---Requires the ItemBonusManager to register this bonus to the related event or skill.
---@class ItemBonus:table
---@field Type string
---@field Tag string
---@field Callbacks ItemBonusCallbacks
---@field Skills table<string,boolean>

---@type ItemBonus
local ItemBonus = {
	Type = "ItemBonus",
	Tag = "",
	Skills = {}
}
ItemBonus.__index = ItemBonus

---@alias ItemBonusConditionCheckCallback fun(self:ItemBonus, event:string, ...):boolean
---@alias ItemBonusActionCallback fun(self:ItemBonus, event:string, ...):void

---@param tag string
---@param callbacks ItemBonusCallbacks
---@param params table
---@return ItemBonus
function ItemBonus:Create(tag, callbacks, params)
	local this =
	{
		Tag = tag or "",
		IsSkillBonus = false,
		DisplayName = "",
		Description = "",
		Callbacks = {},
		Skills = {},
	}
	if Ext.IsServer() then
		---@type ItemBonus
		this.Callbacks = Common.CloneTable(defaultCallbacks)

		if callbacks then
			for k,v in pairs(callbacks) do
				this.Callbacks[k] = v
			end
		end
	end
	if params then
		for k,v in pairs(params) do
			this[k] = v
		end
	end
	setmetatable(this, self)
	return this
end

local affectsSkillsText = Classes.TranslatedString:CreateFromKey("LLTREASURE_Tooltip_TagSkillsHeader", "<font color='#CCAAFF'>Alters Skill:<br>[1]</font>")
local affectsSkillsTextPlural = Classes.TranslatedString:CreateFromKey("LLTREASURE_Tooltip_TagSkillsHeaderPlural", "<font color='#CCAAFF'>Alters Skills:<br>[1]</font>")
local defaultColor = "#AACC88"
local fontStyle = "<font color='%s'>%s</font>"

---Get the display name.
---@return string
function ItemBonus:GetDisplayName(tag, tooltipType, character, itemDisplayNames)
	if self.DisplayName == "" or character then
		self.DisplayName = GameHelpers.Tooltip.ReplacePlaceholders(GameHelpers.GetStringKeyText(self.Tag, self.Tag))
	end
	local color = defaultColor
	for skill,b in pairs(self.Skills) do
		local ability = Ext.StatGetAttribute(skill, "Ability")
		if not StringHelpers.IsNullOrWhitespace(ability) then
			color = Data.Colors.Ability[ability] or defaultColor
		end
	end
	return string.format(fontStyle, color, self.DisplayName)
end

local function GetSkillName(skill)
	local name = Ext.GetTranslatedStringFromKey(Ext.StatGetAttribute(skill, "DisplayName"))
	if not StringHelpers.IsNullOrWhitespace(name) then
		return name
	end
end

---@return EclItem
local function GetTaggedItem(tag, character)
	for i,slot in Data.VisibleEquipmentSlots:Get() do
		local uuid = character:GetItemBySlot(slot)
		if uuid then
			local item = Ext.GetItem(uuid)
			if item then
				if TagHelper:ItemHasTag(item, tag) then
					return item
				end
			end
		end
	end
	return nil
end

---Get the display name.
---@param character EsvCharacter|EclCharacter|nil
---@return string
function ItemBonus:GetDescription(tag, tooltipType, character, itemDisplayNames)
	if self.Description == "" then
		local descKey = string.format("%s_Description", self.Tag)
		self.Description = GameHelpers.Tooltip.ReplacePlaceholders(GameHelpers.GetStringKeyText(descKey, descKey))
	end
	local desc = self.Description
	if tooltipType == "Item" then
		local skills = {}
		local uniqueNames = {}
		for skill,b in pairs(self.Skills) do
			local name = GetSkillName(skill)
			if name and not uniqueNames[name] then
				skills[#skills+1] = name
			end
			uniqueNames[name] = true
		end
		local count = #skills
		if count > 0 then
			if count > 1 then
				desc = self.Description .. "<br>" .. affectsSkillsTextPlural:ReplacePlaceholders(StringHelpers.Join("<br>", skills, true))
			else
				desc = self.Description .. "<br>" .. affectsSkillsText:ReplacePlaceholders(skills[1])
			end
		end
	end
	if tooltipType == "Skill" and character then
		local item = GetTaggedItem(self.Tag, character)
		if item and itemDisplayNames[item.NetID] then
			desc = string.format("%s<br>(%s)", desc, itemDisplayNames[item.NetID])
		end
	end
	return string.format(fontStyle, defaultColor, desc)
end

---Get the display name and description according to the tag.
---@param character EsvCharacter|EclCharacter|nil
---@return string,string
function ItemBonus:GetText(character, tooltipType, itemDisplayNames)
	local displayName = self:GetDisplayName(self.Tag, tooltipType, character, itemDisplayNames)
	local description = self:GetDescription(self.Tag, tooltipType, character, itemDisplayNames)
	
	return displayName,description
end

---Get the display name and description according to the tag.
---@param character EsvCharacter|EclCharacter|nil
---@return string,string
function ItemBonus:GetSortingValue()
	local displayName,desc = self:GetText()
	return string.lower(displayName)
end

function ItemBonus:CanApply(...)
	if self.Callbacks.CanApply then
		local b,canApply = xpcall(self.Callbacks.CanApply, debug.traceback, self, ...)
		if b then
			return canApply
		else
			Ext.PrintError(canApply)
		end
		return false
	end
	return true
end

function ItemBonus:Apply(...)
	if self.Callbacks.Apply then
		local b,err = xpcall(self.Callbacks.Apply, debug.traceback, self, ...)
		if not b then
			Ext.PrintError(err)
		end
	end
end

function ItemBonus:OnEquipped(char, item)
	SetTag(char, self.Tag)
	if self.Callbacks.Equip then
		local b,err = xpcall(self.Callbacks.Equip, debug.traceback, self, char, item)
		if not b then
			Ext.PrintError(err)
		end
	end
	SendClientItemName(Ext.GetItem(item))
end

function ItemBonus:OnUnEquipped(char, item)
	if self.Callbacks.UnEquip then
		local b,err = xpcall(self.Callbacks.UnEquip, debug.traceback, self, char, item)
		if not b then
			Ext.PrintError(err)
		end
	end
	if not TagHelper:HasEquippedItemWithTag(char, self.Tag) then
		ClearTag(char, self.Tag)
	end
end

return ItemBonus