-- One-time native authoring. Edit the layered Aseprite source thereafter, then run export.lua.
local root=assert(REWRITE_ROOT or app.params["repo"], "Pass repo")
local destination=root.."/art/production/ui/main_menu/night_operations.aseprite"
assert(not app.fs.isFile(destination), "Source exists; checkpoint and edit it instead of regenerating")
local W,H=1920,1080
local rgba=app.pixelColor.rgba
local function color(hex,a)
 return rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),a or 255)
end
local function rect(im,x,y,w,h,c)
 for yy=math.max(0,math.floor(y)),math.min(H-1,math.floor(y+h-1)) do
  for xx=math.max(0,math.floor(x)),math.min(W-1,math.floor(x+w-1)) do im:drawPixel(xx,yy,c) end
 end
end
local function line(im,x1,y1,x2,y2,c,size)
 local n=math.max(math.abs(x2-x1),math.abs(y2-y1),1)
 for t=0,n do rect(im,math.floor(x1+(x2-x1)*t/n),math.floor(y1+(y2-y1)*t/n),size or 1,size or 1,c) end
end
local function poly(im,points,c)
 local y0,y1=H,0
 for _,p in ipairs(points) do y0=math.min(y0,p[2]);y1=math.max(y1,p[2]) end
 for y=math.max(0,y0),math.min(H-1,y1) do
  local xs={}
  for i,p in ipairs(points) do
   local q=points[i%#points+1]
   if (p[2]<=y and q[2]>y) or(q[2]<=y and p[2]>y) then xs[#xs+1]=p[1]+(y-p[2])*(q[1]-p[1])/(q[2]-p[2]) end
  end
  table.sort(xs)
  for i=1,#xs-1,2 do rect(im,math.ceil(xs[i]),y,math.floor(xs[i+1])-math.ceil(xs[i])+1,1,c) end
 end
end
local function disk(im,cx,cy,r,c)
 for y=-r,r do
  local x=math.floor(math.sqrt(r*r-y*y))
  rect(im,cx-x,cy+y,x*2+1,1,c)
 end
end
local s=Sprite(W,H,ColorMode.RGB)
local function layer(name)
 local l=#s.layers==1 and s.layers[1].name=="Layer 1" and s.layers[1] or s:newLayer()
 l.name=name
 local im=Image(W,H)
 if l:cel(1) then l:cel(1).image=im else s:newCel(l,1,im) end
 return im,l
end
local function finish(im,l) l:cel(1).image=im end

local im,l=layer("01 / Night room and floor")
for y=0,H-1,4 do
 local t=math.min(y/800,1)
 rect(im,0,y,W,4,rgba(14+math.floor(t*5),24+math.floor(t*8),35+math.floor(t*10),255))
end
rect(im,0,735,W,345,color("0b1721"))
for x=440,1920,180 do line(im,1200,660,x,1080,color("20303b"),2) end
for _,y in ipairs({790,838,905,1000}) do line(im,440,y,1920,y,color("1c2a35"),2) end
rect(im,0,48,W,12,color("090f18"));rect(im,0,60,W,4,color("2b3e4b"))
for x=640,1880,250 do
 rect(im,x,64,4,672,color("0e1b27"));rect(im,x+4,64,2,672,color("263c49"))
end
for y=106,702,96 do line(im,640,y,1918,y,color("20333f"),1) end
finish(im,l)

im,l=layer("02 / City through the eastern window")
rect(im,1374,106,484,464,color("091623"))
for y=112,550,4 do
 local t=(y-112)/440
 rect(im,1380,y,470,4,rgba(19+math.floor(t*21),34+math.floor(t*17),50+math.floor(t*13),255))
end
disk(im,1746,188,29,color("71847e"));disk(im,1756,181,25,color("1e3041"))
for i=1,42 do
 local x=1382+(i*131)%460;local y=122+(i*73)%180
 rect(im,x,y,2,2,color(i%3==0 and "8da7a5" or "49616d"))
end
poly(im,{{1380,374},{1440,350},{1488,366},{1530,342},{1615,364},{1700,338},{1788,365},{1850,355},{1850,470},{1380,470}},color("233b48"))
rect(im,1380,458,470,94,color("152f3c"))
for i=0,29 do
 local x=1384+i*16;local bh=35+(i*37)%72
 rect(im,x,462-bh,16,bh,color(i%2==0 and "101f2b" or "162a36"))
 for wy=462-bh+10,450,12 do
  for wx=x+4,x+11,6 do if (wx+wy+i)%5~=0 then rect(im,wx,wy,2,3,color(i%3==0 and "b49d67" or "6f8c87")) end end
 end
end
-- A dome and paired slender minarets establish the local skyline without depicting a disaster.
disk(im,1564,392,28,color("0d1d29"));rect(im,1531,391,67,56,color("0d1d29"))
for _,x in ipairs({1520,1608}) do
 rect(im,x,357,5,89,color("0b1b26"));poly(im,{{x-2,358},{x+2,342},{x+7,358}},color("0b1b26"))
 rect(im,x-3,375,12,3,color("49605f"))
end
for y=472,544,8 do
 for i=0,35 do
  local x=1384+(i*71+y*3)%452
  rect(im,x,y,5+(i%4)*3,1,color(i%3==0 and "797b53" or "365568"))
 end
end
rect(im,1364,96,504,12,color("0b1722"));rect(im,1364,96,12,486,color("0b1722"))
rect(im,1856,96,12,486,color("0b1722"));rect(im,1364,570,504,16,color("3a4b50"))
for _,x in ipairs({1490,1612,1734}) do rect(im,x,108,8,462,color("102331"));rect(im,x+8,108,2,462,color("536766")) end
rect(im,1376,314,480,8,color("102331"));rect(im,1376,322,480,2,color("536766"))
finish(im,l)

im,l=layer("03 / Türkiye coordination board")
rect(im,716,142,608,418,color("08151e"));rect(im,724,150,592,402,color("59736f"))
rect(im,728,154,584,394,color("1a353d"));rect(im,734,160,572,382,color("102934"))
for x=748,1290,26 do line(im,x,172,x,526,color("1e3c45")) end
for y=172,526,26 do line(im,748,y,1290,y,color("1e3c45")) end
local map=assert(app.open(root.."/art/production/ui/p0/map-general.aseprite"))
local land=Image(map.width,map.height)
for _,ml in ipairs(map.layers) do
 if ml.name=="02 / Pasif Türkiye zemini" or (ml.name:find(" / ",1,true) and not ml.name:match("^%d") and not ml.name:match("^HIT")) then
  local c=ml:cel(1);if c then land:drawImage(c.image,c.position) end
 end
end
local xmin,ymin,xmax,ymax=map.width,map.height,0,0
for p in land:pixels() do
 if app.pixelColor.rgbaA(p())>0 then xmin=math.min(xmin,p.x);ymin=math.min(ymin,p.y);xmax=math.max(xmax,p.x);ymax=math.max(ymax,p.y) end
end
assert(xmax>xmin and ymax>ymin,"Native Türkiye land is required")
local tw=530;local th=math.floor((ymax-ymin)/(xmax-xmin)*tw)
local tx,ty=756,260
for y=0,th,2 do for x=0,tw,2 do
 local sx=math.min(xmax,math.floor(xmin+x/tw*(xmax-xmin)))
 local sy=math.min(ymax,math.floor(ymin+y/th*(ymax-ymin)))
 if app.pixelColor.rgbaA(land:getPixel(sx,sy))>0 then rect(im,tx+x,ty+y,2,2,color("73998d")) end
end end
map:close()
for _,p in ipairs({{818,282},{850,328},{1002,320},{1080,356},{1234,320},{1142,380},{1040,400}}) do
 rect(im,p[1]-4,p[2]-4,10,10,color("254d50"));rect(im,p[1]-1,p[2]-1,4,4,color("e2c68b"))
end
for i=0,20 do rect(im,754+i*25,506,14,3,color(i%4==0 and "c4b47c" or "527d76")) end
rect(im,754,190,90,6,color("699488"));rect(im,754,206,134,3,color("3b6260"))
rect(im,1152,190,130,3,color("49726e"));rect(im,1228,204,54,3,color("49726e"))
finish(im,l)

im,l=layer("04 / Wall clock and shelves")
disk(im,1034,94,35,color("091520"));disk(im,1034,94,30,color("67817b"));disk(im,1034,94,26,color("1b303b"))
for i=0,11 do local a=i*math.pi/6;rect(im,1033+math.floor(math.sin(a)*22),93-math.floor(math.cos(a)*22),3,3,color("9eac98")) end
line(im,1034,94,1034,77,color("d8d3ad"),2);line(im,1034,94,1049,102,color("d8d3ad"),2)
rect(im,712,610,314,12,color("07131c"));rect(im,712,622,314,4,color("43555a"))
for i=0,8 do
 local x=732+i*28
 rect(im,x,558+(i%3)*5,21,52-(i%3)*5,color(i%3==0 and "735c4c" or "36565c"))
 rect(im,x+3,566+(i%3)*5,2,35,color("8b8c72"));rect(im,x+9,597,10,3,color("b2aa83"))
end
rect(im,1804,620,44,126,color("14252d"));rect(im,1810,628,32,110,color("8b7858"))
for y=642,730,16 do rect(im,1816,y,21,3,color("4b5249")) end
finish(im,l)

im,l=layer("05 / Workbench and perspective")
poly(im,{{690,780},{1770,752},{1920,904},{732,1018}},color("0a141c"))
poly(im,{{698,754},{1758,730},{1912,882},{732,982}},color("596365"))
poly(im,{{704,764},{1756,740},{1890,872},{738,966}},color("384a50"))
poly(im,{{732,982},{1912,882},{1912,910},{732,1014}},color("20333e"))
line(im,742,970,1882,873,color("8b8870"),3)
poly(im,{{776,1008},{816,1004},{824,1080},{778,1080}},color("0a1720"))
poly(im,{{1780,921},{1820,918},{1850,1080},{1800,1080}},color("0a1720"))
for i=0,32 do line(im,760+i*30,784,795+i*30,810,color("405258")) end
finish(im,l)

im,l=layer("06 / Consoles and live telemetry")
rect(im,1022,568,334,218,color("091721"));rect(im,1030,576,318,200,color("425c60"))
rect(im,1040,586,298,168,color("0c2531"));rect(im,1044,590,290,160,color("143744"))
rect(im,1054,600,170,4,color("689a91"));rect(im,1288,600,34,4,color("b0ae75"))
for y=628,734,22 do line(im,1054,y,1322,y,color("244854")) end
for x=1054,1322,28 do line(im,x,620,x,736,color("244854")) end
local graph={{1058,705},{1080,705},{1090,684},{1108,696},{1122,649},{1136,716},{1158,692},{1184,692},{1194,682},{1210,688},{1234,658},{1244,684},{1280,684},{1296,668},{1317,672}}
for i=1,#graph-1 do line(im,graph[i][1],graph[i][2],graph[i+1][1],graph[i+1][2],color("a0c6a3"),2) end
rect(im,1274,761,7,4,color("d5b56e"));rect(im,1300,761,16,4,color("253c48"))
rect(im,1162,786,48,37,color("1a303c"));rect(im,1128,820,116,8,color("577071"))
poly(im,{{1048,850},{1346,824},{1383,875},{1070,910}},color("172c37"))
for row=0,3 do for col=0,18 do rect(im,1064+col*14+row*5,856+row*10-col,10,5,color("4c6569")) end end
rect(im,1400,618,156,116,color("10232d"));rect(im,1406,624,144,104,color("496365"))
rect(im,1414,632,128,80,color("122e39"))
for i=0,10 do rect(im,1424+i*10,691-(i*11)%42,5,11+(i*11)%42,color(i%4==0 and "bea974" or "608e83")) end
rect(im,1464,736,34,55,color("203741"));rect(im,1446,786,72,6,color("597370"))
finish(im,l)

im,l=layer("07 / Radio and emergency telephone")
poly(im,{{766,826},{966,810},{1016,846},{804,868}},color("6b7369"))
poly(im,{{804,868},{1016,846},{1016,930},{804,954}},color("223942"))
poly(im,{{766,826},{804,868},{804,954},{766,910}},color("162a34"))
for y=877,932,6 do for x=824,890,6 do rect(im,x,y,3,2,color("081c28")) end end
rect(im,914,862,80,27,color("102632"));rect(im,919,867,65,12,color("9fba8f"))
for i=0,10 do rect(im,922+i*5,870,2,6,color("334b46")) end
disk(im,934,916,11,color("101e28"));disk(im,934,916,7,color("748479"))
disk(im,974,912,11,color("101e28"));disk(im,974,912,7,color("748479"))
line(im,782,822,770,690,color("0a1924"),4);line(im,770,690,766,656,color("84978a"),2)
for i=0,12 do disk(im,742+i*6,912+(i%2)*4,4,color("091822")) end
rect(im,706,870,34,16,color("132b35"));rect(im,700,880,48,45,color("132b35"))
finish(im,l)

im,l=layer("08 / Paper maps and notes")
poly(im,{{1372,834},{1578,813},{1682,913},{1452,944}},color("b6b494"))
poly(im,{{1382,838},{1574,822},{1668,906},{1454,935}},color("d0c8a3"))
line(im,1462,832,1536,925,color("998f75"),2);line(im,1524,828,1610,916,color("998f75"),2)
for i=0,7 do line(im,1400+i*19,845-i,1460+i*23,920-i*3,color("aaa98b")) end
for _,p in ipairs({{1458,855},{1480,870},{1514,861},{1538,894},{1564,879},{1608,900}}) do
 disk(im,p[1],p[2],3,color("6a8273"))
end
line(im,1458,855,1480,870,color("7a9179"),2);line(im,1480,870,1514,861,color("7a9179"),2)
line(im,1514,861,1538,894,color("7a9179"),2);line(im,1538,894,1608,900,color("7a9179"),2)
poly(im,{{1274,935},{1392,923},{1412,960},{1290,975}},color("8a7764"))
for i=0,3 do line(im,1292,943+i*6,1380,934+i*6,color("b5aa8b")) end
line(im,1566,802,1650,866,color("ab7754"),5);line(im,1650,866,1658,872,color("ded0aa"),3)
finish(im,l)

im,l=layer("09 / Lamp and warm working light")
disk(im,1738,842,44,color("172b34"));rect(im,1700,838,80,8,color("4e5f60"))
line(im,1736,832,1724,676,color("6c7c71"),8);line(im,1724,676,1666,574,color("6c7c71"),8)
disk(im,1724,676,11,color("1a303b"));disk(im,1666,574,9,color("9a9b7d"))
poly(im,{{1606,565},{1686,552},{1730,596},{1578,620}},color("18313b"))
line(im,1580,618,1728,596,color("dfb573"),4)
poly(im,{{1584,626},{1724,603},{1848,856},{1498,896}},color("e4bd79",12))
rect(im,1612,855,54,52,color("9d9c7f"));rect(im,1618,861,42,40,color("b5b194"))
disk(im,1639,855,27,color("b7b296"));disk(im,1639,855,21,color("233b42"))
line(im,1666,864,1684,867,color("a6a58a"),5);line(im,1684,867,1684,890,color("a6a58a"),5);line(im,1684,890,1666,894,color("a6a58a"),5)
finish(im,l)

im,l=layer("10 / Foreground chair")
poly(im,{{1066,985},{1102,939},{1240,928},{1294,969},{1284,1080},{1058,1080}},color("08141e"))
poly(im,{{1080,986},{1112,951},{1234,940},{1276,974},{1268,1056},{1074,1068}},color("18303b"))
line(im,1114,952,1231,942,color("3c555b"),3)
poly(im,{{1110,1014},{1240,1001},{1242,1034},{1110,1046}},color("152a35"))
finish(im,l)

im,l=layer("11 / Left menu quiet area and edge shadows")
for x=0,750,4 do
 local a=math.floor(245*(1-math.min(x/750,1)))
 rect(im,x,0,4,H,color("09141e",a))
end
for i=0,23 do
 rect(im,0,i*3,W,3,color("050d16",math.floor((24-i)*3)))
 rect(im,0,H-3-i*3,W,3,color("050d16",math.floor((24-i)*4)))
end
finish(im,l)
s.data=json.encode({asset="Rewrite it / Night operations",native_width=W,native_height=H,frame_count=1,palette="teal, slate, muted brass",source="Aseprite native layers; existing Türkiye source sampled read-only",authoring="author_splash.lua",runtime="ui_preview/assets/main_menu_splash.png"})
assert(#s.layers==11 and #s.frames==1)
s:saveAs(destination)
print("REWRITE_SPLASH_SOURCE_PASS layers="..#s.layers.." width="..s.width.." height="..s.height)
s:close()
