# ShaguDPS 4.3 for WoW 1.18.1 Clients

A very small and lightweight damage and healing meter, updated for 1.18.1 clients.
It reads structured combat events from **ClassicAPI** or **Nampower** when they are
loaded, and falls back to parsing the chat combat log on a plain client.

Based on [ShaguDPS](https://github.com/shagu/ShaguDPS) by Shagu and the Nampower
parser from [Duciel's fork](https://github.com/Duciel/ShaguDPS).

## What's new in 4.0

**Data sources**
- **ClassicAPI** (preferred): reads `COMBAT_LOG_EVENT_UNFILTERED`, which needs a
  ClassicAPI build that includes the combat log. Units come with
  GUIDs and group/pet flags, so group members, pets, guardians and totems are found
  without scanning names on every hit, and nothing depends on the client language.
- **Nampower**: reads `SPELL_DAMAGE_EVENT_*`, `AUTO_ATTACK_*`, `DAMAGE_SHIELD_*` and
  `SPELL_HEAL_BY_*`. Turns on Nampower's auto attack and heal events
  (`NP_EnableAutoAttackEvents`, `NP_EnableSpellHealEvents`) when it is used.
  Needs GUID unit tokens, which SuperWoW or ClassicAPI provide; without them it
  isn't used (it used to take over and record nothing).
- **Chat combat log**: the original text parser, used when neither is available.
- Pick one in the settings or with `/sdps source`; "Auto" takes the best one loaded.
  The settings show which source is in use.
- Unit lookups are cached per GUID, so busy raids cost less.
- Pets and totems of group members are matched to their owner through the GUID
  (`UnitOwnerGUID` with ClassicAPI, the owner token with SuperWoW).

**Boss fight history** (new in 4.3)
- The segment menu reads *Current*, *Fights*, *Overall*. *Fights* opens the last
  10 boss fights, newest first, with their length; wipes are greyed out.
- A fight counts as a boss fight when someone in the group targeted a raid boss
  (boss classification or skull level) during it. Trash fights aren't kept.
- Picking one shows its damage and healing; chat reports name the boss, kill or
  wipe and the fight length.
- The history is saved per character and survives reloads and logouts. A raid
  boss fight takes roughly 50 KB, so ten of them stay under 1 MB. *Reset Data*
  clears it too.

**Three modes** (new in 4.2)
- *Damage* shows total damage, damage per second and share on one bar, for
  example `37.0k (2388.4 DPS, 62.1%)`; *Heal* does the same for effective
  healing (`1500 (96.8 HPS, 100.0%)`), with overhealing as the lighter bar behind
  it. Large numbers are shortened (`37.0k`, `1.23m`); chat reports
  use the same short numbers and add the overhealing to heal lines.
- Windows that showed DPS or HPS switch to Damage or Heal.
- Fixed the Lua error when sending the heal report to chat.

**Threat view** (new in 4.1)
- A third mode next to Damage and Heal: the threat list of your current
  target, straight from the server's threat API (the same one TWThreat uses).
- Shows each player's threat and percent of the tank's threat, with a red
  *Pull Aggro* line where you would take aggro: 110% of the tank in melee range,
  130% at range. Player bars show threat, TPS and percent; hover a bar to see
  who has aggro. The *Pull Aggro* row is a threshold, so it has no TPS value.
- The segment button shows the target's name in this mode.
- Asks the server twice a second, only while a window shows threat, you are in a
  party or raid and your target is an elite or boss in combat. If TWThreat is
  also running, ShaguDPS reads its answers instead of asking a second time.
  Switching targets requests fresh data immediately.
  Replies refresh visible threat windows immediately; actual update speed
  depends on the server and, when sharing replies, the other addon's query rate.
- TPS is averaged over a rolling five-second window. Old threat bars clear when
  the target dies, combat ends, you leave the group, or no reply arrives for
  three seconds. A fresh reply restores the display.
- If your player is missing from the reply, the pull threshold shows a
  110–130% range; the bar marks its upper end until your range is known.

**Per second time**
- *Active Time* (default, as before): each unit's own time spent dealing damage.
- *Fight Duration*: the time the whole segment lasted, the same for everyone, like
  most raid parses. Windows keep ticking while a fight runs.
- Bar tooltips show the active time, and in fight duration mode the fight time and
  the share of it the unit was active.

**Classic theme** (default; switch back with *Theme: Flat* or `/sdps theme 0`)
- Tooltip-style window in a neutral dark fill with the silver border.
- Gold title buttons and icons that light up on hover, no boxes.
- Silver rule under the title, quest-log glow on hovered bars and menu entries.
- Dropdown lists as tooltip panels.
- Shadowed text instead of outlines, a dark track behind each bar.
- Settings in the stock dialog box with the gold header plate, stock checkboxes,
  page arrows and close button.

**Window**
- *Blizzard Retail (Modern)* is texture 8 (`/sdps texture 8`). It uses the
  supplied retail bar texture and modern colors for all nine classes at full
  opacity, including Warlock (0.53, 0.53, 0.93). Pastel lightening is bypassed
  for all class colors with this preset.
- Class icons appear beside player names in Damage, Heal and Threat. Toggle
  *Show Class Icons* in settings; icons scale with bar height.
- Lock button left of the + button locks or unlocks moving and resizing of all windows.
- Three more bar textures in the style of Puppeteer's health bars: *Puppeteer*
  (with the shine), *Puppeteer Shineless* and *Puppeteer Flat*. *Blizzard* is the
  stock bar. The settings show the textures by name.

**Fixes**
- New windows start with the size and view of the first window.
- Long names no longer run into the numbers on the bars.
- Unmerged pets show as "Owner - Pet" instead of "Owner - Pet (Owner)".
- Fixed the best effective heal value used for the heal bar scale.
- Bars of different windows no longer share global frame names.
- The settings window closes with Escape.
- When the selected data source can't be used, the settings say why and which
  source is used instead (for example a ClassicAPI build without the combat log).
- Less work per combat event and per refresh: names and labels are cached, damage
  events skip the target name lookup, and only the units that get a bar are read
  when a window refreshes. Hidden windows don't refresh.

## Installation
1. Download the latest version and unpack it.
2. Make sure the folder is named `ShaguDPS` (not `ShaguDPS-master`).
3. Copy `ShaguDPS` into `Wow-Directory\Interface\AddOns`.
4. Restart the game.

Optional client mods: [ClassicAPI](https://github.com/brues-code/ClassicAPI),
[Nampower](https://github.com/pepopo978/nampower), SuperWoW.

## Commands

`/shagudps`, `/sdps` or `/sd`:

```
/sdps config           Open the settings
/sdps threatdebug      Measure threat requests/replies for 10 seconds
/sdps visible 1        Show main window (0 or 1)
/sdps height 15        Bar height (any number)
/sdps spacing 0        Bar spacing
/sdps trackall 0       Track all nearby units (0 or 1)
/sdps mergepet 1       Merge pets into owner data (0 or 1)
/sdps source 1         Data source (1 auto, 2 ClassicAPI, 3 Nampower, 4 chat log)
/sdps time 0           Per second time (0 active time, 1 fight duration)
/sdps texture 2        Statusbar texture (1 to 8)
/sdps pastel 0         Use pastel colors (0 or 1)
/sdps backdrop 1       Show window backdrop and border (0 or 1)
/sdps theme 1          Theme (0 flat, 1 classic), needs a reload
/sdps lock 0           Lock windows
/sdps toggle           Toggle visibility of the main window
```

## Combat Log Range

ShaguDPS has no raid-syncing between players: it sees what your client is told about,
which is limited by the combat log range (40 yards by default). This applies to every
data source. To raise it to 200:

    /run for _,n in pairs({"Party", "PartyPet", "FriendlyPlayers", "FriendlyPlayersPets", "HostilePlayers", "HostilePlayersPets", "Creature" }) do SetCVar("CombatLogRange"..n, 200) end

Or in your Config.wtf:

    SET CombatLogRangeParty "200"
    SET CombatLogRangePartyPet "200"
    SET CombatLogRangeFriendlyPlayers "200"
    SET CombatLogRangeFriendlyPlayersPets "200"
    SET CombatLogRangeHostilePlayers "200"
    SET CombatLogRangeHostilePlayersPets "200"
    SET CombatLogRangeCreature "200"

Some unitframe addons rely on the range being exactly "40" for their range checks,
and some reset it back to "40".
