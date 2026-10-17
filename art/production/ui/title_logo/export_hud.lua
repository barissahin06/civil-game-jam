local root = assert(REWRITE_ROOT or app.params["repo"], "Pass repo")
local source = root .. "/art/production/ui/title_logo/rewrite_it_hud.aseprite"
local output = root .. "/generated/art/title_logo/rewrite_it_hud.png"
local runtime = root .. "/our-game/assets/branding/rewrite_it_hud.png"
local expected = {
  "01 / Letter shadow", "02 / Letter outline", "03 / Ivory letters",
  "04 / Highlights and ink wear", "05 / Violet italic it", "06 / Revision return line",
}
local sprite = assert(app.open(source), "Native HUD source is required")
assert(sprite.width == 320 and sprite.height == 80 and #sprite.frames == 1, "HUD canvas/frame contract")
assert(#sprite.layers == #expected, "HUD layer count")
for i, name in ipairs(expected) do assert(sprite.layers[i].name == name, "Layer contract: " .. name) end
local native = Image(sprite.width, sprite.height, ColorMode.RGB)
native:drawSprite(sprite, 1)
local opaque = 0
for p in native:pixels() do
  local alpha = app.pixelColor.rgbaA(p())
  assert(alpha == 0 or alpha == 255, "Only crisp transparent or opaque pixels")
  if p.x < 3 or p.x >= 317 or p.y < 2 or p.y >= 78 then assert(alpha == 0, "HUD transparent safety border") end
  if alpha > 0 then opaque = opaque + 1 end
end
assert(opaque > 7500 and opaque < 15000, "HUD logo silhouette")
app.fs.makeAllDirectories(root .. "/generated/art/title_logo")
sprite:saveCopyAs(output)
local exported = assert(Image{fromFile = output})
assert(exported.width == native.width and exported.height == native.height, "HUD export dimensions")
for y = 0, native.height - 1 do
  for x = 0, native.width - 1 do
    assert(native:getPixel(x, y) == exported:getPixel(x, y), "HUD native/export pixel mismatch")
  end
end
sprite:saveCopyAs(runtime)
sprite:close()
local completion = "REWRITE_HUD_EXPORT_PASS 320x80 layers=6 alpha=binary border=transparent roundtrip=exact opaque=" .. opaque
local report = assert(io.open(root .. "/generated/art/title_logo/rewrite_it_hud.export-check.txt", "w"))
report:write(completion .. "\n")
report:close()
print(completion)
