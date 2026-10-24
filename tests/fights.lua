-- Run from the repository root using Lua 5.0: lua tests/fights.lua
local now, in_combat, dead = 0, true, false
function GetTime() return now end
function GetNumRaidMembers() return 2 end
function GetNumPartyMembers() return 0 end
function UnitExists(unit) return unit == 'target' or unit == 'player' or unit == 'raid1' or unit == 'raid2' end
function UnitIsPlayer(unit) return UnitExists(unit) and unit ~= 'target' end
function UnitIsFriend(_, unit) return unit ~= 'target' end
function UnitIsDead(unit) return unit == 'target' and dead end
function UnitAffectingCombat(unit) return UnitExists(unit) and in_combat and not UnitIsDead(unit) end
function UnitClassification() return 'worldboss' end
function UnitLevel() return -1 end
function UnitName(unit)
  if unit == 'target' then return 'Hakkar' end
  if unit == 'player' or unit == 'raid1' then return 'Tester' end
  if unit == 'raid2' then return 'Healer' end
end
function UnitClass() return 'Priest', 'PRIEST' end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end
function CreateFrame()
  return {scripts={},RegisterEvent=function() end,SetScript=function(self,k,fn) self.scripts[k]=fn end}
end
gsub,strsub=string.gsub,string.sub
UNITDIESOTHER='%s dies.'
ShaguDPS={parser={},config={merge_pets=1},data={damage={[0]={},[1]={}},heal={[0]={},[1]={}},classes={Tester='PRIEST',Healer='PRIEST'}}}
dofile('parser.lua')
dofile('fights.lua')
local parser, fights = ShaguDPS.parser, ShaguDPS.fights
local function scan()
  this=fights
  fights.scripts.OnUpdate()
end
local function heal()
  parser:AddData('Healer','Heal','Tester',100,2,'heal')
end
parser.combat:UpdateState()
parser:AddData('Tester','Smite','Hakkar',1000,2,'damage')
scan()
now=60
event,arg1='CHAT_MSG_COMBAT_HOSTILE_DEATH','Hakkar dies.'
fights.scripts.OnEvent()
dead,in_combat=true,false
parser.combat:UpdateState()
assert(table.getn(fights.list)==1 and fights.list[1].kill, 'save real boss kill')
-- Healing after combat starts a small parser segment while the corpse remains targeted.
now=61
heal()
scan()
now=67
heal()
now=73
parser.combat:UpdateState()
assert(table.getn(fights.list)==1, 'post-kill healing with a boss corpse must not create a duplicate wipe')
assert(fights.list[1].damage.Tester._sum==1000, 'preserve original kill data')
-- An alive but unengaged boss must not turn pre-pull healing into a wipe either.
now,dead=75,false
heal()
scan()
now=81
heal()
now=87
parser.combat:UpdateState()
assert(table.getn(fights.list)==1, 'pre-pull healing must not save a boss attempt')
-- A genuine subsequent pull and wipe should still be kept separately.
now,in_combat=90,true
parser.combat:UpdateState()
parser:AddData('Tester','Smite','Hakkar',200,2,'damage')
scan()
now,in_combat=100,false
parser.combat:UpdateState()
assert(table.getn(fights.list)==2 and not fights.list[1].kill, 'retain a genuine new wipe')
assert(fights.list[1].name=='Hakkar' and fights.list[2].kill)
-- Saved history must be a snapshot, independent of later segment edits.
ShaguDPS.data.damage[1].Tester._sum=9999
assert(fights.list[2].damage.Tester._sum==1000)
-- Modern ClassicAPI: destination GUID, not localized text or source, decides kills.
CombatLogGetCurrentEventInfo = function() end
local guid = '0xBOSS1'
UnitGUID = function() return guid end
dofile('fights.lua')
fights = ShaguDPS.fights
now, in_combat, dead = 110, true, false
parser.fight.active = true
parser.OnFightStart()
scan()
event, arg1 = 'CHAT_MSG_COMBAT_HOSTILE_DEATH', 'Hakkar dies.'
fights.scripts.OnEvent()
event, arg2, arg8 = 'COMBAT_LOG_EVENT_UNFILTERED', 'UNIT_DIED', '0xOTHER'
fights.scripts.OnEvent()
parser.OnFightEnd(10)
assert(not fights.list[1].kill, 'ignore a same-name mob or unrelated death')
now = 120
parser.OnFightStart()
scan()
event, arg2, arg3, arg8 = 'COMBAT_LOG_EVENT_UNFILTERED', 'UNIT_DIED', true, guid
fights.scripts.OnEvent()
parser.OnFightEnd(10)
assert(fights.list[1].kill, 'source-less GUID death marks the boss kill')
now, guid = 130, nil
parser.OnFightStart()
scan()
event, arg1 = 'CHAT_MSG_COMBAT_HOSTILE_DEATH', 'Hakkar dies.'
fights.scripts.OnEvent()
parser.OnFightEnd(10)
assert(fights.list[1].kill, 'chat fallback when boss GUID cannot be resolved')
print('Fight history regression checks passed (Lua 5.0)')
