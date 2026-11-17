local size = 64
local tree = Sprite(size, size, ColorMode.RGB)
local pixels = app.pixelColor

local function color(hex, alpha)
    local value = tonumber(hex, 16)
    return pixels.rgba(math.floor(value / 65536), math.floor(value / 256) % 256, value % 256, alpha or 255)
end

local function layer(name, reuse)
    local item = reuse and tree.layers[1] or tree:newLayer()
    item.name = name
    return tree:newCel(item, tree.frames[1], Image(size, size, ColorMode.RGB), Point(0, 0)).image
end

local function polygon(image, ink, points, mask)
    for y = 0, size - 1 do
        local scan = y + 0.5
        local intersections = {}
        for index, a in ipairs(points) do
            local b = points[index % #points + 1]
            if (a[2] > scan) ~= (b[2] > scan) then
                intersections[#intersections + 1] = a[1] + (scan - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
            end
        end
        table.sort(intersections)
        for i = 1, #intersections, 2 do
            local left = math.ceil(intersections[i] - 0.5)
            local right = math.ceil(intersections[i + 1] - 0.5) - 1
            for x = left, right do
                if not mask or pixels.rgbaA(mask:getPixel(x, y)) > 0 then
                    image:drawPixel(x, y, ink)
                end
            end
        end
    end
end

local shadow = layer("Ground shadow", true)
polygon(shadow, color("1F342A", 57), {
    {11, 58}, {18, 56}, {44, 56}, {53, 58}, {53, 60}, {46, 62}, {20, 62}, {11, 60},
})
polygon(shadow, color("25382B", 105), {
    {20, 58}, {27, 56}, {42, 56}, {46, 58}, {44, 60}, {24, 60},
})

local bark = layer("Trunk and roots")
polygon(bark, color("3B3328"), {
    {18, 32}, {24, 35}, {31, 42}, {34, 42}, {34, 35}, {39, 32}, {40, 41}, {44, 38},
    {48, 38}, {44, 44}, {40, 47}, {39, 51}, {41, 55}, {44, 56}, {45, 58}, {50, 59},
    {46, 60}, {38, 59}, {35, 60}, {33, 59}, {28, 60}, {21, 60}, {23, 57}, {28, 56},
    {31, 52}, {32, 47}, {27, 45}, {22, 41}, {17, 38},
})
polygon(bark, color("77503A"), {
    {19, 35}, {24, 37}, {29, 42}, {34, 44}, {36, 41}, {36, 35}, {38, 36}, {38, 44},
    {42, 42}, {46, 39}, {43, 44}, {38, 47}, {37, 52}, {39, 55}, {43, 57}, {45, 59},
    {38, 57}, {35, 59}, {33, 57}, {29, 59}, {23, 59}, {26, 57}, {30, 57}, {33, 51},
    {34, 46}, {28, 44}, {24, 41}, {20, 39},
})
polygon(bark, color("A8734A"), {
    {21, 37}, {24, 38}, {28, 42}, {33, 44}, {35, 43}, {36, 37}, {38, 37}, {37, 45},
    {40, 45}, {36, 48}, {36, 52}, {34, 55}, {35, 58}, {33, 56}, {28, 58}, {25, 58},
    {30, 56}, {33, 51}, {34, 46}, {30, 45}, {26, 43},
})
polygon(bark, color("C4905C"), {
    {30, 45}, {34, 46}, {35, 48}, {34, 51}, {34, 53}, {31, 55}, {33, 51}, {33, 48},
})
bark:drawPixel(26, 57, color("C4905C"))
bark:drawPixel(36, 52, color("583E31"))
bark:drawPixel(36, 53, color("583E31"))
bark:drawPixel(37, 54, color("583E31"))

local canopy = layer("Canopy")
polygon(canopy, color("243B2C"), {
    {4, 27}, {6, 24}, {8, 24}, {8, 19}, {11, 16}, {13, 15}, {17, 15}, {17, 12},
    {20, 9}, {24, 9}, {24, 7}, {28, 5}, {34, 5}, {37, 7}, {39, 10}, {43, 10}, {47, 12},
    {47, 13}, {51, 13}, {55, 16}, {56, 20}, {58, 20}, {61, 23}, {61, 28}, {62, 30},
    {61, 34}, {58, 36}, {56, 36}, {54, 40}, {49, 42}, {45, 41}, {42, 43}, {37, 43},
    {34, 41}, {31, 42}, {27, 42}, {24, 40}, {19, 42}, {15, 41}, {12, 38}, {9, 38},
    {6, 36}, {6, 33}, {4, 32},
})

local leaves = Image(size, size, ColorMode.RGB)
local function covered(x, y)
    return pixels.rgbaA(canopy:getPixel(x, y)) > 0
end

for y = 1, size - 2 do
    for x = 1, size - 2 do
        if covered(x, y) and covered(x - 1, y) and covered(x + 1, y)
            and covered(x, y - 1) and covered(x, y + 1) then
            leaves:drawPixel(x, y, color("345539"))
        end
    end
end
canopy:drawImage(leaves, Point(0, 0))

-- Paint overlapping foliage clusters from the rear toward the sunlit crown.
local function foliage(hex, points)
    polygon(canopy, color(hex), points, leaves)
end

foliage("426A43", {
    {32, 15}, {41, 10}, {47, 14}, {52, 13}, {57, 17}, {57, 21}, {60, 22}, {62, 27},
    {59, 31}, {54, 31}, {53, 35}, {49, 37}, {45, 36}, {44, 34}, {39, 34}, {35, 31},
})
foliage("567D49", {
    {38, 14}, {43, 12}, {47, 14}, {52, 14}, {55, 17}, {56, 21}, {59, 22}, {60, 26},
    {56, 28}, {52, 27}, {49, 30}, {45, 29}, {45, 26}, {41, 26}, {38, 23},
})
foliage("739451", {
    {45, 15}, {51, 15}, {54, 17}, {55, 21}, {52, 20}, {50, 21}, {47, 21}, {47, 19}, {44, 18},
})
foliage("486E41", {
    {5, 26}, {9, 24}, {9, 20}, {12, 16}, {17, 15}, {22, 17}, {25, 23}, {28, 28},
    {25, 34}, {21, 35}, {20, 38}, {16, 38}, {12, 34}, {8, 34}, {5, 31},
})
foliage("668A49", {
    {7, 25}, {11, 23}, {11, 19}, {15, 16}, {18, 16}, {23, 19}, {24, 23}, {21, 27},
    {17, 27}, {17, 29}, {12, 31}, {8, 30}, {6, 28},
})
foliage("88A558", {
    {10, 25}, {12, 23}, {12, 20}, {15, 18}, {18, 18}, {18, 20}, {20, 21}, {16, 21},
    {15, 24}, {13, 24}, {12, 26}, {9, 27},
})
foliage("456C42", {
    {19, 25}, {26, 22}, {32, 24}, {35, 25}, {40, 24}, {44, 27}, {46, 31}, {42, 35},
    {37, 35}, {36, 39}, {31, 40}, {27, 38}, {27, 35}, {24, 36}, {21, 33},
})
foliage("5A8047", {
    {22, 27}, {26, 25}, {30, 25}, {32, 27}, {36, 26}, {40, 27}, {42, 29}, {41, 32},
    {37, 32}, {35, 34}, {31, 34}, {29, 32}, {25, 33}, {22, 30},
})
foliage("567D44", {
    {18, 14}, {21, 10}, {25, 9}, {28, 6}, {34, 6}, {38, 9}, {39, 12}, {43, 12},
    {46, 15}, {46, 19}, {43, 21}, {40, 20}, {38, 23}, {33, 24}, {28, 21}, {24, 22}, {20, 19},
})
foliage("71954C", {
    {20, 14}, {24, 11}, {27, 11}, {29, 7}, {33, 7}, {36, 9}, {37, 12}, {41, 13},
    {43, 16}, {40, 18}, {37, 17}, {34, 20}, {31, 19}, {29, 20}, {25, 17}, {21, 17},
})
foliage("96AD57", {
    {27, 12}, {29, 9}, {33, 8}, {35, 10}, {35, 12}, {32, 11}, {31, 14}, {27, 14}, {24, 16}, {22, 15},
})
foliage("82A251", {
    {29, 28}, {32, 27}, {35, 28}, {38, 27}, {39, 29}, {36, 30}, {34, 29}, {32, 31}, {29, 31},
})
foliage("759851", {{54, 23}, {57, 23}, {59, 25}, {57, 26}, {54, 25}, {52, 26}, {52, 24}})

local apples = layer("Red fruit")
local fruit_shadow = color("883E34")
local fruit_red = color("C9523D")
local fruit_light = color("F08B57")
for _, fruit in ipairs({{13, 25}, {22, 16}, {30, 20}, {39, 15}, {52, 21}, {19, 34}, {33, 34}, {48, 32}, {56, 29}}) do
    local x, y = fruit[1], fruit[2]
    apples:drawPixel(x + 1, y - 1, color("384B32"))
    apples:drawPixel(x, y, fruit_light)
    apples:drawPixel(x + 1, y, fruit_red)
    apples:drawPixel(x, y + 1, fruit_red)
    apples:drawPixel(x + 1, y + 1, fruit_shadow)
    apples:drawPixel(x + 2, y + 1, fruit_shadow)
end

return tree
