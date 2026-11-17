-- generate_sprint3.lua
-- Batch asset generation for "Vườn Nhỏ" (Vietnamese Countryside Farming Game)
-- Aseprite 1.3.15.5-dev batch script
-- Outputs editable .aseprite (Base + Detail layers) and RGBA .png files

local source_dir = (app.params and app.params["source_dir"]) or "art"
local out_dir = (app.params and app.params["out_dir"]) or "assets/art"

if app.fs and app.fs.makeDirectory then
  pcall(app.fs.makeDirectory, source_dir)
  pcall(app.fs.makeDirectory, out_dir)
end

-- 16-color palette
local PAL = {
  _ = Color{ r = 0, g = 0, b = 0, a = 0 },             -- transparent
  k = Color{ r = 0x15, g = 0x10, b = 0x0c, a = 255 }, -- #15100c ink outline / darkest bark
  d = Color{ r = 0x36, g = 0x20, b = 0x13, a = 255 }, -- #362013 deep shadow / dark wood
  b = Color{ r = 0x5e, g = 0x35, b = 0x19, a = 255 }, -- #5e3519 wood shadow
  w = Color{ r = 0x94, g = 0x5a, b = 0x2b, a = 255 }, -- #945a2b warm wood
  l = Color{ r = 0xc6, g = 0x8a, b = 0x4c, a = 255 }, -- #c68a4c light wood / skin shadow
  s = Color{ r = 0xee, g = 0xd1, b = 0x9c, a = 255 }, -- #eed19c straw / nón lá / paper / skin
  g = Color{ r = 0x1c, g = 0x38, b = 0x1c, a = 255 }, -- #1c381c dark foliage
  G = Color{ r = 0x38, g = 0x6e, b = 0x2d, a = 255 }, -- #386e2d foliage green
  p = Color{ r = 0x6c, g = 0xa3, b = 0x3b, a = 255 }, -- #6ca33b green midtone
  P = Color{ r = 0xa8, g = 0xd4, b = 0x5d, a = 255 }, -- #a8d45d bright sprout green
  t = Color{ r = 0x78, g = 0x20, b = 0x17, a = 255 }, -- #782017 deep terracotta
  r = Color{ r = 0xbd, g = 0x38, b = 0x26, a = 255 }, -- #bd3826 red terracotta / blouse
  o = Color{ r = 0xea, g = 0x65, b = 0x32, a = 255 }, -- #ea6532 bright roof / warm highlight
  i = Color{ r = 0x22, g = 0x44, b = 0x5e, a = 255 }, -- #22445e dark indigo
  I = Color{ r = 0x3e, g = 0x78, b = 0xa6, a = 255 }, -- #3e78a6 bright indigo
  f = Color{ r = 0x80, g = 0x9c, b = 0x91, a = 255 }, -- #809c91 sage scarf / metal
}

local function pset(img, x, y, c)
  if c and x >= 0 and x < img.width and y >= 0 and y < img.height then
    img:drawPixel(x, y, c)
  end
end

local function fillRect(img, x, y, w, h, c)
  for py = y, y + h - 1 do
    for px = x, x + w - 1 do
      pset(img, px, py, c)
    end
  end
end

local function drawMatrix(img, ox, oy, rows)
  for r = 1, #rows do
    local line = rows[r]
    local y = oy + r - 1
    for c = 1, #line do
      local ch = line:sub(c, c)
      local col = PAL[ch]
      if col then
        pset(img, ox + c - 1, y, col)
      end
    end
  end
end

local function saveSprite(filename, w, h, drawBase, drawDetail)
  local spr = Sprite(w, h, ColorMode.RGB)

  -- Setup Base layer
  local baseLayer = spr.layers[1]
  baseLayer.name = "Base"
  local baseCel = baseLayer.cels[1]
  if baseCel then
    drawBase(baseCel.image)
  else
    local baseImg = Image(w, h, ColorMode.RGB)
    drawBase(baseImg)
    spr:newCel(baseLayer, 1, baseImg)
  end

  -- Setup Detail layer (draw before newCel)
  local detailLayer = spr:newLayer()
  detailLayer.name = "Detail"
  local detailImg = Image(w, h, ColorMode.RGB)
  drawDetail(detailImg)
  spr:newCel(detailLayer, 1, detailImg)

  -- Save outputs
  local asePath = source_dir .. "/" .. filename .. ".aseprite"
  local pngPath = out_dir .. "/" .. filename .. ".png"
  spr:saveAs(asePath)
  spr:saveCopyAs(pngPath)
  spr:close()
end

--------------------------------------------------------------------------------
-- 1. village_people (32x24)
-- Standing front: Cô Huệ (seed seller, 0..15) & Bác Bảy (riverside cook, 16..31)
--------------------------------------------------------------------------------
local people_base = {
  "________________________________",
  "_______ss_____________dddd______",
  "______ssss___________dddddd_____",
  "_____ssssss__________kkkkkk_____",
  "____ssssssss________dddddddd____",
  "___ssssssssss________dssssd_____",
  "__ssssssssssss______dksskskd____",
  "_ssssssssssssss_____dssddssd____",
  "___ddssssssdd________ddssdd_____",
  "___dkslsslsbk_______ffffffff____",
  "____dssssd_________fffsfffsf____",
  "____rrrrrrrr_______iiiiiiiiii___",
  "___rrrrrrrrrr_____iiiiiiiiiiii__",
  "___rrrrrrrrrr_____iiiiiiiiiiii__",
  "___ssrrrrrrss_____ssiiiiiiiiss__",
  "____rrrrrrrr_______iiiiiiiiii___",
  "____kkddddkk________dddddddd____",
  "____kkddddkk________iiiiiiii____",
  "____kkd__dkk________iii__iii____",
  "____kkd__dkk________iii__iii____",
  "____kkd__dkk________iii__iii____",
  "____kkd__dkk________lll__lll____",
  "____lld__dll________ddd__ddd____",
  "____kkk__kkk________kkk__kkk____",
}

local people_detail = {
  "________________________________",
  "_______ll_____________kkkk______",
  "______llll___________kddddk_____",
  "_____llllll__________dffffd_____",
  "____llllllll________dddddddd____",
  "___lllsllllsll_______dssssd_____",
  "__llsllllllllll_____kksskskk____",
  "_llllllllllllll_____kskddksk____",
  "___ttlllllltt________kksskk_____",
  "___kkslsslsbk_______ssfffsff____",
  "____tssssd__________ffffffff____",
  "____rorrroro_______iIiiiiiiIi___",
  "___roossssoor_____iIIiiiiiiIIi__",
  "___rrrsPPsrr______iIiiIwwIiiIi__",
  "___ssllwwllss_____ssiiIwwIliss__",
  "____rrrrrrrr_______iiiiiiiiii___",
  "____kkddddkk________kkddddkk____",
  "____kkooodkk________iIIiiiII____",
  "____kkd__dkk________iII__IIi____",
  "____kkd__dkk________iII__IIi____",
  "____kkd__dkk________iII__IIi____",
  "____kld__dlk________lll__lll____",
  "____kld__dlk________kdd__ddk____",
  "____kkk__kkk________kkk__kkk____",
}

local function drawPeopleBase(img)
  drawMatrix(img, 0, 0, people_base)
end

local function drawPeopleDetail(img)
  drawMatrix(img, 0, 0, people_detail)
end

--------------------------------------------------------------------------------
-- 2. village_board (16x16)
-- Wooden village notice board with pinned paper notice and red seal
--------------------------------------------------------------------------------
local board_base = {
  "____bbbbbbbb____",
  "___wwwwwwwwww___",
  "__dddddddddddd__",
  "___bbbbbbbbbb___",
  "___bwwwwwwwwb___",
  "___bwwwwwwwwb___",
  "___bwwwwwwwwb___",
  "___bwwwwwwwwb___",
  "___bwwwwwwwwb___",
  "___bwwwwwwwwb___",
  "___bbbbbbbbbb___",
  "____dd____dd____",
  "____ww____ww____",
  "____dd____dd____",
  "___pddp__pddp___",
  "__kGGk____kGGk__",
}

local board_detail = {
  "____llllllll____",
  "___llllllllll___",
  "________________",
  "________________",
  "____kssssss_____",
  "____skkskksk____",
  "____ssssssss____",
  "____skkskkrk____",
  "____sssssstk____",
  "____ssssssdd____",
  "____llllllll____",
  "____ll____ll____",
  "____ll____ll____",
  "____ll____ll____",
  "___PPP____PPP___",
  "________________",
}

local function drawBoardBase(img)
  drawMatrix(img, 0, 0, board_base)
end

local function drawBoardDetail(img)
  drawMatrix(img, 0, 0, board_detail)
end

--------------------------------------------------------------------------------
-- 3. village_stall (64x48)
-- Welcoming open-front Vietnamese seed stall with red tiled roof & seed boxes
--------------------------------------------------------------------------------
local function drawStallBase(img)
  -- Terracotta roof ridge & slope
  fillRect(img, 16, 4, 32, 3, PAL.t)
  fillRect(img, 14, 5, 36, 2, PAL.r)
  for y = 7, 18 do
    local spread = y - 6
    local x1 = math.max(3, 16 - spread)
    local x2 = math.min(60, 47 + spread)
    fillRect(img, x1, y, x2 - x1 + 1, 1, PAL.r)
  end

  -- Eave overhang beam & shadow
  fillRect(img, 7, 19, 50, 2, PAL.d)

  -- Timber pillars (left x=9..12, right x=51..54)
  fillRect(img, 9, 19, 4, 26, PAL.b)
  fillRect(img, 51, 19, 4, 26, PAL.b)

  -- Back interior wall & shelf
  fillRect(img, 13, 20, 38, 11, PAL.d)
  fillRect(img, 14, 25, 36, 2, PAL.b)

  -- Front counter structure
  fillRect(img, 10, 31, 44, 3, PAL.w)
  fillRect(img, 11, 34, 42, 9, PAL.b)
  fillRect(img, 10, 43, 44, 2, PAL.d)

  -- 4 seed boxes on counter
  local box_x = { 14, 23, 33, 42 }
  local box_col = { PAL.s, PAL.r, PAL.p, PAL.k }
  for b = 1, 4 do
    local bx = box_x[b]
    fillRect(img, bx, 28, 8, 5, PAL.d)
    fillRect(img, bx + 1, 29, 6, 4, box_col[b])
  end

  -- Ground accessories (left seedling tray, right seed jar)
  fillRect(img, 4, 41, 7, 5, PAL.w)
  fillRect(img, 5, 42, 5, 3, PAL.G)
  fillRect(img, 54, 39, 4, 2, PAL.d)
  fillRect(img, 53, 41, 6, 5, PAL.t)

  -- Foundation step & bottom center anchor ground line
  fillRect(img, 6, 45, 52, 2, PAL.d)
  fillRect(img, 8, 46, 48, 2, PAL.b)
  fillRect(img, 10, 47, 44, 1, PAL.k)
end

local function drawStallDetail(img)
  -- Roof ridge ornamentation & tile flute lines
  fillRect(img, 17, 4, 30, 1, PAL.o)
  pset(img, 15, 3, PAL.o)
  pset(img, 14, 4, PAL.o)
  pset(img, 48, 3, PAL.o)
  pset(img, 49, 4, PAL.o)

  for y = 7, 18 do
    local spread = y - 6
    local x1 = math.max(3, 16 - spread)
    local x2 = math.min(60, 47 + spread)
    for x = x1, x2 do
      local mod = (x - 16) % 4
      if mod == 0 then
        pset(img, x, y, PAL.o)
      elseif mod == 2 then
        pset(img, x, y, PAL.t)
      end
    end
  end

  -- Eaves tile caps
  for x = 4, 59, 2 do
    pset(img, x, 18, PAL.o)
    pset(img, x + 1, 18, PAL.t)
  end

  -- Hanging wooden seed signboard under overhang
  fillRect(img, 24, 20, 16, 5, PAL.d)
  fillRect(img, 25, 21, 14, 3, PAL.s)
  for _, cx in ipairs({ 27, 29, 31, 33, 35, 37 }) do
    pset(img, cx, 22, PAL.k)
  end
  pset(img, 26, 19, PAL.l)
  pset(img, 37, 19, PAL.l)

  -- Left hanging corn bundle
  for cy = 20, 25 do
    pset(img, 14, cy, (cy % 2 == 0) and PAL.o or PAL.s)
    pset(img, 13, cy, PAL.l)
  end

  -- Right hanging herb bundle
  for hy = 20, 25 do
    pset(img, 49, hy, (hy % 2 == 0) and PAL.p or PAL.f)
    pset(img, 50, hy, PAL.G)
  end

  -- Ceramic seed jars on rear wall shelf
  fillRect(img, 18, 22, 3, 3, PAL.f)
  pset(img, 19, 21, PAL.l)
  fillRect(img, 43, 22, 3, 3, PAL.r)
  pset(img, 44, 21, PAL.l)

  -- Pillars & counter edge highlights and plank seams
  for py = 19, 43 do
    pset(img, 9, py, PAL.w)
    pset(img, 51, py, PAL.w)
  end
  fillRect(img, 10, 31, 44, 1, PAL.l)
  for _, px in ipairs({ 16, 22, 28, 34, 40, 46 }) do
    for cy = 34, 42 do
      pset(img, px, cy, PAL.k)
    end
  end

  -- Seed box textures & sprout shoot
  for _, pt in ipairs({ {15,29,PAL.s}, {17,29,PAL.l}, {19,29,PAL.s}, {16,30,PAL.s}, {18,30,PAL.l} }) do
    pset(img, pt[1], pt[2], pt[3])
  end
  for _, pt in ipairs({ {24,29,PAL.o}, {26,29,PAL.t}, {28,29,PAL.o}, {25,30,PAL.o}, {27,30,PAL.t} }) do
    pset(img, pt[1], pt[2], pt[3])
  end
  for _, pt in ipairs({ {34,29,PAL.P}, {36,29,PAL.p}, {38,29,PAL.P}, {35,30,PAL.P}, {37,30,PAL.p} }) do
    pset(img, pt[1], pt[2], pt[3])
  end
  pset(img, 36, 27, PAL.P)
  pset(img, 35, 28, PAL.P)
  pset(img, 37, 28, PAL.P)
  for _, pt in ipairs({ {43,29,PAL.s}, {45,29,PAL.s}, {47,29,PAL.s}, {44,30,PAL.s}, {46,30,PAL.s} }) do
    pset(img, pt[1], pt[2], pt[3])
  end
  for _, bx in ipairs({ 14, 23, 33, 42 }) do
    fillRect(img, bx, 28, 8, 1, PAL.l)
  end

  -- Left sprout tray shoots
  for _, sp in ipairs({ {5,40}, {6,39}, {7,40}, {8,39}, {9,40} }) do
    pset(img, sp[1], sp[2], PAL.P)
  end

  -- Right terracotta jar highlights & twine tie
  pset(img, 54, 40, PAL.l)
  pset(img, 54, 42, PAL.o)
  pset(img, 55, 42, PAL.o)
  pset(img, 57, 43, PAL.k)
  fillRect(img, 53, 41, 6, 1, PAL.s)

  -- Stone foundation highlights & side grass tufts
  fillRect(img, 12, 45, 40, 1, PAL.l)
  for _, gp in ipairs({ {5,45,PAL.G}, {5,44,PAL.P}, {6,45,PAL.P}, {58,45,PAL.G}, {58,44,PAL.P}, {59,45,PAL.P} }) do
    pset(img, gp[1], gp[2], gp[3])
  end
end

--------------------------------------------------------------------------------
-- Run batch generation
--------------------------------------------------------------------------------
saveSprite("village_people", 32, 24, drawPeopleBase, drawPeopleDetail)
saveSprite("village_board", 16, 16, drawBoardBase, drawBoardDetail)
saveSprite("village_stall", 64, 48, drawStallBase, drawStallDetail)
