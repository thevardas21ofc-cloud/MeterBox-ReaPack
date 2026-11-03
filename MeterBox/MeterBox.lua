--[[
@description MeterBox - REAPER Master Meter
@author MeterBox
@version 0.5.4
@provides
  [main] MeterBox.lua
  MeterBox - Open Settings.lua
@about
  Stereo master peak meter with a JS_ReaScriptAPI overlay in REAPER's transport bar.
  Requires js_ReaScriptAPI for transport mode; floating mode is available as fallback.
]]
local S="MeterBox"
local D={mode="transport",locked=true,x=8,y=5,w=250,h=38,bg="20252B",track="38424C",left="36D6A0",right="58A6FF",peak="F4F5F7",text="D8DEE6",labels=true,hold=true,min=-60,max=0}
local c={}
for k,v in pairs(D) do
 local s=reaper.GetExtState(S,k)
 if s=="" then c[k]=v elseif type(v)=="boolean" then c[k]=s=="1" elseif type(v)=="number" then c[k]=tonumber(s) or v else c[k]=s end
end
local function save() for k,v in pairs(c) do reaper.SetExtState(S,k,tostring(v),true) end end
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
 local p=6; local lw=c.labels and 15 or 0; local bh=math.max(4,(h-15)/2); local bw=w-p-lw-p
 for i,v in ipairs({L,R}) do
  local y=p+(i-1)*(bh+3)
  if c.labels then gfxcol(c.text); gfx.x=p; gfx.y=y-1; gfx.drawstr(i==1 and "L" or "R") end
  gfxcol(c.track); gfx.rect(p+lw,y,bw,bh,1)
  gfxcol(i==1 and c.left or c.right); gfx.rect(p+lw,y,bw*norm(v),bh,1)
  if c.hold then gfxcol(c.peak); gfx.rect(p+lw+bw*norm(i==1 and HL or HR),y,1,bh,1) end
 end
 gfx.update()
end
-- Transport overlay (JS_ReaScriptAPI / LICE)
local function api(n) return reaper.APIExists(n) end
local jsok=api("JS_Composite") and api("JS_Composite_Unlink") and api("JS_LICE_CreateBitmap") and api("JS_LICE_DestroyBitmap") and api("JS_LICE_Clear") and api("JS_LICE_FillRect") and api("JS_Window_FindChild") and api("JS_Window_GetClientSize") and api("JS_Window_ScreenToClient") and api("JS_Window_InvalidateRect") and api("JS_Mouse_GetState")
local hwnd,bmp,bw,bh,linked
local font
local function find_transport()
 local main=reaper.GetMainHwnd()
 local h=reaper.JS_Window_FindChild(main,"Transport",true)
 if not h and reaper.JS_Window_Find then h=reaper.JS_Window_Find("Transport",true) end
 return h
end
local function unlink()
 if hwnd and bmp and linked then pcall(reaper.JS_Composite_Unlink,hwnd,bmp,true) end
 linked=false
end
local function destroy()
 unlink()
 if bmp then pcall(reaper.JS_LICE_DestroyBitmap,bmp) end
 bmp=nil; bw=nil; bh=nil
end
local function lice_rect(x,y,w,h,col)
 if w>0 and h>0 then reaper.JS_LICE_FillRect(bmp,x,y,w,h,rgb(col),1,"COPY") end
end
local function draw_lice()
 reaper.JS_LICE_Clear(bmp,0x00000000)
 lice_rect(0,0,bw,bh,c.bg)
 local p=5; local lw=c.labels and 13 or 0; local barh=math.max(4,math.floor((bh-13)/2)); local barx=p+lw; local barw=math.max(8,bw-barx-p)
 for i,v in ipairs({L,R}) do
  local y=p+(i-1)*(barh+3)
  if c.labels and reaper.JS_LICE_CreateFont and not font then font=reaper.JS_LICE_CreateFont() end
  if c.labels and font and reaper.JS_LICE_DrawText then
   reaper.JS_LICE_SetFontColor(font,rgb(c.text))
   reaper.JS_LICE_DrawText(bmp,font,i==1 and "L" or "R",1,2,y-2,barx-1,y+barh+2)
  end
  lice_rect(barx,y,barw,barh,c.track)
  lice_rect(barx,y,math.floor(barw*norm(v)),barh,i==1 and c.left or c.right)
  if c.hold then lice_rect(clamp(barx+math.floor(barw*norm(i==1 and HL or HR)),barx,barx+barw-1),y-1,1,barh+2,c.peak) end
 end
end
local function attach()
 if not jsok then return false end
 hwnd=find_transport()
 if not hwnd or not reaper.JS_Window_IsWindow(hwnd) then return false end
 local _,cw,ch=reaper.JS_Window_GetClientSize(hwnd)
 if not cw or not ch or cw<10 or ch<10 then return false end
 local w=clamp(c.w,150,math.max(150,cw-c.x-2)); local h=clamp(c.h,24,math.max(24,ch-c.y-2))
 if not bmp or bw~=w or bh~=h then
  destroy(); bmp=reaper.JS_LICE_CreateBitmap(true,w,h); bw=w; bh=h
  if not bmp then return false end
  linked=reaper.JS_Composite(hwnd,c.x,c.y,w,h,bmp,0,0,w,h,true)~=0
 end
 if not linked then linked=reaper.JS_Composite(hwnd,c.x,c.y,w,h,bmp,0,0,w,h,true)~=0 end
 if not linked then return false end
 draw_lice()
 reaper.JS_Window_InvalidateRect(hwnd,c.x,c.y,c.x+bw,c.y+bh,true)
 return true
end
local dragging,ox,oy=false,0,0
local function drag()
 if not hwnd or c.locked then return end
 local mx,my=reaper.GetMousePosition()
 local ok,x,y=reaper.JS_Window_ScreenToClient(hwnd,mx,my)
 if not ok then return end
 local down=(reaper.JS_Mouse_GetState(1)&1)==1
 if down and not dragging then
  if x>=c.x and x<=c.x+c.w and y>=c.y and y<=c.y+c.h then dragging=true; ox=x-c.x; oy=y-c.y end
 elseif down and dragging then c.x=math.max(0,math.floor(x-ox)); c.y=math.max(0,math.floor(y-oy))
 elseif not down and dragging then dragging=false; save(); destroy() end
end
-- Settings window
local settings=false
local floating=false
local function open_settings()
 if settings then return end
 settings=true; gfx.init("MeterBox Settings",360,300,0); gfx.setfont(1,"Arial",14)
end
local function btn(x,y,w,h,s,on)
 gfxcol(on and "315B53" or "343B43"); gfx.roundrect(x,y,w,h,5,1)
 gfxcol("E8EDF2"); gfx.x=x+8; gfx.y=y+7; gfx.drawstr(s)
end
local md=false
local function settings_loop()
 gfxcol("191E24"); gfx.rect(0,0,360,300,1)
 gfxcol("E8EDF2"); gfx.x=16; gfx.y=14; gfx.drawstr("METERBOX / SETTINGS")
 gfxcol("9AA6B2"); gfx.x=16; gfx.y=40; gfx.drawstr("Changes are saved immediately.")
 btn(16,68,156,34,"Transport overlay",c.mode=="transport")
 btn(188,68,156,34,"Floating window",c.mode=="floating")
 btn(16,112,156,34,"Lock position: "..(c.locked and "ON" or "OFF"),c.locked)
 btn(188,112,156,34,"Labels: "..(c.labels and "ON" or "OFF"),c.labels)
 btn(16,156,156,34,"Peak markers: "..(c.hold and "ON" or "OFF"),c.hold)
 btn(188,156,156,34,"Width: "..c.w.." px",false)
 btn(16,200,156,34,"Height: "..c.h.." px",false)
 btn(188,200,156,34,"Palette: "..(c.left=="36D6A0" and "Mint / Blue" or "Green / Amber"),false)
 btn(16,244,328,34,"Close settings",false)
 gfx.update()
 if (gfx.mouse_cap&1)==1 and not md then
  md=true; local x,y=gfx.mouse_x,gfx.mouse_y
  if y>=68 and y<102 then c.mode=x<180 and "transport" or "floating"
  elseif y>=112 and y<146 then if x<180 then c.locked=not c.locked else c.labels=not c.labels end
  elseif y>=156 and y<190 then if x<180 then c.hold=not c.hold else c.w=c.w+25; if c.w>400 then c.w=175 end end
  elseif y>=200 and y<234 then
   if x<180 then c.h=c.h+4; if c.h>58 then c.h=26 end
   elseif c.left=="36D6A0" then c.left,c.right,c.bg,c.track,c.peak,c.text="7CDA65","FFB454","15191E","303840","FFFFFF","F1F1F1"
   else c.left,c.right,c.bg,c.track,c.peak,c.text="36D6A0","58A6FF","20252B","38424C","F4F5F7","D8DEE6" end
  elseif y>=244 and y<282 then settings=false; gfx.quit(); if c.mode=="floating" then floating=false end
  end
  save(); if c.mode=="transport" then destroy() end
 elseif (gfx.mouse_cap&1)==0 then md=false end
 local ch=gfx.getchar()
 if ch<0 or ch==27 then settings=false; gfx.quit(); if c.mode=="floating" then floating=false end end
end
local function start_float() gfx.init("MeterBox",c.w,c.h,0); gfx.setfont(1,"Arial",11); floating=true end
local function loop()
 if reaper.GetExtState(S,"open_settings")=="1" then reaper.SetExtState(S,"open_settings","",false); open_settings(); if c.mode=="floating" then floating=false end end
 levels()
 if settings then settings_loop() end
 if c.mode=="transport" and jsok then
  if floating then gfx.quit(); floating=false end
  if not hwnd or not reaper.JS_Window_IsWindow(hwnd) then hwnd=nil; attach() else drag(); attach() end
  if bmp and linked then draw_lice(); reaper.JS_Window_InvalidateRect(hwnd,c.x,c.y,c.x+bw,c.y+bh,true) end
 elseif c.mode=="floating" and not settings then
  if bmp then destroy() end
  hwnd=nil
  if not floating then start_float() end
  if gfx.getchar()<0 then return end
  if (gfx.mouse_cap&2)==2 then open_settings(); floating=false else draw_gfx() end
 elseif c.mode=="transport" and not jsok and not settings then
  reaper.ShowMessageBox("Transport overlay requires js_ReaScriptAPI. Install it or choose Floating window in settings.","MeterBox",0)
  c.mode="floating"; save()
 end
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
