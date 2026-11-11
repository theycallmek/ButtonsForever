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
-- uiMapID of each city with a rune vendor -> vendor spots on that map (x, y in percent), from wowhead Forever.
-- faction: only that faction is alerted (the other can't buy there); none = neutral, everyone is.
-- Thunder Bluff's vendor walks a path, hence all the points.
local RUNE_CITIES = {
	[1453] = { faction = "Alliance", { 55, 65.2 }, { 55.2, 66 }, { 55.8, 65.2 }, { 63, 74.8 } }, -- Stormwind City
	[1455] = { faction = "Alliance", { 30.4, 26.4 }, { 30.6, 26.4 }, { 31.2, 27.4 }, { 31.2, 27.6 } }, -- Ironforge
	[1457] = { faction = "Alliance", { 34, 9.4 }, { 34, 9.6 }, { 34.6, 9.8 } }, -- Darnassus
	[1454] = { faction = "Horde", { 45.4, 56.4 }, { 45.4, 56.8 }, { 45.6, 56.8 } }, -- Orgrimmar
	[1458] = { faction = "Horde", { 69.4, 39.2 }, { 69.4, 39.6 }, { 69.6, 39.2 } }, -- Undercity
	[1456] = { faction = "Horde", -- Thunder Bluff
		{ 36.4, 54.4 }, { 36.4, 54.6 }, { 36.4, 55.6 }, { 36.6, 53.4 }, { 36.6, 53.8 }, { 36.6, 55.4 }, { 36.6, 55.8 },
		{ 36.8, 57 }, { 37, 52.2 }, { 37.2, 58.4 }, { 37.2, 58.6 }, { 37.4, 51.4 }, { 37.4, 59.8 }, { 37.6, 51.6 },
		{ 37.6, 60.2 }, { 38, 61.2 }, { 38.4, 51.2 }, { 38.4, 61.8 }, { 38.6, 62.2 }, { 38.8, 51.4 }, { 39.4, 52 },
		{ 39.4, 62.6 }, { 39.6, 52 }, { 39.6, 63 }, { 40, 62.2 }, { 40.4, 53.2 }, { 40.4, 53.6 }, { 40.6, 53.4 },
		{ 40.6, 61.8 }, { 41.4, 54.4 }, { 41.4, 54.6 }, { 41.4, 60.4 }, { 41.4, 60.8 }, { 41.6, 54.4 }, { 41.6, 60.8 },
		{ 41.8, 59.8 }, { 42, 55.4 }, { 42.4, 56 }, { 42.4, 56.6 }, { 42.4, 58.2 }, { 42.4, 59.2 }, { 42.6, 55.4 },
		{ 42.6, 56.4 }, { 42.6, 58.2 }, { 42.6, 58.8 }, { 42.6, 59.6 }, { 42.8, 56.6 }, { 43.6, 57.4 }, { 43.6, 57.8 },
	},
}
-- Rune vendors out in the zones, same format, plus area = the town's area (subzone) ID, from AreaTable.
-- These only alert inside that town, not across the zone. Checked when you cross into a new subzone, so
-- there's no polling. Winterspring (58.8, 78.4) and Riverglades (62.2, 85.8, Alliance) also have vendors
-- but are left out until their town's area ID is known.
local RUNE_TOWNS = {
	[1429] = { area = 91, faction = "Alliance", { 64.8, 69.2 } }, -- Elwynn Forest (Tower of Azora)
	[1431] = { area = 42, faction = "Alliance", { 76, 45.2 } }, -- Duskwood (Darkshire)
	[1435] = { area = 75, faction = "Horde", { 45.8, 53 } }, -- Swamp of Sorrows (Stonard)
	[1437] = { area = 150, faction = "Alliance", { 8.4, 56.4 }, { 8.4, 56.6 } }, -- Wetlands (Menethil Harbor)
	[1416] = { area = 279, { 14, 63.4 }, { 14.2, 63.6 } }, -- Alterac Mountains (Dalaran, neutral; town inferred from coords)
	[1417] = { area = 324, { 27, 58.8 } }, -- Arathi Highlands (Stromgarde Keep, neutral; town inferred from coords)
	[1424] = { area = 271, faction = "Alliance", { 50.8, 59 } }, -- Hillsbrad Foothills (Southshore)
	[1425] = { area = 3317, faction = "Horde", { 78.8, 78.4 }, { 78.8, 78.6 } }, -- The Hinterlands (Revantusk Village)
	[1413] = { area = 380, faction = "Horde", { 51.4, 30.2 } }, -- The Barrens (The Crossroads)
	[1440] = { area = 415, faction = "Alliance", { 35, 48.4 }, { 35, 48.6 } }, -- Ashenvale (Astranaar)
	[1441] = { area = 484, faction = "Horde", { 45, 50.4 }, { 45.2, 50.6 } }, -- Thousand Needles (Freewind Post)
	[1442] = { area = 460, faction = "Horde", { 47.4, 61.8 }, { 47.6, 61.6 } }, -- Stonetalon Mountains (Sun Rock Retreat)
	[1444] = { area = 1116, faction = "Alliance", { 30.8, 42 } }, -- Feralas (Feathermoon Stronghold)
	[1445] = { area = 496, faction = "Horde", { 36.4, 30.4 }, { 36.4, 30.6 }, { 36.6, 30.4 }, { 36.6, 30.6 } }, -- Dustwallow Marsh (Brackenwall Village)
	[1451] = { area = 3425, { 48.8, 37 } }, -- Silithus (Cenarion Hold, neutral)
}

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
	barDir = "UP", tradeDir = "RIGHT", barStrata = "MEDIUM", tradeStrata = "HIGH",
	showBar = true, showTrade = true, mouseover = false,
	runeAlert = true, alertWarning = true, alertChat = true, alertSound = "RAID_WARNING", alertMap = true,
	alertAt = 1, autoBuy = true, buyTele = 10, buyPort = 10, buyConfirm = true }
-- alert sound choices: SOUNDKIT key, label. "NONE" plays nothing.
local SOUNDS = {
	{ "NONE", L["None"] }, { "RAID_WARNING", L["Raid warning"] }, { "READY_CHECK", L["Ready check"] },
	{ "ALARM_CLOCK_WARNING_3", L["Alarm clock"] }, { "TELL_MESSAGE", L["Whisper"] }, { "MAP_PING", L["Map ping"] },
}
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

	local fly = CreateFrame("Frame", nil, t, "SecureFrameTemplate") -- inherits the bar/panel strata setting
	fly:Hide()
	t.fly = fly
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

-- Close open flyouts when a mouse press lands anywhere except the flyout's own buttons.
-- shortcut: skipped in combat, where addon code can't hide secure frames; the toggle and casting still close them.
local function CloseFlyoutsOnOutsideClick()
	if InCombatLockdown() then return end
	for _, t in ipairs(flyouts) do
		if t.fly:IsShown() and not t:IsMouseOver() then
			local onButton = false
			for _, b in ipairs(t.buttons) do
				if b:IsVisible() and b:IsMouseOver() then onButton = true break end
			end
			if not onButton then t.fly:Hide() end
		end
	end
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
	bar:SetFrameStrata(db.barStrata)
	bar:SetShown(db.showBar)
	bar:UpdateFade()
	trade:SetSize(6 + w + 10 + 22 + 4 + 100 + 6, 6 + 3 * h + 2 * 8 + 6)
	trade:SetFrameStrata(db.tradeStrata)
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

	-- Mouseover setting: invisible until hovered or a flyout is open. Alpha is allowed in combat,
	-- and hidden-by-alpha buttons still take clicks, like other addons' mouseover bars.
	function bar:UpdateFade()
		local show = not db.mouseover
		for _, t in ipairs({ tele, port }) do
			if t:IsMouseOver() or t.fly:IsShown() then show = true end
		end
		self:SetAlpha(show and 1 or 0)
	end
	local function Fade() bar:UpdateFade() end

	for _, t in ipairs({ tele, port }) do
		t:HookScript("OnEnter", Fade)
		t:HookScript("OnLeave", Fade)
		t.fly:HookScript("OnShow", Fade)
		t.fly:HookScript("OnHide", Fade)
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
	local show = wantTrade and db.showTrade
	if show and not trade:IsShown() then
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
	trade:SetShown(show)
end

---------------------------------------------------------------- out-of-runes alert
local alertedRunes = {}
local function KnowsAny(spells)
	for _, s in ipairs(spells) do if Known(s) then return true end end
	return false
end
local function PlayAlertSound(key)
	local id = SOUNDKIT[key]
	if id then PlaySound(id) end
end
-- Player position on `map` in percent, or nil (unknown, or hidden by the game).
local function PlayerPos(map)
	local pos = C_Map.GetPlayerMapPosition(map, "player")
	if not pos then return end
	local x, y = pos:GetXY()
	if not x or (issecretvalue and issecretvalue(x)) then return end
	return x * 100, y * 100
end
-- Map size in yards, from its corners' world positions (world x runs north, y runs west).
local mapSizes = {}
local function MapSize(map)
	if not mapSizes[map] then
		local _, tl = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(0, 0))
		local _, br = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(1, 1))
		if not (tl and br) then return end
		mapSizes[map] = { tl.y - br.y, tl.x - br.x }
	end
	return mapSizes[map][1], mapSizes[map][2]
end

---------------------------------------------------------------- vendor pins (our own, so the player's waypoint is untouched)
local pin -- { map=, x=, y= } in percent while a vendor is marked
local mapPin, miniPin
local function PinFrame(parent, size)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(size, size)
	f:SetFrameStrata("HIGH")
	f.icon = f:CreateTexture(nil, "OVERLAY")
	f.icon:SetAllPoints()
	f.icon:SetTexture(C_Item.GetItemIconByID(RUNE_PORT))
	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["Rune vendor"])
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", GameTooltip_Hide)
	f:Hide()
	return f
end
-- Minimap view radius in yards. Fallback: HereBeDragons' diameters per zoom level, halved.
local MINIMAP_SIZE = { indoor = { 300, 240, 180, 120, 80, 50 }, outdoor = { 466.67, 400, 333.33, 266.67, 200, 133.33 } }
local function MinimapRadius()
	if C_Minimap and C_Minimap.GetViewRadius then return C_Minimap.GetViewRadius() end
	return MINIMAP_SIZE[IsIndoors() and "indoor" or "outdoor"][Minimap:GetZoom() + 1] / 2
end
local function UpdateMiniPin(self)
	local px, py = PlayerPos(pin.map)
	local w, h = MapSize(pin.map)
	if not (px and w) then self.icon:SetAlpha(0) return end
	local facing = GetCVar("rotateMinimap") == "1" and GetPlayerFacing() or nil
	if facing and issecretvalue and issecretvalue(facing) then facing = nil end
	local x, y, edge = ns.MinimapOffset((pin.x - px) * w / 100, (pin.y - py) * h / 100,
		MinimapRadius(), Minimap:GetWidth() / 2, facing)
	self:SetPoint("CENTER", Minimap, "CENTER", x, y)
	self.icon:SetAlpha(edge and 0.6 or 1) -- dimmed on the edge: the vendor is further than the minimap shows
end
local function UpdateMapPin()
	local canvas = WorldMapFrame:GetCanvas()
	local show = pin and WorldMapFrame:IsShown() and WorldMapFrame:GetMapID() == pin.map
	mapPin:SetShown(show)
	if not show then return end
	-- keep the same on-screen size as the map zooms
	local scale = WorldMapFrame.ScrollContainer.GetCanvasScale and WorldMapFrame.ScrollContainer:GetCanvasScale()
	if not scale or scale <= 0 then scale = 1 end
	mapPin:SetScale(1 / scale)
	-- anchor offsets are in the pin's own (scaled) units, so convert from canvas units
	mapPin:SetPoint("CENTER", canvas, "TOPLEFT",
		canvas:GetWidth() * pin.x / 100 * scale, -canvas:GetHeight() * pin.y / 100 * scale)
end
local function ShowVendorPin(map, x, y)
	if not mapPin then
		mapPin = PinFrame(WorldMapFrame:GetCanvas(), 20)
		WorldMapFrame:HookScript("OnUpdate", UpdateMapPin) -- cheap, and catches map changes, resizes and zoom
		miniPin = PinFrame(Minimap, 16)
		miniPin:SetScript("OnUpdate", UpdateMiniPin) -- only runs while shown
	end
	pin = { map = map, x = x, y = y }
	miniPin:Show()
	UpdateMapPin()
end
local function HideVendorPin()
	pin = nil
	if mapPin then mapPin:Hide() miniPin:Hide() end
end

-- Where the player is, if near a rune vendor: map, nearest vendor point. Cities count everywhere on
-- their map; zone vendors only inside the vendor's town.
local function VendorArea()
	local map = C_Map.GetBestMapForUnit("player")
	local points = map and (RUNE_CITIES[map] or RUNE_TOWNS[map])
	if not points or (points.faction and points.faction ~= UnitFactionGroup("player")) then return end
	local px, py = PlayerPos(map)
	local w, h = MapSize(map)
	local p = ns.Nearest(points, px, py, w or 0, h or 0)
	if RUNE_CITIES[map] then return map, p end
	-- the game names the current subzone only as translated text, so compare it to the town's translated name
	if points.area and GetSubZoneText() == C_Map.GetAreaInfo(points.area) then return map, p end
end

-- Warn once per visit for each rune at or below db.alertAt while you know a spell that uses it.
-- Runs only on game events (zone/subzone changes, bag changes, vendor closed), never on a timer.
local function CheckRunes()
	if not db.runeAlert then HideVendorPin() return end
	local map, p = VendorArea()
	local inArea = map ~= nil
	local runes = {
		{ item = RUNE_TELE, known = KnowsAny(TELEPORTS), count = C_Item.GetItemCount(RUNE_TELE) },
		{ item = RUNE_PORT, known = KnowsAny(PORTALS), count = C_Item.GetItemCount(RUNE_PORT) },
	}
	local alerts = ns.RunesToAlert(inArea, runes, alertedRunes, db.alertAt)
	if #alerts > 0 and db.alertMap then ShowVendorPin(map, p[1], p[2]) end
	-- restocked every low rune, or left the area: nothing left to point at
	if next(alertedRunes) == nil then HideVendorPin() end
	for _, item in ipairs(alerts) do
		local it = Item:CreateFromItemID(item) -- waits for the localized item name to load
		it:ContinueOnItemLoad(function()
			local msg = L["You have %d %s left. Buy more from a reagent vendor."]:format(C_Item.GetItemCount(item), it:GetItemName())
			if db.alertWarning then RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo.RAID_WARNING) end
			if db.alertChat then print("|cff69ccf0ButtonsForever|r: " .. msg) end
			PlayAlertSound(db.alertSound)
		end)
	end
end

---------------------------------------------------------------- rune auto-buy
local function MerchantItem(i) -- name, price per stack, items per stack
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		local t = C_MerchantFrame.GetItemInfo(i)
		if t then return t.name, t.price, t.stackCount end
	elseif GetMerchantItemInfo then
		local name, _, price, stack = GetMerchantItemInfo(i)
		return name, price, stack
	end
end
-- Runes this vendor sells that we're short of: { {index, itemID, name, qty}, ... }, total cost in copper.
local function PlanRuneBuys()
	local want = {
		[RUNE_TELE] = KnowsAny(TELEPORTS) and db.buyTele or 0,
		[RUNE_PORT] = KnowsAny(PORTALS) and db.buyPort or 0,
	}
	local plan, cost = {}, 0
	for i = 1, GetMerchantNumItems() do
		local id = GetMerchantItemID(i)
		local qty = id and want[id] and ns.TopUp(C_Item.GetItemCount(id), want[id]) or 0
		if qty > 0 then
			want[id] = nil -- a vendor listing it twice shouldn't double the order
			local name, price, stack = MerchantItem(i)
			-- shortcut: assumes the item is sold singly (runes are); a multi-item stack would be priced per stack
			cost = cost + (price or 0) * qty / math.max(stack or 1, 1)
			plan[#plan + 1] = { index = i, itemID = id, name = name or "?", qty = qty }
		end
	end
	return plan, cost
end
local function Describe(plan)
	local parts = {}
	for _, p in ipairs(plan) do parts[#parts + 1] = p.qty .. " x " .. p.name end
	return table.concat(parts, ", ")
end
local function BuyRunes()
	local plan, cost = PlanRuneBuys() -- re-planned so a changed bag or a closed vendor is handled
	if #plan == 0 then return end
	if GetMoney() < cost then
		print("|cff69ccf0ButtonsForever|r: " .. L["Not enough money to auto-buy runes (%s needed)."]:format(GetMoneyString(cost)))
		return
	end
	for _, p in ipairs(plan) do
		local max = C_Item.GetItemMaxStackSizeByID(p.itemID) or 1
		local left = p.qty
		while left > 0 do -- one call buys at most a stack
			local n = math.min(left, max)
			BuyMerchantItem(p.index, n)
			left = left - n
		end
	end
	print("|cff69ccf0ButtonsForever|r: " .. L["Bought %s."]:format(Describe(plan)))
end
StaticPopupDialogs.BUTTONSFOREVER_BUY_RUNES = {
	text = "%s", button1 = YES, button2 = NO, OnAccept = BuyRunes,
	timeout = 0, hideOnEscape = true, whileDead = true, preferredIndex = 3,
}
local function OnMerchantShow()
	if not db.autoBuy then return end
	local plan, cost = PlanRuneBuys()
	if #plan == 0 then return end
	if db.buyConfirm then
		StaticPopup_Show("BUTTONSFOREVER_BUY_RUNES", L["Buy %s for %s?"]:format(Describe(plan), GetMoneyString(cost)))
	else
		BuyRunes()
	end
end

---------------------------------------------------------------- settings (Esc > Options > AddOns, or /bf)
local function BuildSettings()
	local cat, layout = Settings.RegisterVerticalLayoutCategory(addonName)
	local function Apply()
		RefreshAll()
		SyncTrade()
	end
	local function Add(key, name, onChange)
		local s = Settings.RegisterAddOnSetting(cat, addonName .. "_" .. key, key, db, type(DEFAULTS[key]), name, DEFAULTS[key])
		s:SetValueChangedCallback(onChange or Apply)
		return s
	end
	-- choices: { {value, label}, ... }
	local function Dropdown(key, name, tip, choices, onChange)
		local function options()
			local c = Settings.CreateControlTextContainer()
			for _, choice in ipairs(choices) do c:Add(choice[1], choice[2]) end
			return c:GetData()
		end
		return Settings.CreateDropdown(cat, Add(key, name, onChange), options, tip)
	end
	local DIRECTIONS = { { "UP", L["Up"] }, { "DOWN", L["Down"] }, { "LEFT", L["Left"] }, { "RIGHT", L["Right"] } }
	local STRATAS = {
		{ "BACKGROUND", L["Background"] }, { "LOW", L["Low"] }, { "MEDIUM", L["Medium"] }, { "HIGH", L["High"] },
		{ "DIALOG", L["Dialog"] }, { "FULLSCREEN", L["Fullscreen"] }, { "FULLSCREEN_DIALOG", L["Fullscreen dialog"] },
		{ "TOOLTIP", L["Tooltip"] },
	}

	Settings.CreateCheckbox(cat, Add("showBar", L["Show flyout bar"]), L["Show the Teleport and Portal bar."])
	Settings.CreateCheckbox(cat, Add("mouseover", L["Show bar on mouseover only"]),
		L["Keeps the bar invisible until you move the mouse over it. It stays visible while a flyout is open."])
	Settings.CreateCheckbox(cat, Add("showTrade", L["Show trade window panel"]), L["Show the panel beside the trade window."])
	local function Slider(key, name, min, max, tip, fmt)
		local o = Settings.CreateSliderOptions(min, max, 1)
		o:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
		return Settings.CreateSlider(cat, Add(key, name), o, tip)
	end
	Slider("width", L["Button width"], 16, 80, L["Width of every ButtonsForever button."])
	Slider("height", L["Button height"], 16, 80, L["Height of every ButtonsForever button."])
	Slider("zoom", L["Icon zoom"], 0, 30, L["Crops the icon's edges. Non-square buttons crop further so icons don't stretch."],
		function(v) return v .. "%" end)
	Dropdown("barDir", L["Bar flyout direction"], L["Which way the Teleport and Portal flyouts on the bar open."], DIRECTIONS)
	Dropdown("tradeDir", L["Trade window flyout direction"], L["Which way the Portal flyout on the trade window panel opens."], DIRECTIONS)
	Dropdown("barStrata", L["Bar strata"],
		L["Draw layer of the bar and its flyouts. Higher layers appear above more of the interface."], STRATAS)
	Dropdown("tradeStrata", L["Trade window strata"], L["Draw layer of the trade window panel and its flyout."], STRATAS)
	Settings.CreateCheckbox(cat, Add("elvui", L["Match ElvUI style"]),
		L["Use ElvUI's button and panel look when ElvUI is installed. Takes effect after /reload."])

	local alert = Settings.CreateCheckbox(cat, Add("runeAlert", L["Low-rune alert"]),
		L["Warn when you're near a rune vendor (anywhere in a capital city, or close to a vendor in a town) and are low on Runes of Teleportation or Runes of Portals."])
	local function alertOn() return db.runeAlert end
	-- indented under the alert checkbox, and greyed out while it's off
	local function Sub(init) init:SetParentInitializer(alert, alertOn) end
	Sub(Slider("alertAt", L["Alert when runes are at or below"], 0, 20,
		L["Warn when you have this many of a rune or fewer. 0 warns only when you're out."]))
	Sub(Settings.CreateCheckbox(cat, Add("alertWarning", L["Alert on screen"]),
		L["Show the alert in the middle of the screen, like a raid warning."]))
	Sub(Settings.CreateCheckbox(cat, Add("alertChat", L["Alert in chat"]), L["Print the alert in the chat window."]))
	Sub(Settings.CreateCheckbox(cat, Add("alertMap", L["Mark vendor on map"]),
		L["Show a marker for the nearest rune vendor on your map and minimap. Your own waypoint isn't touched."]))
	local sounds = {} -- skip any sound this client doesn't have
	for _, s in ipairs(SOUNDS) do
		if s[1] == "NONE" or SOUNDKIT[s[1]] then sounds[#sounds + 1] = s end
	end
	Sub(Dropdown("alertSound", L["Alert sound"], L["Sound played with the alert. Picking one plays it."], sounds,
		function(_, value) PlayAlertSound(value) end))
	local test = CreateSettingsButtonInitializer(L["Test alert sound"], L["Play"],
		function() PlayAlertSound(db.alertSound) end, L["Play the chosen alert sound."], true)
	layout:AddInitializer(test)
	Sub(test)

	local buy = Settings.CreateCheckbox(cat, Add("autoBuy", L["Auto-buy runes"]),
		L["Top up your runes when you open a vendor that sells them."])
	local function buyOn() return db.autoBuy end
	local function BuySub(init) init:SetParentInitializer(buy, buyOn) end
	local buyTip = L["When a vendor that sells them is open, buy enough to have this many. 0 turns it off."]
	BuySub(Slider("buyTele", L["Auto-buy Runes of Teleportation"], 0, 100, buyTip))
	BuySub(Slider("buyPort", L["Auto-buy Runes of Portals"], 0, 100, buyTip))
	BuySub(Settings.CreateCheckbox(cat, Add("buyConfirm", L["Confirm auto-buy"]), L["Ask before auto-buying runes."]))
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
			"PLAYER_REGEN_ENABLED", "TRADE_SHOW", "TRADE_CLOSED", "GLOBAL_MOUSE_DOWN",
			"PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "MERCHANT_SHOW", "MERCHANT_CLOSED",
			"ZONE_CHANGED", "ZONE_CHANGED_INDOORS" }) do
			self:RegisterEvent(e)
		end
	elseif event == "GLOBAL_MOUSE_DOWN" then
		CloseFlyoutsOnOutsideClick()
	elseif event == "MERCHANT_SHOW" then
		OnMerchantShow()
	elseif event == "MERCHANT_CLOSED" then
		StaticPopup_Hide("BUTTONSFOREVER_BUY_RUNES")
		CheckRunes() -- done shopping: clear the vendor pin if the runes are restocked
	elseif event == "PLAYER_ENTERING_WORLD" or event:find("^ZONE_CHANGED") then
		CheckRunes()
	elseif event == "BAG_UPDATE_DELAYED" then
		UpdateCounts()
		CheckRunes() -- catches using your last rune while in a city
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
