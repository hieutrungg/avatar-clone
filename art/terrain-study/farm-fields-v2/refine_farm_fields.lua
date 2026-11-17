local output = assert(app.params.output_dir)
local project = assert(app.params.project_dir)
local source = assert(app.open(project .. "/art/terrain-study/farm-fields-v1/farm_fields_study.aseprite"))
local atlas = Sprite(256, 288, ColorMode.RGB)
local layers = {}
for index, name in ipairs({"base", "detail", "highlights"}) do
    local layer = index == 1 and atlas.layers[1] or atlas:newLayer()
    layer.name = name
    local image = Image(256, 288, ColorMode.RGB)
    local cel = assert(source.layers[index]:cel(source.frames[1]))
    image:drawImage(cel.image, cel.position)
    atlas:newCel(layer, atlas.frames[1], image, Point(0, 0))
    layers[index] = layer:cel(atlas.frames[1]).image
end
source:close()

local function color(hex)
    local value = tonumber(hex, 16)
    return app.pixelColor.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, 255)
end

local grass = color("5C8036")
local grass_shade = color("537536")
local dirt = color("945C3C")
local water = color("365D60")
local water_ripple = color("4C7374")
local water_light = color("628A86")
local water_dark = color("33565C")
local shore_grass = color("496940")
local shore_lower = color("706042")
local shore_wet = color("565843")
local shore_shallow = color("416967")
local clear = app.pixelColor.rgba(0, 0, 0, 0)

local function put(layer, c, r, x, y, pixel)
    if x >= 0 and x < 32 and y >= 0 and y < 32 then
        layers[layer]:drawPixel(c * 32 + x, r * 32 + y, pixel)
    end
end

local function texture(c, r, painter)
    for y = 0, 31 do
        for x = 0, 31 do
            local base, detail, highlight = painter(x, y)
            put(1, c, r, x, y, base)
            put(2, c, r, x, y, detail or clear)
            put(3, c, r, x, y, highlight or clear)
        end
    end
end

local function corner(u, v, inset, radius)
    local a, b = inset + radius - u, inset + radius - v
    if a > 0 and b > 0 then
        return radius - math.sqrt(a * a + b * b)
    end
    return math.min(u, v) - inset
end

local function edges(inset)
    return {
        function(x, y) return y - inset end,
        function(x, y) return 31 - y - inset end,
        function(x, y) return x - inset end,
        function(x, y) return 31 - x - inset end,
    }
end

local function corners(inset, radius, inside)
    local function measure(u, v)
        if inside then
            return -corner(31 - u, 31 - v, 31 - inset, math.min(6, radius))
        end
        return corner(u, v, inset, radius)
    end
    return {
        function(x, y) return measure(x, y) end,
        function(x, y) return measure(31 - x, y) end,
        function(x, y) return measure(x, 31 - y) end,
        function(x, y) return measure(31 - x, 31 - y) end,
    }
end

local function is_interior(x, y)
    return x >= 2 and x <= 29 and y >= 2 and y <= 29
end

local dirt_shade, dirt_light = color("8C593D"), color("AA724E")
local function path_tile(c, r, distance)
    texture(c, r, function(x, y)
        local d = distance(x, y)
        local grain = (x * 17 + y * 23 + x * y * 11) % 59
        if d < -1 then return grass end
        if d < 1 then
            return grass_shade, is_interior(x, y) and grain < 9 and color("648946") or nil
        end
        return dirt, is_interior(x, y) and (grain < 3 and dirt_light or (grain < 9 and dirt_shade or nil)) or nil
    end)
end

local function brick(c, x, y, length, rise)
    local shadow, clay, light = color("744938"), color("AA533D"), color("C87553")
    for offset = 0, length do
        local top = y - math.floor(offset * rise / length)
        for dy = 0, 4 do
            if (offset > 0 and offset < length) or (dy >= 1 and dy <= 3) then
                put(2, c, 1, x + offset, top + dy + 1, shadow)
                put(2, c, 1, x + offset, top + dy, dy == 0 and light or clay)
            end
        end
    end
end

for c = 0, 7 do path_tile(c, 1, function() return 8 end) end
brick(2, 9, 16, 9, 2)
brick(3, 8, 10, 8, -2)
brick(3, 18, 21, 6, 1)
brick(4, 8, 9, 10, 1)
brick(4, 13, 19, 10, 2)
for n = 1, 10 do
    local x, y = 3 + n * 7 % 25, 3 + n * 11 % 25
    put(2, 5, 1, x, y, dirt_shade)
    put(3, 5, 1, x, y - 1, color("BF9C7A"))
    put(2, 6, 1, x, y, dirt_shade)
end
for y = 3, 28 do
    put(2, 7, 1, 10 + math.floor(math.sin(y / 6)), y, dirt_shade)
end

for index, distance in ipairs(edges(7)) do path_tile(index - 1, 2, distance) end
for index, distance in ipairs(corners(7, 10, false)) do path_tile(index + 3, 2, distance) end
for index, distance in ipairs(corners(7, 10, true)) do path_tile(index - 1, 3, distance) end
path_tile(4, 3, function(x, y) return math.min(y - 8, 23 - y) end)
path_tile(5, 3, function(x, y) return math.min(x - 8, 23 - x) end)
path_tile(6, 3, function(x, y) return math.max(x - 7, math.min(y - 8, 23 - y)) end)
path_tile(7, 3, function(x, y)
    local dx, dy = math.max(0, 12 - x), y - 15.5
    return 7.5 - math.sqrt(dx * dx + dy * dy)
end)

local function draw_sedge(c, r, x, y, flip)
    local dark, middle, light = color("3F573B"), color("658747"), color("9CB468")
    for offset = -3, 3 do put(2, c, r, x + offset, y + 1, dark) end
    for offset = 0, 7 do
        put(2, c, r, x - flip * math.floor(offset / 3), y - offset, offset > 4 and light or middle)
    end
    for offset = 0, 5 do
        put(2, c, r, x + flip * math.floor(offset / 2), y - offset, offset > 2 and light or middle)
        put(2, c, r, x - flip * (1 + math.floor(offset / 2)), y - offset + 1, middle)
    end
    put(3, c, r, x - 2 * flip, y - 7, color("B4B478"))
end

local function bank_tile(c, r, distance)
    texture(c, r, function(x, y)
        local d = distance(x, y)
        local reach = math.min(x, 31 - x, y, 31 - y, 4) / 4
        d = d + reach * (math.sin((x + y) * 0.22 + c) * 1.4 + math.sin((x - y) * 0.41) * 0.5)
        local grain = (x * 19 + y * 13 + x * y * 7) % 47
        if d < -1 then return grass end
        if d < 1 then return shore_grass end
        if d < 3 then return shore_lower end
        if d < 5 then return shore_wet end
        if d < 7 then
            return shore_shallow, is_interior(x, y) and grain < 10 and water_ripple or nil
        end
        return water
    end)
end

local bank_edges = edges(8)
for index, distance in ipairs(bank_edges) do bank_tile(index - 1, 7, distance) end
for index, distance in ipairs(corners(8, 11, false)) do bank_tile(index + 3, 7, distance) end
for index, distance in ipairs(corners(8, 11, true)) do bank_tile(index - 1, 8, distance) end
for index, direction in ipairs({1, 3, 2, 4}) do bank_tile(index + 3, 8, bank_edges[direction]) end
draw_sedge(4, 8, 8, 10, 1)
draw_sedge(4, 8, 22, 12, -1)
draw_sedge(6, 8, 11, 22, 1)
draw_sedge(6, 8, 24, 26, -1)
draw_sedge(7, 8, 24, 13, 1)
draw_sedge(7, 8, 27, 26, -1)
for y = 13, 19 do
    for x = 6, 17 do
        if (x > 7 and x < 16) or (y > 14 and y < 18) then
            local pixel = y == 13 and color("A89E83") or (y == 19 and color("59605A") or color("8B8470"))
            put(2, 5, 8, x, y, pixel)
        end
    end
end

for c = 0, 7 do
    texture(c, 6, function(x, y) return water end)
    for wave = 0, (c == 0 and 1 or 3) do
        local start = 3 + (c * 11 + wave * 13) % 20
        local y = 5 + (c * 7 + wave * 9) % 23
        for offset = 0, 3 + (c + wave) % 4 do
            put(2, c, 6, start + offset, y, water_ripple)
            if offset > 1 then put(2, c, 6, start + offset, y + 1, water_dark) end
            if wave == 1 and offset == 2 then put(3, c, 6, start + offset, y, water_light) end
        end
    end
    if c == 3 or c == 4 then
        local lee, leaf, veining = color("3C6557"), color("5A8060"), color("73946A")
        for y = 11, 19 do
            for x = 10, 23 do
                local dx, dy = (x - 16) / 7, (y - 15) / 4
                if dx * dx + dy * dy < 1 and not (x >= 16 and y >= 15 and x - 16 > (y - 15) * 3) then
                    put(2, c, 6, x, y, y < 17 and leaf or lee)
                end
            end
        end
        put(3, c, 6, 14, 14, veining)
        put(3, c, 6, 15, 14, veining)
    end
end

local dry = {color("82563E"), color("95674A"), color("A17250"), color("AD7C56")}
local wet = {color("624638"), color("735342"), color("805C49"), color("906B51")}
local wet_glint = color("869187")
for r = 4, 5 do
    local palette = r == 4 and dry or wet
    for c = 0, 7 do
        texture(c, r, function(x, y)
            local inset = math.min(y - 3, 28 - y)
            if c == 4 or c == 6 then inset = math.min(inset, corner(x, math.min(y, 31 - y), 3, 5)) end
            if c == 5 or c == 7 then inset = math.min(inset, corner(31 - x, math.min(y, 31 - y), 3, 5)) end
            if inset < 0 then return grass end
            local shift = is_interior(x, y) and (math.floor(x / 9) + c) % 2 or 0
            local band = (y + shift) % 7
            local grain = (x * 13 + y * 17 + x * y * 5 + c * 7) % 61
            local tone = palette[band < 2 and 1 or (band < 4 and 3 or 2)]
            if inset < 2 then tone = palette[1] end
            if is_interior(x, y) and inset > 3 and band == 2 and grain < 19 then
                return tone, palette[4]
            end
            if r == 5 and is_interior(x, y) and inset > 6 and band == 1 and grain < 5 then
                return tone, nil, wet_glint
            end
            return tone
        end)
    end
end

atlas:saveCopyAs(output .. "/farm_fields_study.aseprite")
atlas:saveCopyAs(output .. "/farm_fields_study.png")

local flat = Image(256, 288, ColorMode.RGB)
for _, layer in ipairs(layers) do flat:drawImage(layer, Point(0, 0)) end
local map = Image(512, 320, ColorMode.RGB)

local function draw_tile(x, y, c, r)
    for dy = 0, 31 do
        for dx = 0, 31 do
            map:drawPixel(x * 32 + dx, y * 32 + dy, flat:getPixel(c * 32 + dx, r * 32 + dy))
        end
    end
end

for y = 0, 9 do
    for x = 0, 15 do
        local variant = (x * 5 + y * 7 + x * y * 3) % 12
        draw_tile(x, y, variant < 7 and 0 or variant - 4, 0)
    end
    draw_tile(6, y, y == 6 and 6 or 2, y == 6 and 3 or 2)
    local bricks = ({0, 2, 0, 3, 0, 2, 0, 5, 0, 7})[y + 1]
    draw_tile(7, y, bricks, 1)
    draw_tile(8, y, 3, 2)
end
draw_tile(2, 6, 7, 3)
for x = 3, 5 do draw_tile(x, 6, 4, 3) end

for y = 1, 4 do
    local row = y < 3 and 4 or 5
    for x = 1, 4 do draw_tile(x, y, ({4, 0, 1, 5})[x], row) end
end

for x = 10, 13 do
    draw_tile(x, 1, x % 2 == 0 and 4 or 0, x % 2 == 0 and 8 or 7)
end
draw_tile(10, 7, 1, 7)
draw_tile(11, 7, 6, 8)
draw_tile(9, 1, 4, 7)
draw_tile(14, 1, 5, 7)
draw_tile(9, 7, 6, 7)
draw_tile(12, 7, 7, 7)
for y = 2, 4 do
    draw_tile(9, y, y == 4 and 5 or 2, y == 4 and 8 or 7)
    draw_tile(14, y, y % 2 == 0 and 7 or 3, y % 2 == 0 and 8 or 7)
    for x = 10, 13 do draw_tile(x, y, (x * 3 + y * 5) % 8, 6) end
end
draw_tile(9, 5, 2, 7)
draw_tile(9, 6, 2, 7)
draw_tile(10, 5, 2, 6)
draw_tile(11, 5, 3, 6)
draw_tile(10, 6, 0, 6)
draw_tile(11, 6, 1, 6)
draw_tile(12, 5, 3, 8)
draw_tile(12, 6, 7, 8)
draw_tile(13, 5, 6, 8)
draw_tile(14, 5, 7, 7)

local function overlay_frame(file, frame_x, frame_y, w, h, x, y)
    local sprite = assert(app.open(project .. "/assets/art/32/" .. file))
    local image = Image(sprite.width, sprite.height, ColorMode.RGB)
    image:drawSprite(sprite, 1, Point(0, 0))
    for oy = 0, h - 1 do
        for ox = 0, w - 1 do
            local pixel = image:getPixel(frame_x + ox, frame_y + oy)
            if app.pixelColor.rgbaA(pixel) == 255 then map:drawPixel(x + ox, y + oy, pixel) end
        end
    end
    sprite:close()
end

local function overlay_sprite(sprite, x, y)
    local image = Image(sprite.width, sprite.height, ColorMode.RGB)
    image:drawSprite(sprite, 1, Point(0, 0))
    map:drawImage(image, Point(x, y), 255, BlendMode.NORMAL)
end

local house = assert(app.open(project .. "/art/terrain-study/farm-fields-v2/farmhouse.png"))
overlay_sprite(house, 22, 225)
house:close()

local tree = dofile(project .. "/art/terrain-study/farm-fields-v2/fruit_tree.lua")
tree:saveCopyAs(output .. "/fruit_tree.aseprite")
tree:saveCopyAs(output .. "/fruit_tree.png")
overlay_sprite(tree, 413, 228)
tree:close()
overlay_frame("peanut.png", 32, 0, 32, 32, 43, 122)
overlay_frame("peanut.png", 64, 0, 32, 32, 94, 122)
overlay_frame("pumpkin.png", 64, 0, 32, 32, 64, 88)
overlay_frame("player.png", 0, 0, 32, 48, 224, 149)

local function save(map_image, name)
    local sprite = Sprite(map_image.width, map_image.height, ColorMode.RGB)
    sprite.cels[1].image:drawImage(map_image, Point(0, 0))
    sprite:saveCopyAs(output .. "/" .. name)
    sprite:close()
end

save(map, "preview_1x.png")
local scaled = Image(1024, 640, ColorMode.RGB)
for y = 0, 319 do
    for x = 0, 511 do
        local pixel = map:getPixel(x, y)
        for dy = 0, 1 do
            for dx = 0, 1 do scaled:drawPixel(x * 2 + dx, y * 2 + dy, pixel) end
        end
    end
end
save(scaled, "preview_2x.png")
