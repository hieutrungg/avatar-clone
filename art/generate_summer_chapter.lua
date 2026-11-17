local rgba = app.pixelColor.rgba
local function rgb(hex)
  return rgba(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16), 255)
end
local function box(img, x, y, w, h, hex)
  local col = rgb(hex)
  for yy = y, y+h-1 do for xx = x, x+w-1 do img:drawPixel(xx, yy, col) end end
end
local function make(name, count, draw)
  local sprite = Sprite(count*32,32,ColorMode.RGB)
  draw(sprite.cels[1].image)
  sprite:saveCopyAs(app.fs.joinPath(app.params.source_dir or "./art/32", name..".aseprite"))
  sprite:saveCopyAs(app.fs.joinPath(app.params.out_dir or "./assets/art/32", name..".png"))
  sprite:close()
end
local plants = {
  {"sticky_rice","e6bd6d"}, {"corn","e7af49"},
  {"winter_melon","9abe77"}, {"yardlong_bean","80bb58"},
}
for _, plant in ipairs(plants) do
  make(plant[1],3,function(img)
    for f=0,2 do
      local x=f*32
      box(img,x+7,26,18,3,"5b4332")
      box(img,x+10,24,14,3,"926642")
      if f==0 then
        box(img,x+13,23,2,2,plant[2]); box(img,x+18,24,2,1,plant[2])
      else
        for n=0,2 do
          local dx=x+11+n*5
          local high=f==1 and 7 or (13+n*2)
          box(img,dx,25-high,2,high,"55804a")
          box(img,dx-3,27-high,4,2,"80ab56")
          box(img,dx+1,30-high,5,2,"668e49")
          if f==2 then
            box(img,dx-1,24-high,4,plant[1]=="yardlong_bean" and 9 or 5,plant[2])
          end
        end
        if f==2 and plant[1]=="winter_melon" then
          box(img,x+9,21,13,5,"4e7046"); box(img,x+11,19,9,6,plant[2])
        end
      end
    end
  end)
end
make("summer_seeds",5,function(img)
  local colors={"d78b46","d8bb75","e7af49","9abe77","80bb58"}
  for i, col in ipairs(colors) do
    local x=(i-1)*32
    box(img,x+7,9,18,18,"694636"); box(img,x+9,8,14,18,"d1a664")
    box(img,x+10,5,12,4,"b68a52"); box(img,x+9,13,14,9,"f4db9d")
    box(img,x+13,15,6,5,col); box(img,x+14,14,3,2,"648446")
  end
end)
make("summer_props",12,function(img)
  local function p(f,x,y,w,h,col) box(img,f*32+x,y,w,h,col) end
  local wood, dark, light, leaf = "a97047", "54392d", "ddab69", "739554"
  -- Cart, trellis, well, pump, sprinkler, cupboard, letter, radio, basket, chick, stall sign, pond.
  p(0,3,12,21,11,dark); p(0,4,11,20,9,wood); p(0,22,21,7,2,light)
  p(0,6,22,6,6,dark); p(0,17,22,6,6,dark); p(0,8,24,2,2,light); p(0,19,24,2,2,light)
  for x=6,22,8 do p(1,x,4,2,25,wood); p(1,x-2,4,6,15,leaf); p(1,x+3,9,3,6,"a3bc62") end
  p(2,2,14,28,14,"636c64"); p(2,4,13,24,6,"acaf94"); p(2,7,14,18,4,"335d60")
  p(2,7,5,2,11,wood); p(2,23,5,2,11,wood); p(2,5,4,22,3,light)
  p(3,5,22,23,5,dark); p(3,8,14,15,9,"365d66"); p(3,10,13,11,3,"7ab3af"); p(3,20,8,4,9,"658d8c")
  p(4,14,12,4,15,"658d8c"); p(4,8,11,16,3,"96b0ad"); p(4,4,8,3,2,"87cbd4"); p(4,25,8,3,2,"87cbd4")
  p(5,3,9,26,19,dark); p(5,4,8,24,17,wood); p(5,5,7,22,3,light)
  p(5,7,13,18,5,dark); p(5,13,14,6,1,light); p(5,7,20,18,3,light)
  p(6,4,12,24,14,"aa824a"); p(6,5,11,22,13,"f2deb1"); p(6,12,16,8,5,"c66d51")
  p(7,4,12,24,14,dark); p(7,6,13,20,11,wood); p(7,8,15,10,6,"385359"); p(7,22,18,3,3,light)
  p(7,24,6,1,7,"bcc3ac")
  p(8,5,14,22,11,dark); p(8,5,13,22,3,light); p(8,7,17,18,7,wood)
  for x=8,24,4 do p(8,x,17,1,7,light) end
  p(9,10,18,12,8,"dab35b"); p(9,17,15,6,6,"f1cc67"); p(9,23,17,3,2,"ce8144"); p(9,20,16,1,1,dark)
  p(10,14,10,4,17,dark); p(10,4,7,24,14,wood); p(10,5,7,22,2,light); p(10,8,12,16,2,light)
  p(11,0,1,32,31,"477971"); p(11,3,2,12,2,"7ca694"); p(11,10,22,14,1,"7ca694")
  p(11,23,9,6,4,"6e9457"); p(11,2,28,7,2,"a9ad6e")
end)
