local sprite = Sprite(160, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function paint(frame, x, y, width, height, hex)
  local value = tonumber(hex, 16)
  local color = app.pixelColor.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, 255)
  for py = y, y + height - 1 do
    for px = x, x + width - 1 do
      image:drawPixel(frame * 32 + px, py, color)
    end
  end
end

-- Storehouse entrance.
paint(0, 5, 10, 22, 20, "563c33")
paint(0, 7, 11, 18, 16, "ad8152")
paint(0, 10, 15, 12, 14, "5d4637")
paint(0, 11, 16, 4, 13, "76583c")
paint(0, 18, 23, 2, 1, "d4b575")
for line = 0, 4 do
  paint(0, 10 - line * 2, 4 + line * 2, 12 + line * 4, 2, line % 2 == 0 and "9b5340" or "ac6250")
end
paint(0, 5, 29, 22, 2, "6e5543")

-- Workbench before and after the tools are installed.
for frame = 1, 2 do
  paint(frame, 5, 14, 22, 6, "594631")
  paint(frame, 6, 13, 20, 4, "b28a59")
  paint(frame, 7, 20, 3, 9, "765837")
  paint(frame, 23, 20, 3, 9, "765837")
  paint(frame, 8, 24, 17, 2, "5b4738")
end
paint(1, 7, 26, 17, 3, "9e764b")
paint(2, 10, 11, 10, 2, "a9ab82")
paint(2, 20, 9, 4, 4, "4b665d")
paint(2, 21, 9, 2, 2, "8faaa1")
paint(2, 14, 14, 7, 2, "ddc597")

-- Pack shelf.
paint(3, 4, 7, 24, 23, "6b4e39")
paint(3, 6, 9, 20, 19, "937047")
for row = 0, 1 do
  local y = 13 + row * 9
  paint(3, 8, y, 7, 6, "bd9358")
  paint(3, 18, y - 2, 6, 8, "cbaa75")
  paint(3, 7, y + 6, 18, 2, "573f33")
end

-- A short rack of bamboo waiting to be split.
paint(4, 6, 10, 3, 19, "78583c")
paint(4, 23, 10, 3, 19, "78583c")
for row = 0, 4 do
  local y = 15 + row * 2
  paint(4, 3, y, 25, 2, row % 2 == 0 and "81904d" or "9ea167")
  paint(4, 13, y, 2, 2, "c9bb80")
end

local source = app.params.source_dir or "art/32"
local output = app.params.out_dir or "assets/art/32"
sprite:saveAs(app.fs.joinPath(source, "storehouse.aseprite"))
sprite:saveAs(app.fs.joinPath(output, "storehouse.png"))
