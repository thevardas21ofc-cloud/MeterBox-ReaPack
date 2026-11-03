--[[
@description MeterBox - REAPER Master Meter
@author MeterBox
@version 0.5.1
@provides
  [main] MeterBox.lua
  MeterBox - Open Settings.lua
@about
  Stereo master peak meter. Reads the REAPER master track directly.
  Right-click the meter to open settings. Transport overlay requires js_ReaScriptAPI.
]]
local S="MeterBox"
local D={mode="floating",locked=true,w=250,h=42,bg="20252B",track="38424C",left="36D6A0",right="58A6FF",peak="F4F5F7",labels=true,hold=true,min=-60,max=0}
local c={}
for k,v in pairs(D) do
 local x=reaper.GetExtState(S,k)
 if x=="" then c[k]=v elseif type(v)=="boolean" then c[k]=x=="1" elseif type(v)=="number" then c[k]=tonumber(x) or v else c[k]=x end
end
local function save() for k,v in pairs(c) do reaper.SetExtState(S,k,tostring(v),true) end end
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function db(v) if not v or v<=0 then return c.min end return clamp(20*math.log(v,10),c.min,c.max) end
local function norm(v) return clamp((v-c.min)/(c.max-c.min),0,1) end
local function color(h) local n=tonumber(h,16) or 0; gfx.set(((n>>16)&255)/255,((n>>8)&255)/255,(n&255)/255,1) end
local L,R,HL,HR=c.min,c.min,c.min,c.min
local function levels()
 local m=reaper.GetMasterTrack(0)
 L=db(reaper.Track_GetPeakInfo(m,0)); R=db(reaper.Track_GetPeakInfo(m,1))
 if reaper.Track_GetPeakHoldDB then
  local a,b=reaper.Track_GetPeakHoldDB(m,0,false),reaper.Track_GetPeakHoldDB(m,1,false)
  if type(a)=="number" then HL=clamp(a*.01,c.min,c.max) end
  if type(b)=="number" then HR=clamp(b*.01,c.min,c.max) end
 end
end
local function draw()
 local w,h=gfx.w,gfx.h
 color(c.bg); gfx.rect(0,0,w,h,1)
 local p=7; local lw=c.labels and 16 or 0; local bh=math.max(5,(h-17)/2); local bw=w-p-lw-p
 for i,v in ipairs({L,R}) do
  local y=p+(i-1)*(bh+3)
  if c.labels then gfx.set(0.85,0.88,0.91,1); gfx.x=p; gfx.y=y-1; gfx.drawstr(i==1 and "L" or "R") end
  color(c.track); gfx.rect(p+lw,y,bw,bh,1)
  color(i==1 and c.left or c.right); gfx.rect(p+lw,y,bw*norm(v),bh,1)
  if c.hold then color(c.peak); gfx.rect(p+lw+bw*norm(i==1 and HL or HR),y-1,1,bh+2,1) end
 end
 gfx.update()
end
local settings=false
local function settings_window()
 settings=true; gfx.init("MeterBox Settings",320,220,0)
end
local function settings_draw()
 gfx.set(.1,.12,.14,1); gfx.rect(0,0,320,220,1)
 gfx.set(.9,.92,.95,1); gfx.x=15; gfx.y=12; gfx.drawstr("METERBOX SETTINGS")
 local rows={"Labels: "..tostring(c.labels),"Peak markers: "..tostring(c.hold),"Meter width: "..c.w,"Meter height: "..c.h,"Palette: "..(c.left=="36D6A0" and "Mint / Blue" or "Green / Amber"),"Close"}
 for i,t in ipairs(rows) do gfx.x=18; gfx.y=42+(i-1)*28; gfx.drawstr(t) end
 gfx.update()
 if gfx.mouse_cap&1==1 and not down then
  down=true; local y=gfx.mouse_y
  if y>=35 and y<65 then c.labels=not c.labels
  elseif y<93 and y>=65 then c.hold=not c.hold
  elseif y<121 and y>=93 then c.w=c.w+25; if c.w>400 then c.w=175 end
  elseif y<149 and y>=121 then c.h=c.h+4; if c.h>58 then c.h=26 end
  elseif y<177 and y>=149 then if c.left=="36D6A0" then c.left,c.right="7CDA65","FFB454" else c.left,c.right="36D6A0","58A6FF" end
  elseif y>=177 then settings=false; gfx.quit() end
  save()
 elseif gfx.mouse_cap&1==0 then down=false end
 local ch=gfx.getchar(); if ch<0 or ch==27 then settings=false; gfx.quit() end
end
local down=false
gfx.init("MeterBox",c.w,c.h,0); gfx.setfont(1,"Arial",11)
reaper.SetExtState(S,"running","1",false)
reaper.atexit(function() reaper.SetExtState(S,"running","",false); gfx.quit() end)
local function loop()
 if reaper.GetExtState(S,"open_settings")=="1" then reaper.SetExtState(S,"open_settings","",false); settings_window() end
 levels()
 if settings then settings_draw() else
  if gfx.getchar()<0 then return end
  if gfx.mouse_cap&2==2 then settings_window() else draw() end
 end
 reaper.defer(loop)
end
if not reaper.Track_GetPeakInfo then reaper.ShowMessageBox("Master peak API unavailable.","MeterBox",0); return end
loop()
