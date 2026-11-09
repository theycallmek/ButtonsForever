-- Out-of-game self-check: luajit test_logic.lua
local ns = {}
assert(loadfile("Logic.lua"))("ButtonsForever", ns)

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

-- IconCoords
local function near(a, b) return math.abs(a - b) < 1e-9 end
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
