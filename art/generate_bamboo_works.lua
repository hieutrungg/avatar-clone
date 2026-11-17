local tiles = 20
local sprite = Sprite(32 * tiles, 32, ColorMode.RGB)
local image = sprite.cels[1].image

local function rect(frame, x, y, w, h, hex)
  local value = tonumber(hex, 16)
  local color = app.pixelColor.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, 255)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      image:drawPixel(frame * 32 + px, py, color)
    end
  end
end

for frame = 0, 3 do
  local metal = frame < 2
  rect(frame, 0, 0, 32, 32, metal and "505052" or "96744f")
  for y = 0, 24, 8 do
    rect(frame, 0, y, 32, 1, metal and "3f4246" or "745538")
    local x = 8 + y / 8 * 4
    rect(frame, x, y + 1, 1, 7, metal and "44464b" or "805e40")
  end
  for n = 1, 5 do
    rect(frame, (n * 13 + frame * 5) % 27, (n * 9 + frame * 3) % 30, frame % 2 == 0 and 2 or 4, 1,
      metal and "666465" or "b0895b")
  end
end

-- Hearth, glowing coal and chimney.
rect(4, 3, 10, 26, 18, "443337")
rect(4, 5, 11, 22, 14, "847064")
rect(4, 8, 3, 16, 10, "6d5c58")
rect(4, 10, 5, 12, 2, "a18772")
rect(4, 7, 17, 18, 8, "542e2a")
rect(4, 9, 21, 14, 4, "ec773f")
rect(4, 12, 18, 5, 6, "ed9a45")
rect(4, 14, 20, 6, 3, "ffce5c")
rect(4, 9, 14, 2, 2, "f9ba62")
rect(4, 20, 15, 1, 2, "fa894e")
rect(4, 3, 27, 26, 3, "302c33")

-- Anvil and quench tub.
rect(5, 11, 22, 10, 8, "533c33")
rect(5, 9, 20, 14, 5, "44313a")
rect(5, 5, 14, 23, 4, "535767")
rect(5, 9, 13, 15, 2, "8d96a1")
rect(5, 12, 17, 8, 5, "414554")
rect(6, 5, 14, 22, 15, "613f32")
rect(6, 8, 17, 16, 10, "a37751")
rect(6, 6, 15, 20, 5, "5e8693")
rect(6, 9, 16, 9, 1, "b4cacc")
rect(6, 9, 21, 16, 2, "856a64")
rect(6, 9, 25, 16, 2, "856a64")

-- Scrap heap.
rect(7, 5, 25, 22, 4, "423c3d")
rect(7, 8, 20, 9, 6, "8a7670")
rect(7, 12, 21, 4, 2, "b2a49b")
rect(7, 18, 17, 6, 10, "646c77")
rect(7, 17, 18, 8, 2, "a09e9e")
rect(7, 20, 23, 5, 3, "554d51")

-- Splitter, covered in dust before restoration.
for frame = 8, 9 do
  rect(frame, 5, 16, 22, 12, frame == 8 and "716657" or "654c38")
  rect(frame, 7, 13, 18, 7, frame == 8 and "9a8c7a" or "567966")
  rect(frame, 10, 14, 12, 4, frame == 8 and "625a5b" or "89a08b")
  rect(frame, 18, 19, 9, 2, "3d393c")
  rect(frame, 24, 20, 4, 4, frame == 8 and "8d7264" or "d39b58")
  rect(frame, 7, 26, 3, 4, "4f3a30")
  rect(frame, 21, 26, 3, 4, "4f3a30")
end
rect(8, 4, 16, 6, 1, "b9a88e")
rect(8, 17, 12, 11, 1, "b9a88e")

-- Wooden sign, order board, stacked bamboo, finished baskets and tarps.
for frame = 10, 11 do
  rect(frame, 8, 14, 3, 16, "5e4535")
  rect(frame, 21, 14, 3, 16, "5e4535")
  rect(frame, 3, 11, 26, 11, "a27850")
  rect(frame, 4, 12, 24, 1, "d3a770")
  if frame == 11 then
    rect(frame, 10, 12, 12, 9, "e3cf9a")
    rect(frame, 12, 15, 8, 1, "984f3d")
    rect(frame, 12, 18, 7, 1, "aa825a")
  else
    rect(frame, 7, 16, 18, 2, "e5bd82")
  end
end
for y = 17, 26, 4 do
  rect(12, 4, y, 23, 4, "607745")
  rect(12, 6, y, 18, 1, "a6a863")
  rect(12, 24, y + 1, 3, 2, "d2b978")
end
rect(12, 11, 17, 2, 12, "816049")
for y = 14, 25, 5 do
  rect(13, 6, y, 21, 2, "5d4435")
  rect(13, 8, y + 2, 17, 4, "bd8950")
  rect(13, 11, y + 2, 1, 3, "795438")
  rect(13, 19, y + 2, 1, 3, "795438")
end
for frame = 14, 15 do
  rect(frame, 3, 25, 26, 5, "374653")
  rect(frame, 5, 19, 22, 8, "5b7787")
  rect(frame, 7, 15, 18, 6, "7795a6")
  rect(frame, 8, 16, 16, 2, "a4b7b8")
  rect(frame, 9, 21, 2, 6, "456273")
  rect(frame, 22, 20, 2, 7, "456273")
  rect(frame, 4, 28, 2, 3, "a88563")
  rect(frame, 26, 27, 2, 3, "a88563")
  if frame == 15 then rect(frame, 10, 16, 12, 2, "a6c0ac") end
end

-- Dust and tools left on the floor.
rect(16, 6, 26, 20, 2, "72604d")
rect(16, 9, 24, 3, 3, "ae9c7b")
rect(16, 19, 23, 3, 3, "ae9c7b")
rect(16, 22, 27, 3, 2, "564b46")
rect(17, 7, 26, 20, 3, "544237")
rect(17, 8, 23, 12, 3, "c6a974")
rect(17, 13, 21, 12, 2, "94734f")

for frame = 18, 19 do
  local forge = frame == 18
  rect(frame, 0, 0, 32, 32, forge and "55484c" or "654837")
  rect(frame, 0, 0, 32, 4, forge and "734d3d" or "844e38")
  for y = 6, 28, 7 do
    rect(frame, 0, y, 32, 1, forge and "403841" or "4c392d")
    rect(frame, 0, y + 1, 32, 1, forge and "6f5d60" or "8d664a")
    if forge then rect(frame, (y * 3) % 28, y + 2, 1, 5, "403841") end
  end
  rect(frame, 0, 29, 32, 3, forge and "36313a" or "4d362d")
end

local source = app.params.source_dir or "art/32"
local output = app.params.out_dir or "assets/art/32"
sprite:saveAs(app.fs.joinPath(source, "bamboo_works.aseprite"))
sprite:saveAs(app.fs.joinPath(output, "bamboo_works.png"))
