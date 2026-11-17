local sprite = Sprite(192, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function box(frame, x, y, w, h, hex)
  local col = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),
    tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), 255)
  for yy=y,y+h-1 do
    for xx=x,x+w-1 do image:drawPixel(frame*32+xx, yy, col) end
  end
end

-- Bếp hội, cờ, đèn lồng, hoa đăng, vách tre và ổ gà con.
box(0,3,25,26,3,"524137")
box(0,5,16,22,11,"90634a")
box(0,6,17,20,2,"d8aa72")
box(0,11,19,10,7,"602e2a")
box(0,14,21,4,4,"ec9d4c")
box(0,5,11,22,6,"535a59")
box(0,6,11,20,1,"b1b3a0")
box(0,12,8,8,2,"846e52")
box(0,7,7,2,3,"b9c3ae")
box(0,24,6,2,5,"b9c3ae")

box(1,14,3,2,25,"876348")
box(1,16,4,11,13,"a74636")
box(1,17,5,8,10,"d26d44")
box(1,18,6,5,7,"e3b76e")
box(1,20,7,2,5,"b8503a")
box(1,12,27,6,2,"56443a")

box(2,15,2,1,6,"8a674d")
box(2,11,7,9,2,"f5bd65")
box(2,9,9,13,9,"ad4536")
box(2,11,10,9,7,"de774a")
box(2,14,9,3,9,"f0a668")
box(2,11,18,9,2,"8d4338")
box(2,15,20,1,3,"e1b457")

box(3,8,23,16,1,"a27754")
box(3,11,19,10,4,"cf8253")
box(3,13,17,6,5,"f6c76f")
box(3,15,14,2,6,"ffeda2")
box(3,4,26,23,1,"7a9e8f")

for x=3,27,4 do
  box(4,x,11,2,17,"b7895a")
  box(4,x,11,1,14,"dbac6a")
end
box(4,2,13,28,2,"76513a")
box(4,2,22,28,2,"76513a")

box(5,3,24,26,4,"8e7049")
box(5,6,22,19,5,"c7a15e")
box(5,10,19,12,6,"ebbc61")
box(5,17,15,6,6,"f4cf68")
box(5,23,17,3,2,"cc7e43")
box(5,20,16,1,1,"473930")
box(5,8,25,3,1,"e1bb7e")
box(5,22,26,4,1,"e1bb7e")

sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32","village_festival.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32","village_festival.png"))
sprite:close()
