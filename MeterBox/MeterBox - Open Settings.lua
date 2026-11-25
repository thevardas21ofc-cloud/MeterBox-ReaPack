--[[
@description MeterBox - Open Settings
@author MeterBox
@version 0.8.4
@about Opens the settings panel inside the standalone floating MeterBox window.
]]
if reaper.GetExtState("MeterBox","running")=="" then
 reaper.ShowMessageBox("Start MeterBox first, then open settings.","MeterBox",0)
 return
end
reaper.SetExtState("MeterBox","open_settings","1",false)
