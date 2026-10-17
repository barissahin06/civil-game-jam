-- Run against checkpointed staged copies, then publish the validated native files.
local stage = assert(app.params["stage"], "Pass stage directory")
assert(stage:gsub("\\", "/"):find("/generated/art/title_logo/", 1, true), "Use a generated staging directory")
local rgba = app.pixelColor.rgba
local replacements = {
  [rgba(188, 75, 67, 255)] = rgba(146, 87, 227, 255),
  [rgba(224, 116, 94, 255)] = rgba(179, 138, 237, 255),
  [rgba(132, 53, 58, 255)] = rgba(93, 62, 148, 255),
}
local report = {}
for _, name in ipairs({"rewrite_it", "rewrite_it_hud"}) do
  local path = stage .. "/" .. name .. ".aseprite"
  local sprite = assert(app.open(path), "Staged native source required")
  assert(#sprite.layers == 6 and #sprite.frames == 1 and sprite.colorMode == ColorMode.RGB, "Native contract")
  assert(sprite.layers[5].name == "05 / Red italic it", "Expected pre-violet source")
  local width, height, duration = sprite.width, sprite.height, sprite.frames[1].duration
  local before, changed = {}, 0
  for i, layer in ipairs(sprite.layers) do
    local cel = assert(layer:cel(1), "Native cel required")
    before[i] = {image = Image(cel.image), x = cel.position.x, y = cel.position.y, name = layer.name}
    if i >= 5 then
      local image = Image(cel.image)
      for p in image:pixels() do
        local replacement = replacements[p()]
        if replacement then p(replacement); changed = changed + 1 end
      end
      cel.image = image
    end
  end
  assert(changed > 0, "Expected three accent colors")
  sprite.layers[5].name = "05 / Violet italic it"
  sprite:saveAs(path)
  sprite:close()
  sprite = assert(app.open(path), "Saved native source required")
  assert(sprite.width == width and sprite.height == height and #sprite.frames == 1, "Geometry changed")
  assert(sprite.frames[1].duration == duration and #sprite.layers == 6, "Frame/layers changed")
  for i, layer in ipairs(sprite.layers) do
    local cel, saved = assert(layer:cel(1)), before[i]
    local expected_name = i == 5 and "05 / Violet italic it" or saved.name
    assert(layer.name == expected_name, "Unexpected layer rename")
    assert(cel.position.x == saved.x and cel.position.y == saved.y, "Cel moved")
    assert(cel.image.width == saved.image.width and cel.image.height == saved.image.height, "Cel resized")
    for p in cel.image:pixels() do
      local old, actual = saved.image:getPixel(p.x, p.y), p()
      local expected = i >= 5 and replacements[old] or nil
      assert(actual == (expected or old), "Unexpected native pixel change")
      assert(app.pixelColor.rgbaA(actual) == app.pixelColor.rgbaA(old), "Alpha changed")
    end
  end
  sprite:close()
  report[#report + 1] = name .. " changed=" .. changed .. " first_four_layers=exact alpha=exact geometry=exact"
end
local completion = "REWRITE_VIOLET_RECOLOR_PASS\n" .. table.concat(report, "\n")
local file = assert(io.open(stage .. "/recolor-check.txt", "w"))
file:write(completion .. "\n")
file:close()
print(completion)
