class_name VillageMap
extends RefCounted

const RIVER_START := 16
const DOCK_ROW := 8
const FISHING_SPOT := Vector2i(18, DOCK_ROW)
const EXIT_CELL := Vector2i(0, 6)
const SHOP_SIGN := Vector2i(3, 4)
const LAN_CELL := Vector2i(3, 5)
const ORDER_BOARD := Vector2i(9, 5)
const MARKET_STALL := Rect2i(12, 4, 3, 2)
const MARKET_CELL := Vector2i(13, 5)
const STALL := Rect2i(3, 1, 4, 3)
const COTTAGES := [Rect2i(11, 1, 2, 2), Rect2i(2, 8, 2, 2)]
const TREES := [Rect2i(8, 1, 2, 2), Rect2i(4, 8, 2, 2), Rect2i(12, 9, 2, 2)]
const BUILDING_FOOTPRINTS := COTTAGES + TREES
const TILE_SIZE := PixelArt.CELL


static func is_blocked(cell: Vector2i) -> bool:
	if cell in [SHOP_SIGN, ORDER_BOARD, FISHING_SPOT] or STALL.has_point(cell) or MARKET_STALL.has_point(cell):
		return true
	for footprint in BUILDING_FOOTPRINTS:
		if footprint.has_point(cell):
			return true
	return cell.x >= RIVER_START and cell.y != DOCK_ROW


static func npc_position(index: int, minute: int) -> Vector2i:
	if index == 0:
		return Vector2i(5, 4) if GardenCalendar.shop_is_open(minute) else Vector2i(8, 3)
	if minute < 12 * 60:
		return Vector2i(14, DOCK_ROW)
	return Vector2i(11, 5) if minute < GardenCalendar.SHOP_CLOSE else Vector2i(12, 3)


static func npc_dialogue(index: int, progress: GardenProgress) -> String:
	if index == 0:
		if GardenCalendar.shop_is_open(progress.minute_of_day):
			if progress.arrival != null:
				if progress.tutorial_completed and progress.day >= ArrivalProgress.BOARD_DAY:
					return "Cô đã nhập hạt cải cho đơn bếp làng và chợ phiên. Cháu xem hạt ở quầy nhé."
				return "Cô có hạt rau muống và mồng tơi. Nếu chưa nhận hạt đầu vụ, cháu tìm cạnh thùng bán ở vườn."
			if progress.seed_is_unlocked(CropCatalog.RADISH):
				return "Cô có hạt củ cải trắng rồi. Cháu ghé biển trước quầy để mua nhé."
			return "Ghé biển trước quầy nếu cháu cần mua hạt. Cải mau lớn, còn cà rốt cần tưới đủ ba đêm."
		return "Cô dọn quầy rồi. Sáng mai, đúng 06:00, cô mở bán lại."
	if progress.arrival != null and progress.day < ArrivalProgress.FISHING_DAY:
		return "Đây là bến sông Cầu. Từ ngày 6, cháu có thể ra đây câu cá."
	if progress.arrival != null and not progress.arrival.caught_fish:
		return "Cần câu ở cuối bến. Nhấn E để thả, rồi nhấn E khi thấy cá cắn câu."
	if progress.market_open() and progress.market_delivery_day == 0:
		return "Chợ đang mở đến 16:00. Quầy mái xanh ven sông nhận ba cây cải cho đơn chợ."
	if progress.can_deliver_fish_order():
		return "Có cá trê rồi à? Cháu giao hai con ở mục Đơn cá trên bảng nhé."
	if progress.order_state == VillageOrder.State.DELIVERED:
		return "Bác nhận đủ cải rồi. Cháu ghé bảng đơn để lĩnh 20 xu nhé."
	if progress.order_state == VillageOrder.State.REWARDED:
		return "Cảm ơn cháu. Bữa nay bếp làng có một nồi canh cải ngon."
	if progress.order_state == VillageOrder.State.ACCEPTED:
		return "Bác để sẵn một giỏ cạnh bảng đơn. Cháu mang ba cây cải tới đó là được."
	if progress.minute_of_day < 12 * 60:
		return "Bác đang lấy nước cho bếp làng. Nếu rảnh, cháu xem đơn cải trên bảng gần quảng trường nhé."
	return "Bếp làng đang thiếu cải. Bác đã ghi số lượng lên bảng đơn rồi."


static func paint_ground(ground: TileMapLayer, size: Vector2i) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = preload("res://assets/art/32/village_terrain.png")
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for column in range(8):
		atlas.create_tile(Vector2i(column, 0))
	ground.tile_set.add_source(atlas, 1)

	for y in range(size.y):
		for x in range(size.x):
			var is_dock := y == DOCK_ROW and x >= RIVER_START - 1
			var road := y == 6 or (x >= 3 and x <= 6 and y >= 4 and y <= 5)
			road = road or MARKET_STALL.has_point(Vector2i(x, y))
			road = road or (x >= 8 and x <= 12 and y >= 4 and y <= 7)
			road = road or (y == DOCK_ROW and x >= 10 and x < RIVER_START)
			var tile := ((x * 23 + y * 41 + x * y * 7) % 19) % 3
			if is_dock:
				tile = 7
			elif x >= RIVER_START:
				tile = 4 + (x + y * 3) % 2
			elif x == RIVER_START - 1:
				tile = 6
			elif road:
				tile = 3
			ground.set_cell(Vector2i(x, y), 1, Vector2i(tile, 0))
