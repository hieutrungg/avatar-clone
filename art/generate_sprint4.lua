-- art/generate_sprint4.lua
-- Aseprite 1.3.15.5-dev Lua batch generator for "Vườn Nhỏ" (Sprint 4)
-- Generates editable .aseprite files (Base & Detail layers) and exports 1x crisp PNGs.

local source_dir = (app.params and app.params["source_dir"]) or "art"
local out_dir = (app.params and app.params["out_dir"]) or "assets/art"

if app.fs and app.fs.makeAllDirectories then
  pcall(function() app.fs.makeAllDirectories(source_dir) end)
  pcall(function() app.fs.makeAllDirectories(out_dir) end)
end

local function makeRgba(r, g, b, a)
  a = a or 255
  if app.pixelColor and app.pixelColor.rgba then
    return app.pixelColor.rgba(r, g, b, a)
  end
  return Color{ r = r, g = g, b = b, a = a }
end

local palette_list = {
  { r = 0x15, g = 0x10, b = 0x0c, a = 255 }, -- 1:  #15100c deepest shadow / outline
  { r = 0x36, g = 0x20, b = 0x13, a = 255 }, -- 2:  #362013 deep wood / soil
  { r = 0x5e, g = 0x35, b = 0x19, a = 255 }, -- 3:  #5e3519 rich brown / bark
  { r = 0x94, g = 0x5a, b = 0x2b, a = 255 }, -- 4:  #945a2b warm wood / soil mid
  { r = 0xc6, g = 0x8a, b = 0x4c, a = 255 }, -- 5:  #c68a4c light wood / plank
  { r = 0xee, g = 0xd1, b = 0x9c, a = 255 }, -- 6:  #eed19c cream / cloth / radish root
  { r = 0x1c, g = 0x38, b = 0x1c, a = 255 }, -- 7:  #1c381c deepest foliage shadow
  { r = 0x38, g = 0x6e, b = 0x2d, a = 255 }, -- 8:  #386e2d foliage body
  { r = 0x6c, g = 0xa3, b = 0x3b, a = 255 }, -- 9:  #6ca33b leaf green
  { r = 0xa8, g = 0xd4, b = 0x5d, a = 255 }, -- 10: #a8d45d lime green / sprout tip
  { r = 0x78, g = 0x20, b = 0x17, a = 255 }, -- 11: #782017 deep red shadow
  { r = 0xbd, g = 0x38, b = 0x26, a = 255 }, -- 12: #bd3826 ripe red produce / bunting
  { r = 0xea, g = 0x65, b = 0x32, a = 255 }, -- 13: #ea6532 orange produce / bunting
  { r = 0x22, g = 0x44, b = 0x5e, a = 255 }, -- 14: #22445e dark river blue shadow
  { r = 0x3e, g = 0x78, b = 0xa6, a = 255 }, -- 15: #3e78a6 river blue canopy stripe
  { r = 0x80, g = 0x9c, b = 0x91, a = 255 }, -- 16: #809c91 sage / blue-green badge
}

local pal_map = {
  ["K"] = makeRgba(0x15, 0x10, 0x0c, 255),
  ["D"] = makeRgba(0x36, 0x20, 0x13, 255),
  ["M"] = makeRgba(0x5e, 0x35, 0x19, 255),
  ["W"] = makeRgba(0x94, 0x5a, 0x2b, 255),
  ["L"] = makeRgba(0xc6, 0x8a, 0x4c, 255),
  ["C"] = makeRgba(0xee, 0xd1, 0x9c, 255),
  ["S"] = makeRgba(0x1c, 0x38, 0x1c, 255),
  ["F"] = makeRgba(0x38, 0x6e, 0x2d, 255),
  ["G"] = makeRgba(0x6c, 0xa3, 0x3b, 255),
  ["H"] = makeRgba(0xa8, 0xd4, 0x5d, 255),
  ["R"] = makeRgba(0x78, 0x20, 0x17, 255),
  ["r"] = makeRgba(0xbd, 0x38, 0x26, 255),
  ["O"] = makeRgba(0xea, 0x65, 0x32, 255),
  ["T"] = makeRgba(0x22, 0x44, 0x5e, 255),
  ["B"] = makeRgba(0x3e, 0x78, 0xa6, 255),
  ["A"] = makeRgba(0x80, 0x9c, 0x91, 255),
}

local assets = {
  ------------------------------------------------------------------------------
  -- 1) radishes.png 48x16 (3 distinct 16x16 frames with shared soil baseline)
  ------------------------------------------------------------------------------
  {
    name = "radishes",
    width = 48,
    height = 16,
    base = {
      "................................................",
      ".....................................G.....G....",
      "....................................GGG...GGG...",
      "...................................GGGG.G.GGGG..",
      ".......................G............GG.GGG.GG...",
      "......................GGG............FGGGGGF....",
      "....................GG.G.GG...........FFFFF.....",
      "...................GGG.G.GGG...........FFF......",
      "....................GG.G.GG...........CCCCC.....",
      "......................FFF............CCCCCCC....",
      ".......W..............FFF............CCCCCCC....",
      ".....WWWWWW.........WWWWWW............CCCCC.....",
      "...MMMMMMMMMM.....MMMMMMMMMM.......MMM.CCC.MM...",
      "..DDDDDDDDDDDD...DDDDDDDDDDDD.....DDDD..C.DDDD..",
      ".KKKKKKKKKKKKKK..KKKKKKKKKKKKKK..KKKKK....KKKKK.",
      "................................................",
    },
    detail = {
      "................................................",
      ".....................................H.....H....",
      "....................................HHH...HHH...",
      "...................................HH.S.H.S.HH..",
      ".......................H............S.SHS.S.S...",
      "......................HHH............SSSSSSS....",
      "....................HH.H.HH...........SSSSS.....",
      "...................H.S.H.S.H...........SSS......",
      "....................S..S..S...........WCCW......",
      "......................SSS............L.CC.L.....",
      ".......L..............SSS............L.CC.L.....",
      ".....L.CC.L.........L.CC.L............LCCL......",
      "...W..K..W..M.....W..K..W..M.......W...LC...M...",
      "..K..M....K..D...K..M....K..D.....K....L.....D..",
      ".K...K....K...K..K...K....K...K..K...........K.",
      "................................................",
    },
  },

  ------------------------------------------------------------------------------
  -- 2) radish_seed.png 16x16 (cream seed bag, blue-green badge, centered)
  ------------------------------------------------------------------------------
  {
    name = "radish_seed",
    width = 16,
    height = 16,
    base = {
      "................",
      "................",
      "......CCCC......",
      ".....CCCCCC.....",
      "......CCCC......",
      ".....WWWWWW.....",
      "...CCCCCCCCCC...",
      "..CCCCCCCCCCCC..",
      "..CCCCCCCCCCCC..",
      "..CCCCCCCCCCCC..",
      "..CCCCCCCCCCCC..",
      "..CCCCCCCCCCCC..",
      "...CCCCCCCCCC...",
      "...WWWWWWWWWW...",
      "....KKKKKKKK....",
      "................",
    },
    detail = {
      "................",
      "................",
      "......L..L......",
      ".....L.CC.L.....",
      "......M..M......",
      ".....M.DD.M.....",
      "...W...M...W....",
      "..L....D....L...",
      "..L...TAAT..L...",
      "..L..TAAHAT.L...",
      "..L..TAACAT.L...",
      "..L...TAAT..L...",
      "...LLLLLLLLLL...",
      "...DDDDDDDDDD...",
      "................",
      "................",
    },
  },

  ------------------------------------------------------------------------------
  -- 3) market_booth.png 48x32 (wood stall, cream/blue canopy, bunting, crates)
  ------------------------------------------------------------------------------
  {
    name = "market_booth",
    width = 48,
    height = 32,
    base = {
      "................................................",
      "................................................",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BBBBBCCCCCTTTTTCCCCCBBBBBCCCCCTTTTTCCCCC....",
      "....BB.BBCC.CCTTT.TTCC.CCBB.BBCC.CCTTT.TTCC.CC..",
      "....B...BC...CT...TC...TB...BC...CT...TC...T....",
      ".......WW.............................WW........",
      ".......WW.............................WW........",
      ".......WW.............................WW........",
      ".......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW........",
      ".......WW.............................WW........",
      ".......WW...LLLLLLLL.......LLLLLLLL...WW........",
      ".......WW...LLLLLLLL.......LLLLLLLL...WW........",
      ".......WW.............................WW........",
      ".......WW.............................WW........",
      "......LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL......",
      "......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW......",
      ".......LLLLLLLLLLLLL........LLLLLLLLLLLLL.......",
      ".......LLLLLLLLLLLLL..LLLL..LLLLLLLLLLLLL.......",
      ".......LLLLLLLLLLLLL..LLLL..LLLLLLLLLLLLL.......",
      ".......MM..LL..WW..MM..LL..WW..MM..LL..WW.......",
      ".......MM..LL..WW..MM..LL..WW..MM..LL..WW.......",
      ".......MM..LL..WW..MM..LL..WW..MM..LL..WW.......",
      ".......MM..LL..WW..MM..LL..WW..MM..LL..WW.......",
      ".......WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW.......",
      ".......DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD.......",
      "......MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM........",
      ".....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK.......",
    },
    detail = {
      "................................................",
      "................................................",
      "....HHHHHCCCCCHHHHHCCCCCHHHHHCCCCCHHHHHCCCCC....",
      "................................................",
      "................................................",
      "................................................",
      "....TTTTTCCCCCTTTTTCCCCCTTTTTCCCCCTTTTTCCCCC....",
      "....TTTTTCCCCCTTTTTCCCCCTTTTTCCCCCTTTTTCCCCC....",
      "................................................",
      "................................................",
      "........W.............................W.........",
      ".........W.rr...OO...CC...BB...rr....W..........",
      "..........rr....OO...CC...BB...rr...............",
      "..........r.....O....C....B....r................",
      "................................................",
      "............r.O........G...r.C..................",
      "................................................",
      "................................................",
      ".......FFGG..HH............r.rr..CC.HH..........",
      "......GGOOOOOGGGG....LL....rrOOrrCCCCGGGG.......",
      ".......W...W...W......W.....W...W...W...........",
      ".......W.M.W.M.W............W.M.W.M.W...........",
      ".......W...W...W......K.....W...W...W...........",
      ".......WWWWWWWWW............WWWWWWWWW...........",
      ".......K...K...K...K...K...K...K...K...K........",
      ".......K...K...K...K...K...K...K...K...K........",
      ".......K...K...K...K...K...K...K...K...K........",
      ".......K...K...K...K...K...K...K...K...K........",
      ".......M...M...M...M...M...M...M...M...M........",
      "................................................",
      "......L................................L........",
      "................................................",
    },
  },

  ------------------------------------------------------------------------------
  -- 4) wayfinding.png 32x16 (two 16x16 tile art cells: arrow right & arrow left)
  ------------------------------------------------------------------------------
  {
    name = "wayfinding",
    width = 32,
    height = 16,
    base = {
      "................................",
      "................................",
      "................................",
      "..LLLLLLLL............LLLLLLLL..",
      "..LLLLLLLLLL........LLLLLLLLLL..",
      "..LLLLLLLLLLLL....LLLLLLLLLLLL..",
      "..LLLLLLLLLLLL....LLLLLLLLLLLL..",
      "..LLLLLLLLLL........LLLLLLLLLL..",
      "..LLLLLLLL............LLLLLLLL..",
      ".......WW..............WW.......",
      ".......WW..............WW.......",
      ".......WW..............WW.......",
      ".......WW..............WW.......",
      ".......WW..............WW.......",
      "......DDDD............DDDD......",
      ".....KKKKKK..........KKKKKK.....",
    },
    detail = {
      "................................",
      "................................",
      "................................",
      "..CCCCCCCC............CCCCCCCC..",
      "..C....DD.M.........M.DD....C...",
      "..C.DDDDDDDDM.....MDDDDDDDD.C...",
      "..C.DDDDDDDDM.....MDDDDDDDD.C...",
      "..C....DD.M.........M.DD....C...",
      "..MMMMMMMM............MMMMMMMM..",
      ".......L.M............L.M.......",
      ".......L.M............L.M.......",
      ".......L.M............L.M.......",
      ".......L.M............L.M.......",
      ".......L.M............L.M.......",
      "......GFFG............GFFG......",
      "................................",
    },
  },
}

local function joinPath(dir, filename)
  if dir:sub(-1) == "/" or dir:sub(-1) == "\\" then
    return dir .. filename
  end
  return dir .. "/" .. filename
end

for _, asset in ipairs(assets) do
  local w = asset.width
  local h = asset.height
  local spr = Sprite(w, h, ColorMode.RGB)

  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"
  local detailLayer = spr:newLayer()
  detailLayer.name = "Detail"

  -- Base layer: draw onto existing cel.image
  local baseCel = baseLayer:cel(1)
  local baseImg = baseCel and baseCel.image or Image(w, h, ColorMode.RGB)
  for y = 0, h - 1 do
    local line = asset.base[y + 1]
    for x = 0, w - 1 do
      local ch = line:sub(x + 1, x + 1)
      local col = pal_map[ch]
      if col then
        baseImg:drawPixel(x, y, col)
      end
    end
  end
  if not baseCel then
    spr:newCel(baseLayer, 1, baseImg, Point(0, 0))
  end

  -- Detail layer: draw onto image before newCel
  local detailImg = Image(w, h, ColorMode.RGB)
  for y = 0, h - 1 do
    local line = asset.detail[y + 1]
    for x = 0, w - 1 do
      local ch = line:sub(x + 1, x + 1)
      local col = pal_map[ch]
      if col then
        detailImg:drawPixel(x, y, col)
      end
    end
  end
  spr:newCel(detailLayer, 1, detailImg, Point(0, 0))

  -- Populate sprite palette table for convenient editing
  local pal = spr.palettes[1]
  pal:resize(#palette_list + 1)
  for i, c in ipairs(palette_list) do
    pal:setColor(i, Color{ r = c.r, g = c.g, b = c.b, a = c.a })
  end

  local asePath = joinPath(source_dir, asset.name .. ".aseprite")
  local pngPath = joinPath(out_dir, asset.name .. ".png")

  spr:saveCopyAs(asePath)
  spr:saveCopyAs(pngPath)
  spr:close()

  print(string.format("Exported %s (%dx%d) -> %s & %s", asset.name, w, h, asePath, pngPath))
end

print("Sprint 4 art generation finished.")
