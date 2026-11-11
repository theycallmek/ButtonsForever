-- Out-of-game self-check: luajit test_logic.lua
local ns = {}
assert(loadfile("Logic.lua"))("ButtonsForever", ns)
local function near(a, b) return math.abs(a - b) < 1e-9 end

local RANKS = {
	{ spell = 1, item = 101, level = 1 },
	{ spell = 2, item = 102, level = 5 },
	{ spell = 3, item = 103, level = 15 },
	{ spell = 4, item = 104, level = 25 },
}

-- PickRank
local function knows(max) return function(id) return id <= max end end
assert(ns.PickRank(RANKS, 17, knows(4)) == 3, "level 17 gets the level-15 rank")
assert(ns.PickRank(RANKS, 17, knows(2)) == 2, "falls back to best rank I know")
assert(ns.PickRank(RANKS, 60, knows(4)) == 4, "high level gets top rank")
assert(ns.PickRank(RANKS, nil, knows(3)) == 3, "unknown level gets best known")
assert(ns.PickRank(RANKS, 3, knows(4)) == 1, "low level gets rank 1")
assert(ns.PickRank(RANKS, 17, knows(0)) == nil, "nothing known")

-- UsableCount
local bags = { [101] = 5, [103] = 40, [104] = 20 }
local function count(item) return bags[item] or 0 end
assert(ns.UsableCount(RANKS, 17, count) == 45, "level 17 can't use item 104")
assert(ns.UsableCount(RANKS, nil, count) == 65, "unknown level counts everything")
assert(ns.UsableCount(RANKS, 3, count) == 5, "level 3 only rank 1")

-- PickStacks
local function it(itemID, c, bag, slot)
	return { itemID = itemID, count = c, maxStack = 20, bag = bag, slot = slot }
end
local items = {
	it(101, 20, 0, 1),
	it(103, 20, 0, 2),
	it(103, 7, 0, 3), -- partial, skipped
	it(999, 20, 0, 4), -- not conjured, skipped
	it(104, 20, 1, 1),
	it(103, 20, 1, 2),
}
local s = ns.PickStacks(items, RANKS, 2, 17)
assert(#s == 2 and s[1].itemID == 103 and s[2].itemID == 103, "best two usable full stacks")
assert(#ns.PickStacks(items, RANKS, 6, 17) == 3, "only usable full stacks")
local all = ns.PickStacks(items, RANKS, 6)
assert(#all == 4 and all[1].itemID == 104, "no level = no filter, highest first")
assert(#ns.PickStacks(items, RANKS, 6, 0) == 0, "level 0 can use nothing")

-- RunesToAlert
local function rune(item, known, c) return { item = item, known = known, count = c } end
local alerted = {}
local a = ns.RunesToAlert(true, { rune(1, true, 0), rune(2, true, 5), rune(3, false, 0) }, alerted, 0)
assert(#a == 1 and a[1] == 1, "only known runes at 0")
assert(#ns.RunesToAlert(true, { rune(1, true, 0) }, alerted, 0) == 0, "once per visit")
ns.RunesToAlert(false, { rune(1, true, 0) }, alerted, 0)
assert(#ns.RunesToAlert(true, { rune(1, true, 0) }, alerted, 0) == 1, "again after leaving the city")
ns.RunesToAlert(true, { rune(1, true, 3) }, alerted, 0)
assert(#ns.RunesToAlert(true, { rune(1, true, 0) }, alerted, 0) == 1, "again after restocking and running out")
assert(#ns.RunesToAlert(false, { rune(1, true, 0) }, {}, 0) == 0, "never outside a city")
assert(#ns.RunesToAlert(true, { rune(1, true, 1) }, {}, 1) == 1, "at the threshold alerts")
assert(#ns.RunesToAlert(true, { rune(1, true, 2) }, {}, 1) == 0, "above the threshold doesn't")

-- TopUp
assert(ns.TopUp(3, 10) == 7 and ns.TopUp(12, 10) == 0 and ns.TopUp(0, 0) == 0, "buy up to the target")

-- Nearest
local pts = { { 10, 10 }, { 50, 50 }, { 90, 20 } }
assert(ns.Nearest(pts, 48, 55, 1000, 1000) == pts[2], "nearest point")
assert(ns.Nearest(pts, 85, 10, 1000, 1000) == pts[3], "nearest point 2")
assert(ns.Nearest(pts, nil, nil) == pts[1], "no position: first point")
local _, d = ns.Nearest({ { 50, 50 } }, 47, 46, 1000, 1000)
assert(near(d, 50), "distance in yards: 30 east, 40 north of a 1000-yard map = 50")

-- MinimapOffset
local x, y, edge = ns.MinimapOffset(50, 0, 100, 70)
assert(near(x, 35) and near(y, 0) and not edge, "east is right")
x, y = ns.MinimapOffset(0, -50, 100, 70)
assert(near(x, 0) and near(y, 35), "north is up")
x, y, edge = ns.MinimapOffset(300, 0, 100, 70)
assert(near(x, 70) and edge, "clamped to the edge")
x, y = ns.MinimapOffset(0, -50, 100, 70, math.pi / 2) -- facing west, vendor north: shows to the right
assert(near(x, 35) and near(y, 0), "rotating minimap")

-- IconCoords
local l, r, t, b = ns.IconCoords(36, 36, 0)
assert(l == 0 and r == 1 and t == 0 and b == 1, "square, no zoom")
l, r, t, b = ns.IconCoords(36, 36, 0.1)
assert(near(l, 0.1) and near(r, 0.9) and near(t, 0.1) and near(b, 0.9), "square zoom")
l, r, t, b = ns.IconCoords(60, 30, 0)
assert(l == 0 and r == 1 and near(t, 0.25) and near(b, 0.75), "wide crops vertically")
l, r, t, b = ns.IconCoords(30, 60, 0)
assert(near(l, 0.25) and near(r, 0.75) and t == 0 and b == 1, "tall crops horizontally")
l, r, t, b = ns.IconCoords(60, 30, 0.1)
assert(near((r - l) / (b - t), 2), "wide keeps 2:1 aspect with zoom")
print("ok")
