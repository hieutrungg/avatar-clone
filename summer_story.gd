class_name SummerStory
extends RefCounted

const FARM_OFFSET := Vector2i(20, 0)
const FARM_GATE := Vector2i(19, 4)
const FARM_EXIT := Vector2i(20, 4)
const FARM_RIGHT := 39
const DRY := Rect2i(35, 8, 3, 1)
const PADDY := Rect2i(33, 9, 5, 2)
const POND := Rect2i(35, 4, 4, 4)
const SPRINKLERS := [Vector2i(30, 5), Vector2i(31, 5), Vector2i(30, 6), Vector2i(31, 6), Vector2i(32, 6)]
const PUMP := Vector2i(32, 2)
const MAI := Vector2i(17, 4)
const FISHING := Vector2i(38, 7)
const WELL := Vector2i(33, 2)
const POSTMAN := Vector2i(5, 4)
const GINGER := Vector2i(27, 2)
const FAMILY_VIEW := Vector2i(34, 8)
const CLOTHES := Vector2i(10, 6)
const DECOR := Vector2i(12, 7)
const CARPENTER := Vector2i(7, 5)
const MARKET_STALLS := [CLOTHES, DECOR, CARPENTER]
const STOCK := {
	"work_shirt": ["Áo làm vườn màu tím than", 22], "tank": ["Bể cá mini 6 lít", 25],
	"coop_plan": ["Bản vẽ chuồng gà cấp 2", 12], "dog_plan": ["Bản vẽ nhà chó", 10],
	"backpack": ["Balo lớn", 15], "spray": ["Thuốc xịt sâu", 5],
}
const STORY_FLAGS := ["post", "family_walk", "hai_hint", "hai_declined", "tea_hai", "reed_cut", "bamboo_ready",
	"kitchen_basket", "radio_song", "goby_tank", "picked_ginger", "solo_rice_0", "solo_rice_1", "solo_rice_2"]

var flags: Dictionary[String, bool] = {}
var purchases: Dictionary[String, bool] = {}
var order := 0
var hai_points := 0
var wearing_shirt := false
var broth_day := 0
var nest_mornings := 0


static func transferred_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.resize(TutorialChapter.PLOT_COUNT)
	for y in range(3, 11):
		for x in range(9, 18):
			var cell := Vector2i(x, y)
			var index := TutorialFarmMap.plot_at(cell)
			if index >= 0:
				cells[index] = cell + FARM_OFFSET
	return cells


static func farm_cells() -> Array[Vector2i]:
	var cells := transferred_cells()
	for x in range(DRY.position.x, DRY.end.x):
		cells.append(Vector2i(x, DRY.position.y))
	return cells


func done(key: String) -> bool:
	return flags.get(key, false)


func mark(key: String) -> bool:
	if done(key):
		return false
	flags[key] = true
	return true


func to_data() -> Dictionary:
	return {"flags": flags.duplicate(), "purchases": purchases.duplicate(), "order": order,
		"hai_points": hai_points, "wearing_shirt": wearing_shirt, "broth_day": broth_day, "nest_mornings": nest_mornings}


static func from_data(data: Variant, day: int) -> SummerStory:
	if not data is Dictionary or day < 11:
		return null
	var state := SummerStory.new()
	var saved: Variant = data.get("flags")
	var stock: Variant = data.get("purchases")
	if not saved is Dictionary or not stock is Dictionary or not data.get("wearing_shirt") is bool:
		return null
	for key in saved:
		if key not in STORY_FLAGS or saved[key] != true:
			return null
		state.flags[key] = true
	for key in stock:
		if not STOCK.has(key) or stock[key] != true:
			return null
		state.purchases[key] = true
	state.order = GardenProgress.read_integer(data.get("order"), 0, 2)
	state.hai_points = GardenProgress.read_integer(data.get("hai_points"), 0, 30)
	state.broth_day = GardenProgress.read_integer(data.get("broth_day"), 0, day + 1)
	state.nest_mornings = GardenProgress.read_integer(data.get("nest_mornings", 0), 0, 4)
	state.wearing_shirt = data.wearing_shirt
	if state.order < 0 or state.hai_points < 0 or state.broth_day < 0 or state.nest_mornings < 0 or (state.wearing_shirt and not state.purchases.has("work_shirt")):
		return null
	return state
