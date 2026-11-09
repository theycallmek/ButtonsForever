local addonName, ns = ...
if UnitClassBase("player") ~= "MAGE" then return end
local L = ns.L

-- Spell/item IDs are Classic Era's; Forever uses the same ones. IDs keep the addon working in every language.
local TELEPORTS = {
	3561, -- Teleport: Stormwind
	3562, -- Teleport: Ironforge
	3565, -- Teleport: Darnassus
	3567, -- Teleport: Orgrimmar
	3563, -- Teleport: Undercity
	3566, -- Teleport: Thunder Bluff
	1297659, -- Teleport: Dalaran (Forever-only)
}
local PORTALS = {
	10059, -- Portal: Stormwind
	11416, -- Portal: Ironforge
	11419, -- Portal: Darnassus
	11417, -- Portal: Orgrimmar
	11418, -- Portal: Undercity
	11420, -- Portal: Thunder Bluff
}
local RUNE_TELE = 17031 -- Rune of Teleportation (item)
local RUNE_PORT = 17032 -- Rune of Portals (item)

-- spell = conjure spell, item = what it makes, level = that item's required level. Lowest rank first.
local WATER_RANKS = {
	{ spell = 5504, item = 5350, level = 1 }, -- Conjure Water (Rank 1) -> Conjured Water
	{ spell = 5505, item = 2288, level = 5 }, -- Conjure Water (Rank 2) -> Conjured Fresh Water
	{ spell = 5506, item = 2136, level = 15 }, -- Conjure Water (Rank 3) -> Conjured Purified Water
	{ spell = 6127, item = 3772, level = 25 }, -- Conjure Water (Rank 4) -> Conjured Spring Water
	{ spell = 10138, item = 8077, level = 35 }, -- Conjure Water (Rank 5) -> Conjured Mineral Water
	{ spell = 10139, item = 8078, level = 45 }, -- Conjure Water (Rank 6) -> Conjured Sparkling Water
	{ spell = 10140, item = 8079, level = 55 }, -- Conjure Water (Rank 7) -> Conjured Crystal Water
}
local FOOD_RANKS = {
	{ spell = 587, item = 5349, level = 1 }, -- Conjure Food (Rank 1) -> Conjured Muffin
	{ spell = 597, item = 1113, level = 5 }, -- Conjure Food (Rank 2) -> Conjured Bread
	{ spell = 990, item = 1114, level = 15 }, -- Conjure Food (Rank 3) -> Conjured Rye
	{ spell = 6129, item = 1487, level = 25 }, -- Conjure Food (Rank 4) -> Conjured Pumpernickel
	{ spell = 10144, item = 8075, level = 35 }, -- Conjure Food (Rank 5) -> Conjured Sourdough
	{ spell = 10145, item = 8076, level = 45 }, -- Conjure Food (Rank 6) -> Conjured Sweet Roll
	{ spell = 28612, item = 22895, level = 55 }, -- Conjure Food (Rank 7) -> Conjured Cinnamon Roll
}
local MAX_TRADE_SLOTS = 6 -- slot 7 is "will not be traded"
local GAP = 3
local DEFAULTS = { width = 36, height = 36, zoom = 8, elvui = true, water = 1, food = 1,
	barDir = "UP", tradeDir = "RIGHT" }
-- flyout direction -> button point, toggle point, x sign, y sign
local DIRS = {
	UP = { "BOTTOM", "TOP", 0, 1 },
	DOWN = { "TOP", "BOTTOM", 0, -1 },
	LEFT = { "RIGHT", "LEFT", -1, 0 },
	RIGHT = { "LEFT", "RIGHT", 1, 0 },
}

local IsKnown = C_SpellBook.IsSpellKnown or IsPlayerSpell
-- spell: ID, or a name for spells whose ID we don't know yet
local function Known(spell)
	local info = C_Spell.GetSpellInfo(spell)
	return info and IsKnown(info.spellID) and info or nil
end

local db, E -- E = ElvUI engine when ElvUI styling is active
local buttons, spellButtons, flyouts = {}, {}, {}
local bar, trade

local function ShowSpellTip(self)
	local info = Known(self.spell)
	if not info then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetSpellByID(info.spellID)
	GameTooltip:Show()
end

local function ItemCounter(itemID)
	return function() return C_Item.GetItemCount(itemID) end
end

-- Every square button goes through here so size, zoom and styling apply to all of them.
-- countFn: optional, returns the number shown in the corner.
local function NewButton(template, parent, countFn, name)
	local b = CreateFrame("Button", name, parent, template)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	if countFn then
		b.countFn = countFn
		b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		b.count:SetPoint("BOTTOMRIGHT", -2, 2)
	end
	if E then
		b:SetTemplate()
		b:StyleButton()
		b.icon:SetInside()
		if b.count then b.count:FontTemplate() end
	else
		b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	end
	buttons[#buttons + 1] = b
	return b
end

-- Secure button that casts `spell`. Spells can only be cast from secure buttons.
local function SpellButton(parent, spell, countFn)
	local b = NewButton("SecureActionButtonTemplate", parent, countFn)
	b:RegisterForClicks("AnyUp", "AnyDown") -- honours the ActionButtonUseKeyDown setting
	b:SetAttribute("type", "spell")
	b:SetAttribute("spell", spell)
	b.spell = spell
	b:SetScript("OnEnter", ShowSpellTip)
	b:SetScript("OnLeave", GameTooltip_Hide)
	spellButtons[#spellButtons + 1] = b
	return b
end

-- Toggle button + secure flyout. Opening/closing runs in a secure snippet so it works in combat.
-- dirKey: the db setting holding this flyout's direction
local function MakeFlyout(name, parent, spells, label, dirKey, countFn)
	local t = NewButton("SecureHandlerClickTemplate", parent, countFn, name)
	t:RegisterForClicks("AnyUp")
	t.label, t.dirKey, t.buttons = label, dirKey, {}

	local fly = CreateFrame("Frame", nil, t, "SecureFrameTemplate")
	fly:SetFrameStrata("DIALOG")
	fly:Hide()
	t:SetFrameRef("flyout", fly)
	t:SetAttribute("_onclick", [[
		local f = self:GetFrameRef("flyout")
		if f:IsShown() then f:Hide() else f:Show() end
	]])

	for i, spell in ipairs(spells) do
		local b = SpellButton(fly, spell, countFn)
		-- close the flyout after a cast; only on the up-click so a key-down cast isn't cut off
		t:WrapScript(b, "OnClick", "if not down then return nil, true end", "self:GetParent():Hide()")
		t.buttons[i] = b
	end

	t:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.label)
		if self.hint then GameTooltip:AddLine(self.hint, 1, 1, 1) end
		GameTooltip:Show()
	end)
	t:SetScript("OnLeave", GameTooltip_Hide)
	flyouts[#flyouts + 1] = t
	return t
end

-- Corner counts are plain font strings, so this is safe in combat.
local function UpdateCounts()
	for _, b in ipairs(buttons) do
		if b.count then
			local n = b.countFn()
			b.count:SetText(n)
			if n == 0 then b.count:SetTextColor(1, 0.2, 0.2) else b.count:SetTextColor(1, 1, 1) end
		end
	end
end

-- Size, show only known spells and lay out. Secure frames can't change in combat, so this defers.
local dirty = false
local function RefreshAll()
	if InCombatLockdown() then dirty = true return end
	dirty = false
	local w, h = db.width, db.height
	local cl, cr, ct, cb = ns.IconCoords(w, h, db.zoom / 100)
	for _, b in ipairs(buttons) do
		b:SetSize(w, h)
		b.icon:SetTexCoord(cl, cr, ct, cb)
	end
	for _, b in ipairs(spellButtons) do
		local info = Known(b.spell)
		b:SetShown(info ~= nil)
		if info then b.icon:SetTexture(info.iconID) end
	end
	for _, t in ipairs(flyouts) do
		local d = DIRS[db[t.dirKey]] or DIRS[DEFAULTS[t.dirKey]]
		local step = (d[3] ~= 0 and w or h) + GAP
		local n = 0
		for _, b in ipairs(t.buttons) do
			if b:IsShown() then
				n = n + 1
				local off = GAP + (n - 1) * step
				b:ClearAllPoints()
				b:SetPoint(d[1], t, d[2], d[3] * off, d[4] * off)
				if n == 1 then t.icon:SetTexture(b.icon:GetTexture()) end
			end
		end
		t:SetShown(n > 0)
	end
	bar:SetSize(2 * w + GAP, h)
	trade:SetSize(6 + w + 10 + 22 + 4 + 100 + 6, 6 + 3 * h + 2 * 8 + 6)
end

---------------------------------------------------------------- main bar
local function BuildBar()
	bar = CreateFrame("Frame", "ButtonsForeverBar", UIParent)
	bar:SetMovable(true)
	bar:SetClampedToScreen(true)
	bar:SetDontSavePosition(true)
	local p = db.point
	if p then bar:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else bar:SetPoint("CENTER", 0, -150) end

	local tele = MakeFlyout("ButtonsForeverTeleports", bar, TELEPORTS, L["Teleports"], "barDir", ItemCounter(RUNE_TELE))
	tele:SetPoint("LEFT")
	local port = MakeFlyout("ButtonsForeverPortals", bar, PORTALS, L["Portals"], "barDir", ItemCounter(RUNE_PORT))
	port:SetPoint("LEFT", tele, "RIGHT", GAP, 0)

	for _, t in ipairs({ tele, port }) do
		t.hint = L["Shift-drag to move"]
		t:RegisterForDrag("LeftButton")
		t:SetScript("OnDragStart", function()
			if IsShiftKeyDown() and not InCombatLockdown() then bar:StartMoving() end
		end)
		t:SetScript("OnDragStop", function()
			bar:StopMovingOrSizing()
			local point, _, rel, x, y = bar:GetPoint()
			db.point = { point, rel, x, y }
		end)
	end
end

---------------------------------------------------------------- trade helper
local function ScanBags()
	local items = {}
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local info = C_Container.GetContainerItemInfo(bag, slot)
			if info and not info.isLocked then
				items[#items + 1] = { itemID = info.itemID, count = info.stackCount,
					maxStack = C_Item.GetItemMaxStackSizeByID(info.itemID), bag = bag, slot = slot }
			end
		end
	end
	return items
end

local partnerLevel -- level of the player we're trading with, nil if unknown

-- shortMsg: localized "Added %d of %d ... stacks" text shown when not all stacks fit
local function AddStacks(ranks, n, shortMsg)
	ClearCursor()
	local stacks = ns.PickStacks(ScanBags(), ranks, n, partnerLevel)
	local placed = 0
	for i = 1, MAX_TRADE_SLOTS do
		if placed == #stacks then break end
		if not GetTradePlayerItemLink(i) then
			placed = placed + 1
			C_Container.PickupContainerItem(stacks[placed].bag, stacks[placed].slot)
			ClickTradeButton(i)
		end
	end
	if placed < n then
		print("|cff69ccf0ButtonsForever|r: " .. shortMsg:format(placed, n))
	end
end

local wantTrade = false
local conjureButtons, title = {}, nil

-- Point each conjure button at the best rank the trade partner can use. Out of combat only.
local function SetConjureRanks()
	local lvl = UnitLevel("npc") -- "npc" is the trade partner while the trade window is open
	if (issecretvalue and issecretvalue(lvl)) or not lvl or lvl <= 0 then lvl = nil end
	partnerLevel = lvl
	for _, c in ipairs(conjureButtons) do
		-- nothing known: keep rank 1 so the button stays hidden until it's learned
		c.spell = ns.PickRank(c.ranks, lvl, IsKnown) or c.ranks[1].spell
		c:SetAttribute("spell", c.spell)
	end
	title:SetText(lvl and L["For level %d"]:format(lvl) or L["Portals / stacks"])
	RefreshAll()
	UpdateCounts()
end

local function TradeRow(anchor, ranks, key, buttonText, shortMsg)
	-- count = items in bags the trade partner can use
	local c = SpellButton(trade, ranks[1].spell, function()
		return ns.UsableCount(ranks, partnerLevel, C_Item.GetItemCount)
	end)
	c:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
	c.ranks = ranks
	conjureButtons[#conjureButtons + 1] = c

	local eb = CreateFrame("EditBox", nil, trade, "InputBoxTemplate")
	eb:SetSize(22, 20)
	eb:SetPoint("LEFT", c, "RIGHT", 10, 0)
	eb:SetNumeric(true)
	eb:SetMaxLetters(1)
	eb:SetAutoFocus(false)
	eb:SetText(tostring(db[key]))
	eb:SetScript("OnTextChanged", function(self)
		db[key] = math.max(1, math.min(MAX_TRADE_SLOTS, self:GetNumber()))
	end)
	eb:SetScript("OnEditFocusLost", function(self) self:SetText(tostring(db[key])) end)
	eb:SetScript("OnEnterPressed", eb.ClearFocus)

	local b = CreateFrame("Button", nil, trade, "UIPanelButtonTemplate")
	b:SetSize(100, 22)
	b:SetPoint("LEFT", eb, "RIGHT", 4, 0)
	b:SetText(buttonText)
	b:SetScript("OnClick", function() AddStacks(ranks, db[key], shortMsg) end)

	if E then
		local S = E:GetModule("Skins")
		S:HandleEditBox(eb)
		S:HandleButton(b)
	end
	return c
end

local function BuildTrade()
	trade = CreateFrame("Frame", "ButtonsForeverTrade", UIParent)
	trade:SetFrameStrata("HIGH")
	trade:Hide()
	if E then
		trade:SetTemplate("Transparent")
	else
		local bg = trade:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.7)
	end

	local port = MakeFlyout("ButtonsForeverTradePortals", trade, PORTALS, L["Portals"], "tradeDir", ItemCounter(RUNE_PORT))
	port:SetPoint("TOPLEFT", 6, -6)
	title = trade:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", port, "RIGHT", 8, 0)
	title:SetText(L["Portals / stacks"])

	local water = TradeRow(port, WATER_RANKS, "water", L["Add Water"],
		L["Added %d of %d water stacks (need more full stacks they can use, or free trade slots)."])
	TradeRow(water, FOOD_RANKS, "food", L["Add Food"],
		L["Added %d of %d food stacks (need more full stacks they can use, or free trade slots)."])
end

local function SyncTrade()
	if InCombatLockdown() then return end -- retried on PLAYER_REGEN_ENABLED
	if wantTrade and not trade:IsShown() then
		SetConjureRanks()
		-- copy TradeFrame's position instead of anchoring to it, so the Blizzard frame never
		-- becomes anchored to our protected panel
		trade:ClearAllPoints()
		if TradeFrame and TradeFrame:GetRight() then
			trade:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", TradeFrame:GetRight() + 2, TradeFrame:GetTop())
		else
			trade:SetPoint("CENTER")
		end
	end
	trade:SetShown(wantTrade)
end

---------------------------------------------------------------- settings (Esc > Options > AddOns, or /bf)
local function BuildSettings()
	local cat = Settings.RegisterVerticalLayoutCategory(addonName)
	local function Add(key, name)
		local s = Settings.RegisterAddOnSetting(cat, addonName .. "_" .. key, key, db, type(DEFAULTS[key]), name, DEFAULTS[key])
		s:SetValueChangedCallback(RefreshAll)
		return s
	end
	local function Slider(key, name, min, max, tip, fmt)
		local o = Settings.CreateSliderOptions(min, max, 1)
		o:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
		Settings.CreateSlider(cat, Add(key, name), o, tip)
	end
	Slider("width", L["Button width"], 16, 80, L["Width of every ButtonsForever button."])
	Slider("height", L["Button height"], 16, 80, L["Height of every ButtonsForever button."])
	Slider("zoom", L["Icon zoom"], 0, 30, L["Crops the icon's edges. Non-square buttons crop further so icons don't stretch."],
		function(v) return v .. "%" end)
	local function Direction(key, name, tip)
		local function options()
			local c = Settings.CreateControlTextContainer()
			c:Add("UP", L["Up"])
			c:Add("DOWN", L["Down"])
			c:Add("LEFT", L["Left"])
			c:Add("RIGHT", L["Right"])
			return c:GetData()
		end
		Settings.CreateDropdown(cat, Add(key, name), options, tip)
	end
	Direction("barDir", L["Bar flyout direction"], L["Which way the Teleport and Portal flyouts on the bar open."])
	Direction("tradeDir", L["Trade window flyout direction"], L["Which way the Portal flyout on the trade window panel opens."])
	Settings.CreateCheckbox(cat, Add("elvui", L["Match ElvUI style"]),
		L["Use ElvUI's button and panel look when ElvUI is installed. Takes effect after /reload."])
	Settings.RegisterAddOnCategory(cat)

	SLASH_BUTTONSFOREVER1, SLASH_BUTTONSFOREVER2 = "/bf", "/buttonsforever"
	SlashCmdList.BUTTONSFOREVER = function() Settings.OpenToCategory(cat:GetID()) end
end

---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, arg)
	if event == "ADDON_LOADED" then
		if arg ~= addonName then return end
		ButtonsForeverDB = ButtonsForeverDB or {}
		db = ButtonsForeverDB
		for k, v in pairs(DEFAULTS) do
			if db[k] == nil then db[k] = v end
		end
		if db.elvui and ElvUI then E = unpack(ElvUI) end
		BuildBar()
		BuildTrade()
		BuildSettings()
		self:UnregisterEvent("ADDON_LOADED")
		for _, e in ipairs({ "PLAYER_LOGIN", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
			"PLAYER_REGEN_ENABLED", "TRADE_SHOW", "TRADE_CLOSED" }) do
			self:RegisterEvent(e)
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		UpdateCounts()
	elseif event == "TRADE_SHOW" or event == "TRADE_CLOSED" then
		wantTrade = event == "TRADE_SHOW"
		SyncTrade()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if dirty then RefreshAll() end
		SyncTrade()
	else -- PLAYER_LOGIN, SPELLS_CHANGED
		RefreshAll()
		UpdateCounts()
	end
end)
