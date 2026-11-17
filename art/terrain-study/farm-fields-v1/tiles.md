# Bản Thử Tileset Vườn Nhỏ - Farm Fields Study v1 (32 × 32 px)

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
