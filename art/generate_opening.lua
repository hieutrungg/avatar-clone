-- Vườn Nhỏ - Cinematic Opening Pixel Art Generator for Aseprite
local sourceDir = (app.params and app.params.source_dir) or "."
local outDir = (app.params and app.params.out_dir) or "."

local function joinPath(dir, filename)
  local last = string.sub(dir, -1)
  if last == "/" or last == "\\" then return dir .. filename end
  return dir .. (string.find(dir, "\\") and "\\" or "/") .. filename
end

local asePath = joinPath(sourceDir, "opening.aseprite")
local pngPath = joinPath(outDir, "opening.png")

local function C(r, g, b) return Color(r, g, b, 255) end

local function hline(img, x0, x1, y, col)
  if y < 0 or y >= img.height then return end
  local xa = math.max(0, math.floor(math.min(x0, x1)))
  local xb = math.min(img.width - 1, math.floor(math.max(x0, x1)))
  for px = xa, xb do img:drawPixel(px, y, col) end
end

local function rect(img, x, y, w, h, col)
  local y0 = math.max(0, math.floor(y))
  local y1 = math.min(img.height - 1, math.floor(y + h - 1))
  for py = y0, y1 do hline(img, x, x + w - 1, py, col) end
end

local function trap(img, y0, y1, x0a, x0b, x1a, x1b, col)
  y0, y1 = math.floor(y0), math.floor(y1)
  local dy = y1 - y0
  if dy <= 0 then hline(img, x0a, x0b, y0, col); return end
  for y = y0, y1 do
    local t = (y - y0) / dy
    local xl = math.floor(x0a + (x1a - x0a) * t + 0.5)
    local xr = math.floor(x0b + (x1b - x0b) * t + 0.5)
    hline(img, xl, xr, y, col)
  end
end

local function circle(img, cx, cy, r, col)
  cx, cy, r = math.floor(cx), math.floor(cy), math.floor(r)
  for y = -r, r do
    local py = cy + y
    if py >= 0 and py < img.height then
      local w = math.floor(math.sqrt(math.max(0, r * r - y * y)))
      hline(img, cx - w, cx + w, py, col)
    end
  end
end

-- Scene 1: Hanoi IT office late at night, silhouette of Hoàng at monitor
local function drawScene1(img, f)
  -- Background night sky & skyline
  rect(img, 0, 0, 256, 32, C(10, 12, 22))
  rect(img, 0, 32, 256, 32, C(16, 20, 34))
  rect(img, 0, 64, 256, 22, C(24, 28, 46))
  hline(img, 10, 246, 85, C(185, 125, 50)) -- distant highway amber glow
  -- Towers
  rect(img, 46, 24, 30, 62, C(16, 20, 34))
  rect(img, 53, 16, 16, 8, C(16, 20, 34))
  rect(img, 60, 8, 2, 8, C(36, 44, 62))
  if f % 2 == 0 then img:drawPixel(60, 7, C(235, 48, 48)) end -- antenna beacon
  rect(img, 102, 34, 34, 52, C(20, 25, 40))
  trap(img, 26, 34, 119, 119, 102, 135, C(20, 25, 40))
  rect(img, 16, 46, 26, 40, C(18, 22, 36))
  rect(img, 82, 52, 16, 34, C(24, 30, 46))
  rect(img, 140, 44, 26, 42, C(18, 23, 38))
  rect(img, 170, 56, 30, 30, C(22, 27, 44))
  local wins = { {50,30}, {62,38}, {54,52}, {108,44}, {122,56}, {114,68}, {24,58}, {146,50}, {178,64} }
  for idx, pt in ipairs(wins) do
    local col = ((idx + f) % 3 == 0) and C(245, 195, 85) or C(155, 105, 45)
    rect(img, pt[1], pt[2], 2, 2, col)
  end
  -- Office window frame & pillars
  rect(img, 0, 0, 256, 14, C(14, 16, 24))
  rect(img, 32, 4, 192, 3, C(28, 34, 48))
  rect(img, 36, 0, 10, 86, C(20, 24, 34))
  rect(img, 198, 0, 10, 86, C(20, 24, 34))
  rect(img, 0, 84, 256, 5, C(26, 32, 44))
  -- Desk
  rect(img, 0, 88, 256, 40, C(22, 26, 36))
  hline(img, 0, 255, 88, C(44, 52, 70))
  -- Ultrawide monitor
  rect(img, 68, 46, 78, 42, C(16, 18, 24))
  rect(img, 70, 48, 74, 38, C(28, 52, 72))
  rect(img, 103, 88, 8, 4, C(20, 22, 30))
  rect(img, 97, 92, 20, 2, C(32, 36, 48))
  local codeCols = { C(140, 210, 240), C(130, 215, 140), C(240, 160, 80), C(190, 140, 230) }
  for r = 0, 5 do
    local cw = 14 + ((r * 17 + f * 5) % 36)
    rect(img, 74, 52 + r * 5, cw, 2, codeCols[(r % 4) + 1])
  end
  rect(img, 72, 74, 70, 10, C(16, 32, 46))
  rect(img, 74, 76, 30, 2, C(100, 220, 130))
  if f % 2 == 0 then rect(img, 106, 76, 3, 4, C(245, 250, 255)) end -- cursor blink
  rect(img, 66, 90, 82, 16, C(32, 44, 58)) -- desk glow
  rect(img, 82, 98, 42, 10, C(30, 35, 48)) -- keyboard
  rect(img, 132, 102, 6, 8, C(34, 40, 54)) -- mouse
  -- Coffee mug & rising steam
  rect(img, 56, 94, 7, 9, C(215, 210, 200))
  rect(img, 54, 96, 2, 5, C(180, 175, 165))
  local sY = 91 - f
  img:drawPixel(59 + (f % 2), sY, C(140, 160, 180))
  img:drawPixel(60 - (f % 2), sY - 2, C(110, 130, 150))
  -- Hoàng at desk
  local yOff = (f == 1 or f == 2) and 1 or 0
  circle(img, 164, 86 + yOff, 15, C(18, 22, 30)) -- chair
  rect(img, 152, 98 + yOff, 24, 26, C(22, 26, 36))
  circle(img, 164, 62 + yOff, 11, C(16, 18, 24)) -- black hair
  rect(img, 154, 60 + yOff, 2, 8, C(78, 110, 138)) -- screen rim light
  rect(img, 156, 68 + yOff, 6, 6, C(180, 120, 85)) -- skin
  trap(img, 74 + yOff, 106 + yOff, 158, 170, 144, 186, C(50, 75, 102)) -- blue jacket
  trap(img, 80 + yOff, 106 + yOff, 168, 170, 174, 186, C(32, 48, 68))
  trap(img, 74 + yOff, 96 + yOff, 158, 161, 144, 148, C(78, 110, 138))
  trap(img, 84 + yOff, 98 + yOff, 144, 152, 120, 130, C(45, 68, 92))
end

-- Scene 2: Last day leaving office in rain, Hoàng carrying cardboard box
local function drawScene2(img, f)
  rect(img, 0, 0, 256, 40, C(22, 26, 36))
  rect(img, 0, 40, 256, 48, C(28, 34, 46))
  -- Warm glowing corporate lobby
  rect(img, 18, 12, 104, 76, C(36, 44, 58))
  rect(img, 24, 18, 92, 70, C(225, 170, 80))
  rect(img, 30, 24, 80, 64, C(245, 195, 110))
  rect(img, 46, 24, 8, 64, C(90, 65, 35))
  rect(img, 82, 24, 8, 64, C(90, 65, 35))
  rect(img, 58, 60, 24, 14, C(120, 85, 45))
  rect(img, 68, 18, 4, 70, C(45, 55, 70))
  rect(img, 0, 0, 140, 12, C(18, 22, 30))
  hline(img, 0, 140, 12, C(55, 68, 88))
  -- Street & distant traffic
  rect(img, 145, 62, 111, 26, C(25, 30, 42))
  rect(img, 170, 72, 8, 4, C(235, 50, 45))
  rect(img, 210, 70, 12, 5, C(250, 245, 210))
  -- Wet sidewalk & amber reflections
  rect(img, 0, 88, 256, 40, C(30, 36, 48))
  hline(img, 0, 255, 88, C(50, 60, 78))
  trap(img, 89, 127, 24, 116, 10, 150, C(115, 85, 45))
  trap(img, 95, 127, 40, 100, 30, 130, C(155, 115, 55))
  rect(img, 170, 92, 50, 14, C(42, 55, 72))
  for px = 0, 256, 36 do hline(img, px, px + 18, 108, C(24, 28, 38)) end

  -- Hoàng walking carrying box
  local hx, hy = 105, 36
  local bob = (f == 1 or f == 3) and 1 or 0
  local legL = (f == 0 and -8) or (f == 1 and -2) or (f == 2 and 6) or 0
  local legR = (f == 0 and 7) or (f == 1 and 2) or (f == 2 and -7) or -1

  circle(img, hx + 12, hy + 10 - bob, 8, C(16, 18, 24)) -- black hair
  rect(img, hx + 14, hy + 8 - bob, 5, 8, C(215, 155, 115)) -- skin
  rect(img, hx + 16, hy + 11 - bob, 2, 2, C(170, 110, 75))
  rect(img, hx + 4, hy + 18 - bob, 18, 26, C(50, 75, 102)) -- blue jacket
  rect(img, hx + 4, hy + 18 - bob, 5, 26, C(32, 48, 68))
  rect(img, hx + 18, hy + 18 - bob, 4, 18, C(78, 110, 138))
  rect(img, hx + 12, hy + 26 - bob, 14, 6, C(45, 68, 92))
  rect(img, hx + 24, hy + 30 - bob, 4, 4, C(215, 155, 115))

  -- Cardboard box & desk plant
  local bx, by = hx + 18, hy + 20 - bob
  rect(img, bx, by, 22, 16, C(180, 122, 68))
  rect(img, bx, by, 22, 3, C(215, 160, 100))
  rect(img, bx + 9, by, 4, 16, C(195, 175, 140))
  hline(img, bx, bx + 21, by + 15, C(138, 86, 42))
  rect(img, bx + 2, by - 6, 6, 6, C(60, 150, 70))
  rect(img, bx + 3, by - 2, 4, 3, C(190, 95, 50))

  -- Legs & shoes
  trap(img, hy + 44 - bob, hy + 76, hx + 7, hx + 13, hx + 9 + legL, hx + 15 + legL, C(26, 30, 40))
  rect(img, hx + 9 + legL, hy + 76, 8, 4, C(18, 18, 22))
  trap(img, hy + 44 - bob, hy + 76, hx + 13, hx + 19, hx + 13 + legR, hx + 19 + legR, C(20, 24, 34))
  rect(img, hx + 13 + legR, hy + 76, 8, 4, C(18, 18, 22))

  -- Rain streaks & puddle splashes
  local rCol = C(145, 170, 195)
  for i = 0, 46 do
    local rx = (i * 19 + f * 7) % 256
    local ry = (i * 23 + f * 17) % 120
    for l = 0, 4 do img:drawPixel(rx + l, ry + l * 2, rCol) end
  end
  local sx = hx + 12 + ((f % 2 == 0) and legL or legR)
  circle(img, sx + 4, hy + 79, (f % 2) + 2, C(170, 195, 220))
end

-- Scene 3: Rural road to Bắc Ninh, cream/red bus, rice fields and tiled roofs
local function drawScene3(img, f)
  rect(img, 0, 0, 256, 25, C(180, 208, 205))
  rect(img, 0, 25, 256, 20, C(205, 225, 218))
  circle(img, 45, 16, 12, C(225, 240, 235))
  circle(img, 60, 14, 15, C(225, 240, 235))
  circle(img, 180, 18, 14, C(225, 240, 235))
  circle(img, 198, 15, 18, C(225, 240, 235))
  trap(img, 36, 48, 0, 256, 0, 256, C(135, 165, 155))
  rect(img, 0, 46, 256, 12, C(38, 76, 54))
  for bx = 10, 240, 32 do
    circle(img, bx + 8, 45, 8, C(48, 92, 64))
    trap(img, 46, 52, bx + 14, bx + 14, bx + 10, bx + 18, C(188, 70, 42))
  end
  -- Flooded jade rice paddies
  rect(img, 0, 56, 256, 30, C(80, 135, 115))
  for y = 58, 84, 6 do
    local shimmer = ((y + f * 3) % 4 == 0) and C(110, 168, 145) or C(70, 120, 102)
    hline(img, 0, 255, y, shimmer)
  end
  trap(img, 68, 86, 0, 4, 30, 36, C(115, 95, 70))
  trap(img, 62, 86, 170, 174, 140, 146, C(115, 95, 70))
  local shoots = { {20,62}, {50,70}, {85,64}, {115,74}, {190,66}, {225,72}, {145,60} }
  for _, pt in ipairs(shoots) do
    local sx = (pt[1] + (4 - f) * 2) % 256
    rect(img, sx, pt[2], 2, 4, C(85, 175, 75))
    rect(img, sx - 1, pt[2] + 1, 4, 2, C(95, 190, 85))
  end
  circle(img, 242, 60, 16, C(45, 110, 50))
  circle(img, 230, 68, 12, C(55, 130, 60))

  -- Highway road & markers
  rect(img, 0, 86, 256, 42, C(75, 80, 88))
  hline(img, 0, 255, 86, C(60, 100, 55))
  hline(img, 0, 255, 88, C(95, 100, 108))
  for _, mx in ipairs({ 24, 134, 238 }) do
    local px = (mx - f * 3) % 256
    rect(img, px, 82, 4, 8, C(230, 230, 230))
    rect(img, px, 82, 4, 2, C(215, 45, 45))
  end

  -- The Cream & Red Bus
  local bump = (f == 1 or f == 3) and 1 or 0
  local bx, by, bw, bh = 62, 68 - bump, 126, 44
  rect(img, bx + 4, by + bh - 2, bw - 8, 6, C(45, 48, 54)) -- shadow
  -- Red lower body
  rect(img, bx + 6, by + 20, bw - 10, 18, C(195, 38, 38))
  rect(img, bx, by + 22, 6, 14, C(170, 30, 30))
  hline(img, bx + 2, bx + bw - 6, by + 20, C(230, 65, 65))
  hline(img, bx + 6, bx + bw - 6, by + 37, C(125, 20, 20))
  -- Cream upper body
  rect(img, bx + 6, by + 4, bw - 12, 16, C(242, 235, 215))
  trap(img, by + 4, by + 20, bx + 12, bx + bw - 6, bx + 4, bx + bw - 6, C(242, 235, 215))
  hline(img, bx + 14, bx + bw - 10, by + 3, C(250, 245, 230))
  -- Windows
  rect(img, bx + 6, by + 8, bw - 14, 11, C(38, 52, 65))
  trap(img, by + 8, by + 19, bx + 12, bx + 22, bx + 6, bx + 22, C(48, 68, 85))
  for wx = bx + 24, bx + bw - 18, 16 do
    rect(img, wx, by + 8, 3, 11, C(235, 228, 208))
    rect(img, wx + 3, by + 8, 3, 7, C(220, 175, 75))
  end
  circle(img, bx + 48, by + 13, 3, C(18, 20, 26)) -- passenger
  rect(img, bx, by + 32, 4, 4, C(255, 250, 200)) -- headlight
  rect(img, bx - 2, by + 36, 6, 3, C(205, 210, 218)) -- bumper

  -- Wheels & spoke rotation
  local wheels = { bx + 26, bx + bw - 24 }
  for _, wx in ipairs(wheels) do
    circle(img, wx, by + 38, 8, C(45, 48, 54))
    circle(img, wx, by + 38, 7, C(24, 26, 32))
    circle(img, wx, by + 38, 4, C(225, 218, 195))
    local ang = f * (math.pi / 2)
    local sx = math.floor(math.cos(ang) * 2.5 + 0.5)
    local sy = math.floor(math.sin(ang) * 2.5 + 0.5)
    img:drawPixel(wx + sx, by + 38 + sy, C(160, 40, 40))
    img:drawPixel(wx - sx, by + 38 - sy, C(160, 40, 40))
  end
end

-- Scene 4: Homecoming at old brick-and-warm-plaster North Vietnamese farmhouse
local function drawScene4(img, f)
  rect(img, 0, 0, 256, 25, C(220, 205, 185))
  rect(img, 0, 25, 256, 25, C(245, 222, 170))
  rect(img, 0, 50, 256, 34, C(122, 144, 91))
  -- Areca palm (cây cau)
  local sway = (f == 1 or f == 2) and 1 or 0
  for ty = 14, 76 do
    local tx = 210 + math.floor(math.sin(ty * 0.05) * 3)
    img:drawPixel(tx, ty, C(130, 115, 95))
    if ty % 6 == 0 then img:drawPixel(tx + 1, ty, C(160, 145, 125)) end
  end
  circle(img, 210 + sway, 14, 12, C(55, 120, 50))
  circle(img, 202 + sway, 12, 9, C(70, 140, 60))
  circle(img, 220 + sway, 12, 9, C(70, 140, 60))
  circle(img, 175, 46, 14, C(45, 95, 45))
  circle(img, 192, 52, 12, C(55, 110, 52))

  -- Farmhouse & clay tile roof
  rect(img, 82, 48, 140, 38, C(228, 202, 162)) -- lime plaster
  for _, bp in ipairs({ {105, 54, 12, 8}, {158, 62, 16, 10}, {200, 52, 10, 6} }) do
    rect(img, bp[1], bp[2], bp[3], bp[4], C(165, 72, 48))
    hline(img, bp[1], bp[1] + bp[3] - 1, bp[2] + math.floor(bp[4]/2), C(130, 52, 34))
  end
  rect(img, 98, 48, 5, 38, C(72, 44, 26))
  rect(img, 140, 48, 5, 38, C(72, 44, 26))
  rect(img, 182, 48, 5, 38, C(72, 44, 26))
  rect(img, 108, 54, 24, 32, C(38, 26, 20))
  rect(img, 110, 56, 8, 30, C(90, 55, 32))
  trap(img, 24, 50, 128, 186, 74, 232, C(196, 75, 48)) -- terracotta roof
  rect(img, 120, 22, 72, 4, C(145, 45, 28))
  for ry = 28, 48, 4 do
    hline(img, 128 - (ry - 24) * 2, 186 + (ry - 24) * 2, ry, C(145, 45, 28))
    hline(img, 128 - (ry - 24) * 2, 186 + (ry - 24) * 2, ry + 1, C(228, 105, 72))
  end
  hline(img, 72, 234, 50, C(110, 35, 20))
  circle(img, 192, 76, 7, C(115, 62, 36)) -- water urn
  rect(img, 188, 68, 8, 3, C(145, 82, 48))

  -- Bát Tràng brick courtyard
  rect(img, 0, 84, 256, 44, C(175, 78, 55))
  for y = 88, 124, 6 do
    hline(img, 0, 255, y, C(138, 56, 38))
    local xShift = (y % 12 == 0) and 0 or 8
    for x = xShift, 255, 16 do rect(img, x, y, 1, 6, C(138, 56, 38)) end
  end
  for mx = 80, 220, 14 do rect(img, mx, 84, 8, 3, C(88, 118, 58)) end

  -- Weathered Blue Gate
  rect(img, 14, 46, 14, 52, C(165, 140, 115))
  trap(img, 40, 46, 21, 21, 12, 30, C(190, 165, 135))
  rect(img, 68, 50, 12, 48, C(165, 140, 115))
  trap(img, 44, 50, 74, 74, 66, 82, C(190, 165, 135))
  rect(img, 28, 58, 12, 40, C(58, 120, 138))
  rect(img, 28, 58, 3, 40, C(40, 85, 100))
  rect(img, 33, 64, 4, 12, C(95, 165, 182))
  local gateAng = f * 2
  trap(img, 60, 96, 68, 68, 54 + gateAng, 58 + gateAng, C(58, 120, 138))
  trap(img, 60, 96, 68, 68, 58 + gateAng, 62 + gateAng, C(40, 85, 100))

  -- Hoàng arriving with box
  local hx = 100 + f * 3
  local hy = 52
  local bob = (f == 1 or f == 3) and 1 or 0
  local legL = (f == 0 and -4) or (f == 1 and 0) or (f == 2 and 4) or 1
  local legR = (f == 0 and 4) or (f == 1 and 0) or (f == 2 and -4) or -1

  circle(img, hx + 10, hy + 8 - bob, 7, C(16, 18, 24)) -- black hair
  rect(img, hx + 12, hy + 6 - bob, 5, 7, C(215, 155, 115)) -- skin
  rect(img, hx + 4, hy + 16 - bob, 16, 22, C(50, 75, 102)) -- blue jacket
  rect(img, hx + 4, hy + 16 - bob, 4, 22, C(32, 48, 68))
  rect(img, hx + 16, hy + 16 - bob, 4, 16, C(78, 110, 138))
  local bx, by = hx + 14, hy + 18 - bob
  rect(img, bx, by, 18, 14, C(180, 122, 68))
  rect(img, bx, by, 18, 3, C(215, 160, 100))
  rect(img, bx + 7, by, 3, 14, C(195, 175, 140))
  rect(img, bx + 2, by - 4, 5, 4, C(60, 150, 70))
  trap(img, hy + 38 - bob, hy + 64, hx + 6, hx + 12, hx + 7 + legL, hx + 13 + legL, C(26, 30, 40))
  rect(img, hx + 7 + legL, hy + 64, 7, 3, C(18, 18, 22))
  trap(img, hy + 38 - bob, hy + 64, hx + 12, hx + 17, hx + 12 + legR, hx + 17 + legR, C(20, 24, 34))
  rect(img, hx + 12 + legR, hy + 64, 7, 3, C(18, 18, 22))

  -- Hopping courtyard sparrow
  local spX = 170 - f * 4
  local spY = 96 + ((f % 2 == 1) and -3 or 0)
  circle(img, spX, spY, 2, C(120, 75, 45))
  img:drawPixel(spX + 2, spY - 1, C(220, 180, 90))
end

-- Export 16 frames to opening.aseprite and 1024x512 atlas to opening.png
local spr = Sprite(256, 128, ColorMode.RGB)
local layer = spr.layers[1]
if #layer.cels > 0 then spr:deleteCel(layer.cels[1]) end
while #spr.frames < 16 do spr:newEmptyFrame() end

local atlasImg = Image(1024, 512, ColorMode.RGB)
local sceneDrawers = { drawScene1, drawScene2, drawScene3, drawScene4 }

local frameIdx = 1
for s = 0, 3 do
  local drawer = sceneDrawers[s + 1]
  for f = 0, 3 do
    local img = Image(256, 128, ColorMode.RGB)
    drawer(img, f)

    local frameObj = spr.frames[frameIdx]
    frameObj.duration = 0.22
    spr:newCel(layer, frameObj, img, Point(0, 0))

    atlasImg:drawImage(img, Point(f * 256, s * 128))
    frameIdx = frameIdx + 1
  end
end

spr:saveCopyAs(asePath)
spr:close()

local atlasSpr = Sprite(1024, 512, ColorMode.RGB)
local atlasLayer = atlasSpr.layers[1]
if #atlasLayer.cels > 0 then atlasSpr:deleteCel(atlasLayer.cels[1]) end
atlasSpr:newCel(atlasLayer, atlasSpr.frames[1], atlasImg, Point(0, 0))
atlasSpr:saveCopyAs(pngPath)
atlasSpr:close()
