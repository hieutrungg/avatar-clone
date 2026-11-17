class_name ArrivalProgress
extends RefCounted

const MAX_STAMINA := 100
const CLEAN_COST := 5
const WEED_COST := 5
const PEST_PENDING := -1
const PEST_REMOVED := -2
const WELCOME_GIFT := "banh_da"
const EGG := "trung_ga"
const MEAL_ENERGY := 20
const COOP_DAY := 5
const FISHING_DAY := 6
const COOKING_DAY := 7
const FENCE_DAY := 8
const DRAIN_DAY := 9
const PRODUCE_DAY := 10
const BOARD_DAY := 11
const FAIR_DAY := 14

enum DogFood { PANTRY, BAG, FED }
enum Hen { LOCKED, RATION, FED, EGG_READY, EGG_COLLECTED }

var intro_seen := false
var tools_taken := false
var floor_cleared := false
var power_on := false
var bed_ready := false
var stamina := MAX_STAMINA
var cleared_weeds := 0
var dog_food: DogFood = DogFood.PANTRY
var seeds_taken := false
var lan_met := false
var cat_home := false
var first_crop_watered := false
var pest_plot := PEST_PENDING
var hen := Hen.LOCKED
var caught_fish := false
var cooked_meal := false
var meal_bonus := 0
var fence_index := -1
var drained := false


func total_stamina() -> int:
	return stamina + maxi(meal_bonus, 0)


func spend_stamina(cost: int) -> bool:
	if total_stamina() < cost:
		return false
	var extra := mini(maxi(meal_bonus, 0), cost)
	meal_bonus -= extra
	stamina -= cost - extra
	return true


func rest(capacity := MAX_STAMINA) -> void:
	stamina = capacity
	meal_bonus = MEAL_ENERGY if meal_bonus == -1 else 0
	if hen == Hen.FED:
		hen = Hen.EGG_READY


func clear_floor() -> bool:
	if floor_cleared or not spend_stamina(CLEAN_COST):
		return false
	floor_cleared = true
	return true


func house_tasks() -> String:
	var marks := ["○", "✓"]
	return "%s  Nhặt đồ nghề cạnh cửa.\n%s  Dọn đống đồ giữa nhà.\n%s  Bật cầu dao trên tường.\n%s  Đặt lại giường để ngủ." % [
		marks[int(tools_taken)], marks[int(floor_cleared)], marks[int(power_on)], marks[int(bed_ready)],
	]


func has_weeds(plot_index: int) -> bool:
	return (cleared_weeds & (1 << plot_index)) == 0


func cut_weeds(plot_index: int, cost := WEED_COST) -> bool:
	if not tools_taken or not has_weeds(plot_index) or not spend_stamina(cost):
		return false
	cleared_weeds |= 1 << plot_index
	return true


func weeds_cleared(plot_count: int) -> int:
	var count := 0
	for index in range(plot_count):
		count += int(not has_weeds(index))
	return count


func to_data() -> Dictionary:
	return {
		"intro_seen": intro_seen,
		"tools_taken": tools_taken,
		"floor_cleared": floor_cleared,
		"power_on": power_on,
		"bed_ready": bed_ready,
		"stamina": stamina,
		"cleared_weeds": cleared_weeds,
		"dog_food": dog_food,
		"seeds_taken": seeds_taken,
		"lan_met": lan_met,
		"cat_home": cat_home,
		"first_crop_watered": first_crop_watered,
		"pest_plot": pest_plot,
		"hen": hen,
		"caught_fish": caught_fish,
		"cooked_meal": cooked_meal,
		"meal_bonus": meal_bonus,
		"fence_index": fence_index,
		"drained": drained,
	}


static func from_data(data: Dictionary, plot_count: int, version: int) -> ArrivalProgress:
	for field in ["intro_seen", "tools_taken", "floor_cleared", "power_on", "bed_ready"]:
		if not data.get(field) is bool:
			return null
	var energy := _read_integer(data.get("stamina"), MAX_STAMINA + (12 if version >= 16 else 0))
	if energy < 0:
		return null
	var arrival := ArrivalProgress.new()
	arrival.intro_seen = data.intro_seen
	arrival.tools_taken = data.tools_taken
	arrival.floor_cleared = data.floor_cleared
	arrival.power_on = data.power_on
	arrival.bed_ready = data.bed_ready
	arrival.stamina = energy
	if version >= 10:
		var weeds := _read_integer(data.get("cleared_weeds"), (1 << plot_count) - 1)
		var food := _read_integer(data.get("dog_food"), DogFood.FED)
		if weeds < 0 or food < 0:
			return null
		arrival.cleared_weeds = weeds
		arrival.dog_food = food as DogFood
	if version >= 11:
		for field in ["seeds_taken", "lan_met", "cat_home", "first_crop_watered"]:
			if not data.get(field) is bool:
				return null
		var pest: Variant = data.get("pest_plot")
		if not (pest is int or pest is float) or not (pest >= PEST_REMOVED and pest < plot_count) or pest != floor(pest):
			return null
		arrival.seeds_taken = data.seeds_taken
		arrival.lan_met = data.lan_met
		arrival.cat_home = data.cat_home
		arrival.first_crop_watered = data.first_crop_watered
		arrival.pest_plot = int(pest)
	if version >= 12:
		for field in ["caught_fish", "cooked_meal", "drained"]:
			if not data.get(field) is bool:
				return null
		var hen_state := _read_integer(data.get("hen"), Hen.EGG_COLLECTED)
		var bonus := _read_integer(data.get("meal_bonus"), MEAL_ENERGY)
		var fence := _read_integer(data.get("fence_index"), GardenProgress.FENCE_AREA.get_area() - 1)
		if hen_state < 0 or (bonus < 0 and data.get("meal_bonus") != -1) or (fence < 0 and data.get("fence_index") != -1):
			return null
		arrival.hen = hen_state as Hen
		arrival.caught_fish = data.caught_fish
		arrival.cooked_meal = data.cooked_meal
		arrival.meal_bonus = bonus
		arrival.fence_index = fence
		arrival.drained = data.drained
		if bonus != 0 and not arrival.cooked_meal:
			return null
	return arrival


static func _read_integer(value: Variant, maximum: int) -> int:
	if not (value is int or value is float) or not (value >= 0 and value <= maximum) or value != floor(value):
		return -1
	return int(value)
