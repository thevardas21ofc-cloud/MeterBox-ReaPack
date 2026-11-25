--[[
@description MeterBox - REAPER Master Meter
@author MeterBox
@version 0.7.0
@provides
  [main] MeterBox.lua
  MeterBox - Open Settings.lua
@about
  Stereo master peak meter with a JS_ReaScriptAPI overlay in REAPER's transport bar.
  Requires js_ReaScriptAPI for transport mode; floating mode is available as fallback.
]]
local S="MeterBox"
local D={mode="transport",locked=true,x=8,y=5,w=176,h=42,bg="171B20",track="303840",left="35DDB0",right="35DDB0",peak="F4F6F8",scale="69737D",text="D8DEE6",labels=false,hold=true,min=-60,max=0}
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
 local p=5; local lw=c.labels and 12 or 0; local barx=p+lw; local barw=math.max(8,bw-barx-p)
 local barh=math.max(4,math.floor((bh-17)/2))
 for i,v in ipairs({L,R}) do
  local y=4+(i-1)*(barh+4)
  if c.labels and reaper.JS_LICE_CreateFont and not font then font=reaper.JS_LICE_CreateFont() end
  if c.labels and font and reaper.JS_LICE_DrawText then
   reaper.JS_LICE_SetFontColor(font,rgb(c.text))
   reaper.JS_LICE_DrawText(bmp,font,i==1 and "L" or "R",1,2,y-2,barx-1,y+barh+2)
  end
  lice_rect(barx,y,barw,barh,c.track)
  lice_rect(barx,y,math.floor(barw*norm(v)),barh,i==1 and c.left or c.right)
  if c.hold then lice_rect(clamp(barx+math.floor(barw*norm(i==1 and HL or HR)),barx,barx+barw-1),y-1,1,barh+2,c.peak) end
 end
 for i=0,6 do
  local x=barx+math.floor(barw*i/6)
  lice_rect(x,bh-5,1,3,c.scale)
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
-- Settings are handled by a separate action/script instance. This avoids
-- sharing the meter's gfx context with the settings window.
local function request_settings()
 reaper.SetExtState(S,"open_settings","1",false)
end
local function start_float() gfx.init("MeterBox",c.w,c.h,0); gfx.setfont(1,"Arial",11); floating=true end
local function loop()
 levels()
 if c.mode=="transport" and jsok then
  if floating then gfx.quit(); floating=false end
  if not hwnd or not reaper.JS_Window_IsWindow(hwnd) then hwnd=nil; attach() else drag(); attach() end
  if bmp and linked then draw_lice(); reaper.JS_Window_InvalidateRect(hwnd,c.x,c.y,c.x+bw,c.y+bh,true) end
 elseif c.mode=="floating" then
  if bmp then destroy() end
  hwnd=nil
  if not floating then start_float() end
  if gfx.getchar()<0 then return end
  if (gfx.mouse_cap&2)==2 then request_settings(); floating=false else draw_gfx() end
 elseif c.mode=="transport" and not jsok then
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
