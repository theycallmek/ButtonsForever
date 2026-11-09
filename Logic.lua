-- Pure helpers (no WoW API) so they can be tested outside the game: luajit test_logic.lua
local _, ns = ...

-- Icon texcoords for a w x h button: crop `zoom` (0-0.5) off each edge, then crop the
-- long axis further so the icon keeps its square aspect instead of stretching.
function ns.IconCoords(w, h, zoom)
	local l, r, t, b = zoom, 1 - zoom, zoom, 1 - zoom
	local span = 1 - 2 * zoom
	if w > h then
		local pad = span * (1 - h / w) / 2
		t, b = t + pad, b - pad
	elseif h > w then
		local pad = span * (1 - w / h) / 2
		l, r = l + pad, r - pad
	end
	return l, r, t, b
end

-- ranks: { {spell = spellID, item = itemID, level = item's required level}, ... } lowest rank first.
-- level: trade partner's level, nil = unknown (anything goes).
local function usable(r, level) return not level or r.level <= level end

-- Highest known rank whose item `level` can use, or nil.
function ns.PickRank(ranks, level, isKnown)
	local best
	for _, r in ipairs(ranks) do
		if isKnown(r.spell) and usable(r, level) then best = r.spell end
	end
	return best
end

-- Total number of conjured items from `ranks` in the bags that `level` can use.
function ns.UsableCount(ranks, level, getCount)
	local n = 0
	for _, r in ipairs(ranks) do
		if usable(r, level) then n = n + getCount(r.item) end
	end
	return n
end

-- items: { {itemID, count, maxStack, bag, slot}, ... }
-- Returns up to n full stacks from `ranks` usable at `level`, highest rank first.
function ns.PickStacks(items, ranks, n, level)
	local rankLevel = {}
	for _, r in ipairs(ranks) do
		if usable(r, level) then rankLevel[r.item] = r.level end
	end
	local out = {}
	for _, it in ipairs(items) do
		if rankLevel[it.itemID] and it.count == it.maxStack then out[#out + 1] = it end
	end
	table.sort(out, function(a, b) return rankLevel[a.itemID] > rankLevel[b.itemID] end)
	for i = #out, n + 1, -1 do out[i] = nil end
	return out
end
