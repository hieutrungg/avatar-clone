-- ============================================================================
-- Vuon Nho (Day 2) - Asset Generator for Aseprite
-- Generates: weeds.png, cau_vang.png, dog_food.png, sickle_cut.png
-- Outputs horizontal atlases at native 32x32 per frame with .aseprite sources.
-- ============================================================================

local rgba = app.pixelColor.rgba

-- ----------------------------------------------------------------------------
-- CLI / Script Parameter Handling
-- ----------------------------------------------------------------------------
local params = app.params or {}
local out_dir = params["out_dir"] or params["outDir"] or "."
local source_dir = params["source_dir"] or params["sourceDir"] or out_dir

local function join_path(dir, filename)
    if not dir or dir == "" or dir == "." then
        return filename
    end
    local sep = (dir:find("\\") and not dir:find("/")) and "\\" or "/"
    if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
        return dir .. filename
    else
        return dir .. sep .. filename
    end
end

-- ----------------------------------------------------------------------------
-- Reusable Drawing Helpers
-- ----------------------------------------------------------------------------
local function pset(img, x, y, col)
    if x >= 0 and x < img.width and y >= 0 and y < img.height and col then
        img:drawPixel(x, y, col)
    end
end

local function stamp(img, ox, oy, pal, rows)
    for y = 1, #rows do
        local row = rows[y]
        for x = 1, #row do
            local ch = row:sub(x, x)
            local col = pal[ch]
            if col then
                pset(img, ox + x - 1, oy + y - 1, col)
            end
        end
    end
end

local function draw_line(img, x0, y0, x1, y1, col)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    while true do
        pset(img, x0, y0, col)
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
    end
end

local function export_atlas(name, width, height, draw_fn)
    local spr = Sprite(width, height, ColorMode.RGB)
    local cel = spr.cels[1] or spr:newCel(spr.layers[1], 1)
    local img = cel.image

    draw_fn(img)

    local png_file = join_path(out_dir, name .. ".png")
    local ase_file = join_path(source_dir, name .. ".aseprite")

    spr:saveCopyAs(png_file)
    spr:saveCopyAs(ase_file)
    spr:close()
end

-- ============================================================================
-- 1. WEEDS (96x32: 3 variants of tall thick field weeds, bottom-anchored)
-- ============================================================================
local pal_weed = {
    ['.'] = nil,
    ['K'] = rgba(22, 44, 20, 255),  -- deep shadow / high-contrast outline
    ['D'] = rgba(38, 74, 30, 255),  -- dark jungle green
    ['G'] = rgba(66, 122, 42, 255), -- mid field green
    ['L'] = rgba(128, 178, 56, 255),-- vibrant yellow-green
    ['H'] = rgba(186, 218, 90, 255),-- bright tip highlight
    ['O'] = rgba(172, 134, 56, 255),-- dry straw ochre blade
    ['B'] = rgba(108, 80, 32, 255), -- dark ochre stem / thatch
    ['S'] = rgba(224, 206, 148, 255)-- seed head cream
}

local weed_var1 = { -- Broad-leaf thick clump weed
    "..............H.................",
    ".............HLK................",
    "............HLGK................",
    "...........HLGGK.......H........",
    "..........HLGGDK......HLK.......",
    "..........LGGDDK.....HLGK.......",
    ".........KLGGDK.....HLGGK.......",
    ".........KLGDK......LGGDK.......",
    "........KLGGDK.....KLGGDK.......",
    "...H....KLGGDK.....KLGDK........",
    "..HLK...KLGGDDK...KLDDK.........",
    "..HLGK...KLGDDK...KGDDK.........",
    ".HLGGK...KLGDDK..KLGDK..........",
    ".HLGGDK..KLDGDK..KGDDK...H......",
    ".KLGGDDK.KLDGDK.KLGDDK..HLK.....",
    "..KLGDDKKKLDGDK.KLDGDK.HLGK.....",
    "...KLGDDKKLDGDKKLDGDDKKLGGK.....",
    "....KLGDDKKDDGKKLDGDKKLGGDK.....",
    ".....KLGDDKKDDDKDDGDKKLGDK......",
    "......KLGDDKDDDKDDGDKLGDK.......",
    ".......KLDGDDDDKDDGDDGDK........",
    "...O...KLDGDDDDKDDDDDDK.........",
    "..OLB...KDDDGDDKDDDDDDK..O......",
    ".OLBGK..KDDDDDDKDDDDDK..OBK.....",
    ".KOBGDK.KDDDDDDKDDDDDK.KOBDK....",
    "..KOBGDDKDDDDDDKDDDDDDKOBGDK....",
    "...KOBGDDDDDDDDDDDDDDDOBGDK.....",
    "....KOBDDDDDDDDDDDDDDDOBDK......",
    ".....KKDDDDDDDDDDDDDDDBDK.......",
    "......KKKDDDDDDDDDDDDKKK........",
    "........KKKKKKKKKKKKK...........",
    "................................"
}

local weed_var2 = { -- Tall flowering / foxtail seed reed
    "...............SH...............",
    "..............SSHK..............",
    ".............SHSSK..............",
    ".............SSSSK..............",
    ".............SSSSK..............",
    "............KSSSBK..............",
    "............KSSSBK..............",
    "............KSSSBK..............",
    ".............KBBK...............",
    ".............KGLK...............",
    ".......H.....KGLK...............",
    "......HLK....KGLK....H..........",
    ".....HLGK...KKGLKK..HLK.........",
    "....HLGGK...KLGGLK..HLGK........",
    "...HLGGDK...KLGGLK..KLGGK.......",
    "...LGGDK....KLGGLK...LGGDK......",
    "..KLGGDK...KKLDGLKK..KLGGDK.....",
    "..KLGDDK...KLDDGGLK...KLGDK.....",
    "..KLGDDK...KLDDGGLK...KLGDDK....",
    "...KLDDK..KKLDDGGLKK..KLDDDK....",
    "...KLDDK..KLDDDGGLLK...KDDDK....",
    "....KDDDK.KLDDDGGLKK..KDDDK.....",
    "....KDDDDKKDDDDGGLKK.KDDDDK.....",
    ".....KDDDDDDDDDGGLKKKDDDDDK.....",
    ".....KDDDDDDDDDGGLKKDDDDDDK.....",
    "......KDDDDDDDDDDLKKDDDDDDK.....",
    "......KKDDDDDDDDDLKKDDDDDK......",
    ".......KKDDDDDDDDLKKDDDDKK......",
    "........KKDDDDDDDDDDDDDKK.......",
    ".........KKKDDDDDDDDDDKK........",
    "...........KKKKKKKKKKK..........",
    "................................"
}

local weed_var3 = { -- Tangled creeping crabgrass / dry thatch
    "......................H.........",
    ".....................HLK........",
    "....................HLGK........",
    "...................HLGGK........",
    "..................HLGGDK........",
    ".......H.........HLGGGDK........",
    "......HLK.......HLGGDDK.........",
    ".....HLGK......HLGGDDK..........",
    "....HLGGK.....KLGGDDDK..........",
    "...HLGGDK.....KLGGDDDK...H......",
    "..HLGGDK.....KLLGGDDDK..HLK.....",
    "..LGGDK......KLGGDDDDK.HLGK.....",
    ".KLGGDK.....KLDGGDDDDKKLGGK.....",
    ".KLGDDK....KKLDGGDDDDKKLGGDK....",
    ".KLGDDK....KLDDGDDDDK.KLGGDK....",
    "..KLDDK...KKLDDGDDDDK..KLGDDK...",
    "..KLDDDK..KLDDDGDDDDK..KLGDDK...",
    "...KDDDK..KLDDDGDDDDK...KLGDDK..",
    "...KDDDDDKKDDDDDDDDDK....KLDDK..",
    "....KDDDDDKDDDDDDDDDK....KDDDK..",
    "....KDDDDDDDDDDDDDDDK...KDDDDK..",
    "....KDDDDDDDDDDDDDDDDK..KDDDDK..",
    ".O...KDDDDDDDDDDDDDDDDKKDDDDDK..",
    "OBK..KDDDDDDDDDDDDDDDDDDDDDDDK..",
    "KOBKKKDDDDDDDDDDDDDDDDDDDDDDK...",
    ".KOBBDDDDDDDDDDDDDDDDDDDDDDK....",
    "..KOBBBDDDDDDDDDDDDDDDDDDDKK....",
    "...KKOBBBDDDDDDDDDDDDDDDDKK.....",
    ".....KKOBBBDDDDDDDDDDDDDKK......",
    ".......KKKOBBBDDDDDDDDKKK.......",
    "..........KKKKKKKKKKKK..........",
    "................................"
}

-- ============================================================================
-- 2. CAU VANG (128x32: 4 frames of golden Vietnamese village dog facing DL)
-- ============================================================================
local pal_dog = {
    ['.'] = nil,
    ['K'] = rgba(56, 32, 18, 255),   -- deep brown outline
    ['B'] = rgba(146, 88, 40, 255),  -- warm fur shadow
    ['Y'] = rgba(218, 150, 56, 255), -- golden ochre coat
    ['L'] = rgba(244, 190, 96, 255), -- top coat highlight
    ['W'] = rgba(252, 234, 192, 255),-- cream muzzle, chest, and socks
    ['E'] = rgba(26, 16, 12, 255),   -- eyes and nose
    ['S'] = rgba(255, 255, 255, 255),-- eye catchlight
    ['P'] = rgba(232, 116, 120, 255) -- tongue / inner ear pink
}

-- Frame 0: Standing alert stray
local dog_f0 = {
    "................................",
    "................................",
    "................................",
    "................................",
    "..............KK................",
    ".............KYLK..........KK...",
    "............KLLYLK........KYLK..",
    ".....KK....KLLYYLK.......KYLK...",
    "....KPBK..KLLYYYYLK......KYLK...",
    "...KPYBK..KLYYYYYLK.....KYYLK...",
    "...KYYBK.KSEYYYYYLK....KYYLK....",
    "...KYYBKKEYYYYYYYLK...KYYLK.....",
    "....KYYEWWYYYYYYYYLK.KYYLK......",
    ".....KEWWYYYYYYYYYLKKYYLK.......",
    ".....KWWYYYYYYYYYYYYYYLK........",
    "......KWWYYYYYYYYYYYYLK.........",
    "......KWWWYYYYYYYYYYLK..........",
    "......KWWWWYYYYYYYYLK...........",
    ".......KWWWBYYYYYYYLK...........",
    ".......KWWBKKBYYYYYLK...........",
    ".......KWWK..KBYYYYYLK..........",
    ".......KWWK...KBYYYYYLK.........",
    ".......KWWK....KBYYYYLK.........",
    ".......KWWK.....KBBBBK..........",
    ".......KYBK.....KYBKYBK.........",
    ".......KYBK.....KYBKYBK.........",
    ".......KYBK.....KYBKYBK.........",
    "......KWWK.....KWWKKWWK.........",
    "......KKKK.....KKKKKKKK.........",
    "................................",
    "................................",
    "................................"
}

-- Frame 1: Standing alert stray (subtle wag / ear flick)
local dog_f1 = {
    "................................",
    "................................",
    "................................",
    "................................",
    ".............KK............KK...",
    "............KYLK..........KYLK..",
    ".....KK....KLLYLK........KYLK...",
    "....KPBK..KLLYYLK.......KYLK....",
    "...KPYBK..KLYYYYYLK....KYYLK....",
    "...KYYBK.KSEYYYYYLK...KYYLK.....",
    "...KYYBKKEYYYYYYYLK..KYYLK......",
    "....KYYEWWYYYYYYYYLKKYYLK.......",
    ".....KEWWYYYYYYYYYYYYYLK........",
    ".....KWWYYYYYYYYYYYYYLK.........",
    "......KWWYYYYYYYYYYYLK..........",
    "......KWWWYYYYYYYYYYLK..........",
    "......KWWWWYYYYYYYYLK...........",
    ".......KWWWWBYYYYYYLK...........",
    ".......KWWWBYYYYYYYLK...........",
    ".......KWWBKKBYYYYYLK...........",
    ".......KWWK..KBYYYYYLK..........",
    ".......KWWK...KBYYYYYLK.........",
    ".......KWWK....KBYYYYLK.........",
    ".......KWWK.....KBBBBK..........",
    ".......KYBK.....KYBKYBK.........",
    ".......KYBK.....KYBKYBK.........",
    ".......KYBK.....KYBKYBK.........",
    "......KWWK.....KWWKKWWK.........",
    "......KKKK.....KKKKKKKK.........",
    "................................",
    "................................",
    "................................"
}

-- Frame 2: Sitting after being fed (belly full, calm, tongue peeking)
local dog_f2 = {
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".............KK.................",
    "............KYLK................",
    ".....KK....KLLYLK...............",
    "....KPBK..KLLYYLK...............",
    "...KPYBK..KLYYYYYLK.............",
    "...KYYBK.KSEYYYYYLK.............",
    "...KYYBKKEYYYYYYYLK.............",
    "....KYYEWWYYYYYYYYLK............",
    ".....KEWWYYYYYYYYYLK............",
    ".....KWWPWWYYYYYYYLK............",
    "......KWPPWWYYYYYYLK............",
    "......KWWWYYYYYYYYYLK...........",
    "......KWWWWYYYYYYYYYLK..........",
    ".......KWWWWBYYYYYYYYLK.........",
    ".......KWWWBYYYYYYYYYYLK........",
    ".......KWWBKBYYYYYYYYYYLK.......",
    ".......KWWKKBYYYYYYYYYYYLK......",
    ".......KWWK.KBYYYYYYYYYYLK......",
    ".......KWWK..KBYYYYYYYYYYLK.....",
    ".......KYBK..KBYYYYYYYYYYLK.....",
    ".......KYBK...KBYYYYYYYYLK......",
    ".......KYBK...KYYYYYYYYLK.......",
    "......KWWK...KWWKKYLLLK.........",
    "......KKKK...KKKK.KKKK..........",
    "................................",
    "................................",
    "................................"
}

-- Frame 3: Sitting after being fed (happy ear twitch & tail lift)
local dog_f3 = {
    "................................",
    "................................",
    "................................",
    "................................",
    "..............KK................",
    ".............KYLK...............",
    ".....KK.....KLLYLK..............",
    "....KPBK...KLLYYLK..............",
    "...KPYBK...KLYYYYYLK............",
    "...KYYBK..KSEYYYYYLK............",
    "...KYYBK.KEYYYYYYYLK.......KK...",
    "....KYYEWWYYYYYYYYLK......KYLK..",
    ".....KEWWYYYYYYYYYLK.....KYLK...",
    ".....KWWPWWYYYYYYYLK....KYYLK...",
    "......KWPPWWYYYYYYLK...KYYLK....",
    "......KWWWYYYYYYYYYLKKYYLK......",
    "......KWWWWYYYYYYYYYYYYLK.......",
    ".......KWWWWBYYYYYYYYYLK........",
    ".......KWWWBYYYYYYYYYLK.........",
    ".......KWWBKBYYYYYYYYLK.........",
    ".......KWWKKBYYYYYYYYLK.........",
    ".......KWWK.KBYYYYYYYYLK........",
    ".......KWWK..KBYYYYYYYYLK.......",
    ".......KYBK..KBYYYYYYYYYLK......",
    ".......KYBK...KBYYYYYYYYLK......",
    ".......KYBK...KYYYYYYYYLK.......",
    "......KWWK...KWWKKYLLLK.........",
    "......KKKK...KKKK.KKKK..........",
    "................................",
    "................................",
    "................................",
    "................................"
}

-- ============================================================================
-- 3. DOG FOOD (32x32: Leaf parcel tied with twine on a wooden shelf)
-- ============================================================================
local pal_food = {
    ['.'] = nil,
    -- Shelf woodwork
    ['#'] = rgba(48, 28, 14, 255),   -- dark wood shadow
    ['='] = rgba(116, 72, 36, 255),  -- mid warm wood
    ['+'] = rgba(168, 110, 60, 255), -- top shelf highlight
    -- Banana leaf parcel
    ['K'] = rgba(24, 46, 20, 255),   -- leaf contour / deep fold
    ['D'] = rgba(42, 80, 34, 255),   -- deep shadow leaf
    ['G'] = rgba(68, 120, 48, 255),  -- mid olive green
    ['L'] = rgba(114, 168, 74, 255), -- bright leaf highlight
    -- Brown bamboo twine (Lạt tre)
    ['t'] = rgba(98, 68, 30, 255),   -- twine shadow
    ['T'] = rgba(166, 126, 64, 255), -- twine midtone
    ['h'] = rgba(220, 184, 120, 255) -- twine highlight knot
}

local food_art = {
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "..............hT................",
    ".............hTTh...............",
    "............KhTThK..............",
    "...........KLLhTLLK.............",
    "..........KLLGhTGGDK............",
    ".........KLLGGhTGGDDDK..........",
    "........KLLGGGhTGGDDDDK.........",
    ".......KLLGGGGhTGGGDDDDK........",
    "......KLLGGGGGhTGGGGDDDDK.......",
    ".....KLLGGGGGGhTGGGGGDDDDK......",
    ".....KLLGGGGGGhTGGGGGDDDDK......",
    ".....KhhhhhhhhhhhhhhhhhhhK......",
    ".....KTTTTTTTTTTTTTTTTTTTK......",
    ".....KLLGGGGGGtTGGGGGDDDDK......",
    ".....KLLGGGGGGtTGGGGGDDDDK......",
    "......KLGGGGGGtTGGGGDDDDK.......",
    ".......KLGGGGGtTGGGDDDDK........",
    "..++++++++++++++++++++++++++++..",
    "..============================..",
    "..============================..",
    "..############################..",
    "....##....................##....",
    "....##....................##....",
    "....#......................#....",
    "................................",
    "................................",
    "................................"
}

-- ============================================================================
-- 4. SICKLE CUT (96x32: 3 frames of sickle swing, cutting arc & clippings)
-- ============================================================================
local pal_sickle = {
    ['.'] = nil,
    -- Sickle handle & steel blade
    ['b'] = rgba(46, 26, 14, 255),   -- handle wood shadow
    ['B'] = rgba(108, 64, 32, 255),  -- handle wood body
    ['H'] = rgba(164, 104, 56, 255), -- handle wood highlight
    ['s'] = rgba(44, 52, 66, 255),   -- blade dark steel
    ['S'] = rgba(130, 146, 168, 255),-- blade mid steel
    ['W'] = rgba(228, 240, 255, 255),-- blade silver edge
    ['*'] = rgba(255, 255, 255, 255),-- blade tip gleam
    -- Swing arc sweep
    ['A'] = rgba(255, 255, 255, 240),-- arc sharp core
    ['a'] = rgba(160, 225, 255, 180),-- arc glowing aura
    ['c'] = rgba(90, 170, 230, 110), -- arc motion trail
    ['f'] = rgba(120, 190, 240, 60), -- arc faint dissipation
    -- Cut grass clippings
    ['g'] = rgba(50, 92, 32, 230),   -- shadow clipping
    ['G'] = rgba(118, 182, 50, 240), -- mid clipping
    ['Y'] = rgba(184, 218, 88, 255)  -- highlight clipping tip
}

-- Frame 0: Wind-up & arc inception
local cut_f0 = {
    "................................",
    "................................",
    "................................",
    "..................*W............",
    ".................WWSs...........",
    "................WWSss...........",
    "...............WWSSss...........",
    "..............WWSSsss...........",
    ".............WWSSsss............",
    ".............WSSsss.............",
    "..............SSss..............",
    "...............sb...............",
    "................bHB.............",
    ".................bHB............",
    "..................bHB...........",
    "...................bHB..........",
    "....................bb..........",
    "................................",
    "............a...................",
    "...........aA...................",
    "..........aAc...................",
    ".........aAc....................",
    "........aAc.....................",
    ".......aAc......................",
    "......aAc.......................",
    ".....aAc........................",
    "....aAc.........................",
    "....ac..........................",
    "................................",
    "................................",
    "................................",
    "................................"
}

-- Frame 1: Dynamic curved crescent swing with flying clippings
local cut_f1 = {
    ".........................ac.....",
    ".......................aAc......",
    ".....................aAAc.......",
    "...................aAAAc........",
    ".................aAAAAc...YG....",
    "...............aAAAAAc...YGGg...",
    ".............aAAAAAc......Gg....",
    "...........aAAAAAc..............",
    ".........aAAAAAc................",
    "........aAAAAAc.......YGG.......",
    ".......aAAAAAc.......YGGg.......",
    "......aAAAAAc.........Gg........",
    ".....aAAAAc.....................",
    "....aAAAAc......................",
    "...aAAAAc...........YG..........",
    "..aAAAAc...........YGGg.........",
    "..aAAAc.............Gg..........",
    ".aAAAc..........................",
    ".aAAc........YG.................",
    ".aAc........YGGg................",
    ".ac..........Gg.................",
    ".c..............................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
}

-- Frame 2: Dissipating arc trail & tumbling clippings
local cut_f2 = {
    "................................",
    "................................",
    "........................f.......",
    "......................ff........",
    "....................fff.........",
    "..................fffc..........",
    "................ffcc.....YG.....",
    "..............ffcc......YGGg....",
    "............ffcc.........Gg.....",
    "..........ffcc..................",
    "........ffcc....................",
    ".......ffcc.........YG..........",
    "......ffcc.........YGGg.........",
    ".....ffc............Gg..........",
    "....ffc.........................",
    "...ffc..........................",
    "..ffc............YG.............",
    "..fc............YGGg............",
    ".ff..............Gg.............",
    ".f..............................",
    "................................",
    "..........YG....................",
    ".........YGGg...................",
    "..........Gg....................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................"
}

-- ============================================================================
-- Batch Render and Export
-- ============================================================================

-- 1. Weeds (96x32: 3 variants)
export_atlas("weeds", 96, 32, function(img)
    stamp(img, 0,  0, pal_weed, weed_var1)
    stamp(img, 32, 0, pal_weed, weed_var2)
    stamp(img, 64, 0, pal_weed, weed_var3)
end)

-- 2. Cau Vang (128x32: 4 animation frames)
export_atlas("cau_vang", 128, 32, function(img)
    stamp(img, 0,  0, pal_dog, dog_f0)
    stamp(img, 32, 0, pal_dog, dog_f1)
    stamp(img, 64, 0, pal_dog, dog_f2)
    stamp(img, 96, 0, pal_dog, dog_f3)
end)

-- 3. Dog Food (32x32: 1 shelf parcel frame)
export_atlas("dog_food", 32, 32, function(img)
    stamp(img, 0, 0, pal_food, food_art)
end)

-- 4. Sickle Cut (96x32: 3 harvest swing frames)
export_atlas("sickle_cut", 96, 32, function(img)
    stamp(img, 0,  0, pal_sickle, cut_f0)
    stamp(img, 32, 0, pal_sickle, cut_f1)
    stamp(img, 64, 0, pal_sickle, cut_f2)
end)
