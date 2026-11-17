class_name SummerCraft
extends RefCounted

const TRIP_DAY := 36
const EMBROIDERY_DAY := 37
const HEAT_HINT_DAY := 38
const LAN_DAY := 40
const LAN_VISIT_HOUR := 12 * 60 + 30
const ORDER_DAY := 41
const LOTUS_DAY := 42
const BUYER_DAY := 43
const FORECAST_DAY := 44
const HUNGER_PRICE := 5
const JAR_PRICE := 20
const TANK_PRICE := 25
const CLOTH_PRICE := 4
const THREAD_PRICE := 3
const CLOTH := "white_cloth"
const FIRST_STITCH := "first_stitch"
const FLOWER_SCARF := "flower_scarf"
const BUYER_CARD := "binh_card"
const ORDER_COUNT := 3
const ORDER_REWARD := 150

var trip_reply := 0
var huong_met := false
var bun_day := 0
var jar := false
var tank := false
var tank_fish := false
var needle := false
var embroidery := false
var first_pattern := ""
var ly_warned := false
var lan_choice := 0
var lan_reply := 0
var order_deadline := 0
var order_done := false
var order_extended := false
var next_order_day := 0
var repeat_deadline := 0
var lotus_caught := false
var buyer_met := false


func to_data() -> Dictionary:
	return {
		"trip_reply": trip_reply, "huong_met": huong_met, "bun_day": bun_day, "jar": jar,
		"tank": tank, "tank_fish": tank_fish, "needle": needle, "embroidery": embroidery,
		"first_pattern": first_pattern, "ly_warned": ly_warned, "lan_choice": lan_choice,
		"lan_reply": lan_reply, "order_deadline": order_deadline, "order_done": order_done,
		"order_extended": order_extended, "next_order_day": next_order_day, "repeat_deadline": repeat_deadline,
		"lotus_caught": lotus_caught, "buyer_met": buyer_met,
	}


static func from_data(data: Variant, day: int, version: int) -> SummerCraft:
	if not data is Dictionary:
		return null
	var state := SummerCraft.new()
	var maxima := {"trip_reply": 2, "bun_day": day, "lan_choice": 3, "lan_reply": 2, "order_deadline": day + 5,
		"next_order_day": day + 7, "repeat_deadline": day + 7}
	for key in state.to_data():
		if version < 18 and key in ["order_extended", "next_order_day", "repeat_deadline"]:
			continue
		var value: Variant = data.get(key)
		var initial: Variant = state.get(key)
		if initial is bool and not value is bool:
			return null
		if initial is String and (not value is String or (not value.is_empty() and not valid_pattern(value))):
			return null
		if initial is int:
			if not (value is int or value is float) or value < 0 or value > maxima[key] or value != floor(value):
				return null
			value = int(value)
		state.set(key, value)
	if version < 18 and state.order_done:
		state.next_order_day = maxi(46, state.order_deadline) + 7
	if state.embroidery != (not state.first_pattern.is_empty()) or (state.embroidery and not state.needle):
		return null
	if state.tank_fish and not state.tank or state.lan_reply > 0 and state.lan_choice == 0 or state.order_done and state.order_deadline == 0:
		return null
	if (day < TRIP_DAY and (state.trip_reply > 0 or state.huong_met or state.tank)) or (
		day < EMBROIDERY_DAY and state.needle
	) or (day < HEAT_HINT_DAY and (state.jar or state.ly_warned)) or (day < LAN_DAY and state.lan_choice > 0) or (
		day < ORDER_DAY and state.order_deadline > 0
	) or (day < LOTUS_DAY and (state.lotus_caught or state.tank_fish)) or (day < BUYER_DAY and state.buyer_met):
		return null
	return state


static func valid_pattern(pattern: String) -> bool:
	if pattern.length() != 64:
		return false
	for color in pattern:
		if color not in ["0", "1", "2", "3"]:
			return false
	return pattern != "0".repeat(64)


static func item_name(item: String) -> String:
	match item:
		CLOTH: return "Vải trắng"
		FIRST_STITCH: return "Miếng thêu đầu tiên"
		FLOWER_SCARF: return "Khăn thêu hoa"
		BUYER_CARD: return "Danh thiếp Chú Bình"
	return ""
