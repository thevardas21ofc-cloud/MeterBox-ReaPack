# MeterBox for REAPER 8

Stereo master peak meter with a transport-bar overlay and floating-window fallback.

## Install with ReaPack

1. Open **Extensions > ReaPack > Import repositories**.
2. Add this URL:

   https://raw.githubusercontent.com/thevardas21ofc-cloud/MeterBox-ReaPack/main/index.xml

3. Synchronize packages, browse packages, search **MeterBox**, and install.
4. Run **MeterBox - REAPER Master Meter** from the Actions list.
5. Run **MeterBox - Open Settings** to change display mode and appearance.

## Transport overlay

- Requires the **js_ReaScriptAPI** extension.
- The default mode is the transport-bar overlay.
- In Settings, choose **Lock position: OFF** to drag the meter inside the transport bar; turn it back ON to lock it.
- Settings include overlay/floating mode, labels, peak markers, width, height and color palette.
- The overlay is drawn over the Transport window; it is not a native REAPER transport control. Window themes, layouts, DPI scaling and OS differences can affect its placement.

## Meter source

The bars read the two channels of REAPER's master track using `Track_GetPeakInfo`. Peak-hold markers use `Track_GetPeakHoldDB` when available.

This release has been published for user testing. The overlay has not been runtime-tested on every REAPER 8 layout/OS. If it fails, please send the exact error text, line number, REAPER version and OS.
