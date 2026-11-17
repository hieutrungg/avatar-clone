local output = assert(app.params.output_dir)
local width, height = 32, 48
local palette = {}
for key, hex in pairs({
    k = "292725", n = "48403C", p = "4A5151", g = "61706A", b = "74503A", c = "A5734C",
    a = "344852", d = "3E6170", e = "507F87", f = "73A1A0",
    r = "9D523C", o = "CD7C4C", t = "E39D66", s = "AE6C4B", j = "F1B67F", i = "FFD29C",
    m = "826039", u = "AC814A", v = "CE9F5B", w = "E6BA74", x = "F7D98E",
}) do
    local number = tonumber(hex, 16)
    palette[key] = app.pixelColor.rgba(math.floor(number / 65536), math.floor(number / 256) % 256, number % 256, 255)
end

local function stamp(image, x, y, rows, mirror)
    for row, line in ipairs(rows) do
        for col = 1, #line do
            local color = palette[line:sub(col, col)]
            if color then
                local px = x + col - 1
                image:drawPixel(mirror and width - 1 - px or px, y + row - 1, color)
            end
        end
    end
end

local hat = {
    "..........kkk..........",
    ".........kvwxk.........",
    "........kvwxxwk........",
    ".......kuwxxwvvk.......",
    "......kuvxwwvvvuk......",
    ".....kuvwxxxwwvuvk.....",
    "....kmvwwxwwwvvvuuk....",
    "...kmuwxwwwvvvwvvumk...",
    "..kmvvwwxxwwvvvvuummk..",
    ".kmuvwwwwvvwwwvvuuummk.",
    "kmuvwxxxwwwvvvwwvvuummk",
    "kmmuuuuuvvvvvvuuuuuummk",
    ".kkkkmmuuuuuuuummkkkk..",
    ".....kkkkkkkkkkk.......",
}

local profile_hat = {
    "............kk.........",
    "...........kvwk........",
    "..........kvxxwk.......",
    ".........kvxwwvuk......",
    "........kvwxwwvuuk.....",
    "......kkvwxwwvvuvuk....",
    ".....kmuwxwwwvvvvumk...",
    "....kmvwxwwvvvwwvuumk..",
    "..kkmuwxwwxwwvvvvuuumk.",
    ".kmuvwwwwwwvvvvvuuuummk",
    "kmuvvwwxxxwwvvwwwvuummk",
    "kmmuuuuuvvvvvvuuuuuummk",
    ".kkkkkkmmuuuuuummkkkk..",
    ".......kkkkkkkkk.......",
}

local front_face = {
    ".kkkkkkkkkkk.", "kkssstsstsskk", "ksjjjjjjjtssk", "ksjkjjjkjttsk",
    "ksjkjjtkittsk", "ksjjijiijttsk", ".ksjjtojtssk.", "..ksttttssk..",
    "...ksssssk...", "....kttsk....",
}

local back_head = {
    ".kkkkkkkkkkk.", "kknnnnnnnnkkk", "ksknnnnnnknsk", "ksknnknnkkssk",
    ".kskkkkkksssk", "..kttssttssk.", "...kttttssk..", "....ksssk....",
}

local profile_face = {
    "..kkkkkkkkk.", ".ksstssnnnkk", ".kjjjttknnnk", ".kjkjjtknnkk",
    "kjjkjjttknsk", "kjijiittstsk", ".kjtjtttsssk", "..kstttssk..",
    "...kssttsk..", "....ksstk...",
}

local front_shirt = {
    "..kkkakkakkk..", ".kfeekstkeedk.", "kfededkkddeeak", "kfeededkddedad",
    "kfeeeddkddddak", "kfeeedtkddebak", "keeeeddkdddack", "keeededkddeaak",
    "keeeeeoddddaak", "kedeedrddddaak", "kdddedrdadaak.", ".kaaddkdaaaak.",
    "..kkkkkkkkkk..",
}

local back_shirt = {
    "..kkkakkakkk..", ".kfeeeaadeeak.", "kfeeeeeeeedaak", "kfeeeeedddaak.",
    "kfeeeedddaak..", "keeeeddddaak..", "keeeeddedaak..", "keeeeedddaak..",
    "keeededdeaak..", "kdededdddaak..", "kdddddddaaak..", ".kaaadaaaak...",
    "..kkkkkkkk....",
}

local satchel = {
    "....oo..", "...or...", "..or....", ".or.....", "or......", "r..kkkk.",
    "..kbccbk", "..kcccok", "..kborbk", "..kbccbk", "...kkkk.",
}

local profile_shirt = {
    "...kkakk...", "..kfestak..", ".kfeedddak.", ".kededddaak", "keedddddaak",
    "keedddddaak", "keeddaddabk", "keeddaadabk", "keeddaaaack", "keddadaabck",
    "kdddadaaabk", ".kaaaaaaak.", "..kkkkkkk..",
}

local function arm(image, x, y, dark, mirror)
    local rows = dark and {".kk.", "kaak", "kddk", "kddk", "kadk", "kaak", "kssk", ".kk."}
        or {".kk.", "kdek", "kefk", "keek", "kddk", "kaak", "kjtk", "ktsk", ".kk."}
    stamp(image, x, y, rows, mirror)
end

local function leg(image, x, y, stride, dark, mirror, profile)
    local rise = stride < 0 and 2 or 0
    local dx = profile and stride * 3 or stride
    local cloth = dark and "kppk" or "kgpk"
    local rows = {".kk.", cloth, cloth, cloth, "kppk", "kgpk", "kngk"}
    for index, row in ipairs(rows) do
        if index <= #rows - rise then
            stamp(image, x + math.floor(dx * (index - 1) / 6 + 0.5), y + index - 1, {row}, mirror)
        end
    end
    local shoes = profile and {".kbbk", "kccbk", ".kkkk"} or {"kbbk", "kcck", "kkkk"}
    stamp(image, x + dx - (profile and 1 or 0), y + 7 - rise, shoes, mirror)
end

local function draw_frame(direction, step)
    local profile = direction == 1 or direction == 2
    local back = direction == 3
    local mirror = direction == 2
    local swing = ({0, -1, 1})[step + 1]
    local rise = step == 1 and 1 or 0
    local feet = Image(width, height, ColorMode.RGB)
    local body = Image(width, height, ColorMode.RGB)
    local head = Image(width, height, ColorMode.RGB)

    leg(feet, profile and 17 or 18, 37, -swing, true, mirror, profile)
    leg(feet, profile and 13 or 10, 37, swing, false, mirror, profile)
    if profile then
        stamp(body, 11, 25 - rise, profile_shirt, mirror)
        arm(body, 13 - swing * 2, 27 - rise, false, mirror)
        stamp(head, 9, 16 - rise, profile_face, mirror)
    else
        arm(body, 6, 27 + swing - rise, back, false)
        arm(body, 22, 27 - swing - rise, true, false)
        stamp(body, 9, 25 - rise, back and back_shirt or front_shirt, false)
        if back then stamp(body, 13, 26 - rise, satchel, false) end
        stamp(head, 10, 16 - rise, back and back_head or front_face, false)
    end
    stamp(head, 4, 5 - rise, profile and profile_hat or hat, mirror)
    return {feet, body, head}
end

local atlas = Sprite(width * 3, height * 4, ColorMode.RGB)
local layers = {atlas.layers[1], atlas:newLayer(), atlas:newLayer()}
local names = {"Boots and trousers", "Indigo shirt and bag", "Face and straw hat"}
local frame_layers = {}
for y = 0, 3 do
    frame_layers[y] = {}
    for x = 0, 2 do frame_layers[y][x] = draw_frame(y, x) end
end
for index, layer in ipairs(layers) do
    layer.name = names[index]
    local image = Image(atlas.width, atlas.height, ColorMode.RGB)
    for y = 0, 3 do
        for x = 0, 2 do image:drawImage(frame_layers[y][x][index], Point(x * width, y * height)) end
    end
    atlas:newCel(layer, atlas.frames[1], image, Point(0, 0))
end
atlas:saveCopyAs(output .. "/hoang.aseprite")
atlas:saveCopyAs(output .. "/hoang.png")

local zoom = 4
local preview = Sprite(width * 4 * zoom, height * zoom, ColorMode.RGB)
local backdrop = app.pixelColor.rgba(41, 58, 46, 255)
for index, step in ipairs({0, 1, 0, 2}) do
    local frame = index == 1 and preview.frames[1] or preview:newEmptyFrame()
    frame.duration = ({0.16, 0.19, 0.16, 0.19})[index]
    local strip = Image(width * 4, height, ColorMode.RGB)
    for y = 0, height - 1 do
        for x = 0, strip.width - 1 do strip:drawPixel(x, y, backdrop) end
    end
    for direction = 0, 3 do
        for _, image in ipairs(frame_layers[direction][step]) do
            strip:drawImage(image, Point(direction * width, 0), 255, BlendMode.NORMAL)
        end
    end
    local image = Image(preview.width, preview.height, ColorMode.RGB)
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do image:drawPixel(x, y, strip:getPixel(x // zoom, y // zoom)) end
    end
    preview:newCel(preview.layers[1], frame, image, Point(0, 0))
end
preview:saveCopyAs(output .. "/hoang-walk.gif")
