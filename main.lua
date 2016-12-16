local frame = CreateFrame("Frame", "ItemLinkLevel");
frame:RegisterEvent("PLAYER_LOGIN");

function filter(self, event, message, user, ...)
	for itemLink in message:gmatch("|%x+|Hitem:.-|h.-|h|r") do
		local itemName, _, _, iLevel, _, itemType, itemSubType, _, itemEquipLoc, _, _, itemClassId, itemSubClassId = GetItemInfo(itemLink)
		if (itemClassId == 2 or itemClassId == 3 or itemClassId == 4) then
			local itemString = string.match(itemLink, "item[%-?%d:]+")
			local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
			
			local attrs = {}
			if (SavedData.show_subtype and itemSubType ~= nil) then table.insert(attrs, itemSubType) end
			if (SavedData.show_equiploc and itemEquipLoc ~= nil and _G[itemEquipLoc] ~= nil) then table.insert(attrs, _G[itemEquipLoc]) end
			if (SavedData.show_ilevel and iLevel ~= nil) then table.insert(attrs, iLevel) end
			
			local newItemName = itemName.." ("..table.concat(attrs, " ")..")"
			local newLink = "|cff"..Color.."|H"..itemString.."|h["..newItemName.."]|h|r"
			
			message = string.gsub(message, escapeSearchString(itemLink), newLink)
		end
	end
	return false, message, user, ...
end

-- Inhibit Regular Expression magic characters ^$()%.[]*+-?)
function escapeSearchString(str)
	return str:gsub("(%W)","%%%1")
end

local function eventHandler(self, event, ...)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filter);
	ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", filter);
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
	
	if (SavedData == nil) then 
		SavedData = {}
		SavedData.show_subtype = true
		SavedData.show_equiploc = true
		SavedData.show_ilevel = true
	end
	
	local panel = CreateFrame("Frame", "OptionsPanel", UIParent)
	panel.name = "ItemLinkLevel"

	local subtypeCheckBox = CreateFrame("CheckButton", "subtypeCheckBox", panel, "UICheckButtonTemplate")
	subtypeCheckBox:SetPoint("TOPLEFT",10, -30)
	subtypeCheckBox:SetChecked(SavedData.show_subtype)
	_G[subtypeCheckBox:GetName().."Text"]:SetText("Display armor/weapon type (Plate, Leather, ...)")
	subtypeCheckBox:SetScript("OnClick", function(self) SavedData.show_subtype = self:GetChecked() end)

	local equipLocCheckbox = CreateFrame("CheckButton", "equipLocCheckbox", panel, "UICheckButtonTemplate")
	equipLocCheckbox:SetPoint("TOPLEFT",10, -60)
	equipLocCheckbox:SetChecked(SavedData.show_equiploc)
	_G[equipLocCheckbox:GetName().."Text"]:SetText("Display equip location (Head, Trinket, ...)")
	equipLocCheckbox:SetScript("OnClick", function(self) SavedData.show_equiploc = self:GetChecked() end)

	local iLevelCheckbox = CreateFrame("CheckButton", "iLevelCheckbox", panel, "UICheckButtonTemplate")
	iLevelCheckbox:SetPoint("TOPLEFT",10, -90)
	iLevelCheckbox:SetChecked(SavedData.show_ilevel)
	_G[iLevelCheckbox:GetName().."Text"]:SetText("Display item level")
	iLevelCheckbox:SetScript("OnClick", function(self) SavedData.show_ilevel = self:GetChecked() end)

	InterfaceOptions_AddCategory(panel)
end
frame:SetScript("OnEvent", eventHandler);

