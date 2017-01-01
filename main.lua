local PLH_RELIC_TOOLTIP_TYPE_PATTERN = _G.RELIC_TOOLTIP_TYPE:gsub('%%s', '(.+)')
local PLH_ITEM_LEVEL_PATTERN = _G.ITEM_LEVEL:gsub('%%d', '(%%d+)')

local frame = CreateFrame("Frame", "ItemLinkLevel");
frame:RegisterEvent("PLAYER_LOGIN");
local tooltip

function filter(self, event, message, user, ...)
	for itemLink in message:gmatch("|%x+|Hitem:.-|h.-|h|r") do
		local itemName, _, quality, _, _, itemType, itemSubType, _, itemEquipLoc, _, _, itemClassId, itemSubClassId = GetItemInfo(itemLink)
		if (quality ~= nil and quality >= SavedData.trigger_quality and (itemClassId == LE_ITEM_CLASS_WEAPON or itemClassId == LE_ITEM_CLASS_GEM or itemClassId == LE_ITEM_CLASS_ARMOR)) then
			local itemString = string.match(itemLink, "item[%-?%d:]+")
			local _, _, color = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
			local iLevel = PLH_GetRealILVL(itemLink)
			
			local attrs = {}
			if (SavedData.show_subtype and itemSubType ~= nil) then
				if (itemClassId == LE_ITEM_CLASS_ARMOR and itemSubClassId == 0) then
				-- don't display Miscellaneous for rings, necks and trinkets
				elseif (itemClassId == LE_ITEM_CLASS_ARMOR and itemEquipLoc == "INVTYPE_CLOAK") then
				-- don't display Cloth for cloaks
				else
					if (SavedData.subtype_short_format) then 
						table.insert(attrs, itemSubType:sub(0, 1)) 
					else 
						table.insert(attrs, itemSubType) 
					end
				end
				if (itemClassId == LE_ITEM_CLASS_GEM and itemSubClassId == LE_ITEM_ARMOR_RELIC) then 
					local relicType = PLH_GetRelicType(itemLink)
					table.insert(attrs, relicType)
				end
			end
			if (SavedData.show_equiploc and itemEquipLoc ~= nil and _G[itemEquipLoc] ~= nil) then table.insert(attrs, _G[itemEquipLoc]) end
			if (SavedData.show_ilevel and iLevel ~= nil) then 
				local txt = iLevel
				if (ItemHasSockets(itemLink)) then txt = txt .. "+S" end
				table.insert(attrs, txt)
			end
			
			local newItemName = itemName.." ("..table.concat(attrs, " ")..")"
			local newLink = "|cff"..color.."|H"..itemString.."|h["..newItemName.."]|h|r"
			
			message = string.gsub(message, escapeSearchString(itemLink), newLink)
		end
	end
	return false, message, user, ...
end

-- Inhibit Regular Expression magic characters ^$()%.[]*+-?)
function escapeSearchString(str)
	return str:gsub("(%W)","%%%1")
end

-- function borrowed from PersonalLootHelper
local function CreateEmptyTooltip()
    local tip = CreateFrame('GameTooltip')
	local leftside = {}
	local rightside = {}
	local L, R
	for i = 1, 6 do
		L, R = tip:CreateFontString(), tip:CreateFontString()
		L:SetFontObject(GameFontNormal)
		R:SetFontObject(GameFontNormal)
		tip:AddFontStrings(L, R)
		leftside[i] = L
		rightside[i] = R
	end
	tip.leftside = leftside
	tip.rightside = rightside
	return tip
end

-- function borrowed from PersonalLootHelper
function PLH_GetRelicType(item)
	local relicType = nil
	
	if item ~= nil then
		tooltip = tooltip or CreateEmptyTooltip()
		tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltip:ClearLines()
		tooltip:SetHyperlink(item)
		local t = tooltip.leftside[2]:GetText()

		local index = 1
		local t
		while not relicType and tooltip.leftside[index] do
			t = tooltip.leftside[index]:GetText()
			if t ~= nil then
				relicType = t:match(PLH_RELIC_TOOLTIP_TYPE_PATTERN)				
			end
			index = index + 1
		end

		tooltip:Hide()
	end
	
	return relicType
end

-- function borrowed from PersonalLootHelper
function PLH_GetRealILVL(item)
	local realILVL = nil
	
	if item ~= nil then
		tooltip = tooltip or CreateEmptyTooltip()
		tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
		tooltip:ClearLines()
		tooltip:SetHyperlink(item)
		local t = tooltip.leftside[2]:GetText()
		if t ~= nil then
--			realILVL = t:match('Item Level (%d+)')
			realILVL = t:match(PLH_ITEM_LEVEL_PATTERN)
		end
		-- ilvl can be in the 2nd or 3rd line dependng on the tooltip; if we didn't find it in 2nd, try 3rd
		if realILVL == nil then
			t = tooltip.leftside[3]:GetText()
			if t ~= nil then
--				realILVL = t:match('Item Level (%d+)')
				realILVL = t:match(PLH_ITEM_LEVEL_PATTERN)
			end
		end
		tooltip:Hide()
		
		-- if realILVL is still nil, we couldn't find it in the tooltip - try grabbing it from getItemInfo, even though
		--   that doesn't return upgrade levels
		if realILVL == nil then
			_, _, _, realILVL, _, _, _, _, _, _, _ = GetItemInfo(item)
		end
	end
	
	if realILVL == nil then
		return 0
	else		
		return tonumber(realILVL)
	end
end

function ItemHasSockets(itemLink)
	local result = false
	local tooltip = CreateFrame("GameTooltip", "ItemLinkLevelSocketTooltip", nil, "GameTooltipTemplate")
	tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltip:ClearLines()
	for i = 1, 30 do
		local texture = _G[tooltip:GetName().."Texture"..i]
		if texture then
			texture:SetTexture(nil)
		end
	end
	tooltip:SetHyperlink(itemLink)
	for i = 1, 30 do
		local texture = _G[tooltip:GetName().."Texture"..i]
		local textureName = texture and texture:GetTexture()

		if textureName then
			local canonicalTextureName = string.gsub(string.upper(textureName), "\\", "/")
			result = string.find(canonicalTextureName, escapeSearchString("ITEMSOCKETINGFRAME/UI-EMPTYSOCKET-"))
		end
	end
	return result
end

local function eventHandler(self, event, ...)
	if (SavedData == nil) then SavedData = {} end
	if (SavedData.trigger_loots == nil) then SavedData.trigger_loots = true end
	if (SavedData.trigger_chat == nil) then SavedData.trigger_chat = true end
	if (SavedData.trigger_quality == nil) then SavedData.trigger_quality = 3 end
	if (SavedData.show_subtype == nil) then SavedData.show_subtype = true end
	if (SavedData.subtype_short_format == nil) then SavedData.subtype_short_format = false end
	if (SavedData.show_equiploc == nil) then SavedData.show_equiploc = true end
	if (SavedData.show_ilevel == nil) then SavedData.show_ilevel = true end

	if (SavedData.trigger_loots) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", filter);
	end

	if (SavedData.trigger_chat) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filter);
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filter);
	end
		
	local panel = CreateFrame("Frame", "OptionsPanel", UIParent)
	panel.name = "ItemLinkLevel"

	local subtypeCheckBox = CreateFrame("CheckButton", "subtypeCheckBox", panel, "UICheckButtonTemplate")
	subtypeCheckBox:SetPoint("TOPLEFT",10, -30)
	subtypeCheckBox:SetChecked(SavedData.show_subtype)
	_G[subtypeCheckBox:GetName().."Text"]:SetText("Display armor/weapon type (Plate, Leather, ...)")
	subtypeCheckBox:SetScript("OnClick", function(self) SavedData.show_subtype = self:GetChecked() end)
	
	local subtypeShortCheckBox = CreateFrame("CheckButton", "subtypeShortCheckBox", panel, "UICheckButtonTemplate")
	subtypeShortCheckBox:SetPoint("TOPLEFT",30, -60)
	subtypeShortCheckBox:SetChecked(SavedData.subtype_short_format)
	_G[subtypeShortCheckBox:GetName().."Text"]:SetText("Short format (P for plate, L for leather, ...)")
	subtypeShortCheckBox:SetScript("OnClick", function(self) SavedData.subtype_short_format = self:GetChecked() end)

	local equipLocCheckbox = CreateFrame("CheckButton", "equipLocCheckbox", panel, "UICheckButtonTemplate")
	equipLocCheckbox:SetPoint("TOPLEFT",10, -90)
	equipLocCheckbox:SetChecked(SavedData.show_equiploc)
	_G[equipLocCheckbox:GetName().."Text"]:SetText("Display equip location (Head, Trinket, ...)")
	equipLocCheckbox:SetScript("OnClick", function(self) SavedData.show_equiploc = self:GetChecked() end)

	local iLevelCheckbox = CreateFrame("CheckButton", "iLevelCheckbox", panel, "UICheckButtonTemplate")
	iLevelCheckbox:SetPoint("TOPLEFT",10, -120)
	iLevelCheckbox:SetChecked(SavedData.show_ilevel)
	_G[iLevelCheckbox:GetName().."Text"]:SetText("Display item level")
	iLevelCheckbox:SetScript("OnClick", function(self) SavedData.show_ilevel = self:GetChecked() end)
	
	local triggerLootsCheckbox = CreateFrame("CheckButton", "triggerLootsCheckbox", panel, "UICheckButtonTemplate")
	triggerLootsCheckbox:SetPoint("TOPLEFT",10, -180)
	triggerLootsCheckbox:SetChecked(SavedData.trigger_loots)
	_G[triggerLootsCheckbox:GetName().."Text"]:SetText("Trigger on loots (requires restart)")
	triggerLootsCheckbox:SetScript("OnClick", function(self) SavedData.trigger_loots = self:GetChecked() end)
	
	local triggerChatCheckbox = CreateFrame("CheckButton", "triggerChatCheckbox", panel, "UICheckButtonTemplate")
	triggerChatCheckbox:SetPoint("TOPLEFT",10, -210)
	triggerChatCheckbox:SetChecked(SavedData.trigger_chat)
	_G[triggerChatCheckbox:GetName().."Text"]:SetText("Trigger on chat messages (requires restart)")
	triggerChatCheckbox:SetScript("OnClick", function(self) SavedData.trigger_chat = self:GetChecked() end)
	
	local triggerQualityLabel = panel:CreateFontString("triggerQualityLabel", panel, "GameFontNormal")
	triggerQualityLabel:SetText("Minimum trigger quality")
	triggerQualityLabel:SetPoint("TOPLEFT",10,-260)
	local triggerQualityValue = panel:CreateFontString("triggerQualityValue", panel, "GameFontNormal")
	local triggerQualitySlider = CreateFrame("Slider", "MySliderGlobalName", panel, "OptionsSliderTemplate")
	triggerQualitySlider:SetPoint("LEFT", triggerQualityLabel, "RIGHT", 10, 0)
	triggerQualitySlider:SetMinMaxValues(0, 6)
	triggerQualitySlider:SetValue(SavedData.trigger_quality)
	triggerQualitySlider:SetValueStep(1)
	getglobal(triggerQualitySlider:GetName() .. 'Low'):SetText(_G["ITEM_QUALITY0_DESC"])
	getglobal(triggerQualitySlider:GetName() .. 'High'):SetText(_G["ITEM_QUALITY6_DESC"])
	triggerQualitySlider:SetScript("OnValueChanged", function(self, value) 
		value = math.floor(value)
		SavedData.trigger_quality = value 
	    triggerQualityValue:SetText(_G["ITEM_QUALITY"..value.."_DESC"])
	end)
	
	triggerQualityValue:SetText(_G["ITEM_QUALITY"..SavedData.trigger_quality.."_DESC"])
	triggerQualityValue:SetPoint("LEFT", triggerQualitySlider, "RIGHT", 10, 0)

	InterfaceOptions_AddCategory(panel)
end
frame:SetScript("OnEvent", eventHandler);

