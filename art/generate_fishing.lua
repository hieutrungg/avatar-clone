-- art/generate_fishing.lua
-- Standalone Aseprite 1.3.15.5-dev Lua batch generator for Vườn Nhỏ
-- Generates:
--   1) fish.aseprite & fish.png (48x16): Cá Rô, Cá Trê (whiskers), Cá Chép (carp)
--   2) fishing_spot.aseprite & fishing_spot.png (16x16): Wooden tackle crate & diagonal rod with red/cream float

local source_dir = (app.params and app.params["source_dir"]) or "art"
local out_dir = (app.params and app.params["out_dir"]) or "assets/art"

local function joinPath(dir, filename)
    if app.fs and app.fs.joinPath then
        return app.fs.joinPath(dir, filename)
    end
    local sep = "/"
    if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
        return dir .. filename
    end
    return dir .. sep .. filename
end

local function ensureDir(dirPath)
    if not (app.fs and app.fs.makeDirectory) then return end
    local accumulated = ""
    for part in dirPath:gmatch("[^/\\]+") do
        if accumulated == "" then
            accumulated = part
        else
            accumulated = accumulated .. "/" .. part
        end
        pcall(function() app.fs.makeDirectory(accumulated) end)
    end
end

local function hexToColor(hex)
    local h = hex:gsub("#", "")
    local r = tonumber(h:sub(1, 2), 16)
    local g = tonumber(h:sub(3, 4), 16)
    local b = tonumber(h:sub(5, 6), 16)
    return Color{ r = r, g = g, b = b, a = 255 }
end

local PALETTE_HEXES = {
    "#15100c", -- 1: Darkest outline / shadow
    "#362013", -- 2: Deep brown / iron band
    "#5e3519", -- 3: Dark wood / carp shadow
    "#945a2b", -- 4: Medium wood plank
    "#c68a4c", -- 5: Amber wood / carp highlight
    "#eed19c", -- 6: Cream / belly / bamboo / float lower
    "#1c381c", -- 7: Dark green perch outline
    "#386e2d", -- 8: Mid green perch body
    "#6ca33b", -- 9: Bright green perch scales
    "#a8d45d", -- A: Lime green perch belly
    "#782017", -- B: Deep red float shadow
    "#bd3826", -- C: Bright red float / carp red
    "#ea6532", -- D: Bright orange carp scales
    "#22445e", -- E: Dark blue-grey catfish outline
    "#3e78a6", -- F: Mid blue-grey catfish body
    "#809c91", -- G: Pale blue-grey catfish belly / whiskers / line
}

local COLOR_MAP = {
    ["1"] = hexToColor("#15100c"),
    ["2"] = hexToColor("#362013"),
    ["3"] = hexToColor("#5e3519"),
    ["4"] = hexToColor("#945a2b"),
    ["5"] = hexToColor("#c68a4c"),
    ["6"] = hexToColor("#eed19c"),
    ["7"] = hexToColor("#1c381c"),
    ["8"] = hexToColor("#386e2d"),
    ["9"] = hexToColor("#6ca33b"),
    ["A"] = hexToColor("#a8d45d"),
    ["B"] = hexToColor("#782017"),
    ["C"] = hexToColor("#bd3826"),
    ["D"] = hexToColor("#ea6532"),
    ["E"] = hexToColor("#22445e"),
    ["F"] = hexToColor("#3e78a6"),
    ["G"] = hexToColor("#809c91"),
}

local function drawAsciiArt(img, startX, startY, lines)
    for y = 1, #lines do
        local row = lines[y]
        for x = 1, #row do
            local ch = row:sub(x, x)
            local col = COLOR_MAP[ch]
            if col then
                img:drawPixel(startX + x - 1, startY + y - 1, col)
            end
        end
    end
end

local function createSprite(w, h, drawFn)
    local spr = Sprite(w, h, ColorMode.RGB)
    if spr.layers[1] and spr.layers[1].isBackground then
        spr.layers[1].isBackground = false
    end

    if spr.palettes and #spr.palettes > 0 then
        local pal = spr.palettes[1]
        pal:resize(#PALETTE_HEXES)
        for i, hex in ipairs(PALETTE_HEXES) do
            pal:setColor(i - 1, hexToColor(hex))
        end
    end

    local cel = (spr.cels and #spr.cels > 0) and spr.cels[1] or nil
    if cel and cel.image then
        drawFn(cel.image)
    else
        local img = Image(w, h, ColorMode.RGB)
        drawFn(img)
        local layer = spr.layers[1] or spr:newLayer()
        spr:newCel(layer, 1, img, Point(0, 0))
    end

    return spr
end

local function exportAsset(spr, filenameBase)
    ensureDir(source_dir)
    ensureDir(out_dir)
    local asePath = joinPath(source_dir, filenameBase .. ".aseprite")
    local pngPath = joinPath(out_dir, filenameBase .. ".png")
    spr:saveAs(asePath)
    spr:saveCopyAs(pngPath)
    spr:close()
end

-- ----------------------------------------------------------------------------
-- 1) fish.png (48x16) - 3 Fish Silhouettes (left-to-right, swimming left):
--    - Slot 1: Cá Rô (Green silver perch, spiny dorsal fin)
--    - Slot 2: Cá Trê (Elongated blue-grey catfish with whiskers)
--    - Slot 3: Cá Chép (Cream/orange carp with arched back and forked tail)
-- ----------------------------------------------------------------------------
local FISH_CA_RO = {
    "................",
    "................",
    "......7.7.7.....",
    ".....7979797....",
    "...7798989877...",
    ".7788989988777..",
    "71618989887.797.",
    ".78AA9887777797.",
    "..766AA87..7797.",
    "...767.7887.....",
    "....7...77......",
    "................",
    "................",
    "................",
    "................",
    "................",
}

local FISH_CA_TRE = {
    "................",
    "................",
    "................",
    ".......EEEEEE...",
    ".G.....EFFFFFE..",
    "..G.EEEFFFFFFFEE",
    "GG1E1FFFFFFEFFFF",
    "..GEEGGGFFFFFFFF",
    ".G...EEEEEFFFFEE",
    ".......EE.EEEE..",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
}

local FISH_CA_CHEP = {
    "................",
    "................",
    "......BB........",
    "....BBCDD3...3DD",
    "..33CCDDCD3.3CD3",
    ".316CC55DCD33D3.",
    "3666CD5DCC333...",
    ".36666DCCC3.3D3.",
    "..33663.3DDD33DD",
    "....33....33....",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
}

local sprFish = createSprite(48, 16, function(img)
    drawAsciiArt(img, 0, 0, FISH_CA_RO)
    drawAsciiArt(img, 16, 0, FISH_CA_TRE)
    drawAsciiArt(img, 32, 0, FISH_CA_CHEP)
end)
exportAsset(sprFish, "fish")

-- ----------------------------------------------------------------------------
-- 2) fishing_spot.png (16x16)
--    Small wooden tackle crate with iron bands and brass latch, visible diagonal
--    bamboo rod, and red/cream float. Bottom-center anchor on dock.
-- ----------------------------------------------------------------------------
local FISHING_SPOT = {
    "................",
    "...........16...",
    "..........16.G..",
    ".........16..G..",
    "........16..111.",
    ".......16..1CDD1",
    "......16..1B6661",
    ".....16....111..",
    "....16..111..G..",
    "...16..14541.1..",
    "..11111455541...",
    "..12444644421...",
    "..12333333321...",
    "..12455554421...",
    "..11111111111...",
    "...111111111....",
}

local sprSpot = createSprite(16, 16, function(img)
    drawAsciiArt(img, 0, 0, FISHING_SPOT)
end)
exportAsset(sprSpot, "fishing_spot")
