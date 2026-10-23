-- Fight history: a copy of the "current" segment of each boss fight, kept
-- in ShaguDPS_Fights (per character, so it survives a reload or logout).
--
-- A fight counts as a boss fight when somebody in the group targeted a boss
-- (classification "worldboss" or a skull level) while it ran. It is named
-- after that boss, and marked as a kill when the boss died during it.

local parser = ShaguDPS.parser
local data = ShaguDPS.data

local MAX_FIGHTS = 10

local fights = CreateFrame("Frame")
ShaguDPS.fights = fights

-- newest first: { id, name, kill, duration, ended, damage, heal, classes }
fights.list = {}
fights.next_id = 1

local boss, boss_dead

local function IsBoss(unit)
  if not UnitExists(unit) or UnitIsPlayer(unit) or UnitIsFriend("player", unit) then return nil end
  -- Post-fight heals can open another parser segment while someone still
  -- targets the corpse. Only an engaged, living boss identifies a new attempt.
  if UnitIsDead(unit) or not UnitAffectingCombat(unit) then return nil end
  return UnitClassification(unit) == "worldboss" or UnitLevel(unit) == -1
end

-- the units whose targets are checked for a boss
local scan_units = { "target", "targettarget" }
for i = 1, 4 do table.insert(scan_units, "party" .. i .. "target") end
for i = 1, 40 do table.insert(scan_units, "raid" .. i .. "target") end

local function ScanForBoss()
  local raid = GetNumRaidMembers()
  for _, unit in pairs(scan_units) do
    -- skip raid units of a smaller raid
    local _, _, n = string.find(unit, "^raid(%d+)")
    if not n or tonumber(n) <= raid then
      if IsBoss(unit) then return UnitName(unit) end
    end
  end
end

local function Copy(t)
  local c = {}
  for k, v in pairs(t) do
    c[k] = type(v) == "table" and Copy(v) or v
  end
  return c
end

-- class and pet owner of everyone in the fight, so colors and pet names
-- still work after a reload
local function Classes(damage, heal)
  local c = {}
  for _, segment in pairs({ damage, heal }) do
    for name in pairs(segment) do
      c[name] = data.classes[name]
      local owner = data.classes[name]
      if owner and data.classes[owner] then c[owner] = data.classes[owner] end
    end
  end
  return c
end

fights.Get = function(self, id)
  for _, fight in pairs(self.list) do
    if fight.id == id then return fight end
  end
end

fights.Reset = function(self)
  for k in pairs(self.list) do self.list[k] = nil end
end

-- the fight shown by a window: segment 2 with config.fight = id
fights.ForWindow = function(self, wconfig)
  local fight = self:Get(wconfig.fight)
  if fight then
    -- restore class colors of fights from an earlier session
    for name, class in pairs(fight.classes) do
      if not data.classes[name] then data.classes[name] = class end
    end
  end
  return fight
end

parser.OnFightStart = function()
  boss, boss_dead = nil, nil
end

parser.OnFightEnd = function(duration)
  if not boss or duration < 5 then return end
  if not next(data.damage[1]) and not next(data.heal[1]) then return end

  local fight = {
    id = fights.next_id,
    name = boss,
    kill = boss_dead,
    duration = duration,
    ended = date and date("%H:%M") or "",
    damage = Copy(data.damage[1]),
    heal = Copy(data.heal[1]),
  }
  fight.classes = Classes(fight.damage, fight.heal)

  fights.next_id = fights.next_id + 1
  table.insert(fights.list, 1, fight)
  while table.getn(fights.list) > MAX_FIGHTS do
    table.remove(fights.list)
  end

  boss, boss_dead = nil, nil
end

-- look for a boss once a second while a fight runs
fights:SetScript("OnUpdate", function()
  if (this.tick or 0) > GetTime() then return end
  this.tick = GetTime() + 1
  if not parser.fight.active or boss then return end
  boss = ScanForBoss()
end)

-- "Onyxia dies."
local death_pattern
if UNITDIESOTHER then
  -- escape the pattern characters of the text, then turn "%s" into a capture
  death_pattern = string.gsub(UNITDIESOTHER, "([%.%-%+%*%?%[%]%^%$%(%)])", "%%%1")
  death_pattern = "^" .. string.gsub(death_pattern, "%%s", "(.+)") .. "$"
end

fights:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
fights:RegisterEvent("VARIABLES_LOADED")
fights:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    ShaguDPS_Fights = ShaguDPS_Fights or {}
    fights.list = ShaguDPS_Fights
    for _, fight in pairs(fights.list) do
      if fight.id >= fights.next_id then fights.next_id = fight.id + 1 end
    end
  elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" and boss and death_pattern and arg1 then
    local _, _, name = string.find(arg1, death_pattern)
    if name == boss then boss_dead = true end
  end
end)
