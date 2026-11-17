-- ============================================================================
-- Vườn Nhỏ - Vietnamese Village 32px Pixel Art Life Redraw Generator
-- Standalone Aseprite v1.3.15.5-dev Lua Batch Script
--
-- Redraws all characters, crops, seed bags, and fish at native 32px resolution:
--   1. player.png (96x192): 3 cols (idle, step A, step B) x 4 rows (down, left, right, up)
--   2. village_people.png (64x48): Cô Huệ (seed seller) & Bác Bảy (riverside cook)
--   3. crops.png (96x32): Cabbage (seed/mound, sprout, mature layered head)
--   4. carrots.png (96x32): Carrot (seed/mound, sprout, mature tapered root & fern greens)
--   5. radishes.png (96x32): White radish (seed/mound, sprout, mature white root & lobed greens)
--   6. seed_bags.png (64x32): Cabbage & carrot seed bags (warm canvas, tied, symbols)
--   7. radish_seed.png (32x32): White radish seed bag (complementary canvas & emblem)
--   8. fish.png (96x32): Cá Rô (perch), Cá Trê (catfish), Cá Chép (carp) swimming left
--
-- Palette: Warm Vietnamese village (terracotta, toasted straw, moss greens, jade, rust, indigo)
-- Lighting: Upper-left, selective outlines, organic pixel clusters, clean silhouettes.
-- Structure: Layered editable .aseprite (Base + Detail) in source_dir, flat RGBA PNG in out_dir.
-- ============================================================================

-- Read script parameters with robust fallbacks
local source_dir = (app.params and app.params["source_dir"]) or "art/32"
local out_dir = (app.params and app.params["out_dir"]) or "assets/art/32"

-- Ensure target directories exist
if app.fs and app.fs.makeAllDirectories then
  pcall(function() app.fs.makeAllDirectories(source_dir) end)
  pcall(function() app.fs.makeAllDirectories(out_dir) end)
end

-- Path joining helper compatible with Windows and forward slashes
local function joinPath(dir, filename)
  if app.fs and app.fs.joinPath then
    return app.fs.joinPath(dir, filename)
  end
  local clean_dir = tostring(dir):gsub("[/\\]+$", "")
  local sep = clean_dir:find("\\") and "\\" or "/"
  return clean_dir .. sep .. filename
end

-- Fast 32-bit RGBA color builder
local function rgba(r, g, b, a)
  a = a or 255
  if app.pixelColor and app.pixelColor.rgba then
    return app.pixelColor.rgba(r, g, b, a)
  elseif Color then
    return Color{ r = r, g = g, b = b, a = a }
  else
    return r + g * 256 + b * 65536 + a * 16777216
  end
end

-- ============================================================================
-- Cohesive Vietnamese Village 32px Palette
-- Warm, earthy, sun-drenched Vietnamese rural landscape
-- ============================================================================

-- Deep selective outlines & ink shadows
local C_INK               = rgba(0x14, 0x0f, 0x0c)
local C_DARK_BROWN         = rgba(0x28, 0x18, 0x10)

-- Rich countryside tilled soil & wood loam
local C_SOIL_SHADOW        = rgba(0x38, 0x1e, 0x12)
local C_SOIL_DARK          = rgba(0x56, 0x2e, 0x18)
local C_SOIL_MID           = rgba(0x7c, 0x46, 0x24)
local C_SOIL_LIGHT         = rgba(0xa6, 0x64, 0x34)
local C_SOIL_CREST         = rgba(0xc8, 0x84, 0x4a)

-- Golden toasted straw & bamboo (Nón lá, woven hats, baskets)
local C_STRAW_DEEP         = rgba(0x7e, 0x4e, 0x20)
local C_STRAW_SHADOW       = rgba(0xaa, 0x72, 0x34)
local C_STRAW_MID          = rgba(0xd4, 0x9e, 0x4e)
local C_STRAW_LIGHT        = rgba(0xee, 0xc4, 0x78)
local C_STRAW_HIGHLIGHT    = rgba(0xfc, 0xe4, 0xaa)

-- Warm sun-kissed Vietnamese peasant skin
local C_SKIN_SHADOW        = rgba(0xb4, 0x72, 0x48)
local C_SKIN_MID           = rgba(0xdc, 0x98, 0x6e)
local C_SKIN_LIGHT         = rgba(0xf2, 0xc0, 0x98)
local C_SKIN_HIGHLIGHT     = rgba(0xfc, 0xdc, 0xbe)

-- Traditional indigo blue (Áo bà ba, Bác Bảy, Catfish)
local C_INDIGO_INK         = rgba(0x10, 0x18, 0x26)
local C_INDIGO_DARK        = rgba(0x1c, 0x2e, 0x46)
local C_INDIGO_MID         = rgba(0x2e, 0x4c, 0x72)
local C_INDIGO_BRIGHT      = rgba(0x42, 0x6e, 0xa0)
local C_INDIGO_LIGHT       = rgba(0x68, 0x9a, 0xcc)
local C_INDIGO_HIGHLIGHT   = rgba(0x9c, 0xc6, 0xec)

-- Peasant trousers & charcoal cotton
local C_TROUSER_DARK       = rgba(0x18, 0x1a, 0x22)
local C_TROUSER_MID        = rgba(0x28, 0x2b, 0x38)
local C_TROUSER_LIGHT      = rgba(0x40, 0x46, 0x5a)

-- Terracotta, rust, and warm sashes (Cô Huệ, roof tiles, carp, sashes)
local C_RUST_DARK          = rgba(0x56, 0x16, 0x12)
local C_TERRA_DARK         = rgba(0x82, 0x26, 0x1c)
local C_TERRA_MID          = rgba(0xb4, 0x3e, 0x28)
local C_TERRA_LIGHT        = rgba(0xdc, 0x5a, 0x3e)
local C_TERRA_HIGHLIGHT    = rgba(0xf0, 0x82, 0x64)
local C_SASH_GOLD          = rgba(0xd4, 0x7e, 0x24)
local C_SASH_LIGHT         = rgba(0xf6, 0xa8, 0x44)

-- Ripe carrot orange
local C_CARROT_SHADOW      = rgba(0x9a, 0x30, 0x14)
local C_CARROT_MID         = rgba(0xd8, 0x50, 0x1c)
local C_CARROT_BRIGHT      = rgba(0xf2, 0x74, 0x26)
local C_CARROT_LIGHT       = rgba(0xfb, 0x9e, 0x48)
local C_CARROT_HIGHLIGHT   = rgba(0xfd, 0xc4, 0x7c)

-- Vietnamese leaf greens, moss & jade (Cabbage, foliage, Cá Rô)
local C_LEAF_INK           = rgba(0x0e, 0x20, 0x10)
local C_LEAF_SHADOW        = rgba(0x1a, 0x38, 0x1c)
local C_LEAF_MID           = rgba(0x2e, 0x5c, 0x28)
local C_LEAF_GREEN         = rgba(0x48, 0x86, 0x34)
local C_LEAF_BRIGHT        = rgba(0x6e, 0xae, 0x44)
local C_LEAF_LIME          = rgba(0x9e, 0xd6, 0x5a)
local C_LEAF_TENDER        = rgba(0xc8, 0xee, 0x7e)
local C_JADE_DARK          = rgba(0x18, 0x3a, 0x34)
local C_JADE_MID           = rgba(0x2e, 0x5e, 0x54)
local C_JADE_LIGHT         = rgba(0x4e, 0x8e, 0x7e)

-- White radish root, burlap canvas & cook scarf (Khăn rằn)
local C_CANVAS_SHADOW      = rgba(0x9a, 0x7a, 0x54)
local C_CANVAS_MID         = rgba(0xc2, 0xa0, 0x76)
local C_CANVAS_LIGHT       = rgba(0xe2, 0xc8, 0xa4)
local C_CANVAS_HIGHLIGHT   = rgba(0xf6, 0xe6, 0xcc)
local C_RADISH_ROOT_SHADOW = rgba(0x92, 0x9a, 0x90)
local C_RADISH_ROOT_MID    = rgba(0xc4, 0xcc, 0xc2)
local C_RADISH_ROOT_WHITE  = rgba(0xec, 0xf2, 0xea)
local C_RADISH_ROOT_BRIGHT = rgba(0xfc, 0xfe, 0xf8)
local C_SCARF_GREY         = rgba(0x4a, 0x54, 0x54)
local C_SCARF_LIGHT        = rgba(0xda, 0xde, 0xda)

-- Cá Rô (Green silver perch)
local C_RO_BACK_DARK       = rgba(0x22, 0x36, 0x1c)
local C_RO_BACK_MID        = rgba(0x3a, 0x54, 0x2e)
local C_RO_FLANK           = rgba(0x66, 0x86, 0x58)
local C_RO_SILVER          = rgba(0x98, 0xb8, 0x92)
local C_RO_BELLY           = rgba(0xcc, 0xe2, 0xc8)
local C_RO_SPINE           = rgba(0x48, 0x5e, 0x3e)

-- Cá Trê (Indigo slate catfish)
local C_TRE_DARK           = rgba(0x16, 0x20, 0x2a)
local C_TRE_MID            = rgba(0x2a, 0x38, 0x4a)
local C_TRE_SLATE          = rgba(0x44, 0x58, 0x70)
local C_TRE_LIGHT          = rgba(0x6c, 0x84, 0x9e)
local C_TRE_BELLY          = rgba(0xb4, 0xc4, 0xd0)
local C_TRE_WHISKER        = rgba(0x16, 0x1e, 0x26)

-- Cá Chép (Golden-red carp)
local C_CHEP_DARK          = rgba(0x50, 0x1c, 0x0e)
local C_CHEP_RUST          = rgba(0x86, 0x32, 0x14)
local C_CHEP_ORANGE        = rgba(0xc6, 0x54, 0x1e)
local C_CHEP_GOLD          = rgba(0xea, 0x82, 0x28)
local C_CHEP_HIGHLIGHT     = rgba(0xf8, 0xb6, 0x50)
local C_CHEP_BELLY         = rgba(0xfa, 0xd8, 0x94)
local C_CHEP_FIN           = rgba(0xd4, 0x4e, 0x20)

-- ============================================================================
-- 1x Pixel Drawing Primitives
-- ============================================================================

local function pset(img, x, y, col)
  if col and x >= 0 and x < img.width and y >= 0 and y < img.height then
    img:drawPixel(x, y, col)
  end
end

local function hline(img, x1, x2, y, col)
  if y < 0 or y >= img.height then return end
  if x1 > x2 then x1, x2 = x2, x1 end
  x1 = math.max(0, x1)
  x2 = math.min(img.width - 1, x2)
  for x = x1, x2 do
    img:drawPixel(x, y, col)
  end
end

local function vline(img, x, y1, y2, col)
  if x < 0 or x >= img.width then return end
  if y1 > y2 then y1, y2 = y2, y1 end
  y1 = math.max(0, y1)
  y2 = math.min(img.height - 1, y2)
  for y = y1, y2 do
    img:drawPixel(x, y, col)
  end
end

local function fillRect(img, x, y, w, h, col)
  for py = y, y + h - 1 do
    hline(img, x, x + w - 1, py, col)
  end
end

local function drawLine(img, x0, y0, x1, y1, col)
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0)
  local sx = (x0 < x1) and 1 or -1
  local sy = (y0 < y1) and 1 or -1
  local err = dx - dy
  while true do
    pset(img, x0, y0, col)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 > -dy then
      err = err - dy
      x0 = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0 = y0 + sy
    end
  end
end

local function fillEllipse(img, cx, cy, rx, ry, col)
  rx = math.max(1, rx)
  ry = math.max(1, ry)
  for y = -ry, ry do
    local py = cy + y
    if py >= 0 and py < img.height then
      local dy_norm = y / ry
      local dx_max = math.floor(rx * math.sqrt(math.max(0, 1 - dy_norm * dy_norm)))
      hline(img, cx - dx_max, cx + dx_max, py, col)
    end
  end
end

local function fillCircle(img, cx, cy, r, col)
  fillEllipse(img, cx, cy, r, r, col)
end

local function fillPolygon(img, pts, col)
  if not pts or #pts < 3 then return end
  local minY = pts[1].y
  local maxY = pts[1].y
  for i = 2, #pts do
    if pts[i].y < minY then minY = pts[i].y end
    if pts[i].y > maxY then maxY = pts[i].y end
  end
  minY = math.max(0, math.floor(minY))
  maxY = math.min(img.height - 1, math.floor(maxY))

  for y = minY, maxY do
    local nodes = {}
    local j = #pts
    for i = 1, #pts do
      local p1 = pts[i]
      local p2 = pts[j]
      if (p1.y < y and p2.y >= y) or (p2.y < y and p1.y >= y) then
        if p2.y ~= p1.y then
          local x = p1.x + (y - p1.y) / (p2.y - p1.y) * (p2.x - p1.x)
          table.insert(nodes, x)
        end
      end
      j = i
    end
    table.sort(nodes)
    for k = 1, #nodes, 2 do
      if nodes[k+1] then
        local xStart = math.floor(nodes[k] + 0.5)
        local xEnd = math.floor(nodes[k+1] + 0.5)
        hline(img, xStart, xEnd, y, col)
      end
    end
  end
end

local function cluster(img, pts, col)
  for _, pt in ipairs(pts) do
    pset(img, pt[1], pt[2], col)
  end
end

-- ============================================================================
-- Sprite Creation and Saving Helper
-- Creates layered .aseprite (Base + Detail) & exports RGBA PNG
-- ============================================================================

local function saveSprite(filename, w, h, drawBase, drawDetail)
  local spr = Sprite(w, h, ColorMode.RGB)

  -- Layer 1: "Base" (silhouette, base colors, blocking)
  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"
  local baseCel = (baseLayer.cels and baseLayer.cels[1]) or (baseLayer.cel and baseLayer:cel(1))
  if baseCel and baseCel.image then
    drawBase(baseCel.image)
  else
    local baseImg = Image(w, h, ColorMode.RGB)
    drawBase(baseImg)
    spr:newCel(baseLayer, 1, baseImg, Point(0, 0))
  end

  -- Layer 2: "Detail" (selective outlines, highlights, textures, facial features)
  local detailLayer = spr:newLayer()
  detailLayer.name = "Detail"
  local detailImg = Image(w, h, ColorMode.RGB)
  drawDetail(detailImg)
  spr:newCel(detailLayer, 1, detailImg, Point(0, 0))

  -- Save outputs
  local aseFile = joinPath(source_dir, filename .. ".aseprite")
  local pngFile = joinPath(out_dir, filename .. ".png")

  spr:saveAs(aseFile)
  spr:saveCopyAs(pngFile)
  spr:close()
end

-- ============================================================================
-- 1. CROPS, CARROTS & RADISHES (96x32 each, 3 frames of 32x32)
-- Shared rich tilled soil mound base with stage transitions:
--   Frame 0: Seed / mound (furrow + seed)
--   Frame 1: Tender sprout (young leaves + stem)
--   Frame 2: Mature harvest (cabbage head, carrot root, white radish root)
-- ============================================================================

local function drawSoilMound(baseImg, detailImg, ox, oy, seedType)
  local cx = ox + 16
  local by = oy + 28

  -- Base: rounded moist tilled soil mound
  for dy = 0, 7 do
    local y = by - dy
    local hw = math.floor(13 * math.sqrt(math.max(0, 1 - (dy / 8.5) ^ 2)))
    hline(baseImg, cx - hw, cx + hw, y, (dy <= 2) and C_SOIL_SHADOW or C_SOIL_DARK)
  end
  hline(baseImg, cx - 11, cx + 11, by - 5, C_SOIL_MID)
  hline(baseImg, cx - 8, cx + 8, by - 6, C_SOIL_MID)

  -- Detail: furrows, organic loam clods, upper-left lighting
  hline(detailImg, cx - 12, cx + 12, by, C_INK)
  pset(detailImg, cx - 13, by - 1, C_INK)
  pset(detailImg, cx + 13, by - 1, C_INK)

  -- Clod highlights (upper-left sun)
  cluster(detailImg, {
    { cx - 9, by - 5 }, { cx - 8, by - 5 }, { cx - 7, by - 6 }, { cx - 6, by - 6 },
    { cx - 3, by - 6 }, { cx - 2, by - 6 }, { cx - 1, by - 7 }, { cx, by - 7 },
    { cx + 3, by - 6 }, { cx + 4, by - 6 }, { cx + 6, by - 5 }
  }, C_SOIL_CREST)

  cluster(detailImg, {
    { cx - 10, by - 4 }, { cx - 5, by - 5 }, { cx + 1, by - 6 }, { cx + 7, by - 4 }
  }, C_SOIL_LIGHT)

  -- Clod drop shadows
  cluster(detailImg, {
    { cx - 8, by - 4 }, { cx - 2, by - 5 }, { cx + 4, by - 5 }, { cx + 8, by - 3 }
  }, C_SOIL_SHADOW)

  -- Seed mound specifics (Frame 0)
  if seedType == "cabbage_seed" then
    -- Hoed central furrow depression with tiny cabbage seeds
    fillRect(detailImg, cx - 2, by - 7, 5, 2, C_SOIL_SHADOW)
    pset(detailImg, cx - 1, by - 6, C_LEAF_SHADOW)
    pset(detailImg, cx, by - 7, C_LEAF_MID)
    pset(detailImg, cx + 1, by - 6, C_LEAF_SHADOW)
    pset(detailImg, cx, by - 6, C_LEAF_LIME)
  elseif seedType == "carrot_seed" then
    -- Tapered furrow with tiny oblong carrot seeds
    fillRect(detailImg, cx - 3, by - 7, 7, 2, C_SOIL_SHADOW)
    pset(detailImg, cx - 2, by - 6, C_CARROT_SHADOW)
    pset(detailImg, cx - 1, by - 7, C_CARROT_BRIGHT)
    pset(detailImg, cx + 1, by - 6, C_CARROT_MID)
    pset(detailImg, cx + 2, by - 7, C_CARROT_LIGHT)
  elseif seedType == "radish_seed" then
    -- Planted depression with pale cream radish seeds
    fillRect(detailImg, cx - 2, by - 7, 5, 2, C_SOIL_SHADOW)
    pset(detailImg, cx - 1, by - 6, C_RADISH_ROOT_SHADOW)
    pset(detailImg, cx, by - 7, C_RADISH_ROOT_WHITE)
    pset(detailImg, cx + 1, by - 6, C_RADISH_ROOT_MID)
  end
end

-- ----------------------------------------------------------------------------
-- Cabbage (crops.png)
-- ----------------------------------------------------------------------------

local function drawCabbageSprout(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local sy = oy + 21

  -- Base: tender green stem and cotyledon lobes
  vline(baseImg, cx, sy - 5, sy, C_LEAF_MID)
  vline(baseImg, cx - 1, sy - 4, sy - 1, C_LEAF_MID)
  fillCircle(baseImg, cx - 4, sy - 5, 3, C_LEAF_GREEN)
  fillCircle(baseImg, cx + 4, sy - 5, 3, C_LEAF_MID)
  fillCircle(baseImg, cx, sy - 7, 2, C_LEAF_BRIGHT)

  -- Detail: leaf ribs, sunlight on upper-left cotyledon
  pset(detailImg, cx - 5, sy - 6, C_LEAF_TENDER)
  pset(detailImg, cx - 4, sy - 6, C_LEAF_LIME)
  pset(detailImg, cx - 3, sy - 5, C_LEAF_LIME)
  pset(detailImg, cx - 4, sy - 4, C_LEAF_MID)
  pset(detailImg, cx + 3, sy - 6, C_LEAF_LIME)
  pset(detailImg, cx + 4, sy - 5, C_LEAF_MID)
  pset(detailImg, cx + 5, sy - 4, C_LEAF_SHADOW)
  pset(detailImg, cx, sy - 8, C_LEAF_TENDER)
  pset(detailImg, cx, sy - 7, C_LEAF_LIME)
  vline(detailImg, cx, sy - 4, sy - 1, C_LEAF_LIME)
  vline(detailImg, cx + 1, sy - 4, sy, C_LEAF_SHADOW)
end

local function drawCabbageMature(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local cy = oy + 17

  -- Base: full layered rounded outer leaves curling onto soil
  fillEllipse(baseImg, cx - 6, cy + 3, 6, 4, C_LEAF_MID)
  fillEllipse(baseImg, cx + 6, cy + 3, 6, 4, C_LEAF_SHADOW)
  fillEllipse(baseImg, cx - 7, cy - 2, 5, 5, C_LEAF_GREEN)
  fillEllipse(baseImg, cx + 7, cy - 2, 5, 5, C_LEAF_MID)
  fillEllipse(baseImg, cx, cy - 6, 7, 4, C_LEAF_MID)
  -- Dense spherical cabbage heart
  fillCircle(baseImg, cx, cy, 6, C_LEAF_BRIGHT)

  -- Detail: layered ruffled curled edges & cabbage heart swirls
  -- Outermost ruffled rim outlines
  cluster(detailImg, {
    { cx - 11, cy + 3 }, { cx - 10, cy + 5 }, { cx - 9, cy + 6 }, { cx - 8, cy + 6 },
    { cx - 7, cy + 7 }, { cx - 4, cy + 7 }, { cx + 4, cy + 7 }, { cx + 7, cy + 7 },
    { cx + 9, cy + 6 }, { cx + 11, cy + 4 }, { cx + 11, cy + 1 }
  }, C_LEAF_INK)

  -- Upper-left leaf highlights & ruffled curling tips
  cluster(detailImg, {
    { cx - 11, cy - 2 }, { cx - 10, cy - 4 }, { cx - 8, cy - 6 }, { cx - 6, cy - 8 },
    { cx - 4, cy - 9 }, { cx - 1, cy - 10 }, { cx + 2, cy - 10 }
  }, C_LEAF_LIME)

  cluster(detailImg, {
    { cx - 9, cy - 3 }, { cx - 7, cy - 5 }, { cx - 3, cy - 8 }, { cx, cy - 9 }
  }, C_LEAF_TENDER)

  -- Branching leaf ribs on outer leaves
  drawLine(detailImg, cx - 2, cy + 4, cx - 8, cy + 4, C_LEAF_LIME)
  drawLine(detailImg, cx - 5, cy + 4, cx - 8, cy + 1, C_LEAF_LIME)
  drawLine(detailImg, cx + 2, cy + 4, cx + 8, cy + 4, C_LEAF_MID)
  drawLine(detailImg, cx + 5, cy + 4, cx + 8, cy + 1, C_LEAF_SHADOW)

  -- Cabbage heart: curved overlapping leaf shell layers
  for a = 0, 7 do
    local rad = 5 - (a * 0.4)
    local hx = math.floor(cx - 2 + rad * math.cos(a * 0.8))
    local hy = math.floor(cy - 1 + rad * math.sin(a * 0.8))
    pset(detailImg, hx, hy, (a < 4) and C_LEAF_TENDER or C_LEAF_LIME)
  end

  -- Shadow crevices in heart
  cluster(detailImg, {
    { cx + 2, cy + 1 }, { cx + 3, cy + 2 }, { cx + 1, cy + 3 }, { cx - 1, cy + 4 }
  }, C_LEAF_MID)
  cluster(detailImg, {
    { cx + 3, cy + 3 }, { cx + 4, cy + 4 }
  }, C_LEAF_SHADOW)

  -- Ambient shadow where cabbage rests on soil
  hline(detailImg, cx - 6, cx + 6, cy + 6, C_LEAF_INK)
end

-- ----------------------------------------------------------------------------
-- Carrot (carrots.png)
-- ----------------------------------------------------------------------------

local function drawCarrotSprout(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local sy = oy + 21

  -- Base: feathery young stalks
  vline(baseImg, cx, sy - 8, sy, C_LEAF_MID)
  drawLine(baseImg, cx, sy - 3, cx - 4, sy - 7, C_LEAF_GREEN)
  drawLine(baseImg, cx, sy - 4, cx + 4, sy - 7, C_LEAF_MID)

  -- Detail: fern-like serrated tips
  cluster(detailImg, {
    { cx - 5, sy - 8 }, { cx - 4, sy - 9 }, { cx - 3, sy - 7 },
    { cx - 1, sy - 9 }, { cx, sy - 10 }, { cx + 1, sy - 8 },
    { cx + 3, sy - 8 }, { cx + 4, sy - 9 }, { cx + 5, sy - 7 }
  }, C_LEAF_LIME)

  cluster(detailImg, {
    { cx - 4, sy - 8 }, { cx, sy - 9 }
  }, C_LEAF_TENDER)

  vline(detailImg, cx + 1, sy - 6, sy, C_LEAF_SHADOW)
end

local function drawCarrotMature(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local ry = oy + 21

  -- Base: tapered carrot root crowning out of soil
  fillPolygon(baseImg, {
    { x = cx - 5, y = ry },
    { x = cx + 5, y = ry },
    { x = cx + 3, y = ry + 6 },
    { x = cx - 3, y = ry + 6 }
  }, C_CARROT_BRIGHT)
  fillEllipse(baseImg, cx, ry, 5, 2, C_CARROT_BRIGHT)

  -- Base: lush feathery fern greens arching up and out
  fillPolygon(baseImg, {
    { x = cx - 9, y = ry - 14 },
    { x = cx + 9, y = ry - 14 },
    { x = cx + 3, y = ry },
    { x = cx - 3, y = ry }
  }, C_LEAF_GREEN)

  -- Detail: Carrot root ridges, highlight & soil contact
  -- Upper-left sunlight glint on root crown
  cluster(detailImg, {
    { cx - 4, ry - 1 }, { cx - 3, ry - 1 }, { cx - 2, ry - 1 },
    { cx - 4, ry }, { cx - 3, ry }, { cx - 4, ry + 1 }, { cx - 3, ry + 1 },
    { cx - 3, ry + 2 }, { cx - 2, ry + 3 }
  }, C_CARROT_HIGHLIGHT)

  cluster(detailImg, {
    { cx - 1, ry - 1 }, { cx - 2, ry }, { cx - 1, ry + 1 }, { cx - 2, ry + 2 }
  }, C_CARROT_LIGHT)

  -- Horizontal carrot growth rings
  hline(detailImg, cx - 3, cx + 3, ry + 2, C_CARROT_SHADOW)
  hline(detailImg, cx - 2, cx + 2, ry + 4, C_CARROT_SHADOW)

  -- Root shadow & soil occlusion on right side
  cluster(detailImg, {
    { cx + 3, ry }, { cx + 4, ry }, { cx + 4, ry + 1 }, { cx + 3, ry + 2 },
    { cx + 3, ry + 3 }, { cx + 2, ry + 4 }, { cx + 2, ry + 5 }
  }, C_CARROT_SHADOW)
  cluster(detailImg, {
    { cx + 4, ry + 2 }, { cx + 3, ry + 4 }
  }, C_INK)

  -- Fern greens: feathery lacy foliage clusters & stalks
  drawLine(detailImg, cx, ry - 1, cx - 7, ry - 13, C_LEAF_MID)
  drawLine(detailImg, cx, ry - 1, cx, ry - 16, C_LEAF_LIME)
  drawLine(detailImg, cx, ry - 1, cx + 7, ry - 13, C_LEAF_MID)

  -- Fern tips & frills
  cluster(detailImg, {
    { cx - 9, ry - 14 }, { cx - 8, ry - 15 }, { cx - 7, ry - 16 }, { cx - 6, ry - 14 },
    { cx - 5, ry - 16 }, { cx - 4, ry - 17 }, { cx - 3, ry - 15 },
    { cx - 1, ry - 18 }, { cx, ry - 19 }, { cx + 1, ry - 17 },
    { cx + 3, ry - 16 }, { cx + 5, ry - 17 }, { cx + 6, ry - 15 },
    { cx + 8, ry - 15 }, { cx + 9, ry - 14 }
  }, C_LEAF_LIME)

  cluster(detailImg, {
    { cx - 8, ry - 14 }, { cx - 4, ry - 16 }, { cx, ry - 18 }, { cx + 4, ry - 16 }
  }, C_LEAF_TENDER)

  -- Shaded fronds underneath
  cluster(detailImg, {
    { cx - 6, ry - 10 }, { cx - 3, ry - 9 }, { cx + 3, ry - 9 }, { cx + 6, ry - 10 }
  }, C_LEAF_SHADOW)
end

-- ----------------------------------------------------------------------------
-- White Radish (radishes.png)
-- ----------------------------------------------------------------------------

local function drawRadishSprout(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local sy = oy + 21

  -- Base: pale twin stems and heart cotyledons
  drawLine(baseImg, cx, sy, cx - 4, sy - 6, C_RADISH_ROOT_MID)
  drawLine(baseImg, cx, sy, cx + 4, sy - 6, C_RADISH_ROOT_MID)
  fillCircle(baseImg, cx - 5, sy - 7, 2, C_LEAF_GREEN)
  fillCircle(baseImg, cx + 5, sy - 7, 2, C_LEAF_MID)

  -- Detail: leaf clefts and sunlight
  pset(detailImg, cx - 6, sy - 8, C_LEAF_TENDER)
  pset(detailImg, cx - 5, sy - 8, C_LEAF_LIME)
  pset(detailImg, cx - 4, sy - 7, C_LEAF_LIME)
  pset(detailImg, cx + 4, sy - 8, C_LEAF_LIME)
  pset(detailImg, cx + 6, sy - 7, C_LEAF_SHADOW)
  pset(detailImg, cx - 2, sy - 3, C_RADISH_ROOT_WHITE)
  pset(detailImg, cx + 1, sy - 3, C_RADISH_ROOT_SHADOW)
end

local function drawRadishMature(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local ry = oy + 20

  -- Base: plump white radish root shoulder protruding from soil
  fillPolygon(baseImg, {
    { x = cx - 5, y = ry },
    { x = cx + 5, y = ry },
    { x = cx + 4, y = ry + 7 },
    { x = cx - 4, y = ry + 7 }
  }, C_RADISH_ROOT_WHITE)
  fillEllipse(baseImg, cx, ry, 5, 2, C_RADISH_ROOT_WHITE)

  -- Base: elongated upright lobed radish greens
  fillPolygon(baseImg, {
    { x = cx - 8, y = ry - 16 },
    { x = cx + 8, y = ry - 16 },
    { x = cx + 3, y = ry },
    { x = cx - 3, y = ry }
  }, C_LEAF_GREEN)

  -- Detail: root shading, lateral root hairs & pale stems
  -- Pure white highlight on upper-left root shoulder
  cluster(detailImg, {
    { cx - 4, ry - 1 }, { cx - 3, ry - 1 }, { cx - 4, ry }, { cx - 3, ry },
    { cx - 4, ry + 1 }, { cx - 3, ry + 1 }, { cx - 4, ry + 2 }, { cx - 3, ry + 2 },
    { cx - 3, ry + 3 }, { cx - 3, ry + 4 }, { cx - 2, ry + 5 }
  }, C_RADISH_ROOT_BRIGHT)

  -- Soft green shoulder blush where stem meets root
  cluster(detailImg, {
    { cx - 2, ry - 1 }, { cx - 1, ry - 1 }, { cx, ry - 1 }, { cx + 1, ry - 1 },
    { cx - 1, ry }, { cx, ry }
  }, C_LEAF_LIME)

  -- Cool pale shadow on right side of root
  cluster(detailImg, {
    { cx + 3, ry }, { cx + 4, ry }, { cx + 4, ry + 1 }, { cx + 3, ry + 2 },
    { cx + 4, ry + 3 }, { cx + 3, ry + 4 }, { cx + 3, ry + 5 }
  }, C_RADISH_ROOT_MID)
  cluster(detailImg, {
    { cx + 4, ry + 2 }, { cx + 4, ry + 4 }, { cx + 3, ry + 6 }
  }, C_RADISH_ROOT_SHADOW)

  -- Fine lateral root hairs branching into soil
  pset(detailImg, cx - 5, ry + 4, C_RADISH_ROOT_WHITE)
  pset(detailImg, cx - 6, ry + 5, C_RADISH_ROOT_MID)
  pset(detailImg, cx + 5, ry + 5, C_RADISH_ROOT_MID)

  -- Radish leaves: crisp white/pale midribs
  drawLine(detailImg, cx - 1, ry - 1, cx - 5, ry - 15, C_RADISH_ROOT_WHITE)
  drawLine(detailImg, cx, ry - 1, cx, ry - 17, C_RADISH_ROOT_WHITE)
  drawLine(detailImg, cx + 1, ry - 1, cx + 5, ry - 14, C_LEAF_TENDER)

  -- Pinnate lobed leaf blade highlights
  cluster(detailImg, {
    { cx - 7, ry - 15 }, { cx - 6, ry - 16 }, { cx - 5, ry - 17 }, { cx - 4, ry - 14 },
    { cx - 2, ry - 17 }, { cx - 1, ry - 18 }, { cx, ry - 19 }, { cx + 1, ry - 17 },
    { cx + 3, ry - 15 }, { cx + 5, ry - 15 }, { cx + 6, ry - 13 }
  }, C_LEAF_LIME)

  cluster(detailImg, {
    { cx - 5, ry - 16 }, { cx, ry - 18 }, { cx + 5, ry - 14 }
  }, C_LEAF_TENDER)

  -- Deep leaf shadow crevices
  cluster(detailImg, {
    { cx - 5, ry - 10 }, { cx - 2, ry - 8 }, { cx + 2, ry - 9 }, { cx + 5, ry - 10 }
  }, C_LEAF_SHADOW)
end

-- ============================================================================
-- 2. SEED BAGS (seed_bags.png 64x32 & radish_seed.png 32x32)
-- Warm canvas burlap sack, cinched neck, tied cord, folded cloth shade
-- ============================================================================

local function drawCanvasBag(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local by = oy + 28

  -- Base: plump burlap pouch body
  fillEllipse(baseImg, cx, by - 8, 9, 8, C_CANVAS_MID)
  fillRect(baseImg, cx - 8, by - 12, 17, 10, C_CANVAS_MID)
  -- Cinched neck
  fillRect(baseImg, cx - 4, by - 18, 9, 3, C_CANVAS_SHADOW)
  -- Ruffled top rim / mouth
  fillPolygon(baseImg, {
    { x = cx - 6, y = by - 22 },
    { x = cx + 6, y = by - 22 },
    { x = cx + 4, y = by - 18 },
    { x = cx - 4, y = by - 18 }
  }, C_CANVAS_LIGHT)

  -- Detail: Twine tie cord, knot, fold shadow & burlap weave
  -- Selective ink outline on bottom and right
  hline(detailImg, cx - 7, cx + 7, by, C_INK)
  cluster(detailImg, {
    { cx + 8, by - 1 }, { cx + 9, by - 3 }, { cx + 9, by - 6 }, { cx + 8, by - 9 }
  }, C_INK)

  -- Hemp cord tied at neck
  hline(detailImg, cx - 4, cx + 4, by - 18, C_SOIL_DARK)
  hline(detailImg, cx - 4, cx + 4, by - 17, C_SOIL_MID)
  -- Knot and hanging twine ends
  cluster(detailImg, {
    { cx - 5, by - 18 }, { cx - 5, by - 17 }, { cx - 6, by - 16 }, { cx - 6, by - 15 }
  }, C_SOIL_LIGHT)

  -- Deep drop shadow under cinched folded edge
  hline(detailImg, cx - 6, cx + 6, by - 16, C_CANVAS_SHADOW)
  hline(detailImg, cx - 7, cx + 7, by - 15, C_CANVAS_SHADOW)

  -- Upper-left highlight on canvas shoulder
  cluster(detailImg, {
    { cx - 7, by - 14 }, { cx - 6, by - 14 }, { cx - 5, by - 14 },
    { cx - 8, by - 12 }, { cx - 7, by - 12 }, { cx - 6, by - 12 },
    { cx - 8, by - 9 },  { cx - 7, by - 9 }
  }, C_CANVAS_HIGHLIGHT)

  cluster(detailImg, {
    { cx - 5, by - 12 }, { cx - 4, by - 13 }, { cx - 6, by - 8 }
  }, C_CANVAS_LIGHT)

  -- Ruffled mouth highlights
  cluster(detailImg, {
    { cx - 6, by - 22 }, { cx - 5, by - 23 }, { cx - 3, by - 22 }, { cx - 2, by - 23 },
    { cx, by - 22 }, { cx + 1, by - 23 }, { cx + 3, by - 22 }
  }, C_CANVAS_HIGHLIGHT)

  -- Subtle burlap weave stitch accents
  cluster(detailImg, {
    { cx - 6, by - 4 }, { cx - 3, by - 3 }, { cx + 3, by - 3 }, { cx + 6, by - 4 }
  }, C_CANVAS_SHADOW)
end

local function drawCabbageEmblem(detailImg, ox, oy)
  local cx = ox + 16
  local cy = oy + 19

  -- Round cabbage emblem
  fillCircle(detailImg, cx, cy, 4, C_LEAF_MID)
  fillCircle(detailImg, cx - 1, cy - 1, 2, C_LEAF_BRIGHT)
  pset(detailImg, cx - 1, cy - 1, C_LEAF_LIME)
  pset(detailImg, cx, cy - 2, C_LEAF_TENDER)
  -- Stitched badge outline
  cluster(detailImg, {
    { cx - 3, cy - 4 }, { cx + 3, cy - 4 }, { cx - 4, cy + 3 }, { cx + 4, cy + 3 }
  }, C_CANVAS_HIGHLIGHT)
end

local function drawCarrotEmblem(detailImg, ox, oy)
  local cx = ox + 16
  local cy = oy + 19

  -- Vibrant carrot emblem
  fillPolygon(detailImg, {
    { x = cx - 2, y = cy - 2 },
    { x = cx + 2, y = cy - 2 },
    { x = cx,     y = cy + 4 }
  }, C_CARROT_BRIGHT)
  pset(detailImg, cx - 1, cy - 1, C_CARROT_LIGHT)
  -- Green fern tuft at top of carrot
  pset(detailImg, cx - 1, cy - 3, C_LEAF_LIME)
  pset(detailImg, cx,     cy - 4, C_LEAF_TENDER)
  pset(detailImg, cx + 1, cy - 3, C_LEAF_BRIGHT)
end

local function drawRadishEmblem(detailImg, ox, oy)
  local cx = ox + 16
  local cy = oy + 19

  -- Complementary white radish emblem with jade border
  cluster(detailImg, {
    { cx - 4, cy }, { cx + 4, cy }, { cx, cy - 4 }, { cx, cy + 4 }
  }, C_JADE_MID)
  -- White radish root silhouette
  fillPolygon(detailImg, {
    { x = cx - 2, y = cy - 2 },
    { x = cx + 2, y = cy - 2 },
    { x = cx,     y = cy + 4 }
  }, C_RADISH_ROOT_WHITE)
  pset(detailImg, cx - 1, cy - 1, C_RADISH_ROOT_BRIGHT)
  pset(detailImg, cx + 1, cy + 1, C_RADISH_ROOT_SHADOW)
  -- Pale green leaves
  pset(detailImg, cx - 1, cy - 3, C_LEAF_LIME)
  pset(detailImg, cx,     cy - 4, C_LEAF_TENDER)
  pset(detailImg, cx + 1, cy - 3, C_JADE_LIGHT)
end

-- ============================================================================
-- 3. FISH (fish.png 96x32, 3 frames of 32x32 swimming left)
-- Frame 0: Cá Rô (green-silver perch, spiny dorsal, compact)
-- Frame 1: Cá Trê (indigo-slate catfish, elongated, barbels/whiskers)
-- Frame 2: Cá Chép (golden-red carp, arched back, large round scales)
-- ============================================================================

local function drawPerch(baseImg, detailImg, ox, oy)
  local fx = ox + 4
  local fy = oy + 16

  -- Base: deep compact perch body & fins
  fillEllipse(baseImg, fx + 11, fy, 10, 6, C_RO_BACK_MID)
  -- Spiny dorsal fin
  fillPolygon(baseImg, {
    { x = fx + 7,  y = fy - 5 },
    { x = fx + 17, y = fy - 5 },
    { x = fx + 13, y = fy - 10 },
    { x = fx + 8,  y = fy - 8 }
  }, C_RO_SPINE)
  -- Caudal tail fin
  fillPolygon(baseImg, {
    { x = fx + 20, y = fy },
    { x = fx + 26, y = fy - 5 },
    { x = fx + 25, y = fy },
    { x = fx + 26, y = fy + 5 }
  }, C_RO_FLANK)
  -- Anal and pectoral fins
  fillPolygon(baseImg, {
    { x = fx + 13, y = fy + 5 },
    { x = fx + 17, y = fy + 5 },
    { x = fx + 15, y = fy + 8 }
  }, C_RO_SPINE)
  fillEllipse(baseImg, fx + 8, fy + 2, 3, 2, C_RO_FLANK)

  -- Detail: Spiny rays, silver gradient, opercle spot & eye
  -- Olive-moss dorsal ridge
  for x = fx + 5, fx + 18 do
    pset(detailImg, x, fy - 4, C_RO_BACK_DARK)
  end

  -- Spiny dorsal fin rays (prickly perch dorsal)
  cluster(detailImg, {
    { fx + 8, fy - 8 }, { fx + 9, fy - 9 }, { fx + 10, fy - 9 }, { fx + 11, fy - 10 },
    { fx + 12, fy - 9 }, { fx + 13, fy - 9 }, { fx + 14, fy - 8 }, { fx + 16, fy - 6 }
  }, C_INK)
  drawLine(detailImg, fx + 11, fy - 10, fx + 11, fy - 5, C_RO_BACK_DARK)
  drawLine(detailImg, fx + 13, fy - 9,  fx + 13, fy - 5, C_RO_BACK_DARK)

  -- Silver flank & belly
  hline(detailImg, fx + 6, fx + 18, fy + 2, C_RO_SILVER)
  hline(detailImg, fx + 7, fx + 16, fy + 4, C_RO_BELLY)

  -- Opercular spot (characteristic of cá rô đồng)
  fillRect(detailImg, fx + 8, fy - 1, 2, 2, C_INK)

  -- Eye
  pset(detailImg, fx + 3, fy - 2, C_SASH_GOLD)
  pset(detailImg, fx + 4, fy - 2, C_SASH_GOLD)
  pset(detailImg, fx + 3, fy - 1, C_INK)
  pset(detailImg, fx + 4, fy - 1, C_CANVAS_HIGHLIGHT)

  -- Snout & mouth
  pset(detailImg, fx + 1, fy, C_INK)
  pset(detailImg, fx + 2, fy, C_RO_BACK_MID)

  -- Tail fin ray striations
  drawLine(detailImg, fx + 20, fy, fx + 25, fy - 4, C_RO_SILVER)
  drawLine(detailImg, fx + 20, fy, fx + 25, fy + 4, C_RO_SILVER)
end

local function drawCatfish(baseImg, detailImg, ox, oy)
  local fx = ox + 4
  local fy = oy + 17

  -- Base: elongated sleek body tapering to rounded tail
  fillEllipse(baseImg, fx + 6, fy, 6, 4, C_TRE_DARK)
  fillPolygon(baseImg, {
    { x = fx + 6,  y = fy - 4 },
    { x = fx + 20, y = fy - 2 },
    { x = fx + 24, y = fy },
    { x = fx + 20, y = fy + 2 },
    { x = fx + 6,  y = fy + 4 }
  }, C_TRE_MID)
  -- Continuous low dorsal & anal fins
  fillEllipse(baseImg, fx + 14, fy - 3, 5, 2, C_TRE_SLATE)
  fillEllipse(baseImg, fx + 16, fy + 3, 5, 2, C_TRE_SLATE)
  fillEllipse(baseImg, fx + 24, fy, 3, 3, C_TRE_SLATE)

  -- Detail: Whisker barbels, smooth slate skin, pale belly, beady eye
  -- 4 Whisker barbels extending gracefully from mouth
  -- Long upper whiskers
  drawLine(detailImg, fx + 2, fy - 1, fx - 2, fy - 4, C_TRE_WHISKER)
  drawLine(detailImg, fx - 2, fy - 4, fx + 3, fy - 7, C_TRE_WHISKER)
  -- Long lower whisker
  drawLine(detailImg, fx + 2, fy + 1, fx - 2, fy + 4, C_TRE_WHISKER)
  drawLine(detailImg, fx - 2, fy + 4, fx + 4, fy + 6, C_TRE_WHISKER)
  -- 2 Short chin whiskers
  pset(detailImg, fx + 1, fy, C_TRE_WHISKER)
  pset(detailImg, fx, fy + 1, C_TRE_WHISKER)

  -- Slate-indigo skin highlights
  hline(detailImg, fx + 6, fx + 17, fy - 2, C_TRE_LIGHT)
  cluster(detailImg, {
    { fx + 7, fy - 3 }, { fx + 9, fy - 3 }, { fx + 11, fy - 3 }
  }, C_INDIGO_HIGHLIGHT)

  -- Creamy soft underbelly
  hline(detailImg, fx + 5, fx + 16, fy + 2, C_TRE_BELLY)

  -- Tiny beady catfish eye
  pset(detailImg, fx + 4, fy - 2, C_INK)
  pset(detailImg, fx + 5, fy - 2, C_CANVAS_HIGHLIGHT)

  -- Broad flat snout
  pset(detailImg, fx, fy, C_TRE_DARK)
  pset(detailImg, fx + 1, fy, C_TRE_DARK)
end

local function drawCarp(baseImg, detailImg, ox, oy)
  local fx = ox + 4
  local fy = oy + 16

  -- Base: deep robust arched body & flowing fins
  fillEllipse(baseImg, fx + 11, fy, 10, 7, C_CHEP_ORANGE)
  -- Arched dorsal fin
  fillPolygon(baseImg, {
    { x = fx + 7,  y = fy - 6 },
    { x = fx + 17, y = fy - 6 },
    { x = fx + 12, y = fy - 10 }
  }, C_CHEP_FIN)
  -- Bifurcated flowing tail fin
  fillPolygon(baseImg, {
    { x = fx + 19, y = fy },
    { x = fx + 26, y = fy - 6 },
    { x = fx + 24, y = fy },
    { x = fx + 26, y = fy + 6 }
  }, C_CHEP_FIN)
  -- Pectoral and pelvic fins
  fillPolygon(baseImg, {
    { x = fx + 8,  y = fy + 3 },
    { x = fx + 12, y = fy + 7 },
    { x = fx + 10, y = fy + 3 }
  }, C_CHEP_FIN)

  -- Detail: Large round scales pattern, golden highlights, carp lips & eye
  -- Arched rust back
  for x = fx + 6, fx + 17 do
    pset(detailImg, x, fy - 5, C_CHEP_RUST)
  end

  -- Large round scale crescents (3 rows of scales)
  local scales = {
    { fx + 8, fy - 2 }, { fx + 11, fy - 2 }, { fx + 14, fy - 2 }, { fx + 17, fy - 2 },
    { fx + 7, fy },     { fx + 10, fy },     { fx + 13, fy },     { fx + 16, fy },
    { fx + 8, fy + 2 }, { fx + 11, fy + 2 }, { fx + 14, fy + 2 }
  }
  for _, sc in ipairs(scales) do
    pset(detailImg, sc[1],     sc[2],     C_CHEP_GOLD)
    pset(detailImg, sc[1] + 1, sc[2],     C_CHEP_HIGHLIGHT)
    pset(detailImg, sc[1] + 2, sc[2],     C_CHEP_RUST)
    pset(detailImg, sc[1] + 1, sc[2] + 1, C_CHEP_RUST)
  end

  -- Golden belly
  hline(detailImg, fx + 7, fx + 15, fy + 4, C_CHEP_BELLY)

  -- Eye: bright golden carp eye
  pset(detailImg, fx + 4, fy - 2, C_CHEP_GOLD)
  pset(detailImg, fx + 5, fy - 2, C_CHEP_GOLD)
  pset(detailImg, fx + 4, fy - 1, C_INK)
  pset(detailImg, fx + 5, fy - 1, C_CANVAS_HIGHLIGHT)

  -- Fleshy mouth & tiny barbel
  pset(detailImg, fx + 1, fy, C_CHEP_RUST)
  pset(detailImg, fx + 2, fy + 1, C_CHEP_GOLD)

  -- Flowing tail fin ray striations
  drawLine(detailImg, fx + 19, fy, fx + 25, fy - 5, C_CHEP_HIGHLIGHT)
  drawLine(detailImg, fx + 19, fy, fx + 25, fy + 5, C_CHEP_HIGHLIGHT)
  drawLine(detailImg, fx + 19, fy, fx + 23, fy,     C_CHEP_ORANGE)
end

-- ============================================================================
-- 4. VILLAGE PEOPLE (village_people.png 64x48)
-- Frame 0 (x=0..31): Cô Huệ (seed seller, terracotta blouse, woven light hat)
-- Frame 1 (x=32..63): Bác Bảy (cook, dark indigo outfit, light khăn rằn scarf)
-- Pivot: local (16, 48), feet baseline at y=45
-- ============================================================================

local function drawCoHue(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local by = oy + 45

  -- Base: Feet and boots
  fillRect(baseImg, cx - 5, by - 1, 3, 2, C_CANVAS_LIGHT)
  fillRect(baseImg, cx + 2, by - 1, 3, 2, C_CANVAS_LIGHT)

  -- Base: Peasant trousers
  fillRect(baseImg, cx - 5, by - 10, 4, 9, C_TROUSER_MID)
  fillRect(baseImg, cx + 1, by - 10, 4, 9, C_TROUSER_MID)

  -- Base: Terracotta blouse (Áo bà ba)
  fillPolygon(baseImg, {
    { x = cx - 7, y = by - 21 },
    { x = cx + 7, y = by - 21 },
    { x = cx + 8, y = by - 11 },
    { x = cx - 8, y = by - 11 }
  }, C_TERRA_MID)
  -- Sleeves
  fillRect(baseImg, cx - 9, by - 20, 3, 8, C_TERRA_MID)
  fillRect(baseImg, cx + 6, by - 20, 3, 8, C_TERRA_MID)
  -- Hands
  fillRect(baseImg, cx - 9, by - 12, 2, 2, C_SKIN_MID)
  fillRect(baseImg, cx + 7, by - 12, 2, 2, C_SKIN_MID)

  -- Base: Head, hair & skin
  fillRect(baseImg, cx - 4, by - 28, 9, 7, C_SKIN_MID)
  fillRect(baseImg, cx - 5, by - 29, 11, 3, C_INK) -- dark hair bun

  -- Base: Light woven hat (Nón quai thao / light woven hat)
  fillPolygon(baseImg, {
    { x = cx - 11, y = by - 30 },
    { x = cx + 11, y = by - 30 },
    { x = cx + 8,  y = by - 36 },
    { x = cx - 8,  y = by - 36 }
  }, C_STRAW_LIGHT)
  fillEllipse(baseImg, cx, by - 30, 12, 3, C_STRAW_MID)

  -- Detail: Hat weave, face, terracotta highlights, buttons, seed basket
  -- Hat woven texture & highlights
  hline(detailImg, cx - 10, cx + 10, by - 30, C_STRAW_DEEP)
  hline(detailImg, cx - 7, cx + 7, by - 36, C_STRAW_HIGHLIGHT)
  for y = by - 35, by - 31, 2 do
    hline(detailImg, cx - 8, cx + 8, y, C_STRAW_LIGHT)
  end

  -- Face: Friendly warm eyes, smile, rosy cheek
  pset(detailImg, cx - 2, by - 25, C_INK)
  pset(detailImg, cx + 2, by - 25, C_INK)
  pset(detailImg, cx,     by - 24, C_SKIN_SHADOW)
  hline(detailImg, cx - 1, cx + 1, by - 22, C_TERRA_DARK)
  pset(detailImg, cx - 3, by - 23, C_TERRA_LIGHT) -- rosy cheek
  pset(detailImg, cx + 3, by - 23, C_TERRA_LIGHT)

  -- Terracotta blouse: neckline, buttons, upper-left lighting
  cluster(detailImg, {
    { cx - 6, by - 20 }, { cx - 5, by - 20 }, { cx - 4, by - 19 },
    { cx - 6, by - 18 }, { cx - 5, by - 18 }, { cx - 6, by - 15 }
  }, C_TERRA_HIGHLIGHT)

  cluster(detailImg, {
    { cx + 5, by - 19 }, { cx + 6, by - 18 }, { cx + 6, by - 15 }
  }, C_TERRA_DARK)

  -- Front buttons (ivory specks)
  pset(detailImg, cx, by - 19, C_CANVAS_HIGHLIGHT)
  pset(detailImg, cx, by - 17, C_CANVAS_HIGHLIGHT)
  pset(detailImg, cx, by - 15, C_CANVAS_HIGHLIGHT)
  pset(detailImg, cx, by - 13, C_CANVAS_HIGHLIGHT)

  -- Woven seed pouch/basket held at hip (right side)
  fillRect(detailImg, cx + 5, by - 14, 4, 4, C_STRAW_SHADOW)
  pset(detailImg, cx + 6, by - 13, C_LEAF_LIME)
  pset(detailImg, cx + 7, by - 13, C_CARROT_BRIGHT)
  pset(detailImg, cx + 6, by - 12, C_RADISH_ROOT_WHITE)

  -- Trouser creases & ground shadow
  vline(detailImg, cx - 3, by - 9, by - 2, C_TROUSER_DARK)
  vline(detailImg, cx + 3, by - 9, by - 2, C_TROUSER_DARK)
  hline(detailImg, cx - 6, cx + 6, by + 1, C_INK)
end

local function drawBacBay(baseImg, detailImg, ox, oy)
  local cx = ox + 16
  local by = oy + 45

  -- Base: Sturdy dark clogs / slippers
  fillRect(baseImg, cx - 5, by - 1, 4, 2, C_SOIL_LIGHT)
  fillRect(baseImg, cx + 1, by - 1, 4, 2, C_SOIL_LIGHT)

  -- Base: Dark peasant trousers
  fillRect(baseImg, cx - 5, by - 10, 4, 9, C_TROUSER_DARK)
  fillRect(baseImg, cx + 1, by - 10, 4, 9, C_TROUSER_DARK)

  -- Base: Dark indigo cook outfit (Áo bà ba)
  fillPolygon(baseImg, {
    { x = cx - 8, y = by - 21 },
    { x = cx + 8, y = by - 21 },
    { x = cx + 8, y = by - 11 },
    { x = cx - 8, y = by - 11 }
  }, C_INDIGO_DARK)
  -- Rolled up sleeves revealing strong forearms
  fillRect(baseImg, cx - 10, by - 20, 3, 5, C_INDIGO_DARK)
  fillRect(baseImg, cx + 7,  by - 20, 3, 5, C_INDIGO_DARK)
  fillRect(baseImg, cx - 10, by - 15, 3, 5, C_SKIN_MID)
  fillRect(baseImg, cx + 7,  by - 15, 3, 5, C_SKIN_MID)

  -- Base: Head, weathered skin & hair
  fillRect(baseImg, cx - 4, by - 28, 9, 7, C_SKIN_MID)
  fillRect(baseImg, cx - 5, by - 30, 11, 3, C_TROUSER_LIGHT) -- silver-grey hair

  -- Base: Light scarf (Khăn rằn) draped around neck & shoulders
  fillPolygon(baseImg, {
    { x = cx - 6, y = by - 23 },
    { x = cx + 6, y = by - 23 },
    { x = cx + 5, y = by - 13 },
    { x = cx - 5, y = by - 13 }
  }, C_SCARF_LIGHT)

  -- Detail: Khăn rằn checkered pattern, cook mustache, wooden ladle
  -- Checkered pattern on scarf (alternating grey & light squares)
  for sy = by - 22, by - 14 do
    for sx = cx - 4, cx + 4 do
      if (sx + sy) % 2 == 0 then
        pset(detailImg, sx, sy, C_SCARF_GREY)
      end
    end
  end
  -- Scarf fringe at ends
  pset(detailImg, cx - 3, by - 12, C_SCARF_LIGHT)
  pset(detailImg, cx - 1, by - 12, C_SCARF_LIGHT)
  pset(detailImg, cx + 1, by - 12, C_SCARF_LIGHT)

  -- Face: Kind eyes with crinkles, neat mustache
  pset(detailImg, cx - 2, by - 25, C_INK)
  pset(detailImg, cx + 2, by - 25, C_INK)
  -- Cook mustache
  hline(detailImg, cx - 2, cx + 2, by - 23, C_DARK_BROWN)
  pset(detailImg, cx - 3, by - 22, C_DARK_BROWN)
  pset(detailImg, cx + 3, by - 22, C_DARK_BROWN)

  -- Indigo tunic highlights on left shoulder
  cluster(detailImg, {
    { cx - 7, by - 20 }, { cx - 6, by - 20 }, { cx - 7, by - 18 }
  }, C_INDIGO_BRIGHT)

  -- Wooden cooking ladle held in right hand
  vline(detailImg, cx + 9, by - 18, by - 11, C_SOIL_LIGHT)
  fillCircle(detailImg, cx + 9, by - 19, 2, C_SOIL_MID)

  -- Ground shadow
  hline(detailImg, cx - 6, cx + 6, by + 1, C_INK)
end

-- ============================================================================
-- 5. PLAYER SPRITESHEET (player.png 96x192)
-- 3 columns (Idle, Step A, Step B) x 4 rows (Down, Left, Right, Up)
-- Cell: 32x48. Pivot: local (16, 48). Baseline feet at y=45.
-- Straw conical nón lá, blue áo bà ba, warm sash, dark trousers, boots.
-- Light upper-left, consistent baseline, distinct directional silhouettes.
-- ============================================================================

local function drawPlayer(baseImg, detailImg, ox, oy, direction, animStep)
  local cx = ox + 16
  local by = oy + 45 -- feet baseline

  -- Stride offsets
  local leftLegDy = 0
  local rightLegDy = 0
  local leftArmDy = 0
  local rightArmDy = 0

  if animStep == 1 then -- Step A
    leftLegDy = 0
    rightLegDy = -2
    leftArmDy = 1
    rightArmDy = -1
  elseif animStep == 2 then -- Step B
    leftLegDy = -2
    rightLegDy = 0
    leftArmDy = -1
    rightArmDy = 1
  end

  -- ==========================================================================
  -- DIRECTION 0: DOWN (Facing Camera)
  -- ==========================================================================
  if direction == 0 then
    -- Base: Boots
    fillRect(baseImg, cx - 5, by - 1 + leftLegDy, 3, 2, C_SOIL_DARK)
    fillRect(baseImg, cx + 2, by - 1 + rightLegDy, 3, 2, C_SOIL_DARK)

    -- Base: Dark Trousers
    fillRect(baseImg, cx - 5, by - 11 + leftLegDy, 4, 10, C_TROUSER_MID)
    fillRect(baseImg, cx + 1, by - 11 + rightLegDy, 4, 10, C_TROUSER_MID)

    -- Base: Áo bà ba (Indigo blue tunic)
    fillPolygon(baseImg, {
      { x = cx - 8, y = by - 22 },
      { x = cx + 8, y = by - 22 },
      { x = cx + 8, y = by - 11 },
      { x = cx - 8, y = by - 11 }
    }, C_INDIGO_MID)
    -- Warm sash
    fillRect(baseImg, cx - 7, by - 15, 15, 3, C_SASH_GOLD)
    -- Sleeves & Hands
    fillRect(baseImg, cx - 9, by - 21 + leftArmDy, 3, 9, C_INDIGO_MID)
    fillRect(baseImg, cx + 7, by - 21 + rightArmDy, 3, 9, C_INDIGO_MID)
    fillRect(baseImg, cx - 9, by - 12 + leftArmDy, 2, 2, C_SKIN_MID)
    fillRect(baseImg, cx + 7, by - 12 + rightArmDy, 2, 2, C_SKIN_MID)

    -- Base: Face & Neck
    fillRect(baseImg, cx - 4, by - 27, 9, 6, C_SKIN_MID)

    -- Base: Conical Nón Lá (Front view)
    fillPolygon(baseImg, {
      { x = cx,      y = by - 39 },
      { x = cx + 12, y = by - 28 },
      { x = cx - 12, y = by - 28 }
    }, C_STRAW_MID)
    fillEllipse(baseImg, cx, by - 28, 12, 3, C_STRAW_MID)

    -- Detail: Nón lá weave, face under brim, buttons, sash knot
    -- Hat concentric weave rings
    fillEllipse(detailImg, cx, by - 28, 12, 3, C_STRAW_DEEP)
    fillEllipse(detailImg, cx, by - 31, 8, 2, C_STRAW_LIGHT)
    fillEllipse(detailImg, cx, by - 35, 4, 1, C_STRAW_LIGHT)

    -- Upper-left highlight on hat cone
    cluster(detailImg, {
      { cx - 2, by - 38 }, { cx - 3, by - 37 }, { cx - 4, by - 35 },
      { cx - 6, by - 33 }, { cx - 8, by - 31 }, { cx - 10, by - 29 }
    }, C_STRAW_HIGHLIGHT)

    -- Face under brim: bangs, eyes, chin tie
    cluster(detailImg, {
      { cx - 4, by - 27 }, { cx - 3, by - 27 }, { cx + 3, by - 27 }, { cx + 4, by - 27 }
    }, C_INK)
    pset(detailImg, cx - 2, by - 25, C_INK)
    pset(detailImg, cx + 2, by - 25, C_INK)
    pset(detailImg, cx,     by - 24, C_SKIN_SHADOW)
    hline(detailImg, cx - 1, cx + 1, by - 23, C_SKIN_SHADOW)
    -- Silk chin strap tie
    pset(detailImg, cx, by - 22, C_STRAW_DEEP)

    -- Áo bà ba: Highlights, buttons & sash knot
    cluster(detailImg, {
      { cx - 7, by - 21 }, { cx - 6, by - 21 }, { cx - 7, by - 19 },
      { cx - 6, by - 17 }, { cx - 7, by - 13 }
    }, C_INDIGO_BRIGHT)

    cluster(detailImg, {
      { cx + 6, by - 20 }, { cx + 7, by - 19 }, { cx + 7, by - 13 }
    }, C_INDIGO_DARK)

    -- Pearl buttons down center
    pset(detailImg, cx, by - 20, C_CANVAS_HIGHLIGHT)
    pset(detailImg, cx, by - 18, C_CANVAS_HIGHLIGHT)
    pset(detailImg, cx, by - 16, C_CANVAS_HIGHLIGHT)

    -- Warm sash highlight & knot on left hip
    hline(detailImg, cx - 6, cx + 6, by - 15, C_SASH_LIGHT)
    cluster(detailImg, {
      { cx - 6, by - 14 }, { cx - 7, by - 13 }, { cx - 7, by - 12 }
    }, C_SASH_GOLD)

    -- Trouser creases & ground shadow
    vline(detailImg, cx - 3, by - 9 + leftLegDy, by - 2 + leftLegDy, C_TROUSER_DARK)
    vline(detailImg, cx + 3, by - 9 + rightLegDy, by - 2 + rightLegDy, C_TROUSER_DARK)
    hline(detailImg, cx - 6, cx + 6, by + 1, C_INK)

  -- ==========================================================================
  -- DIRECTION 1: LEFT (Facing Left Profile)
  -- ==========================================================================
  elseif direction == 1 then
    -- Legs stride positions
    local frontLx = cx - 4
    local backLx  = cx + 2
    if animStep == 1 then
      frontLx = cx - 6
      backLx  = cx + 3
    elseif animStep == 2 then
      frontLx = cx - 2
      backLx  = cx + 4
    end

    -- Base: Boots
    fillRect(baseImg, frontLx - 2, by - 1 + leftLegDy, 4, 2, C_SOIL_DARK)
    fillRect(baseImg, backLx - 1,  by - 1 + rightLegDy, 3, 2, C_SOIL_DARK)

    -- Base: Trousers
    fillRect(baseImg, frontLx - 2, by - 11 + leftLegDy, 4, 10, C_TROUSER_MID)
    fillRect(baseImg, backLx - 1,  by - 11 + rightLegDy, 3, 10, C_TROUSER_DARK)

    -- Base: Áo bà ba body
    fillPolygon(baseImg, {
      { x = cx - 6, y = by - 22 },
      { x = cx + 5, y = by - 22 },
      { x = cx + 5, y = by - 11 },
      { x = cx - 6, y = by - 11 }
    }, C_INDIGO_MID)
    -- Sash
    fillRect(baseImg, cx - 5, by - 15, 10, 3, C_SASH_GOLD)
    -- Foreground arm
    fillRect(baseImg, cx - 2 + leftArmDy, by - 21, 4, 9, C_INDIGO_MID)
    fillRect(baseImg, cx - 2 + leftArmDy, by - 12, 2, 2, C_SKIN_MID)

    -- Base: Head profile
    fillRect(baseImg, cx - 5, by - 27, 8, 6, C_SKIN_MID)

    -- Base: Conical Nón Lá (Side profile)
    fillPolygon(baseImg, {
      { x = cx + 1,  y = by - 39 },
      { x = cx + 11, y = by - 29 },
      { x = cx - 11, y = by - 29 }
    }, C_STRAW_MID)

    -- Detail: Hat profile, nose, chin, chest highlight
    -- Sunlit front slope of conical hat
    cluster(detailImg, {
      { cx, by - 38 }, { cx - 2, by - 36 }, { cx - 4, by - 34 },
      { cx - 6, by - 32 }, { cx - 8, by - 31 }, { cx - 11, by - 29 }
    }, C_STRAW_HIGHLIGHT)
    -- Rear slope shadow
    cluster(detailImg, {
      { cx + 3, by - 36 }, { cx + 6, by - 33 }, { cx + 9, by - 30 }
    }, C_STRAW_SHADOW)
    hline(detailImg, cx - 10, cx + 10, by - 29, C_STRAW_DEEP)

    -- Profile face: nose, eye, chin strap
    pset(detailImg, cx - 6, by - 25, C_SKIN_LIGHT) -- nose
    pset(detailImg, cx - 4, by - 25, C_INK)        -- eye
    pset(detailImg, cx - 3, by - 22, C_STRAW_DEEP) -- tie

    -- Front chest highlight
    vline(detailImg, cx - 5, by - 21, by - 16, C_INDIGO_BRIGHT)
    hline(detailImg, cx - 4, cx + 4, by - 15, C_SASH_LIGHT)

    -- Ground shadow
    hline(detailImg, cx - 6, cx + 5, by + 1, C_INK)

  -- ==========================================================================
  -- DIRECTION 2: RIGHT (Facing Right Profile - Upper-left relit)
  -- ==========================================================================
  elseif direction == 2 then
    local frontLx = cx + 1
    local backLx  = cx - 5
    if animStep == 1 then
      frontLx = cx + 3
      backLx  = cx - 6
    elseif animStep == 2 then
      frontLx = cx - 1
      backLx  = cx - 3
    end

    -- Base: Boots
    fillRect(baseImg, backLx - 1,  by - 1 + leftLegDy, 3, 2, C_SOIL_DARK)
    fillRect(baseImg, frontLx - 1, by - 1 + rightLegDy, 4, 2, C_SOIL_DARK)

    -- Base: Trousers
    fillRect(baseImg, backLx - 1,  by - 11 + leftLegDy, 3, 10, C_TROUSER_DARK)
    fillRect(baseImg, frontLx - 1, by - 11 + rightLegDy, 4, 10, C_TROUSER_MID)

    -- Base: Áo bà ba body
    fillPolygon(baseImg, {
      { x = cx - 5, y = by - 22 },
      { x = cx + 6, y = by - 22 },
      { x = cx + 6, y = by - 11 },
      { x = cx - 5, y = by - 11 }
    }, C_INDIGO_MID)
    -- Sash
    fillRect(baseImg, cx - 5, by - 15, 10, 3, C_SASH_GOLD)
    -- Foreground arm
    fillRect(baseImg, cx - 1 + rightArmDy, by - 21, 4, 9, C_INDIGO_MID)
    fillRect(baseImg, cx + 1 + rightArmDy, by - 12, 2, 2, C_SKIN_MID)

    -- Base: Head profile
    fillRect(baseImg, cx - 3, by - 27, 8, 6, C_SKIN_MID)

    -- Base: Conical Nón Lá (Side profile)
    fillPolygon(baseImg, {
      { x = cx - 1,  y = by - 39 },
      { x = cx + 11, y = by - 29 },
      { x = cx - 11, y = by - 29 }
    }, C_STRAW_MID)

    -- Detail: Upper-left lighting on rear slope of hat!
    cluster(detailImg, {
      { cx - 2, by - 38 }, { cx - 4, by - 36 }, { cx - 6, by - 34 },
      { cx - 8, by - 32 }, { cx - 11, by - 29 }
    }, C_STRAW_HIGHLIGHT)
    -- Front slope in softer midtone
    cluster(detailImg, {
      { cx + 3, by - 36 }, { cx + 6, by - 33 }, { cx + 9, by - 30 }
    }, C_STRAW_SHADOW)
    hline(detailImg, cx - 10, cx + 10, by - 29, C_STRAW_DEEP)

    -- Profile face: nose, eye, chin strap
    pset(detailImg, cx + 5, by - 25, C_SKIN_LIGHT) -- nose
    pset(detailImg, cx + 3, by - 25, C_INK)        -- eye
    pset(detailImg, cx + 2, by - 22, C_STRAW_DEEP) -- tie

    -- Back catches upper-left light
    vline(detailImg, cx - 5, by - 21, by - 16, C_INDIGO_BRIGHT)
    hline(detailImg, cx - 4, cx + 4, by - 15, C_SASH_LIGHT)

    -- Ground shadow
    hline(detailImg, cx - 5, cx + 6, by + 1, C_INK)

  -- ==========================================================================
  -- DIRECTION 3: UP (Facing Away / Back View)
  -- ==========================================================================
  elseif direction == 3 then
    -- Base: Boots (heels)
    fillRect(baseImg, cx - 5, by - 1 + leftLegDy, 3, 2, C_SOIL_DARK)
    fillRect(baseImg, cx + 2, by - 1 + rightLegDy, 3, 2, C_SOIL_DARK)

    -- Base: Dark Trousers
    fillRect(baseImg, cx - 5, by - 11 + leftLegDy, 4, 10, C_TROUSER_DARK)
    fillRect(baseImg, cx + 1, by - 11 + rightLegDy, 4, 10, C_TROUSER_DARK)

    -- Base: Áo bà ba back
    fillPolygon(baseImg, {
      { x = cx - 8, y = by - 22 },
      { x = cx + 8, y = by - 22 },
      { x = cx + 8, y = by - 11 },
      { x = cx - 8, y = by - 11 }
    }, C_INDIGO_DARK)
    -- Sash across back
    fillRect(baseImg, cx - 7, by - 15, 15, 3, C_SASH_GOLD)
    -- Sleeves
    fillRect(baseImg, cx - 9, by - 21 + leftArmDy, 3, 9, C_INDIGO_DARK)
    fillRect(baseImg, cx + 7, by - 21 + rightArmDy, 3, 9, C_INDIGO_DARK)

    -- Base: Nape of neck & hair
    fillRect(baseImg, cx - 3, by - 26, 7, 5, C_INK)

    -- Base: Conical Nón Lá (Full circular back-top view)
    fillCircle(baseImg, cx, by - 32, 12, C_STRAW_MID)

    -- Detail: Concentric bamboo weave circles & quadrant lighting
    fillCircle(detailImg, cx, by - 32, 12, C_STRAW_DEEP)
    fillCircle(detailImg, cx, by - 32, 8,  C_STRAW_MID)
    fillCircle(detailImg, cx, by - 32, 4,  C_STRAW_LIGHT)
    pset(detailImg, cx, by - 32, C_STRAW_HIGHLIGHT) -- peak tip

    -- Upper-left quadrant sunlit sweep
    cluster(detailImg, {
      { cx - 4, by - 36 }, { cx - 5, by - 35 }, { cx - 7, by - 34 },
      { cx - 8, by - 32 }, { cx - 7, by - 30 }, { cx - 9, by - 33 }
    }, C_STRAW_HIGHLIGHT)

    -- Lower-right quadrant deep shade
    cluster(detailImg, {
      { cx + 5, by - 28 }, { cx + 7, by - 29 }, { cx + 8, by - 31 }, { cx + 6, by - 30 }
    }, C_STRAW_DEEP)

    -- Back central seam on tunic
    vline(detailImg, cx, by - 21, by - 16, C_INDIGO_INK)
    -- Left shoulder highlight
    cluster(detailImg, {
      { cx - 7, by - 21 }, { cx - 6, by - 21 }, { cx - 7, by - 19 }
    }, C_INDIGO_MID)

    -- Ground shadow
    hline(detailImg, cx - 6, cx + 6, by + 1, C_INK)
  end
end

-- ============================================================================
-- Main Generation Routine
-- Generates all 8 required assets with exact specified dimensions and names
-- ============================================================================

-- 1. player.png (96x192)
saveSprite("player", 96, 192,
  function(baseImg)
    for row = 0, 3 do
      for col = 0, 2 do
        drawPlayer(baseImg, Image(96, 192), col * 32, row * 48, row, col)
      end
    end
  end,
  function(detailImg)
    for row = 0, 3 do
      for col = 0, 2 do
        drawPlayer(Image(96, 192), detailImg, col * 32, row * 48, row, col)
      end
    end
  end
)

-- 2. village_people.png (64x48)
saveSprite("village_people", 64, 48,
  function(baseImg)
    drawCoHue(baseImg, Image(64, 48), 0, 0)
    drawBacBay(baseImg, Image(64, 48), 32, 0)
  end,
  function(detailImg)
    drawCoHue(Image(64, 48), detailImg, 0, 0)
    drawBacBay(Image(64, 48), detailImg, 32, 0)
  end
)

-- 3. crops.png (96x32: Cabbage)
saveSprite("crops", 96, 32,
  function(baseImg)
    drawSoilMound(baseImg, Image(96, 32), 0,  0, "cabbage_seed")
    drawSoilMound(baseImg, Image(96, 32), 32, 0, nil)
    drawCabbageSprout(baseImg, Image(96, 32), 32, 0)
    drawSoilMound(baseImg, Image(96, 32), 64, 0, nil)
    drawCabbageMature(baseImg, Image(96, 32), 64, 0)
  end,
  function(detailImg)
    drawSoilMound(Image(96, 32), detailImg, 0,  0, "cabbage_seed")
    drawSoilMound(Image(96, 32), detailImg, 32, 0, nil)
    drawCabbageSprout(Image(96, 32), detailImg, 32, 0)
    drawSoilMound(Image(96, 32), detailImg, 64, 0, nil)
    drawCabbageMature(Image(96, 32), detailImg, 64, 0)
  end
)

-- 4. carrots.png (96x32: Carrot)
saveSprite("carrots", 96, 32,
  function(baseImg)
    drawSoilMound(baseImg, Image(96, 32), 0,  0, "carrot_seed")
    drawSoilMound(baseImg, Image(96, 32), 32, 0, nil)
    drawCarrotSprout(baseImg, Image(96, 32), 32, 0)
    drawSoilMound(baseImg, Image(96, 32), 64, 0, nil)
    drawCarrotMature(baseImg, Image(96, 32), 64, 0)
  end,
  function(detailImg)
    drawSoilMound(Image(96, 32), detailImg, 0,  0, "carrot_seed")
    drawSoilMound(Image(96, 32), detailImg, 32, 0, nil)
    drawCarrotSprout(Image(96, 32), detailImg, 32, 0)
    drawSoilMound(Image(96, 32), detailImg, 64, 0, nil)
    drawCarrotMature(Image(96, 32), detailImg, 64, 0)
  end
)

-- 5. radishes.png (96x32: White Radish)
saveSprite("radishes", 96, 32,
  function(baseImg)
    drawSoilMound(baseImg, Image(96, 32), 0,  0, "radish_seed")
    drawSoilMound(baseImg, Image(96, 32), 32, 0, nil)
    drawRadishSprout(baseImg, Image(96, 32), 32, 0)
    drawSoilMound(baseImg, Image(96, 32), 64, 0, nil)
    drawRadishMature(baseImg, Image(96, 32), 64, 0)
  end,
  function(detailImg)
    drawSoilMound(Image(96, 32), detailImg, 0,  0, "radish_seed")
    drawSoilMound(Image(96, 32), detailImg, 32, 0, nil)
    drawRadishSprout(Image(96, 32), detailImg, 32, 0)
    drawSoilMound(Image(96, 32), detailImg, 64, 0, nil)
    drawRadishMature(Image(96, 32), detailImg, 64, 0)
  end
)

-- 6. seed_bags.png (64x32: Cabbage & Carrot bags)
saveSprite("seed_bags", 64, 32,
  function(baseImg)
    drawCanvasBag(baseImg, Image(64, 32), 0,  0)
    drawCanvasBag(baseImg, Image(64, 32), 32, 0)
  end,
  function(detailImg)
    drawCanvasBag(Image(64, 32), detailImg, 0,  0)
    drawCabbageEmblem(detailImg, 0, 0)
    drawCanvasBag(Image(64, 32), detailImg, 32, 0)
    drawCarrotEmblem(detailImg, 32, 0)
  end
)

-- 7. radish_seed.png (32x32: Radish bag)
saveSprite("radish_seed", 32, 32,
  function(baseImg)
    drawCanvasBag(baseImg, Image(32, 32), 0, 0)
  end,
  function(detailImg)
    drawCanvasBag(Image(32, 32), detailImg, 0, 0)
    drawRadishEmblem(detailImg, 0, 0)
  end
)

-- 8. fish.png (96x32: Cá Rô, Cá Trê, Cá Chép swimming left)
saveSprite("fish", 96, 32,
  function(baseImg)
    drawPerch(baseImg, Image(96, 32), 0,  0)
    drawCatfish(baseImg, Image(96, 32), 32, 0)
    drawCarp(baseImg, Image(96, 32), 64, 0)
  end,
  function(detailImg)
    drawPerch(Image(96, 32), detailImg, 0,  0)
    drawCatfish(Image(96, 32), detailImg, 32, 0)
    drawCarp(Image(96, 32), detailImg, 64, 0)
  end
)
