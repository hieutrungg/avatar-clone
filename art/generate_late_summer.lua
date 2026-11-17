local sprite = Sprite(320, 32, ColorMode.RGB)
local image = sprite.cels[1].image

local function fill(frame, x, y, w, h, hex)
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  local color = app.pixelColor.rgba(r, g, b, 255)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      image:drawPixel(frame * 32 + px, py, color)
    end
  end
end

local function leaf(frame, x, y, light)
  fill(frame, x + 2, y, 6, 1, "386653")
  fill(frame, x, y + 1, 10, 4, "386653")
  fill(frame, x + 1, y + 1, 7, 3, light)
  fill(frame, x + 2, y + 5, 6, 1, "386653")
  fill(frame, x + 4, y + 3, 3, 1, "9ba964")
end

for frame = 0, 2 do
  fill(frame, 0, 0, 32, 32, "427b77")
  for n = 0, 8 do
    local x, y = (n * 13 + frame * 3) % 27, (n * 11 + frame * 5) % 31
    fill(frame, x, y, 3 + n % 3, 1, n % 2 == 0 and "59958a" or "346d6d")
  end
  if frame ~= 1 then leaf(frame, 3 + frame * 5, 20, "55875b") end
  if frame == 2 then
    leaf(frame, 19, 8, "668f57")
    leaf(frame, 2, 7, "548750")
    fill(frame, 21, 6, 4, 2, "cb8295")
    fill(frame, 22, 5, 2, 1, "e2a1ae")
  end
end

leaf(3, 8, 23, "63965d")
fill(3, 15, 13, 2, 14, "4f7344")
fill(3, 11, 9, 10, 3, "b38847")
fill(3, 13, 8, 7, 3, "e6bd60")
fill(3, 13, 9, 1, 1, "896037")
fill(3, 16, 10, 1, 1, "896037")
fill(3, 18, 9, 1, 1, "896037")
fill(3, 13, 12, 6, 2, "997743")
leaf(4, 7, 20, "76a76b")
leaf(4, 15, 16, "88b36f")
leaf(4, 10, 24, "6ca468")
fill(4, 11, 21, 6, 1, "abc482")

for row = 0, 11 do
  local margin = math.floor((row - 5) ^ 2 * 0.17) + 2
  fill(5, margin, 17 + row, 32 - 2 * margin, 1, "534b3b")
  if row > 0 and row < 11 then fill(5, margin + 1, 17 + row, 30 - 2 * margin, 1, row % 2 == 0 and "ba844b" or "95663f") end
end
fill(5, 8, 20, 16, 5, "70503a")
fill(5, 10, 22, 13, 1, "cca064")
fill(5, 5, 29, 22, 1, "9acead")

for x = 9, 22, 3 do
  fill(6, x, 21 + x % 4, 2, 7, "99754a")
  fill(6, x, 19 + x % 4, 2, 2, "d5ab59")
end
fill(6, 8, 28, 16, 1, "664833")

for frame = 7, 9 do
  fill(frame, 9, 10, 14, 17, "53453c")
  fill(frame, 10, 11, 12, 15, "d4a66c")
  fill(frame, 11, 9, 10, 4, "edcca0")
  fill(frame, 11, 18, 10, 6, ({"b87d9c", "c8ab67", "d48b45"})[frame - 6])
  fill(frame, 14, 20, 4, 2, "f8e2a4")
end

local source = app.params.source_dir or "art/32"
local output = app.params.out_dir or "assets/art/32"
sprite:saveAs(app.fs.joinPath(source, "late_summer.aseprite"))
sprite:saveAs(app.fs.joinPath(output, "late_summer.png"))
