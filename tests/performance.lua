-- Exercise the real command through its slash handler with mocked profiling APIs.
ShaguDPS = {settings={}, window={}, parser={}, config={}, textures={}}
local now, snapshots, cpuSnapshots = 0, 0, 0
local messages, frames = {}, {}
DEFAULT_CHAT_FRAME = {AddMessage=function(self,s) table.insert(messages,s) end}
function CreateFrame()
 local f={SetScript=function(self,key,fn) self[key]=fn end}
 table.insert(frames,f)
 return f
end
function GetTime() return now end
strlower=string.lower
SlashCmdList={}
local file=assert(io.open('settings.lua'))
local source=file:read('*a');file:close()
local start=assert(string.find(source,'-- Profiling is opt-in.',1,true))
assert(loadstring('local config, textures = ShaguDPS.config, ShaguDPS.textures\n' .. string.sub(source,start)))()
local function run() SlashCmdList.SHAGUMETER('perf') end
run()
assert(string.find(messages[1],'no addon profiling APIs',1,true))
UpdateAddOnMemoryUsage=function() snapshots=snapshots+1 end
GetAddOnMemoryUsage=function(name) assert(name=='ShaguDPS');return snapshots==1 and 100 or 120 end
GetCVar=function() return '0' end
run()
assert(snapshots==1)
now=9;frames[1].OnUpdate();assert(snapshots==1)
now=10;frames[1].OnUpdate();assert(snapshots==2 and frames[1].OnUpdate==nil)
assert(string.find(messages[table.getn(messages)],'120.0 KB (+20.0 KB',1,true))
UpdateAddOnCPUUsage=function() cpuSnapshots=cpuSnapshots+1 end
GetAddOnCPUUsage=function() return cpuSnapshots==1 and 50 or 75 end
GetCVar=function() return '1' end
run()
now=20;frames[1].OnUpdate()
assert(cpuSnapshots==2 and frames[1].OnUpdate==nil)
assert(string.find(messages[table.getn(messages)],'25.00 ms over 10.0s (2.50 ms/s)',1,true))
assert(snapshots==4, 'memory snapshots only at measurement boundaries')
print('Performance diagnostic checks passed (Lua 5.0)')
