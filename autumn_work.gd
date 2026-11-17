class_name AutumnWork
extends RefCounted

const INVEST_DAY := 62
const SOIL_DAY := 63
const REST_DAY := 64
const CRAFT_DAY := 65
const AUTUMN_DAY := 66
const CARE_DAY := 67
const WORKROOM_DAY := 68
const WORKROOM_SHELF := 69
const WORKROOM_FINISH := 70
const RAIN_START := 75
const RAIN_NIGHTS := 7
const LESSON_HOUR := 450
const RUSH_CLOSE := 660
const FAVOR_DAY := 75
const WEST := [Vector2i(2, 4), Vector2i(2, 7), Vector2i(4, 7), Vector2i(6, 5), Vector2i(6, 7), Vector2i(4, 9)]
const LEDGER := Vector2i(9, 4)
const WAREHOUSE := Vector2i(7, 4)
const BUYER := Vector2i(14, 7)
const INVESTMENTS := ["Mở sáu luống phía tây", "Xây kho cấp 2", "Mua gói hạt vụ thu"]
const COSTS := [1200, 1500, 800]
const STORAGE_SLOTS := 20
const EXTRA_SLOTS := 8
const CORNER_ITEMS := ["scrap_wood", "iron_nail", "bamboo_pole"]
const CORNER_COUNTS := [6, 2, 4]
const CORNER_TASKS := ["Lắp bàn đan", "Đóng giá thành phẩm", "Bố trí chỗ chờ cho mẻ tiếp theo"]
const FINE := "fine_bamboo_strip"
const WEAVES := ["Nong phơi lúa", "Giỏ xách hoa văn", "Rổ tre xuất khẩu"]
const WEAVE_COST := [8, 6, 10]
const RANKS := ["Thường", "Đẹp", "Tinh Xảo"]
const WOVEN := ["fine_tray_0", "fine_tray_1", "fine_tray_2", "woven_bag_0", "woven_bag_1", "woven_bag_2", "fine_export_0", "fine_export_1", "fine_export_2"]
const WOVEN_VALUE := [150, 245, 350, 225, 350, 500, 280, 440, 600]
const EMBROIDERED := ["crane_embroidery", "lotus_embroidery"]
const MOTIFS := ["Chim hạc", "Hoa sen"]
const REPEAT_IDS := ["large_bamboo_basket", "rice_drying_tray", "export_bamboo_basket"]
const REPEAT_AMOUNTS := [12, 8, 6]
const REPEAT_PAY := [1200, 1440, 1500]

var pending := 0
var built := 0
var storage: Dictionary[String, int] = {}
var damage_applied := false
var damp_baskets := 0
var first_payout := 0
var reputation := 0
var favored := false
var repeat_day := 0
var repeat_due := 0
var repeat_count := 0
var second_streak := 0
var training_bonus := false
var weave2 := false
var embroidery2 := false
var first_bag := 0
var hai_points := 0
var old_story := false
var starter_seeds := false
var sown := 0
var corner_step := 0


static func woven_id(product: int, rank: int) -> String:
	return WOVEN[product * 3 + rank]


static func item_name(item: String) -> String:
	if item == FINE:
		return "Nan Tinh"
	var index := WOVEN.find(item)
	if index >= 0:
		return "%s · %s" % [WEAVES[floori(index / 3.0)], RANKS[index % 3]]
	index = EMBROIDERED.find(item)
	return "Tranh thêu %s" % MOTIFS[index].to_lower() if index >= 0 else ""


static func sale_price(item: String) -> int:
	var index := WOVEN.find(item)
	if index >= 0:
		return WOVEN_VALUE[index]
	index = EMBROIDERED.find(item)
	return [380, 320][index] if index >= 0 else 0


static func can_store(item: String) -> bool:
	if item in [LateSummer.STEM, LateSummer.RATTAN, FINE] or item in BambooWorks.PRODUCTS or item in WOVEN or item in EMBROIDERED:
		return true
	for crop in CropCatalog.CROPS.values():
		if item in [crop.seed_item, crop.produce_item]:
			return true
	return false


func repeat_kind() -> int:
	return repeat_count % REPEAT_IDS.size()


func set_next_order(day: int) -> void:
	repeat_day = WORKROOM_FINISH if day == BambooWorks.FIRST_DUE and repeat_count == 0 else (
		mini(GardenProgress.MAX_SAVE_INTEGER, day + 7 + (day + repeat_count) % 4)
	)
	repeat_due = 0


func corner_ready() -> bool:
	return corner_step == CORNER_TASKS.size()


func storage_slots() -> int:
	return STORAGE_SLOTS + (EXTRA_SLOTS if corner_ready() else 0)


func to_data() -> Dictionary:
	return {
		"pending": pending, "built": built, "storage": storage.duplicate(), "damage_applied": damage_applied,
		"damp_baskets": damp_baskets, "first_payout": first_payout, "reputation": reputation, "favored": favored,
		"repeat_day": repeat_day, "repeat_due": repeat_due, "repeat_count": repeat_count,
		"second_streak": second_streak, "training_bonus": training_bonus, "weave2": weave2, "embroidery2": embroidery2,
		"first_bag": first_bag, "hai_points": hai_points, "old_story": old_story,
		"starter_seeds": starter_seeds, "sown": sown, "corner_step": corner_step,
	}


static func from_data(data: Variant, day: int, version: int) -> AutumnWork:
	if not data is Dictionary:
		return null
	var state := AutumnWork.new()
	var limits := {
		"pending": 7, "built": 7, "damp_baskets": GardenProgress.MAX_SAVE_INTEGER, "first_payout": BambooWorks.ORDER_PAY,
		"repeat_day": mini(GardenProgress.MAX_SAVE_INTEGER, day + 10), "repeat_due": mini(GardenProgress.MAX_SAVE_INTEGER, day + 3),
		"repeat_count": day, "second_streak": 7, "first_bag": 3, "hai_points": 20,
	}
	for key in limits:
		var number := GardenProgress.read_integer(data.get(key), 0, limits[key])
		if number < 0:
			return null
		state.set(key, number)
	if state.first_payout not in [0, BambooWorks.DAMAGED_PAY, BambooWorks.ORDER_PAY]:
		return null
	var rep := GardenProgress.read_integer(data.get("reputation"), -5, 0)
	if rep not in [-5, 0]:
		return null
	state.reputation = rep
	for key in ["damage_applied", "favored", "training_bonus", "weave2", "embroidery2", "old_story"]:
		if not data.get(key) is bool:
			return null
		state.set(key, data[key])
	if version >= 22:
		state.sown = GardenProgress.read_integer(data.get("sown"), 0, 7)
		state.corner_step = GardenProgress.read_integer(data.get("corner_step"), 0, CORNER_TASKS.size())
		if state.sown < 0 or state.corner_step < 0 or not data.get("starter_seeds") is bool:
			return null
		state.starter_seeds = data.starter_seeds
		if (day < AUTUMN_DAY and (state.starter_seeds or state.sown != 0)) or (state.corner_step > 0 and (
			day < WORKROOM_DAY + state.corner_step - 1 or (state.built & 2) == 0
		)):
			return null
	elif state.repeat_day == 69 and state.repeat_due == 0 and state.repeat_count == 0 and day < WORKROOM_FINISH:
		state.repeat_day = WORKROOM_FINISH
	var saved: Variant = data.get("storage")
	if not saved is Dictionary or saved.size() > state.storage_slots() or (not saved.is_empty() and (state.built & 2) == 0):
		return null
	for item in saved:
		var count := GardenProgress.read_integer(saved[item], 1, GardenProgress.MAX_SAVE_INTEGER)
		if not item is String or not can_store(item) or count < 1:
			return null
		state.storage[item] = count
	if (state.built & state.pending) != 0 or (state.first_bag > 0 and not state.weave2) or (state.old_story and state.first_bag == 0):
		return null
	return state
