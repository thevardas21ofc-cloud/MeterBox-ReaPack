## 0.7.0\n- Rebuilt Settings as a separate ReaScript window instead of sharing the meter's gfx context.
- Settings window is independently movable and receives its own mouse input.
- Meter loop continues reading the REAPER master peak APIs; display loop uses REAPER's deferred UI cycle with a 60 Hz target interval documented in source.

# Changelog

## 0.6.1 - 2026-11-25
- Fix settings window placement: opens centered over the REAPER main window.
- Raise and focus the settings window when opened and while active, instead of leaving it behind the arrange/event window.

## 0.6.0 - 2026-11-25
- Redesigned the meter as a compact, minimal two-bar display.
- Reduced default dimensions to 176 × 42 px and removed channel labels by default.
- Added independent colour cycling for left/right bars, track background, panel background, peak marker and scale.
- Preserved transport overlay, floating fallback, master-track peak feed and peak hold.

## 0.5.1 - 2026-11-03
- First public ReaPack test build.
- Direct stereo master peak feed.
- Continuous L/R bars and peak-hold markers.
- Floating meter and persistent appearance settings.
