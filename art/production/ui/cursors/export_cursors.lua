-- Export only: native artwork remains the single editable source of truth.
-- aseprite -b --script-param repo=C:/path/to/repo --script export_cursors.lua
local root = CURSOR_REPO or app.params["repo"]
assert(root and root ~= "", "Pass --script-param repo=<repository root>")
local source = app.fs.joinPath(root, "art/production/ui/cursors/rewrite_cursors.aseprite")
local destination = app.fs.joinPath(root, "our-game/ui_preview/assets")
local sprite = app.open(source)
assert(sprite and sprite.width == 32 and sprite.height == 32, "Expected native 32x32 cursor source")
app.fs.makeAllDirectories(destination)
local expected = { "arrow", "pointing", "move", "can_drop", "forbidden" }
assert(#sprite.frames == #expected and #sprite.tags == #expected, "Expected five static cursor frames/tags")
for index, name in ipairs(expected) do
  assert(sprite.tags[index].name == name, "Cursor tag/frame order changed")
  local image = Image(32, 32, ColorMode.RGB)
  image:drawSprite(sprite, index)
  local output = app.fs.joinPath(destination, "cursor_" .. name .. ".png")
  image:saveAs(output)
  assert(app.fs.isFile(output), "Cursor export missing: " .. name)
  print("CURSOR_EXPORT_OK: " .. output)
end
sprite:close()
