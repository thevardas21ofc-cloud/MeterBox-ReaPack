--[[
@description MeterBox - Open Settings
@author MeterBox
@version 0.8.1
@about Opens a separate, movable settings window for the running MeterBox master meter.
]]
local S="MeterBox"
if reaper.GetExtState(S,"running")=="" then
 reaper.ShowMessageBox("Start MeterBox first, then open settings.","MeterBox",0)
 return
end
local defaults={mode="transport",locked=true,w=176,h=42,bg="171B20",track="303840",left="35DDB0",right="35DDB0",peak="F4F6F8",scale="69737D",text="D8DEE6",labels=false,hold=true}
local c={}
for k,v in pairs(defaults) do
 local s=reaper.GetExtState(S,k)
 if s=="" then c[k]=v
 elseif type(v)=="boolean" then c[k]=s=="1"
 elseif type(v)=="number" then c[k]=tonumber(s) or v
 else c[k]=s end
end
local function save()
 for k,v in pairs(c) do reaper.SetExtState(S,k,tostring(v),true) end
end
local function rgb(h) return tonumber(h,16) or 0 end
local function color(h)
 local n=rgb(h); gfx.set(((n>>16)&255)/255,((n>>8)&255)/255,(n&255)/255,1)
end
local function button(x,y,w,h,label,active)
 color(active and "315B53" or "343B43")
 gfx.roundrect(x,y,w,h,5,1)
 color("E8EDF2"); gfx.x=x+8; gfx.y=y+7; gfx.drawstr(label)
end
local swatches={"35DDB0","58A6FF","7CDA65","FFB454","F06B82","B58CFF","E6E9ED","FFFFFF","20252B","171B20","303840","69737D"}
local rows={{"left","Left meter"},{"right","Right meter"},{"track","Meter background"},{"bg","Panel background"},{"peak","Peak marker"},{"scale","Scale marks"}}
local function cycle(key)
 local n=1
 for i,v in ipairs(swatches) do if v==c[key] then n=i end end
 c[key]=swatches[n%#swatches+1]
end
local x,y=160,120
if reaper.JS_Window_GetRect then
 local ok,l,t,r,b=reaper.JS_Window_GetRect(reaper.GetMainHwnd())
 if ok then x=math.max(0,math.floor(l+(r-l-420)/2)); y=math.max(0,math.floor(t+(b-t-410)/2)) end
end
gfx.init("MeterBox Settings",420,410,0,x,y)
gfx.setfont(1,"Arial",14)
local hwnd
if gfx.gethwnd then hwnd=gfx.gethwnd() end
if hwnd and reaper.JS_Window_IsWindow and reaper.JS_Window_IsWindow(hwnd) then
 if reaper.JS_Window_Show then reaper.JS_Window_Show(hwnd,"SHOW") end
 if reaper.JS_Window_SetZOrder then reaper.JS_Window_SetZOrder(hwnd,"TOP",nil) end
 if reaper.JS_Window_SetForeground then reaper.JS_Window_SetForeground(hwnd) end
end
local mouse_down=false
local function draw()
 color("171B20"); gfx.rect(0,0,420,410,1)
 color("E8EDF2"); gfx.x=16; gfx.y=14; gfx.drawstr("METERBOX  /  APPEARANCE")
 color("89949F"); gfx.x=16; gfx.y=38; gfx.drawstr("Settings are saved automatically.")
 button(16,62,388,30,"Standalone floating meter window",true)
 button(16,100,188,30,"Lock position: "..(c.locked and "ON" or "OFF"),c.locked)
 button(216,100,188,30,"Peak hold: "..(c.hold and "ON" or "OFF"),c.hold)
 button(16,138,188,30,"Width: "..c.w.." px  (+16)",false)
 button(216,138,188,30,"Height: "..c.h.." px  (+4)",false)
 for i,r in ipairs(rows) do
  local yy=180+(i-1)*29
  button(16,yy,188,25,r[2],false)
  color(c[r[1]]); gfx.rect(216,yy+5,188,15,1)
 end
 button(16,365,388,28,"Close settings",false)
 gfx.update()
end
local function loop()
 draw()
 if (gfx.mouse_cap&1)~=0 and not mouse_down then
  mouse_down=true
  local mx,my=gfx.mouse_x,gfx.mouse_y
  if my>=100 and my<130 then if mx<210 then c.locked=not c.locked else c.hold=not c.hold end
  elseif my>=138 and my<168 then
   if mx<210 then c.w=c.w+16; if c.w>400 then c.w=144 end
   else c.h=c.h+4; if c.h>64 then c.h=30 end end
  elseif my>=180 and my<354 then
   local i=math.floor((my-180)/29)+1
   if rows[i] then cycle(rows[i][1]) end
  elseif my>=365 then gfx.quit(); return end
  save()
 elseif (gfx.mouse_cap&1)==0 then mouse_down=false end
 local ch=gfx.getchar()
 if ch<0 or ch==27 then gfx.quit(); return end
 reaper.defer(loop)
end
reaper.atexit(function() gfx.quit() end)
loop()
