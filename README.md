# MeterBox for REAPER 8

Compact stereo master peak meter for REAPER. Reads the master track directly and displays continuous L/R bars with peak markers.

## Requirements
- REAPER 8 (REAPER 7+ may work).
- js_ReaScriptAPI is required for the transport overlay. Floating mode does not require it.

## Install
1. In REAPER, open Extensions > ReaPack > Import repositories.
2. Add: https://raw.githubusercontent.com/thevardas21ofc-cloud/MeterBox-ReaPack/main/index.xml
3. Synchronize, browse packages, search MeterBox, and install.
4. Run **MeterBox - REAPER Master Meter** from the Actions list.
5. Run **MeterBox - Open Settings** to change appearance and mode.

## Notes
The transport overlay is composited into the Transport window; it is not a native transport control. Window layouts, themes, DPI scaling and OS behavior may affect placement. This is an early release and the transport overlay has not been runtime-tested on your REAPER installation. Please report any error with its exact text and line number.

Repository: https://github.com/thevardas21ofc-cloud/MeterBox-ReaPack