--[[
@description MeterBox - Open Settings
@author MeterBox
@version 0.5.1
@about Opens the settings window for the running MeterBox master meter.
]]
if reaper.GetExtState("MeterBox","running")=="" then
 reaper.ShowMessageBox("Start MeterBox first, then open settings.","MeterBox",0)
else
 reaper.SetExtState("MeterBox","open_settings","1",false)
end
