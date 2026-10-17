# Rewrite it cursors

`rewrite_cursors.aseprite` is the editable 32 × 32 RGBA source. Its five single-frame
tags use separate `outline`, `fill`, and `accent` layers. These are static hardware
cursors; frame order describes states, not an animation.

| Tag       | Runtime PNG            | Hotspot (x, y) |
| --------- | ---------------------- | -------------- |
| arrow     | `cursor_arrow.png`     | (3, 3)         |
| pointing  | `cursor_pointing.png`  | (12, 3)        |
| move      | `cursor_move.png`      | (15, 15)       |
| can_drop  | `cursor_can_drop.png`  | (15, 15)       |
| forbidden | `cursor_forbidden.png` | (15, 15)       |

Coordinates are zero-based. Arrow and pointing hotspots sit on their visible tips;
the three action indicators use their visual center. The cream face and dark edge
remain readable against both the slate UI and the lighter map.

Palette: outline `#09141e`, slate `#101e2b`, cream `#e7e6d8`, brass `#d3b782`,
teal `#7eaea0`, warm red `#d17e70`. Pixels are fully opaque or transparent, without
filtering or antialiasing.

Export the saved native source with Aseprite 1.3:

```powershell
& $env:ASEPRITE_PATH -b --script-param "repo=$($PWD.Path)" --script art/production/ui/cursors/export_cursors.lua
```

`create_cursor_source.lua` records the original native authoring and refuses to
overwrite an existing source. Edit the Aseprite source for further art changes,
checkpointing it first, then run the export script to refresh the runtime PNGs in
`our-game/ui_preview/assets/`.
