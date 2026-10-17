-- Rebuild only the derived sheet; preserve the editable native source.
local root=assert(app.params["repo"], "Pass repo")
local sprite=assert(app.open(root.."/art/production/ui/crisis_pilot/operations.aseprite"))
assert(sprite.width==480 and sprite.height==270 and #sprite.frames==10)
local sheet=Image(4800,270,ColorMode.RGB)
for index=1,10 do
 local frame=Image(480,270,ColorMode.RGB)
 frame:drawSprite(sprite,index)
 sheet:drawImage(frame,Point((index-1)*480,0))
end
sheet:saveAs(root.."/our-game/ui_preview/assets/operations.png")
sprite:close()
print("OPERATION_EXPORT_PASS states=5 poses=2 native=480x270")
