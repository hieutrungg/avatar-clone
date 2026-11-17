local source = app.params.source_dir or "art/32"
local output = app.params.out_dir or "assets/art/32"

local function painter(image, frame)
  return function(x, y, width, height, hex)
    local value = tonumber(hex, 16)
    local color = app.pixelColor.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, 255)
    for py = y, y + height - 1 do
      for px = x, x + width - 1 do
        image:drawPixel(frame * 32 + px, py, color)
      end
    end
  end
end

local function leaf(rect, x, y, color)
  rect(x + 1, y, 4, 1, "355332")
  rect(x, y + 1, 6, 2, "355332")
  rect(x + 1, y + 1, 4, 1, color)
  rect(x + 2, y + 3, 2, 1, "355332")
end

local function sprout(rect)
  rect(15, 23, 2, 6, "53754a")
  leaf(rect, 10, 22, "8caf52")
  leaf(rect, 16, 21, "94b359")
end

local function save_crop(name, draw)
  local sprite = Sprite(96, 32, ColorMode.RGB)
  local image = sprite.cels[1].image
  sprout(painter(image, 0))
  draw(painter(image, 1), false)
  draw(painter(image, 2), true)
  sprite:saveAs(app.fs.joinPath(source, name .. ".aseprite"))
  sprite:saveAs(app.fs.joinPath(output, name .. ".png"))
end

save_crop("sweet_potato", function(rect, ripe)
  rect(8, 25, 17, 2, "52643a")
  rect(15, 18, 2, 9, "668b47")
  leaf(rect, 9, 20, "8db157")
  leaf(rect, 15, 17, "749f51")
  leaf(rect, 20, 21, "779d52")
  if ripe then
    leaf(rect, 4, 23, "94b862")
    leaf(rect, 23, 24, "94b862")
    rect(8, 27, 8, 3, "855366")
    rect(9, 26, 6, 2, "b57272")
    rect(19, 27, 6, 3, "855366")
    rect(20, 26, 4, 1, "b57272")
  end
end)

save_crop("peanut", function(rect, ripe)
  rect(14, 15, 2, 12, "628a4d")
  rect(10, 21, 12, 2, "627446")
  leaf(rect, 9, 18, "82a950")
  leaf(rect, 16, 18, "91aa56")
  leaf(rect, 13, 14, "a1b95f")
  if ripe then
    leaf(rect, 7, 22, "83a958")
    leaf(rect, 19, 21, "9fb35d")
    rect(9, 24, 2, 2, "f1c75d")
    rect(19, 22, 2, 2, "f1c75d")
    rect(11, 27, 6, 2, "a47b45")
    rect(12, 27, 4, 1, "d9af69")
    rect(18, 27, 5, 2, "b28851")
  end
end)

save_crop("pumpkin", function(rect, ripe)
  rect(5, 24, 22, 2, "537448")
  rect(14, 17, 2, 8, "658945")
  leaf(rect, 7, 19, "869f4e")
  leaf(rect, 13, 16, "92ab56")
  leaf(rect, 21, 21, "83a057")
  if ripe then
    rect(13, 21, 12, 8, "a7603d")
    rect(11, 23, 16, 4, "ca763e")
    rect(14, 22, 9, 6, "ed9e4b")
    rect(16, 23, 4, 4, "f5b158")
    rect(19, 20, 2, 2, "5c7042")
  else
    rect(16, 22, 6, 4, "6a8848")
    rect(18, 22, 3, 2, "99a75a")
  end
end)
