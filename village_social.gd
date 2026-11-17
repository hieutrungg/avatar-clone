class_name VillageSocial
extends RefCounted

const AFTER_FAIR_DAY := 31
const NEIGHBORS_DAY := 32
const TRAINING_DAY := 33
const MESSAGE_DAY := 34
const SCARF_DAY := 35
const EARLY_WAKE := 5 * 60
const RECOVERY_WAKE := 6 * 60 + 30
const RIDE_PRICE := 8
const RIDE_STEPS := 2
const SCARF := "embroidered_scarf"
const THREAD := "colored_thread"
const CHIEF := Vector2i(6, 5)
const MINH := Vector2i(6, 8)
const TUAN := Vector2i(2, 5)
const PHONE := Vector2i(9, 2)
const RESPONSES := [
	"Cho em thêm thời gian.",
	"Em đang bận, chưa tính được.",
	"Em không về được.",
]

var chief_met := false
var wrestled := false
var minh_points := 20
var tuan_points := 15
var training_invited := false
var wake_early := false
var training_day := 0
var streak := 0
var training_reward := false
var boss_reply := 0
var minh_story := 0
var scarf_found := false
var scarf_reply := 0


func to_data() -> Dictionary:
	return {
		"chief_met": chief_met, "wrestled": wrestled, "minh_points": minh_points, "tuan_points": tuan_points,
		"training_invited": training_invited, "wake_early": wake_early, "training_day": training_day,
		"streak": streak, "training_reward": training_reward, "boss_reply": boss_reply,
		"minh_story": minh_story, "scarf_found": scarf_found, "scarf_reply": scarf_reply,
	}


static func from_data(data: Variant, day: int) -> VillageSocial:
	if not data is Dictionary:
		return null
	var state := VillageSocial.new()
	var maxima := {
		"minh_points": 60, "tuan_points": 20, "training_day": day,
		"streak": 7, "boss_reply": 3, "minh_story": 2, "scarf_reply": 2,
	}
	for key in state.to_data():
		var value: Variant = data.get(key)
		if state.get(key) is bool:
			if not value is bool:
				return null
		else:
			if not (value is int or value is float) or value < 0 or value > maxima[key] or value != floor(value):
				return null
			value = int(value)
		state.set(key, value)
	if (state.wake_early and not state.training_invited) or (state.training_day > 0 and (
		not state.training_invited or state.training_day < TRAINING_DAY
	)) or (state.training_reward != (state.streak == 7)) or (state.streak > 0 and state.training_day == 0):
		return null
	if (state.boss_reply > 0 and day < MESSAGE_DAY) or (state.minh_story > 0 and day < SCARF_DAY) or (
		state.scarf_found and state.minh_story == 0
	) or (state.scarf_reply > 0 and not state.scarf_found):
		return null
	if day < AFTER_FAIR_DAY and (state.chief_met or state.training_invited):
		return null
	if day < NEIGHBORS_DAY and (state.minh_points != 20 or state.tuan_points != 15):
		return null
	return state


func stamina_cap(day: int) -> int:
	return ArrivalProgress.MAX_STAMINA + (10 if training_reward else 0) + (2 if training_day == day else 0)


static func item_name(item: String) -> String:
	match item:
		SCARF: return "Khăn thêu cũ"
		THREAD: return "Chỉ màu"
	return ""
