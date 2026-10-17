-- Run through edit_aseprite on a checkpointed working copy; only these three layers are owned.
local sprite = assert(app.activeSprite, "Open map-general.aseprite")
assert(sprite.width == 3072 and sprite.height == 1728 and #sprite.frames == 1)
local width, height = sprite.width, sprite.height
local rgba, alpha, red = app.pixelColor.rgba, app.pixelColor.rgbaA, app.pixelColor.rgbaR
local names = {"70 / Arazi - Dağ sıraları", "71 / Arazi - Orman ve bozkır", "72 / Arazi - Kıyı dokusu"}
local function layer_named(name)
  for _, layer in ipairs(sprite.layers) do if layer.name == name then return layer end end
end
for _, name in ipairs(names) do
  local old = layer_named(name)
  if old then sprite:deleteLayer(old) end
end
assert(#sprite.layers == 31, "Preserve the approved map's original layers")
local function image_of(name)
  local cel = assert(assert(layer_named(name), name):cel(1))
  local image = Image(width, height, ColorMode.RGB)
  image:drawImage(cel.image, cel.position)
  return image
end
local land = image_of("02 / Pasif Türkiye zemini")
local foreign = image_of("01a / Çevre ülkeler")
local borders = image_of("03 / Pasif il sınırları")
local coast = image_of("90 / Kıyı ve ülke sınırı")
local hit = image_of("HIT / Seçilebilir iller")
local base = Image(width, height, ColorMode.RGB)
base:drawSprite(sprite, 1)
local blocked = {}
for _, name in ipairs({"99 / İl adları", "98 / Ülke adları"}) do
  local image = image_of(name)
  for pixel in image:pixels() do
    if alpha(pixel()) > 0 then
      local cx, cy = math.floor(pixel.x / 8), math.floor(pixel.y / 8)
      for dy = -1, 1 do for dx = -1, 1 do blocked[(cy + dy) * 384 + cx + dx] = true end end
    end
  end
end
local function inside(x, y) return x >= 2 and y >= 2 and x < width - 2 and y < height - 2 end
local function turkey(x, y) return inside(x, y) and alpha(land:getPixel(x, y)) > 0 end
local function water(x, y)
  return inside(x, y) and not turkey(x, y) and alpha(foreign:getPixel(x, y)) == 0
end
local function clear(x, y, sea)
  if not inside(x, y) or blocked[math.floor(y / 8) * 384 + math.floor(x / 8)] then return false end
  if sea then return water(x, y) end
  if not turkey(x, y) or alpha(borders:getPixel(x, y)) > 0 or alpha(coast:getPixel(x, y)) > 0 then return false end
  local id = red(hit:getPixel(x, y))
  return red(hit:getPixel(x - 1, y)) == id and red(hit:getPixel(x + 1, y)) == id
    and red(hit:getPixel(x, y - 1)) == id and red(hit:getPixel(x, y + 1)) == id
end
local counts = {mountains = 0, trees = 0, grass = 0, waves = 0, coastal_pixels = 0}
local relief, vegetation, sea = Image(width, height), Image(width, height), Image(width, height)
local function put(image, x, y, ink, is_sea)
  x, y = math.floor(x), math.floor(y)
  if clear(x, y, is_sea) then image:drawPixel(x, y, ink) end
end
local function tint(value, delta, green)
  local function channel(n) return math.max(0, math.min(255, n)) end
  return rgba(channel(app.pixelColor.rgbaR(value) + delta), channel(app.pixelColor.rgbaG(value) + delta + (green or 0)),
    channel(app.pixelColor.rgbaB(value) + delta), 255)
end
local function project(lon, lat)
  return math.floor((lon - 12) * 0.777593016455506 * 93 + 0.5), math.floor((49 - lat) * 93 + 0.5)
end
local function space(x, y, w, h, is_sea)
  for yy = y, y + h, 4 do for xx = x, x + w, 4 do
    if is_sea then
      if not clear(xx, yy, true) then return false end
    elseif not turkey(xx, yy) or blocked[math.floor(yy / 8) * 384 + math.floor(xx / 8)] then
      return false
    end
  end end
  return true
end
-- Drawn stepped silhouettes keep the ranges readable at the native camera scale.
local peaks = {
  {"          h", "         hld", "        hllld", "       hlllldd", "      hlllllddd", "     hllllldddd",
   "    hllllllddddd", "   hlllllldddddd", "  hlllllllddddddd", " hlllllllldddddddd", "hllllllllddddddddd", "ssssssssssssssssss"},
  {"      h", "     hlh", "    hllld", "   hlllldd", "  hlllllddd", " hlllllldddd", "hlllllllddddd",
   "lllllllllddddd", "llllllllldddddd", "lllllllllldddddd", "sssssssssssssssss"},
  {"           h", "          hld", "         hllld", "        hlllldd", "       hlllllddd", "      hlllllldddd",
   "     hlllllllddddd", "    hlllllllldddddd", "   hllllllllldddddd", "  hllllllllllddddddd", " hllllllllllldddddddd", "sssssssssssssssssssss"},
}
local function mountain(lon, lat, variant, snowy)
  local cx, cy = project(lon, lat)
  local rows = peaks[variant % #peaks + 1]
  local w, h = #rows[#rows] * 2, #rows * 2
  local x0, y0 = cx - math.floor(w / 2), cy - h
  if not space(x0, y0, w, h, false) then return end
  local ground = base:getPixel(cx, cy)
  local colors = {h = tint(ground, 28), l = tint(ground, 8), d = tint(ground, -26), s = tint(ground, -14)}
  for y, row in ipairs(rows) do for x = 1, #row do
    local ink = colors[row:sub(x, x)]
    if ink then
      if snowy and y <= 3 then ink = tint(ground, 44) end
      for dy = 0, 1 do for dx = 0, 1 do put(relief, x0 + (x - 1) * 2 + dx, y0 + (y - 1) * 2 + dy, ink, false) end end
    end
  end end
  counts.mountains = counts.mountains + 1
end
local function ridge(points, snowy)
  for i = 1, #points - 1 do
    local a, b = points[i], points[i + 1]
    local steps = math.max(1, math.floor(math.sqrt(((a[1] - b[1]) * 72) ^ 2 + ((a[2] - b[2]) * 93) ^ 2) / 29))
    for j = 0, steps - 1 do
      local t = j / steps
      mountain(a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t + ((j + i) % 3 - 1) * 0.055, i + j, snowy)
    end
  end
end
ridge({{29.2, 40.0}, {30.6, 40.3}, {32.0, 40.55}, {33.4, 40.8}, {35.2, 40.8}, {37.0, 40.5}, {39.0, 40.5}, {41.0, 40.8}, {42.4, 41.0}}, false)
ridge({{28.7, 37.4}, {30.0, 37.2}, {31.3, 37.4}, {32.8, 37.2}, {34.3, 37.5}, {35.8, 37.7}, {36.8, 38.0}}, false)
ridge({{38.0, 39.8}, {39.5, 39.5}, {40.8, 39.7}, {42.1, 39.8}, {43.4, 39.6}, {44.0, 39.2}}, true)
ridge({{39.1, 38.6}, {40.8, 38.3}, {42.0, 38.1}, {43.4, 37.8}}, true)
local function tree(cx, cy, variant)
  local h, w = 11 + variant % 3 * 2, 9 + variant % 2 * 2
  if not space(cx - 5, cy - h, w + 2, h + 2, false) then return end
  local ground = base:getPixel(cx, cy)
  local dark, light = tint(ground, -25, 5), tint(ground, -10, 9)
  for y = 0, h - 3 do
    local half = math.min(math.floor(w / 2), math.floor(y / 3) + (y % 4 == 0 and 0 or 1))
    for x = -half, half do put(vegetation, cx + x, cy - h + y, x < 0 and light or dark, false) end
  end
  put(vegetation, cx, cy - 1, tint(ground, -28), false)
  put(vegetation, cx, cy, tint(ground, -28), false)
  counts.trees = counts.trees + 1
end
local groves = {
  {28.5, 40.0, 62, 24}, {30.0, 40.6, 68, 30}, {31.6, 41.0, 72, 22}, {33.2, 41.3, 64, 20},
  {35.0, 41.1, 62, 20}, {36.9, 40.9, 56, 18}, {38.5, 40.9, 68, 22}, {40.0, 41.0, 58, 18},
  {41.1, 41.1, 46, 20}, {27.7, 38.2, 50, 32}, {28.4, 37.6, 50, 28}, {29.7, 37.2, 52, 20},
}
for g, grove in ipairs(groves) do
  local cx, cy = project(grove[1], grove[2])
  for y = -grove[4], grove[4], 13 do for x = -grove[3], grove[3], 13 do
    local n = (x * 19 + y * 23 + g * 41) % 13
    if n < 9 and (x / grove[3]) ^ 2 + (y / grove[4]) ^ 2 < 1 then tree(cx + x + n % 4, cy + y + n % 3, n) end
  end end
end
for _, patch in ipairs({{31.0, 39.4}, {32.1, 39.0}, {33.4, 38.7}, {33.0, 38.0}, {31.8, 37.7}, {35.2, 38.5}, {37.5, 37.4}, {39.0, 37.4}}) do
  local cx, cy = project(patch[1], patch[2])
  for y = -14, 14, 9 do for x = -30, 30, 13 do
    local xx, yy = cx + x + (y % 5), cy + y
    if space(xx, yy - 4, 7, 5, false) then
      local ground = base:getPixel(xx, yy)
      local ink = tint(ground, 13)
      for _, p in ipairs({{0, -1}, {1, 0}, {3, -2}, {3, -1}, {3, 0}, {5, -1}, {6, -2}}) do put(vegetation, xx + p[1], yy + p[2], ink, false) end
      counts.grass = counts.grass + 1
    end
  end end
end
for _, point in ipairs({{25.0, 39.4}, {25.3, 38.8}, {25.4, 38.1}, {25.2, 37.4}, {26.0, 36.7}, {27.0, 36.2},
  {28.6, 35.8}, {29.5, 36.0}, {30.6, 35.6}, {31.8, 35.8}, {33.2, 35.7}, {34.6, 35.4},
  {29.3, 42.4}, {30.7, 42.8}, {32.4, 42.9}, {34.0, 43.0}, {35.6, 42.7}, {37.1, 42.5}, {38.7, 42.4}, {40.2, 42.2}}) do
  local cx, cy = project(point[1], point[2])
  for row = 0, 1 do
    local x0, y0 = cx + row * 14, cy + row * 8
    if space(x0, y0 - 1, 22, 3, true) then
      for x = 0, 20 do
        local yy = y0 + ((x < 3 or x > 17) and 1 or 0)
        put(sea, x0 + x, yy, rgba(35, 57, 73, 255), true)
      end
      counts.waves = counts.waves + 1
    end
  end
end
for y = 650, 1300, 5 do for x = 950, 2350, 7 do
  if clear(x, y, true) and (turkey(x - 5, y) or turkey(x + 5, y) or turkey(x, y - 5) or turkey(x, y + 5)) then
    for dx = 0, 2 do
      put(sea, x + dx, y, rgba(42, 67, 81, 255), true)
      counts.coastal_pixels = counts.coastal_pixels + 1
    end
  end
end end
local first_index = assert(layer_named("90 / Kıyı ve ülke sınırı")).stackIndex
for i, image in ipairs({relief, vegetation, sea}) do
  local layer = sprite:newLayer()
  layer.name = names[i]
  layer.stackIndex = first_index + i - 1
  layer.data = json.encode({kind = "decorative_terrain",runtime = "map-terrain.png",general_only = true,counts = counts})
  sprite:newCel(layer, 1, image, Point(0, 0))
end
assert(#sprite.layers == 34 and #sprite.frames == 1)
assert(counts.mountains >= 35 and counts.trees >= 60 and counts.waves >= 15, "Terrain density unexpectedly low " .. json.encode(counts))
print("TERRAIN_AUTHOR_PASS " .. json.encode(counts))
