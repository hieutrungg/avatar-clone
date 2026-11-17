local sprite = Sprite(256, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function box(frame, x, y, w, h, hex)
  local color = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
  for yy=y,y+h-1 do
    for xx=x,x+w-1 do image:drawPixel(frame*32+xx,yy,color) end
  end
end

-- Food stall, water jar, glass tank, and two fish.
box(0,3,13,26,14,"a26c46"); box(0,2,12,28,3,"e1ac69")
box(0,5,5,2,8,"624739"); box(0,25,5,2,8,"624739")
box(0,4,3,24,4,"a9503d"); box(0,7,3,3,4,"de9067"); box(0,17,3,3,4,"de9067")
box(0,10,18,12,5,"635a55"); box(0,11,17,10,2,"e5dcc0"); box(0,13,16,6,1,"b89c65")
box(1,9,9,14,16,"634b39"); box(1,7,12,18,12,"95674a"); box(1,9,11,3,13,"b98a59")
box(1,9,8,14,3,"ba9867"); box(1,11,8,9,1,"6c533f"); box(1,8,17,16,2,"7e9d90")
box(2,4,8,24,17,"8caa9f"); box(2,5,10,22,13,"497f83")
box(2,7,12,2,8,"79afb0"); box(2,6,22,20,2,"b8a57a"); box(2,4,24,24,2,"5d5549")

for frame=3,4 do
  local deep = frame==3 and "6a7853" or "b65f39"
  local skin = frame==3 and "a1a774" or "ec9552"
  local light = frame==3 and "c7c392" or "f9bd78"
  box(frame,7,12,16,9,deep); box(frame,6,14,19,5,skin)
  box(frame,9,12,12,5,skin); box(frame,11,13,9,2,light)
  box(frame,21,14,8,4,deep); box(frame,26,11,3,3,skin)
  box(frame,26,18,3,4,skin); box(frame,9,15,2,2,"3a3733")
  if frame==4 then box(frame,28,9,2,6,light); box(frame,28,18,2,6,light) end
end

-- Bác Lý, Chú Bình and an embroidery mat.
for frame=5,6 do
  local cloth=frame==5 and "8a664a" or "62848a"
  box(frame,9,28,14,2,"52473c")
  box(frame,11,16,11,12,cloth); box(frame,12,16,5,7,"ae9166")
  box(frame,12,7,9,9,"d2a17d"); box(frame,11,6,11,4,"595749")
  box(frame,14,12,1,1,"423831"); box(frame,18,12,1,1,"423831")
  box(frame,22,18,4,7,frame==5 and "867c58" or "d4c199")
end
box(7,5,15,22,12,"745542"); box(7,6,13,20,12,"e6d7b3")
box(7,9,16,14,6,"c0a98a"); box(7,14,17,3,5,"9f5662"); box(7,12,19,7,1,"b38077")

sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32","summer_craft.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32","summer_craft.png"))
sprite:close()
