class_name VillageFestival
extends RefCounted

const ORDER_DAY := 22
const NOTICE_DAY := 28
const PREP_DAY := 29
const FAIR_DAY := 30
const OPEN := 8 * 60
const CLOSE := 17 * 60
const LANTERN_HOUR := 19 * 60
const EGG_ORDER_COUNT := 10
const EGG_ORDER_REWARD := 80
const BRAN := "fine_bran"
const MUNG := "mung_bean"
const GINGER := "wild_ginger"
const SNAIL := "river_snail"
const MUSHROOM := "wood_ear"
const DISH_NAMES := ["Canh cá rau má", "Xôi nếp đậu xanh", "Ốc xào mộc nhĩ", "Cháo gà gừng"]
const DISH_SCORES := [60, 80, 70, 90]
const DISH_HINTS := ["Cá câu, rau má và gạo", "Nếp tự trồng và đậu xanh", "Ốc, mộc nhĩ và một loại rau", "Trứng, gạo và gừng"]
const NAME_LIMIT := 18

var egg_deadline := 0
var egg_order_done := false
var chick_age := 0
var chick_fed := false
var chick_divider := false
var chick_straw := false
var chick_named := ""
var chick_joined := false
var chick_seen_hai := false
var chick_play_day := 0
var registered := false
var prepared_dish := -1
var contest := 0
var contest_score := 0
var judging_minute := 0
var wrestling := false
var wrestler_met := false
var lantern := false
var reputation := 0
var lan_points := 0
var gather_mask := 0
var mill_day := 0


func to_data() -> Dictionary:
	return {
		"egg_deadline": egg_deadline, "egg_order_done": egg_order_done,
		"chick_age": chick_age, "chick_fed": chick_fed, "chick_divider": chick_divider,
		"chick_straw": chick_straw, "chick_named": chick_named, "chick_joined": chick_joined,
		"chick_seen_hai": chick_seen_hai, "chick_play_day": chick_play_day,
		"registered": registered, "prepared_dish": prepared_dish, "contest": contest,
		"contest_score": contest_score, "judging_minute": judging_minute,
		"wrestling": wrestling, "wrestler_met": wrestler_met, "lantern": lantern,
		"reputation": reputation, "lan_points": lan_points, "gather_mask": gather_mask,
		"mill_day": mill_day,
	}


static func from_data(data: Variant, day: int, max_lan_points := 15) -> VillageFestival:
	if not data is Dictionary:
		return null
	var state := VillageFestival.new()
	for key in state.to_data():
		var value: Variant = data.get(key)
		var initial: Variant = state.get(key)
		if initial is bool and not value is bool:
			return null
		if initial is String and (not value is String or value.length() > NAME_LIMIT):
			return null
		if initial is int:
			var minimum := -1 if key == "prepared_dish" else 0
			var maximum := {
				"egg_deadline": day + 4, "chick_age": 3, "chick_play_day": day,
				"prepared_dish": DISH_NAMES.size() - 1, "contest": 2, "contest_score": 100,
				"judging_minute": GardenCalendar.LAST_MINUTE, "reputation": 55,
				"lan_points": max_lan_points, "gather_mask": 15, "mill_day": day,
			}
			if not (value is int or value is float) or value < minimum or value > maximum[key] or value != floor(value):
				return null
			value = int(value)
		state.set(key, value)
	if (state.chick_joined and (state.chick_age < 3 or state.chick_divider)) or (
		state.contest > 0 and state.judging_minute == 0
	) or (state.wrestler_met and not state.wrestling):
		return null
	return state


static func item_name(item: String) -> String:
	match item:
		BRAN: return "Cám mịn"
		MUNG: return "Đậu xanh"
		GINGER: return "Gừng"
		SNAIL: return "Ốc bươu"
		MUSHROOM: return "Mộc nhĩ"
	return ""
