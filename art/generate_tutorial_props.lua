-- Nine 32 px frames for the day 5–9 activities, in the order used by garden.gd.
local sprite = Sprite(288, 32, ColorMode.RGB)
local image = sprite.cels[1].image
local function block(frame, x, y, width, height, hex)
  local color = app.pixelColor.rgba(tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
  for row = y, y + height - 1 do
    for col = x, x + width - 1 do image:drawPixel(frame * 32 + col, row, color) end
  end
end

local shadow, timber, grain, straw = "483328", "976344", "c58b58", "e9bc6b"
local function coop(frame, open, egg)
  block(frame, 2, 26, 28, 3, "534731")
  block(frame, 5, 11, 22, 15, shadow)
  block(frame, 7, 12, 18, 12, timber)
  for x = 9, 23, 4 do block(frame, x, 13, 1, 11, grain) end
  for y = 0, 6 do block(frame, 9 - y, 5 + y, 14 + y * 2, 1, y % 2 == 0 and "a84e36" or "803c31") end
  block(frame, 3, 12, 26, 2, shadow)
  block(frame, 13, 15, 9, 11, shadow)
  if not open then
    block(frame, 14, 16, 7, 9, grain)
    block(frame, 19, 20, 1, 2, straw)
  else
    block(frame, 9, 20, 8, 5, "f2d5a1")
    block(frame, 13, 17, 4, 5, "f7e9c9")
    block(frame, 14, 16, 2, 1, "ae483c")
    block(frame, 17, 19, 2, 1, straw)
    block(frame, 15, 18, 1, 1, shadow)
    block(frame, 11, 25, 4, 1, grain)
  end
  if egg then
    block(frame, 21, 22, 3, 4, "e3bd8a")
    block(frame, 22, 22, 2, 3, "fff1d4")
  end
end

coop(0, false, false)
for frame = 1, 2 do
  block(frame, 4, 24, 24, 3, shadow)
  block(frame, 5, 17, 22, 7, timber)
  block(frame, 3, 16, 26, 2, grain)
  block(frame, 7, 18, 18, 3, frame == 2 and straw or shadow)
  block(frame, 6, 24, 3, 3, grain)
  block(frame, 23, 24, 3, 3, grain)
end

block(3, 4, 16, 24, 14, shadow)
block(3, 5, 16, 22, 7, "947060")
block(3, 7, 23, 18, 5, "b58a6a")
block(3, 13, 23, 6, 5, "993d32")
block(3, 15, 24, 2, 3, straw)
block(3, 10, 11, 13, 7, "505b5d")
block(3, 9, 11, 15, 2, "7a8580")
block(3, 14, 9, 5, 2, shadow)

block(4, 3, 16, 26, 10, shadow)
block(4, 4, 17, 24, 3, grain)
block(4, 4, 22, 24, 2, timber)
for x = 4, 25, 21 do
  block(4, x, 13, 3, 16, timber)
  block(4, x, 13, 1, 13, grain)
end

block(5, 10, 2, 13, 28, "66553c")
block(5, 12, 1, 9, 30, "3c554c")
block(5, 14, 1, 5, 30, "557d77")
for y = 5, 29, 8 do block(5, 15, y, 4, 1, "7d9c8a") end

block(6, 14, 13, 4, 15, shadow)
block(6, 7, 7, 18, 12, timber)
block(6, 7, 7, 18, 2, grain)
for column = 10, 22, 4 do block(6, column, 10, 1, 6, straw) end
block(6, 10, 12, 13, 1, straw)
block(6, 10, 15, 13, 1, straw)

coop(7, true, false)
coop(8, true, true)

local source_dir = app.params.source_dir or "./art/32"
local out_dir = app.params.out_dir or "./assets/art/32"
sprite:saveAs(app.fs.joinPath(source_dir, "tutorial_props.aseprite"))
sprite:saveCopyAs(app.fs.joinPath(out_dir, "tutorial_props.png"))
sprite:close()
