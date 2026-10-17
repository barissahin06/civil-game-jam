-- Complete the existing 12x22 bitmap grid without redrawing unrelated glyphs.
-- Run on a checkpointed working copy; the native editing tool saves on success.
local sprite = assert(app.activeSprite)
assert(sprite.width == 384 and sprite.height == 88 and #sprite.frames == 1 and #sprite.layers == 1)
local cel = assert(sprite.layers[1]:cel(1))
local image = Image(sprite.width, sprite.height, ColorMode.RGB)
image:drawImage(cel.image, cel.position)
local ids, cells = {}, {}
for code = 32, 126 do ids[#ids + 1] = code end
for _, code in ipairs({199,286,304,214,350,220,231,287,305,246,351,252,8378,8226,215,
  194,206,219,226,238,251,8216,8217,8220,8221,171,187,8211,8212,8230,160}) do
  ids[#ids + 1] = code
end
for index, code in ipairs(ids) do cells[code] = {((index - 1) % 32) * 12, math.floor((index - 1) / 32) * 22} end
local white = app.pixelColor.rgba(255,255,255,255)
local function clear(code)
  local cell = assert(cells[code])
  for y = 0, 21 do for x = 0, 9 do image:drawPixel(cell[1] + x, cell[2] + y, 0) end end
end
local function draw(code, rows, top)
  clear(code)
  local cell, row = cells[code], top or 2
  for pattern in rows:gmatch("[^/]+") do
    assert(#pattern == 5 and row < 11)
    for x = 1, 5 do
      if pattern:sub(x,x) == "#" then
        for dy = 0, 1 do for dx = 0, 1 do
          image:drawPixel(cell[1] + (x - 1) * 2 + dx, cell[2] + row * 2 + dy, white)
        end end
      end
    end
    row = row + 1
  end
end
local function copy(target, source)
  local a, b = cells[target], cells[source]
  for y = 0, 21 do for x = 0, 9 do
    image:drawPixel(a[1] + x, a[2] + y, image:getPixel(b[1] + x, b[2] + y))
  end end
end
local patterns = {
  [34] = '.#.#./.#.#.',
  [35] = '.#.#./#####/.#.#./.#.#./#####/.#.#./.#.#.',
  [36] = '..#../.####/#.#../.###./..#.#/####./..#..',
  [38] = '.##../#..#./.##../#.#.#/#..#./#..##/.##.#',
  [39] = '..#../..#..',
  [42] = '.#.#./..#../#####/..#../.#.#.',
  [59] = '...../..#../..#../...../..#../..#../.#...',
  [60] = '...#./..#../.#.../#..../.#.../..#../...#.',
  [62] = '.#.../..#../...#./....#/...#./..#../.#...',
  [64] = '.###./#...#/#.###/#.#.#/#.###/#..../.####',
  [91] = '.###./.#.../.#.../.#.../.#.../.#.../.###.',
  [92] = '#..../#..../.#.../..#../...#./....#/....#',
  [93] = '.###./...#./...#./...#./...#./...#./.###.',
  [94] = '..#../.#.#./#...#',
  [95] = '...../...../...../...../...../...../#####',
  [96] = '.#.../..#..',
  [123] = '..##./.#.../.#.../##.../.#.../.#.../..##.',
  [124] = '..#../..#../..#../..#../..#../..#../..#..',
  [125] = '.##../...#./...#./...##/...#./...#./.##..',
  [126] = '...../...../.#..#/#.##.',
  [8216] = '..##./.#.../.#...',
  [8217] = '..#../..#../.#...',
  [8220] = '##.##/#..#./#..#.',
  [8221] = '#..#./#..#./.#..#',
  [171] = '...../...../.#..#/#..#./.#..#',
  [187] = '...../...../#..#./.#..#/#..#.',
  [8211] = '...../...../...../.###.',
  [8212] = '...../...../...../#####',
  [8230] = '...../...../...../...../...../...../#.#.#',
}
for code, pattern in pairs(patterns) do draw(code, pattern) end
-- Keep the established uppercase artwork while retaining Turkish dotted/dotless I.
copy(105,304)
for _, pair in ipairs({{194,65},{206,73},{219,85},{226,65},{238,73},{251,85}}) do
  copy(pair[1],pair[2])
  local cell = cells[pair[1]]
  for y, row in ipairs({'..#..','.#.#.'}) do for x = 1, 5 do
    for dy = 0, 1 do for dx = 0, 1 do
      image:drawPixel(cell[1] + (x - 1) * 2 + dx, cell[2] + (y - 1) * 2 + dy,
        row:sub(x,x) == '#' and white or 0)
    end end
  end end
end
clear(160)
for _, code in ipairs(ids) do
  if code ~= 32 and code ~= 63 and code ~= 160 then
    local cell, question, different = cells[code], cells[63], false
    for y = 0, 21 do for x = 0, 9 do
      if image:getPixel(cell[1] + x,cell[2] + y) ~= image:getPixel(question[1] + x,question[2] + y) then different = true end
    end end
    assert(different, 'Placeholder question glyph: ' .. code)
  end
end
cel.image, cel.position = image, Point(0,0)
print('FONT_AUTHOR_PASS glyphs=' .. #ids .. ' grid=384x88 advance=12 line=22')
