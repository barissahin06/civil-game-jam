-- Authored native pixel scene. Two drawn key poses per simulation state; no raster input.
local root=assert(app.params["repo"], "Pass repo")
local dir=root.."/art/production/ui/crisis_pilot/"
assert(not app.fs.isFile(dir.."operations.aseprite"), "Do not overwrite an edited native source")
local spr=Sprite(480,270,ColorMode.RGB)
local colors={sky=0xff30251b,ground=0xff383b36,ink=0xff201c18,wall=0xff7e8175,
 light=0xffc1c3aa,shade=0xff535b53,red=0xff6663ad,teal=0xff99ad78,gold=0xff82b7d3,
 dark=0xff392e24,blue=0xff7c6b48,skin=0xff99bbce,orange=0xff65a2d2}
local function rect(img,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do
  if xx>=0 and xx<480 and yy>=0 and yy<270 then img:drawPixel(xx,yy,c) end
 end end
end
local function line(img,x,y,w,c) rect(img,x,y,w,1,c) end
local function building(img,x,y,w,h,restored)
 rect(img,x+5,y+6,w,h,colors.ink)
 rect(img,x,y,w,h,colors.shade);rect(img,x+4,y+4,w-8,h-4,colors.wall)
 rect(img,x-4,y-6,w+8,8,colors.light)
 for yy=y+14,y+h-12,24 do for xx=x+10,x+w-15,22 do
  rect(img,xx,yy,12,16,colors.ink);rect(img,xx+2,yy+2,8,11,colors.blue)
  rect(img,xx+2,yy+2,3,11,colors.gold)
 end end
 if not restored then
  for i=0,8 do rect(img,x+w-24-i*2,y+8+i*6,3,9,colors.ink) end
  for i=0,6 do rect(img,x-4+i*11,y+h-8-(i%3)*5,15,8,colors.shade) end
 end
end
local function person(img,x,y,pose,kind)
 rect(img,x-3,y+17,18,3,colors.ink)
 rect(img,x+2,y-12,8,8,colors.skin);rect(img,x,y-15,12,4,colors.gold)
 rect(img,x+1,y-4,10,13,kind or colors.orange)
 rect(img,x+4,y-3,3,12,colors.light)
 rect(img,x+1,y+9,4,9,colors.dark);rect(img,x+8,y+9,4,9,colors.dark)
 if pose==0 then
  rect(img,x-3,y-2,4,11,colors.orange);rect(img,x+11,y-2,4,11,colors.orange)
 else
  rect(img,x-6,y+2,7,4,colors.orange);rect(img,x+11,y+3,9,4,colors.skin)
  rect(img,x+18,y+4,2,18,colors.light)
 end
end
local names={"waiting","rescue","aid","recovery","restored"}
spr.layers[1].name="01 / Ground and skyline"
local buildings=spr:newLayer();buildings.name="02 / Buildings and damage"
local equipment=spr:newLayer();equipment.name="03 / Tents and equipment"
local workers=spr:newLayer();workers.name="04 / Drawn work poses"
for f=1,10 do
 if f>1 then spr:newEmptyFrame() end
 local state=math.floor((f-1)/2);local pose=(f-1)%2
 spr.frames[f].duration=0.35
 local base=Image(480,270);base:clear(colors.sky)
 rect(base,0,92,480,178,colors.ground)
 for x=0,479 do
  local top=75+math.floor(math.sin(x*0.023)*12)+math.floor(math.cos(x*0.057)*5)
  rect(base,x,top,1,100-top,colors.dark)
 end
 for y=180,269 do
  local edge=math.floor((y-180)*0.65)
  rect(base,0,y,480,1,colors.shade)
  rect(base,130+edge,y,170,1,colors.dark)
 end
 for x=0,479,9 do for y=104,269,8 do
  if (x*13+y*7)%17<5 then rect(base,x,y,3,1,colors.shade) end
 end end
 for i=0,6 do rect(base,180+i*15,230+i*5,10,2,colors.gold) end
 spr:newCel(spr.layers[1],f,base)
 local b=Image(480,270)
 building(b,26,61,105,112,state==4)
 building(b,144,88,114,78,state==4)
 rect(b,184,120,26,46,colors.ink);rect(b,188,124,18,42,colors.blue)
 if state~=4 then
  for i=0,15 do
   local x=30+(i*37)%210;local y=158+(i*13)%24
   rect(b,x,y,14+(i%3)*3,7,colors.ink);rect(b,x,y-3,11+(i%3)*3,7,colors.wall)
  end
 else
  for i=0,4 do rect(b,20+i*49,178,24,4,colors.teal) end
 end
 spr:newCel(buildings,f,b)
 local e=Image(480,270)
 -- Field shelter, independent from workers so cels remain editable.
 for i=0,42 do rect(e,326-i,112+i,2*i+20,1,colors.teal) end
 rect(e,284,154,104,39,colors.shade);rect(e,289,155,94,34,colors.teal)
 rect(e,324,139,24,50,colors.dark);rect(e,330,144,12,45,colors.ink)
 rect(e,292,160,22,14,colors.light);rect(e,300,158,6,18,colors.red)
 rect(e,292,164,22,6,colors.red)
 -- Radio table and floodlight.
 rect(e,408,111,3,92,colors.wall);rect(e,399,104,22,12,colors.gold)
 rect(e,399,106,22,2,colors.light);rect(e,390,199,41,3,colors.ink)
 rect(e,402,182,48,6,colors.blue);rect(e,405,188,3,16,colors.ink)
 rect(e,443,188,3,16,colors.ink);rect(e,418,170,17,12,colors.dark)
 rect(e,429,159,2,13,colors.light);rect(e,421,173,7,3,colors.teal)
 if state==2 or state==3 or state==4 then
  for i=0,3 do
   local x=275+(i%2)*24;local y=216-math.floor(i/2)*18
   rect(e,x,y,21,17,colors.ink);rect(e,x+1,y+1,18,14,colors.gold)
   rect(e,x+8,y+1,3,14,colors.light)
  end
 end
 if state==3 then
  rect(e,98,181,58,28,colors.blue);rect(e,105,175,24,11,colors.gold)
  rect(e,104,204,13,13,colors.ink);rect(e,140,204,13,13,colors.ink)
 end
 spr:newCel(equipment,f,e)
 local w=Image(480,270)
 person(w,421,209,0,colors.blue)
 if state==1 then person(w,104,190,pose);person(w,159,177,1-pose);person(w,221,194,pose) end
 if state==2 then
  person(w,259,210,pose);person(w,331,207,1-pose,colors.teal)
  rect(w,269+pose*5,212,16,12,colors.gold)
 end
 if state==3 then person(w,188,189,pose);person(w,245,195,1-pose) end
 if state==4 then person(w,176,196,pose,colors.teal);person(w,310,210,1-pose,colors.teal) end
 spr:newCel(workers,f,w)
end
for index,name in ipairs(names) do
 local tag=spr:newTag((index-1)*2+1,index*2);tag.name=name
end
spr.data=json.encode({kind="representative_operation",width=480,height=270,states=names})
spr:saveAs(dir.."operations.aseprite")
print("OPERATION_NATIVE_PASS frames="..#spr.frames.." layers="..#spr.layers)
