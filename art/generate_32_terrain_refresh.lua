-- ============================================================================
-- VƯỜN NHỎ - NATURAL SUMMER VIETNAMESE FARM LANDSCAPE GENERATOR
-- Standalone Deterministic Aseprite Lua Script
--
-- Atlases Generated:
--   1. terrain.aseprite & terrain.png (288x32, 9 columns of 32x32)
--      Col 0: Grass base
--      Col 1: Dirt path
--      Col 2: Untouched tillable soil (rich crumbly loam)
--      Col 3: Dry furrows (baked dusty ridges, sunlit top-left)
--      Col 4: Wet furrows (dark saturated mud with glossy water sheen)
--      Col 5: Grass variant 1 (soft blade tufts)
--      Col 6: Grass variant 2 (summer clover & tiny pale wildflowers)
--      Col 7: Grass variant 3 (lush wind-bent blades)
--      Col 8: Dirt path variant (embedded smooth pebbles & subtle ruts)
--
--   2. village_terrain.aseprite & village_terrain.png (256x32, 8 columns of 32x32)
--      Col 0: Village grass variant A (garden-compatible palette)
--      Col 1: Village grass variant B
--      Col 2: Village grass variant C
--      Col 3: Village path (wider compacted earthen lane)
--      Col 4: Deep river variant 1 (horizontal wavelets)
--      Col 5: Deep river variant 2 (shifting current & light glints)
--      Col 6: River bank (grassy left half, muddy slope, deep river right half)
--      Col 7: Wooden dock (weathered planks, bevels, depth & water shadow)
--
-- Layers per sprite:
--   - "base": Fully opaque background & primary ground tones
--   - "detail": Handcrafted clusters, top-left highlights, shadows, wood grain
-- ============================================================================

local PRNG = {}
PRNG.__index = PRNG
function PRNG.new(seed)
    local self = setmetatable({}, PRNG)
    self.s = seed or 1337
    return self
end
function PRNG:next()
    self.s = (self.s * 1664525 + 1013904223) % 4294967296
    return self.s
end
function PRNG:random(min, max)
    local r = self:next() / 4294967296
    if not min then return r end
    if not max then return math.floor(r * min) + 1 end
    return math.floor(r * (max - min + 1)) + min
end

local rgba = app.pixelColor.rgba

-- ----------------------------------------------------------------------------
-- CONSTRAINED SUMMER VIETNAMESE PALETTE (Handcrafted, low contrast)
-- ----------------------------------------------------------------------------
-- Grass (Warm tropical summer greens)
local G_BASE        = rgba(83, 126, 56, 255)
local G_DARK        = rgba(68, 106, 48, 255)
local G_LIGHT       = rgba(96, 139, 65, 255)
local G_TIP         = rgba(109, 151, 71, 255)
local G_PATCH       = rgba(78, 120, 54, 255)
local G_SUN         = rgba(88, 132, 58, 255)
local G_DEEP        = rgba(46, 86, 32, 255)
local G_FLOWER      = rgba(222, 230, 152, 255)
local G_FLOWER_CORE = rgba(196, 166, 76, 255)

-- Dirt Path (Warm alluvial sandy loam / đất phù sa pha cát)
local D_BASE        = rgba(162, 118, 78, 255)
local D_LIGHT       = rgba(172, 127, 85, 255)
local D_DARK        = rgba(151, 108, 72, 255)
local D_DEEP        = rgba(124, 84, 52, 255)
local D_PEBBLE_HI   = rgba(194, 186, 172, 255)
local D_PEBBLE_SHAD = rgba(114, 104, 92, 255)

-- Untouched Tillable Soil (Rich crumbly moist loam / đất tơi xốp)
local S_BASE        = rgba(108, 72, 46, 255)
local S_LIGHT       = rgba(126, 86, 56, 255)
local S_DARK        = rgba(82, 52, 34, 255)
local S_CLOD_HI     = rgba(138, 96, 64, 255)
local S_DEEP        = rgba(64, 38, 24, 255)

-- Dry Furrows (Luống khô: baked dusty crests, distinct ridges)
local F_DRY_TRENCH  = rgba(92, 64, 44, 255)
local F_DRY_RIDGE   = rgba(150, 112, 78, 255)
local F_DRY_SLOPE   = rgba(126, 90, 62, 255)
local F_DRY_HI      = rgba(172, 132, 94, 255)
local F_DRY_SHAD    = rgba(76, 50, 34, 255)

-- Wet Furrows (Luống ướt: deep saturated mud, specular sheen)
local F_WET_TRENCH  = rgba(38, 26, 18, 255)
local F_WET_RIDGE   = rgba(66, 44, 28, 255)
local F_WET_SLOPE   = rgba(50, 34, 22, 255)
local F_WET_SHEEN   = rgba(96, 122, 116, 255)
local F_WET_GLINT   = rgba(132, 162, 156, 255)
local F_WET_DEEP    = rgba(26, 18, 12, 255)

-- Village Path (Compacted rural earthen walkway)
local VP_BASE       = rgba(166, 126, 86, 255)
local VP_LIGHT      = rgba(175, 135, 94, 255)
local VP_DARK       = rgba(154, 115, 78, 255)

-- Deep River (Murky tropical delta water / sông phù sa sâu)
local R_BASE        = rgba(24, 60, 76, 255)
local R_TROUGH      = rgba(16, 42, 54, 255)
local R_RIPPLE      = rgba(38, 88, 108, 255)
local R_CREST       = rgba(56, 118, 138, 255)
local R_GLINT       = rgba(86, 156, 176, 255)

-- River Bank (Bờ sông: grassy transition, wet mud slope, water lap)
local BANK_MUD      = rgba(88, 62, 42, 255)
local BANK_WET      = rgba(54, 38, 26, 255)
local BANK_LAP      = rgba(72, 130, 146, 255)

-- Wooden Dock (Cầu gỗ: weathered tropical timber, depth, water shadow)
local W_PLANK       = rgba(134, 94, 60, 255)
local W_HI          = rgba(168, 126, 84, 255)
local W_GRAIN       = rgba(112, 76, 48, 255)
local W_SEAM        = rgba(54, 34, 20, 255)
local W_EDGE        = rgba(70, 46, 28, 255)
local W_PEG         = rgba(42, 28, 18, 255)
local W_PEG_HI      = rgba(180, 140, 100, 255)
local W_POST        = rgba(64, 52, 40, 255)
local W_MOSS        = rgba(42, 72, 50, 255)
local W_WATER_SHAD  = rgba(14, 34, 44, 255)

-- ----------------------------------------------------------------------------
-- DRAWING HELPERS
-- ----------------------------------------------------------------------------
local function set_pixel(img, col, lx, ly, color)
    if lx >= 0 and lx < 32 and ly >= 0 and ly < 32 then
        img:drawPixel(col * 32 + lx, ly, color)
    end
end

-- ----------------------------------------------------------------------------
-- PROCEDURAL TILE GENERATORS
-- ----------------------------------------------------------------------------

-- Grass generator (Base & Variants)
local function draw_grass_tile(base_img, detail_img, col, variant, rng)
    -- Base layer: 100% opaque background
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, x, y, G_BASE)
        end
    end

    -- Detail layer: clustered low-contrast blades, seamless edges (border kept clean)
    local clusters = {}
    if variant == 0 then
        clusters = { {6, 8}, {18, 6}, {10, 20}, {22, 18}, {15, 26} }
    elseif variant == 1 then
        clusters = { {5, 6}, {12, 12}, {24, 8}, {8, 24}, {19, 21}, {26, 25} }
    elseif variant == 2 then
        clusters = { {7, 10}, {21, 7}, {14, 18}, {6, 24}, {23, 23} }
    elseif variant == 3 then
        clusters = { {8, 6}, {19, 11}, {11, 15}, {25, 17}, {7, 22}, {18, 26} }
    elseif variant == "vA" then
        clusters = { {6, 7}, {20, 8}, {12, 17}, {23, 19}, {8, 25} }
    elseif variant == "vB" then
        clusters = { {9, 5}, {16, 12}, {6, 19}, {24, 14}, {18, 24} }
    elseif variant == "vC" then
        clusters = { {7, 8}, {22, 6}, {13, 15}, {8, 23}, {21, 22}, {16, 27} }
    end

    for _, pt in ipairs(clusters) do
        local cx, cy = pt[1], pt[2]
        local radius = rng:random(2, 5)
        for dy = -2, 2 do
            for dx = -radius, radius do
                local x, y = cx + dx, cy + 2 + dy
                if x >= 2 and x <= 29 and y >= 2 and y <= 29 and math.abs(dx) + math.abs(dy) < radius + 1 then
                    set_pixel(base_img, col, x, y, dy < 0 and G_SUN or G_PATCH)
                end
            end
        end
        -- Top-left blade
        set_pixel(detail_img, col, cx, cy - 1, G_TIP)
        set_pixel(detail_img, col, cx, cy, G_LIGHT)
        set_pixel(detail_img, col, cx + 1, cy, G_BASE)
        set_pixel(detail_img, col, cx + 1, cy + 1, G_DARK)

        -- Clustered partner blade
        if rng:random(1, 100) > 30 then
            set_pixel(detail_img, col, cx + 2, cy - 1, G_TIP)
            set_pixel(detail_img, col, cx + 2, cy, G_LIGHT)
            set_pixel(detail_img, col, cx + 3, cy + 1, G_DARK)
        end

        -- Variant 2 & vC: Tiny Vietnamese garden clover / wildflower
        if (variant == 2 or variant == "vC") and rng:random(1, 100) > 40 then
            set_pixel(detail_img, col, cx - 1, cy + 1, G_FLOWER)
            set_pixel(detail_img, col, cx, cy + 1, G_FLOWER_CORE)
            set_pixel(detail_img, col, cx - 1, cy + 2, G_DEEP)
        end
    end
end

-- Dirt path generator (Col 1 & Col 8)
local function draw_dirt_path_tile(base_img, detail_img, col, is_variant, rng)
    -- Base layer: Opaque warm earth with gentle edge transitions
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, x, y, D_BASE)
        end
    end

    -- Detail layer: Natural earthen texture
    for _ = 1, 65 do
        local x, y = rng:random(2, 29), rng:random(2, 29)
        local tone = rng:random(1, 2) == 1 and D_LIGHT or D_DARK
        set_pixel(detail_img, col, x, y, tone)
        if rng:random(1, 3) == 1 then set_pixel(detail_img, col, x + 1, y, tone) end
    end

    -- Col 8: Dirt path variant with compatible edges, embedded pebbles & cart rut
    if is_variant then
        -- Clustered smooth river pebbles (top-left highlight, bottom-right shadow)
        local pebbles = { {7, 8}, {21, 6}, {14, 18}, {9, 27}, {25, 26} }
        for _, pb in ipairs(pebbles) do
            local px, py = pb[1], pb[2]
            set_pixel(detail_img, col, px, py, D_PEBBLE_HI)
            set_pixel(detail_img, col, px + 1, py, D_LIGHT)
            set_pixel(detail_img, col, px, py + 1, D_DARK)
            set_pixel(detail_img, col, px + 1, py + 1, D_PEBBLE_SHAD)
        end
    end
end

-- Untouched tillable soil (Col 2: Rich, crumbly garden loam)
local function draw_untouched_soil_tile(base_img, detail_img, col, rng)
    -- Base layer: Solid rich loam
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, x, y, S_BASE)
        end
    end

    -- Detail layer: Crumbly clods lit from top-left (no furrow lines)
    for y = 1, 30, 2 do
        for x = 1, 30, 2 do
            local n = rng:random(1, 100)
            if n < 40 then
                -- Soil clod
                set_pixel(detail_img, col, x, y, S_CLOD_HI)
                set_pixel(detail_img, col, x + 1, y, S_LIGHT)
                set_pixel(detail_img, col, x, y + 1, S_DARK)
                set_pixel(detail_img, col, x + 1, y + 1, S_DEEP)
            elseif n < 55 then
                set_pixel(detail_img, col, x, y, S_DARK)
            end
        end
    end
end

-- Dry furrows (Col 3: Luống đất khô)
local function draw_dry_furrows_tile(base_img, detail_img, col, rng)
    -- 4 horizontal furrow rows (8 pixels each), aligns across garden grids
    for y = 0, 31 do
        local fy = y % 8
        local base_color = F_DRY_RIDGE
        if fy == 0 or fy == 1 then
            base_color = F_DRY_TRENCH
        elseif fy == 2 or fy == 3 or fy == 4 then
            base_color = F_DRY_RIDGE
        else
            base_color = F_DRY_SLOPE
        end

        for x = 0, 31 do
            set_pixel(base_img, col, x, y, base_color)
        end
    end

    -- Detail layer: Baked sunlit crest highlights & dry crumbly clods
    for band = 0, 3 do
        local by = band * 8
        -- Continuous ridge highlight line along upper ridge
        for x = 0, 31 do
            if (x + band) % 3 ~= 0 then
                set_pixel(detail_img, col, x, by + 2, F_DRY_HI)
            end
            if x % 4 == 0 then
                set_pixel(detail_img, col, x, by + 1, F_DRY_SHAD)
            end
        end

        -- Scattered baked clods on ridge
        for x = 3, 28, 5 do
            if rng:random(1, 100) < 65 then
                local cx = x + rng:random(-1, 1)
                set_pixel(detail_img, col, cx, by + 3, F_DRY_HI)
                set_pixel(detail_img, col, cx + 1, by + 3, F_DRY_RIDGE)
                set_pixel(detail_img, col, cx + 1, by + 4, F_DRY_SLOPE)
                set_pixel(detail_img, col, cx, by + 4, F_DRY_SHAD)
            end
        end
    end
end

-- Wet furrows (Col 4: Luống đất ướt)
local function draw_wet_furrows_tile(base_img, detail_img, col, rng)
    -- Same 8-pixel periodicity for perfect grid correspondence, much darker sepia tones
    for y = 0, 31 do
        local fy = y % 8
        local base_color = F_WET_RIDGE
        if fy == 0 or fy == 1 then
            base_color = F_WET_TRENCH
        elseif fy == 2 or fy == 3 or fy == 4 then
            base_color = F_WET_RIDGE
        else
            base_color = F_WET_SLOPE
        end

        for x = 0, 31 do
            set_pixel(base_img, col, x, y, base_color)
        end
    end

    -- Detail layer: Specular water sheen & dark mud crevices
    for band = 0, 3 do
        local by = band * 8
        for x = 0, 31 do
            -- Wet sheen highlights catching sunlight top-left
            if (x + band * 2) % 4 == 0 then
                set_pixel(detail_img, col, x, by + 2, F_WET_SHEEN)
                if x % 8 == 0 then
                    set_pixel(detail_img, col, x + 1, by + 2, F_WET_GLINT)
                end
            end
            -- Moist trench shadows
            if x % 3 == 0 then
                set_pixel(detail_img, col, x, by + 0, F_WET_DEEP)
            end
        end

        -- Wet mud clods
        for x = 2, 28, 4 do
            if rng:random(1, 100) < 55 then
                local cx = x + rng:random(-1, 1)
                set_pixel(detail_img, col, cx, by + 3, F_WET_RIDGE)
                set_pixel(detail_img, col, cx + 1, by + 3, F_WET_SHEEN)
                set_pixel(detail_img, col, cx, by + 4, F_WET_DEEP)
            end
        end
    end
end

-- Village path (Col 3 in village_terrain)
local function draw_village_path_tile(base_img, detail_img, col, rng)
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, x, y, VP_BASE)
        end
    end

    -- Compaction tracks and fine sand grain flecks
    for _ = 1, 82 do
        local x, y = rng:random(2, 29), rng:random(2, 29)
        set_pixel(detail_img, col, x, y, VP_LIGHT)
        if rng:random(1, 3) == 1 then set_pixel(detail_img, col, x + 1, y + 1, VP_DARK) end
    end
end

-- Deep river tile (Cols 4 & 5: Horizontal wavelets & current glints)
local function draw_river_tile(base_img, detail_img, col, variant, rng)
    -- Base layer: Solid deep delta water
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, x, y, R_BASE)
        end
    end

    -- Detail layer: Seamless horizontal ripples wrapping around x=0..31
    local wave_rows = {}
    if variant == 1 then
        wave_rows = { {4, 12, 0}, {9, 14, 16}, {15, 10, 8}, {21, 16, 20}, {27, 12, 4} }
    else
        wave_rows = { {6, 14, 8}, {12, 12, 22}, {18, 16, 2}, {24, 10, 14}, {29, 14, 26} }
    end

    for _, wv in ipairs(wave_rows) do
        local ry, len, sx = wv[1], wv[2], wv[3]
        for i = 0, len - 1 do
            local wx = (sx + i) % 32
            -- Crest highlight
            if i > 1 and i < len - 2 then
                set_pixel(detail_img, col, wx, ry, R_CREST)
                if i == math.floor(len / 2) then
                    set_pixel(detail_img, col, wx, ry, R_GLINT)
                end
            else
                set_pixel(detail_img, col, wx, ry, R_RIPPLE)
            end
            -- Trough shadow immediately underneath
            set_pixel(detail_img, col, wx, (ry + 1) % 32, R_TROUGH)
        end
    end
end

-- River bank tile (Col 6: Grassy left half, muddy slope, deep river right half)
local function draw_river_bank_tile(base_img, detail_img, col, rng)
    -- Base layer: Left half grass (0..12), transition slope (13..16), river (17..31)
    for y = 0, 31 do
        for x = 0, 31 do
            if x <= 12 then
                set_pixel(base_img, col, x, y, G_BASE)
            elseif x == 13 or x == 14 then
                set_pixel(base_img, col, x, y, BANK_MUD)
            elseif x == 15 or x == 16 then
                set_pixel(base_img, col, x, y, BANK_WET)
            else
                set_pixel(base_img, col, x, y, R_BASE)
            end
        end
    end

    -- Detail layer: Grass blades on left, water lap line, river ripples on right
    -- Grass markings on grassy side
    local bank_grass = { {4, 6}, {8, 11}, {3, 19}, {7, 24} }
    for _, pt in ipairs(bank_grass) do
        local gx, gy = pt[1], pt[2]
        set_pixel(detail_img, col, gx, gy - 1, G_TIP)
        set_pixel(detail_img, col, gx, gy, G_LIGHT)
        set_pixel(detail_img, col, gx + 1, gy + 1, G_DARK)
    end

    -- Shoreline water lap / foam line along muddy edge
    for y = 0, 31 do
        if y % 3 ~= 0 then
            set_pixel(detail_img, col, 16, y, BANK_LAP)
        end
        if y % 4 == 0 then
            set_pixel(detail_img, col, 14, y, D_PEBBLE_HI)
            set_pixel(detail_img, col, 14, y + 1, D_PEBBLE_SHAD)
        end
    end

    -- River wavelets on water side
    local bank_ripples = { {6, 8, 19}, {14, 10, 18}, {22, 9, 21}, {28, 8, 20} }
    for _, rw in ipairs(bank_ripples) do
        local ry, len, sx = rw[1], rw[2], rw[3]
        for i = 0, len - 1 do
            local wx = sx + i
            if wx < 32 then
                set_pixel(detail_img, col, wx, ry, R_CREST)
                set_pixel(detail_img, col, wx, ry + 1, R_TROUGH)
            end
        end
    end
end

-- Wooden dock tile (Col 7: Weathered planks, bevels, pegs, depth & water shadow)
local function draw_dock_tile(base_img, detail_img, col, rng)
    -- Base layer: River water top and bottom, dock structure across center
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 3 or y >= 30 then
                set_pixel(base_img, col, x, y, R_BASE)
            elseif y == 28 or y == 29 then
                set_pixel(base_img, col, x, y, W_WATER_SHAD)
            else
                set_pixel(base_img, col, x, y, W_PLANK)
            end
        end
    end

    -- Detail layer: Horizontal planks with bevels, pegs and believable 3D depth
    -- 3 Main wooden deck planks (y: 4..10, 12..18, 20..26)
    local planks = { {4, 10}, {12, 18}, {20, 26} }
    for _, p in ipairs(planks) do
        local p_top, p_bot = p[1], p[2]
        for x = 0, 31 do
            -- Top chamfer highlight (light from top-left)
            set_pixel(detail_img, col, x, p_top, W_HI)
            -- Bottom edge shadow / seam
            set_pixel(detail_img, col, x, p_bot, W_SEAM)
            -- Subtle wood grain lines
            if (x + p_top * 3) % 7 == 0 and p_top + 2 <= p_bot - 1 then
                set_pixel(detail_img, col, x, p_top + 2, W_GRAIN)
            end
        end
        -- Wood pegs / forged nail heads near ends
        set_pixel(detail_img, col, 4, p_top + 2, W_PEG)
        set_pixel(detail_img, col, 4, p_top + 1, W_PEG_HI)
        set_pixel(detail_img, col, 27, p_top + 2, W_PEG)
        set_pixel(detail_img, col, 27, p_top + 1, W_PEG_HI)
    end

    -- Front rim timber / edge overhang (y = 27) showing dock depth
    for x = 0, 31 do
        set_pixel(detail_img, col, x, 27, W_EDGE)
    end

    -- Heavy wooden pilings / posts sunk into water with waterline moss
    local posts = { {3, 6}, {25, 28} }
    for _, pst in ipairs(posts) do
        local x1, x2 = pst[1], pst[2]
        for px = x1, x2 do
            set_pixel(detail_img, col, px, 27, W_POST)
            set_pixel(detail_img, col, px, 28, W_MOSS)
            set_pixel(detail_img, col, px, 29, W_WATER_SHAD)
        end
        -- Left post edge highlight
        set_pixel(detail_img, col, x1, 28, W_HI)
    end

    -- Water surface ripples in exposed water zones
    for x = 4, 18 do
        set_pixel(detail_img, col, x, 2, R_CREST)
        set_pixel(detail_img, col, x, 3, R_TROUGH)
    end
    for x = 12, 24 do
        set_pixel(detail_img, col, x, 31, R_CREST)
    end
end

-- ----------------------------------------------------------------------------
-- ATLAS BUILDERS
-- ----------------------------------------------------------------------------

local function join_path(dir, filename)
    if not dir or dir == "" or dir == "." then
        return filename
    end
    local last = dir:sub(-1)
    local sep = "/"
    if dir:find("\\") and not dir:find("/") then
        sep = "\\"
    end
    if last == "/" or last == "\\" then
        return dir .. filename
    else
        return dir .. sep .. filename
    end
end

local function generate_atlas(name, width, height, render_func, source_dir, out_dir)
    local spr = Sprite(width, height, ColorMode.RGB)
    local base_layer = spr.layers[1]
    base_layer.name = "base"

    local detail_layer = spr:newLayer()
    detail_layer.name = "detail"

    local frame = spr.frames[1]
    local base_cel = base_layer:cel(frame) or spr:newCel(base_layer, frame)
    local detail_cel = detail_layer:cel(frame) or spr:newCel(detail_layer, frame)

    local base_img = base_cel.image
    local detail_img = detail_cel.image

    detail_img:clear(rgba(0, 0, 0, 0))

    render_func(base_img, detail_img)

    local ase_path = join_path(source_dir, name .. ".aseprite")
    local png_path = join_path(out_dir, name .. ".png")

    spr:saveCopyAs(ase_path)
    spr:saveCopyAs(png_path)
    spr:close()
end

-- ----------------------------------------------------------------------------
-- MAIN ENTRY POINT
-- ----------------------------------------------------------------------------
local params = app.params or {}
local source_dir = params["source_dir"] or params.source_dir or "."
local out_dir = params["out_dir"] or params.out_dir or source_dir

if app.fs and app.fs.makeAllDirectories and out_dir ~= "" and out_dir ~= "." then
    pcall(function() app.fs.makeAllDirectories(out_dir) end)
end

local rng = PRNG.new(1337)

-- 1. Build Garden Atlas: terrain.aseprite & terrain.png (288x32)
generate_atlas("terrain", 288, 32, function(base_img, detail_img)
    draw_grass_tile(base_img, detail_img, 0, 0, rng)           -- Col 0: Grass base
    draw_dirt_path_tile(base_img, detail_img, 1, false, rng)   -- Col 1: Dirt path
    draw_untouched_soil_tile(base_img, detail_img, 2, rng)      -- Col 2: Untouched soil
    draw_dry_furrows_tile(base_img, detail_img, 3, rng)         -- Col 3: Dry furrows
    draw_wet_furrows_tile(base_img, detail_img, 4, rng)         -- Col 4: Wet furrows
    draw_grass_tile(base_img, detail_img, 5, 1, rng)           -- Col 5: Grass variant 1
    draw_grass_tile(base_img, detail_img, 6, 2, rng)           -- Col 6: Grass variant 2
    draw_grass_tile(base_img, detail_img, 7, 3, rng)           -- Col 7: Grass variant 3
    draw_dirt_path_tile(base_img, detail_img, 8, true, rng)    -- Col 8: Dirt path variant
end, source_dir, out_dir)

-- 2. Build Village Atlas: village_terrain.aseprite & village_terrain.png (256x32)
generate_atlas("village_terrain", 256, 32, function(base_img, detail_img)
    draw_grass_tile(base_img, detail_img, 0, "vA", rng)        -- Col 0: Grass variant A
    draw_grass_tile(base_img, detail_img, 1, "vB", rng)        -- Col 1: Grass variant B
    draw_grass_tile(base_img, detail_img, 2, "vC", rng)        -- Col 2: Grass variant C
    draw_village_path_tile(base_img, detail_img, 3, rng)       -- Col 3: Village path
    draw_river_tile(base_img, detail_img, 4, 1, rng)           -- Col 4: Deep river variant 1
    draw_river_tile(base_img, detail_img, 5, 2, rng)           -- Col 5: Deep river variant 2
    draw_river_bank_tile(base_img, detail_img, 6, rng)         -- Col 6: River bank
    draw_dock_tile(base_img, detail_img, 7, rng)               -- Col 7: Wooden dock
end, source_dir, out_dir)
