---@type table<integer,string>
local ItemDisplayNames = {}

---@param item EsvItem
---@param tooltip TooltipData
local function OnItemTooltip(item, tooltip)
	for tag,bonus in pairs(ItemBonusManager.ItemBonuses) do
		if TagHelper:ItemHasTag(item, tag) then
			local displayName,description = bonus:GetText()
			tooltip:AppendElement({
				Type="Tags",
				Label = displayName,
				Value = description,
				Warning = ""
			})
		end
	end
end

---@param character EclCharacter
---@param skill string
---@param tooltip TooltipData
local function OnSkillTooltip(character, skill, tooltip)
	local bonuses = ItemBonusManager:GetSkillBonuses(skill, true, character)
	if bonuses then
		local descriptionElement = tooltip:GetElement("SkillDescription") or {Type="SkillDescription", Label=""}
		for i=1,#bonuses do
			local bonus = bonuses[i]
			local displayName,description = bonus:GetText(character, "Skill", ItemDisplayNames)
			descriptionElement.Label = descriptionElement.Label .. string.format("<br>%s<br>%s", displayName, description)
		end
	end
end

--Game.Tooltip.RegisterListener("Item", nil, OnItemTooltip)
Game.Tooltip.RegisterListener("Skill", nil, OnSkillTooltip)

Ext.RegisterNetListener("LLTREASURE_SaveItemName", function(cmd, payload)
	local data = Common.JsonParse(payload)
	if data then
		if #data > 0 then
			for i,v in pairs(data) do
				ItemDisplayNames[v.NetID] = v.DisplayName
			end
		else
			ItemDisplayNames[data.NetID] = data.DisplayName
		end
	end
end)