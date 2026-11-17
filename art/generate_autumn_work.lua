local sprite = Sprite(192, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function paint(frame, x, y, w, h, hex)
  local value = tonumber(hex, 16)
  local color = app.pixelColor.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, 255)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      image:drawPixel(frame * 32 + px, py, color)
    end
  end
end

-- Puddles and broken bamboo leaves in the yard.
paint(0, 7, 21, 18, 5, "86a29d")
paint(0, 3, 23, 26, 5, "75918c")
paint(0, 8, 28, 17, 1, "6b8680")
paint(0, 6, 25, 10, 1, "b1c6ba")
paint(0, 19, 23, 7, 1, "a6bcb0")
for step = 0, 9 do
  paint(1, 6 + step * 2, 24 - math.floor(step / 2), 2, 1, "806141")
  if step % 2 == 0 then
    paint(1, 7 + step * 2, 21 - math.floor(step / 2), 4, 2, "a58949")
    paint(1, 8 + step * 2, 25 - math.floor(step / 2), 4, 2, "7c9055")
  end
end

-- Open account book.
paint(2, 3, 15, 26, 14, "514037")
paint(2, 4, 16, 24, 10, "e1cca4")
paint(2, 5, 16, 22, 2, "f1dfb6")
paint(2, 15, 16, 2, 10, "a68460")
for line = 19, 24, 2 do
  paint(2, 6, line, 7, 1, "9d7e68")
  paint(2, 19, line, 7, 1, "9d7e68")
end

-- Labeled storage crate.
paint(3, 4, 12, 24, 17, "4f4638")
paint(3, 5, 13, 22, 14, "b18b54")
paint(3, 6, 14, 20, 2, "d0a672")
paint(3, 8, 17, 2, 10, "816041")
paint(3, 22, 17, 2, 10, "816041")
paint(3, 12, 18, 9, 5, "e5cb9c")
paint(3, 13, 20, 6, 1, "836953")

-- Removed-for-inspection moldy wicker.
paint(4, 6, 16, 20, 13, "6c624a")
paint(4, 8, 17, 16, 10, "b39a6d")
for line = 18, 26, 3 do
  paint(4, 8, line, 16, 1, "7b7556")
end
for n = 0, 6 do
  paint(4, 9 + (n * 7) % 14, 18 + (n * 3) % 8, 2, 2, "d3d7b8")
end

-- A row of split fine bamboo strips.
for line = 0, 5 do
  paint(5, 5 + line % 2, 17 + line * 2, 21 - line % 3, 1, "d9cb88")
  paint(5, 6, 18 + line * 2, 18, 1, "827652")
end
paint(5, 10, 17, 2, 12, "996b50")
paint(5, 21, 17, 2, 12, "996b50")

local source = app.params.source_dir or "art/32"
local output = app.params.out_dir or "assets/art/32"
sprite:saveAs(app.fs.joinPath(source, "autumn_work.aseprite"))
sprite:saveAs(app.fs.joinPath(output, "autumn_work.png"))
