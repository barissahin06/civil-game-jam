-- Export the editable P0 sources; never save changes back to a native source.
local root=assert(P0_ROOT or app.params["repo"], "Pass the repository root as repo")
local source=root .. "/art/production/ui/p0/"
local output=root .. "/our-game/ui_preview/assets/"
assert(app.fs.isDirectory(output), "P0 asset directory is required")
local catalog_file=assert(io.open(root .. "/our-game/regions/data/service_areas.json","rb"))
local areas=json.decode(catalog_file:read("*a")).areas;catalog_file:close()
local center_count=#areas

local function layer_image(sprite,layer)
 local cel=assert(layer:cel(1),"Expected a single-frame source")
 local image=Image(sprite.width,sprite.height)
 image:drawImage(cel.image,cel.position)
 return image
end

for _,name in ipairs({"controls","afet_pixel","icons","paper","signals","map-general","map-preparedness","map-logistics","map-damage"}) do
 local sprite=assert(app.open(source .. name .. ".aseprite"))
 assert(#sprite.frames==1)
 if name:sub(1,4)=="map-" then
  assert(sprite.width==3072 and sprite.height==1728,"Regional map canvas contract changed")
  local borders,countries,country_lines,country_names
  for _,layer in ipairs(sprite.layers) do
   if layer.name=="03 / Pasif il sınırları" then borders=layer end
   if layer.name=="01a / Çevre ülkeler" then countries=layer end
   if layer.name=="01b / Ülke sınırları" then country_lines=layer end
   if layer.name=="98 / Ülke adları" then country_names=layer end
  end
  assert(borders and borders.isVisible and borders:cel(1),"Native map must retain passive province borders")
  assert(countries and countries.isVisible and countries:cel(1) and country_lines and country_lines.isVisible
   and country_lines:cel(1) and country_names and country_names.isVisible and country_names:cel(1),
   "Native map must retain noninteractive country context")
  local metadata=json.decode(borders.data)
  assert(metadata.visible_provinces==81 and metadata.passive_provinces==81-center_count and metadata.selectable_provinces==center_count,
   "Province border contract changed")
 end
 if name=="map-general" then
  local terrain=Image(sprite.width,sprite.height,ColorMode.RGB)
  for _,wanted in ipairs({"70 / Arazi - Dağ sıraları","71 / Arazi - Orman ve bozkır","72 / Arazi - Kıyı dokusu"}) do
   local found
   for _,layer in ipairs(sprite.layers) do
    if layer.name==wanted then found=layer;break end
   end
   assert(found and found.isVisible and found:cel(1),"Native terrain layer missing: " .. wanted)
   local cel=found:cel(1)
   terrain:drawImage(cel.image,cel.position)
   found.isVisible=false
  end
  assert(#sprite.layers==center_count+13,"General map must retain its province, context and terrain layers")
  local count=0
  for pixel in terrain:pixels() do
   local alpha=app.pixelColor.rgbaA(pixel())
   assert(alpha==0 or alpha==255,"Terrain must retain hard pixel edges")
   if alpha==255 then count=count+1 end
  end
  assert(count>10000,"Terrain export is unexpectedly sparse")
  terrain:saveAs(output .. "map-terrain.png")
  print("TERRAIN_EXPORT_PASS layers=3 pixels=" .. count .. " 3072x1728")
 end
 sprite:saveCopyAs(output .. name .. ".png")
 if name=="map-general" then
  local mask,labels
  for _,layer in ipairs(sprite.layers) do
   if layer.name:sub(1,3)=="HIT" then mask=layer_image(sprite,layer)
   elseif layer.name:sub(1,4)=="99 /" then labels=layer_image(sprite,layer) end
  end
  assert(mask and labels,"Native map must retain IDs and city labels")
  local ids={}
  for pixel in mask:pixels() do
   local id=app.pixelColor.rgbaR(pixel())
   if id>0 then ids[id]=true end
  end
  local count=0
  for _ in pairs(ids) do count=count+1 end
  assert(count==center_count,"Selectable province count differs from the gameplay catalog")
  for _,area in ipairs(areas) do assert(ids[area.id],"Missing selectable center: " .. area.name) end
  mask:saveAs(output .. "map-hitmask.png")
  labels:saveAs(output .. "map-labels.png")
 end
 sprite:close()
end

local selection=assert(app.open(source .. "map-selection.aseprite"))
assert(#selection.layers==center_count and selection.width==3072 and selection.height==1728)
local selection_ids={}
for _,layer in ipairs(selection.layers) do
 local id=assert(tonumber(layer.name:match("^SELECT / TR%-(%d+)$")),"Selection layer ID missing")
 assert(not selection_ids[id],"Duplicate selection layer")
 selection_ids[id]=true
 layer_image(selection,layer):saveAs(output .. string.format("selection-%02d.png",id))
end
for _,area in ipairs(areas) do assert(selection_ids[area.id],"Missing selection border: " .. area.name) end
selection:close()

local descriptor=assert(io.open(source .. "afet_pixel.fnt","rb"))
local text=descriptor:read("*a");descriptor:close()
assert(text:find("chars count=126",1,true),"Bitmap font grid changed; update its descriptor")
local destination=assert(io.open(output .. "afet_pixel.fnt","wb"))
destination:write(text);destination:close()
print("P0_EXPORT_PASS native_sources=10 selectable_provinces=" .. center_count .. " glyphs=126")
