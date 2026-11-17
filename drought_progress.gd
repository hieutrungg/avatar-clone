class_name DroughtProgress
extends RefCounted

const FIRST := 45
const LAST := 49
const RAIN := 50
const OIL_DAY := 46
const SHARE_DAY := 47
const DIG_DAY := 48
const SECOND_PASS := 15 * 60
const ROPE := "well_rope"
const ROPE_PRICE := 10
const OIL_TUAN := 15
const OIL_THANH := 18
const WATER_PRICE := 30
const WOOD := 8
const WELL_SITE := Vector2i(17, 5)
const THANH := Vector2i(10, 8)
const TAM := Vector2i(6, 7)

var oil := 1
var supply := 0
var chicken_water := 0
var delivery := 0
var share_choice := 0
var learned_well := false
var well_step := 0
var ly_help := false
var review_seen := false
var stamina_spent := 0
var spent := 0
var lost := 0
var stunted := 0
var dry_hen_days := 0


static func active(on_day: int) -> bool:
	return on_day >= FIRST and on_day <= LAST


static func item_name(item: String) -> String:
	return "Dây thừng" if item == ROPE else ""


func to_data() -> Dictionary:
	return {
		"oil": oil, "supply": supply, "chicken_water": chicken_water, "delivery": delivery,
		"share_choice": share_choice, "learned_well": learned_well, "well_step": well_step,
		"ly_help": ly_help, "review_seen": review_seen, "spent": spent, "lost": lost,
		"stunted": stunted, "dry_hen_days": dry_hen_days, "stamina_spent": stamina_spent,
	}


static func from_data(data: Variant, day: int) -> DroughtProgress:
	if not data is Dictionary:
		return null
	var state := DroughtProgress.new()
	var limits := {"oil": 5, "supply": 80, "chicken_water": 2, "delivery": day, "share_choice": 2,
		"well_step": 4, "spent": 9007199254740991, "lost": 50, "stunted": 50, "dry_hen_days": 5, "stamina_spent": 2048}
	for key in state.to_data():
		var value: Variant = data.get(key)
		if state.get(key) is bool:
			if not value is bool:
				return null
		else:
			if not (value is int or value is float) or value < 0 or value > limits[key] or value != floor(value):
				return null
			value = int(value)
		state.set(key, value)
	if state.well_step > 0 and not state.learned_well:
		return null
	return state
