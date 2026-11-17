class_name SummerProgress
extends RefCounted

const FIRST_DAY := 11
const LETTER_DAY := 12
const MAI_DAY := 13
const CITY_LETTER_DAY := 14
const WEAVE_DAY := 15
const SOLO_DAY := 16
const RAIN_DAY := 17
const FAMILY_DAY := 18
const PUMP_DAY := 19
const BUILD_DAY := 20
const QUIET_DAY := 21
const WOOD := "scrap_wood"
const NAIL := "iron_nail"
const STRAW := "dry_straw"
const PENNYWORT := "pennywort"
const CANE_JUICE := "cane_juice"
const NAIL_PRICE := 2
const COOP_WOOD := 5
const COOP_BAMBOO := 4
const COOP_NAILS := 2
const COOP_STRAW := 7

const IRON_HOE_PRICE := 20
const SICKLE_PRICE := 12
const FERTILIZER_PRICE := 6
const FERTILIZER := "fertilizer"
const RICE_BAG := "family_rice"
const BASKETS := ["basket_rough", "basket_plain", "basket_good", "basket_fine"]
const BASKET_NAMES := ["Rổ thô", "Rổ thường", "Rổ tốt", "Rổ đẹp"]
const BASKET_PRICES := [8, 14, 22, 30]
const BAMBOO := "bamboo"
const ROOT_STOCK := "thuan_thanh_stock"

const HEIRLOOM_DRY := [Vector2i(16, 7), Vector2i(18, 7)]
const HEIRLOOM_PADDY := [Vector2i(16, 9), Vector2i(18, 9)]
const HEIRLOOM_CELLS := HEIRLOOM_DRY + HEIRLOOM_PADDY
const SPRINKLER_CELLS := [Vector2i(10, 6), Vector2i(12, 6), Vector2i(14, 6), Vector2i(16, 8), Vector2i(18, 8)]
const WELL_CELL := Vector2i(9, 9)
const VISIT_WINDOWS := {LETTER_DAY: 9 * 60, MAI_DAY: 12 * 60, CITY_LETTER_DAY: 12 * 60, FAMILY_DAY: 11 * 60 + 30}

var visited_market := false
var cart_loaded := false
var cart_sale := false
var iron_hoe := false
var sharp_sickle := false
var read_letter := false
var received_heirlooms := false
var invited_hai := false
var ate_with_hai := false
var met_mai := false
var read_city_letter := false
var learned_weaving := false
var solo_basket := false
var nest_basket := false
var read_notebook := false
var heard_dad := false
var farm_note := ""
var parents_visited := false
var family_meal := false
var family_replied := false
var mom_points := 0
var inspected_pump := false
var found_pipes := false
var sprinkler := -1
var hatch_day := 0
var chick := false
var expanded_coop := false
var fertilizer_used := false
var neighbor_order := 0
var coop_step := 0
var coop_work := 0
var feeder_days := 0
var nails_found := false
var wood_day := 0
var wood_mask := 0
var straw_day := 0
var tea_day := 0
var herb_day := 0
var broth_day := 0
var juice_until := 0
var rice_turned := 0
var lan_helped := false
var hai_chat := false
var lotus_seen := false
var festival := VillageFestival.new()
var social := VillageSocial.new()
var craft := SummerCraft.new()
var drought := DroughtProgress.new()
var late := LateSummer.new()
var works := BambooWorks.new()
var autumn := AutumnWork.new()


func to_data() -> Dictionary:
	return {
		"visited_market": visited_market, "cart_loaded": cart_loaded, "cart_sale": cart_sale,
		"iron_hoe": iron_hoe, "sharp_sickle": sharp_sickle, "read_letter": read_letter,
		"received_heirlooms": received_heirlooms, "invited_hai": invited_hai, "ate_with_hai": ate_with_hai,
		"met_mai": met_mai, "read_city_letter": read_city_letter, "learned_weaving": learned_weaving,
		"solo_basket": solo_basket, "nest_basket": nest_basket, "read_notebook": read_notebook, "heard_dad": heard_dad, "farm_note": farm_note,
		"parents_visited": parents_visited, "family_meal": family_meal, "family_replied": family_replied, "mom_points": mom_points,
		"inspected_pump": inspected_pump, "found_pipes": found_pipes, "sprinkler": sprinkler,
		"hatch_day": hatch_day, "chick": chick, "expanded_coop": expanded_coop, "fertilizer_used": fertilizer_used,
		"neighbor_order": neighbor_order,
		"coop_step": coop_step, "coop_work": coop_work, "feeder_days": feeder_days,
		"nails_found": nails_found, "wood_day": wood_day, "wood_mask": wood_mask, "straw_day": straw_day,
		"tea_day": tea_day, "herb_day": herb_day, "broth_day": broth_day, "juice_until": juice_until,
		"rice_turned": rice_turned, "lan_helped": lan_helped, "hai_chat": hai_chat, "lotus_seen": lotus_seen,
		"festival": festival.to_data(),
		"social": social.to_data(),
		"craft": craft.to_data(),
		"drought": drought.to_data(),
		"late": late.to_data(),
		"works": works.to_data(),
		"autumn": autumn.to_data(),
	}


static func from_data(data: Variant, day: int, version: int) -> SummerProgress:
	if not data is Dictionary:
		return null
	var state := SummerProgress.new()
	for key in state.to_data():
		if key in ["festival", "social", "craft", "drought", "late", "works", "autumn"]:
			continue
		var default: Variant = state.get(key)
		var value: Variant = data.get(key) if version >= 14 else data.get(key, default)
		if default is bool and not value is bool:
			return null
		if default is String and (not value is String or value.length() > 160):
			return null
		if default is int:
			var minimum := -1 if key == "sprinkler" else 0
			var maximum := 30
			match key:
				"sprinkler": maximum = SPRINKLER_CELLS.size() - 1
				"hatch_day": maximum = day + 5
				"neighbor_order": maximum = 2
				"coop_step": maximum = 4
				"coop_work": maximum = 4
				"feeder_days": maximum = 2
				"wood_mask", "rice_turned": maximum = 7
				"wood_day", "straw_day", "tea_day", "herb_day", "broth_day": maximum = day
				"juice_until": maximum = GardenCalendar.LAST_MINUTE
			if not (value is int or value is float) or value < minimum or value > maximum or value != floor(value):
				return null
			value = int(value)
		state.set(key, value)
	if (state.received_heirlooms and not state.read_letter) or (state.ate_with_hai and not state.invited_hai) or (
		state.solo_basket and not state.learned_weaving
	) or (state.family_meal and not state.parents_visited) or (state.family_replied and not state.family_meal) or (state.inspected_pump and not state.parents_visited) or (
		state.found_pipes and not state.inspected_pump
	) or (state.sprinkler >= 0 and not state.found_pipes) or (state.chick and state.hatch_day > 0):
		return null
	if state.coop_step == 4 and (not state.expanded_coop or state.coop_work != 0):
		return null
	if state.coop_work > 0 and state.coop_step not in [1, 2]:
		return null
	if state.lan_helped != (state.rice_turned == 7):
		return null
	if version >= 15:
		state.festival = VillageFestival.from_data(data.get("festival"), day, 20 if version >= 24 else 15)
		if state.festival == null:
			return null
	elif state.chick:
		state.festival.chick_age = 3
		state.festival.chick_joined = true
	if version >= 16:
		state.social = VillageSocial.from_data(data.get("social"), day)
		if state.social == null or (state.social.training_invited and not state.festival.wrestling):
			return null
	else:
		state.social.wrestled = state.festival.wrestling
	if version >= 17:
		state.craft = SummerCraft.from_data(data.get("craft"), day, version)
		if state.craft == null:
			return null
	if version >= 18:
		state.drought = DroughtProgress.from_data(data.get("drought"), day)
		if state.drought == null:
			return null
	if version >= 19:
		state.late = LateSummer.from_data(data.get("late"), day)
		if state.late == null:
			return null
	if version >= 20:
		state.works = BambooWorks.from_data(data.get("works"), day, version)
		if state.works == null:
			return null
	else:
		state.works.county_met = state.late.melon_sold > 0 or state.late.corn_sold > 0
	if version >= 21:
		state.autumn = AutumnWork.from_data(data.get("autumn"), day, version)
		if state.autumn == null or state.works.order_paid != (state.autumn.first_payout > 0):
			return null
		if state.works.queued_count > 0 and not state.autumn.corner_ready():
			return null
	elif state.works.order_paid:
		state.autumn.first_payout = state.works.order_value()
		state.autumn.favored = not state.works.storm_damage
		state.autumn.reputation = -5 if state.works.storm_damage else 0
		state.autumn.damage_applied = true
		state.autumn.set_next_order(mini(day, state.works.order_due))
	return state


static func item_name(item: String) -> String:
	match item:
		FERTILIZER: return "Phân bón"
		RICE_BAG: return "Gạo quê"
		BAMBOO: return "Tre"
		ROOT_STOCK: return "Củ giống Thuận Thành"
		WOOD: return "Gỗ tạp"
		NAIL: return "Đinh sắt"
		STRAW: return "Rơm khô"
		PENNYWORT: return "Rau má"
		CANE_JUICE: return "Nước mía"
		"drying_mat": return "Nong phơi tre"
	var index := BASKETS.find(item)
	if index >= 0:
		return BASKET_NAMES[index]
	for name in [VillageFestival.item_name(item), VillageSocial.item_name(item), SummerCraft.item_name(item), DroughtProgress.item_name(item), LateSummer.item_name(item), AutumnWork.item_name(item), BambooWorks.item_name(item)]:
		if not name.is_empty():
			return name
	return ""


static func sale_price(item: String) -> int:
	var fine_price := AutumnWork.sale_price(item)
	if fine_price > 0:
		return fine_price
	if item == SummerCraft.FLOWER_SCARF:
		return 35
	if item == FishCatalog.GOLDFISH:
		return 0
	var wholesale := BambooWorks.sale_price(item)
	if wholesale > 0:
		return wholesale
	var index := BASKETS.find(item)
	if index >= 0:
		return BASKET_PRICES[index]
	if FishCatalog.FISH.has(item):
		return FishCatalog.FISH[item].sell_price
	for crop in CropCatalog.CROPS.values():
		if crop.produce_item == item:
			return crop.sell_price
	return 0
