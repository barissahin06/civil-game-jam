-- Native Aseprite authoring. New-source creation deliberately refuses overwrite.
-- aseprite -b --script-param repo=C:/path/to/repo --script create_cursor_source.lua
local root = CURSOR_REPO or app.params["repo"]
assert(root and root ~= "", "Pass --script-param repo=<repository root>")
local directory = app.fs.joinPath(root, "art/production/ui/cursors")
local source = app.fs.joinPath(directory, "rewrite_cursors.aseprite")
assert(not app.fs.isFile(source), "Source exists: checkpoint and edit its staged copy instead")
app.fs.makeAllDirectories(directory)

local colors = {
  outline = Color { r = 9, g = 20, b = 30, a = 255 },
  slate = Color { r = 16, g = 30, b = 43, a = 255 },
  cream = Color { r = 231, g = 230, b = 216, a = 255 },
  brass = Color { r = 211, g = 183, b = 130, a = 255 },
  teal = Color { r = 126, g = 174, b = 160, a = 255 },
  red = Color { r = 209, g = 126, b = 112, a = 255 },
}
local sprite = Sprite(32, 32, ColorMode.RGB)
sprite.layers[1].name = "outline"
local layers = { outline = sprite.layers[1], fill = sprite:newLayer(), accent = sprite:newLayer() }
layers.fill.name = "fill"
layers.accent.name = "accent"
local palette = Palette(7)
palette:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
for index, name in ipairs { "outline", "slate", "cream", "brass", "teal", "red" } do
  palette:setColor(index, colors[name])
end
sprite:setPalette(palette)
local images = {}
local function put(layer, x, y, color)
  assert(x >= 0 and x < 32 and y >= 0 and y < 32, "Pixel outside 32x32")
  images[layer]:drawPixel(x, y, colors[color])
end
local function rectangle(layer, x, y, width, height, color)
  for py = y, y + height - 1 do
    for px = x, x + width - 1 do put(layer, px, py, color) end
  end
end
local function line(layer, x1, y1, x2, y2, color)
  local dx, dy = math.abs(x2 - x1), -math.abs(y2 - y1)
  local sx, sy = x1 < x2 and 1 or -1, y1 < y2 and 1 or -1
  local error = dx + dy
  while true do
    put(layer, x1, y1, color)
    if x1 == x2 and y1 == y2 then break end
    local twice = error * 2
    if twice >= dy then error = error + dy; x1 = x1 + sx end
    if twice <= dx then error = error + dx; y1 = y1 + sy end
  end
end
local function polygon(layer, points, color)
  local left, right, top, bottom = 31, 0, 31, 0
  for _, p in ipairs(points) do
    left = math.min(left, p[1]); right = math.max(right, p[1])
    top = math.min(top, p[2]); bottom = math.max(bottom, p[2])
  end
  for y = top, bottom do
    for x = left, right do
      local inside = false
      local j = #points
      for i = 1, #points do
        local a, b = points[i], points[j]
        if ((a[2] > y) ~= (b[2] > y)) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then inside = not inside end
        j = i
      end
      if inside then put(layer, x, y, color) end
    end
  end
  for i, a in ipairs(points) do
    local b = points[i % #points + 1]
    line(layer, a[1], a[2], b[1], b[2], color)
  end
end
local function frame(name, draw)
  local index = #sprite.frames
  if index > 1 or #sprite.tags > 0 then sprite:newEmptyFrame(); index = #sprite.frames end
  images = { outline = Image(32, 32, ColorMode.RGB), fill = Image(32, 32, ColorMode.RGB), accent = Image(32, 32, ColorMode.RGB) }
  draw()
  for layer, image in pairs(images) do sprite:newCel(layers[layer], index, image, Point(0, 0)) end
  sprite.frames[index].duration = 0.1
  local tag = sprite:newTag(index, index)
  tag.name = name
end

frame("arrow", function()
  polygon("outline", { {3,3}, {3,27}, {9,21}, {13,29}, {17,27}, {13,19}, {23,19} }, "outline")
  polygon("fill", { {5,7}, {5,23}, {10,18}, {14,26}, {15,25}, {11,17}, {18,17} }, "cream")
  polygon("accent", { {9,12}, {18,17}, {13,17}, {11,16} }, "brass")
  line("accent", 12,22,14,26,"brass")
  line("accent", 13,24,14,25,"teal")
end)

frame("pointing", function()
  polygon("outline", { {12,3}, {15,3}, {17,5}, {17,12}, {19,12}, {20,13}, {22,13}, {24,15}, {24,22}, {22,25}, {22,28}, {10,28}, {10,25}, {7,22}, {5,18}, {5,15}, {8,15}, {11,18}, {11,5} }, "outline")
  polygon("fill", { {13,5}, {15,5}, {15,15}, {18,14}, {19,16}, {21,15}, {22,16}, {22,21}, {20,24}, {12,24}, {12,23}, {9,21}, {7,17}, {8,17}, {12,21}, {13,21} }, "cream")
  rectangle("fill", 12,25,9,2,"brass")
  rectangle("accent", 14,25,5,1,"teal")
  line("accent",16,16,16,19,"brass")
  line("accent",19,17,19,20,"brass")
  line("accent",14,6,14,10,"brass")
end)

frame("move", function()
  polygon("outline", { {15,2}, {22,9}, {19,9}, {19,12}, {22,12}, {22,9}, {29,15}, {22,22}, {22,19}, {19,19}, {19,22}, {22,22}, {15,29}, {9,22}, {12,22}, {12,19}, {9,19}, {9,22}, {2,15}, {9,9}, {9,12}, {12,12}, {12,9}, {9,9} }, "outline")
  polygon("fill", { {15,5}, {19,8}, {17,8}, {17,14}, {23,14}, {23,12}, {26,15}, {23,19}, {23,17}, {17,17}, {17,23}, {19,23}, {15,26}, {12,23}, {14,23}, {14,17}, {8,17}, {8,19}, {5,15}, {8,12}, {8,14}, {14,14}, {14,8}, {12,8} }, "cream")
  rectangle("accent",14,14,3,3,"teal")
  line("accent",15,6,15,11,"brass")
  line("accent",19,15,24,15,"brass")
  line("accent",15,20,15,24,"brass")
  line("accent",6,15,11,15,"brass")
end)

frame("can_drop", function()
  polygon("outline", { {15,3}, {28,15}, {15,28}, {3,15} }, "outline")
  polygon("fill", { {15,6}, {25,15}, {15,25}, {6,15} }, "cream")
  polygon("accent", { {15,8}, {23,15}, {15,23}, {8,15} }, "brass")
  rectangle("outline",13,9,5,13,"outline")
  rectangle("outline",9,13,13,5,"outline")
  rectangle("accent",14,10,3,11,"teal")
  rectangle("accent",10,14,11,3,"teal")
  put("accent",14,14,"cream")
end)

frame("forbidden", function()
  polygon("outline", { {11,3}, {20,3}, {25,7}, {28,12}, {28,19}, {24,25}, {20,28}, {11,28}, {6,24}, {3,19}, {3,12}, {6,7} }, "outline")
  polygon("fill", { {11,5}, {20,5}, {24,9}, {26,13}, {26,19}, {22,24}, {19,26}, {12,26}, {8,22}, {5,18}, {5,12}, {8,8} }, "cream")
  polygon("accent", { {12,8}, {19,8}, {23,12}, {23,18}, {19,23}, {12,23}, {8,18}, {8,12} }, "slate")
  polygon("accent", { {8,7}, {10,7}, {25,22}, {23,25}, {21,24}, {7,10} }, "outline")
  polygon("accent", { {9,8}, {10,8}, {24,22}, {23,24}, {8,9} }, "red")
  line("accent",11,5,19,5,"brass")
end)

sprite:saveAs(source)
assert(app.fs.isFile(source), "Native source missing after save")
print("CURSOR_SOURCE_OK: " .. source .. "; frames=" .. #sprite.frames .. "; layers=" .. #sprite.layers)
sprite:close()
