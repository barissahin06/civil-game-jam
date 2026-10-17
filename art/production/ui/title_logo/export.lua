local root = assert(REWRITE_ROOT or app.params["repo"], "Pass repo")
local source = root .. "/art/production/ui/title_logo/rewrite_it.aseprite"
local output = root .. "/generated/art/title_logo/rewrite_it.png"
local runtime = root .. "/our-game/assets/branding/rewrite_it.png"
local expected = {
  "01 / Letter shadow", "02 / Letter outline", "03 / Ivory letters",
  "04 / Highlights and ink wear", "05 / Violet italic it", "06 / Revision return line",
}
local sprite = assert(app.open(source), "Native title source is required")
assert(sprite.width == 1152 and sprite.height == 432 and #sprite.frames == 1, "Canvas/frame contract")
assert(#sprite.layers == #expected, "Layer count")
for i, name in ipairs(expected) do assert(sprite.layers[i].name == name, "Layer contract: " .. name) end
local native = Image(sprite.width, sprite.height, ColorMode.RGB)
native:drawSprite(sprite, 1)
local opaque = 0
for p in native:pixels() do
  local alpha = app.pixelColor.rgbaA(p())
  assert(alpha == 0 or alpha == 255, "Only crisp transparent or opaque pixels")
  if p.x < 24 or p.x >= 1128 or p.y < 24 or p.y >= 420 then assert(alpha == 0, "Transparent safety border") end
  if alpha > 0 then opaque = opaque + 1 end
end
assert(opaque > 90000 and opaque < 230000, "Expected transparent logo silhouette")
app.fs.makeAllDirectories(root .. "/generated/art/title_logo")
sprite:saveCopyAs(output)
local exported = assert(Image{fromFile = output})
assert(exported.width == native.width and exported.height == native.height, "Export dimensions")
for y = 0, native.height - 1 do
  for x = 0, native.width - 1 do
    assert(native:getPixel(x, y) == exported:getPixel(x, y), "Native/export pixel mismatch")
  end
end
sprite:saveCopyAs(runtime)
sprite:close()
local completion = "REWRITE_TITLE_EXPORT_PASS 1152x432 layers=6 alpha=binary border=transparent roundtrip=exact opaque=" .. opaque
local report = assert(io.open(root .. "/generated/art/title_logo/rewrite_it.export-check.txt", "w"))
report:write(completion .. "\n")
report:close()
print(completion)
