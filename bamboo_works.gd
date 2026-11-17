class_name BambooWorks
extends RefCounted

const FORGE_DAY := 56
const OFFER_DAY := 57
const RESTORE_DAY := 58
const ORDER_DAY := 59
const STORM_DAY := 60
const FIRST_DUE := 61
const STORM_HOUR := 17 * 60
const STORM_SECONDS := 180
const SICKLE_PRICE := 500
const WORKS_PRICE := 1500
const ORDER_SIZE := 20
const ORDER_PAY := 4000
const DAMAGED_PAY := 2800
const MAX_BATCH := 20
const IRON := "scrap_iron"
const WINE := "sticky_rice_wine"
const PRODUCTS := ["large_bamboo_basket", "rice_drying_tray", "export_bamboo_basket", "fine_bamboo_strip", "fine_tray_1", "woven_bag_1", "fine_export_1"]
const NAMES := ["Sọt tre lớn", "Nong phơi lúa", "Rổ tre xuất khẩu", "Lạt mỏng · 4 Nan Tinh", "Nong · Đẹp", "Giỏ hoa văn · Đẹp", "Rổ xuất khẩu · Đẹp"]
const MATERIALS := [1, 2, 3, 1, 8, 6, 10]
const SECONDS := [6, 9, 12, 4, 10, 12, 14]
const RESALE := [35, 62, 91]
const RAW_TARP := 1
const GOODS_TARP := 2
const COOP_TARP := 4
const DOOR := 8
const YARD_TARPS := RAW_TARP | GOODS_TARP

var iron_mask := 0
var forged := false
var sickle_hits := 0
var wine_taken := false
var offered := false
var repair_step := 0
var grove_day := 0
var grove_mask := 0
var batch_product := 0
var batch_count := 0
var batch_ticks := 0
var queued_product := 0
var queued_count := 0
var finished: Array[int] = [0, 0, 0, 0, 0, 0, 0]
var order_due := 0
var order_paid := false
var county_met := false
var storm_started := false
var storm_left := 0
var protection := 0
var storm_damage := false
var wind_steps := 0


static func item_name(item: String) -> String:
	match item:
		IRON: return "Sắt vụn"
		WINE: return "Bình rượu nếp"
	var index := PRODUCTS.find(item)
	return "" if index < 0 or index > 2 else NAMES[index]


static func sale_price(item: String) -> int:
	var index := PRODUCTS.find(item)
	return 0 if index < 0 or index > 2 else RESALE[index]


func ready() -> bool:
	return repair_step == 4


func has_advisor(day: int) -> bool:
	return ready() and day >= ORDER_DAY


func unit_ticks() -> int:
	return int(SECONDS[batch_product - 1]) * 6


func batch_seconds(day: int, include_queue := false) -> int:
	if batch_count == 0:
		return 0
	var ticks := batch_count * unit_ticks() - batch_ticks
	if include_queue and queued_count > 0:
		ticks += int(SECONDS[queued_product - 1]) * 6 * queued_count
	return ceili(float(ticks) / (6 if has_advisor(day) else 5))


func advance_batch(seconds: int, day: int) -> bool:
	if batch_count == 0 or seconds <= 0:
		return false
	var available := seconds * (6 if has_advisor(day) else 5)
	while batch_count > 0 and available > 0:
		var unit := unit_ticks()
		var product := batch_product - 1
		var used := mini(available, batch_count * unit - batch_ticks)
		batch_ticks += used
		available -= used
		var made := floori(float(batch_ticks) / unit)
		if made > 0:
			finished[product] = mini(GardenProgress.MAX_SAVE_INTEGER, finished[product] + made * (4 if product == 3 else 1))
			batch_count -= made
			batch_ticks -= made * unit
		if batch_count == 0:
			batch_product = queued_product
			batch_count = queued_count
			queued_product = 0
			queued_count = 0
	return true


func resolve_storm() -> void:
	storm_left = 0
	storm_damage = repair_step > 0 and (protection & YARD_TARPS) != YARD_TARPS


func order_value() -> int:
	return DAMAGED_PAY if storm_damage else ORDER_PAY


func to_data() -> Dictionary:
	return {
		"iron_mask": iron_mask, "forged": forged, "sickle_hits": sickle_hits,
		"wine_taken": wine_taken, "offered": offered, "repair_step": repair_step,
		"grove_day": grove_day, "grove_mask": grove_mask, "county_met": county_met,
		"batch_product": batch_product, "batch_count": batch_count, "batch_ticks": batch_ticks,
		"queued_product": queued_product, "queued_count": queued_count,
		"finished": finished.duplicate(), "order_due": order_due, "order_paid": order_paid,
		"storm_started": storm_started, "storm_left": storm_left, "protection": protection,
		"storm_damage": storm_damage, "wind_steps": wind_steps,
	}


static func from_data(data: Variant, day: int, version: int) -> BambooWorks:
	if not data is Dictionary:
		return null
	var state := BambooWorks.new()
	var limits := {
		"iron_mask": 7, "sickle_hits": 16383, "repair_step": 4, "grove_day": day,
		"grove_mask": 15, "batch_product": PRODUCTS.size(), "batch_count": MAX_BATCH, "batch_ticks": 83,
		"order_due": mini(GardenProgress.MAX_SAVE_INTEGER, day + 2), "storm_left": STORM_SECONDS,
		"protection": 15, "wind_steps": 7,
	}
	for key in limits:
		var value := GardenProgress.read_integer(data.get(key), 0, limits[key])
		if value < 0:
			return null
		state.set(key, value)
	for key in ["forged", "wine_taken", "offered", "county_met", "order_paid", "storm_started", "storm_damage"]:
		if not data.get(key) is bool:
			return null
		state.set(key, data[key])
	if version >= 22:
		state.queued_product = GardenProgress.read_integer(data.get("queued_product"), 0, PRODUCTS.size())
		state.queued_count = GardenProgress.read_integer(data.get("queued_count"), 0, MAX_BATCH)
		if state.queued_product < 0 or state.queued_count < 0 or (state.queued_product == 0) != (state.queued_count == 0) or (
			state.queued_count > 0 and state.batch_count == 0
		):
			return null
	var goods: Variant = data.get("finished")
	if not goods is Array or goods.size() != (3 if version == 20 else PRODUCTS.size()):
		return null
	for index in goods.size():
		var value := GardenProgress.read_integer(goods[index], 0, GardenProgress.MAX_SAVE_INTEGER)
		if value < 0:
			return null
		state.finished[index] = value
	if (state.batch_product == 0) != (state.batch_count == 0):
		return null
	if state.batch_product == 0 and state.batch_ticks != 0:
		return null
	if state.batch_product > 0 and (not state.ready() or state.batch_ticks >= state.unit_ticks()):
		return null
	if (state.repair_step > 0 and (not state.offered or day < RESTORE_DAY)) or (
		state.order_due > 0 and (state.order_due < FIRST_DUE or not state.ready() or not state.county_met)
	) or (state.order_paid and state.order_due == 0):
		return null
	if state.storm_started and day < STORM_DAY or (state.storm_left > 0 and day != STORM_DAY):
		return null
	if not state.storm_started and (state.storm_left > 0 or state.protection != 0 or state.storm_damage):
		return null
	return state
