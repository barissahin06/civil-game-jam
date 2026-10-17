-- One-time native authoring. Future artwork edits belong in rewrite_it.aseprite.
local root = assert(REWRITE_ROOT or app.params["repo"], "Pass repo")
local source = root .. "/art/production/ui/title_logo/rewrite_it.aseprite"
assert(not app.fs.isFile(source), "Source exists; checkpoint and edit it instead")
local W, H, GRID = 1152, 432, 3
local LW, LH = W / GRID, H / GRID
local rgba = app.pixelColor.rgba
local function color(hex)
  return rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end
local C = {
  ink = color("081b25"), shadow = color("153b47"), ivory = color("eadfbc"),
  light = color("fff0cf"), shade = color("b6a477"), wear = color("83978b"),
  red = color("bc4b43"), redlight = color("e0745e"), redshade = color("84353a"),
}
local function mask() return {} end
local function pixel(m, x, y, value)
  if x >= 0 and x < LW and y >= 0 and y < LH then m[y * LW + x] = value == nil and true or value end
end
local function inside(m, x, y) return x >= 0 and x < LW and y >= 0 and y < LH and m[y * LW + x] end
local function polygon(m, points, value)
  local ymin, ymax = LH, 0
  for _, p in ipairs(points) do ymin = math.min(ymin, p[2]); ymax = math.max(ymax, p[2]) end
  for y = ymin, ymax - 1 do
    local crossings = {}
    for i, p in ipairs(points) do
      local q = points[i % #points + 1]
      if (p[2] <= y and q[2] > y) or (q[2] <= y and p[2] > y) then
        crossings[#crossings + 1] = p[1] + (y - p[2]) * (q[1] - p[1]) / (q[2] - p[2])
      end
    end
    table.sort(crossings)
    for i = 1, #crossings - 1, 2 do
      for x = math.ceil(crossings[i]), math.ceil(crossings[i + 1]) - 1 do pixel(m, x, y, value) end
    end
  end
end
local letters = mask()
local function glyph(points, x, y, yscale, cutout)
  local translated = {}
  for _, p in ipairs(points) do translated[#translated + 1] = {x + p[1], y + math.floor(p[2] * (yscale or 1))} end
  polygon(letters, translated, not cutout)
end
local R = {{0,0},{31,0},{39,3},{43,9},{43,25},{39,31},{31,35},{42,53},{47,57},{47,64},{31,64},{16,38},{14,38},{14,55},{20,58},{20,64},{0,64},{0,58},{5,55},{5,9},{0,6}}
local R_COUNTER = {{14,9},{27,9},{31,12},{31,24},{27,28},{14,28}}
local E = {{0,0},{39,0},{39,17},{32,17},{29,9},{14,9},{14,27},{24,27},{27,22},{32,22},{32,42},{27,42},{24,36},{14,36},{14,55},{29,55},{33,47},{40,47},{40,64},{0,64},{0,58},{5,55},{5,9},{0,6}}
local W_GLYPH = {{0,0},{19,0},{19,6},{15,8},{23,43},{29,23},{25,9},{22,6},{22,0},{40,0},{40,6},{36,9},{44,43},{52,9},{48,6},{48,0},{64,0},{64,6},{60,10},{46,64},{35,64},{29,43},{22,64},{12,64},{0,9}}
local I = {{0,0},{26,0},{26,6},{18,9},{18,55},{26,58},{26,64},{0,64},{0,58},{8,55},{8,9},{0,6}}
local T = {{0,0},{44,0},{44,18},{37,18},{33,9},{27,9},{27,55},{35,58},{35,64},{9,64},{9,58},{17,55},{17,9},{11,9},{7,18},{0,18}}
glyph(R,20,18,74/64); glyph(R_COUNTER,20,18,74/64,true)
glyph(E,71,28); glyph(W_GLYPH,115,28)
glyph(R,183,28); glyph(R_COUNTER,183,28,1,true)
glyph(I,234,28); glyph(T,264,28); glyph(E,312,28)

local sprite = Sprite(W, H, ColorMode.RGB)
local function layer(name)
  local l = #sprite.layers == 1 and sprite.layers[1].name == "Layer 1" and sprite.layers[1] or sprite:newLayer()
  l.name = name
  local im = Image(W, H, ColorMode.RGB)
  if l:cel(1) then l:cel(1).image = im else sprite:newCel(l, 1, im) end
  return im, l
end
local function stamp(im, x, y, c)
  for yy = y * GRID, (y + 1) * GRID - 1 do
    for xx = x * GRID, (x + 1) * GRID - 1 do
      if xx >= 0 and xx < W and yy >= 0 and yy < H then im:drawPixel(xx, yy, c) end
    end
  end
end
local function paint(im, m, c, dx, dy)
  for index, yes in pairs(m) do
    if yes then stamp(im, index % LW + (dx or 0), math.floor(index / LW) + (dy or 0), c) end
  end
end
local function expanded(im, m, c, radius, ox, oy)
  for dy = -radius, radius do
    for dx = -radius, radius do paint(im, m, c, dx + (ox or 0), dy + (oy or 0)) end
  end
end
local function finish(im, l) l:cel(1).image = im end
local im, l = layer("01 / Letter shadow")
expanded(im, letters, C.shadow, 2, 3, 4)
finish(im, l)
im, l = layer("02 / Letter outline")
expanded(im, letters, C.ink, 2)
finish(im, l)
im, l = layer("03 / Ivory letters")
paint(im, letters, C.ivory)
finish(im, l)
im, l = layer("04 / Highlights and ink wear")
for index, yes in pairs(letters) do
  if yes then
    local x, y = index % LW, math.floor(index / LW)
    if not inside(letters, x, y - 1) then stamp(im, x, y, C.light)
    elseif not inside(letters, x, y + 1) then stamp(im, x, y, C.shade) end
  end
end
-- A few deliberate ink flecks retain the newspaper tone without weakening counters.
for _, p in ipairs({{27,23},{49,29},{28,84},{83,33},{102,81},{129,35},{154,82},{194,34},{212,84},{245,82},{277,34},{321,34},{342,83}}) do
  if inside(letters, p[1], p[2]) then stamp(im, p[1], p[2], C.wear) end
end
finish(im, l)

local red = mask()
-- Custom lowercase italic strokes: broad nib, open gap between i and t.
polygon(red, {{317,105},{325,105},{320,121},{320,124},{325,123},{329,119},{332,122},{326,129},{319,132},{312,132},{309,129},{310,122}})
polygon(red, {{321,94},{327,94},{329,97},{327,102},{320,102},{318,99}})
polygon(red, {{339,99},{346,96},{342,108},{351,108},{349,114},{339,114},{335,125},{336,127},{342,125},{348,120},{351,123},{343,131},{337,134},{329,134},{326,131},{327,124},{330,114},{325,114},{327,108},{333,108}})
im, l = layer("05 / Red italic it")
expanded(im, red, C.shadow, 2, 2, 2)
expanded(im, red, C.ink, 1)
paint(im, red, C.red)
for index, yes in pairs(red) do
  if yes then
    local x, y = index % LW, math.floor(index / LW)
    if not inside(red, x, y - 1) then stamp(im, x, y, C.redlight)
    elseif not inside(red, x, y + 1) then stamp(im, x, y, C.redshade) end
  end
end
finish(im, l)

local revision = mask()
polygon(revision, {{299,112},{290,108},{278,106},{91,106},{91,101},{78,110},{91,119},{91,114},{277,114},{289,116},{297,120},{300,117}})
im, l = layer("06 / Revision return line")
expanded(im, revision, C.shadow, 1, 2, 2)
expanded(im, revision, C.ink, 1)
paint(im, revision, C.red)
for x = 96, 275 do stamp(im, x, 106, C.redlight) end
finish(im, l)

assert(#sprite.layers == 6 and #sprite.frames == 1, "Native layer contract")
sprite:saveAs(source)
sprite:close()
print("REWRITE_TITLE_AUTHOR_PASS 1152x432 grid=3 layers=6 native_source_created")
