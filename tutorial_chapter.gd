class_name TutorialChapter
extends RefCounted

const LAST_DAY := 10
const PLOT_COUNT := 40
const VISITOR_NAMES := {
	1: "Trưởng thôn", 2: "Cô Lan", 4: "Bác Lý", 6: "Bác thợ mộc",
	7: "Chị Thảo", 8: "Trưởng thôn", 10: "Trưởng thôn",
}
const VISITOR_START := {6: 8 * 60, 7: 8 * 60, 8: 8 * 60}
const TITLES := [
	"Về tới quê", "Mảnh vườn của ông", "Sâu, cỏ và lứa cải đầu tiên", "Bác Lý và ruộng nước",
	"Bóng nước và chú mèo đói", "Khói bếp đầu tiên", "Tiếng loa bán rong", "Tiếng mưa và Cậu Vàng",
	"Nắng ấm và mùa gặt", "Bảo vệ thùng giao hàng",
]
const GOALS := [
	["Gặp Trưởng thôn ở sân gạch", "Dùng liềm phát đủ 10 bụi cỏ sân", "Dùng chìa khóa vào nhà", "Giải Tháp Cầu Chì Sứ để mở điện", "Đặt lại giường rồi ngủ"],
	["Mở cổng tre ở hàng rào bên phải sân", "Đọc tấm biển của ông trong vườn", "Quay lại sân gạch gặp Cô Lan", "Dọn 10 bụi cỏ trong vườn", "Cuốc, gieo và tưới 5 luống cải ngọt", "Mở rương lương thực trong nhà", "Ăn một phần lương thực", "Về giường nghỉ"],
	["Dùng liềm phá khóa nhà kho", "Kiểm tra kệ đồ trong kho", "Trị sâu, nhổ cỏ, bón NPK rồi thu 5 luống cải", "Dọn 3 khúc gỗ chắn chuồng gà", "Về giường nghỉ"],
	["Ra sân gặp Bác Lý", "Ăn cà mèn cơm nóng trong túi", "Dùng 3 gỗ sửa chuồng gà", "Thả đôi gà vào chuồng", "Cho gà ăn sâu béo ở máng", "Cuốc, tưới hai lượt rồi gieo 10 ô ruộng nước", "Gặp chú mèo ngoài hiên", "Về giường nghỉ"],
	["Lấy vợt ở nhà kho", "Vớt 5 mảng bèo quanh ao", "Câu cá bống ở ao", "Cho mèo ăn cá", "Đeo vòng có chuông cho mèo", "Về giường nghỉ"],
	["Gặp bác thợ mộc ở sân", "Dùng búa đập 5 tảng đá", "Sửa bếp với 5 đá và 3 gỗ", "Nấu canh cá cải ngọt ở bếp", "Ăn bát canh nóng trong túi", "Về giường nghỉ"],
	["Ra cổng gặp Chị Thảo", "Hái rau má, mộc nhĩ và tầm bóp", "Đổi hàng lấy giống ngô và rau dền", "Cuốc, gieo và tưới 25 ô vườn", "Đóng thùng giao hàng bằng 10 gỗ", "Về giường nghỉ"],
	["Đón Cậu Vàng từ Trưởng thôn", "Dùng 2 gỗ dựng mái che cho chó", "Cho Cậu Vàng ăn một quả trứng", "Bắt ốc trên luống và ếch quanh ao", "Sắp xếp đồ ở rương nhà kho", "Về giường nghỉ"],
	["Gặt 10 ô lúa và thu hoạch 25 ô rau, ngô", "Phát rêu và sửa cối đá với 2 gỗ", "Giã thóc thành gạo và cám", "Kiểm kê nông sản trong kho", "Về giường nghỉ"],
	["Nghe Trưởng thôn dặn ở cổng", "Đóng nông sản vào thùng giao hàng", "Bảo vệ thùng trước đàn chuột", "Về giường để kết thúc tutorial"],
]
const ITEMS := {
	"old_key": "Chìa khóa nhà cũ", "sickle": "Liềm cùn", "phu_the": "Bánh phu thê",
	"weed": "Cỏ dại", "hoe": "Cuốc chim", "can": "Bình tưới", "cabbage_seed": "Hạt cải ngọt",
	"noodles": "Mì tôm", "sweet_root": "Khoai lang", "potato": "Khoai tây", "raw_rice": "Gạo nếp tẻ",
	"sprayer": "Bình xịt", "npk": "Phân NPK", "hammer": "Búa tạ", "worm": "Sâu béo",
	"cabbage_produce": "Cải ngọt", "wood": "Gỗ tạp", "hot_lunch": "Cà mèn cơm nóng",
	"chicken_pair": "Lồng gà trống mái", "rice_seed": "Thóc giống", "net": "Vợt lưới",
	"duckweed": "Bèo vụn", "rod": "Cần câu trúc", "goby": "Cá bống", "collar": "Vòng cổ có chuông",
	"stone": "Đá cuội", "cabbage_soup": "Canh cá cải ngọt", "pennywort": "Rau má", "wood_ear": "Mộc nhĩ",
	"ground_cherry": "Tầm bóp", "corn_seed": "Hạt ngô", "amaranth_seed": "Hạt rau dền",
	"trung_ga": "Trứng gà", "snail": "Ốc bươu", "frog": "Ếch đồng", "frog_porridge": "Cháo ếch",
	"snail_dish": "Ốc xào mộc nhĩ", "sour_soup": "Canh chua cá bống", "paddy": "Thóc vàng",
	"white_rice": "Gạo trắng", "rice_bran": "Cám gạo", "early_corn": "Ngô", "amaranth": "Rau dền",
	"rice_meal": "Cơm trắng cá kho tộ", "frog_rice": "Cơm trắng ếch xào sả", "golden_rat_tooth": "Răng Chuột Vàng",
}
const MARKET_PRICES := {
	"cabbage_produce": 10, "goby": 8, "trung_ga": 12, "snail": 4, "frog": 8,
	"white_rice": 15, "rice_bran": 4, "early_corn": 11, "amaranth": 7, "paddy": 6,
}
const CARRY_ITEMS := ["worm", "duckweed", "stone", "golden_rat_tooth", "wood_ear", "ground_cherry", "rice_bran", "raw_rice", "noodles", "phu_the", "sweet_root", "potato"]
const FOOD := {
	"phu_the": 30, "weed": 2, "noodles": 30, "sweet_root": 15, "potato": 5, "raw_rice": 2,
	"hot_lunch": 100, "cabbage_soup": 80, "frog_porridge": 100, "snail_dish": 65,
	"sour_soup": 100, "rice_meal": 100, "frog_rice": 100,
}

enum Soil { BARE, TILLED, DAMP, FLOODED, SOWN, WET, SPROUT, PEST, WEEDS, RIPE, HARVESTED }

var phase := 0
var bag: Dictionary[String, int] = {}
var storage: Dictionary[String, int] = {}
var crate: Dictionary[String, int] = {}
var counts: Dictionary[String, int] = {}
var plots: Array[int] = []
var fuses: Array[int] = [0, 0, 0] # Index 0 is the smallest fuse.
var fuse_moves := 0
var water := 0
var cell := Vector2i(7, 7)
var cat_name := "Hoàng Thượng"


func _init() -> void:
	plots.resize(PLOT_COUNT)
	plots.fill(Soil.BARE)


func goal(day: int) -> String:
	return GOALS[day - 1][phase]


func visitor_present(day: int, minute: int) -> bool:
	if minute < int(VISITOR_START.get(day, 0)):
		return false
	match day:
		1, 7: return phase <= 2
		2: return phase == 2
		4, 6, 8, 10: return phase == 0
	return false


func cat_present(day: int) -> bool:
	return day > 4 or (day == 4 and phase >= 6)


func ready_to_sleep(day: int) -> bool:
	return phase == GOALS[day - 1].size() - 1


func count(key: String) -> int:
	return counts.get(key, 0)


func advance(key: String, amount := 1) -> int:
	counts[key] = count(key) + amount
	return counts[key]


func quantity(item: String) -> int:
	return bag.get(item, 0)


func give(item: String, amount: int) -> void:
	var total := quantity(item) + amount
	if total > 0:
		bag[item] = total
	else:
		bag.erase(item)


func has_cost(cost: Dictionary) -> bool:
	for item: String in cost:
		if quantity(item) < cost[item]:
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not has_cost(cost):
		return false
	for item: String in cost:
		give(item, -cost[item])
	return true


func transfer(item: String, source: Dictionary[String, int], destination: Dictionary[String, int], amount: int) -> void:
	var moving := clampi(amount, 0, source.get(item, 0))
	if moving == 0:
		return
	source[item] -= moving
	if source[item] == 0:
		source.erase(item)
	destination[item] = destination.get(item, 0) + moving


func estimated_value() -> int:
	var total := 0
	for item in crate:
		total += int(MARKET_PRICES.get(item, 0)) * crate[item]
	return total


func top_fuse(peg: int) -> int:
	return fuses.find(peg)


func fuse_solved() -> bool:
	return fuses == [2, 2, 2]


func move_fuse(source: int, target: int) -> bool:
	if source not in [0, 1, 2] or target not in [0, 1, 2] or source == target or fuse_solved():
		return false
	var disk := top_fuse(source)
	var destination := top_fuse(target)
	if disk < 0 or (destination >= 0 and destination < disk):
		return false
	fuses[disk] = target
	fuse_moves += 1
	return true


func to_data() -> Dictionary:
	return {"phase": phase, "bag": bag.duplicate(), "storage": storage.duplicate(), "crate": crate.duplicate(),
		"counts": counts.duplicate(), "plots": plots.duplicate(), "fuses": fuses.duplicate(), "moves": fuse_moves,
		"water": water, "cell": [cell.x, cell.y], "cat": cat_name}


static func from_data(data: Dictionary, day: int) -> TutorialChapter:
	if day < 1 or day > LAST_DAY:
		return null
	var chapter := TutorialChapter.new()
	chapter.phase = _integer(data.get("phase"), GOALS[day - 1].size() - 1)
	chapter.water = _integer(data.get("water"), 10)
	chapter.fuse_moves = _integer(data.get("moves"), 1000000)
	var position: Variant = data.get("cell")
	var cat: Variant = data.get("cat")
	if chapter.phase < 0 or chapter.water < 0 or chapter.fuse_moves < 0 or not position is Array or position.size() != 2:
		return null
	chapter.cell = Vector2i(_integer(position[0], 18), _integer(position[1], 10))
	if chapter.cell.x < 1 or chapter.cell.y < 1 or not cat is String or cat.is_empty() or cat.length() > 24:
		return null
	chapter.cat_name = cat
	if not _read_array(data.get("fuses"), chapter.fuses, 2) or not _read_array(data.get("plots"), chapter.plots, Soil.HARVESTED):
		return null
	if not _read_counts(data.get("counts"), chapter.counts, []) or not _read_counts(data.get("bag"), chapter.bag, ITEMS.keys()):
		return null
	if not _read_counts(data.get("storage"), chapter.storage, ITEMS.keys()) or not _read_counts(data.get("crate"), chapter.crate, MARKET_PRICES.keys()):
		return null
	return chapter


static func _read_array(value: Variant, target: Array[int], maximum: int) -> bool:
	if not value is Array or value.size() != target.size():
		return false
	for index in target.size():
		var number := _integer(value[index], maximum)
		if number < 0:
			return false
		target[index] = number
	return true


static func _read_counts(value: Variant, target: Dictionary[String, int], keys: Array) -> bool:
	if not value is Dictionary or value.size() > 120:
		return false
	for key in value:
		var number := _integer(value[key], 1000000)
		if not key is String or key.length() > 32 or (not keys.is_empty() and key not in keys) or number < 1:
			return false
		target[key] = number
	return true


static func _integer(value: Variant, maximum: int) -> int:
	if not (value is int or value is float) or value < 0 or value > maximum or value != floor(value):
		return -1
	return int(value)
