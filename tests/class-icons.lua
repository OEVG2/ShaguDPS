-- Exercise the actual icon/layout helper without loading the full WoW UI.
ShaguDPS = { expansion=function() return 'vanilla' end, window={}, config={class_icons=1,height=15,spacing=0} }
local f = assert(io.open('window.lua'))
local source = f:read('*a')
f:close()
local boundary = assert(string.find(source, '-- default backdrops', 1, true))
assert(loadstring(string.sub(source, 1, boundary - 1)))()
local icon = {
 SetTexture=function(self,v) self.texture=v end,
 SetTexCoord=function(self,a,b,c,d) self.coords={a,b,c,d} end,
 SetWidth=function(self,v) self.width=v end, SetHeight=function(self,v) self.height=v end,
 SetPoint=function() end, Show=function(self) self.shown=true end, Hide=function(self) self.shown=false end,
}
local bar = {CreateTexture=function() return icon end,textLeft={SetPoint=function(self,a,b,c,x) self.offset=x end}}
local update = ShaguDPS.window.UpdateClassIcon
update(bar, 'MAGE')
assert(icon.shown and icon.width==13 and bar.textLeft.offset==18)
assert(icon.coords[1]==.25 and icon.coords[2]==.5)
update(bar, 'PRIEST')
assert(icon.coords[1]==.5 and icon.coords[3]==.25, 'recycled bar updates class')
update(bar, nil)
assert(not icon.shown and bar.textLeft.offset==5, 'threshold/unknown rows have no icon gap')
ShaguDPS.config.class_icons=0
update(bar, 'MAGE')
assert(not icon.shown and bar.textLeft.offset==5, 'toggle restores original layout')
ShaguDPS.config.class_icons=1
ShaguDPS.config.height=24
ShaguDPS.config.spacing=2
update(bar,'WARRIOR')
assert(icon.shown and icon.width==20 and bar.textLeft.offset==25, 'icons follow bar sizing')
print('Class icon layout checks passed (Lua 5.0)')
