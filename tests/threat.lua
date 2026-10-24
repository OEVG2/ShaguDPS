-- Run from the repository root with Lua 5.0: lua tests/threat.lua
local now, party, raid, target, combat = 10, 1, 0, true, true
local sent, refreshes, draws = {}, 0, 0
local visible = true
function GetTime() return now end
function GetNumPartyMembers() return party end
function GetNumRaidMembers() return raid end
function UnitExists() return target end
function UnitIsPlayer() return nil end
function UnitIsDead() return nil end
function UnitClassification() return 'elite' end
function UnitAffectingCombat() return combat end
function UnitName(unit) return unit == 'player' and 'Tester' or 'Boss' end
function SendAddonMessage(prefix, text, channel)
  table.insert(sent, {prefix, text, channel})
end
function CreateFrame()
  return {scripts={}, RegisterEvent=function() end,
    SetScript=function(self, name, fn) self.scripts[name] = fn end}
end
ShaguDPS = {
  config = {[1]={view=5,bars=8}},
  data = {classes={}},
  parser = {ScanName=function() end, callbacks={refresh={function() refreshes=refreshes+1 end}}},
  window = {[1]={IsVisible=function() return visible end, Refresh=function() draws=draws+1 end}},
}
dofile('threat.lua')
local threat, data = ShaguDPS.threat, ShaguDPS.data
local function update()
  this = threat
  threat.scripts.OnUpdate()
end
local function emit(kind, text)
  this, event, arg1, arg2 = threat, kind, 'SERVER', text
  threat.scripts.OnEvent()
end
update()
assert(table.getn(sent) == 1 and sent[1][1] == 'TWT_UDTSv4' and sent[1][2] == 'limit=8' and sent[1][3] == 'PARTY')
emit('CHAT_MSG_ADDON', 'TWTv4=Tank:1:1000.5:100.0:1;Tester:0:500.25:50.0:1;#TMTv1=ignored')
assert(data.threat.Tank and data.threat.Tank._sum == 1000.5, 'decimal threat must be parsed')
assert(data.threat.Tester._perc == 50 and data.threat.Tester._melee)
assert(data.threat['Pull Aggro']._sum == 1100)
now = 12
emit('CHAT_MSG_ADDON', 'TWTv4=Tank:1:1200:100:1;Tester:0:700:58:0;Bad:0:oops:10:1;')
assert(data.threat.Tester._tps == 99.875)
assert(not data.threat.Bad)
assert(data.threat['Pull Aggro']._sum == 1560)
update()
assert(table.getn(sent) == 1, 'recent external answers suppress duplicate queries')
now = 13.5
update()
assert(table.getn(sent) == 2, 'queries resume after external answers stop')
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:0:0:0:0;')
assert(not data.threat.Tank and not data.threat['Pull Aggro'])
emit('PLAYER_TARGET_CHANGED')
assert(not next(data.threat))
assert(not threat.last_answer and threat.pending)
assert(table.getn(sent) == 3, 'target changes query immediately')
now, party = 15, 0
update()
assert(table.getn(sent) == 3, 'no queries while solo')
now, party, combat = 16, 1, false
update()
assert(table.getn(sent) == 3, 'no queries out of combat')
now, combat, visible = 17, true, false
update()
assert(table.getn(sent) == 3, 'no queries with hidden threat windows')
now, visible, raid = 18, true, 10
update()
assert(sent[4][3] == 'RAID')
assert(refreshes > 0)
now = 22
update()
assert(string.find(threat:GetStatus(), 'No threat reply', 1, true))
party, raid = 0, 0
assert(string.find(threat:GetStatus(), 'Join a party', 1, true))
party, target = 1, false
assert(string.find(threat:GetStatus(), 'Select a living', 1, true))
target, combat = true, false
assert(string.find(threat:GetStatus(), 'enter combat', 1, true))
combat = true
emit('PLAYER_TARGET_CHANGED')
assert(string.find(threat:GetStatus(), 'Waiting for threat data', 1, true))
emit('CHAT_MSG_ADDON', 'TWTv4=')
assert(string.find(threat:GetStatus(), 'no threat entries', 1, true))
-- Poll at 2 Hz, without waiting for the normal window refresh timer.
emit('PLAYER_TARGET_CHANGED')
now = 30
update()
local requests, previous_draws = table.getn(sent), draws
now = 30.21
update()
assert(table.getn(sent) == requests, 'polls must be rate limited')
now = 30.51
update()
assert(table.getn(sent) == requests + 1, 'poll again after 0.5 seconds')
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:100:100:1;')
assert(draws > previous_draws, 'visible threat window refreshes immediately')
assert(data.threat.Tester._tps == 0, 'first sample has no elapsed time')
now = 30.71
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:120:100:1;')
assert(math.abs(data.threat.Tester._tps - 100) < 0.001, 'TPS updates on the next sample')
now = 30.91
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:110:100:1;')
assert(data.threat.Tester._tps == 0, 'threat reduction resets TPS baseline')
now = 31.11
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:130:100:1;')
assert(math.abs(data.threat.Tester._tps - 100) < 0.001)
emit('CHAT_MSG_ADDON', 'TWTv4=')
now = 31.3
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:200:100:1;')
assert(data.threat.Tester._tps == 0, 'returning players start a fresh sample')
visible = false
previous_draws = draws
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:210:100:1;')
assert(draws == previous_draws, 'hidden windows are not redrawn')
-- Recent replies from another addon must not suppress a new target query.
visible = true
now = 40
emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:300:100:1;')
local before_switch = table.getn(sent)
emit('PLAYER_TARGET_CHANGED')
assert(table.getn(sent) == before_switch + 1)
assert(not next(data.threat), 'clear previous target data immediately')
update()
assert(table.getn(sent) == before_switch + 1, 'no duplicate poll in the same frame')
visible = false
emit('PLAYER_TARGET_CHANGED')
assert(table.getn(sent) == before_switch + 1, 'hidden windows do not query on target change')
visible, target = true, false
emit('PLAYER_TARGET_CHANGED')
assert(table.getn(sent) == before_switch + 1, 'no query when target is lost')
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage=function(self, text) table.insert(messages, text) end }
now, visible, target = 50, true, true
threat.last_foreign = nil
threat:Measure()
for sample = 0, 19 do
  now = 50 + sample * 0.5
  update()
  emit('CHAT_MSG_ADDON', 'TWTv4=Tester:1:300:100:1;')
end
assert(table.getn(messages) == 1, 'diagnostic does not spam each packet')
now = 60
update()
assert(table.getn(messages) == 2)
assert(string.find(messages[2], '20 requests (2.00/s)', 1, true))
assert(string.find(messages[2], '20 replies (2.00/s)', 1, true))
assert(string.find(messages[2], '0 changed replies', 1, true))
now = 61
update()
assert(table.getn(messages) == 2, 'measurement stops automatically')
print('Threat regression checks passed (Lua 5.0)')
