local sprite = Sprite(192, 32, ColorMode.RGB)
local image = sprite.cels[1].image

local function paint(frame, x, y, w, h, hex)
  local rgba = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),
    tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), 255)
  for yy=y,y+h-1 do
    for xx=x,x+w-1 do image:drawPixel(frame*32+xx, yy, rgba) end
  end
end

local dark, wood, straw, shine = "543b31", "936449", "b89350", "dbba72"

-- Frame under construction and the finished thatched extension.
for frame=0,1 do
  paint(frame,1,26,30,3,"605d3b")
  for x=3,27,8 do
    paint(frame,x,11,3,17,dark)
    paint(frame,x,11,1,14,wood)
  end
  paint(frame,3,13,27,3,wood)
  if frame==1 then
    paint(frame,5,14,23,12,dark)
    for x=6,26,3 do paint(frame,x,14,2,11,straw) end
    paint(frame,5,17,23,2,wood)
    paint(frame,5,22,23,1,wood)
    for y=0,8 do
      local inset=math.max(1,7-y)
      paint(frame,inset,4+y,32-inset*2,1,y%3==0 and shine or straw)
    end
    paint(frame,1,13,30,2,dark)
    for x=3,29,3 do paint(frame,x,12,1,3,shine) end
  end
end

-- Rơm cuộn và phên thóc phơi.
for y=0,11 do
  local inset=(y<2 or y>9) and 4 or 1
  paint(2,5+inset,15+y,22-inset*2,1,(y%3==0) and shine or straw)
end
paint(2,12,16,1,10,wood)
paint(2,20,15,1,12,wood)
paint(3,2,14,28,14,dark)
paint(3,3,14,26,12,wood)
paint(3,5,15,22,10,straw)
for y=16,24,3 do
  for x=5+(y%2),25,4 do paint(3,x,y,2,1,shine) end
end
paint(3,5,14,22,1,shine)

-- Cụm rau má và ao sen nhỏ.
for _, stem in ipairs({{11,20},{18,16},{21,22},{14,24}}) do
  paint(4,stem[1],stem[2],1,7,"466a48")
  paint(4,stem[1]-2,stem[2]-1,5,4,"79a35d")
  paint(4,stem[1]-1,stem[2]-1,3,1,"a1bc70")
end
for y=4,27 do
  local inset=math.floor(math.abs(16-y)/2)+1
  paint(5,inset,y,32-inset*2,1,y<15 and "4d7c72" or "34666a")
end
paint(5,5,19,15,1,"79a59a")
paint(5,20,9,7,4,"7c9b56")
paint(5,8,13,6,3,"5c905f")
paint(5,10,11,2,3,"e098a6")
paint(5,22,7,3,3,"e3b4ad")

sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32", "quiet_farm.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32", "quiet_farm.png"))
sprite:close()
