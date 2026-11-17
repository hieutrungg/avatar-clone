local sprite = Sprite(128,32,ColorMode.RGB)
local image = sprite.cels[1].image
local function ink(hex)
  return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local function box(frame,x,y,w,h,hex)
  local color=ink(hex)
  for yy=y,y+h-1 do for xx=x,x+w-1 do image:drawPixel(frame*32+xx,yy,color) end end
end
local function line(frame, x, y, x2, y2, hex)
  local steps = math.max(math.abs(x2-x),math.abs(y2-y),1)
  local color = ink(hex)
  for i=0,steps do
    local px=math.floor(x+(x2-x)*i/steps+0.5)
    local py=math.floor(y+(y2-y)*i/steps+0.5)
    image:drawPixel(frame*32+px,py,color)
  end
end
box(0,0,0,32,32,"a97c51")
box(0,0,0,32,2,"bc8d5c")
local cracks={{0,15,8,13},{8,13,14,17},{14,17,19,8},{19,8,23,7},
              {23,7,25,0},{23,7,31,10},{14,17,17,25},{17,25,13,31},
              {17,25,27,23},{27,23,31,26},{7,0,8,13}}
for _,c in ipairs(cracks) do
  line(0,c[1],c[2],c[3],c[4],"714b35")
  if c[2]<30 and c[4]<30 then line(0,c[1],c[2]+1,c[3],c[4]+1,"c19162") end
end
box(1,5,17,22,10,"704a36")
box(1,7,16,18,8,"ac774f")
box(1,10,17,12,5,"614637")
box(1,13,10,7,7,"a68b60")
box(2,4,16,24,12,"62655c")
box(2,6,14,20,9,"9da28d")
box(2,9,16,14,5,"436d70")
box(2,10,17,11,2,"80a49a")
box(2,7,8,2,9,"916c4b")
box(2,23,8,2,9,"916c4b")
box(2,6,6,20,3,"b98c54")
box(2,16,8,1,9,"d1b27c")
box(3,10,12,12,13,"646f6e")
box(3,12,12,8,11,"a7b4a2")
box(3,15,8,5,5,"d6bc81")
box(3,13,16,6,2,"827154")

sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32","drought.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32","drought.png"))
sprite:close()
