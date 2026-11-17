-- ============================================================================
-- VƯỜN NHỎ - BẢN THỬ TILESET NÔNG TRẠI ĐỒNG QUÊ BẮC NINH (32x32 PX)
-- File: generate_farm_fields_study.lua
--
-- Standalone Deterministic Aseprite Lua Generator Script
-- Tham chiếu bố cục & độ rõ: Stonebit Studio Farm Fields 32x32
--
-- Atlases & Outputs:
--   - farm_fields_study.aseprite (256x288 px, 8 cols x 9 rows, 3 layers: base, detail, highlights)
--   - farm_fields_study.png      (Flattened atlas 256x288 px)
--   - preview_1x.png             (Preview map 512x320 px, 16x10 tiles, with player character 32x48)
--   - preview_2x.png             (Nearest-neighbor 2x scaled preview 1024x640 px)
--   - tiles.md                   (Comprehensive documentation of tile indices, palette, autotiling)
--
-- Command execution:
--   aseprite -b --script D:/DuAnLinhTinh/GameNongTrai/art/terrain-study/farm-fields-v1/generate_farm_fields_study.lua \
--            --script-param output_dir=D:/DuAnLinhTinh/GameNongTrai/art/terrain-study/farm-fields-v1 \
--            --script-param project_dir=D:/DuAnLinhTinh/GameNongTrai
-- ============================================================================

local PRNG = {}
PRNG.__index = PRNG
function PRNG.new(seed)
    local self = setmetatable({}, PRNG)
    self.s = seed or 20261115
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
-- BẮC NINH COUNTRYSIDE PALETTE (Warm, muted olive, rich loam, burnt clay)
-- ----------------------------------------------------------------------------
-- 1. Cỏ ô liu dịu (Muted Olive Grass & Meadow)
local G_BASE        = rgba(92, 128, 54, 255)   -- Nền cỏ xanh ô liu dịu vùng châu thổ
local G_DARK        = rgba(74, 106, 44, 255)   -- Đổ bóng gốc cỏ, ranh giới đất
local G_LIGHT       = rgba(110, 144, 66, 255)  -- Thân ngọn cỏ hướng sáng Tây Bắc
local G_TIP         = rgba(126, 160, 78, 255)  -- Đỉnh nhọn lá cỏ bắt sáng
local G_PATCH       = rgba(84, 118, 50, 255)   -- Vạt cỏ sẫm màu
local G_SUN         = rgba(102, 138, 60, 255)  -- Vạt cỏ đón nắng
local G_SHADOW      = rgba(56, 84, 34, 255)    -- Rãnh khuất sáng
local G_FLOWER      = rgba(232, 226, 160, 255) -- Cánh hoa dại vàng nhạt
local G_FLOWER_CORE = rgba(194, 152, 70, 255)  -- Nhụy hoa cỏ mùa hạ
local G_FLOWER_W    = rgba(244, 240, 224, 255) -- Hoa cỏ may trắng ngà

-- 2. Đất phù sa đỏ nâu (Red River Delta Alluvial Soil)
local D_BASE        = rgba(148, 92, 60, 255)   -- Đất phù sa đỏ nâu tơi xốp
local D_LIGHT       = rgba(166, 110, 76, 255)  -- Hạt đất mịn bề mặt
local D_DARK        = rgba(126, 76, 48, 255)   -- Bóng chân vệt đất
local D_DEEP        = rgba(102, 58, 36, 255)   -- Hốc đất sẫm
local D_FINE        = rgba(182, 126, 90, 255)  -- Bụi phù sa mịn khô ráo
local D_PEBBLE_HI   = rgba(190, 182, 170, 255) -- Sỏi cuội suối sáng
local D_PEBBLE_SHAD = rgba(112, 104, 94, 255)  -- Chân bóng sỏi cuội

-- 3. Gạch nung đỏ lệch (Rustic Terracotta Bricks / Phù Lãng, Bát Tràng)
local BRICK_BASE    = rgba(168, 66, 46, 255)   -- Gạch nung đỏ son sẫm củi rơm
local BRICK_HI      = rgba(198, 90, 66, 255)   -- Vát mép gạch gốm đón nắng
local BRICK_SHAD    = rgba(122, 44, 30, 255)   -- Vát cạnh khuất sáng
local BRICK_MUD     = rgba(124, 76, 50, 255)   -- Đất phù sa bám dính trên mặt gạch
local BRICK_PIT     = rgba(98, 34, 22, 255)    -- Vết mẻ cạnh gạch nung rơm

-- 4. Luống khô (Dry Furrows: rãnh ngắn lệch nhịp, gờ đất nung khô)
local F_DRY_CRUST   = rgba(168, 118, 80, 255)  -- Váng đất bề mặt khô giòn
local F_DRY_RIDGE   = rgba(144, 98, 66, 255)   -- Gờ vồng đất lên luống
local F_DRY_SLOPE   = rgba(126, 82, 54, 255)   -- Sườn dốc luống đất
local F_DRY_TRENCH  = rgba(106, 66, 44, 255)   -- Rãnh thoát nước luống khô
local F_DRY_HI      = rgba(188, 138, 96, 255)  -- Điểm sáng vụn đất nung
local F_DRY_DEEP    = rgba(86, 50, 32, 255)    -- Đáy rãnh luống sâu

-- 5. Luống ướt (Wet Furrows: đất nâu sẫm, vệt nước thưa phản chiếu)
local F_WET_BASE    = rgba(52, 34, 24, 255)    -- Bùn sẫm ngậm đẫm nước
local F_WET_RIDGE   = rgba(70, 46, 32, 255)    -- Gờ luống đất ẩm
local F_WET_SLOPE   = rgba(42, 28, 20, 255)    -- Sườn luống ướt trơn
local F_WET_TRENCH  = rgba(30, 18, 12, 255)    -- Rãnh luống ngập nước sẫm
local F_WET_SHEEN   = rgba(108, 138, 134, 255) -- Màng nước ánh xanh ngọc xám
local F_WET_GLINT   = rgba(154, 188, 182, 255) -- Điểm lấp lánh phản chiếu trời mây
local F_WET_DEEP    = rgba(20, 12, 8, 255)     -- Khe bùn khuất bóng

-- 6. Mặt nước ao làng xanh ngọc xám (Calm Grayish-Teal Pond Water)
local W_BASE        = rgba(46, 76, 80, 255)    -- Nước ao làng xanh ngọc xám tĩnh lặng
local W_DEEP        = rgba(32, 54, 58, 255)    -- Vùng nước sâu thăm thẳm
local W_RIPPLE      = rgba(64, 100, 104, 255)  -- Gợn sóng lăn tăn
local W_CREST       = rgba(86, 128, 132, 255)  -- Đỉnh gợn sóng đón sáng
local W_GLINT       = rgba(130, 172, 176, 255) -- Tia sáng lấp lánh mặt ao
local W_DUCKWEED    = rgba(116, 154, 74, 255)  -- Bèo tấm non xanh mướt
local W_DUCK_CORE   = rgba(142, 178, 96, 255)  -- Tim lá bèo tấm
local W_LILY_PAD    = rgba(76, 116, 62, 255)   -- Lá súng tròn nhỏ
local W_LILY_EDGE   = rgba(104, 146, 86, 255)  -- Viền mép lá súng
local W_SHALLOW     = rgba(62, 88, 86, 255)    -- Nước nông ánh đất phù sa

-- 7. Bờ ao thấp có cỏ lác (Low Pond Bank with Sedge / Cỏ lác)
local BANK_EARTH    = rgba(120, 80, 54, 255)   -- Vai đất mép bờ ao
local BANK_MUD      = rgba(82, 54, 38, 255)    -- Dải bùn thoai thoải mép nước
local BANK_WET      = rgba(56, 38, 28, 255)    -- Bùn sũng ngập nước
local BANK_LAP      = rgba(98, 138, 140, 255)  -- Mép sóng vỗ bờ đất êm dịu
local REED_BASE     = rgba(74, 106, 46, 255)   -- Gốc bụi cỏ lác rậm
local REED_MID      = rgba(98, 134, 60, 255)   -- Thân dẹp tam giác lá lác
local REED_TIP      = rgba(124, 162, 74, 255)  -- Đỉnh ngọn cỏ lác vươn ra mặt nước
local REED_SHAD     = rgba(48, 70, 32, 255)    -- Bóng cỏ lác đổ xuống váng bùn
local STONE_BASE    = rgba(148, 142, 132, 255) -- Phiến đá cầu ao rửa chân
local STONE_HI      = rgba(174, 168, 158, 255) -- Mặt đá mòn nhẵn đón sáng
local STONE_SHAD    = rgba(112, 106, 96, 255)  -- Chân phiến đá chìm trong bùn

-- ----------------------------------------------------------------------------
-- DRAWING HELPERS
-- ----------------------------------------------------------------------------
local function set_pixel(img, col, row, lx, ly, color)
    if lx >= 0 and lx < 32 and ly >= 0 and ly < 32 then
        img:drawPixel(col * 32 + lx, row * 32 + ly, color)
    end
end

local function draw_rect(img, col, row, x1, y1, x2, y2, color)
    for y = y1, y2 do
        for x = x1, x2 do
            set_pixel(img, col, row, x, y, color)
        end
    end
end

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

-- ============================================================================
-- PROCEDURAL TILE GENERATORS (72 TILES: 8 COLS x 9 ROWS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ROW 0: CỎ Ô LIU DỊU (MUTED OLIVE GRASS & MEADOW ACCENTS)
-- ----------------------------------------------------------------------------
local function generate_row0_grass(base_img, detail_img, high_img, rng)
    local row = 0
    -- Fill base layer with solid olive grass for all columns in Row 0
    for col = 0, 7 do
        draw_rect(base_img, col, row, 0, 0, 31, 31, G_BASE)
        -- Subtle low-contrast organic micro-patches on base
        for y = 2, 29, 4 do
            for x = 2, 29, 4 do
                local n = rng:random(1, 100)
                if n < 35 then
                    set_pixel(base_img, col, row, x, y, G_PATCH)
                    set_pixel(base_img, col, row, x + 1, y, G_PATCH)
                elseif n > 75 then
                    set_pixel(base_img, col, row, x, y, G_SUN)
                    set_pixel(base_img, col, row, x, y + 1, G_SUN)
                end
            end
        end
    end

    -- Col 0: Pure Grass Base (seamless, minimal blades)
    local col = 0
    local c0_blades = { {8, 9}, {23, 7}, {14, 21}, {26, 23} }
    for _, pt in ipairs(c0_blades) do
        local bx, by = pt[1], pt[2]
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx, by + 1, G_DARK)
        set_pixel(high_img, col, row, bx, by - 1, G_TIP)
    end

    -- Col 1: Grass Variant A (Soft blade tufts)
    col = 1
    local c1_tufts = { {6, 8}, {18, 6}, {10, 19}, {24, 17}, {15, 27} }
    for _, pt in ipairs(c1_tufts) do
        local bx, by = pt[1], pt[2]
        set_pixel(high_img, col, row, bx, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 1, by + 1, G_DARK)
        -- Clustered companion blade
        set_pixel(high_img, col, row, bx + 2, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx + 2, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 3, by + 1, G_DARK)
    end

    -- Col 2: Grass Variant B (Summer clover & tiny pale wildflowers)
    col = 2
    local c2_tufts = { {7, 10}, {21, 8}, {13, 18}, {25, 24} }
    for _, pt in ipairs(c2_tufts) do
        local bx, by = pt[1], pt[2]
        set_pixel(high_img, col, row, bx, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 1, by + 1, G_DARK)
    end
    -- Clover cluster 1
    set_pixel(detail_img, col, row, 18, 14, G_SUN)
    set_pixel(detail_img, col, row, 19, 13, G_LIGHT)
    set_pixel(detail_img, col, row, 20, 14, G_SUN)
    set_pixel(detail_img, col, row, 19, 15, G_DARK)
    -- Tiny wildflower
    set_pixel(high_img, col, row, 8, 23, G_FLOWER)
    set_pixel(detail_img, col, row, 9, 23, G_FLOWER_CORE)
    set_pixel(detail_img, col, row, 8, 24, G_SHADOW)

    -- Col 3: Grass Variant C (Wind-bent blades)
    col = 3
    local c3_tufts = { {5, 6}, {19, 10}, {11, 16}, {26, 18}, {7, 24}, {18, 26} }
    for _, pt in ipairs(c3_tufts) do
        local bx, by = pt[1], pt[2]
        set_pixel(high_img, col, row, bx + 1, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 1, by, G_SUN)
        set_pixel(detail_img, col, row, bx + 2, by + 1, G_DARK)
    end

    -- Col 4: Grass Variant D (Alluvial soil clod & river pebble peek)
    col = 4
    local c4_tufts = { {9, 7}, {23, 9}, {8, 23}, {24, 21} }
    for _, pt in ipairs(c4_tufts) do
        local bx, by = pt[1], pt[2]
        set_pixel(high_img, col, row, bx, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 1, by + 1, G_DARK)
    end
    -- Exposed soil clod
    set_pixel(detail_img, col, row, 16, 15, D_LIGHT)
    set_pixel(detail_img, col, row, 17, 15, D_BASE)
    set_pixel(detail_img, col, row, 16, 16, D_DARK)
    set_pixel(detail_img, col, row, 17, 16, D_DEEP)
    -- Pebble
    set_pixel(high_img, col, row, 14, 14, D_PEBBLE_HI)
    set_pixel(detail_img, col, row, 15, 14, D_PEBBLE_SHAD)

    -- Col 5: Grass Variant E (Wild grass stalk / Cỏ lác cạn)
    col = 5
    local c5_tufts = { {6, 11}, {21, 6}, {13, 22}, {25, 17} }
    for _, pt in ipairs(c5_tufts) do
        local bx, by = pt[1], pt[2]
        set_pixel(high_img, col, row, bx, by - 1, G_TIP)
        set_pixel(detail_img, col, row, bx, by, G_LIGHT)
        set_pixel(detail_img, col, row, bx + 1, by + 1, G_DARK)
    end
    -- Taller stalks
    for sy = 0, 3 do
        set_pixel(detail_img, col, row, 16, 12 + sy, G_LIGHT)
        set_pixel(detail_img, col, row, 17, 13 + sy, G_DARK)
    end
    set_pixel(high_img, col, row, 16, 11, G_TIP)

    -- Col 6: Grass Variant F (Dual clover patches)
    col = 6
    local c6_clovers = { {8, 9}, {22, 20} }
    for _, clv in ipairs(c6_clovers) do
        local cx, cy = clv[1], clv[2]
        set_pixel(detail_img, col, row, cx - 1, cy, G_SUN)
        set_pixel(high_img, col, row, cx, cy - 1, G_LIGHT)
        set_pixel(detail_img, col, row, cx + 1, cy, G_SUN)
        set_pixel(detail_img, col, row, cx, cy + 1, G_DARK)
    end

    -- Col 7: Grass Variant G (Fine floral meadow: white/yellow wildflower clusters)
    col = 7
    local flowers = { {6, 8, G_FLOWER}, {20, 10, G_FLOWER_W}, {11, 23, G_FLOWER}, {25, 21, G_FLOWER_W} }
    for _, fl in ipairs(flowers) do
        local fx, fy, color = fl[1], fl[2], fl[3]
        set_pixel(high_img, col, row, fx, fy, color)
        set_pixel(detail_img, col, row, fx + 1, fy, G_FLOWER_CORE)
        set_pixel(detail_img, col, row, fx, fy + 1, G_SHADOW)
    end
end

-- ----------------------------------------------------------------------------
-- ROW 1: ĐƯỜNG ĐẤT PHÙ SA & GẠCH NUNG LỆCH (ALLUVIAL LOAM & TERRACOTTA BRICKS)
-- ----------------------------------------------------------------------------
local function generate_row1_dirt(base_img, detail_img, high_img, rng)
    local row = 1
    -- Fill base layer with rich reddish brown alluvial soil
    for col = 0, 7 do
        draw_rect(base_img, col, row, 0, 0, 31, 31, D_BASE)
        -- Micro-crust texture
        for _ = 1, 35 do
            local x = rng:random(1, 30)
            local y = rng:random(1, 30)
            local t = rng:random(1, 2) == 1 and D_LIGHT or D_DARK
            set_pixel(base_img, col, row, x, y, t)
        end
    end

    -- Col 0: Pure Dirt Base (smooth crumbly alluvial soil, seamless)
    local col = 0
    for _ = 1, 25 do
        local x = rng:random(2, 29)
        local y = rng:random(2, 29)
        set_pixel(detail_img, col, row, x, y, D_LIGHT)
        set_pixel(detail_img, col, row, x + 1, y + 1, D_DARK)
    end

    -- Col 1: Dirt Footpath (compacted central path with fine dust)
    col = 1
    for y = 0, 31 do
        set_pixel(detail_img, col, row, 15, y, D_FINE)
        set_pixel(detail_img, col, row, 16, y, D_LIGHT)
        if y % 3 == 0 then
            set_pixel(detail_img, col, row, 14, y, D_DARK)
            set_pixel(detail_img, col, row, 17, y, D_DARK)
        end
    end

    -- Helper to draw an embedded crooked terracotta brick (gạch nung lệch)
    local function draw_brick(c, bx, by, bw, bh, angle_type)
        -- Depression / shadow underneath the brick
        draw_rect(detail_img, c, row, bx - 1, by - 1, bx + bw + 1, by + bh + 1, D_DEEP)
        -- Brick body
        draw_rect(detail_img, c, row, bx, by, bx + bw, by + bh, BRICK_BASE)
        -- Top & Left chamfer highlight
        for x = bx, bx + bw do
            set_pixel(high_img, c, row, x, by, BRICK_HI)
        end
        for y = by, by + bh do
            set_pixel(high_img, c, row, bx, y, BRICK_HI)
        end
        -- Bottom & Right edge shadow
        for x = bx, bx + bw do
            set_pixel(detail_img, c, row, x, by + bh, BRICK_SHAD)
        end
        for y = by, by + bh do
            set_pixel(detail_img, c, row, bx + bw, y, BRICK_SHAD)
        end
        -- Silt / mud dust caked on brick
        if angle_type == 1 then
            set_pixel(detail_img, c, row, bx + 2, by + 1, BRICK_MUD)
            set_pixel(detail_img, c, row, bx + 3, by + 1, BRICK_MUD)
            set_pixel(detail_img, c, row, bx + 1, by + 2, BRICK_PIT)
        else
            set_pixel(detail_img, c, row, bx + bw - 2, by + bh - 1, BRICK_MUD)
            set_pixel(detail_img, c, row, bx + bw - 1, by + bh - 2, BRICK_PIT)
        end
    end

    -- Col 2: Dirt with 1 Crooked Terracotta Brick (1 viên gạch nung lệch Bắc Ninh)
    col = 2
    draw_brick(col, 10, 12, 11, 7, 1)

    -- Col 3: Dirt with 2 Broken Terracotta Bricks (2 mảnh gạch nung)
    col = 3
    draw_brick(col, 5, 6, 8, 5, 2)
    draw_brick(col, 17, 18, 9, 6, 1)

    -- Col 4: Dirt with Stepping Brick Course (Hàng gạch bước chân)
    col = 4
    draw_brick(col, 7, 8, 10, 6, 1)
    draw_brick(col, 14, 18, 10, 6, 2)

    -- Col 5: Dirt with Clustered River Pebbles (Sỏi suối mịn)
    col = 5
    local pebbles = { {6, 8}, {20, 7}, {13, 17}, {8, 25}, {23, 23} }
    for _, pb in ipairs(pebbles) do
        local px, py = pb[1], pb[2]
        set_pixel(high_img, col, row, px, py, D_PEBBLE_HI)
        set_pixel(detail_img, col, row, px + 1, py, D_LIGHT)
        set_pixel(detail_img, col, row, px, py + 1, D_DARK)
        set_pixel(detail_img, col, row, px + 1, py + 1, D_PEBBLE_SHAD)
    end

    -- Col 6: Dirt Clod Patch (Cụm đất tơi xốp)
    col = 6
    for y = 4, 27, 4 do
        for x = 4, 27, 4 do
            set_pixel(high_img, col, row, x, y, D_FINE)
            set_pixel(detail_img, col, row, x + 1, y, D_LIGHT)
            set_pixel(detail_img, col, row, x, y + 1, D_DARK)
            set_pixel(detail_img, col, row, x + 1, y + 1, D_DEEP)
        end
    end

    -- Col 7: Cart Rut / Wheel Impression (Vệt bánh xe lún nhẹ)
    col = 7
    for y = 0, 31 do
        set_pixel(detail_img, col, row, 12, y, D_FINE)
        set_pixel(detail_img, col, row, 13, y, D_DEEP)
        set_pixel(detail_img, col, row, 14, y, D_DARK)
        set_pixel(detail_img, col, row, 15, y, D_LIGHT)
    end
end

-- ----------------------------------------------------------------------------
-- ROW 2: ĐƯỜNG ĐẤT - CỎ: MÉP THẲNG & GÓC NGOÀI (STRAIGHT EDGES & OUTER CORNERS)
-- ----------------------------------------------------------------------------
local function generate_row2_dirt_edges(base_img, detail_img, high_img, rng)
    local row = 2

    -- Helper to draw organic grass overhang onto dirt
    local function draw_grass_overhang_h(c, boundary_y, is_north)
        for x = 0, 31 do
            local offset = (math.sin(x * 0.7) * 2 + (x % 3))
            local by = math.floor(boundary_y + offset)
            if is_north then
                for y = 0, by do set_pixel(base_img, c, row, x, y, G_BASE) end
                for y = by + 1, 31 do set_pixel(base_img, c, row, x, y, D_BASE) end
                -- Grass blade tips poking down
                set_pixel(high_img, c, row, x, by, G_TIP)
                set_pixel(detail_img, c, row, x, by + 1, G_DARK)
                set_pixel(detail_img, c, row, x, by + 2, D_DEEP)
            else
                for y = 0, by do set_pixel(base_img, c, row, x, y, D_BASE) end
                for y = by + 1, 31 do set_pixel(base_img, c, row, x, y, G_BASE) end
                -- Blades rising up
                set_pixel(high_img, c, row, x, by + 1, G_TIP)
                set_pixel(detail_img, c, row, x, by, D_DARK)
            end
        end
    end

    local function draw_grass_overhang_v(c, boundary_x, is_west)
        for y = 0, 31 do
            local offset = (math.cos(y * 0.6) * 2 + (y % 3))
            local bx = math.floor(boundary_x + offset)
            if is_west then
                for x = 0, bx do set_pixel(base_img, c, row, x, y, G_BASE) end
                for x = bx + 1, 31 do set_pixel(base_img, c, row, x, y, D_BASE) end
                set_pixel(high_img, c, row, bx, y, G_TIP)
                set_pixel(detail_img, c, row, bx + 1, y, D_DEEP)
            else
                for x = 0, bx do set_pixel(base_img, c, row, x, y, D_BASE) end
                for x = bx + 1, 31 do set_pixel(base_img, c, row, x, y, G_BASE) end
                set_pixel(high_img, c, row, bx + 1, y, G_TIP)
                set_pixel(detail_img, c, row, bx, y, D_DARK)
            end
        end
    end

    -- Col 0: Edge North (Cỏ trên y <= 11, Đất dưới y >= 12)
    draw_grass_overhang_h(0, 11, true)
    -- Col 1: Edge South (Đất trên y <= 19, Cỏ dưới y >= 20)
    draw_grass_overhang_h(1, 19, false)
    -- Col 2: Edge West (Cỏ trái x <= 11, Đất phải x >= 12)
    draw_grass_overhang_v(2, 11, true)
    -- Col 3: Edge East (Đất trái x <= 19, Cỏ phải x >= 20)
    draw_grass_overhang_v(3, 19, false)

    -- Outer Corners: Grass on outside corner, Dirt on inside
    local function draw_outer_corner(c, corner_type)
        for y = 0, 31 do
            for x = 0, 31 do
                local d = 0
                if corner_type == "TL" then
                    d = math.sqrt(x * x + y * y)
                elseif corner_type == "TR" then
                    d = math.sqrt((31 - x) * (31 - x) + y * y)
                elseif corner_type == "BL" then
                    d = math.sqrt(x * x + (31 - y) * (31 - y))
                elseif corner_type == "BR" then
                    d = math.sqrt((31 - x) * (31 - x) + (31 - y) * (31 - y))
                end

                if d < 18 then
                    set_pixel(base_img, c, row, x, y, G_BASE)
                else
                    set_pixel(base_img, c, row, x, y, D_BASE)
                end
                -- Rim transition
                if math.abs(d - 18) < 1.0 then
                    set_pixel(high_img, c, row, x, y, G_TIP)
                elseif d >= 18 and d < 20 then
                    set_pixel(detail_img, c, row, x, y, D_DEEP)
                end
            end
        end
    end

    draw_outer_corner(4, "TL") -- Col 4: Outer TL
    draw_outer_corner(5, "TR") -- Col 5: Outer TR
    draw_outer_corner(6, "BL") -- Col 6: Outer BL
    draw_outer_corner(7, "BR") -- Col 7: Outer BR
end

-- ----------------------------------------------------------------------------
-- ROW 3: ĐƯỜNG ĐẤT - CỎ: GÓC LÕM & LỐI ĐI HẸP (INNER CORNERS & THIN PATHS)
-- ----------------------------------------------------------------------------
local function generate_row3_dirt_inner(base_img, detail_img, high_img, rng)
    local row = 3

    -- Inner Corners: Dirt covers tile, Grass bites into one corner
    local function draw_inner_corner(c, corner_type)
        for y = 0, 31 do
            for x = 0, 31 do
                set_pixel(base_img, c, row, x, y, D_BASE)
                local d = 0
                if corner_type == "TL" then
                    d = math.sqrt(x * x + y * y)
                elseif corner_type == "TR" then
                    d = math.sqrt((31 - x) * (31 - x) + y * y)
                elseif corner_type == "BL" then
                    d = math.sqrt(x * x + (31 - y) * (31 - y))
                elseif corner_type == "BR" then
                    d = math.sqrt((31 - x) * (31 - x) + (31 - y) * (31 - y))
                end

                if d < 11 then
                    set_pixel(base_img, c, row, x, y, G_BASE)
                end
                if math.abs(d - 11) < 1.0 then
                    set_pixel(high_img, c, row, x, y, G_TIP)
                elseif d >= 11 and d < 13 then
                    set_pixel(detail_img, c, row, x, y, D_DEEP)
                end
            end
        end
    end

    draw_inner_corner(0, "TL") -- Col 0: Inner TL
    draw_inner_corner(1, "TR") -- Col 1: Inner TR
    draw_inner_corner(2, "BL") -- Col 2: Inner BL
    draw_inner_corner(3, "BR") -- Col 3: Inner BR

    -- Col 4: Thin Horizontal Path (Grass top & bottom, Dirt middle)
    local col = 4
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 7 or y >= 24 then
                set_pixel(base_img, col, row, x, y, G_BASE)
            else
                set_pixel(base_img, col, row, x, y, D_BASE)
            end
        end
    end
    for x = 0, 31 do
        set_pixel(high_img, col, row, x, 7, G_TIP)
        set_pixel(detail_img, col, row, x, 8, D_DEEP)
        set_pixel(high_img, col, row, x, 24, G_TIP)
    end

    -- Col 5: Thin Vertical Path (Grass left & right, Dirt middle)
    col = 5
    for y = 0, 31 do
        for x = 0, 31 do
            if x <= 7 or x >= 24 then
                set_pixel(base_img, col, row, x, y, G_BASE)
            else
                set_pixel(base_img, col, row, x, y, D_BASE)
            end
        end
    end
    for y = 0, 31 do
        set_pixel(high_img, col, row, 7, y, G_TIP)
        set_pixel(detail_img, col, row, 8, y, D_DEEP)
        set_pixel(high_img, col, row, 24, y, G_TIP)
    end

    -- Col 6: Path End Cap North (Tận cùng lối đi hướng Bắc, bo tròn vào cỏ)
    col = 6
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, row, x, y, G_BASE)
            if y >= 10 and x >= 6 and x <= 25 then
                local dx = math.abs(x - 15.5)
                local dy = y - 10
                if dy >= 6 or (dx * dx + (6 - dy) * (6 - dy) <= 36) then
                    set_pixel(base_img, col, row, x, y, D_BASE)
                end
            end
        end
    end

    -- Col 7: Path End Cap South (Tận cùng lối đi hướng Nam, bo tròn vào cỏ)
    col = 7
    for y = 0, 31 do
        for x = 0, 31 do
            set_pixel(base_img, col, row, x, y, G_BASE)
            if y <= 21 and x >= 6 and x <= 25 then
                local dx = math.abs(x - 15.5)
                local dy = 21 - y
                if dy >= 6 or (dx * dx + (6 - dy) * (6 - dy) <= 36) then
                    set_pixel(base_img, col, row, x, y, D_BASE)
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- ROW 4: LUỐNG KHÔ BẮC NINH (DRY FURROWS: RÃNH NGẮN LỆCH NHỊP)
-- ----------------------------------------------------------------------------
local function generate_row4_dry_furrows(base_img, detail_img, high_img, rng)
    local row = 4

    -- Helper to draw dry furrow stripes with staggered short trenches (rãnh ngắn lệch nhịp)
    local function draw_dry_furrow_center(c, shift_x)
        for y = 0, 31 do
            local band = math.floor(y / 8)
            local fy = y % 8
            local base_tone = F_DRY_RIDGE
            if fy == 0 or fy == 1 then
                base_tone = F_DRY_TRENCH
            elseif fy == 2 or fy == 3 or fy == 4 then
                base_tone = F_DRY_CRUST
            else
                base_tone = F_DRY_SLOPE
            end
            for x = 0, 31 do
                set_pixel(base_img, c, row, x, y, base_tone)
            end
        end

        -- Detail & Highlight layers: Short, staggered rhythm
        for band = 0, 3 do
            local by = band * 8
            local offset_band = (band * 7 + shift_x) % 16

            for x = 0, 31 do
                local phase = (x + offset_band) % 16
                -- Short trench pocket: only deep shadow for 9 pixels, then soil bridge
                if phase < 9 then
                    set_pixel(detail_img, c, row, x, by + 0, F_DRY_DEEP)
                    set_pixel(detail_img, c, row, x, by + 1, F_DRY_TRENCH)
                else
                    -- Clod bridge connecting furrows
                    set_pixel(detail_img, c, row, x, by + 1, F_DRY_RIDGE)
                end

                -- Ridge crest highlight
                if phase >= 2 and phase <= 12 then
                    set_pixel(high_img, c, row, x, by + 2, F_DRY_HI)
                    set_pixel(detail_img, c, row, x, by + 3, F_DRY_CRUST)
                end
            end

            -- Scattered sun-baked clods
            for x = 3, 28, 6 do
                local cx = (x + offset_band) % 32
                set_pixel(high_img, c, row, cx, by + 2, F_DRY_HI)
                set_pixel(detail_img, c, row, cx + 1, by + 3, F_DRY_SLOPE)
                set_pixel(detail_img, c, row, cx, by + 3, F_DRY_TRENCH)
            end
        end
    end

    draw_dry_furrow_center(0, 0) -- Col 0: Dry Furrow Center A
    draw_dry_furrow_center(1, 5) -- Col 1: Dry Furrow Center B (alternate stagger)

    -- Col 2: Dry Furrow Edge North (Transition to path/grass at top)
    local col = 2
    draw_dry_furrow_center(col, 2)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    for x = 0, 31 do
        set_pixel(high_img, col, row, x, 7, F_DRY_HI)
        set_pixel(detail_img, col, row, x, 6, D_DARK)
    end

    -- Col 3: Dry Furrow Edge South (Transition to path/grass at bottom)
    col = 3
    draw_dry_furrow_center(col, 4)
    draw_rect(base_img, col, row, 0, 26, 31, 31, D_BASE)
    for x = 0, 31 do
        set_pixel(detail_img, col, row, x, 25, F_DRY_DEEP)
        set_pixel(detail_img, col, row, x, 26, D_DARK)
    end

    -- Col 4: Dry Furrow Edge West (Furrow bed left head cap)
    col = 4
    draw_dry_furrow_center(col, 0)
    for y = 0, 31 do
        for x = 0, 6 do
            set_pixel(base_img, col, row, x, y, D_BASE)
        end
        set_pixel(high_img, col, row, 7, y, F_DRY_HI)
        set_pixel(detail_img, col, row, 6, y, D_DARK)
    end

    -- Col 5: Dry Furrow Edge East (Furrow bed right head cap)
    col = 5
    draw_dry_furrow_center(col, 3)
    for y = 0, 31 do
        for x = 25, 31 do
            set_pixel(base_img, col, row, x, y, D_BASE)
        end
        set_pixel(detail_img, col, row, 24, y, F_DRY_DEEP)
        set_pixel(detail_img, col, row, 25, y, D_DARK)
    end

    -- Col 6: Dry Furrow Corner TL
    col = 6
    draw_dry_furrow_center(col, 1)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    draw_rect(base_img, col, row, 0, 0, 6, 31, D_BASE)
    set_pixel(high_img, col, row, 7, 7, F_DRY_HI)

    -- Col 7: Dry Furrow Corner TR
    col = 7
    draw_dry_furrow_center(col, 3)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    draw_rect(base_img, col, row, 25, 0, 31, 31, D_BASE)
    set_pixel(detail_img, col, row, 24, 7, F_DRY_DEEP)
end

-- ----------------------------------------------------------------------------
-- ROW 5: LUỐNG ƯỚT BẮC NINH (WET FURROWS: ĐẤT SẪM, VỆT NƯỚC THƯA PHẢN CHIẾU)
-- ----------------------------------------------------------------------------
local function generate_row5_wet_furrows(base_img, detail_img, high_img, rng)
    local row = 5

    -- Helper for wet furrows: dark saturated mud with sparse specular sheen
    local function draw_wet_furrow_center(c, shift_x)
        for y = 0, 31 do
            local fy = y % 8
            local base_tone = F_WET_RIDGE
            if fy == 0 or fy == 1 then
                base_tone = F_WET_TRENCH
            elseif fy == 2 or fy == 3 or fy == 4 then
                base_tone = F_WET_RIDGE
            else
                base_tone = F_WET_SLOPE
            end
            for x = 0, 31 do
                set_pixel(base_img, c, row, x, y, base_tone)
            end
        end

        for band = 0, 3 do
            local by = band * 8
            local offset_band = (band * 9 + shift_x) % 16

            for x = 0, 31 do
                local phase = (x + offset_band) % 16
                -- Deep shadow trench
                set_pixel(detail_img, c, row, x, by + 0, F_WET_DEEP)

                -- Sparse specular water glints (vệt nước thưa)
                if phase == 4 or phase == 5 then
                    set_pixel(high_img, c, row, x, by + 1, F_WET_GLINT)
                elseif phase >= 2 and phase <= 7 then
                    set_pixel(detail_img, c, row, x, by + 1, F_WET_SHEEN)
                end

                -- Moist ridge clod sheen
                if phase == 11 then
                    set_pixel(high_img, c, row, x, by + 3, F_WET_SHEEN)
                end
            end
        end
    end

    draw_wet_furrow_center(0, 0) -- Col 0: Wet Furrow Center A
    draw_wet_furrow_center(1, 6) -- Col 1: Wet Furrow Center B (puddle variant)

    -- Col 2: Wet Furrow Edge North
    local col = 2
    draw_wet_furrow_center(col, 2)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    for x = 0, 31 do
        set_pixel(high_img, col, row, x, 7, F_WET_RIDGE)
        set_pixel(detail_img, col, row, x, 6, D_DARK)
    end

    -- Col 3: Wet Furrow Edge South
    col = 3
    draw_wet_furrow_center(col, 4)
    draw_rect(base_img, col, row, 0, 26, 31, 31, D_BASE)
    for x = 0, 31 do
        set_pixel(detail_img, col, row, x, 25, F_WET_DEEP)
    end

    -- Col 4: Wet Furrow Edge West
    col = 4
    draw_wet_furrow_center(col, 0)
    for y = 0, 31 do
        for x = 0, 6 do set_pixel(base_img, col, row, x, y, D_BASE) end
        set_pixel(high_img, col, row, 7, y, F_WET_RIDGE)
    end

    -- Col 5: Wet Furrow Edge East
    col = 5
    draw_wet_furrow_center(col, 3)
    for y = 0, 31 do
        for x = 25, 31 do set_pixel(base_img, col, row, x, y, D_BASE) end
        set_pixel(detail_img, col, row, 24, y, F_WET_DEEP)
    end

    -- Col 6: Wet Furrow Corner TL
    col = 6
    draw_wet_furrow_center(col, 1)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    draw_rect(base_img, col, row, 0, 0, 6, 31, D_BASE)

    -- Col 7: Wet Furrow Corner TR
    col = 7
    draw_wet_furrow_center(col, 3)
    draw_rect(base_img, col, row, 0, 0, 31, 6, D_BASE)
    draw_rect(base_img, col, row, 25, 0, 31, 31, D_BASE)
end

-- ----------------------------------------------------------------------------
-- ROW 6: MẶT NƯỚC AO LÀNG XANH NGỌC XÁM (POND WATER & SURFACE RIPPLES)
-- ----------------------------------------------------------------------------
local function generate_row6_water(base_img, detail_img, high_img, rng)
    local row = 6
    -- Fill base layer with calm grayish-teal water
    for col = 0, 7 do
        draw_rect(base_img, col, row, 0, 0, 31, 31, W_BASE)
    end

    -- Helper to draw wavelets
    local function draw_wavelets(c, rows_data)
        for _, wv in ipairs(rows_data) do
            local ry, len, sx = wv[1], wv[2], wv[3]
            for i = 0, len - 1 do
                local wx = (sx + i) % 32
                if i > 1 and i < len - 2 then
                    set_pixel(high_img, c, row, wx, ry, W_CREST)
                    if i == math.floor(len / 2) then
                        set_pixel(high_img, c, row, wx, ry, W_GLINT)
                    end
                else
                    set_pixel(detail_img, c, row, wx, ry, W_RIPPLE)
                end
                set_pixel(detail_img, c, row, wx, (ry + 1) % 32, W_DEEP)
            end
        end
    end

    -- Col 0: Calm Deep Water (Subtle deep tone)
    local col = 0
    draw_wavelets(col, { {8, 8, 4}, {22, 9, 18} })

    -- Col 1: Water Wavelet A
    col = 1
    draw_wavelets(col, { {5, 12, 2}, {13, 14, 16}, {21, 10, 6}, {27, 12, 18} })

    -- Col 2: Water Wavelet B (Alternate wavelets with glints)
    col = 2
    draw_wavelets(col, { {4, 14, 14}, {11, 11, 2}, {18, 16, 12}, {26, 10, 22} })

    -- Col 3: Water with Floating Duckweed (Bèo tấm ao quê)
    col = 3
    draw_wavelets(col, { {6, 10, 4}, {24, 10, 16} })
    local weed_clusters = { {12, 14}, {13, 14}, {12, 15}, {22, 18}, {23, 17}, {8, 25} }
    for _, dw in ipairs(weed_clusters) do
        local dx, dy = dw[1], dw[2]
        set_pixel(detail_img, col, row, dx, dy, W_DUCKWEED)
        set_pixel(high_img, col, row, dx, dy - 1, W_DUCK_CORE)
        set_pixel(detail_img, col, row, dx, dy + 1, W_DEEP)
    end

    -- Col 4: Water with Water Lily Pad (Lá súng non)
    col = 4
    draw_wavelets(col, { {5, 10, 18}, {25, 12, 4} })
    -- Draw 6x5 lily pad
    local pad_pts = {
        {15, 13}, {16, 13}, {17, 13},
        {14, 14}, {15, 14}, {17, 14}, {18, 14}, -- notch at 16, 14
        {14, 15}, {15, 15}, {16, 15}, {17, 15}, {18, 15},
        {15, 16}, {16, 16}, {17, 16}
    }
    for _, pt in ipairs(pad_pts) do
        set_pixel(detail_img, col, row, pt[1], pt[2], W_LILY_PAD)
    end
    set_pixel(high_img, col, row, 15, 13, W_LILY_EDGE)
    set_pixel(high_img, col, row, 17, 13, W_LILY_EDGE)
    set_pixel(detail_img, col, row, 16, 17, W_DEEP)

    -- Col 5: Water Shallows (Nước nông ven bờ, ánh phù sa)
    col = 5
    for y = 0, 31 do
        for x = 0, 31 do
            if (x + y) % 3 == 0 then
                set_pixel(base_img, col, row, x, y, W_SHALLOW)
            end
        end
    end
    draw_wavelets(col, { {7, 12, 8}, {20, 14, 14} })

    -- Col 6: Submerged Mud Shelf (Thềm bùn dưới nước)
    col = 6
    draw_wavelets(col, { {9, 14, 2}, {19, 12, 16} })
    for y = 14, 18 do
        for x = 6, 26 do
            set_pixel(detail_img, col, row, x, y, BANK_WET)
        end
    end

    -- Col 7: Wavelet C (Gió hè lăn tăn)
    col = 7
    draw_wavelets(col, { {6, 16, 0}, {14, 14, 10}, {22, 16, 16}, {29, 12, 6} })
end

-- ----------------------------------------------------------------------------
-- ROW 7: BỜ AO THẤP CÓ CỎ LÁC (LOW POND BANK WITH SEDGE REEDS)
-- ----------------------------------------------------------------------------
local function generate_row7_pond_bank(base_img, detail_img, high_img, rng)
    local row = 7

    -- Col 0: Bank North (Bờ phía Bắc: Cỏ/đất ở trên y<=15, bùn nước ở dưới y>=16)
    local col = 0
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 11 then
                set_pixel(base_img, col, row, x, y, G_BASE)
            elseif y <= 14 then
                set_pixel(base_img, col, row, x, y, BANK_EARTH)
            elseif y <= 17 then
                set_pixel(base_img, col, row, x, y, BANK_MUD)
            elseif y <= 19 then
                set_pixel(base_img, col, row, x, y, BANK_WET)
            else
                set_pixel(base_img, col, row, x, y, W_BASE)
            end
        end
    end
    -- Sedge tufts (Cỏ lác) drooping down over water
    for x = 2, 29, 5 do
        set_pixel(detail_img, col, row, x, 14, REED_BASE)
        set_pixel(high_img, col, row, x, 15, REED_MID)
        set_pixel(high_img, col, row, x + 1, 16, REED_TIP)
        set_pixel(detail_img, col, row, x + 1, 18, REED_SHAD)
    end
    -- Water lap foam
    for x = 0, 31 do
        if x % 3 ~= 0 then set_pixel(high_img, col, row, x, 19, BANK_LAP) end
    end

    -- Col 1: Bank South (Bờ phía Nam: Nước ở trên y<=13, bùn cỏ ở dưới y>=14)
    col = 1
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 12 then
                set_pixel(base_img, col, row, x, y, W_BASE)
            elseif y <= 14 then
                set_pixel(base_img, col, row, x, y, BANK_WET)
            elseif y <= 17 then
                set_pixel(base_img, col, row, x, y, BANK_MUD)
            elseif y <= 21 then
                set_pixel(base_img, col, row, x, y, BANK_EARTH)
            else
                set_pixel(base_img, col, row, x, y, G_BASE)
            end
        end
    end
    -- Lap line and reeds
    for x = 0, 31 do
        if x % 4 ~= 0 then set_pixel(high_img, col, row, x, 13, BANK_LAP) end
    end
    for x = 3, 28, 6 do
        set_pixel(high_img, col, row, x, 15, REED_TIP)
        set_pixel(detail_img, col, row, x, 16, REED_MID)
        set_pixel(detail_img, col, row, x, 17, REED_BASE)
    end

    -- Col 2: Bank West (Bờ phía Tây: Cỏ/đất bên trái x<=14, Nước bên phải x>=15)
    col = 2
    for y = 0, 31 do
        for x = 0, 31 do
            if x <= 10 then
                set_pixel(base_img, col, row, x, y, G_BASE)
            elseif x <= 13 then
                set_pixel(base_img, col, row, x, y, BANK_EARTH)
            elseif x <= 15 then
                set_pixel(base_img, col, row, x, y, BANK_MUD)
            elseif x <= 17 then
                set_pixel(base_img, col, row, x, y, BANK_WET)
            else
                set_pixel(base_img, col, row, x, y, W_BASE)
            end
        end
    end
    for y = 2, 29, 6 do
        set_pixel(detail_img, col, row, 13, y, REED_BASE)
        set_pixel(high_img, col, row, 14, y, REED_MID)
        set_pixel(high_img, col, row, 16, y + 1, REED_TIP)
        set_pixel(detail_img, col, row, 16, y + 2, REED_SHAD)
    end
    for y = 0, 31 do
        if y % 3 ~= 0 then set_pixel(high_img, col, row, 17, y, BANK_LAP) end
    end

    -- Col 3: Bank East (Bờ phía Đông: Nước bên trái x<=15, Cỏ/đất bên phải x>=16)
    col = 3
    for y = 0, 31 do
        for x = 0, 31 do
            if x <= 14 then
                set_pixel(base_img, col, row, x, y, W_BASE)
            elseif x <= 16 then
                set_pixel(base_img, col, row, x, y, BANK_WET)
            elseif x <= 19 then
                set_pixel(base_img, col, row, x, y, BANK_MUD)
            elseif x <= 22 then
                set_pixel(base_img, col, row, x, y, BANK_EARTH)
            else
                set_pixel(base_img, col, row, x, y, G_BASE)
            end
        end
    end
    for y = 0, 31 do
        if y % 4 ~= 0 then set_pixel(high_img, col, row, 15, y, BANK_LAP) end
    end
    for y = 4, 28, 6 do
        set_pixel(high_img, col, row, 17, y, REED_TIP)
        set_pixel(detail_img, col, row, 18, y, REED_MID)
        set_pixel(detail_img, col, row, 19, y, REED_BASE)
    end

    -- Outer Corners: Earth outside, Water inside
    local function draw_bank_outer(c, corner_type)
        for y = 0, 31 do
            for x = 0, 31 do
                local d = 0
                if corner_type == "TL" then
                    d = math.sqrt(x * x + y * y)
                elseif corner_type == "TR" then
                    d = math.sqrt((31 - x) * (31 - x) + y * y)
                elseif corner_type == "BL" then
                    d = math.sqrt(x * x + (31 - y) * (31 - y))
                elseif corner_type == "BR" then
                    d = math.sqrt((31 - x) * (31 - x) + (31 - y) * (31 - y))
                end

                if d < 12 then
                    set_pixel(base_img, c, row, x, y, G_BASE)
                elseif d < 16 then
                    set_pixel(base_img, c, row, x, y, BANK_EARTH)
                elseif d < 19 then
                    set_pixel(base_img, c, row, x, y, BANK_MUD)
                elseif d < 22 then
                    set_pixel(base_img, c, row, x, y, BANK_WET)
                else
                    set_pixel(base_img, c, row, x, y, W_BASE)
                end

                if math.abs(d - 22) < 1.0 then
                    set_pixel(high_img, c, row, x, y, BANK_LAP)
                end
            end
        end
    end

    draw_bank_outer(4, "TL") -- Col 4: Bank Outer TL
    draw_bank_outer(5, "TR") -- Col 5: Bank Outer TR
    draw_bank_outer(6, "BL") -- Col 6: Bank Outer BL
    draw_bank_outer(7, "BR") -- Col 7: Bank Outer BR
end

-- ----------------------------------------------------------------------------
-- ROW 8: BỜ AO CHI TIẾT (INNER CORNERS, DENSE SEDGE & STEPPING STONE)
-- ----------------------------------------------------------------------------
local function generate_row8_bank_details(base_img, detail_img, high_img, rng)
    local row = 8

    -- Bank Inner Corners: Water pockets into one corner
    local function draw_bank_inner(c, corner_type)
        for y = 0, 31 do
            for x = 0, 31 do
                set_pixel(base_img, c, row, x, y, G_BASE)
                local d = 0
                if corner_type == "TL" then
                    d = math.sqrt(x * x + y * y)
                elseif corner_type == "TR" then
                    d = math.sqrt((31 - x) * (31 - x) + y * y)
                elseif corner_type == "BL" then
                    d = math.sqrt(x * x + (31 - y) * (31 - y))
                elseif corner_type == "BR" then
                    d = math.sqrt((31 - x) * (31 - x) + (31 - y) * (31 - y))
                end

                if d < 11 then
                    set_pixel(base_img, c, row, x, y, W_BASE)
                elseif d < 14 then
                    set_pixel(base_img, c, row, x, y, BANK_WET)
                elseif d < 17 then
                    set_pixel(base_img, c, row, x, y, BANK_MUD)
                elseif d < 20 then
                    set_pixel(base_img, c, row, x, y, BANK_EARTH)
                end

                if math.abs(d - 11) < 1.0 then
                    set_pixel(high_img, c, row, x, y, BANK_LAP)
                end
            end
        end
    end

    draw_bank_inner(0, "TL") -- Col 0: Bank Inner TL
    draw_bank_inner(1, "TR") -- Col 1: Bank Inner TR
    draw_bank_inner(2, "BL") -- Col 2: Bank Inner BL
    draw_bank_inner(3, "BR") -- Col 3: Bank Inner BR

    -- Col 4: Bank North Variant with Dense Sedge (Cỏ lác dày ven bờ ao)
    local col = 4
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 12 then set_pixel(base_img, col, row, x, y, G_BASE)
            elseif y <= 15 then set_pixel(base_img, col, row, x, y, BANK_EARTH)
            elseif y <= 18 then set_pixel(base_img, col, row, x, y, BANK_MUD)
            else set_pixel(base_img, col, row, x, y, W_BASE) end
        end
    end
    for x = 1, 30, 3 do
        set_pixel(detail_img, col, row, x, 13, REED_BASE)
        set_pixel(high_img, col, row, x, 14, REED_MID)
        set_pixel(high_img, col, row, x + (x % 2 == 0 and 1 or -1), 16, REED_TIP)
        set_pixel(detail_img, col, row, x + 1, 18, REED_SHAD)
    end

    -- Col 5: Bank West with Stepping Stone (Phiến đá cầu ao rửa chân)
    col = 5
    for y = 0, 31 do
        for x = 0, 31 do
            if x <= 10 then set_pixel(base_img, col, row, x, y, G_BASE)
            elseif x <= 13 then set_pixel(base_img, col, row, x, y, BANK_EARTH)
            elseif x <= 16 then set_pixel(base_img, col, row, x, y, BANK_MUD)
            else set_pixel(base_img, col, row, x, y, W_BASE) end
        end
    end
    -- Flat river stone slab protruding into water (x = 11..22, y = 11..20)
    draw_rect(detail_img, col, row, 11, 12, 22, 20, STONE_BASE)
    for x = 11, 22 do
        set_pixel(high_img, col, row, x, 12, STONE_HI)
        set_pixel(detail_img, col, row, x, 20, STONE_SHAD)
    end
    for y = 12, 20 do
        set_pixel(high_img, col, row, 11, y, STONE_HI)
        set_pixel(detail_img, col, row, 22, y, STONE_SHAD)
    end
    -- Submerged stone shadow
    for x = 14, 23 do set_pixel(detail_img, col, row, x, 21, W_DEEP) end

    -- Col 6: Low Submerged Mud Slope (Dốc bùn thoai thoải ngập nước)
    col = 6
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 8 then set_pixel(base_img, col, row, x, y, BANK_EARTH)
            elseif y <= 16 then set_pixel(base_img, col, row, x, y, BANK_MUD)
            elseif y <= 24 then set_pixel(base_img, col, row, x, y, BANK_WET)
            else set_pixel(base_img, col, row, x, y, W_BASE) end
        end
    end
    for x = 0, 31 do
        if x % 3 ~= 0 then set_pixel(high_img, col, row, x, 24, BANK_LAP) end
    end

    -- Col 7: Shoreline Water Lap Foam (Vệt bọt nước vỗ bờ)
    col = 7
    for y = 0, 31 do
        for x = 0, 31 do
            if y <= 14 then set_pixel(base_img, col, row, x, y, W_BASE)
            elseif y <= 18 then set_pixel(base_img, col, row, x, y, BANK_WET)
            else set_pixel(base_img, col, row, x, y, BANK_MUD) end
        end
    end
    for x = 0, 31 do
        set_pixel(high_img, col, row, x, 14, BANK_LAP)
        if x % 2 == 0 then set_pixel(high_img, col, row, x, 13, W_CREST) end
    end
end

-- ============================================================================
-- ATLAS EXPORT FUNCTION (MULTI-LAYER ASEPRITE & FLAT PNG)
-- ============================================================================
local function build_atlas(rng)
    local spr = Sprite(256, 288, ColorMode.RGB)
    local base_layer = spr.layers[1]
    base_layer.name = "base"

    local detail_layer = spr:newLayer()
    detail_layer.name = "detail"

    local high_layer = spr:newLayer()
    high_layer.name = "highlights"

    local frame = spr.frames[1]
    local base_cel = base_layer:cel(frame) or spr:newCel(base_layer, frame)
    local detail_cel = detail_layer:cel(frame) or spr:newCel(detail_layer, frame)
    local high_cel = high_layer:cel(frame) or spr:newCel(high_layer, frame)

    local base_img = base_cel.image
    local detail_img = detail_cel.image
    local high_img = high_cel.image

    detail_img:clear(rgba(0, 0, 0, 0))
    high_img:clear(rgba(0, 0, 0, 0))

    -- Generate all 9 rows
    generate_row0_grass(base_img, detail_img, high_img, rng)
    generate_row1_dirt(base_img, detail_img, high_img, rng)
    generate_row2_dirt_edges(base_img, detail_img, high_img, rng)
    generate_row3_dirt_inner(base_img, detail_img, high_img, rng)
    generate_row4_dry_furrows(base_img, detail_img, high_img, rng)
    generate_row5_wet_furrows(base_img, detail_img, high_img, rng)
    generate_row6_water(base_img, detail_img, high_img, rng)
    generate_row7_pond_bank(base_img, detail_img, high_img, rng)
    generate_row8_bank_details(base_img, detail_img, high_img, rng)

    -- Composite flat image for preview extraction
    local flat_atlas = Image(256, 288, ColorMode.RGB)
    flat_atlas:clear(rgba(0, 0, 0, 0))
    flat_atlas:drawImage(base_img, Point(0, 0))
    flat_atlas:drawImage(detail_img, Point(0, 0))
    flat_atlas:drawImage(high_img, Point(0, 0))

    return spr, flat_atlas
end

-- ============================================================================
-- PLAYER SPRITE FRAME LOADER (32x48 FRONT IDLE WITH PROCEDURAL FALLBACK)
-- ============================================================================
local function load_player_frame(project_dir)
    local candidate_paths = {
        join_path(project_dir, "assets/art/32/player.png"),
        join_path(project_dir, "player.png"),
        "assets/art/32/player.png",
        "D:/DuAnLinhTinh/GameNongTrai/assets/art/32/player.png",
        "D:\\DuAnLinhTinh\\GameNongTrai\\assets\\art\\32\\player.png"
    }

    local player_img = nil

    for _, path in ipairs(candidate_paths) do
        local ok, spr = pcall(function() return app.open(path) end)
        if ok and spr then
            player_img = Image(32, 48, ColorMode.RGB)
            player_img:clear(rgba(0, 0, 0, 0))
            local full = Image(spr.width, spr.height, ColorMode.RGB)
            full:clear(rgba(0, 0, 0, 0))
            for _, layer in ipairs(spr.layers) do
                if layer.isVisible then
                    local c = layer:cel(spr.frames[1])
                    if c then full:drawImage(c.image, c.position) end
                end
            end
            -- Frame 0 in player.png is front idle at (0, 0, 32, 48)
            for y = 0, 47 do
                for x = 0, 31 do
                    player_img:drawPixel(x, y, full:getPixel(x, y))
                end
            end
            spr:close()
            break
        end
    end

    -- Procedural pixel fallback matching Vườn Nhỏ player if file load fails
    if not player_img then
        player_img = Image(32, 48, ColorMode.RGB)
        player_img:clear(rgba(0, 0, 0, 0))

        -- Palette for player fallback
        local HAT_TOP   = rgba(221, 178, 106, 255)
        local HAT_HI    = rgba(237, 209, 142, 255)
        local HAT_BODY  = rgba(181, 136, 68, 255)
        local HAT_RIM   = rgba(102, 68, 32, 255)
        local SKIN_BASE = rgba(216, 164, 120, 255)
        local EYE_DARK  = rgba(38, 28, 20, 255)
        local SHIRT_MID = rgba(54, 84, 120, 255)
        local SHIRT_HI  = rgba(72, 106, 148, 255)
        local SHIRT_SHD = rgba(36, 56, 82, 255)
        local BUTTON_W  = rgba(240, 234, 222, 255)
        local SASH_GOLD = rgba(224, 152, 44, 255)
        local PANTS_MID = rgba(34, 42, 54, 255)
        local PANTS_SHD = rgba(22, 28, 36, 255)
        local SHOE_BASE = rgba(74, 44, 24, 255)

        -- Conical hat (Nón lá: y = 4..12)
        for y = 4, 12 do
            local half_w = (y - 4) * 3 + 1
            for x = 15 - half_w, 16 + half_w do
                if x >= 0 and x < 32 then
                    player_img:drawPixel(x, y, HAT_BODY)
                end
            end
        end
        for y = 4, 11 do
            local half_w = (y - 4) * 3 + 1
            player_img:drawPixel(15 - half_w, y, HAT_HI)
            player_img:drawPixel(16 + half_w, y, HAT_RIM)
        end
        player_img:drawPixel(15, 4, HAT_TOP)
        player_img:drawPixel(16, 4, HAT_TOP)

        -- Face (y = 13..15)
        for y = 13, 15 do
            for x = 12, 19 do player_img:drawPixel(x, y, SKIN_BASE) end
        end
        player_img:drawPixel(13, 14, EYE_DARK)
        player_img:drawPixel(18, 14, EYE_DARK)

        -- Shirt (Áo chàm bà ba: y = 16..26)
        for y = 16, 26 do
            for x = 8, 23 do player_img:drawPixel(x, y, SHIRT_MID) end
            player_img:drawPixel(8, y, SHIRT_HI)
            player_img:drawPixel(23, y, SHIRT_SHD)
        end
        player_img:drawPixel(15, 18, BUTTON_W)
        player_img:drawPixel(15, 21, BUTTON_W)
        for x = 8, 23 do
            player_img:drawPixel(x, 24, SASH_GOLD)
            player_img:drawPixel(x, 25, SASH_GOLD)
        end

        -- Pants (Quần chàm sẫm: y = 27..39)
        for y = 27, 39 do
            for x = 10, 14 do player_img:drawPixel(x, y, PANTS_MID) end
            for x = 17, 21 do player_img:drawPixel(x, y, PANTS_MID) end
            player_img:drawPixel(10, y, PANTS_MID)
            player_img:drawPixel(21, y, PANTS_SHD)
        end

        -- Shoes (Chân / Giày nâu: y = 40..42)
        for y = 40, 42 do
            for x = 9, 14 do player_img:drawPixel(x, y, SHOE_BASE) end
            for x = 17, 22 do player_img:drawPixel(x, y, SHOE_BASE) end
        end
    end

    return player_img
end

-- ============================================================================
-- PREVIEW MAP GENERATOR (16x10 TILES = 512x320 PX)
-- ============================================================================
local function generate_preview_map(flat_atlas, player_img)
    local map_cols = 16
    local map_rows = 10
    local pw = map_cols * 32
    local ph = map_rows * 32
    local preview_1x = Image(pw, ph, ColorMode.RGB)
    preview_1x:clear(G_BASE)

    -- Blueprint Map Data: Array of rows, each entry is {col, row} in atlas
    local map_data = {
        -- Row 0: Grass border top, dirt path enters at cols 7-8, meadow east
        { {0,0}, {1,0}, {2,0}, {0,0}, {7,0}, {1,0}, {2,2}, {0,1}, {0,1}, {1,0}, {0,0}, {7,0}, {1,0}, {2,0}, {0,0}, {1,0} },
        -- Row 1: Dry Furrow top border, Path with brick, Pond North Bank
        { {0,0}, {6,4}, {2,4}, {2,4}, {7,4}, {0,0}, {2,2}, {2,1}, {1,1}, {4,7}, {0,7}, {4,8}, {0,7}, {0,7}, {5,7}, {0,0} },
        -- Row 2: Dry Furrow Bed Center, Path with bricks, Pond surface
        { {1,0}, {4,4}, {0,4}, {1,4}, {5,4}, {0,0}, {2,2}, {0,1}, {3,1}, {2,7}, {0,6}, {1,6}, {3,6}, {0,6}, {3,7}, {7,0} },
        -- Row 3: Wet Furrow top border, Path, Pond surface with lily pad
        { {0,0}, {6,5}, {2,5}, {2,5}, {7,5}, {0,0}, {2,2}, {1,1}, {0,1}, {2,7}, {1,6}, {0,6}, {2,6}, {4,6}, {3,7}, {0,0} },
        -- Row 4: Wet Furrow Bed Center, Path with stepping bricks, Pond stepping stone!
        { {2,0}, {4,5}, {0,5}, {1,5}, {5,5}, {0,0}, {2,2}, {4,1}, {0,1}, {5,8}, {5,6}, {7,6}, {0,6}, {1,6}, {3,7}, {1,0} },
        -- Row 5: Raised Bed Connector, Main Plaza Path [PLAYER STANDS HERE!], Pond water
        { {0,0}, {0,2}, {0,1}, {2,1}, {0,1}, {0,1}, {0,1}, {0,1}, {2,1}, {2,7}, {0,6}, {3,6}, {1,6}, {0,6}, {3,7}, {2,0} },
        -- Row 6: Path South edge, Path with fine silt, Pond water with shore foam
        { {0,0}, {1,2}, {1,2}, {1,2}, {1,2}, {1,2}, {0,1}, {1,1}, {0,1}, {2,7}, {1,6}, {0,6}, {2,6}, {7,8}, {3,7}, {0,0} },
        -- Row 7: Grass south of garden, Path with pebbles, Pond South Bank
        { {1,0}, {0,0}, {2,0}, {7,0}, {0,0}, {2,2}, {0,1}, {3,1}, {5,1}, {6,7}, {1,7}, {1,7}, {6,8}, {1,7}, {7,7}, {1,0} },
        -- Row 8: Meadow, Path with cart rut, Meadow south of pond
        { {0,0}, {2,0}, {1,0}, {0,0}, {1,0}, {2,2}, {0,1}, {0,1}, {7,1}, {1,0}, {0,0}, {2,0}, {7,0}, {1,0}, {0,0}, {0,0} },
        -- Row 9: Southern Meadow grass border
        { {1,0}, {0,0}, {7,0}, {1,0}, {0,0}, {2,2}, {0,1}, {0,1}, {0,1}, {0,0}, {1,0}, {0,0}, {0,0}, {2,0}, {0,0}, {1,0} }
    }

    -- Assemble 16x10 preview map from flat atlas
    for my = 0, map_rows - 1 do
        for mx = 0, map_cols - 1 do
            local tile = map_data[my + 1][mx + 1]
            local tc, tr = tile[1], tile[2]
            for py = 0, 31 do
                for px = 0, 31 do
                    local c = flat_atlas:getPixel(tc * 32 + px, tr * 32 + py)
                    preview_1x:drawPixel(mx * 32 + px, my * 32 + py, c)
                end
            end
        end
    end

    -- Blend Player Character (32x48) onto the earthen path near the furrows & pond
    -- Position: col 7 (x = 224), row 5 (feet on path at y = 188)
    local char_x = 224
    local char_y = 142

    -- Grounding contact shadow under player's feet (translucent oval)
    local shadow_col = rgba(40, 24, 16, 255)
    for sy = 43, 46 do
        local sw = 46 - sy + 5
        for sx = 16 - sw, 16 + sw do
            local px = char_x + sx
            local py = char_y + sy
            if px >= 0 and px < pw and py >= 0 and py < ph then
                local bg = preview_1x:getPixel(px, py)
                local r = math.floor(app.pixelColor.rgbaR(bg) * 0.55)
                local g = math.floor(app.pixelColor.rgbaG(bg) * 0.55)
                local b = math.floor(app.pixelColor.rgbaB(bg) * 0.55)
                preview_1x:drawPixel(px, py, rgba(r, g, b, 255))
            end
        end
    end

    -- Draw player sprite pixels
    for cy = 0, 47 do
        for cx = 0, 31 do
            local pcol = player_img:getPixel(cx, cy)
            local a = app.pixelColor.rgbaA(pcol)
            if a > 10 then
                local px = char_x + cx
                local py = char_y + cy
                if px >= 0 and px < pw and py >= 0 and py < ph then
                    if a >= 250 then
                        preview_1x:drawPixel(px, py, pcol)
                    else
                        -- Alpha blend
                        local bg = preview_1x:getPixel(px, py)
                        local inv = 255 - a
                        local r = math.floor((app.pixelColor.rgbaR(pcol) * a + app.pixelColor.rgbaR(bg) * inv) / 255)
                        local g = math.floor((app.pixelColor.rgbaG(pcol) * a + app.pixelColor.rgbaG(bg) * inv) / 255)
                        local b = math.floor((app.pixelColor.rgbaB(pcol) * a + app.pixelColor.rgbaB(bg) * inv) / 255)
                        preview_1x:drawPixel(px, py, rgba(r, g, b, 255))
                    end
                end
            end
        end
    end

    -- Nearest-Neighbor 2x Scaled Preview (1024x640 px)
    local preview_2x = Image(pw * 2, ph * 2, ColorMode.RGB)
    for y = 0, ph - 1 do
        for x = 0, pw - 1 do
            local c = preview_1x:getPixel(x, y)
            preview_2x:drawPixel(x * 2,     y * 2,     c)
            preview_2x:drawPixel(x * 2 + 1, y * 2,     c)
            preview_2x:drawPixel(x * 2,     y * 2 + 1, c)
            preview_2x:drawPixel(x * 2 + 1, y * 2 + 1, c)
        end
    end

    return preview_1x, preview_2x
end

-- ============================================================================
-- SAVE HELPER TO EXPORT ANY IMAGE AS PNG
-- ============================================================================
local function save_image_as_png(img, filepath)
    local spr = Sprite(img.width, img.height, ColorMode.RGB)
    local cel = spr.cels[1] or spr:newCel(spr.layers[1], spr.frames[1])
    cel.image:drawImage(img, Point(0, 0))
    spr:saveCopyAs(filepath)
    spr:close()
end

-- ============================================================================
-- MARKDOWN DOCUMENTATION WRITER (tiles.md)
-- ============================================================================
local function generate_tiles_md(output_dir)
    local md_path = join_path(output_dir, "tiles.md")
    local f = io.open(md_path, "w")
    if not f then return false end

    local content = [[# Bản Thử Tileset Vườn Nhỏ - Farm Fields Study v1 (32 × 32 px)

## 1. Thông Số Kỹ Thuật Atlas
- **Kích thước Atlas**: 256 × 288 px (8 cột × 9 hàng, tổng cộng 72 tile).
- **Kích thước mỗi Tile**: 32 × 32 px (bám lưới pixel nguyên, không lệch nửa pixel).
- **Hệ thống Layer nguồn `.aseprite`**:
  - `highlights`: Vệt nước lấp lánh, ngọn cỏ bắt sáng, mép gạch vát đón nắng, đỉnh luống đất nung khô.
  - `detail`: Gờ luống, cụm đất phù sa, viên gạch nung lệch, dải bùn bờ ao, khóm cỏ lác, phiến đá cầu ao, rãnh bánh xe.
  - `base`: Màu nền gốc phủ kín 100% (cỏ ô liu dịu, đất phù sa đỏ nâu, nước ao xanh ngọc xám).
- **Kích thước Preview Map**:
  - `preview_1x.png`: 512 × 320 px (16 cột × 10 hàng tile).
  - `preview_2x.png`: 1024 × 640 px (scale phóng to Nearest-Neighbor giữ nguyên độ sắc nét pixel art).
  - Nhân vật: 32 × 48 px lấy trực tiếp từ khung idle chính diện của `player.png`, tích hợp bóng tiếp xúc mặt đất.

---

## 2. Bảng Phân Bố Tile Hàng / Cột (8 Cột × 9 Hàng)

| Hàng | Cột | Tên Tile | Chức Năng & Đặc Điểm Hình Ảnh Bắc Ninh |
|:---:|:---:|:---|:---|
| **0** | 0 | `grass_base` | Cỏ ô liu dịu gốc, hoa văn hạt dịu mắt, liền mạch 4 hướng. |
| **0** | 1 | `grass_var_a` | Cụm 2-3 lá cỏ mềm đón sáng Tây Bắc, bóng chân cỏ êm. |
| **0** | 2 | `grass_var_b` | Vạt cỏ 3 lá mùa hạ và hoa cỏ dại vàng nhạt li ti. |
| **0** | 3 | `grass_var_c` | Lá cỏ xuôi nhẹ theo chiều gió hè đồng bằng. |
| **0** | 4 | `grass_var_d` | Vết đất phù sa đỏ nâu hé lộ cùng sỏi suối mịn. |
| **0** | 5 | `grass_var_e` | Nhánh cỏ lác mọc cao vươn thẳng trên nền cỏ. |
| **0** | 6 | `grass_var_f` | Hai cụm cỏ 3 lá xanh mướt phân bố cân bằng. |
| **0** | 7 | `grass_var_g` | Cụm hoa cỏ may trắng ngà và cúc dại vàng đồng nội. |
| **1** | 0 | `dirt_base` | Đất phù sa đỏ nâu tơi xốp, hạt mịn hữu cơ, nối liền 4 hướng. |
| **1** | 1 | `dirt_path` | Lối mòn nén chặt ở giữa, hạt bụi phù sa sáng màu. |
| **1** | 2 | `dirt_brick_single` | Một viên gạch nung đỏ son lệch góc, viền bùn bám cối rơm. |
| **1** | 3 | `dirt_brick_pair` | Hai mảnh gạch nung vỡ mẻ cạnh, đất cặn trong kẽ nứt. |
| **1** | 4 | `dirt_brick_stepping` | Hàng gạch bước chân so le chống lầy lội mùa mưa. |
| **1** | 5 | `dirt_pebbles` | Cụm sỏi cuội suối nhẵn tròn chìm trong đất phù sa. |
| **1** | 6 | `dirt_clods` | Cụm vụn đất xới tơi xốp cạnh luống cày. |
| **1** | 7 | `dirt_cart_rut` | Vệt lún bánh xe bò/xe cút kít nén chặt dọc lối đi. |
| **2** | 0 | `edge_dirt_n` | Mép thẳng Bắc: Cỏ phủ trên (y ≤ 11), đất phù sa ở dưới (y ≥ 12). |
| **2** | 1 | `edge_dirt_s` | Mép thẳng Nam: Đất ở trên (y ≤ 19), ngọn cỏ vươn từ dưới lên. |
| **2** | 2 | `edge_dirt_w` | Mép thẳng Tây: Cỏ mép trái (x ≤ 11), đất mở rộng sang phải. |
| **2** | 3 | `edge_dirt_e` | Mép thẳng Đông: Đất bên trái, cỏ mở rộng sang phải (x ≥ 20). |
| **2** | 4 | `corner_outer_tl` | Góc ngoài Tây-Bắc: Cỏ góc trên trái, bo tròn tự nhiên vào đất. |
| **2** | 5 | `corner_outer_tr` | Góc ngoài Đông-Bắc: Cỏ góc trên phải bo tròn vào đất. |
| **2** | 6 | `corner_outer_bl` | Góc ngoài Tây-Nam: Cỏ góc dưới trái bo tròn vào đất. |
| **2** | 7 | `corner_outer_br` | Góc ngoài Đông-Nam: Cỏ góc dưới phải bo tròn vào đất. |
| **3** | 0 | `corner_inner_tl` | Góc lõm Tây-Bắc: Đất bao quanh, cỏ lẹm vào góc trên trái. |
| **3** | 1 | `corner_inner_tr` | Góc lõm Đông-Bắc: Đất bao quanh, cỏ lẹm vào góc trên phải. |
| **3** | 2 | `corner_inner_bl` | Góc lõm Tây-Nam: Đất bao quanh, cỏ lẹm vào góc dưới trái. |
| **3** | 3 | `corner_inner_br` | Góc lõm Đông-Nam: Đất bao quanh, cỏ lẹm vào góc dưới phải. |
| **3** | 4 | `path_thin_h` | Lối đi đất hẹp ngang (cỏ kẹp trên và dưới). |
| **3** | 5 | `path_thin_v` | Lối đi đất hẹp dọc (cỏ kẹp trái và phải). |
| **3** | 6 | `path_end_n` | Tận cùng lối đi hướng Bắc, mũi đất bo tròn vào đồng cỏ. |
| **3** | 7 | `path_end_s` | Tận cùng lối đi hướng Nam, mũi đất bo tròn vào đồng cỏ. |
| **4** | 0 | `furrow_dry_center_a` | Luống khô A: 4 gờ luống, rãnh ngắn lệch nhịp 6-10 px, váng nung khô. |
| **4** | 1 | `furrow_dry_center_b` | Luống khô B: Nhịp so le bù trừ, liên kết mượt với tile A. |
| **4** | 2 | `furrow_dry_edge_n` | Mép trên luống khô: Gờ đất đắp cao chuyển sang lối đi. |
| **4** | 3 | `furrow_dry_edge_s` | Mép dưới luống khô: Chân luống đổ bóng râm xuống rãnh. |
| **4** | 4 | `furrow_dry_edge_w` | Đầu luống khô phía Tây: Đầu gờ đất khum tròn. |
| **4** | 5 | `furrow_dry_edge_e` | Đầu luống khô phía Đông: Đầu gờ đất khum tròn thoát nước. |
| **4** | 6 | `furrow_dry_corner_tl` | Góc trên trái luống khô kết thúc vào bờ đất. |
| **4** | 7 | `furrow_dry_corner_tr` | Góc trên phải luống khô kết thúc vào bờ đất. |
| **5** | 0 | `furrow_wet_center_a` | Luống ướt A: Đất nâu sẫm đẫm nước, vệt nước thưa lấp lánh phản chiếu. |
| **5** | 1 | `furrow_wet_center_b` | Luống ướt B: Vũng nước nông bóng loáng trong lòng rãnh. |
| **5** | 2 | `furrow_wet_edge_n` | Mép trên luống ướt: Vạt đất ẩm sẫm màu giáp bờ đất. |
| **5** | 3 | `furrow_wet_edge_s` | Mép dưới luống ướt: Chân gờ ướt sũng ngậm nước. |
| **5** | 4 | `furrow_wet_edge_w` | Đầu luống ướt phía Tây với vũng đọng nước nhỏ. |
| **5** | 5 | `furrow_wet_edge_e` | Đầu luống ướt phía Đông thoát nước chậm. |
| **5** | 6 | `furrow_wet_corner_tl` | Góc trên trái luống đất ướt. |
| **5** | 7 | `furrow_wet_corner_tr` | Góc trên phải luống đất ướt. |
| **6** | 0 | `water_calm_base` | Mặt nước ao làng xanh ngọc xám sâu, tĩnh lặng, liền mạch 4 hướng. |
| **6** | 1 | `water_wavelet_a` | Gợn sóng ngang êm ả đón ánh sáng ban ngày. |
| **6** | 2 | `water_wavelet_b` | Gợn sóng so le điểm xuyết tia sáng lấp lánh. |
| **6** | 3 | `water_duckweed` | Cụm bèo tấm xanh mướt trôi bồng bềnh ven mặt nước. |
| **6** | 4 | `water_lily_pad` | Lá súng non tròn nhỏ khía rãnh nổi trên mặt nước. |
| **6** | 5 | `water_shallows` | Vùng nước nông ánh màu phù sa lắng dưới đáy ao. |
| **6** | 6 | `water_mud_shelf` | Thềm bùn thoai thoải chìm dưới làn nước trong. |
| **6** | 7 | `water_wavelet_c` | Sóng lăn tăn gió hè dài mềm mại. |
| **7** | 0 | `bank_north` | Bờ Bắc: Đất cỏ ở trên, bùn dốc, cỏ lác rủ ngọn xuống nước. |
| **7** | 1 | `bank_south` | Bờ Nam: Nước ở trên, dải bùn thoai thoải, mép bờ đất phía dưới. |
| **7** | 2 | `bank_west` | Bờ Tây: Cỏ đất bên trái, khóm cỏ lác vươn sang nước bên phải. |
| **7** | 3 | `bank_east` | Bờ Đông: Nước bên trái, bờ đất dốc thoai thoải bên phải. |
| **7** | 4 | `bank_outer_tl` | Góc ngoài bờ ao Tây-Bắc: Đất góc trên trái, nước góc dưới phải. |
| **7** | 5 | `bank_outer_tr` | Góc ngoài bờ ao Đông-Bắc: Đất góc trên phải, nước góc dưới trái. |
| **7** | 6 | `bank_outer_bl` | Góc ngoài bờ ao Tây-Nam: Đất góc dưới trái, nước góc trên phải. |
| **7** | 7 | `bank_outer_br` | Góc ngoài bờ ao Đông-Nam: Đất góc dưới phải, nước góc trên trái. |
| **8** | 0 | `bank_inner_tl` | Góc lõm bờ ao Tây-Bắc: Túi nước lẹm vào góc trên trái. |
| **8** | 1 | `bank_inner_tr` | Góc lõm bờ ao Đông-Bắc: Túi nước lẹm vào góc trên phải. |
| **8** | 2 | `bank_inner_bl` | Góc lõm bờ ao Tây-Nam: Túi nước lẹm vào góc dưới trái. |
| **8** | 3 | `bank_inner_br` | Góc lõm bờ ao Đông-Nam: Túi nước lẹm vào góc dưới phải. |
| **8** | 4 | `bank_dense_reeds` | Bờ ao biến thể: Khóm cỏ lác mọc dày đặc rủ bóng xuống nước. |
| **8** | 5 | `bank_stepping_stone` | Phiến đá cầu ao tự nhiên nhô ra mép nước để rửa chân/rau. |
| **8** | 6 | `bank_mud_slope` | Dốc bùn thoai thoải ngập nước không có lau sậy cao. |
| **8** | 7 | `bank_shore_foam` | Vệt bọt nước vỗ bờ êm ả lấp lánh phản chiếu. |

---

## 3. Bảng Màu Đặc Trưng Bắc Ninh (Độ Tương Phản Thấp, Dễ Đọc ở 1×)

- **Cỏ ô liu dịu**:
  - `G_BASE` `#5C8036` (Nền chính)
  - `G_DARK` `#4A6A2C` (Bóng rãnh)
  - `G_LIGHT` `#6E9042` (Thân cỏ)
  - `G_TIP` `#7EA04E` (Ngọn cỏ)
- **Đất phù sa & Gạch nung**:
  - `D_BASE` `#945C3C` (Đất phù sa đỏ nâu)
  - `D_LIGHT` `#A66E4C` (Hạt phù sa bề mặt)
  - `BRICK_BASE` `#A8422E` (Gạch nung son sẫm)
  - `BRICK_HI` `#C65A42` (Vát mép gạch đón nắng)
- **Luống khô & Luống ướt**:
  - `F_DRY_CRUST` `#A87650` (Váng luống khô)
  - `F_DRY_TRENCH` `#6A422C` (Rãnh luống khô)
  - `F_WET_BASE` `#342218` (Bùn ướt sẫm màu)
  - `F_WET_SHEEN` `#6C8A86` (Ánh nước xanh ngọc)
  - `F_WET_GLINT` `#9ABCB6` (Tia phản chiếu)
- **Ao làng & Cỏ lác**:
  - `W_BASE` `#2E4C50` (Nước xanh ngọc xám)
  - `W_CREST` `#568084` (Đỉnh gợn sóng)
  - `REED_MID` `#62863C` (Lá cỏ lác tam giác)
  - `STONE_BASE` `#948E84` (Phiến đá cầu ao)

---

## 4. Bố Cục Bản Đồ Mẫu (Preview Map 16 × 10 Tiles)
- **Tây-Bắc (Cols 1-4, Rows 1-4)**: Khu vườn với 2 luống khô song song bên trên và 2 luống ướt bên dưới, mép đất viền tự nhiên.
- **Trung Tâm (Cols 7-8, Rows 0-9)**: Con đường đất phù sa uốn lượn có lát các viên gạch nung lệch góc, hàng gạch bước chân và vệt bánh xe lún nhẹ.
- **Nhân Vật (x = 224, y = 142)**: Bác nông dân áo chàm, thắt lưng vàng, nón lá truyền thống đứng trên lối đi cạnh luống rau và nhìn sang bờ ao.
- **Đông-Nam (Cols 10-14, Rows 1-7)**: Ao làng Bắc Ninh với bờ ao thấp có cỏ lác, phiến đá cầu ao (col 9, row 4), bèo tấm và lá súng trôi bồng bềnh.
- **Vành Đai Ngoại Vi**: Đồng cỏ ô liu dịu xen lẫn hoa dại vàng nhạt và cỏ 3 lá.
]]

    f:write(content)
    f:close()
    return true
end

-- ============================================================================
-- MAIN SCRIPT EXECUTION
-- ============================================================================
local params = app.params or {}
local output_dir = params["output_dir"] or params.output_dir or "."
local project_dir = params["project_dir"] or params.project_dir or "."

if app.fs and app.fs.makeAllDirectories and output_dir ~= "" and output_dir ~= "." then
    pcall(function() app.fs.makeAllDirectories(output_dir) end)
end

local rng = PRNG.new(20261115)

-- 1. Build Atlas Sprite & Flat Image
local spr, flat_atlas = build_atlas(rng)

-- 2. Save farm_fields_study.aseprite (with useful layers) and farm_fields_study.png
local ase_path = join_path(output_dir, "farm_fields_study.aseprite")
local png_path = join_path(output_dir, "farm_fields_study.png")

spr:saveCopyAs(ase_path)
spr:saveCopyAs(png_path)
spr:close()

-- 3. Load Player Frame from player.png
local player_img = load_player_frame(project_dir)

-- 4. Generate Previews (1x and 2x nearest-neighbor)
local preview_1x, preview_2x = generate_preview_map(flat_atlas, player_img)

local prev1_path = join_path(output_dir, "preview_1x.png")
local prev2_path = join_path(output_dir, "preview_2x.png")

save_image_as_png(preview_1x, prev1_path)
save_image_as_png(preview_2x, prev2_path)

-- 5. Generate Markdown Documentation
generate_tiles_md(output_dir)

print("SUCCESS: Farm Fields Study generated in " .. output_dir)
