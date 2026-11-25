--[[
@description MeterBox - REAPER Master Meter
@author MeterBox
@version 0.8.0
@provides
  [main] MeterBox.lua
  MeterBox - Open Settings.lua
@about
  Stereo master peak meter with a JS_ReaScriptAPI overlay in REAPER's transport bar.
  Requires js_ReaScriptAPI for transport mode; floating mode is available as fallback.
]]
local S="MeterBox"
local D={mode="floating",locked=true,x=8,y=5,w=176,h=42,bg="171B20",track="303840",left="35DDB0",right="35DDB0",peak="F4F6F8",scale="69737D",text="D8DEE6",labels=false,hold=true,min=-60,max=0}
local c={}
for k,v in pairs(D) do
 local s=reaper.GetExtState(S,k)
 if s=="" then c[k]=v elseif type(v)=="boolean" then c[k]=s=="1" elseif type(v)=="number" then c[k]=tonumber(s) or v else c[k]=s end
end
local function save() for k,v in pairs(c) do reaper.SetExtState(S,k,tostring(v),true) end end
-- MeterBox is a standalone floating window; never attach it to the transport.
c.mode="floating"
save()
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function db(v) if not v or v<=0 then return c.min end return clamp(20*math.log(v,10),c.min,c.max) end
local function norm(v) return clamp((v-c.min)/(c.max-c.min),0,1) end
local function rgb(h) return 0xFF000000 | (tonumber(h,16) or 0) end
local function gfxcol(h) local n=rgb(h); gfx.set(((n>>16)&255)/255,((n>>8)&255)/255,(n&255)/255,1) end
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
local function draw_gfx()
 local w,h=gfx.w,gfx.h
 gfxcol(c.bg); gfx.rect(0,0,w,h,1)
 local p=5; local lw=c.labels and 12 or 0; local bx=p+lw; local bw=math.max(8,w-bx-p)
 local bh=math.max(4,math.floor((h-17)/2))
 for i,v in ipairs({L,R}) do
  local y=4+(i-1)*(bh+4)
  if c.labels then gfxcol(c.text); gfx.x=p; gfx.y=y-2; gfx.drawstr(i==1 and "L" or "R") end
  gfxcol(c.track); gfx.rect(bx,y,bw,bh,1)
  gfxcol(i==1 and c.left or c.right); gfx.rect(bx,y,bw*norm(v),bh,1)
  if c.hold then gfxcol(c.peak); gfx.rect(bx+bw*norm(i==1 and HL or HR),y-1,1,bh+2,1) end
 end
 gfxcol(c.scale)
 for i=0,6 do local x=bx+bw*i/6; gfx.line(x,h-5,x,h-2) end
 gfx.update()
end
-- Standalone floating meter window. It is intentionally not composited
-- into the transport, so it remains a separate movable REAPER gfx window.
local floating=false
local function start_float()
 gfx.init("MeterBox",c.w,c.h,0)
 gfx.setfont(1,"Arial",11)
 floating=true
end
-- Settings are handled by a separate action/script instance. This avoids
-- sharing the meter's gfx context with the settings window.
local function request_settings()
 reaper.SetExtState(S,"open_settings","1",false)
end
local function start_float() gfx.init("MeterBox",c.w,c.h,0); gfx.setfont(1,"Arial",11); floating=true end
local function loop()
 levels()
 if not floating then start_float() end
 if gfx.getchar()<0 then floating=false; return end
 if (gfx.mouse_cap&2)==2 then request_settings() end
 draw_gfx()
 reaper.defer(loop)
end
if not reaper.GetMasterTrack or not reaper.Track_GetPeakInfo then reaper.ShowMessageBox("Master peak API unavailable.","MeterBox",0); return end
if c.mode=="transport" and not jsok then
 local a=reaper.ShowMessageBox("Transport overlay requires js_ReaScriptAPI. Choose Yes for floating mode, or No to stop.","MeterBox",1)
 if a==1 then c.mode="floating"; save() else return end
end
reaper.SetExtState(S,"running","1",false)
reaper.atexit(function()
 reaper.SetExtState(S,"running","",false); destroy()
 if font and reaper.JS_LICE_DestroyFont then pcall(reaper.JS_LICE_DestroyFont,font) end
 gfx.quit()
end)
loop()
