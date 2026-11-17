-- Native 32 px cucumber and seed bag for Vườn Nhỏ.
local source_dir = app.params["source_dir"] or "art/32"
local out_dir = app.params["out_dir"] or "assets/art/32"

local palette = {
  soil = 0x654528, soil_light = 0x9e6d3d,
  leaf_dark = 0x36572b, leaf = 0x56823c, leaf_light = 0x81a848,
  fruit_dark = 0x26482a, fruit = 0x4e7d37, fruit_light = 0x9cba50,
  bag_dark = 0x796345, bag = 0xc9aa73, bag_light = 0xe9d4a2,
}
for name, rgb in pairs(palette) do
  palette[name] = app.pixelColor.rgba((rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255, 255)
end

local function ellipse(image, cx, cy, rx, ry, color)
  for dy = -ry, ry do
    local width = math.floor(rx * math.sqrt(1 - (dy / ry) ^ 2))
    for dx = -width, width do
      image:drawPixel(cx + dx, cy + dy, color)
    end
  end
end

local function leaf(image, x, y, width, height)
  ellipse(image, x, y, width, height, palette.leaf_dark)
  ellipse(image, x - 1, y - 1, width - 1, height - 1, palette.leaf)
  for n = 0, width - 2 do
    image:drawPixel(x - n, y - math.floor(n / 3), palette.leaf_light)
  end
end

local function cucumber(image, x, y, length, radius)
  for n = 0, length do
    local tip = math.min(n, length - n)
    local width = math.min(radius, 1 + tip)
    local column = x + n
    local center = y - math.floor(n / 3)
    for dy = -width, width do
      local color = palette.fruit
      if dy == width or tip == 0 then
        color = palette.fruit_dark
      elseif dy == -width + 1 and tip > 1 then
        color = palette.fruit_light
      end
      image:drawPixel(column, center + dy, color)
    end
    if n % 4 == 2 then
      image:drawPixel(column, center + 1, palette.leaf_light)
    end
  end
end

local function export(name, width, paint)
  local sprite = Sprite(width, 32, ColorMode.RGB)
  local art = Image(width, 32, ColorMode.RGB)
  paint(art)
  local layer = sprite.layers[1]
  layer.name = "Pixel art"
  sprite:newCel(layer, 1, art, Point(0, 0))
  sprite:saveAs(app.fs.joinPath(source_dir, name .. ".aseprite"))
  sprite:saveCopyAs(app.fs.joinPath(out_dir, name .. ".png"))
  sprite:close()
end

export("cucumbers", 96, function(image)
  for frame = 0, 2 do
    local center = frame * 32 + 16
    ellipse(image, center, 28, 11, 2, palette.soil)
    ellipse(image, center - 1, 27, 8, 1, palette.soil_light)
  end
  image:drawPixel(15, 25, palette.bag_light)
  image:drawPixel(16, 25, palette.bag)

  for y = 18, 27 do
    image:drawPixel(48, y, palette.leaf_dark)
  end
  leaf(image, 44, 20, 5, 3)
  leaf(image, 52, 17, 5, 3)

  leaf(image, 74, 17, 6, 4)
  leaf(image, 81, 12, 7, 5)
  leaf(image, 87, 18, 6, 4)
  cucumber(image, 70, 25, 20, 4)
end)

export("cucumber_seed", 32, function(image)
  ellipse(image, 16, 22, 10, 8, palette.bag_dark)
  ellipse(image, 15, 21, 9, 8, palette.bag)
  ellipse(image, 13, 20, 6, 6, palette.bag_light)
  ellipse(image, 16, 9, 6, 3, palette.bag)
  ellipse(image, 16, 13, 5, 1, palette.bag_dark)
  cucumber(image, 10, 23, 11, 2)
end)
