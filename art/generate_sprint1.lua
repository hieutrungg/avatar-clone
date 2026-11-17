-- ============================================================================
-- Vườn Nhỏ - Vietnamese Countryside Pixel Art Generator (Sprint 1)
-- Aseprite Script (Aseprite 1.3.15.5-dev on Windows)
--
-- Generates 3 original retro farm assets at 1x resolution:
--   1. carrots   (48x16): planted seed mound, delicate sprout, ripe carrot with greens
--   2. seed_bags (32x16): cabbage seed bag (green mark), carrot seed bag (orange mark)
--   3. shop_sign (16x16): warm wooden signpost with light seed-bag emblem
--
-- Saves editable .aseprite files (with Base and Detail layers) to source_dir
-- and exports flattened RGBA .png files to out_dir.
-- ============================================================================

local out_dir = (app.params and app.params["out_dir"]) or "assets/art"
local source_dir = (app.params and app.params["source_dir"]) or "art"

local function joinPath(dir, filename)
  local clean_dir = tostring(dir):gsub("[/\\]+$", "")
  local sep = clean_dir:find("\\") and "\\" or "/"
  return clean_dir .. sep .. filename
end

-- Shared 16-color Vietnamese countryside palette
local PALETTE_DEF = {
  ["0"] = { r = 0x15, g = 0x10, b = 0x0c, a = 255 }, -- deep dark / outline
  ["1"] = { r = 0x36, g = 0x20, b = 0x13, a = 255 }, -- dark bark / shadow
  ["2"] = { r = 0x5e, g = 0x35, b = 0x19, a = 255 }, -- rich loam / wet earth
  ["3"] = { r = 0x94, g = 0x5a, b = 0x2b, a = 255 }, -- untouched earth / wood shadow
  ["4"] = { r = 0xc6, g = 0x8a, b = 0x4c, a = 255 }, -- dry tilled crest / golden burlap
  ["5"] = { r = 0xee, g = 0xd1, b = 0x9c, a = 255 }, -- warm cream / straw highlight
  ["6"] = { r = 0x1c, g = 0x38, b = 0x1c, a = 255 }, -- deep shadow foliage
  ["7"] = { r = 0x38, g = 0x6e, b = 0x2d, a = 255 }, -- leaf midtone / grass
  ["8"] = { r = 0x6c, g = 0xa3, b = 0x3b, a = 255 }, -- soft green / sprout midtone
  ["9"] = { r = 0xa8, g = 0xd4, b = 0x5d, a = 255 }, -- pale sprout green highlight
  ["r"] = { r = 0x78, g = 0x20, b = 0x17, a = 255 }, -- terracotta shadow
  ["R"] = { r = 0xbd, g = 0x38, b = 0x26, a = 255 }, -- carrot shade / red tile
  ["O"] = { r = 0xea, g = 0x65, b = 0x32, a = 255 }, -- ripe carrot orange
  ["b"] = { r = 0x22, g = 0x44, b = 0x5e, a = 255 }, -- indigo shadow
  ["B"] = { r = 0x3e, g = 0x78, b = 0xa6, a = 255 }, -- indigo blue
  ["S"] = { r = 0x80, g = 0x9c, b = 0x91, a = 255 }, -- stone sheen
  ["."] = { r = 0,    g = 0,    b = 0,    a = 0   }, -- transparent
}

local COLOR_MAP = {}
for ch, c in pairs(PALETTE_DEF) do
  COLOR_MAP[ch] = app.pixelColor.rgba(c.r, c.g, c.b, c.a)
end

-- ============================================================================
-- 1. CARROTS (48x16): 3 cells of 16x16
-- Shared ground baseline at row y=14, contact shadow at row y=15
-- ============================================================================
local carrots_base = {
  "................................................",
  "................................................",
  "................................................",
  "..................................7...7...7.....",
  ".................................777.777.777....",
  ".................................77777777777....",
  "..................................777777777.....",
  ".....................7...7.........7777777......",
  "....................777.777.........77777.......",
  "....................777.777..........777........",
  ".....................77777..........OOOOOO......",
  ".......4O.............777..........OOOOOOOO.....",
  ".....222222..........222222........OOOOOOOO.....",
  "....22222222........22222222......22OOOOOO22....",
  "...2222222222......2222222222....222222222222...",
  "................................................"
}

local carrots_detail = {
  "................................................",
  "................................................",
  "................................................",
  "..................................9...9...9.....",
  ".................................989.989.989....",
  ".................................89889889876....",
  "..................................788988776.....",
  ".....................9...9.........7888776......",
  "....................989.989.........78776.......",
  "....................876.876..........766........",
  ".....................88766..........05OOR0......",
  ".......4O.............876..........055OORR0.....",
  ".....442013..........442013........05OOORR0.....",
  "....43222110........43222110......20OOOOR0210...",
  "...3222222110.......3222222110.....3222222110...",
  "....11111110........11111110........11111110...."
}

-- ============================================================================
-- 2. SEED BAGS (32x16): 2 cells of 16x16
-- Cell 0: Cabbage seed bag (green mark) | Cell 1: Carrot seed bag (orange mark)
-- ============================================================================
local seed_bags_base = {
  "................................",
  "................................",
  "................................",
  "...44..44..........44..44.......",
  "....4444............4444........",
  "...333333..........333333.......",
  "..44444444........44444444......",
  ".4444444444......4444444444.....",
  ".4444774444......4444OO4444.....",
  ".4447777444......4444OO4444.....",
  ".4444774444......44444O4444.....",
  ".4444444444......4444444444.....",
  "..44444444........44444444......",
  "...333333..........333333.......",
  "................................",
  "................................"
}

local seed_bags_detail = {
  "................................",
  "................................",
  "................................",
  "...55..540.........55..540......",
  "....55440...........55440.......",
  "...0354100.........0354100......",
  "..05555430........05555430......",
  ".055.98.430......055.98.430.....",
  ".05.9886.30......05.5OOR.30.....",
  ".05.8776.30......05..OOR.30.....",
  ".054.76.430......054..R.430.....",
  ".0554443330......0554443330.....",
  "..04433310........04433310......",
  "...011110..........011110.......",
  "....1111............1111........",
  "................................"
}

-- ============================================================================
-- 3. SHOP SIGN (16x16): 1 cell of 16x16
-- Warm wooden signpost with light seed-bag emblem, bottom center aligned
-- ============================================================================
local shop_sign_base = {
  "................",
  "................",
  "..333333333333..",
  ".33333333333333.",
  ".33333533533333.",
  ".33333555533333.",
  ".33333555533333.",
  ".33333355333333.",
  ".33333333333333.",
  "..333333333333..",
  "......3333......",
  "......3333......",
  "......3333......",
  "......3333......",
  "......3333......",
  "................"
}

local shop_sign_detail = {
  "................",
  "................",
  "..044444444440..",
  ".05555555555410.",
  ".04333533533210.",
  ".04333455333210.",
  ".04333555433210.",
  ".04333355333210.",
  ".03333333333210.",
  "..011111111110..",
  "......0420......",
  "......0420......",
  "......0420......",
  "......0420......",
  "......0310......",
  ".....011110....."
}

-- ============================================================================
-- Rendering & Export Helpers
-- ============================================================================
local function renderGrid(image, grid, charMap)
  assert(#grid == image.height, "Grid height must match the atlas")
  for y = 0, #grid - 1 do
    local line = grid[y + 1]
    assert(#line == image.width, "Grid width must match the atlas on row " .. (y + 1))
    for x = 0, #line - 1 do
      local ch = line:sub(x + 1, x + 1)
      local col = charMap[ch]
      if col and ch ~= "." then
        image:drawPixel(x, y, col)
      end
    end
  end
end

local function generateAsset(name, width, height, baseGrid, detailGrid)
  local spr = Sprite(width, height, ColorMode.RGB)

  -- Setup Layer 1: "Base"
  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"
  local baseCel = baseLayer:cel(1)
  if not baseCel then
    local baseImg = Image(width, height, ColorMode.RGB)
    renderGrid(baseImg, baseGrid, COLOR_MAP)
    spr:newCel(baseLayer, 1, baseImg, Point(0, 0))
  else
    renderGrid(baseCel.image, baseGrid, COLOR_MAP)
  end

  -- Setup Layer 2: "Detail"
  local detailLayer = spr:newLayer()
  detailLayer.name = "Detail"
  local detailImg = Image(width, height, ColorMode.RGB)
  renderGrid(detailImg, detailGrid, COLOR_MAP)
  spr:newCel(detailLayer, 1, detailImg, Point(0, 0))

  -- Paths for editable .aseprite and exported RGBA .png
  local aseFile = joinPath(source_dir, name .. ".aseprite")
  local pngFile = joinPath(out_dir, name .. ".png")

  spr:saveAs(aseFile)
  spr:saveCopyAs(pngFile)
  spr:close()
end

-- ============================================================================
-- Main Routine
-- ============================================================================
local assets = {
  { name = "carrots",   width = 48, height = 16, base = carrots_base,   detail = carrots_detail   },
  { name = "seed_bags", width = 32, height = 16, base = seed_bags_base, detail = seed_bags_detail },
  { name = "shop_sign", width = 16, height = 16, base = shop_sign_base, detail = shop_sign_detail },
}

for _, a in ipairs(assets) do
  generateAsset(a.name, a.width, a.height, a.base, a.detail)
end
