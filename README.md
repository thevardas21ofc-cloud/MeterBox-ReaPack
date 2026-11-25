# MeterBox for REAPER 8

Compact stereo master peak meter with a transport-bar overlay and floating-window fallback.

## Install with ReaPack

1. Open **Extensions > ReaPack > Import repositories**.
2. Add this URL:

   https://raw.githubusercontent.com/thevardas21ofc-cloud/MeterBox-ReaPack/main/index.xml

3. Synchronize packages, browse packages, search **MeterBox**, and install.
4. Run **MeterBox - REAPER Master Meter** from the Actions list.
5. Run **MeterBox - Open Settings** to change display mode and appearance.

## Appearance (v0.6.0+)

- Minimal two-bar stereo display, default size 176 × 42 px.
- Independent colour controls for left meter, right meter, meter background, panel background, peak marker and scale marks. Click each colour row in Settings to cycle through the available swatches.
- Adjustable width and height, peak hold, channel labels and lock position.

## Settings window (v0.7.0)

- Opens centered over the REAPER main window and is brought to the foreground.
- Requires js_ReaScriptAPI for the foreground/focus helpers; the settings remain available without them but window focus behavior may depend on the OS.

## Transport overlay

- Requires the **js_ReaScriptAPI** extension.
- The default mode is the transport-bar overlay.
- In Settings, choose **Lock position: OFF** to drag the meter inside the transport bar; turn it back ON to lock it.
- The overlay is drawn over the Transport window; it is not a native REAPER transport control. Window themes, layouts, DPI scaling and OS differences can affect its placement.

## Meter source

The bars read the two channels of REAPER's master track using `Track_GetPeakInfo`. Peak-hold markers use `Track_GetPeakHoldDB` when available.

The overlay has not been runtime-tested on every REAPER 8 layout/OS. If it fails, please send the exact error text, line number, REAPER version and OS.
