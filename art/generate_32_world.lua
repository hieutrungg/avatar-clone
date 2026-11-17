-- ============================================================================
-- Vườn Nhỏ - Vietnamese Countryside 32px World & Props Generator
-- Standalone Aseprite Script (Aseprite 1.3.15.5-dev on Windows)
--
-- Generates 9 comprehensive 32px-grid retro farm and village assets:
--   1. terrain.png         (288x32)  - 9 cells: base grass, dirt path, soil, dry furrows,
--                                      wet furrows, grass tufts, flowers, clover, path var
--   2. village_terrain.png (256x32)  - 8 cells: 3 grass vars, packed road, 2 river vars,
--                                      riverbank strip (land left, water right), wooden dock
--   3. props.png           (192x64)  - 3 cells (64x64): cream farmhouse, shipping chest, shade tree
--   4. village_stall.png   (128x96)  - Seed shop with terracotta roof, counter, seed shelves
--   5. market_booth.png    (96x64)   - Cream-and-blue striped awning with produce crates
--   6. shop_sign.png       (32x32)   - Hanging wooden sign with seed-bag emblem
--   7. village_board.png   (32x32)   - Rustic notice board with two cream pinned sheets
--   8. fishing_spot.png    (32x32)   - Tackle crate with diagonal rod and red/cream float
--   9. wayfinding.png      (64x32)   - 2 cells (32x32): wooden signs pointing right and left
--
-- Saves editable layered .aseprite files (Base & Detail) to source_dir
-- and exports flattened RGBA .png files to out_dir.
-- ============================================================================

-- Read script parameters with robust defaults
local source_dir = (app.params and app.params["source_dir"]) or "art/32"
local out_dir = (app.params and app.params["out_dir"]) or "assets/art/32"

-- Path joining helper compatible with Windows and forward slashes
local function joinPath(dir, filename)
  local clean_dir = tostring(dir):gsub("[/\\]+$", "")
  local sep = clean_dir:find("\\") and "\\" or "/"
  return clean_dir .. sep .. filename
end

-- ============================================================================
-- Cohesive Vietnamese Countryside Palette (Rich, grounded, painterly)
-- ============================================================================
local function rgba(r, g, b, a)
  return app.pixelColor.rgba(r, g, b, a or 255)
end

local PAL = {
  trans         = rgba(0, 0, 0, 0),
  shadow_ambient= rgba(0x18, 0x12, 0x0c, 110),
  shadow_deep   = rgba(0x12, 0x0c, 0x08, 170),

  -- Mossy olive grass (Cỏ đồng quê êm dịu, không chói)
  grass_base    = rgba(0x4a, 0x6e, 0x2e), -- #4a6e2e midtone
  grass_dark    = rgba(0x43, 0x65, 0x2c), -- shade under grass
  grass_deep    = rgba(0x3c, 0x5c, 0x28), -- shadow at the root
  grass_light   = rgba(0x55, 0x77, 0x35), -- soft sunlit grass
  grass_high    = rgba(0x6e, 0x8b, 0x40), -- blade tip
  grass_warm    = rgba(0x51, 0x72, 0x33), -- warm olive transition

  -- Flowers & wild clover accents
  flower_white  = rgba(0xf7, 0xf3, 0xe4),
  flower_cream  = rgba(0xfa, 0xf6, 0xca),
  flower_gold   = rgba(0xf2, 0xa3, 0x2b),
  flower_coral  = rgba(0xd9, 0x5b, 0x4c),
  clover_light  = rgba(0x75, 0xa8, 0x38),
  clover_dark   = rgba(0x2a, 0x47, 0x19),

  -- Worn clay path & packed village road (Đất thịt, đất sét nung ấm)
  path_base     = rgba(0x99, 0x68, 0x43), -- #996843 worn clay
  path_dark     = rgba(0x8c, 0x5f, 0x3d), -- clay shade
  path_deep     = rgba(0x79, 0x50, 0x34), -- recessed clay
  path_light    = rgba(0xa5, 0x75, 0x4d), -- sunlit crest
  path_high     = rgba(0xb9, 0x88, 0x59), -- dry clay highlight
  pebble_lt     = rgba(0xdb, 0xbe, 0x9e), -- #dbbe9e river pebble highlight
  pebble_dk     = rgba(0x63, 0x40, 0x28), -- #634028 pebble shadow

  road_base     = rgba(0x87, 0x5d, 0x3d), -- #875d3d packed hard road
  road_dark     = rgba(0x7d, 0x54, 0x38),
  road_light    = rgba(0x94, 0x68, 0x46),

  -- Untouched cultivable soil (Đất màu xốp tơi)
  soil_base     = rgba(0x61, 0x3f, 0x24), -- #613f24 rich fertile loam
  soil_dark     = rgba(0x4a, 0x2e, 0x18), -- #4a2e18 loam shade
  soil_deep     = rgba(0x33, 0x1e, 0x0e), -- #331e0e furrow shadow
  soil_light    = rgba(0x7d, 0x53, 0x31), -- #7d5331 aerated crumb
  soil_high     = rgba(0x96, 0x6a, 0x43), -- #966a43 dry surface clod

  -- Tilled dry furrows (Luống đất cày khô)
  furrow_d_base = rgba(0x8c, 0x5d, 0x35),
  furrow_d_ridge= rgba(0xa6, 0x74, 0x47),
  furrow_d_high = rgba(0xc4, 0x8f, 0x5f),
  furrow_d_shade= rgba(0x6b, 0x42, 0x22),
  furrow_d_deep = rgba(0x47, 0x29, 0x13),

  -- Tilled wet furrows (Luống đất cày đã tưới nước đẫm, lấp lánh phù sa)
  furrow_w_base = rgba(0x38, 0x21, 0x13),
  furrow_w_ridge= rgba(0x4b, 0x2f, 0x1b),
  furrow_w_high = rgba(0x5e, 0x3d, 0x25),
  furrow_w_shade= rgba(0x22, 0x13, 0x0a),
  furrow_w_deep = rgba(0x13, 0x09, 0x04),
  furrow_glint  = rgba(0x6b, 0x8f, 0x9c), -- water reflection
  furrow_sheen  = rgba(0x42, 0x5a, 0x63), -- wet mud sheen

  -- Dark indigo river water (Nước sông quê sẫm màu, đượm phù sa)
  water_deep    = rgba(0x16, 0x25, 0x38), -- #162538 deep depth
  water_base    = rgba(0x1f, 0x35, 0x4e), -- #1f354e river body
  water_mid     = rgba(0x2d, 0x48, 0x66), -- #2d4866 ripple mid
  water_ripple  = rgba(0x43, 0x68, 0x8c), -- #43688c ripple light
  water_glint   = rgba(0x71, 0x9b, 0xc2), -- #719bc2 sun glint

  -- Water hyacinth (Bèo lục bình / bèo tây)
  leaf_pad_base = rgba(0x3a, 0x61, 0x26),
  leaf_pad_high = rgba(0x5e, 0x8f, 0x39),
  flower_hy_pur = rgba(0x94, 0x6f, 0xb8),
  flower_hy_lt  = rgba(0xd4, 0xb8, 0xfa),

  -- Reeds & riverbank (Lau sậy bờ sông & bùn)
  mud_wet       = rgba(0x3a, 0x24, 0x15),
  reed_green    = rgba(0x4d, 0x6e, 0x2e),
  reed_light    = rgba(0x72, 0x96, 0x43),
  reed_plume    = rgba(0x8a, 0x6b, 0x3b),
  stone_light   = rgba(0x7c, 0x8a, 0x91),
  stone_dark    = rgba(0x49, 0x55, 0x5c),

  -- Weathered hardwood (Cầu tàu, bảng gỗ, cột nhà)
  wood_deep     = rgba(0x24, 0x15, 0x0c), -- deep gap / post shade
  wood_dark     = rgba(0x45, 0x2a, 0x18),
  wood_base     = rgba(0x6b, 0x44, 0x29),
  wood_light    = rgba(0x8c, 0x5f, 0x3d),
  wood_high     = rgba(0xa8, 0x78, 0x51),
  iron_dark     = rgba(0x22, 0x1e, 0x20),
  iron_light    = rgba(0x57, 0x52, 0x54),

  -- Layered terracotta roof tile (Mái ngói ta / ngói đỏ mũi hài đất nung)
  tile_deep     = rgba(0x4a, 0x13, 0x0b), -- underside overlap shadow
  tile_shade    = rgba(0x78, 0x22, 0x14), -- tile shadow
  tile_base     = rgba(0xba, 0x3c, 0x22), -- rich red terracotta
  tile_light    = rgba(0xdc, 0x56, 0x34), -- tile crest highlight
  tile_ridge    = rgba(0xf0, 0x73, 0x4b), -- top ridge sunlit accent
  mortar_white  = rgba(0xe8, 0xe2, 0xd1), -- chỉ vôi trắng bờ nóc

  -- Plaster & architectural walls (Tường quét vôi vàng nhạt/kem truyền thống)
  plaster_deep  = rgba(0x5c, 0x4f, 0x39),
  plaster_shade = rgba(0xb0, 0xa1, 0x82),
  plaster_base  = rgba(0xd6, 0xc7, 0xa7),
  plaster_light = rgba(0xed, 0xe2, 0xc7),
  plaster_high  = rgba(0xf7, 0xf0, 0xdb),

  -- Market awning (Mái bạt sọc xanh chàm & kem)
  awning_blue_dk= rgba(0x24, 0x48, 0x6e),
  awning_blue   = rgba(0x35, 0x67, 0x99),
  awning_blue_lt= rgba(0x53, 0x87, 0xbf),
  awning_crm_dk = rgba(0xc7, 0xbc, 0x9b),
  awning_crm    = rgba(0xe6, 0xdd, 0xc3),
  awning_crm_lt = rgba(0xf7, 0xf2, 0xdf),

  -- Produce & details
  sack_burlap   = rgba(0xd4, 0xb8, 0x87),
  sack_shade    = rgba(0x9c, 0x7d, 0x4f),
  rice_grain    = rgba(0xe8, 0xd7, 0xa0),
  rice_gold     = rgba(0xf5, 0xca, 0x64),
  bean_green    = rgba(0x4d, 0x7d, 0x34),
  bean_red      = rgba(0x87, 0x24, 0x1c),
  fruit_orange  = rgba(0xea, 0x67, 0x26),
  fruit_amber   = rgba(0xf5, 0x98, 0x36),
  fruit_bright  = rgba(0xff, 0xc9, 0x4a),
  melon_dark    = rgba(0x28, 0x54, 0x29),
  melon_light   = rgba(0x4f, 0x99, 0x4f),
  carrot_org    = rgba(0xe8, 0x64, 0x20),
  veg_cabbage   = rgba(0x73, 0xa3, 0x3b),
  veg_cabbage_lt= rgba(0xa6, 0xd1, 0x69),
  pin_red       = rgba(0xc7, 0x2b, 0x26),
  float_red     = rgba(0xd9, 0x2c, 0x24),
  float_white   = rgba(0xf5, 0xf2, 0xeb),
}

-- ============================================================================
-- Low-Level Drawing Primitives (Safe boundaries, pixel precision)
-- ============================================================================
local function setPx(img, x, y, col)
  if x >= 0 and x < img.width and y >= 0 and y < img.height then
    img:drawPixel(x, y, col)
  end
end

local function fillRect(img, x0, y0, w, h, col)
  local x1 = math.max(0, x0)
  local y1 = math.max(0, y0)
  local x2 = math.min(img.width - 1, x0 + w - 1)
  local y2 = math.min(img.height - 1, y0 + h - 1)
  for y = y1, y2 do
    for x = x1, x2 do
      img:drawPixel(x, y, col)
    end
  end
end

local function drawHLine(img, x0, y, len, col)
  if y < 0 or y >= img.height then return end
  local x1 = math.max(0, x0)
  local x2 = math.min(img.width - 1, x0 + len - 1)
  for x = x1, x2 do
    img:drawPixel(x, y, col)
  end
end

local function drawVLine(img, x, y0, len, col)
  if x < 0 or x >= img.width then return end
  local y1 = math.max(0, y0)
  local y2 = math.min(img.height - 1, y0 + len - 1)
  for y = y1, y2 do
    img:drawPixel(x, y, col)
  end
end

local function drawStamp(img, x0, y0, lines, charMap)
  for r, line in ipairs(lines) do
    local y = y0 + r - 1
    for c = 1, #line do
      local ch = line:sub(c, c)
      local col = charMap[ch]
      if col and ch ~= "." and ch ~= " " then
        setPx(img, x0 + c - 1, y, col)
      end
    end
  end
end

-- ============================================================================
-- Seamless 32x32 Procedural Texture Engines
-- ============================================================================

-- Base Grass Engine: Seamless toroidal 32x32 mossy olive countryside terrain
local function renderSeamlessGrass(img, ox, oy)
  -- 1. Uniform base fill
  fillRect(img, ox, oy, 32, 32, PAL.grass_base)

  -- 2. Toroidal soft organic midtone mounding (asymmetric, subdued contrast)
  local shadeBlobs = {
    { cx = 6,  cy = 8,  w = 5, h = 3 },
    { cx = 22, cy = 12, w = 6, h = 4 },
    { cx = 14, cy = 24, w = 5, h = 3 },
    { cx = 27, cy = 27, w = 4, h = 3 },
  }
  for _, b in ipairs(shadeBlobs) do
    for dy = -b.h, b.h do
      for dx = -b.w, b.w do
        if (dx * dx) / (b.w * b.w) + (dy * dy) / (b.h * b.h) <= 1.0 then
          local px = (b.cx + dx + 32) % 32
          local py = (b.cy + dy + 32) % 32
          setPx(img, ox + px, oy + py, PAL.grass_dark)
        end
      end
    end
  end

  local lightBlobs = {
    { cx = 12, cy = 6,  w = 4, h = 2 },
    { cx = 4,  cy = 20, w = 5, h = 3 },
    { cx = 24, cy = 20, w = 4, h = 2 },
    { cx = 18, cy = 16, w = 3, h = 2 },
  }
  for _, b in ipairs(lightBlobs) do
    for dy = -b.h, b.h do
      for dx = -b.w, b.w do
        if (dx * dx) / (b.w * b.w) + (dy * dy) / (b.h * b.h) <= 1.0 then
          local px = (b.cx + dx + 32) % 32
          local py = (b.cy + dy + 32) % 32
          setPx(img, ox + px, oy + py, PAL.grass_light)
        end
      end
    end
  end

  -- 3. Subtle painterly pixel pairs (upper-left light, lower-right soft shade)
  local tuftSpots = {
    { x = 3,  y = 4  }, { x = 16, y = 3  }, { x = 27, y = 5  },
    { x = 9,  y = 11 }, { x = 20, y = 10 }, { x = 28, y = 15 },
    { x = 2,  y = 16 }, { x = 13, y = 18 }, { x = 23, y = 17 },
    { x = 8,  y = 26 }, { x = 17, y = 29 }, { x = 29, y = 25 },
  }
  for _, p in ipairs(tuftSpots) do
    setPx(img, ox + p.x, oy + p.y, PAL.grass_high)
    setPx(img, ox + (p.x + 1) % 32, oy + (p.y + 1) % 32, PAL.grass_deep)
  end
end

-- Warm Dirt Path Engine: Seamless worn clay path with organic footway wear
local function renderWarmDirtPath(img, ox, oy, isVariant)
  fillRect(img, ox, oy, 32, 32, PAL.path_base)

  -- Subtle wear depressions across center
  local ruts = {
    { x = 2,  y = 6,  w = 8,  h = 4 },
    { x = 16, y = 10, w = 10, h = 5 },
    { x = 6,  y = 18, w = 12, h = 4 },
    { x = 22, y = 22, w = 7,  h = 5 },
    { x = 12, y = 27, w = 9,  h = 4 },
  }
  for _, b in ipairs(ruts) do
    for dy = -b.h, b.h do
      for dx = -b.w, b.w do
        if (dx * dx) / (b.w * b.w) + (dy * dy) / (b.h * b.h) <= 1.0 then
          local px = (b.x + dx + 32) % 32
          local py = (b.y + dy + 32) % 32
          setPx(img, ox + px, oy + py, PAL.path_dark)
        end
      end
    end
  end

  -- Sun-baked dry clay ridges
  local drySpots = {
    { x = 8,  y = 3,  w = 5, h = 2 },
    { x = 24, y = 7,  w = 6, h = 3 },
    { x = 4,  y = 14, w = 4, h = 2 },
    { x = 18, y = 17, w = 5, h = 2 },
    { x = 28, y = 28, w = 4, h = 2 },
  }
  for _, b in ipairs(drySpots) do
    for dy = -b.h, b.h do
      for dx = -b.w, b.w do
        if (dx * dx) / (b.w * b.w) + (dy * dy) / (b.h * b.h) <= 1.0 then
          local px = (b.x + dx + 32) % 32
          local py = (b.y + dy + 32) % 32
          setPx(img, ox + px, oy + py, PAL.path_light)
        end
      end
    end
  end

  -- Fine clay micro-pebbles and highlights
  local specks = {
    { x = 5,  y = 5  }, { x = 19, y = 4  }, { x = 11, y = 12 },
    { x = 27, y = 13 }, { x = 7,  y = 22 }, { x = 21, y = 25 },
    { x = 15, y = 30 }, { x = 30, y = 20 }
  }
  for _, p in ipairs(specks) do
    setPx(img, ox + p.x, oy + p.y, PAL.path_high)
    setPx(img, ox + (p.x + 1) % 32, oy + (p.y + 1) % 32, PAL.path_deep)
  end

  -- Variant additions: Embedded smooth flat river pebbles & dried wheel rut
  if isVariant then
    -- Smooth river pebble 1
    fillRect(img, ox + 9,  oy + 14, 3, 2, PAL.pebble_lt)
    setPx(img, ox + 8,  oy + 15, PAL.pebble_dk)
    setPx(img, ox + 12, oy + 15, PAL.pebble_dk)
    setPx(img, ox + 10, oy + 16, PAL.pebble_dk)
    setPx(img, ox + 11, oy + 16, PAL.pebble_dk)

    -- Smooth river pebble 2
    fillRect(img, ox + 22, oy + 21, 4, 2, PAL.pebble_lt)
    setPx(img, ox + 21, oy + 22, PAL.pebble_dk)
    setPx(img, ox + 26, oy + 22, PAL.pebble_dk)
    drawHLine(img, ox + 22, oy + 23, 4, PAL.pebble_dk)

    -- Subtle dried cart wheel rut impression
    for y = 8, 25 do
      local rx = math.floor(16 + math.sin(y * 0.25) * 1.5)
      setPx(img, ox + rx,     oy + y, PAL.path_deep)
      setPx(img, ox + rx + 1, oy + y, PAL.path_dark)
      if (y % 4 == 0) then
        setPx(img, ox + rx - 1, oy + y, PAL.path_light)
      end
    end
  end
end

-- Untouched Cultivable Soil: Rich aerated brown loam ready for planting
local function renderUntouchedSoil(img, ox, oy)
  fillRect(img, ox, oy, 32, 32, PAL.soil_base)

  -- Rich earthy depressions
  local clods = {
    { x = 4,  y = 5,  w = 4, h = 3 }, { x = 18, y = 7,  w = 5, h = 3 },
    { x = 11, y = 14, w = 5, h = 4 }, { x = 26, y = 15, w = 4, h = 3 },
    { x = 5,  y = 22, w = 5, h = 3 }, { x = 20, y = 24, w = 5, h = 4 },
    { x = 13, y = 29, w = 4, h = 2 }, { x = 29, y = 29, w = 3, h = 2 },
  }
  for _, c in ipairs(clods) do
    for dy = -c.h, c.h do
      for dx = -c.w, c.w do
        if (dx * dx) / (c.w * c.w) + (dy * dy) / (c.h * c.h) <= 1.0 then
          local px = (c.x + dx + 32) % 32
          local py = (c.y + dy + 32) % 32
          setPx(img, ox + px, oy + py, PAL.soil_dark)
        end
      end
    end
  end

  -- Aerated clod highlights
  local highlights = {
    { x = 5,  y = 4  }, { x = 19, y = 6  }, { x = 12, y = 13 },
    { x = 27, y = 14 }, { x = 6,  y = 21 }, { x = 21, y = 23 },
    { x = 14, y = 28 }, { x = 30, y = 28 }, { x = 8,  y = 10 },
    { x = 22, y = 2  }, { x = 16, y = 19 }, { x = 2,  y = 27 }
  }
  for _, p in ipairs(highlights) do
    setPx(img, ox + p.x, oy + p.y, PAL.soil_high)
    setPx(img, ox + (p.x + 1) % 32, oy + p.y, PAL.soil_light)
    setPx(img, ox + p.x, oy + (p.y + 1) % 32, PAL.soil_deep)
  end
end

-- Tilled Furrows Engine (Horizontal ridges with hoed rhythm)
local function renderTilledFurrows(img, ox, oy, isWet)
  if isWet then
    fillRect(img, ox, oy, 32, 32, PAL.furrow_w_base)
  else
    fillRect(img, ox, oy, 32, 32, PAL.furrow_d_base)
  end

  -- 4 horizontal ridges across the 32x32 tile (centers at y=4, 12, 20, 28)
  for furrow = 0, 3 do
    local base_y = furrow * 8
    for x = 0, 31 do
      -- Organic wave to emulate hand-hoed furrows
      local dy_wave = math.floor(math.sin(x * 0.45 + furrow * 1.5) * 0.8)
      local y_crest = (base_y + 4 + dy_wave + 32) % 32
      local y_trough = (base_y + dy_wave + 32) % 32
      local y_subtrough = (base_y + 1 + dy_wave + 32) % 32
      local y_ridge_hi = (base_y + 3 + dy_wave + 32) % 32
      local y_ridge_lo = (base_y + 5 + dy_wave + 32) % 32

      if not isWet then
        -- DRY FURROWS
        setPx(img, ox + x, oy + y_trough, PAL.furrow_d_deep)
        setPx(img, ox + x, oy + y_subtrough, PAL.furrow_d_shade)
        setPx(img, ox + x, oy + y_ridge_hi, PAL.furrow_d_high)
        setPx(img, ox + x, oy + y_crest, PAL.furrow_d_ridge)
        setPx(img, ox + x, oy + y_ridge_lo, PAL.furrow_d_shade)
        if (x % 5 == 0) then
          setPx(img, ox + x, oy + y_ridge_hi, PAL.path_high)
        end
      else
        -- WET FURROWS (Rich dark loam + reflective water glints in troughs)
        setPx(img, ox + x, oy + y_trough, PAL.furrow_w_deep)
        setPx(img, ox + x, oy + y_subtrough, PAL.furrow_w_shade)
        setPx(img, ox + x, oy + y_ridge_hi, PAL.furrow_w_high)
        setPx(img, ox + x, oy + y_crest, PAL.furrow_w_ridge)
        setPx(img, ox + x, oy + y_ridge_lo, PAL.furrow_w_shade)

        -- Water pools & specular glints in furrow troughs
        if (x % 7 == 1 or x % 7 == 2) then
          setPx(img, ox + x, oy + y_trough, PAL.furrow_glint)
        elseif (x % 7 == 3 or x % 7 == 0) then
          setPx(img, ox + x, oy + y_trough, PAL.furrow_sheen)
        end
        if (x % 11 == 2) then
          setPx(img, ox + x, oy + y_subtrough, PAL.water_glint)
        end
      end
    end
  end
end

-- ============================================================================
-- 1. TERRAIN (288x32): 9 cells of 32x32
-- Order: Base Grass | Warm Path | Untouched Soil | Dry Furrows | Wet Furrows |
--        Grass Tufts | Grass Flowers | Grass Clover | Path Variant
-- ============================================================================
local function drawTerrain(baseImg, detailImg, w, h)
  -- 0: Base Grass
  renderSeamlessGrass(baseImg, 0, 0)

  -- 1: Warm Dirt Path
  renderWarmDirtPath(baseImg, 32, 0, false)

  -- 2: Untouched Cultivable Soil
  renderUntouchedSoil(baseImg, 64, 0)

  -- 3: Tilled Dry Furrows
  renderTilledFurrows(baseImg, 96, 0, false)

  -- 4: Tilled Wet Furrows
  renderTilledFurrows(baseImg, 128, 0, true)

  -- 5: Grass Variant - Sparse Tufts (Exact same base & border, interior clusters)
  renderSeamlessGrass(baseImg, 160, 0)
  local tufts = {
    { x = 160 + 8,  y = 10 },
    { x = 160 + 20, y = 14 },
    { x = 160 + 13, y = 22 },
  }
  for _, t in ipairs(tufts) do
    -- Painterly 3-blade tuft
    setPx(detailImg, t.x,     t.y,     PAL.grass_high)
    setPx(detailImg, t.x - 1, t.y + 1, PAL.grass_light)
    setPx(detailImg, t.x + 1, t.y + 1, PAL.grass_high)
    setPx(detailImg, t.x,     t.y + 1, PAL.grass_base)
    setPx(detailImg, t.x,     t.y + 2, PAL.grass_deep)
    setPx(detailImg, t.x + 1, t.y + 2, PAL.grass_dark)
  end

  -- 6: Grass Variant - Tiny Flowers (Exact base & border)
  renderSeamlessGrass(baseImg, 192, 0)
  local flowers = {
    { x = 192 + 9,  y = 12, c_petal = PAL.flower_white, c_eye = PAL.flower_gold },
    { x = 192 + 13, y = 14, c_petal = PAL.flower_cream, c_eye = PAL.flower_gold },
    { x = 192 + 22, y = 19, c_petal = PAL.flower_coral, c_eye = PAL.flower_cream },
  }
  for _, f in ipairs(flowers) do
    setPx(detailImg, f.x,     f.y,     f.c_eye)
    setPx(detailImg, f.x - 1, f.y,     f.c_petal)
    setPx(detailImg, f.x + 1, f.y,     f.c_petal)
    setPx(detailImg, f.x,     f.y - 1, f.c_petal)
    setPx(detailImg, f.x,     f.y + 1, PAL.grass_deep) -- green sepal
  end

  -- 7: Grass Variant - Clover (Exact base & border)
  renderSeamlessGrass(baseImg, 224, 0)
  local clovers = {
    { x = 224 + 10, y = 11 },
    { x = 224 + 21, y = 18 },
  }
  for _, cl in ipairs(clovers) do
    -- 3-leaf clover cluster
    setPx(detailImg, cl.x,     cl.y - 1, PAL.clover_light)
    setPx(detailImg, cl.x - 1, cl.y,     PAL.clover_light)
    setPx(detailImg, cl.x + 1, cl.y,     PAL.clover_light)
    setPx(detailImg, cl.x,     cl.y,     PAL.clover_dark)
    setPx(detailImg, cl.x,     cl.y + 1, PAL.grass_deep) -- stem
  end

  -- 8: Path Variant - Embedded stones & cart rut
  renderWarmDirtPath(baseImg, 256, 0, true)
end

-- ============================================================================
-- 2. VILLAGE TERRAIN (256x32): 8 cells of 32x32
-- Order: Grass Var 1 | Grass Var 2 | Grass Var 3 | Packed Earth Road |
--        River Var 1 | River Var 2 | Riverbank Strip | Wooden Dock
-- ============================================================================
local function renderIndigoRiver(img, ox, oy)
  fillRect(img, ox, oy, 32, 32, PAL.water_base)

  -- Flowing ripples (Toroidal seamless across x and y)
  for y = 0, 31 do
    local ripple_band = (y % 8)
    for x = 0, 31 do
      local wave = math.sin((x * 0.4) + (y * 0.6))
      if ripple_band == 2 and wave > 0.3 then
        setPx(img, ox + x, oy + y, PAL.water_mid)
      elseif ripple_band == 3 and wave > 0.4 then
        setPx(img, ox + x, oy + y, PAL.water_ripple)
      elseif ripple_band == 4 and wave > 0.6 then
        setPx(img, ox + x, oy + y, PAL.water_glint)
      elseif ripple_band == 0 or ripple_band == 7 then
        setPx(img, ox + x, oy + y, PAL.water_deep)
      end
    end
  end
end

local function drawVillageTerrain(baseImg, detailImg, w, h)
  -- 0: Grass Variant 1
  renderSeamlessGrass(baseImg, 0, 0)

  -- 1: Grass Variant 2 (Subtle moss patch in center)
  renderSeamlessGrass(baseImg, 32, 0)
  for dy = -4, 4 do
    for dx = -5, 5 do
      if (dx * dx) / 25 + (dy * dy) / 16 <= 1.0 then
        setPx(detailImg, 32 + 16 + dx, 16 + dy, PAL.grass_dark)
      end
    end
  end
  setPx(detailImg, 32 + 15, 15, PAL.grass_light)
  setPx(detailImg, 32 + 17, 16, PAL.grass_deep)

  -- 2: Grass Variant 3 (Subtle wild meadow herbs)
  renderSeamlessGrass(baseImg, 64, 0)
  setPx(detailImg, 64 + 11, 12, PAL.grass_high)
  setPx(detailImg, 64 + 12, 13, PAL.grass_deep)
  setPx(detailImg, 64 + 22, 20, PAL.grass_high)
  setPx(detailImg, 64 + 23, 21, PAL.grass_deep)

  -- 3: Packed Earth Road (Solid, compacted laterite village road)
  fillRect(baseImg, 96, 0, 32, 32, PAL.road_base)
  for y = 0, 31 do
    for x = 0, 31 do
      if (x + y * 3) % 7 == 0 then
        setPx(baseImg, 96 + x, y, PAL.road_dark)
      elseif (x * 2 + y) % 9 == 0 then
        setPx(baseImg, 96 + x, y, PAL.road_light)
      end
    end
  end
  -- 4: River Variant 1 (Dark indigo water, gentle ripples)
  renderIndigoRiver(baseImg, 128, 0)

  -- 5: River Variant 2 (Dark indigo water with floating water hyacinth cluster)
  renderIndigoRiver(baseImg, 160, 0)
  -- Water hyacinth pads (bèo lục bình)
  local hy_pads = {
    { x = 160 + 13, y = 14 },
    { x = 160 + 16, y = 13 },
    { x = 160 + 18, y = 16 },
    { x = 160 + 14, y = 17 },
  }
  for _, pad in ipairs(hy_pads) do
    fillRect(detailImg, pad.x, pad.y, 3, 2, PAL.leaf_pad_base)
    setPx(detailImg, pad.x + 1, pad.y, PAL.leaf_pad_high)
    setPx(detailImg, pad.x + 1, pad.y + 1, PAL.grass_deep)
  end
  -- Delicate violet-lilac hyacinth blossom with tiny golden eye
  setPx(detailImg, 160 + 16, 15, PAL.flower_hy_pur)
  setPx(detailImg, 160 + 15, 15, PAL.flower_hy_lt)
  setPx(detailImg, 160 + 16, 14, PAL.flower_gold)

  -- 6: Riverbank Strip: Bank on RIGHT edge (Land left x:0..20, Water right x:25..31)
  -- Left portion is grassy land sharing the seamless grass pattern
  renderSeamlessGrass(baseImg, 192, 0)
  -- Transition muddy slope (x: 20..24)
  for y = 0, 31 do
    setPx(baseImg, 192 + 20, y, PAL.grass_dark)
    setPx(baseImg, 192 + 21, y, PAL.mud_wet)
    setPx(baseImg, 192 + 22, y, PAL.mud_wet)
    setPx(baseImg, 192 + 23, y, PAL.path_deep)
    setPx(baseImg, 192 + 24, y, PAL.water_deep)
    -- Right portion is dark indigo water seamlessly matching River tiles
    for x = 25, 31 do
      local wave = math.sin((x * 0.4) + (y * 0.6))
      local col = PAL.water_base
      if (y % 8 == 3) and wave > 0.4 then col = PAL.water_ripple end
      if (y % 8 == 4) and wave > 0.6 then col = PAL.water_glint end
      setPx(baseImg, 192 + x, y, col)
    end
  end
  -- Bank stones & cluster of riverside reeds (lau sậy)
  setPx(detailImg, 192 + 21, 6,  PAL.stone_light)
  setPx(detailImg, 192 + 22, 7,  PAL.stone_dark)
  setPx(detailImg, 192 + 21, 23, PAL.stone_light)
  setPx(detailImg, 192 + 22, 24, PAL.stone_dark)
  -- Reed stalks along bank
  local reed_ys = { 4, 11, 18, 26 }
  for _, ry in ipairs(reed_ys) do
    drawVLine(detailImg, 192 + 20, ry, 4, PAL.reed_green)
    setPx(detailImg, 192 + 20, ry - 1, PAL.reed_plume)
    setPx(detailImg, 192 + 21, ry + 1, PAL.reed_light)
  end

  -- 7: Wooden dock. Extend the rails across each repeat so the span is continuous.
  -- Under-dock shadow / water base
  fillRect(baseImg, 224, 0, 32, 32, PAL.water_deep)
  drawHLine(baseImg, 224, 3, 32, PAL.wood_high)
  drawHLine(baseImg, 224, 4, 32, PAL.wood_base)
  drawHLine(baseImg, 224, 5, 32, PAL.wood_dark)
  drawHLine(baseImg, 224, 26, 32, PAL.wood_high)
  drawHLine(baseImg, 224, 27, 32, PAL.wood_base)
  drawHLine(baseImg, 224, 28, 32, PAL.wood_deep)
  -- Vertical dock planks running across the strip (y: 6..25)
  for px = 0, 31 do
    local isPlankGap = (px % 4 == 0)
    for py = 6, 25 do
      if isPlankGap then
        setPx(detailImg, 224 + px, py, PAL.wood_deep)
      else
        local grain = (py % 5 == 1) and PAL.wood_light or PAL.wood_base
        if px % 4 == 1 then grain = PAL.wood_high end
        setPx(detailImg, 224 + px, py, grain)
      end
    end
    -- Iron spike heads on planks near rails
    if px % 4 == 2 then
      setPx(detailImg, 224 + px, 6,  PAL.iron_dark)
      setPx(detailImg, 224 + px, 25, PAL.iron_dark)
    end
  end
end

-- ============================================================================
-- 3. PROPS (192x64): 3 cells of 64x64 (Transparent, all bottom centered)
-- Cell 0: Small Cream Farmhouse with Terracotta Roof (Centered door at base)
-- Cell 1: Low Open Shipping Chest (Harvest produce inside)
-- Cell 2: Full Shade Tree (Gnarled trunk, leafy lobes, ripe warm fruit)
-- ============================================================================
local function drawProps(baseImg, detailImg, w, h)
  -- --------------------------------------------------------------------------
  -- Cell 0: Farmhouse (64x64, center x=32, baseline y=58)
  -- --------------------------------------------------------------------------
  -- Ground shadow under farmhouse
  for sy = 56, 60 do
    drawHLine(baseImg, 8, sy, 48, PAL.shadow_ambient)
  end

  -- Cream plaster wall block (x: 14..50, y: 34..57)
  fillRect(baseImg, 14, 34, 37, 24, PAL.plaster_base)
  fillRect(detailImg, 15, 35, 35, 3, PAL.plaster_shade) -- drop shadow under eave
  drawHLine(detailImg, 14, 57, 37, PAL.plaster_deep)    -- foundation line

  -- Corner wooden pillars
  drawVLine(detailImg, 14, 34, 24, PAL.wood_base)
  drawVLine(detailImg, 50, 34, 24, PAL.wood_dark)

  -- Centered front wooden door (x: 28..35, y: 42..57) - CLEAR DOOR AT BASE
  fillRect(detailImg, 28, 42, 8, 16, PAL.wood_dark)
  fillRect(detailImg, 29, 43, 6, 14, PAL.wood_base)
  drawVLine(detailImg, 32, 43, 14, PAL.wood_deep)      -- double-door split
  setPx(detailImg, 31, 49, PAL.iron_light)             -- left brass handle
  setPx(detailImg, 33, 49, PAL.iron_light)             -- right brass handle
  drawHLine(detailImg, 28, 57, 8, PAL.stone_dark)      -- stone threshold

  -- Flanking barred windows
  -- Left window (x: 18..23, y: 43..50)
  fillRect(detailImg, 18, 43, 6, 8, PAL.wood_deep)
  drawVLine(detailImg, 20, 44, 6, PAL.wood_light)
  drawVLine(detailImg, 22, 44, 6, PAL.wood_light)
  -- Right window (x: 41..46, y: 43..50)
  fillRect(detailImg, 41, 43, 6, 8, PAL.wood_deep)
  drawVLine(detailImg, 42, 44, 6, PAL.wood_light)
  drawVLine(detailImg, 44, 44, 6, PAL.wood_light)

  -- Terracotta Roof (Mái ngói ta: hipped roof, eaves x: 8..56, y: 16..34)
  for ry = 0, 17 do
    local y = 16 + ry
    local inset = math.floor((17 - ry) * 0.95)
    local x_left = 8 + inset
    local x_right = 56 - inset
    local width = x_right - x_left + 1
    if width > 0 then
      -- Roof base fill
      fillRect(baseImg, x_left, y, width, 1, PAL.tile_base)
      -- Tile column ridges
      for rx = x_left, x_right do
        local col_mod = (rx % 4)
        if col_mod == 0 then
          setPx(detailImg, rx, y, PAL.tile_deep)
        elseif col_mod == 1 then
          setPx(detailImg, rx, y, PAL.tile_light)
        elseif col_mod == 2 then
          setPx(detailImg, rx, y, PAL.tile_base)
        else
          setPx(detailImg, rx, y, PAL.tile_shade)
        end
      end
    end
  end
  -- White lime mortar ridge cap (Bờ nóc chỉ vôi trắng x: 23..41, y: 15..17)
  drawHLine(detailImg, 23, 16, 19, PAL.mortar_white)
  drawHLine(detailImg, 24, 15, 17, PAL.tile_ridge)
  setPx(detailImg, 22, 15, PAL.mortar_white) -- curved decorative end left
  setPx(detailImg, 42, 15, PAL.mortar_white) -- curved decorative end right
  -- Scalloped eave drip edge
  for ex = 8, 56 do
    setPx(detailImg, ex, 33, (ex % 2 == 0) and PAL.tile_light or PAL.tile_shade)
    setPx(detailImg, ex, 34, PAL.tile_deep)
  end

  -- --------------------------------------------------------------------------
  -- Cell 1: Low Open Shipping Chest (64x64, center x=96, baseline y=58)
  -- --------------------------------------------------------------------------
  local cx0 = 64
  -- Ground shadow
  for sy = 56, 60 do
    drawHLine(baseImg, cx0 + 14, sy, 36, PAL.shadow_ambient)
  end

  -- Tilted open lid (x: 16..47, y: 32..40)
  fillRect(detailImg, cx0 + 17, 33, 30, 8, PAL.wood_base)
  drawHLine(detailImg, cx0 + 16, 32, 32, PAL.wood_high)
  drawHLine(detailImg, cx0 + 17, 40, 30, PAL.wood_deep)
  -- Metal hinges on lid
  drawVLine(detailImg, cx0 + 22, 33, 8, PAL.iron_dark)
  drawVLine(detailImg, cx0 + 41, 33, 8, PAL.iron_dark)

  -- Chest interior showing harvest bounties (y: 41..47, x: 18..46)
  fillRect(baseImg, cx0 + 18, 41, 28, 7, PAL.wood_deep)
  -- Burlap rice sack left
  fillRect(detailImg, cx0 + 20, 42, 7, 6, PAL.sack_burlap)
  drawHLine(detailImg, cx0 + 21, 41, 5, PAL.rice_grain)
  -- Ripe orange gourds / melons center
  fillRect(detailImg, cx0 + 28, 43, 6, 5, PAL.fruit_orange)
  setPx(detailImg, cx0 + 30, 42, PAL.fruit_amber)
  setPx(detailImg, cx0 + 31, 43, PAL.fruit_bright)
  -- Fresh green Asian greens right
  fillRect(detailImg, cx0 + 36, 42, 8, 6, PAL.veg_cabbage)
  setPx(detailImg, cx0 + 38, 41, PAL.veg_cabbage_lt)
  setPx(detailImg, cx0 + 41, 41, PAL.veg_cabbage_lt)

  -- Sturdy chest front box (x: 16..47, y: 47..57)
  fillRect(baseImg, cx0 + 16, 47, 32, 11, PAL.wood_base)
  -- Planks & grain
  drawHLine(detailImg, cx0 + 16, 47, 32, PAL.wood_high)
  drawHLine(detailImg, cx0 + 16, 52, 32, PAL.wood_deep)
  drawHLine(detailImg, cx0 + 16, 53, 32, PAL.wood_light)
  drawHLine(detailImg, cx0 + 16, 57, 32, PAL.wood_deep)
  -- Heavy iron corner brackets & front latch
  fillRect(detailImg, cx0 + 16, 47, 3, 11, PAL.iron_dark)
  fillRect(detailImg, cx0 + 45, 47, 3, 11, PAL.iron_dark)
  drawVLine(detailImg, cx0 + 31, 47, 6, PAL.iron_dark)
  setPx(detailImg, cx0 + 31, 50, PAL.iron_light) -- padlock / latch eye
  -- Rivet studs on corner straps
  setPx(detailImg, cx0 + 17, 48, PAL.iron_light)
  setPx(detailImg, cx0 + 17, 55, PAL.iron_light)
  setPx(detailImg, cx0 + 46, 48, PAL.iron_light)
  setPx(detailImg, cx0 + 46, 55, PAL.iron_light)

  -- --------------------------------------------------------------------------
  -- Cell 2: Full Shade Tree (64x64, center x=160, baseline y=58)
  -- --------------------------------------------------------------------------
  local tx0 = 128
  -- Ground shadow under canopy and roots
  for sy = 56, 61 do
    drawHLine(baseImg, tx0 + 14, sy, 36, PAL.shadow_ambient)
  end

  -- Sturdy gnarled hardwood trunk & spreading roots (y: 38..58, x: 26..38)
  fillRect(baseImg, tx0 + 29, 38, 7, 16, PAL.wood_base)
  drawVLine(detailImg, tx0 + 29, 38, 16, PAL.wood_light)
  drawVLine(detailImg, tx0 + 34, 38, 16, PAL.wood_dark)
  drawVLine(detailImg, tx0 + 35, 38, 16, PAL.wood_deep)
  -- Left root flare
  drawHLine(detailImg, tx0 + 24, 57, 6, PAL.wood_base)
  setPx(detailImg, tx0 + 23, 58, PAL.wood_dark)
  -- Right root flare
  drawHLine(detailImg, tx0 + 35, 57, 6, PAL.wood_dark)
  setPx(detailImg, tx0 + 41, 58, PAL.wood_deep)

  -- Full leafy canopy lobes (Organic pillowy clusters, highlight upper-left)
  local lobes = {
    { cx = 32, cy = 20, r = 16 }, -- main central crown
    { cx = 22, cy = 25, r = 12 }, -- lower left lobe
    { cx = 42, cy = 26, r = 12 }, -- lower right lobe
    { cx = 25, cy = 14, r = 11 }, -- upper left lobe
    { cx = 39, cy = 15, r = 11 }, -- upper right lobe
  }
  for _, l in ipairs(lobes) do
    for dy = -l.r, l.r do
      for dx = -l.r, l.r do
        local dist2 = dx * dx + dy * dy
        if dist2 <= l.r * l.r then
          local px = tx0 + l.cx + dx
          local py = l.cy + dy
          if px >= tx0 and px < tx0 + 64 and py >= 0 and py < 64 then
            -- Shading based on vector from upper-left sun
            local shade_val = (dx + dy) / (l.r * 1.4)
            local col = PAL.grass_base
            if shade_val < -0.45 then
              col = PAL.grass_high
            elseif shade_val < -0.1 then
              col = PAL.grass_light
            elseif shade_val > 0.4 then
              col = PAL.grass_deep
            elseif shade_val > 0.15 then
              col = PAL.grass_dark
            end
            setPx(baseImg, px, py, col)
          end
        end
      end
    end
  end

  -- Painterly foliage clusters & rim highlights
  local leaf_accents = {
    { x = 20, y = 14 }, { x = 27, y = 10 }, { x = 36, y = 9  },
    { x = 16, y = 23 }, { x = 28, y = 19 }, { x = 40, y = 18 },
  }
  for _, a in ipairs(leaf_accents) do
    setPx(detailImg, tx0 + a.x,     a.y,     PAL.grass_high)
    setPx(detailImg, tx0 + a.x + 1, a.y,     PAL.grass_high)
    setPx(detailImg, tx0 + a.x,     a.y + 1, PAL.grass_light)
  end

  -- Warm ripe fruit clusters (Chùm quả chín vàng cam trĩu cành)
  local fruits = {
    { x = 22, y = 22 }, { x = 24, y = 23 },
    { x = 33, y = 18 }, { x = 35, y = 19 },
    { x = 42, y = 24 }, { x = 44, y = 25 },
    { x = 27, y = 30 }, { x = 29, y = 31 },
    { x = 37, y = 28 }, { x = 39, y = 29 },
  }
  for _, f in ipairs(fruits) do
    setPx(detailImg, tx0 + f.x, f.y, PAL.fruit_amber)
    setPx(detailImg, tx0 + f.x + 1, f.y, PAL.fruit_orange)
    setPx(detailImg, tx0 + f.x, f.y - 1, PAL.fruit_bright) -- sunlit glint
  end
end

-- ============================================================================
-- 4. VILLAGE STALL (128x96): Transparent Seed Shop
-- Terracotta roof, seed shelves with ceramic jars, counter with open grain sacks
-- ============================================================================
local function drawVillageStall(baseImg, detailImg, w, h)
  -- Center x = 64, baseline y = 90
  -- Ground shadow
  for sy = 88, 93 do
    drawHLine(baseImg, 16, sy, 96, PAL.shadow_ambient)
  end

  -- 4 Main timber support posts (x: 22..24, 48..50, 77..79, 103..105, y: 26..89)
  local posts = { 22, 48, 77, 103 }
  for _, px in ipairs(posts) do
    fillRect(baseImg, px, 26, 3, 64, PAL.wood_base)
    drawVLine(detailImg, px, 26, 64, PAL.wood_light)
    drawVLine(detailImg, px + 2, 26, 64, PAL.wood_deep)
  end

  -- Back plaster wall & shelving (x: 26..101, y: 32..65)
  fillRect(baseImg, 26, 32, 76, 33, PAL.plaster_shade)
  -- 2 Wooden shelves across back wall
  drawHLine(detailImg, 26, 42, 76, PAL.wood_light)
  drawHLine(detailImg, 26, 43, 76, PAL.wood_dark)
  drawHLine(detailImg, 26, 54, 76, PAL.wood_light)
  drawHLine(detailImg, 26, 55, 76, PAL.wood_dark)

  -- Ceramic Seed Jars on Shelves (Chum sành Bát Tràng with linen cloth ties)
  local jars = {
    { x = 32, y = 35 }, { x = 40, y = 35 }, { x = 60, y = 35 },
    { x = 68, y = 35 }, { x = 86, y = 35 }, { x = 94, y = 35 },
    { x = 34, y = 47 }, { x = 44, y = 47 }, { x = 84, y = 47 },
  }
  for _, j in ipairs(jars) do
    fillRect(detailImg, j.x, j.y + 2, 5, 5, PAL.wood_dark)
    setPx(detailImg, j.x + 1, j.y + 3, PAL.path_light) -- ceramic glaze sheen
    drawHLine(detailImg, j.x, j.y + 1, 5, PAL.plaster_light) -- cloth cover
    drawHLine(detailImg, j.x + 1, j.y + 2, 3, PAL.wood_deep) -- cord tie
  end

  -- Braids of dried red chilis & garlic hanging under eaves
  for cy = 0, 5 do
    setPx(detailImg, 53, 34 + cy * 2, (cy % 2 == 0) and PAL.bean_red or PAL.tile_light)
    setPx(detailImg, 73, 34 + cy * 2, (cy % 2 == 0) and PAL.flower_white or PAL.flower_cream)
  end

  -- Front Wooden Counter (x: 20..107, y: 65..89)
  fillRect(baseImg, 20, 65, 88, 24, PAL.wood_base)
  -- Counter top ledge
  drawHLine(detailImg, 18, 64, 92, PAL.wood_high)
  drawHLine(detailImg, 18, 65, 92, PAL.wood_light)
  drawHLine(detailImg, 18, 66, 92, PAL.wood_dark)
  -- Vertical front planks
  for x = 20, 107 do
    if x % 6 == 0 then
      drawVLine(detailImg, x, 67, 22, PAL.wood_deep)
    end
  end

  -- 3 Large Open Burlap Seed Sacks on Counter
  -- 1. Left Sack: Golden Rice Seed (Lúa giống)
  fillRect(detailImg, 28, 68, 16, 17, PAL.sack_burlap)
  drawHLine(detailImg, 27, 67, 18, PAL.sack_shade) -- rolled burlap rim
  fillRect(detailImg, 29, 68, 14, 5, PAL.rice_gold)
  setPx(detailImg, 32, 69, PAL.rice_grain)
  setPx(detailImg, 37, 70, PAL.rice_grain)

  -- 2. Center Sack: Green Mung Beans (Đậu xanh)
  fillRect(detailImg, 56, 68, 16, 17, PAL.sack_burlap)
  drawHLine(detailImg, 55, 67, 18, PAL.sack_shade)
  fillRect(detailImg, 57, 68, 14, 5, PAL.bean_green)
  setPx(detailImg, 60, 69, PAL.grass_high)
  setPx(detailImg, 65, 70, PAL.grass_high)

  -- 3. Right Sack: Dark Red Beans (Đậu đỏ)
  fillRect(detailImg, 84, 68, 16, 17, PAL.sack_burlap)
  drawHLine(detailImg, 83, 67, 18, PAL.sack_shade)
  fillRect(detailImg, 85, 68, 14, 5, PAL.bean_red)
  setPx(detailImg, 88, 69, PAL.tile_light)
  setPx(detailImg, 93, 70, PAL.tile_light)

  -- Wooden seed scoop resting on center sack
  drawHLine(detailImg, 68, 66, 4, PAL.wood_high)
  setPx(detailImg, 72, 65, PAL.wood_light)

  -- Rich Terracotta Roof (x: 10..117, y: 10..32)
  for ry = 0, 21 do
    local y = 10 + ry
    local inset = math.floor((21 - ry) * 0.8)
    local x1 = 10 + inset
    local x2 = 117 - inset
    local w_span = x2 - x1 + 1
    if w_span > 0 then
      fillRect(baseImg, x1, y, w_span, 1, PAL.tile_base)
      for rx = x1, x2 do
        local m = (rx % 4)
        if m == 0 then
          setPx(detailImg, rx, y, PAL.tile_deep)
        elseif m == 1 then
          setPx(detailImg, rx, y, PAL.tile_light)
        elseif m == 2 then
          setPx(detailImg, rx, y, PAL.tile_base)
        else
          setPx(detailImg, rx, y, PAL.tile_shade)
        end
      end
    end
  end
  -- White lime ridge roll cap (x: 28..99, y: 9..11)
  drawHLine(detailImg, 28, 10, 72, PAL.mortar_white)
  drawHLine(detailImg, 29, 9, 70, PAL.tile_ridge)
  setPx(detailImg, 27, 9, PAL.mortar_white)
  setPx(detailImg, 100, 9, PAL.mortar_white)
  -- Scalloped eave drip edge
  for ex = 10, 117 do
    setPx(detailImg, ex, 31, (ex % 2 == 0) and PAL.tile_light or PAL.tile_shade)
    setPx(detailImg, ex, 32, PAL.tile_deep)
  end
end

-- ============================================================================
-- 5. MARKET BOOTH (96x64): Transparent Fabric Awning & Produce Crates
-- Cream-and-blue striped awning, timber frame, bountiful market crates
-- ============================================================================
local function drawMarketBooth(baseImg, detailImg, w, h)
  -- Center x = 48, baseline y = 60
  -- Ground shadow
  for sy = 58, 62 do
    drawHLine(baseImg, 10, sy, 76, PAL.shadow_ambient)
  end

  -- 4 Wooden timber poles (x: 14, 38, 58, 80, y: 22..59)
  local poles = { 14, 80, 38, 58 }
  for _, px in ipairs(poles) do
    fillRect(baseImg, px, 22, 2, 38, PAL.wood_base)
    setPx(detailImg, px, 22, PAL.wood_light)
    drawVLine(detailImg, px + 1, 22, 38, PAL.wood_dark)
  end

  -- Produce Crates & Slanted Rack (x: 16..78, y: 38..59)
  fillRect(baseImg, 16, 38, 64, 21, PAL.wood_base)
  -- Rack slats
  drawHLine(detailImg, 15, 38, 66, PAL.wood_high)
  drawHLine(detailImg, 15, 48, 66, PAL.wood_dark)
  drawHLine(detailImg, 15, 58, 66, PAL.wood_deep)
  drawVLine(detailImg, 37, 39, 20, PAL.wood_deep)
  drawVLine(detailImg, 57, 39, 20, PAL.wood_deep)

  -- Produce Crate 1 (Left): Round Striped Watermelons (Dưa hấu)
  for my = 40, 46 do
    for mx = 18, 35 do
      if (mx + my) % 3 == 0 then
        setPx(detailImg, mx, my, PAL.melon_dark)
      else
        setPx(detailImg, mx, my, PAL.melon_light)
      end
    end
  end

  -- Produce Crate 2 (Center): Bright Orange Carrots with leafy green tops
  for cy = 41, 46 do
    for cx = 40, 54 do
      if (cx % 3 == 0) then
        setPx(detailImg, cx, cy, PAL.carrot_org)
      elseif (cx % 3 == 1) then
        setPx(detailImg, cx, cy, PAL.fruit_amber)
      else
        setPx(detailImg, cx, cy, PAL.grass_high) -- carrot top greens
      end
    end
  end

  -- Produce Crate 3 (Right): Asian Greens & Cabbages (Rau cải / bắp cải)
  for gy = 40, 46 do
    for gx = 60, 75 do
      if (gx + gy) % 2 == 0 then
        setPx(detailImg, gx, gy, PAL.veg_cabbage)
      else
        setPx(detailImg, gx, gy, PAL.veg_cabbage_lt)
      end
    end
  end

  -- Striped Fabric Awning (x: 10..85, y: 8..27)
  -- Bold alternating 5px stripes: Indigo Blue and Warm Cream
  for ay = 0, 16 do
    local y = 8 + ay
    local inset = math.floor((16 - ay) * 0.4)
    local x1 = 10 + inset
    local x2 = 85 - inset
    for x = x1, x2 do
      local stripe_idx = math.floor((x - 10) / 6) % 2
      local col_base, col_lt, col_dk
      if stripe_idx == 0 then
        -- Blue stripe
        col_base = PAL.awning_blue
        col_lt = PAL.awning_blue_lt
        col_dk = PAL.awning_blue_dk
      else
        -- Cream stripe
        col_base = PAL.awning_crm
        col_lt = PAL.awning_crm_lt
        col_dk = PAL.awning_crm_dk
      end

      -- Shade with canopy curvature
      local final_col = col_base
      if ay == 0 or (x % 6 == 1) then
        final_col = col_lt
      elseif ay > 13 or (x % 6 == 0) then
        final_col = col_dk
      end
      setPx(baseImg, x, y, final_col)
    end
  end

  -- Scalloped fabric fringe at front hem (y: 25..27)
  for fx = 10, 85 do
    local isFringePeak = (fx % 4 == 0 or fx % 4 == 1)
    setPx(detailImg, fx, 25, isFringePeak and PAL.awning_crm_lt or PAL.awning_blue_lt)
    setPx(detailImg, fx, 26, isFringePeak and PAL.awning_crm or PAL.awning_blue)
    if isFringePeak then
      setPx(detailImg, fx, 27, PAL.awning_blue_dk)
    end
  end
end

-- ============================================================================
-- 6. SHOP SIGN (32x32): Transparent Hanging Wooden Sign with Seed-Bag Emblem
-- ============================================================================
local function drawShopSign(baseImg, detailImg, w, h)
  -- Baseline at y = 30
  -- Ground post hole shadow
  setPx(baseImg, 6, 30, PAL.shadow_ambient)
  setPx(baseImg, 7, 30, PAL.shadow_ambient)
  setPx(baseImg, 8, 30, PAL.shadow_ambient)

  -- Vertical timber support post (x: 6..8, y: 4..30)
  fillRect(baseImg, 6, 4, 3, 27, PAL.wood_base)
  drawVLine(detailImg, 6, 4, 27, PAL.wood_light)
  drawVLine(detailImg, 8, 4, 27, PAL.wood_deep)

  -- Wrought-iron cantilever arm (x: 8..26, y: 5..7)
  drawHLine(detailImg, 8, 5, 18, PAL.iron_dark)
  drawHLine(detailImg, 9, 6, 17, PAL.iron_light)
  -- Diagonal iron scroll brace
  setPx(detailImg, 8, 8, PAL.iron_dark)
  setPx(detailImg, 9, 7, PAL.iron_dark)
  setPx(detailImg, 10, 6, PAL.iron_dark)

  -- Hanging iron link chains (x: 13, 23, y: 7..9)
  drawVLine(detailImg, 13, 7, 3, PAL.iron_light)
  drawVLine(detailImg, 23, 7, 3, PAL.iron_light)

  -- Hanging wooden sign board (x: 11..25, y: 10..23)
  fillRect(baseImg, 11, 10, 15, 14, PAL.wood_base)
  -- Beveled sign board edges
  drawHLine(detailImg, 11, 10, 15, PAL.wood_high)
  drawVLine(detailImg, 11, 10, 14, PAL.wood_light)
  drawHLine(detailImg, 11, 23, 15, PAL.wood_deep)
  drawVLine(detailImg, 25, 10, 14, PAL.wood_dark)

  -- Seed-Bag Emblem centered on board (x: 15..21, y: 13..20)
  -- Tied pouch body
  fillRect(detailImg, 15, 15, 7, 5, PAL.sack_burlap)
  drawHLine(detailImg, 16, 14, 5, PAL.sack_shade) -- tied cinch neck
  drawHLine(detailImg, 15, 13, 7, PAL.sack_burlap) -- flared bag ruffle
  -- Sprouting green leaf emblem from knot
  setPx(detailImg, 18, 12, PAL.grass_high)
  setPx(detailImg, 19, 11, PAL.grass_high)
  setPx(detailImg, 17, 12, PAL.grass_deep)
  -- Golden seed dot on bag
  setPx(detailImg, 18, 17, PAL.rice_gold)
end

-- ============================================================================
-- 7. VILLAGE BOARD (32x32): Transparent Rustic Notice Board
-- Twin posts, shingle rain cap, two cream notice sheets with handwriting
-- ============================================================================
local function drawVillageBoard(baseImg, detailImg, w, h)
  -- Baseline at y = 30
  -- Ground shadow under posts
  setPx(baseImg, 5, 30, PAL.shadow_ambient)
  setPx(baseImg, 6, 30, PAL.shadow_ambient)
  setPx(baseImg, 25, 30, PAL.shadow_ambient)
  setPx(baseImg, 26, 30, PAL.shadow_ambient)

  -- Twin vertical timber posts (x: 5..6 and 25..26, y: 6..30)
  fillRect(baseImg, 5, 6, 2, 25, PAL.wood_base)
  drawVLine(detailImg, 5, 6, 25, PAL.wood_light)
  drawVLine(detailImg, 6, 6, 25, PAL.wood_deep)

  fillRect(baseImg, 25, 6, 2, 25, PAL.wood_base)
  drawVLine(detailImg, 25, 6, 25, PAL.wood_light)
  drawVLine(detailImg, 26, 6, 25, PAL.wood_deep)

  -- Wooden backing board (x: 4..27, y: 8..23)
  fillRect(baseImg, 4, 8, 24, 16, PAL.wood_dark)
  -- Horizontal plank lines
  drawHLine(detailImg, 4, 12, 24, PAL.wood_deep)
  drawHLine(detailImg, 4, 17, 24, PAL.wood_deep)
  drawHLine(detailImg, 4, 22, 24, PAL.wood_deep)

  -- Rustic Shingle Rain-Cap Roof on top (x: 3..28, y: 4..7)
  fillRect(baseImg, 3, 5, 26, 3, PAL.tile_base)
  drawHLine(detailImg, 3, 4, 26, PAL.tile_ridge)
  drawHLine(detailImg, 3, 7, 26, PAL.tile_deep)
  for rx = 3, 28 do
    if rx % 4 == 0 then
      drawVLine(detailImg, rx, 5, 2, PAL.tile_shade)
    end
  end

  -- Sheet 1 (Left): Cream notice sheet pinned with red pin (x: 7..14, y: 11..21)
  fillRect(detailImg, 7, 11, 8, 11, PAL.plaster_light)
  drawHLine(detailImg, 7, 21, 8, PAL.plaster_shade)
  drawVLine(detailImg, 14, 11, 11, PAL.plaster_shade)
  -- Red map pin at top center
  setPx(detailImg, 10, 11, PAL.pin_red)
  setPx(detailImg, 10, 10, PAL.flower_coral)
  -- Simulated handwriting script lines
  drawHLine(detailImg, 8, 14, 5, PAL.plaster_deep)
  drawHLine(detailImg, 8, 16, 6, PAL.plaster_deep)
  drawHLine(detailImg, 8, 18, 4, PAL.plaster_deep)

  -- Sheet 2 (Right): Slightly smaller cream notice sheet (x: 16..24, y: 13..22)
  fillRect(detailImg, 16, 13, 9, 10, PAL.plaster_base)
  drawHLine(detailImg, 16, 22, 9, PAL.plaster_shade)
  drawVLine(detailImg, 24, 13, 10, PAL.plaster_shade)
  -- Dark pin
  setPx(detailImg, 20, 13, PAL.iron_dark)
  -- Simulated script lines & red village stamp mark
  drawHLine(detailImg, 18, 15, 5, PAL.plaster_deep)
  drawHLine(detailImg, 18, 17, 6, PAL.plaster_deep)
  drawHLine(detailImg, 18, 19, 4, PAL.plaster_deep)
  setPx(detailImg, 22, 19, PAL.pin_red) -- red square village seal
  setPx(detailImg, 23, 19, PAL.pin_red)
end

-- ============================================================================
-- 8. FISHING SPOT (32x32): Tackle Crate, Bamboo Rod, Red/Cream Float
-- Distinct clear silhouette, transparent background, bottom center anchor
-- ============================================================================
local function drawFishingSpot(baseImg, detailImg, w, h)
  -- Baseline at y = 30
  -- Ground shadow
  for sy = 28, 30 do
    drawHLine(baseImg, 4, sy, 24, PAL.shadow_ambient)
  end

  -- Wooden Tackle Crate (x: 5..18, y: 18..29)
  fillRect(baseImg, 5, 18, 14, 12, PAL.wood_base)
  -- Crate lid bevel
  drawHLine(detailImg, 5, 18, 14, PAL.wood_high)
  drawHLine(detailImg, 5, 21, 14, PAL.wood_deep)
  drawHLine(detailImg, 5, 29, 14, PAL.wood_deep)
  -- Brass corner reinforcements & latch
  fillRect(detailImg, 5, 18, 2, 12, PAL.wood_dark)
  fillRect(detailImg, 17, 18, 2, 12, PAL.wood_dark)
  setPx(detailImg, 11, 22, PAL.fruit_bright) -- brass lock hasp
  setPx(detailImg, 11, 23, PAL.fruit_amber)

  -- Metal Bait Bucket / Can beside crate (x: 19..24, y: 22..29)
  fillRect(detailImg, 19, 22, 6, 8, PAL.stone_dark)
  drawHLine(detailImg, 19, 22, 6, PAL.stone_light)
  drawVLine(detailImg, 20, 23, 6, PAL.stone_light)
  drawHLine(detailImg, 19, 29, 6, PAL.wood_deep)
  -- Wire bucket handle arching up
  setPx(detailImg, 19, 20, PAL.stone_light)
  setPx(detailImg, 20, 19, PAL.stone_light)
  setPx(detailImg, 21, 19, PAL.stone_light)

  -- Slender Bamboo Fishing Rod (Cần câu trúc: running diagonally from (5, 27) to (27, 4))
  local rod_points = {
    { x = 5,  y = 27 }, { x = 6,  y = 25 }, { x = 7,  y = 23 },
    { x = 9,  y = 21 }, { x = 10, y = 19 }, { x = 12, y = 17 },
    { x = 14, y = 15 }, { x = 16, y = 13 }, { x = 18, y = 11 },
    { x = 20, y = 9  }, { x = 23, y = 7  }, { x = 25, y = 5  },
    { x = 27, y = 4  },
  }
  for i, pt in ipairs(rod_points) do
    setPx(baseImg, pt.x, pt.y, PAL.wood_high)
    if i % 3 == 0 then
      setPx(detailImg, pt.x, pt.y, PAL.wood_deep) -- bamboo segment node
    else
      setPx(detailImg, pt.x, pt.y, PAL.path_high)
    end
  end

  -- Fine fishing line dropping from rod tip at (27, 4) down to float
  drawVLine(detailImg, 26, 5, 8, PAL.stone_light)

  -- Classic Red & Cream Fishing Bobber / Float (x: 25..27, y: 13..17)
  -- Top red hemisphere
  fillRect(detailImg, 25, 13, 3, 2, PAL.float_red)
  setPx(detailImg, 26, 12, PAL.flower_coral) -- tip quill
  -- Bottom cream hemisphere
  fillRect(detailImg, 25, 15, 3, 2, PAL.float_white)
  setPx(detailImg, 26, 17, PAL.stone_dark)   -- bottom stem
  -- Dark waterline ring
  drawHLine(detailImg, 25, 14, 3, PAL.tile_deep)
end

-- ============================================================================
-- 9. WAYFINDING (64x32): Two 32x32 Transparent Wooden Directional Signs
-- First sign (x: 0..31): points RIGHT with dark carved arrow & edge highlight
-- Second sign (x: 32..63): points LEFT with dark carved arrow & edge highlight
-- No text!
-- ============================================================================
local function drawWayfinding(baseImg, detailImg, w, h)
  -- --------------------------------------------------------------------------
  -- Sign 1 (Cell 0, x: 0..31): Points RIGHT
  -- --------------------------------------------------------------------------
  -- Ground shadow under post
  setPx(baseImg, 8, 30, PAL.shadow_ambient)
  setPx(baseImg, 9, 30, PAL.shadow_ambient)
  setPx(baseImg, 10, 30, PAL.shadow_ambient)

  -- Vertical timber support post (x: 8..10, y: 12..30)
  fillRect(baseImg, 8, 12, 3, 19, PAL.wood_base)
  drawVLine(detailImg, 8, 12, 19, PAL.wood_light)
  drawVLine(detailImg, 10, 12, 19, PAL.wood_deep)

  -- Horizontal wooden arrow plank pointing RIGHT (x: 5..27, y: 8..17)
  -- Rectangular body (x: 5..22, y: 8..17)
  fillRect(baseImg, 5, 8, 18, 10, PAL.wood_base)
  -- Arrow point chevron at right (x: 23..27)
  for ax = 0, 4 do
    local y_span = 4 - ax
    drawVLine(baseImg, 23 + ax, 12 - y_span, y_span * 2 + 1, PAL.wood_base)
  end

  -- Beveled edge highlights & shadows
  drawHLine(detailImg, 5, 8, 18, PAL.wood_high)
  drawVLine(detailImg, 5, 8, 10, PAL.wood_light)
  drawHLine(detailImg, 5, 17, 18, PAL.wood_deep)
  -- Chevron edges
  for ax = 0, 4 do
    setPx(detailImg, 23 + ax, 8 + ax, PAL.wood_high)
    setPx(detailImg, 23 + ax, 17 - ax, PAL.wood_deep)
  end

  -- Dark carved arrow pointing RIGHT (x: 9..23, y: 11..14)
  drawHLine(detailImg, 9, 12, 10, PAL.wood_deep)
  drawHLine(detailImg, 9, 13, 10, PAL.wood_deep)
  -- Arrowhead
  setPx(detailImg, 19, 11, PAL.wood_deep)
  setPx(detailImg, 19, 14, PAL.wood_deep)
  setPx(detailImg, 20, 12, PAL.wood_deep)
  setPx(detailImg, 20, 13, PAL.wood_deep)
  setPx(detailImg, 21, 12, PAL.wood_deep)
  setPx(detailImg, 21, 13, PAL.wood_deep)
  setPx(detailImg, 22, 12, PAL.wood_deep)
  -- Sunlit rim inside carved groove
  drawHLine(detailImg, 9, 11, 10, PAL.wood_light)

  -- --------------------------------------------------------------------------
  -- Sign 2 (Cell 1, x: 32..63): Points LEFT
  -- --------------------------------------------------------------------------
  local ox = 32
  -- Ground shadow under post
  setPx(baseImg, ox + 21, 30, PAL.shadow_ambient)
  setPx(baseImg, ox + 22, 30, PAL.shadow_ambient)
  setPx(baseImg, ox + 23, 30, PAL.shadow_ambient)

  -- Vertical timber support post (x: 21..23, y: 12..30)
  fillRect(baseImg, ox + 21, 12, 3, 19, PAL.wood_base)
  drawVLine(detailImg, ox + 21, 12, 19, PAL.wood_light)
  drawVLine(detailImg, ox + 23, 12, 19, PAL.wood_deep)

  -- Horizontal wooden arrow plank pointing LEFT (x: 4..26, y: 8..17)
  -- Rectangular body (x: 9..26, y: 8..17)
  fillRect(baseImg, ox + 9, 8, 18, 10, PAL.wood_base)
  -- Arrow point chevron at left (x: 4..8)
  for ax = 0, 4 do
    local y_span = ax
    drawVLine(baseImg, ox + 4 + ax, 12 - y_span, y_span * 2 + 1, PAL.wood_base)
  end

  -- Beveled edge highlights & shadows
  drawHLine(detailImg, ox + 9, 8, 18, PAL.wood_high)
  drawVLine(detailImg, ox + 26, 8, 10, PAL.wood_deep)
  drawHLine(detailImg, ox + 9, 17, 18, PAL.wood_deep)
  -- Chevron edges
  for ax = 0, 4 do
    setPx(detailImg, ox + 8 - ax, 8 + ax, PAL.wood_high)
    setPx(detailImg, ox + 8 - ax, 17 - ax, PAL.wood_deep)
  end

  -- Dark carved arrow pointing LEFT (x: 8..22, y: 11..14)
  drawHLine(detailImg, ox + 13, 12, 10, PAL.wood_deep)
  drawHLine(detailImg, ox + 13, 13, 10, PAL.wood_deep)
  -- Arrowhead
  setPx(detailImg, ox + 12, 11, PAL.wood_deep)
  setPx(detailImg, ox + 12, 14, PAL.wood_deep)
  setPx(detailImg, ox + 11, 12, PAL.wood_deep)
  setPx(detailImg, ox + 11, 13, PAL.wood_deep)
  setPx(detailImg, ox + 10, 12, PAL.wood_deep)
  setPx(detailImg, ox + 10, 13, PAL.wood_deep)
  setPx(detailImg, ox + 9,  12, PAL.wood_deep)
  -- Sunlit rim inside carved groove
  drawHLine(detailImg, ox + 13, 11, 10, PAL.wood_light)
end

-- ============================================================================
-- Generator Engine & Export Routine
-- ============================================================================
local function generateAsset(name, width, height, renderFunc)
  print(string.format("Generating %s (%dx%d)...", name, width, height))
  local spr = Sprite(width, height, ColorMode.RGB)

  -- Setup Layer 1: "Base"
  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"
  local baseCel = baseLayer:cel(1)
  if not baseCel then
    baseCel = spr:newCel(baseLayer, 1, Image(width, height, ColorMode.RGB), Point(0, 0))
  else
    baseCel.image:clear(PAL.trans)
  end
  local baseImg = baseCel.image

  -- Setup Layer 2: "Detail"
  local detailLayer = spr:newLayer()
  detailLayer.name = "Detail"
  local detailImg = Image(width, height, ColorMode.RGB)
  detailImg:clear(PAL.trans)

  -- Render art using procedural primitives and painterly stamps
  renderFunc(baseImg, detailImg, width, height)
  spr:newCel(detailLayer, 1, detailImg, Point(0, 0))

  -- Save editable layered .aseprite file to source_dir
  local aseFile = joinPath(source_dir, name .. ".aseprite")
  spr:saveAs(aseFile)

  -- Export flattened RGBA .png file to out_dir
  local pngFile = joinPath(out_dir, name .. ".png")
  spr:saveCopyAs(pngFile)

  spr:close()
  print(string.format("Saved %s and %s successfully.", aseFile, pngFile))
end

-- ============================================================================
-- Main Generation Pipeline
-- ============================================================================
local ASSET_MANIFEST = {
  { name = "terrain",         width = 288, height = 32, draw = drawTerrain        },
  { name = "village_terrain", width = 256, height = 32, draw = drawVillageTerrain },
  { name = "props",           width = 192, height = 64, draw = drawProps         },
  { name = "village_stall",   width = 128, height = 96, draw = drawVillageStall   },
  { name = "market_booth",    width = 96,  height = 64, draw = drawMarketBooth    },
  { name = "shop_sign",       width = 32,  height = 32, draw = drawShopSign       },
  { name = "village_board",   width = 32,  height = 32, draw = drawVillageBoard   },
  { name = "fishing_spot",    width = 32,  height = 32, draw = drawFishingSpot    },
  { name = "wayfinding",      width = 64,  height = 32, draw = drawWayfinding     },
}

for _, asset in ipairs(ASSET_MANIFEST) do
  generateAsset(asset.name, asset.width, asset.height, asset.draw)
end

print("All 9 Vườn Nhỏ 32px world and environment assets generated successfully!")
