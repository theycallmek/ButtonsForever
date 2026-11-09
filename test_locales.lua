-- Out-of-game check: every locale translates every L["..."] key used in ButtonsForever.lua,
-- with the same number of %d placeholders. Run: luajit test_locales.lua
local keys = {}
for key in io.open("ButtonsForever.lua"):read("*a"):gmatch('L%["(.-)"%]') do keys[key] = true end

local function placeholders(s) return select(2, s:gsub("%%d", "")) end

local failures = 0
for _, code in ipairs({ "deDE", "esES", "esMX", "frFR", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }) do
	GetLocale = function() return code end
	local ns = {}
	assert(loadfile("Locales.lua"))("ButtonsForever", ns)
	for key in pairs(keys) do
		local text = rawget(ns.L, key)
		if not text then
			print(code .. " missing: " .. key)
			failures = failures + 1
		elseif placeholders(text) ~= placeholders(key) then
			print(code .. " wrong %d count: " .. key)
			failures = failures + 1
		end
	end
end

GetLocale = function() return "enUS" end
local ns = {}
assert(loadfile("Locales.lua"))("ButtonsForever", ns)
assert(ns.L["Teleports"] == "Teleports", "enUS falls back to the key")

assert(failures == 0, failures .. " locale problems")
print("ok")
