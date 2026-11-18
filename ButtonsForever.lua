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
local ARCANE_POWDER = 17020 -- Arcane Powder (item)
-- Reagents the low-reagent alert and auto-buy look after. spells: what uses it (it's only bought or alerted
-- about if you know one); buy: db key of the amount to keep; at: db key of its alert level (runes share
-- alertAt); on: db key of its own on/off switch.
local REAGENTS = {
	{ item = RUNE_TELE, spells = TELEPORTS, buy = "buyTele" },
	{ item = RUNE_PORT, spells = PORTALS, buy = "buyPort" },
	{ item = ARCANE_POWDER, spells = { 23028 }, on = "powder", at = "powderAt", buy = "buyPowder" }, -- Arcane Brilliance
}
-- Buff reminder. Ranks lowest first. Any armor counts; Arcane Brilliance counts as Arcane Intellect.
local ARMORS = {
	FROST = { 168, 7300, 7301, 7302, 7320, 10219, 10220 }, -- Frost Armor 1-3, then Ice Armor 1-4
	MAGE = { 6117, 22782, 22783 }, -- Mage Armor 1-3
}
local INTELLECT = { 1459, 1460, 1461, 10156, 10157, 23028 } -- Arcane Intellect 1-5, Arcane Brilliance
-- Forever's mage scrolls (from Bundle of Scrolls, wowhead Forever), by required level. Shown only while in your bags.
local SCROLLS = {
	213564, -- Scroll of Minor Evocation (15)
	274947, -- Scroll of Imbue Lesser Flame (15)
	275067, -- Scroll of Imbue Chillknife (15)
	275069, -- Scroll of Rat Familiar (15)
	217495, -- Scroll of Cryoblast (25)
	213550, -- Scroll of Polymorph: Odd Melon (25)
	277483, -- Scroll of Frog Familiar (25)
	277484, -- Scroll of Confuse Beast (25)
	277485, -- Scroll of Imbue Frost (25)
	277486, -- Scroll of Imbue Striking (25)
	277487, -- Scroll of Imbue Baleflame (25)
	277488, -- Scroll of Imbue Iceknife (25)
	277489, -- Scroll of Imbue Spark (25)
	213548, -- Scroll of Liminal Passage (40)
	277491, -- Scroll of Rebuke Elemental (40)
	277492, -- Scroll of Khadgar's Unlocking (40)
	277493, -- Scroll of Cat Familiar (40)
	277494, -- Scroll of Imbue Accuracy (40)
	277495, -- Scroll of Imbue Quickening (40)
	277496, -- Scroll of Imbue Balefrost (40)
	277497, -- Scroll of Imbue Flame (40)
	277498, -- Scroll of Imbue Manablade (40)
}
-- uiMapID of each city with a rune vendor -> vendor spots on that map (x, y in percent), from wowhead Forever.
-- faction: only that faction is alerted (the other can't buy there); none = neutral, everyone is.
-- npcs: the vendors there (NPC ID, English name), from wowhead Forever's "sold by" for Rune of Teleportation.
-- Thunder Bluff's vendor walks a path, hence all the points.
local RUNE_CITIES = {
	[1453] = { npcs = { { 1257, "Keldric Boucher" }, { 1275, "Kyra Boucher" }, { 1307, "Charys Yserian" }, { 1308, "Owen Vaughn" }, { 1351, "Brother Cassius" } }, faction = "Alliance", { 55, 65.2 }, { 55.2, 66 }, { 55.8, 65.2 }, { 63, 74.8 } }, -- Stormwind City
	[1455] = { npcs = { { 5110, "Barim Jurgenstaad" }, { 5151, "Ginny Longberry" } }, faction = "Alliance", { 30.4, 26.4 }, { 30.6, 26.4 }, { 31.2, 27.4 }, { 31.2, 27.6 } }, -- Ironforge
	[1457] = { npcs = { { 3562, "Alaindia" }, { 4220, "Cyroen" } }, faction = "Alliance", { 34, 9.4 }, { 34, 9.6 }, { 34.6, 9.8 } }, -- Darnassus
	[1454] = { npcs = { { 3323, "Horthus" }, { 3335, "Hagrus" }, { 3351, "Magenius" } }, faction = "Horde", { 45.4, 56.4 }, { 45.4, 56.8 }, { 45.6, 56.8 } }, -- Orgrimmar
	[1458] = { npcs = { { 4562, "Thomas Mordan" }, { 4575, "Hannah Akeley" } }, faction = "Horde", { 69.4, 39.2 }, { 69.4, 39.6 }, { 69.6, 39.2 } }, -- Undercity
	[1456] = { npcs = { { 8361, "Chepi" } }, faction = "Horde", -- Thunder Bluff
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
	[1429] = { npcs = { { 958, "Dawn Brightstar" } }, area = 91, faction = "Alliance", { 64.8, 69.2 } }, -- Elwynn Forest (Tower of Azora)
	[1431] = { npcs = { { 1673, "Alyssa Eva" } }, area = 42, faction = "Alliance", { 76, 45.2 } }, -- Duskwood (Darkshire)
	[1435] = { npcs = { { 983, "Thultazor" } }, area = 75, faction = "Horde", { 45.8, 53 } }, -- Swamp of Sorrows (Stonard)
	[1437] = { npcs = { { 1463, "Falkan Armonis" } }, area = 150, faction = "Alliance", { 8.4, 56.4 }, { 8.4, 56.6 } }, -- Wetlands (Menethil Harbor)
	[1416] = { npcs = { { 29537, "Darahir" } }, area = 279, { 14, 63.4 }, { 14.2, 63.6 } }, -- Alterac Mountains (Dalaran, neutral; town inferred from coords)
	[1417] = { npcs = { { 2805, "Deneb Walker" } }, area = 324, { 27, 58.8 } }, -- Arathi Highlands (Stromgarde Keep, neutral; town inferred from coords)
	[1424] = { npcs = { { 3542, "Jaysin Lanyda" } }, area = 271, faction = "Alliance", { 50.8, 59 } }, -- Hillsbrad Foothills (Southshore)
	[1425] = { npcs = { { 14739, "Mystic Yayo'jin" } }, area = 3317, faction = "Horde", { 78.8, 78.4 }, { 78.8, 78.6 } }, -- The Hinterlands (Revantusk Village)
	[1413] = { npcs = { { 3490, "Hula'mahi" } }, area = 380, faction = "Horde", { 51.4, 30.2 } }, -- The Barrens (The Crossroads)
	[1440] = { npcs = { { 3970, "Llana" } }, area = 415, faction = "Alliance", { 35, 48.4 }, { 35, 48.6 } }, -- Ashenvale (Astranaar)
	[1441] = { npcs = { { 4878, "Montarr" } }, area = 484, faction = "Horde", { 45, 50.4 }, { 45.2, 50.6 } }, -- Thousand Needles (Freewind Post)
	[1442] = { npcs = { { 4083, "Jeeda" } }, area = 460, faction = "Horde", { 47.4, 61.8 }, { 47.6, 61.6 } }, -- Stonetalon Mountains (Sun Rock Retreat)
	[1444] = { npcs = { { 3700, "Jadenvis Seawatcher" } }, area = 1116, faction = "Alliance", { 30.8, 42 } }, -- Feralas (Feathermoon Stronghold)
	[1445] = { npcs = { { 13476, "Balai Lok'Wein" } }, area = 496, faction = "Horde", { 36.4, 30.4 }, { 36.4, 30.6 }, { 36.6, 30.4 }, { 36.6, 30.6 } }, -- Dustwallow Marsh (Brackenwall Village)
	[1451] = { npcs = { { 15175, "Khur Hornstriker" } }, area = 3425, { 48.8, 37 } }, -- Silithus (Cenarion Hold, neutral)
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
local DEFAULTS = { width = 36, height = 36, zoom = 8, elvui = true, water = 1, food = 1,
	barDir = "UP", tradeDir = "RIGHT", barStrata = "MEDIUM", tradeStrata = "HIGH",
	spacing = 3, barLayout = "HORIZONTAL",
	showBar = true, showTrade = true, mouseover = false, showScrolls = true, scrollSort = "LEVEL",
	runeAlert = true, alertWarning = true, alertChat = true, alertSound = "RAID_WARNING", alertMap = true,
	alertAt = 1, vendorMark = 1, autoBuy = true, buyTele = 10, buyPort = 10, buyConfirm = true,
	powder = true, powderAt = 1, buyPowder = 20,
	buffRemind = true, remindArmor = true, armorType = "FROST", remindInt = true,
	buffWidth = 36, buffHeight = 36, buffZoom = 8, buffStrata = "MEDIUM" }
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
local function Known(spell) -- spell ID -> its info if you know it, else nil
	local info = C_Spell.GetSpellInfo(spell)
	return info and IsKnown(info.spellID) and info or nil
end

local db, E -- E = ElvUI engine when ElvUI styling is active
local buttons, spellButtons, itemButtons, flyouts = {}, {}, {}, {}
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

-- Secure button that uses item `id` from the bags; shown only while you have one.
local function ItemButton(parent, id)
	local b = NewButton("SecureActionButtonTemplate", parent, ItemCounter(id))
	b:RegisterForClicks("AnyUp", "AnyDown")
	b:SetAttribute("type", "item")
	b:SetAttribute("item", "item:" .. id)
	b.item = id
	b.icon:SetTexture(C_Item.GetItemIconByID(id))
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetItemByID(self.item)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	itemButtons[#itemButtons + 1] = b
	return b
end

-- Toggle button + secure flyout. Opening/closing runs in a secure snippet so it works in combat.
-- dirKey: the db setting holding this flyout's direction
-- newButton: optional (flyout, entry) -> button; default is a spell button with countFn
local function MakeFlyout(name, parent, spells, label, dirKey, countFn, newButton)
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
		local b = newButton and newButton(fly, spell) or SpellButton(fly, spell, countFn)
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
-- Revisit if players report flyouts staying open in combat.
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
	local w, h, GAP = db.width, db.height, db.spacing
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
	for _, b in ipairs(itemButtons) do b:SetShown(C_Item.GetItemCount(b.item) > 0) end
	for _, t in ipairs(flyouts) do
		local d = DIRS[db[t.dirKey]] or DIRS[DEFAULTS[t.dirKey]]
		local step = (d[3] ~= 0 and w or h) + GAP
		local n = 0
		for _, b in ipairs(t.order and t.order() or t.buttons) do
			if b:IsShown() then
				n = n + 1
				local off = GAP + (n - 1) * step
				b:ClearAllPoints()
				b:SetPoint(d[1], t, d[2], d[3] * off, d[4] * off)
				if n == 1 then t.icon:SetTexture(b.icon:GetTexture()) end
			end
		end
		t:SetShown(n > 0 and (not t.showKey or db[t.showKey]))
	end
	-- line up the bar's visible buttons with no gaps (e.g. scrolls before you've learned portals)
	local vertical, shown = db.barLayout == "VERTICAL", 0
	for _, t in ipairs(bar.toggles) do
		if t:IsShown() then
			t:ClearAllPoints()
			if vertical then t:SetPoint("TOP", 0, -shown * (h + GAP)) else t:SetPoint("LEFT", shown * (w + GAP), 0) end
			shown = shown + 1
		end
	end
	local n = math.max(1, shown)
	if vertical then bar:SetSize(w, n * (h + GAP) - GAP) else bar:SetSize(n * (w + GAP) - GAP, h) end
	bar:SetFrameStrata(db.barStrata)
	bar:SetShown(db.showBar)
	bar:UpdateFade()
	trade:SetSize(6 + w + 10 + 22 + 4 + 100 + 6, 6 + 3 * h + 2 * 8 + 6)
	trade:SetFrameStrata(db.tradeStrata)
end

---------------------------------------------------------------- main bar
local function SavePoint(frame, key) -- end a Shift-drag and remember where it landed
	frame:StopMovingOrSizing()
	local point, _, rel, x, y = frame:GetPoint()
	db[key] = { point, rel, x, y }
end
local function BuildBar()
	bar = CreateFrame("Frame", "ButtonsForeverBar", UIParent)
	bar:SetMovable(true)
	bar:SetClampedToScreen(true)
	bar:SetDontSavePosition(true)
	local p = db.point
	if p then bar:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else bar:SetPoint("CENTER", 0, -150) end

	local tele = MakeFlyout("ButtonsForeverTeleports", bar, TELEPORTS, L["Teleports"], "barDir", ItemCounter(RUNE_TELE))
	local port = MakeFlyout("ButtonsForeverPortals", bar, PORTALS, L["Portals"], "barDir", ItemCounter(RUNE_PORT))
	local function scrollCount()
		local n = 0
		for _, id in ipairs(SCROLLS) do n = n + C_Item.GetItemCount(id) end
		return n
	end
	local scrolls = MakeFlyout("ButtonsForeverScrolls", bar, SCROLLS, L["Scrolls"], "barDir", scrollCount, ItemButton)
	scrolls.showKey = "showScrolls"
	-- flyout order per the scrollSort setting; LEVEL is SCROLLS' own order
	local sortKeys = {
		NAME = function(b) return C_Item.GetItemNameByID(b.item) or "" end, -- bag items are cached, so names are there
		COUNT = function(b) return -C_Item.GetItemCount(b.item) end,
	}
	function scrolls.order()
		local key = sortKeys[db.scrollSort]
		return key and ns.SortBy(scrolls.buttons, key) or scrolls.buttons
	end
	bar.toggles = { tele, port, scrolls } -- placed by RefreshAll

	-- Mouseover setting: invisible until hovered or a flyout is open. Alpha is allowed in combat,
	-- and hidden-by-alpha buttons still take clicks, like other addons' mouseover bars.
	function bar:UpdateFade()
		local show = not db.mouseover
		for _, t in ipairs(self.toggles) do
			if t:IsMouseOver() or t.fly:IsShown() then show = true end
		end
		self:SetAlpha(show and 1 or 0)
	end
	local function Fade() bar:UpdateFade() end

	for _, t in ipairs(bar.toggles) do
		t:HookScript("OnEnter", Fade)
		t:HookScript("OnLeave", Fade)
		t.fly:HookScript("OnShow", Fade)
		t.fly:HookScript("OnHide", Fade)
		t.hint = L["Shift-drag to move"]
		t:RegisterForDrag("LeftButton")
		t:SetScript("OnDragStart", function()
			if IsShiftKeyDown() and not InCombatLockdown() then bar:StartMoving() end
		end)
		t:SetScript("OnDragStop", function() SavePoint(bar, "point") end)
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
local function BestKnown(spells) -- highest known rank, or nil
	local best
	for _, s in ipairs(spells) do if Known(s) then best = s end end
	return best
end
-- Sounds other addons (ElvUI, SharedMedia packs...) share through LibSharedMedia, if one of them loaded it.
local LSM_PREFIX = "LSM:"
local function SharedMedia() return LibStub and LibStub("LibSharedMedia-3.0", true) end
local function PlayAlertSound(key)
	if key:sub(1, #LSM_PREFIX) == LSM_PREFIX then
		local lsm = SharedMedia()
		local file = lsm and lsm:Fetch("sound", key:sub(#LSM_PREFIX + 1), true)
		if file then PlaySoundFile(file, "Master") return end
		key = "RAID_WARNING" -- the addon that had this sound is gone
	end
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
local pin -- { map=, x=, y=, npcs= } (x, y in percent) while a vendor is marked
local mapPin, miniPin, clicker
-- An NPC's name in the client's language: the game's creature cache if it has it (the game is always right),
-- else our translated list (Locales.lua), else English.
local function NpcName(id, english)
	local tip = C_TooltipInfo and C_TooltipInfo.GetHyperlink(("unit:Creature-0-0-0-0-%d-0"):format(id))
	local line = tip and tip.lines and tip.lines[1]
	local name = line and line.leftText
	if name and name ~= "" and not (issecretvalue and issecretvalue(name)) then return name end
	return ns.VendorNames[id] or english
end
-- Names of the marked area's vendors. A city can have several; we don't know which stands at which spot.
local function VendorNames()
	local out = {}
	for i, n in ipairs(pin and pin.npcs or {}) do out[i] = NpcName(n[1], n[2]) end
	return out
end
local function VendorTip(owner)
	local names = VendorNames()
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(#names == 1 and names[1] or L["Rune vendor"])
	if #names > 1 then
		for _, n in ipairs(names) do GameTooltip:AddLine(n, 1, 1, 1) end
	end
	if #names > 0 and not InCombatLockdown() then
		GameTooltip:AddLine(db.vendorMark > 0 and L["Click to target and mark."] or L["Click to target."], 0, 1, 0)
	end
	GameTooltip:Show()
end
-- Targeting needs a secure click, and secure frames can't move in combat. So the pins stay plain frames, and
-- out of combat this one secure button is laid over whichever pin the mouse is on.
local function ShowClicker(over)
	if not clicker then
		clicker = CreateFrame("Button", "ButtonsForeverVendorTarget", UIParent, "SecureActionButtonTemplate")
		clicker:SetFrameStrata("TOOLTIP")
		clicker:RegisterForClicks("AnyUp")
		clicker:SetAttribute("type", "macro")
		clicker:SetScript("OnEnter", VendorTip)
		clicker:SetScript("OnLeave", function(self)
			GameTooltip_Hide()
			if not InCombatLockdown() then self:Hide() end -- otherwise PLAYER_REGEN_ENABLED hides it
		end)
		clicker:SetScript("PostClick", function(self)
			local t = UnitName("target")
			if issecretvalue and issecretvalue(t) then return end
			if not tContains(self.vendors, t) then
				print("|cff69ccf0ButtonsForever|r: " .. L["Too far away to target: %s"]:format(table.concat(self.vendors, ", ")))
				return
			end
			local mark = db.vendorMark
			if mark > 0 and GetRaidTargetIndex("target") ~= mark then SetRaidTarget("target", mark) end
		end)
	end
	local names = VendorNames()
	if #names == 0 then return end
	local s = over:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local x, y = over:GetCenter()
	clicker:ClearAllPoints()
	clicker:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * s, y * s)
	clicker:SetSize(over:GetWidth() * s, over:GetHeight() * s)
	clicker.vendors, clicker.owner = names, over
	-- one line per vendor: whichever is in range gets targeted
	clicker:SetAttribute("macrotext", "/targetexact " .. table.concat(names, "\n/targetexact "))
	clicker:Show()
end
local function PinFrame(parent, size)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(size, size)
	f:SetFrameStrata("HIGH")
	f.icon = f:CreateTexture(nil, "OVERLAY")
	f.icon:SetAllPoints()
	f.icon:SetTexture(C_Item.GetItemIconByID(RUNE_PORT))
	f:SetScript("OnEnter", function(self)
		VendorTip(self)
		if not InCombatLockdown() then ShowClicker(self) end
	end)
	f:SetScript("OnLeave", GameTooltip_Hide)
	-- also fires when the world map closes; an invisible clicker left behind would eat clicks under the mouse
	f:SetScript("OnHide", function(self)
		if clicker and clicker.owner == self and not InCombatLockdown() then clicker:Hide() end
	end)
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
local function ShowVendorPin(map, p)
	if not mapPin then
		mapPin = PinFrame(WorldMapFrame:GetCanvas(), 20)
		WorldMapFrame:HookScript("OnUpdate", UpdateMapPin) -- cheap, and catches map changes, resizes and zoom
		miniPin = PinFrame(Minimap, 16)
		miniPin:SetScript("OnUpdate", UpdateMiniPin) -- only runs while shown
	end
	pin = { map = map, x = p[1], y = p[2], npcs = (RUNE_CITIES[map] or RUNE_TOWNS[map]).npcs }
	miniPin:Show()
	UpdateMapPin()
end
local function HideVendorPin()
	pin = nil
	if mapPin then mapPin:Hide() miniPin:Hide() end
	if clicker and not InCombatLockdown() then clicker:Hide() end
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
	local runes = {}
	for i, r in ipairs(REAGENTS) do
		runes[i] = { item = r.item, known = (not r.on or db[r.on]) and BestKnown(r.spells) ~= nil,
			count = C_Item.GetItemCount(r.item), at = r.at and db[r.at] }
	end
	local alerts = ns.RunesToAlert(inArea, runes, alertedRunes, db.alertAt)
	if #alerts > 0 and db.alertMap then ShowVendorPin(map, p) end
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
	local want, merchant = {}, {}
	for _, r in ipairs(REAGENTS) do
		want[r.item] = (not r.on or db[r.on]) and BestKnown(r.spells) and db[r.buy] or 0
	end
	for i = 1, GetMerchantNumItems() do
		local name, price, stack = MerchantItem(i)
		merchant[i] = { id = GetMerchantItemID(i), name = name, price = price, stack = stack }
	end
	return ns.PlanBuys(merchant, want, C_Item.GetItemCount)
end
-- Free general bag slots, and whether the plan fits in them (partial stacks are topped up first).
local function PlanFits(plan)
	local room, free, need = {}, 0, 0
	for _, it in ipairs(ScanBags()) do room[it.itemID] = (room[it.itemID] or 0) + it.maxStack - it.count end
	for bag = 0, NUM_BAG_SLOTS do
		local n, bagType = C_Container.GetContainerNumFreeSlots(bag)
		if bagType == 0 then free = free + n end -- special bags (soul, ammo) can't hold reagents
	end
	for _, p in ipairs(plan) do
		need = need + ns.SlotsNeeded(p.qty, room[p.itemID] or 0, C_Item.GetItemMaxStackSizeByID(p.itemID) or 1)
	end
	return need <= free
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
	if not PlanFits(plan) then
		print("|cff69ccf0ButtonsForever|r: " .. L["Not enough bag space to auto-buy runes."])
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

---------------------------------------------------------------- buff reminder
-- Greyed-out icons of missing self-buffs. Plain frames (nothing to cast), so they can change in combat.
-- Click-through, except while Shift is held so the row can be dragged.
local buffBar
local function HasAura(spells)
	for _, s in ipairs(spells) do
		if C_UnitAuras.GetPlayerAuraBySpellID(s) then return true end
	end
	return false
end
local function UpdateBuffs()
	-- the game hides your auras from addons in combat, so every buff looks missing; keep what we had and recheck after
	if not buffBar or InCombatLockdown() or UnitAffectingCombat("player") then return end
	local missing = {}
	if db.buffRemind and not UnitIsDeadOrGhost("player") then
		if db.remindArmor and not (HasAura(ARMORS.FROST) or HasAura(ARMORS.MAGE)) then
			-- the preferred armor if you know it, else whichever you do
			local other = db.armorType == "MAGE" and "FROST" or "MAGE"
			missing[#missing + 1] = BestKnown(ARMORS[db.armorType] or ARMORS.FROST) or BestKnown(ARMORS[other])
		end
		if db.remindInt and not HasAura(INTELLECT) then missing[#missing + 1] = BestKnown(INTELLECT) end
	end
	local w, h, GAP = db.buffWidth, db.buffHeight, db.spacing
	local cl, cr, ct, cb = ns.IconCoords(w, h, db.buffZoom / 100)
	local n = 0
	for _, f in ipairs(buffBar.icons) do f:Hide() end
	for _, spell in ipairs(missing) do -- a spell you don't know yet added nil, i.e. nothing
		n = n + 1
		local f = buffBar.icons[n]
		f:SetSize(w, h)
		f:ClearAllPoints()
		f:SetPoint("LEFT", (n - 1) * (w + GAP), 0)
		f.icon:SetTexture(C_Spell.GetSpellTexture(spell))
		f.icon:SetTexCoord(cl, cr, ct, cb)
		f:Show()
	end
	buffBar:SetSize(math.max(n, 1) * (w + GAP) - GAP, h)
	buffBar:SetFrameStrata(db.buffStrata)
	buffBar:SetShown(n > 0)
end
local function BuildBuffs()
	buffBar = CreateFrame("Frame", "ButtonsForeverBuffs", UIParent)
	buffBar:SetMovable(true)
	buffBar:SetClampedToScreen(true)
	buffBar:SetDontSavePosition(true)
	local p = db.buffPoint
	if p then buffBar:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else buffBar:SetPoint("CENTER", 0, 120) end
	buffBar:EnableMouse(false)
	buffBar:RegisterForDrag("LeftButton")
	buffBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
	buffBar:SetScript("OnDragStop", function(self) SavePoint(self, "buffPoint") end)
	buffBar.icons = {}
	for i = 1, 2 do
		local f = CreateFrame("Frame", nil, buffBar)
		f.icon = f:CreateTexture(nil, "ARTWORK")
		f.icon:SetAllPoints()
		f.icon:SetDesaturated(true)
		if E then
			f:SetTemplate()
			f.icon:SetInside()
		end
		buffBar.icons[i] = f
	end
	-- its own frame so UNIT_AURA only fires for the player, not every unit around
	local watch = CreateFrame("Frame")
	watch:RegisterUnitEvent("UNIT_AURA", "player")
	for _, e in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "MODIFIER_STATE_CHANGED", "PLAYER_REGEN_ENABLED" }) do
		watch:RegisterEvent(e)
	end
	watch:SetScript("OnEvent", function(_, event)
		if event == "MODIFIER_STATE_CHANGED" then
			buffBar:EnableMouse(IsShiftKeyDown()) -- click-through unless Shift is held
			if not IsShiftKeyDown() then buffBar:StopMovingOrSizing() end
		else
			UpdateBuffs()
		end
	end)
end

---------------------------------------------------------------- settings (Esc > Options > AddOns, or /bf)
local function BuildSettings()
	-- Pages: ButtonsForever (bar and look), then Trade Window, Reagents and Buff Reminder under it.
	local main, cat, layout -- cat, layout: the page being filled; the helpers below add to it
	local function Page(name)
		if main then
			cat, layout = Settings.RegisterVerticalLayoutSubcategory(main, name)
		else
			cat, layout = Settings.RegisterVerticalLayoutCategory(name)
			main = cat
		end
	end
	local function Header(text)
		if CreateSettingsListSectionHeaderInitializer then
			layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
		end
	end
	local function Apply()
		RefreshAll()
		SyncTrade()
		UpdateBuffs()
		CheckRunes() -- alert and marker settings
	end
	local function Add(key, name, onChange)
		local s = Settings.RegisterAddOnSetting(cat, addonName .. "_" .. key, key, db, type(DEFAULTS[key]), name, DEFAULTS[key])
		s:SetValueChangedCallback(onChange or Apply)
		return s
	end
	local function Checkbox(key, name, tip) return Settings.CreateCheckbox(cat, Add(key, name), tip) end
	local function Slider(key, name, min, max, tip, fmt)
		local o = Settings.CreateSliderOptions(min, max, 1)
		o:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
		return Settings.CreateSlider(cat, Add(key, name), o, tip)
	end
	-- choices: { {value, label}, ... }
	local function Dropdown(key, name, tip, choices, onChange)
		local function options()
			local c = Settings.CreateControlTextContainer()
			for _, choice in ipairs(type(choices) == "function" and choices() or choices) do c:Add(choice[1], choice[2]) end
			return c:GetData()
		end
		return Settings.CreateDropdown(cat, Add(key, name, onChange), options, tip)
	end
	-- Under(parent, key)(init): indent init under parent's checkbox, greyed out while db[key] is off
	local function Under(parent, key)
		return function(init) init:SetParentInitializer(parent, function() return db[key] end) end
	end
	local function Percent(v) return v .. "%" end
	local DIRECTIONS = { { "UP", L["Up"] }, { "DOWN", L["Down"] }, { "LEFT", L["Left"] }, { "RIGHT", L["Right"] } }
	local STRATAS = {
		{ "BACKGROUND", L["Background"] }, { "LOW", L["Low"] }, { "MEDIUM", L["Medium"] }, { "HIGH", L["High"] },
		{ "DIALOG", L["Dialog"] }, { "FULLSCREEN", L["Fullscreen"] }, { "FULLSCREEN_DIALOG", L["Fullscreen dialog"] },
		{ "TOOLTIP", L["Tooltip"] },
	}

	---------------- ButtonsForever: the flyout bar and how every button looks
	Page(addonName)
	Header(L["Flyout bar"])
	local bar = Checkbox("showBar", L["Show flyout bar"], L["Show the Teleport and Portal bar."])
	local BarSub = Under(bar, "showBar")
	BarSub(Checkbox("mouseover", L["Show bar on mouseover only"],
		L["Keeps the bar invisible until you move the mouse over it. It stays visible while a flyout is open."]))
	BarSub(Dropdown("barLayout", L["Bar layout"], L["Lay the bar's buttons out in a row, or in a column with one button per row."],
		{ { "HORIZONTAL", L["Horizontal"] }, { "VERTICAL", L["Vertical"] } }))
	BarSub(Dropdown("barDir", L["Bar flyout direction"], L["Which way the Teleport and Portal flyouts on the bar open."], DIRECTIONS))
	BarSub(Dropdown("barStrata", L["Bar strata"],
		L["Draw layer of the bar and its flyouts. Higher layers appear above more of the interface."], STRATAS))

	Header(L["Scrolls"])
	local scrolls = Checkbox("showScrolls", L["Show scrolls button"],
		L["Show the Scrolls button on the bar. It only appears while you have a scroll in your bags."])
	Under(scrolls, "showScrolls")(Dropdown("scrollSort", L["Scroll order"], L["How scrolls are ordered in the Scrolls flyout."], {
		{ "LEVEL", L["Required level"] }, { "NAME", L["Name"] }, { "COUNT", L["Most in bags"] },
	}))

	Header(L["Appearance"])
	Slider("width", L["Button width"], 16, 80, L["Width of every ButtonsForever button."])
	Slider("height", L["Button height"], 16, 80, L["Height of every ButtonsForever button."])
	Slider("zoom", L["Icon zoom"], 0, 30, L["Crops the icon's edges. Non-square buttons crop further so icons don't stretch."], Percent)
	Slider("spacing", L["Button spacing"], 0, 20,
		L["Gap in pixels between buttons that sit next to each other: on the bar, in flyouts and in the buff reminder."])
	Checkbox("elvui", L["Match ElvUI style"], L["Use ElvUI's button and panel look when ElvUI is installed. Takes effect after /reload."])

	---------------- Trade Window
	Page(L["Trade window"])
	local trade = Checkbox("showTrade", L["Show trade window panel"], L["Show the panel beside the trade window."])
	local TradeSub = Under(trade, "showTrade")
	TradeSub(Dropdown("tradeDir", L["Trade window flyout direction"], L["Which way the Portal flyout on the trade window panel opens."], DIRECTIONS))
	TradeSub(Dropdown("tradeStrata", L["Trade window strata"], L["Draw layer of the trade window panel and its flyout."], STRATAS))

	---------------- Reagents: low-reagent alert, auto-buy, and the reagents besides runes
	Page(L["Reagents"])
	Header(L["Alert"])
	local alert = Checkbox("runeAlert", L["Low-rune alert"],
		L["Warn when you're near a rune vendor (anywhere in a capital city, or close to a vendor in a town) and are low on Runes of Teleportation or Runes of Portals."])
	local Sub = Under(alert, "runeAlert")
	Sub(Slider("alertAt", L["Alert when runes are at or below"], 0, 20,
		L["Warn when you have this many of a rune or fewer. 0 warns only when you're out."]))
	Sub(Checkbox("alertWarning", L["Alert on screen"], L["Show the alert in the middle of the screen, like a raid warning."]))
	Sub(Checkbox("alertChat", L["Alert in chat"], L["Print the alert in the chat window."]))
	-- built when the dropdown opens, so sounds from addons that loaded after us are included
	local function sounds()
		local list = {}
		for _, s in ipairs(SOUNDS) do -- skip any sound this client doesn't have
			if s[1] == "NONE" or SOUNDKIT[s[1]] then list[#list + 1] = s end
		end
		local lsm = SharedMedia()
		if lsm then
			for _, name in ipairs(lsm:List("sound")) do
				if name ~= "None" then list[#list + 1] = { LSM_PREFIX .. name, name } end
			end
		end
		return list
	end
	Sub(Dropdown("alertSound", L["Alert sound"], L["Sound played with the alert. Picking one plays it."], sounds,
		function(_, value) PlayAlertSound(value) end))
	local test = CreateSettingsButtonInitializer(L["Test alert sound"], L["Play"],
		function() PlayAlertSound(db.alertSound) end, L["Play the chosen alert sound."], true)
	layout:AddInitializer(test)
	Sub(test)
	Sub(Checkbox("alertMap", L["Mark vendor on map"],
		L["Show a marker for the nearest rune vendor on your map and minimap. Your own waypoint isn't touched."]))
	local marks = { { 0, L["None"] } } -- RAID_TARGET_n are the game's own translated marker names
	for i = 1, 8 do
		marks[#marks + 1] = { i, ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:0|t %s"):format(i, _G["RAID_TARGET_" .. i]) }
	end
	Sub(Dropdown("vendorMark", L["Vendor marker"],
		L["Clicking the vendor's map or minimap icon targets the vendor and puts this marker on them. Out of combat only."], marks))

	Header(L["Auto-buy"])
	local buy = Checkbox("autoBuy", L["Auto-buy runes"], L["Top up your runes when you open a vendor that sells them."])
	local BuySub = Under(buy, "autoBuy")
	local buyTip = L["When a vendor that sells them is open, buy enough to have this many. 0 turns it off."]
	BuySub(Slider("buyTele", L["Auto-buy Runes of Teleportation"], 0, 100, buyTip))
	BuySub(Slider("buyPort", L["Auto-buy Runes of Portals"], 0, 100, buyTip))
	BuySub(Checkbox("buyConfirm", L["Confirm auto-buy"], L["Ask before auto-buying runes."]))

	-- own switch, alert level (uses the low-rune alert) and amount to keep (uses auto-buy)
	Header(L["Other reagents"])
	local function Reagent(on, at, keep, name, tip)
		local R = Under(Checkbox(on, name, tip), on)
		R(Slider(at, L["Alert at or below"], 0, 20, L["Warn when you have this many or fewer. Needs Low-rune alert on."]))
		R(Slider(keep, L["Auto-buy up to"], 0, 100,
			L["Keep this many when a vendor that sells it is open. 0 never buys it. Needs Auto-buy runes on."]))
	end
	Reagent("powder", "powderAt", "buyPowder", L["Arcane Powder"],
		L["Low-reagent alert and auto-buy for Arcane Powder, used by Arcane Brilliance."])

	---------------- Buff Reminder
	Page(L["Buff reminder"])
	local buffs = Checkbox("buffRemind", L["Buff reminder"],
		L["Show a greyed-out icon of your armor or Arcane Intellect while it isn't on you. Clicks pass through it; hold Shift to drag it."])
	local BuffSub = Under(buffs, "buffRemind")
	local spellName = C_Spell.GetSpellName
	BuffSub(Checkbox("remindArmor", L["Remind about armor"], L["Remind you when no armor spell is on you."]))
	BuffSub(Dropdown("armorType", L["Preferred armor"], L["Which armor the reminder shows. Any armor counts as on."], {
		{ "FROST", spellName(168) .. " / " .. spellName(7302) }, { "MAGE", spellName(6117) },
	}))
	BuffSub(Checkbox("remindInt", L["Remind about %s"]:format(spellName(1459)),
		L["Remind you when Arcane Intellect or Arcane Brilliance isn't on you."]))
	BuffSub(Slider("buffWidth", L["Reminder icon width"], 16, 80, L["Width of the buff reminder icons."]))
	BuffSub(Slider("buffHeight", L["Reminder icon height"], 16, 80, L["Height of the buff reminder icons."]))
	BuffSub(Slider("buffZoom", L["Reminder icon zoom"], 0, 30,
		L["Crops the icon's edges. Non-square buttons crop further so icons don't stretch."], Percent))
	BuffSub(Dropdown("buffStrata", L["Reminder strata"], L["Draw layer of the buff reminder icons."], STRATAS))

	Settings.RegisterAddOnCategory(main)
	SLASH_BUTTONSFOREVER1, SLASH_BUTTONSFOREVER2 = "/bf", "/buttonsforever"
	SlashCmdList.BUTTONSFOREVER = function() Settings.OpenToCategory(main:GetID()) end
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
		BuildBuffs()
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
		RefreshAll() -- show/hide scrolls (waits for combat to end)
		UpdateCounts()
		CheckRunes() -- catches using your last rune while in a city
	elseif event == "TRADE_SHOW" or event == "TRADE_CLOSED" then
		wantTrade = event == "TRADE_SHOW"
		SyncTrade()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if dirty then RefreshAll() end
		SyncTrade()
		if clicker and not (clicker:IsMouseOver() and clicker.owner:IsVisible()) then clicker:Hide() end
	else -- PLAYER_LOGIN, SPELLS_CHANGED
		RefreshAll()
		UpdateCounts()
		UpdateBuffs() -- learning a spell can add a reminder
	end
end)
