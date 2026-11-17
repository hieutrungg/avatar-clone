-- =======================================================================
-- Vuon Nho - Pixel Art Generation Script for Aseprite
-- Hand-crafted 32px pixel art for Vietnamese Farming Game
-- =======================================================================

local rgba = app.pixelColor.rgba

-- -----------------------------------------------------------------------
-- Palette Definitions (Warm Earthy Palette & RPG Tones)
-- -----------------------------------------------------------------------
local C = {
  -- Utility / transparent
  ['.'] = nil,

  -- Earth / Soil
  ['K'] = rgba(34, 20, 14, 255),    -- Deep outline / dark soil
  ['D'] = rgba(72, 44, 28, 255),    -- Moist loam
  ['M'] = rgba(116, 74, 44, 255),   -- Mid brown dirt
  ['L'] = rgba(162, 112, 70, 255),  -- Highlight loam
  ['H'] = rgba(198, 152, 108, 255), -- Dry earth crumbs
  ['S'] = rgba(52, 34, 20, 255),    -- Sown seed grain

  -- Water Spinach (Rau Muong) - Crisp greens & hollow straight stems
  ['w1'] = rgba(18, 44, 22, 255),   -- Dark shade / outline
  ['w2'] = rgba(36, 84, 42, 255),   -- Deep leaf green
  ['w3'] = rgba(66, 140, 60, 255),  -- Mid leaf green
  ['w4'] = rgba(116, 186, 78, 255), -- Bright spear leaf
  ['w5'] = rgba(166, 220, 112, 255),-- Tender upright stem

  -- Malabar Spinach (Mong Toi) - Vine magenta/purple & heart leaves
  ['m0'] = rgba(24, 20, 28, 255),   -- Deep outline
  ['m1'] = rgba(88, 30, 56, 255),   -- Vine shadow purple
  ['m2'] = rgba(146, 44, 84, 255),  -- Reddish-purple vine
  ['m3'] = rgba(22, 62, 40, 255),   -- Deep emerald leaf
  ['m4'] = rgba(44, 114, 66, 255),  -- Mid succulent leaf
  ['m5'] = rgba(88, 166, 90, 255),  -- Juicy leaf highlight
  ['mB'] = rgba(42, 16, 36, 255),   -- Dark purple berry
  ['mH'] = rgba(182, 74, 124, 255), -- Berry gleam

  -- Paper Seed Bags
  ['pk'] = rgba(58, 42, 30, 255),   -- Seed bag outline
  ['p1'] = rgba(172, 134, 94, 255),  -- Kraft shadow
  ['p2'] = rgba(212, 178, 134, 255), -- Kraft paper base
  ['p3'] = rgba(238, 214, 176, 255), -- Kraft highlight
  ['pL'] = rgba(250, 246, 234, 255), -- Cream paper label
  ['pT'] = rgba(126, 92, 60, 255),  -- Sealing stitch line

  -- Cat (Hoang Thuong) - Cream & Ginger Tabby
  ['cK'] = rgba(42, 26, 18, 255),   -- Outline
  ['c1'] = rgba(176, 82, 28, 255),  -- Dark ginger shadow
  ['c2'] = rgba(222, 118, 44, 255), -- Mid warm ginger
  ['c3'] = rgba(244, 164, 78, 255), -- Light ginger highlight
  ['c4'] = rgba(212, 192, 168, 255),-- Cream shaded belly/paws
  ['c5'] = rgba(252, 244, 230, 255),-- Light cream fur
  ['cP'] = rgba(240, 136, 148, 255),-- Pink ear/nose
  ['cE'] = rgba(46, 138, 68, 255),  -- Green eyes
  ['cW'] = rgba(255, 255, 255, 230),-- White muzzle / whiskers

  -- Caterpillar (Sau Rau)
  ['sK'] = rgba(18, 38, 14, 255),   -- Dark outline
  ['s1'] = rgba(72, 126, 24, 255),  -- Shadow yellow-green
  ['s2'] = rgba(138, 200, 32, 255), -- Vibrant yellow-green
  ['s3'] = rgba(198, 236, 72, 255), -- Lime highlight
  ['sE'] = rgba(12, 22, 8, 255),    -- Eye spot
  ['sW'] = rgba(255, 255, 255, 255),-- Eye highlight

  -- Neighbor Characters (Chi Lan & Bo Duc)
  ['oK'] = rgba(30, 20, 24, 255),   -- RPG character dark outline
  ['sk1'] = rgba(190, 128, 94, 255),-- Skin shadow
  ['sk2'] = rgba(230, 168, 130, 255),-- Skin tone
  ['sk3'] = rgba(248, 202, 172, 255),-- Skin highlight
  ['hr1'] = rgba(28, 22, 26, 255),  -- Black hair shadow
  ['hr2'] = rgba(58, 46, 54, 255),  -- Black hair highlight
  -- Chi Lan: Soft plum ao ba ba & dark brown silk pants
  ['pl1'] = rgba(86, 40, 64, 255),  -- Plum shadow
  ['pl2'] = rgba(136, 66, 100, 255), -- Plum cloth
  ['pl3'] = rgba(176, 100, 138, 255),-- Plum highlight
  ['pt1'] = rgba(46, 32, 28, 255),  -- Silk pants dark
  ['pt2'] = rgba(74, 52, 46, 255),  -- Silk pants brown
  ['wd']  = rgba(158, 108, 68, 255),-- Wooden clogs
  -- Bo Duc: Non la, indigo farmer shirt, rolled trousers
  ['nl1'] = rgba(138, 102, 52, 255),-- Non la rim/shadow
  ['nl2'] = rgba(214, 180, 114, 255),-- Non la straw
  ['nl3'] = rgba(242, 220, 156, 255),-- Non la highlight
  ['in1'] = rgba(30, 42, 64, 255),  -- Indigo shadow
  ['in2'] = rgba(52, 74, 110, 255), -- Indigo shirt
  ['in3'] = rgba(82, 114, 160, 255),-- Indigo highlight
  ['tr1'] = rgba(54, 40, 28, 255),  -- Rolled trousers shadow
  ['tr2'] = rgba(88, 66, 48, 255),  -- Rolled trousers brown
  ['kr']  = rgba(188, 196, 204, 255),-- Khan ran neck scarf
}

-- -----------------------------------------------------------------------
-- Helper Functions
-- -----------------------------------------------------------------------
local function draw_art(img, ox, oy, pal, rows)
  for y, row in ipairs(rows) do
    local r = oy + y - 1
    if r >= 0 and r < img.height then
      local len = #row
      for x = 1, len do
        local c = ox + x - 1
        if c >= 0 and c < img.width then
          local ch = row:sub(x, x)
          local col = pal[ch]
          if col then
            img:drawPixel(c, r, col)
          end
        end
      end
    end
  end
end

local function draw_art_multichar(img, ox, oy, pal, rows)
  for y, row in ipairs(rows) do
    local r = oy + y - 1
    if r >= 0 and r < img.height then
      local x = 0
      local idx = 1
      local len = #row
      while idx <= len do
        local ch = row:sub(idx, idx)
        local key = ch
        local token3 = row:sub(idx, idx + 2)
        local token2 = row:sub(idx, idx + 1)
        if pal[token3] then
          key = token3
        elseif pal[token2] then
          key = token2
        end
        local col = pal[key]
        local c = ox + x
        if col and c >= 0 and c < img.width then
          img:drawPixel(c, r, col)
        end
        x = x + 1
        idx = idx + #key
      end
    end
  end
end

-- Common Soil Bed (width 26, height 9)
local SOIL_MOUND = {
  "........KKKKKKKKKKKK........",
  ".....KKKMMMMMMLLMMMMKKK.....",
  "...KKMMMLLLLHLLLLMMMMMKKK...",
  "..KMMMMLLHHHLLLLMMMMMMMDDK..",
  ".KMMMMMLLLLLLMMMMMMMDDDDDKK.",
  ".KMMMMMMMMMMMMMMMDDDDDDDDDK.",
  ".KDDMMMMMMMMMDDDDDDDDDDDDDK.",
  "..KKDDDDDDDDDDDDDDDDDDDDKK..",
  "....KKKKKKKKKKKKKKKKKKKK...."
}

-- -----------------------------------------------------------------------
-- 1 & 2. CROPS: Rau Muong & Mong Toi (96x32 each)
-- -----------------------------------------------------------------------
local function create_rau_muong()
  local spr = Sprite(96, 32, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Tile 0: Sown seed in furrowed soil bed
  draw_art(img, 2, 22, C, SOIL_MOUND)
  local seeds = {
    "....K...K.....K...K....",
    "...KSK.KSK...KSK.KSK...",
    "....K...K.....K...K...."
  }
  draw_art(img, 4, 23, C, seeds)

  -- Tile 1: Tender sprout (pale upright stem, slender spear cotyledons)
  draw_art(img, 34, 22, C, SOIL_MOUND)
  local sprout = {
    "..w1w4....w4w1..",
    ".w1w4w3..w3w4w1.",
    ".w1w4w4w1w4w4w1.",
    "..w1w3w5w5w3w1..",
    "....w1w5w5w1....",
    "....w1w5w5w1....",
    "....w1w5w5w1....",
    ".....w1w5w1.....",
    ".....w1w5w1....."
  }
  draw_art_multichar(img, 42, 14, C, sprout)

  -- Tile 2: Mature Water Spinach (arrowhead leaves, hollow straight stems)
  draw_art(img, 66, 22, C, SOIL_MOUND)
  local mature_muong = {
    "........w1w4............w4w1........",
    ".......w1w4w3w1........w1w3w4w1.....",
    "......w1w4w4w3w1..w1w4.w1w3w4w4w1...",
    "......w1w3w4w4w1.w1w4w1w1w4w4w3w1...",
    ".......w1w3w4w1.w1w4w3w1w1w4w3w1....",
    "..w1w4..w1w4w1..w1w4w4w1.w1w4w1..w4w1",
    ".w1w4w3w1w1w5w1..w1w3w5w1w1w5w1w1w3w4w1",
    "w1w4w4w3w1w5w5w1w1w5w5w1w1w5w5w1w3w4w4w1",
    ".w1w3w4w1.w1w5w5w1w5w5w1w5w5w1.w1w4w3w1",
    "..w1w1w1...w1w5w5w5w5w5w5w5w1...w1w1w1.",
    "............w1w5w5w5w5w5w5w1............",
    ".............w1w5w5w5w5w5w1.............",
    ".............w1w5w5w5w5w5w1.............",
    "............w1w5w5w5w5w5w5w1............",
    "............w1w5w5w1.w1w5w5w1..........."
  }
  draw_art_multichar(img, 64, 8, C, mature_muong)

  return spr
end

local function create_mong_toi()
  local spr = Sprite(96, 32, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Tile 0: Sown seed / moist compost bed with round Malabar berry seeds
  draw_art(img, 2, 22, C, SOIL_MOUND)
  local seeds_mt = {
    "....m0m0....m0m0....m0m0....",
    "...m0mBm0..m0mBm0..m0mBm0...",
    "....m0m0....m0m0....m0m0...."
  }
  draw_art_multichar(img, 4, 23, C, seeds_mt)

  -- Tile 1: Tender sprout (reddish-purple stem, rounded thick heart leaves)
  draw_art(img, 34, 22, C, SOIL_MOUND)
  local sprout_mt = {
    "...m0m4m4m0....m0m4m4m0...",
    "..m0m5m5m4m0..m0m4m5m5m0..",
    "..m0m5m5m4m0..m0m4m5m5m0..",
    "...m0m4m4m1m2m2m1m4m4m0...",
    "....m0m1m2m2m2m2m1m0.....",
    "......m0m1m2m2m1m0.......",
    ".......m0m1m2m1m0........",
    ".......m0m1m2m1m0........"
  }
  draw_art_multichar(img, 41, 15, C, sprout_mt)

  -- Tile 2: Mature Malabar Spinach (heart leaves, twining red vine, berries)
  draw_art(img, 66, 22, C, SOIL_MOUND)
  local mature_mong_toi = {
    "..............m0m2m2m0..............",
    "..........m0m4m0m2m1m0m4m0..........",
    "........m0m5m5m4m0m0m4m5m5m0........",
    ".......m0m5m5m5m4m0m4m5m5m5m0.......",
    ".......m0m4m5m4m3m0m3m4m5m4m0.......",
    "........m0m3m4m3m0..m0m3m4m3m0......",
    ".........m0m0m0m2m1m2m0m0m0m0.......",
    "....m0m4m4m0...m0m1m2m0...m0m4m4m0..",
    "..m0m5m5m5m4m0m0mBm2m1m0m0m4m5m5m5m0",
    "..m0m5m5m5m4m0m0mHmBm0.m0m4m5m5m5m0",
    "..m0m4m5m4m3m0..m0m1m2m0..m0m3m4m5m4m0",
    "...m0m3m4m3m0...m0m2m1m0...m0m3m4m3m0.",
    "....m0m0m0m0...m0m1m2m0m0...m0m0m0m0..",
    "..............m0m2m1m0mBm0............",
    ".............m0m1m2m0m0m0.............",
    "............m0m1m2m1m0................"
  }
  draw_art_multichar(img, 67, 7, C, mature_mong_toi)

  return spr
end

-- -----------------------------------------------------------------------
-- 3. SEED PACKETS: greens_seeds.png (64x32)
-- -----------------------------------------------------------------------
local function create_greens_seeds()
  local spr = Sprite(64, 32, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Base Kraft Paper Envelope Template (18 wide, 24 high)
  local bag_base = {
    "....pkpkpkpkpkpkpkpkpkpk....",
    "...pkp3p3p3p3p3p3p3p3p3pk...",
    "..pkpTpTpTpTpTpTpTpTpTpTpk..",
    "..pkp3p3p3p3p3p3p3p3p3p3pk..",
    ".pkp3p3p2p2p2p2p2p2p2p2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2pLpLpLpLpLpLpLp2p1pk.",
    ".pkp3p2p2p2p2p2p2p2p2p2p1pk.",
    ".pkp3p2p2p2p2p2p2p2p2p2p1pk.",
    ".pkp3p2p2p2p2p2p2p2p2p2p1pk.",
    ".pkp3p2p2p2p2p2p2p2p2p2p1pk.",
    ".pkp3p2p2p2p2p2p2p2p2p2p1pk.",
    ".pkp1p1p1p1p1p1p1p1p1p1p1pk.",
    "..pkpkpkpkpkpkpkpkpkpkpkpk.."
  }

  -- Draw Bag 1 (Rau Muong) at x=7, y=5
  draw_art_multichar(img, 7, 5, C, bag_base)
  -- Rau Muong Spear Motif on Label
  local rm_motif = {
    "w3w3w3w3w3w3w3",
    "..............",
    "....w1w4w1....",
    "...w1w4w4w1...",
    "...w1w3w4w1...",
    "....w1w5w1....",
    "....w1w5w1...."
  }
  draw_art_multichar(img, 13, 11, C, rm_motif)

  -- Draw Bag 2 (Mong Toi) at x=39, y=5
  draw_art_multichar(img, 39, 5, C, bag_base)
  -- Mong Toi Heart & Vine Motif on Label
  local mt_motif = {
    "m2m2m2m2m2m2m2",
    "..............",
    "..m0m4m0m4m0..",
    "..m0m5m5m5m0..",
    "...m0m4m4m0...",
    "....m0m2m1m0..",
    "....m0m1mBm0.."
  }
  draw_art_multichar(img, 45, 11, C, mt_motif)

  return spr
end

-- -----------------------------------------------------------------------
-- 4. CAT: hoang_thuong.png (64x32)
-- Cream and Ginger Vietnamese Cat seated, 2 tail/ear animation frames
-- -----------------------------------------------------------------------
local function create_hoang_thuong()
  local spr = Sprite(64, 32, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Frame 1: Resting upright, ears erect, tail curled neatly along floor
  local cat_f1 = {
    ".....cKcK.............cKcK......",
    "....cKc2cK...........cKc2cK.....",
    "....cKc2c2cK.......cKc2c2cK.....",
    "....cKc2cPc2cKcKcKc2cPc2cK......",
    ".....cKc2c2c2c2c2c2c2c2cK.......",
    "....cKc2c3c2c2c1c2c2c3c2cK......",
    "...cKc2cEc3cWcWcWc3cEc2cK.......",
    "...cKc2cEcWcWcPcWcWcEc2cK.......",
    "....cKc2cWcWcWcWcWcWc2cK........",
    ".....cKcKc4c5c5c5c4cKcK.........",
    "....cKc2c2c4c5c5c4c2c2cK........",
    "...cKc2c1c2c4c5c4c2c1c2cK.......",
    "...cKc2c2c2c4c5c4c2c2c2cK.......",
    "..cKc2c1c2c4c5c5c4c2c1c2cK......",
    "..cKc2c2c4c4c5c5c4c4c2c2cK......",
    "..cKcKc5c5cKc5c5cKc5c5cKcK......",
    ".cKc2c2c5c5cKc5c5cKc2c2c2cK.....",
    ".cKc2c1c2cKcKcKcKcKc2c1c2cK.....",
    "..cKc2c2c2c2c2c2c2c2c2c2cK......",
    "...cKcKcKcKcKcKcKcKcKcKcK......."
  }
  draw_art_multichar(img, 0, 11, C, cat_f1)

  -- Frame 2: Ear twitched, tail flicked up excitedly
  local cat_f2 = {
    "......................cKcK......",
    "....cKcKcK...........cKc2cK.....",
    "...cKc2c2c2cK......cKc2c2cK.....",
    "....cKc2cPc2cKcKcKc2cPc2cK......",
    ".....cKc2c2c2c2c2c2c2c2cK.......",
    "....cKc2c3c2c2c1c2c2c3c2cK......",
    "...cKc2cEc3cWcWcWc3cEc2cK.......",
    "...cKc2cEcWcWcPcWcWcEc2cK.......",
    "....cKc2cWcWcWcWcWcWc2cK........",
    ".....cKcKc4c5c5c5c4cKcK...cKcK..",
    "....cKc2c2c4c5c5c4c2c2cK.cKc2cK.",
    "...cKc2c1c2c4c5c4c2c1c2KcKc2c1cK",
    "...cKc2c2c2c4c5c4c2c2c2c2c2c2cK.",
    "..cKc2c1c2c4c5c5c4c2c1c2c2c1cK..",
    "..cKc2c2c4c4c5c5c4c4c2c2c2cK....",
    "..cKcKc5c5cKc5c5cKc5c5cKcK......",
    ".cKc2c2c5c5cKc5c5cKc2c2c2cK.....",
    ".cKc2c1c2cKcKcKcKcKc2c1c2cK.....",
    "..cKc2c2c2c2c2c2c2c2c2c2cK......",
    "...cKcKcKcKcKcKcKcKcKcKcK......."
  }
  draw_art_multichar(img, 32, 11, C, cat_f2)

  return spr
end

-- -----------------------------------------------------------------------
-- 5. CATERPILLAR: sau_rau.png (64x32)
-- Tiny readable green caterpillar frames at bottom-right of each 32x32 tile
-- -----------------------------------------------------------------------
local function create_sau_rau()
  local spr = Sprite(64, 32, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Tile 0: Crawling stretched out (placed at bottom right: x=18, y=24)
  local catp_crawl = {
    "..............sKsK..",
    "....sKsK.sKsKsKsWsE.",
    "..sKs3sKs3s2s2s2sKsK",
    ".sKs3s2s2s2s3s2s2s1sK",
    ".sKs2s1s1s2s1s1s1sKsK",
    "..sKsK.sKsKsK.sKsK.."
  }
  draw_art_multichar(img, 18, 24, C, catp_crawl)

  -- Tile 1: Inchworm arched loop (placed at bottom right: x=50, y=22)
  local catp_loop = {
    ".....sKsK...........",
    "...sKs3s3sKsK.sKsK..",
    "..sKs3s2s2s3sKsKsWsE",
    "..sKs2s1s1s2s2s2sKsK",
    ".sKs2s1sK.sKs1s1sKsK",
    ".sKs1sKsK..sKsKsK..."
  }
  draw_art_multichar(img, 50, 22, C, catp_loop)

  return spr
end

-- -----------------------------------------------------------------------
-- 6. NEIGHBORS: nguoi_hang_xom.png (64x48)
-- 32x48 frames: Left Chi Lan (plum/brown), Right Bo Duc (indigo/non la)
-- -----------------------------------------------------------------------
local function create_nguoi_hang_xom()
  local spr = Sprite(64, 48, ColorMode.RGB)
  local img = spr.cels[1].image

  -- Left: Chi Lan (Young adult neighbor, gentle RPG silhouette)
  local chi_lan = {
    "...........oKoKoK...............",
    ".........oKhr1hr1oK.............",
    "........oKhr1hr2hr1oK...........",
    ".......oKhr1hr1hr1hr1oK.........",
    ".......oKhr1sk2sk2hr1oK.........",
    ".......oKsk2sk3sk2sk2oK.........",
    ".......oKsk2oKoKsk2sk2oK........",
    "........oKsk2sk2sk2sk2oK........",
    ".........oKsk2sk1sk2oK..........",
    "..........oKsk2sk2oK............",
    "........oKoKpl2pl2oKoK..........",
    "......oKpl1pl2pl3pl2pl1oK.......",
    ".....oKpl1pl2pl3pl3pl2pl1oK.....",
    ".....oKpl1pl2pl3pl3pl2pl1oK.....",
    ".....oKpl1pl2pl2pl2pl2pl1oK.....",
    ".....oKsk1pl1pl2pl2pl1sk1oK.....",
    ".....oKsk2pl1pl2pl2pl1sk2oK.....",
    "......oKoKpl1pl2pl2pl1oKoK......",
    "........oKpl1pl2pl2pl1oK........",
    "........oKpt1pt1pt1pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1pt2pt2pt1oK........",
    "........oKpt1oK.oKpt1oK.........",
    "........oKwdwdoK.oKwdwdoK......."
  }
  draw_art_multichar(img, 4, 19, C, chi_lan)

  -- Right: Bo Duc (Older farmer in Non La & Indigo shirt)
  local bo_duc = {
    "...............oKoK.............",
    ".............oKnl3oK............",
    "............oKnl3nl2oK..........",
    "...........oKnl3nl2nl2oK........",
    "..........oKnl3nl2nl2nl2oK......",
    ".........oKnl3nl2nl2nl2nl1oK....",
    ".......oKoKnl2nl2nl2nl2nl1oKoK..",
    "......oKnl1nl1nl1nl1nl1nl1nl1oK.",
    ".........oKhr1hr1hr1hr1oK.......",
    "........oKsk2sk2sk2sk2sk2oK.....",
    "........oKsk2oKoKsk2oKoKsk2oK...",
    "........oKsk2sk2sk1sk2sk2oK.....",
    "........oKhr1hr1hr1hr1hr1oK.....",
    ".........oKsk2sk1sk1sk2oK.......",
    "..........oKoKkroKoKoK..........",
    "........oKoKin2in2in2oKoK.......",
    "......oKin1in2in3in3in2in1oK....",
    ".....oKin1in2in3in3in3in2in1oK..",
    ".....oKin1in2in3in3in3in2in1oK..",
    ".....oKin1in2in2in2in2in2in1oK..",
    ".....oKsk1in1in2in2in2in1sk1oK..",
    ".....oKsk2in1in2in2in2in1sk2oK..",
    "......oKoKin1in2in2in2in1oKoK...",
    "........oKin1in2in2in2in1oK.....",
    "........oKtr1tr1tr1tr1tr1oK.....",
    "........oKtr1tr2tr2tr2tr1oK.....",
    "........oKtr1tr2tr2tr2tr1oK.....",
    "........oKtr1tr2tr2tr2tr1oK.....",
    "........oKtr1tr2oKoKtr2tr1oK....",
    "........oKsk1sk2oKoKsk2sk1oK....",
    "........oKsk1sk2oKoKsk2sk1oK...."
  }
  draw_art_multichar(img, 35, 16, C, bo_duc)

  return spr
end

-- -----------------------------------------------------------------------
-- Export and Execution Flow
-- -----------------------------------------------------------------------
local function ensure_directory(path)
  if app.fs and app.fs.isDirectory and not app.fs.isDirectory(path) then
    if app.fs.makeDirectory then
      app.fs.makeDirectory(path)
    end
  end
end

local function export_asset(spr, name, out_dir, source_dir)
  local png_path = app.fs.joinPath(out_dir, name .. ".png")
  local ase_path = app.fs.joinPath(source_dir, name .. ".aseprite")

  spr:saveCopyAs(png_path)
  spr:saveCopyAs(ase_path)
  spr:close()
end

local function main()
  local params = app.params or {}
  local out_dir = params["out_dir"] or params.out_dir or "."
  local source_dir = params["source_dir"] or params.source_dir or out_dir

  ensure_directory(out_dir)
  ensure_directory(source_dir)

  -- Generate and Export each asset
  export_asset(create_rau_muong(), "rau_muong", out_dir, source_dir)
  export_asset(create_mong_toi(), "mong_toi", out_dir, source_dir)
  export_asset(create_greens_seeds(), "greens_seeds", out_dir, source_dir)
  export_asset(create_hoang_thuong(), "hoang_thuong", out_dir, source_dir)
  export_asset(create_sau_rau(), "sau_rau", out_dir, source_dir)
  export_asset(create_nguoi_hang_xom(), "nguoi_hang_xom", out_dir, source_dir)
end

main()
