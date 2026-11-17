# ButtonsForever

[![CurseForge](https://img.shields.io/badge/CurseForge-ButtonsForever-f16436)](https://www.curseforge.com/wow/addons/buttonsforever)
[![Wago](https://img.shields.io/badge/Wago-ButtonsForever-c1272d)](https://addons.wago.io/addons/buttonsforever)
[![GitHub release](https://img.shields.io/github/v/release/theycallmek/ButtonsForever)](https://github.com/theycallmek/ButtonsForever/releases/latest)

Download from [CurseForge](https://www.curseforge.com/wow/addons/buttonsforever), [Wago](https://addons.wago.io/addons/buttonsforever) or [GitHub Releases](https://github.com/theycallmek/ButtonsForever/releases/latest).

A mage addon for **World of Warcraft: Forever**. It folds every city teleport and portal into two flyout buttons, adds a trade window helper for conjuring and handing out food and water, and keeps you stocked on runes with a low-rune alert and auto-buy.

The addon does nothing on characters that aren't mages.

## Features

### Teleport and Portal flyouts

![The Teleports flyout open on a level 22 mage, showing Orgrimmar and Undercity, with the rune count on each button](.previews/flyout.png)
- A small bar with two buttons, **Teleports** and **Portals**. Click one to open a flyout of the city spells you know, then click a city to cast it. The flyout closes after casting, or when you click anywhere else. In combat, clicking elsewhere doesn't close it, because WoW blocks addons from doing that; click the button again instead.
- They work in combat.
- Each button shows how many runes you have: Rune of Teleportation for teleports, Rune of Portals for portals. The number turns red at 0.
- A third button, **Scrolls**, holds Forever's 22 new mage scrolls (the ones from Bundle of Scrolls, such as Scroll of Minor Evocation or Scroll of Cat Familiar). Only scrolls in your bags appear, and the button itself appears only while you have at least one. Click a scroll to use it. Scrolls picked up or used in combat appear or disappear when combat ends.
- **Shift-drag** any button to move the bar. Its position is saved.

### Low-rune alert
When you're near a rune vendor and running low on a rune you need, the addon tells you to restock. "Near" means:

- **Capital cities:** anywhere in Stormwind, Ironforge, Darnassus, Orgrimmar, Undercity or Thunder Bluff.
- **Towns:** when you walk into the town of a rune vendor in Elwynn Forest, Duskwood, Swamp of Sorrows, Wetlands, Alterac Mountains, Arathi Highlands, Hillsbrad Foothills, The Hinterlands, The Barrens, Ashenvale, Thousand Needles, Stonetalon Mountains, Feralas, Dustwallow Marsh and Silithus. Entering the zone alone doesn't set it off; it goes off when you walk into the vendor's town, such as Crossroads or Astranaar. Towns are recognised by ID, so this works in every language.
- **Your faction only:** vendors in the other faction's cities and towns never alert you, since you can't buy from them. Neutral vendors in Alterac Mountains, Arathi Highlands and Silithus alert everyone.

How it works:

- **When it fires:** when you have that many of a rune or fewer, 1 by default (you pick 0–20). It checks only on game events, with no timers running: when you enter a zone, city or area, when your bags change (so using a rune there can set it off), and when you close a vendor.
- **The warning:** "You have 1 Rune of Teleportation left. Buy more from a reagent vendor." It can show in the middle of the screen like a raid warning, in chat, or both, with a sound you choose.
- **Vendor marker:** it puts a rune icon on your world map and minimap at the nearest rune vendor. If the vendor is beyond the minimap's range, the icon sits dimmed on the minimap's edge, pointing the way. It's the addon's own marker, so any waypoint you've set is left alone. It's removed once you've restocked above the threshold or left the area.
- **Vendor name and targeting:** hovering the marker shows the vendor's name, or every rune vendor's name in a city that has several. Clicking it targets the vendor and puts a raid marker on them, a star by default. Clicking works out of combat only and when the vendor is close enough to target. If they're too far, chat says so.
- It warns once per visit for each rune, and only about runes used by spells you know. A mage who hasn't learned portals yet won't be warned about Runes of Portals.
- **Other reagents:** Arcane Powder (for Arcane Brilliance) is covered too, with its own on/off switch, alert level and auto-buy amount.

### Auto-buy runes
When you open a vendor that sells runes, the addon tops you up to the amount you set, 10 of each by default:

- **Only the difference:** with 3 Runes of Teleportation in your bags and a target of 10, it buys 7. If you already have enough, nothing happens.
- **Confirmation:** by default a popup shows what it will buy and the total price, for example "Buy 7 x Rune of Teleportation, 10 x Rune of Portals for …?" with the price filled in. Turn the confirmation off to buy straight away. Either way, chat says what was bought.
- **Gold:** if you can't afford it, it buys nothing and says how much gold is needed.
- **Your spells:** it only buys runes for spells you know. Set an amount to 0 to never buy that rune.

### Buff reminder
A greyed-out icon appears while you're missing a self-buff, and disappears once you cast it:

- **Armor:** shows when none of Frost Armor, Ice Armor or Mage Armor is on you. The icon is your best rank of the armor you prefer (Frost/Ice by default, or Mage Armor).
- **Arcane Intellect:** shows when neither Arcane Intellect nor Arcane Brilliance is on you, including one cast by another mage.
- Clicks pass straight through the icons. Hold **Shift** and drag to move them; the position is saved.
- It updates only when your buffs change, with no timers running, and hides while you're dead.
- In combat, the game hides your buffs from addons, so the icons stay as they were when combat started and update when it ends.

### Trade window helper
Open a trade with someone and a panel appears beside the trade window:

![The ButtonsForever panel beside the trade window, set up for a level 17 trade partner](.previews/trade-window.png)

- **A Portal flyout**, for porting the person you're trading with.
- **Conjure Water / Conjure Food** buttons cast the highest rank your trade partner can use. For example, a level 17 gets level 15 water. If you don't know that rank yet, they use the best one you do know. The panel title shows your partner's level.
- The number on each Conjure button is how much of that food or water in your bags your partner can use.
- **Add Water / Add Food** put full stacks of 20 into the trade window, highest usable rank first. Type how many stacks (1–6) in the box beside each button; the amounts are remembered. You still click Trade yourself, because addons aren't allowed to accept trades.

### Settings
Type `/bf` (or `/buttonsforever`), or go to **Esc → Options → AddOns → ButtonsForever**.

![The ButtonsForever settings panel](.previews/settings.png)

The settings are split over four pages: **ButtonsForever**, with **Trade window**, **Reagents** and **Buff reminder** listed under it. Settings shown in bold are on/off switches; the settings under each one grey out while it's off.

#### ButtonsForever

| Setting | What it does |
|---|---|
| **Show flyout bar** | Turns the Teleport and Portal bar on or off |
| Show bar on mouseover only | Keeps the bar invisible until you hover it. It stays visible while a flyout is open |
| Bar layout | Horizontal (a row, the default) or Vertical (a column, one button per row) |
| Bar flyout direction | Up, Down, Left or Right (default Up) |
| Bar strata | Which interface layer the bar is drawn on, from Background to Tooltip (default Medium). Raise it if other frames cover the buttons |
| **Show scrolls button** | Turns the Scrolls button on the bar on or off (default on). It still only appears while you have a scroll |
| Scroll order | How the Scrolls flyout is ordered: Required level (default), Name, or Most in bags |
| Button width / height | Size of every bar and trade panel button, 16–80 pixels each |
| Icon zoom | Crops the icon's edges, 0–30%. Non-square buttons crop instead of stretching the icon |
| Button spacing | Gap between buttons next to each other on the bar, in flyouts and in the buff reminder, 0–20 pixels (default 3) |
| Match ElvUI style | Uses ElvUI's look when ElvUI is installed. Needs `/reload` |

#### Trade window

| Setting | What it does |
|---|---|
| **Show trade window panel** | Turns the panel beside the trade window on or off |
| Trade window flyout direction | Up, Down, Left or Right (default Right) |
| Trade window strata | Interface layer of the panel (default High) |

#### Reagents

| Setting | What it does |
|---|---|
| **Low-rune alert** | Turns the low-reagent warning on or off (default on) |
| Alert when runes are at or below | Warn at this many runes or fewer, 0–20 (default 1). 0 warns only when you're out |
| Alert on screen / Alert in chat | Where the warning shows: the middle of the screen like a raid warning, the chat window, or both (both on by default) |
| Alert sound | None, Raid warning (default), Ready check, Alarm clock, Whisper or Map ping. Picking one plays it. Sounds shared by other addons through LibSharedMedia (ElvUI, SharedMedia packs and others) are added to the list automatically |
| Test alert sound | A **Play** button that plays the chosen sound |
| Mark vendor on map | A marker on the world map and minimap at the nearest rune vendor (default on). Your own waypoint isn't touched |
| Vendor marker | The raid marker put on the vendor when you click the map or minimap marker: None, or any of the 8 raid markers (default Star) |
| **Auto-buy runes** | Turns auto-buy on or off (default on) |
| Auto-buy Runes of Teleportation / Portals | How many of each to keep, 0–100 (default 10). 0 never buys that rune |
| Confirm auto-buy | Ask before buying (default on) |
| **Arcane Powder** | Turns the Arcane Powder alert and auto-buy on or off (default on). Only for spells you know |
| Alert at or below | Warn at this many or fewer, 0–20 (default 1). Uses the Low-rune alert settings |
| Auto-buy up to | How many to keep, 0–100 (default 20). Uses Auto-buy runes and its confirmation |

#### Buff reminder

| Setting | What it does |
|---|---|
| **Buff reminder** | Turns the buff reminder icons on or off (default on) |
| Remind about armor / Arcane Intellect | Turn either reminder off (both on by default) |
| Preferred armor | Which armor's icon is shown: Frost/Ice Armor (default) or Mage Armor. Any armor counts as on |
| Reminder icon width / height / zoom | Same as the bar's, for the reminder icons (defaults 36, 36, 8%) |
| Reminder strata | Interface layer of the reminder icons (default Medium) |

## Installation

Copy the `ButtonsForever` folder into your Forever AddOns folder, for example `World of Warcraft\_forever_\Interface\AddOns\ButtonsForever`, then restart the game or `/reload`.

## Languages

Spells and items are looked up by ID, so the addon works on every client. The addon's own labels are translated for German, Spanish (Spain and Mexico), French, Portuguese (Brazil), Russian, Korean, and Simplified and Traditional Chinese. Italian uses English, matching Forever's Italian client.

Rune vendor names come built in for every language, taken from wowhead's translated vendor lists, so clicking the vendor marker targets the right NPC on any client. If the game has the vendor's name cached, the addon uses that instead.

The spell terms in each translation were checked against wowhead's in-game names. The rest of the wording is a draft, and corrections from native speakers are welcome. To add or fix a language, edit `Locales.lua`. Any missing text falls back to English.

## Development

| File | Contents |
|---|---|
| `ButtonsForever.toc`, `ButtonsForever_Forever.toc` | Addon metadata, Interface `16001`. Identical; the `_Forever` copy tells WoWUp it's a Forever addon, so keep both in sync |
| `icon.tga` | The 64×64 icon shown in the AddOn List |
| `Locales.lua` | Translated UI text |
| `Logic.lua` | Pure logic with no game API: rank picking, stack picking, scroll sorting, icon cropping, rune alert and auto-buy amounts, vendor distance, minimap marker position |
| `ButtonsForever.lua` | Frames, secure buttons, events, settings, and the rune vendor locations |

Run the out-of-game tests with [LuaJIT](https://luajit.org/), which uses Lua 5.1 like WoW:

```
luajit test_logic.lua
luajit test_locales.lua
```

`test_locales.lua` checks that every language has every label, with matching `%d` placeholders.

### Notes
- Spell and item IDs are Classic Era's, which Forever reuses. Each one has a comment naming the spell or item, and they were checked against wowhead's Forever pages.
- Cities and zones are recognised by map ID (Classic's), and the rune vendor coordinates come from wowhead's Forever data.
- Forever uses retail's (Midnight's) addon restrictions. Spells are cast only from secure buttons, and the flyouts open through a secure handler, which is what lets them work in combat. Size and layout changes made in combat apply when combat ends.
