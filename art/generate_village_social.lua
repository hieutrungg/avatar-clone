local sprite = Sprite(192, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function paint(frame, x, y, w, h, hex)
  local col = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),
    tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), 255)
  for yy=y,y+h-1 do
    for xx=x,x+w-1 do image:drawPixel(frame*32+xx, yy, col) end
  end
end

local function person(frame, skin, coat, light, hair)
  paint(frame,9,29,16,2,"535044")
  paint(frame,12,16,9,12,coat)
  paint(frame,13,17,6,5,light)
  paint(frame,10,18,3,6,coat)
  paint(frame,21,18,2,7,coat)
  paint(frame,13,24,8,5,"444349")
  paint(frame,12,28,5,2,hair)
  paint(frame,18,28,4,2,hair)
  paint(frame,12,8,9,8,skin)
  paint(frame,11,7,10,4,hair)
  paint(frame,14,5,6,3,hair)
  paint(frame,13,12,1,1,"554034")
  paint(frame,18,12,1,1,"554034")
  paint(frame,15,15,3,1,"a36755")
end

-- Trưởng thôn, Bà Minh với khăn trên tay, Tuấn đội mũ lưỡi trai.
person(0,"d9aa7d","625a4d","a28665","a7a19a")
paint(0,8,7,16,2,"5d564a")
paint(0,10,5,12,3,"716b59")
person(1,"d1a383","664451","886071","a6a29f")
paint(1,18,3,4,4,"b6ae9f")
paint(1,12,11,8,1,"625759")
paint(1,14,21,10,4,"eee0b0")
paint(1,17,22,4,1,"ac736d")
person(2,"dba87c","3f6562","688e79","393841")
paint(2,11,7,11,3,"4e6f72")
paint(2,9,9,6,1,"588180")

-- Xe máy, cọc đèn tập và khăn thêu.
paint(3,3,24,27,4,"4d453e")
paint(3,4,21,7,7,"45414a")
paint(3,21,21,7,7,"45414a")
paint(3,6,23,3,3,"9c9884")
paint(3,23,23,3,3,"9c9884")
paint(3,7,17,14,6,"507b75")
paint(3,8,15,13,3,"4b4350")
paint(3,20,13,4,9,"7b9f94")
paint(3,22,12,5,2,"e8d4a1")
paint(4,15,7,2,22,"785943")
paint(4,12,5,8,8,"876449")
paint(4,13,6,6,5,"f1cb7c")
paint(4,15,6,2,5,"f9e2a7")
paint(4,12,27,8,2,"543d34")
paint(5,5,13,22,13,"8c6c55")
paint(5,6,12,20,12,"e6d6af")
paint(5,7,13,18,1,"b0796c")
paint(5,7,22,18,1,"b0796c")
paint(5,15,15,2,6,"835d67")
paint(5,13,17,6,2,"b28485")

sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32","village_social.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32","village_social.png"))
sprite:close()
