class_name LateSummer
extends RefCounted

const RECOVERY := 51
const LOTUS_DAY := 52
const BASKET_DAY := 53
const HARVEST := 54
const FIRST_FAIR := 55
const FERRY_WAKE := 270
const FARE := 50
const LOT_SIZE := 10
const SLOTS := 10
const MELON_TARGET := 30
const CORN_TARGET := 50
const HERBS := "herbal_compost"
const STEM := "bamboo_pole"
const RATTAN := "wild_rattan"
const POD := "lotus_pod"
const LEAF := "lotus_leaf"
const TEA := "lotus_tea_jar"
const PREMIUM := "_premium"
const GOODS := ["winter_melon_produce", "corn_produce", "yardlong_bean_produce",
	"winter_melon_produce_premium", "corn_produce_premium", "yardlong_bean_produce_premium"]
const FIELD := GardenProgress.PLOT_CELLS + SummerProgress.HEIRLOOM_DRY + AutumnWork.WEST

var water := 0
var herbs_day := 0
var fertilized_count := 0
var lotus_invited := false
var lotus_done := false
var lotus_mask := 0
var lotus_day := 0
var bamboo_hits := 0
var rattan_mask := 0
var basket_score := -1
var basket_wear := 0
var stubble := 0
var hat := false
var hat_remainder := 0
var melon_sold := 0
var corn_sold := 0
var cargo: Dictionary[String, int] = {}


static func fair_day(day: int) -> bool:
	return day >= FIRST_FAIR and (day - FIRST_FAIR) % 7 == 0


static func crop_goods(crop: String) -> String:
	return CropCatalog.CROPS[crop].produce_item


static func item_name(item: String) -> String:
	match item:
		HERBS: return "Phân bón thảo mộc"
		STEM: return "Tre ống"
		RATTAN: return "Dây mây dại"
		POD: return "Đài sen chín"
		LEAF: return "Lá sen bản to"
		TEA: return "Hũ trà sen mộc"
	var index := GOODS.find(item)
	if index < 3:
		return ""
	return "%s thượng hạng" % ["Bí đao", "Ngô", "Đậu đũa"][index - 3]


static func fair_price(day: int, item: String) -> int:
	var index := GOODS.find(item)
	if index < 0:
		return 0
	var base: int = [25, 20, 17][index % 3]
	var week := GardenCalendar.week_number(day)
	var change: int = [-10, 0, 10, 20][(week * 3 + index % 3 * 5) % 4]
	return roundi(base * (100 + change) / 100.0 * (1.25 if index >= 3 else 1.0))


func seeds_unlocked() -> bool:
	return melon_sold >= MELON_TARGET and corn_sold >= CORN_TARGET


func slots_used() -> int:
	var count := 0
	for amount in cargo.values():
		count += amount
	return count


func has_stubble(cell: Vector2i) -> bool:
	var index := FIELD.find(cell)
	return index >= 0 and stubble & (1 << index) != 0


func to_data() -> Dictionary:
	return {
		"water": water, "herbs_day": herbs_day, "fertilized_count": fertilized_count,
		"lotus_invited": lotus_invited, "lotus_done": lotus_done, "lotus_mask": lotus_mask, "lotus_day": lotus_day,
		"bamboo_hits": bamboo_hits, "rattan_mask": rattan_mask, "basket_score": basket_score, "basket_wear": basket_wear,
		"stubble": stubble, "hat": hat, "hat_remainder": hat_remainder,
		"melon_sold": melon_sold, "corn_sold": corn_sold, "cargo": cargo.duplicate(),
	}


static func from_data(data: Variant, day: int) -> LateSummer:
	if not data is Dictionary:
		return null
	var state := LateSummer.new()
	var limits := {
		"water": [0, 6], "herbs_day": [0, day], "fertilized_count": [0, 3],
		"lotus_mask": [0, 32767], "lotus_day": [0, day], "bamboo_hits": [0, 63],
		"rattan_mask": [0, 7], "basket_wear": [0, 8], "stubble": [0, 16383], "hat_remainder": [0, 9],
		"melon_sold": [0, MELON_TARGET], "corn_sold": [0, CORN_TARGET],
	}
	for key in limits:
		var bounds: Array = limits[key]
		var count := GardenProgress.read_integer(data.get(key), bounds[0], bounds[1])
		if count < bounds[0]:
			return null
		state.set(key, count)
	state.basket_score = GardenProgress.read_integer(data.get("basket_score"), 0, 6)
	if state.basket_score == -1 and data.get("basket_score") != -1:
		return null
	for key in ["lotus_invited", "lotus_done", "hat"]:
		if not data.get(key) is bool:
			return null
		state.set(key, data[key])
	var saved_cargo: Variant = data.get("cargo")
	if not saved_cargo is Dictionary:
		return null
	for item in saved_cargo:
		var count := GardenProgress.read_integer(saved_cargo[item], 1, SLOTS)
		if item not in GOODS or count < 1:
			return null
		state.cargo[item] = count
	if state.slots_used() > SLOTS or state.basket_wear > state.basket_score + 2 or (not state.hat and state.hat_remainder != 0) or (
		state.basket_score < 0 and (not state.cargo.is_empty() or state.basket_wear != 0)
	) or (
		state.lotus_done and not state.lotus_invited
	):
		return null
	return state
