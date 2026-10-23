-- Synthetic Lua 5.0 benchmark, run from the repository root:
-- lua tests/threat-benchmark.lua 0.5 (then 0.2)
-- Simulates 10 minutes at 60 FPS with 40 entries per reply.
-- Includes packet generation and parsing; WoW rendering/networking are mocked.
local input = assert(io.open('threat.lua'))
local source = input:read('*a')
input:close()
local interval = tonumber(arg[1])
source = string.gsub(source, 'local INTERVAL = [%d%.]+', 'local INTERVAL = '..interval)
local now, requests, draws = 0, 0, 0
local frames = 600 * 60
function GetTime() return now end
function GetNumPartyMembers() return 0 end
function GetNumRaidMembers() return 40 end
function UnitExists() return true end
function UnitIsPlayer() return false end
function UnitIsDead() return false end
function UnitClassification() return 'worldboss' end
function UnitAffectingCombat() return true end
function UnitName(unit) return unit == 'player' and 'Player1' or 'Boss' end
function CreateFrame()
 return {scripts={}, RegisterEvent=function() end,SetScript=function(self,k,f) self.scripts[k]=f end}
end
ShaguDPS={config={[1]={view=5,bars=40}},data={classes={}},parser={ScanName=function() end,callbacks={refresh={}}},window={[1]={IsVisible=function() return true end,Refresh=function() draws=draws+1 end}}}
local rows={}
function SendAddonMessage()
 requests=requests+1
 for i=1,40 do rows[i]='Player'..i..':'..(i==1 and '1' or '0')..':'..(requests*100+i)..'.5:100.0:1' end
 event,arg2='CHAT_MSG_ADDON','TWTv4='..table.concat(rows,';')
 ShaguDPS.threat.scripts.OnEvent()
end
assert(loadstring(source))()
collectgarbage()
local before=gcinfo()
local start=os.clock()
for frame=1,frames do
 now=frame/60
 this=ShaguDPS.threat
 this.scripts.OnUpdate()
end
local elapsed=os.clock()-start
local peak=gcinfo()
collectgarbage()
print(string.format('interval=%.1fs, simulated=600s, requests=%d, rows=%d, mock redraws=%d, CPU=%.4fs, CPU/reply=%.3fms, heap before/after GC=%.1f/%.1fKB, heap at end=%.1fKB',interval,requests,requests*40,draws,elapsed,elapsed/requests*1000,before,gcinfo(),peak))
