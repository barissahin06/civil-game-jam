-- One-time native adaptation; further edits belong in rewrite_it_hud.aseprite.
local root = assert(REWRITE_ROOT or app.params["repo"], "Pass repo")
local source = root .. "/art/production/ui/title_logo/rewrite_it.aseprite"
local output = root .. "/art/production/ui/title_logo/rewrite_it_hud.aseprite"
assert(not app.fs.isFile(output), "HUD source exists; checkpoint and edit it instead")
local original = assert(app.open(source), "Approved title source is required")
assert(original.width == 1152 and original.height == 432 and #original.frames == 1, "Title contract")
assert(#original.layers == 6, "Title layer contract")
local layers = {}
for i, layer in ipairs(original.layers) do
  local image = Image(original.width, original.height, ColorMode.RGB)
  local cel = assert(layer:cel(1), "Missing title cel")
  image:drawImage(cel.image, cel.position)
  layers[i] = {name = layer.name, image = image}
end
local function bounds(first, last)
  local x0, y0, x1, y1 = original.width, original.height, 0, 0
  for i = first, last do
    for p in layers[i].image:pixels() do
      if app.pixelColor.rgbaA(p()) > 0 then
        x0, y0 = math.min(x0, p.x), math.min(y0, p.y)
        x1, y1 = math.max(x1, p.x + 1), math.max(y1, p.y + 1)
      end
    end
  end
  return {x = x0, y = y0, width = x1 - x0, height = y1 - y0}
end
local letter_bounds, it_bounds, arrow_bounds = bounds(1, 4), bounds(5, 5), bounds(6, 6)
local sprite = Sprite(320, 80, ColorMode.RGB)
for i, source_layer in ipairs(layers) do
  local layer = i == 1 and sprite.layers[1] or sprite:newLayer()
  layer.name = source_layer.name
  local crop, x0, y0, w, h
  if i <= 4 then crop, x0, y0, w, h = letter_bounds, 4, 3, 254, 61
  elseif i == 5 then crop, x0, y0, w, h = it_bounds, 268, 24, 44, 40
  else crop, x0, y0, w, h = arrow_bounds, 43, 66, 215, 10 end
  local image = Image(sprite.width, sprite.height, ColorMode.RGB)
  for y = 0, h - 1 do
    local sy = crop.y + math.min(crop.height - 1, math.floor((y + 0.5) * crop.height / h))
    for x = 0, w - 1 do
      local sx = crop.x + math.min(crop.width - 1, math.floor((x + 0.5) * crop.width / w))
      image:drawPixel(x0 + x, y0 + y, source_layer.image:getPixel(sx, sy))
    end
  end
  if layer:cel(1) then layer:cel(1).image = image else sprite:newCel(layer, 1, image) end
end
sprite:saveAs(output)
sprite:close()
original:close()
print("REWRITE_HUD_AUTHOR_PASS 320x80 layers=6 native_source_created")
