class_name GardenProgress
extends RefCounted

const PLOT_CELLS := [
	Vector2i(10, 5), Vector2i(12, 5), Vector2i(14, 5),
	Vector2i(10, 7), Vector2i(12, 7), Vector2i(14, 7),
]
const STARTING_SEEDS := 6
const GOAL_COINS := 60
const SAVE_VERSION := 24
const LOW_PLOT := Vector2i(10, 7)
const DITCH_CELL := LOW_PLOT + Vector2i.DOWN
const FENCE_AREA := Rect2i(13, 9, 3, 2)
const FIRST_PRODUCE := "water_spinach_produce"
const PROTOTYPE_SEED_COUNT := 6
const PROTOTYPE_SALE_PRICE := 10
# JSON numbers must round-trip through Godot's floating-point parser.
const MAX_SAVE_INTEGER := 9007199254740991
const FIRST_SUMMER_LENGTH := 100

enum PlotAction { HOE, SOW, WATER, HARVEST, NO_SEEDS, ALREADY_WATERED, OUT_OF_SEASON, REMOVE_PEST, FLOODED, DEEP_HOE, FLOOD_PADDY, WRONG_SOIL, WAIT_FOR_WATER, WELL_EMPTY, CUT_STUBBLE }
enum PrototypeStage { UNTILLED, TILLED, SEED, SPROUT, RIPE }
enum Area { GARDEN, VILLAGE, HOUSE, DISTRICT, FESTIVAL, LOTUS_POND, COUNTY_FAIR, FORGE, BAMBOO_WORKS, STOREHOUSE }

class Plot:
	var tilled := false
	var crop_id := ""
	var watered_nights := 0
	var watered := false
	var prepared := false
	var fertilized := false
	var watered_twice := false
	var drought_stress := 0
	var loosened := false
	var fertile := false

class Relationship:
	var points := 0
	var last_gift_day := 0
	var event_seen := false

var plots: Dictionary[Vector2i, Plot] = {}
var relationships: Dictionary[String, Relationship] = {}
var day := 1
var minute_of_day := GardenCalendar.START_MINUTE
var coins := 0
var inventory: Dictionary[String, int] = {CropCatalog.CROPS[CropCatalog.CABBAGE].seed_item: STARTING_SEEDS}
var selected_crop := CropCatalog.CABBAGE
var tutorial_completed := false
var area: Area = Area.GARDEN
var order_state: VillageOrder.State = VillageOrder.State.AVAILABLE
var market_delivery_day := 0
var fish_order_state: FishOrder.State = FishOrder.State.AVAILABLE
var arrival: ArrivalProgress
var summer: SummerProgress
var chapter: TutorialChapter
var detailed_tutorial_completed := false
var packed_tutorial_goods: Dictionary[String, int] = {}
var summer_story: SummerStory


func _init() -> void:
	for cell in PLOT_CELLS:
		plots[cell] = Plot.new()
	for villager_id in VillagerCatalog.IDS:
		relationships[villager_id] = Relationship.new()


static func new_arrival(detailed := false) -> GardenProgress:
	var progress := GardenProgress.new()
	progress.arrival = ArrivalProgress.new()
	progress.summer = SummerProgress.new()
	progress.inventory.clear()
	progress.selected_crop = CropCatalog.WATER_SPINACH
	if detailed:
		progress.chapter = TutorialChapter.new()
		progress.minute_of_day = 15 * 60
	return progress


func season() -> GardenCalendar.Season:
	if arrival != null and day >= AutumnWork.AUTUMN_DAY and day <= FIRST_SUMMER_LENGTH:
		return GardenCalendar.Season.AUTUMN
	return GardenCalendar.season(_season_day(day))


func season_name() -> String:
	if season() == GardenCalendar.Season.AUTUMN:
		return "Thu"
	return GardenCalendar.season_name(_season_day(day))


func season_date() -> int:
	if season() == GardenCalendar.Season.AUTUMN:
		return day - AutumnWork.AUTUMN_DAY + 1
	if arrival != null and day <= FIRST_SUMMER_LENGTH:
		return day
	return GardenCalendar.day_in_season(_season_day(day))


func is_raining(on_day: int) -> bool:
	if chapter != null and on_day <= TutorialChapter.LAST_DAY:
		return on_day == 8
	if summer_story != null and on_day >= SummerProgress.FIRST_DAY and on_day <= SummerProgress.BUILD_DAY:
		return on_day == SummerProgress.RAIN_DAY
	if arrival != null and DroughtProgress.active(on_day):
		return false
	if arrival != null and on_day == DroughtProgress.RAIN:
		return true
	if arrival != null and on_day == BambooWorks.STORM_DAY:
		return on_day != day or minute_of_day >= BambooWorks.STORM_HOUR
	if arrival != null and on_day >= BambooWorks.FIRST_DUE and on_day <= AutumnWork.CRAFT_DAY:
		return false
	if arrival != null and on_day >= AutumnWork.RAIN_START and on_day < AutumnWork.RAIN_START + AutumnWork.RAIN_NIGHTS:
		return true
	if arrival != null and on_day == AutumnWork.RAIN_START + AutumnWork.RAIN_NIGHTS:
		return false
	if arrival != null and on_day >= LateSummer.RECOVERY and on_day <= LateSummer.FIRST_FAIR:
		return false
	if arrival != null and on_day <= ArrivalProgress.PRODUCE_DAY:
		return on_day == ArrivalProgress.DRAIN_DAY
	if arrival != null and on_day >= SummerProgress.RAIN_DAY and on_day <= SummerProgress.PUMP_DAY:
		return on_day == SummerProgress.RAIN_DAY
	if arrival != null and on_day == VillageFestival.FAIR_DAY:
		return false
	if arrival != null and on_day in [SummerCraft.HEAT_HINT_DAY, SummerCraft.FORECAST_DAY]:
		return false
	return GardenCalendar.is_raining(_season_day(on_day))


func _season_day(on_day: int) -> int:
	if arrival == null:
		return on_day
	if on_day <= FIRST_SUMMER_LENGTH:
		return GardenCalendar.SEASON_LENGTH + GardenCalendar.weekday_index(on_day) + 1
	return on_day + GardenCalendar.SEASON_LENGTH * 2 - FIRST_SUMMER_LENGTH


func can_visit_village() -> bool:
	return chapter == null and (arrival == null or day >= 3)


func can_visit_district() -> bool:
	return summer_story == null or day >= SummerCraft.TRIP_DAY


func village_wholesale_market() -> bool:
	return summer_story != null and area == Area.VILLAGE


func story_order() -> bool:
	if not village_wholesale_market() or summer_story.order == 2:
		return false
	if summer_story.order == 0:
		summer_story.order = 1
		return true
	var reward := (5 * wholesale_price("amaranth") + 2 * wholesale_price(FishCatalog.GOBY)) * 3
	if quantity("amaranth") < 5 or quantity(FishCatalog.GOBY) < 2 or reward > MAX_SAVE_INTEGER - coins:
		return false
	_add_items("amaranth", -5)
	_add_items(FishCatalog.GOBY, -2)
	_earn(reward)
	summer_story.order = 2
	return true


func buy_story_stock(item: String) -> bool:
	if not village_wholesale_market() or not GardenCalendar.shop_is_open(minute_of_day) or not SummerStory.STOCK.has(item):
		return false
	var cost: int = SummerStory.STOCK[item][1]
	if summer_story.purchases.has(item) or coins < cost or (item == "tank" and summer.craft.tank):
		return false
	coins -= cost
	summer_story.purchases[item] = true
	if item == "work_shirt":
		summer_story.wearing_shirt = true
	return true


func can_sleep() -> bool:
	return arrival == null or arrival.bed_ready


func yard_open() -> bool:
	return arrival != null and day >= 2


func plot_has_weeds(cell: Vector2i) -> bool:
	var index := PLOT_CELLS.find(cell)
	return index >= 0 and yard_open() and arrival.has_weeds(index)


func cleared_plot_count() -> int:
	return arrival.weeds_cleared(PLOT_CELLS.size()) if arrival != null else PLOT_CELLS.size()


func summer_available(from_day: int) -> bool:
	return summer != null and day >= from_day


func in_drought() -> bool:
	return summer != null and DroughtProgress.active(day)


func pump_running() -> bool:
	return summer != null and summer.sprinkler >= 0 and (
		not in_drought() or (summer.drought.oil > 0 and arrival.power_on)
	) and not (day == DroughtProgress.RAIN)


func drought_water_left() -> int:
	return summer.drought.supply if in_drought() else 0


func collect_scrap_iron(index: int) -> bool:
	if not summer_available(BambooWorks.FORGE_DAY) or area != Area.FORGE or index < 0 or index >= 3:
		return false
	var bit := 1 << index
	if summer.works.iron_mask & bit:
		return false
	summer.works.iron_mask |= bit
	_add_items(BambooWorks.IRON, 1)
	return true


func forge_sickle() -> bool:
	if not summer_available(BambooWorks.FORGE_DAY) or area != Area.FORGE or not arrival.tools_taken or (
		summer.works.forged or coins < BambooWorks.SICKLE_PRICE or quantity(BambooWorks.IRON) < 3
	):
		return false
	coins -= BambooWorks.SICKLE_PRICE
	_add_items(BambooWorks.IRON, -3)
	summer.works.forged = true
	summer.works.sickle_hits = 0
	return true


func take_workshop_wine() -> bool:
	if not summer_available(BambooWorks.OFFER_DAY) or area != Area.HOUSE or summer.works.wine_taken:
		return false
	summer.works.wine_taken = true
	_add_items(BambooWorks.WINE, 1)
	return true


func discuss_workshop() -> bool:
	if not summer_available(BambooWorks.OFFER_DAY) or area != Area.BAMBOO_WORKS or (
		not summer.learned_weaving or summer.works.offered or quantity(BambooWorks.WINE) == 0
	):
		return false
	_add_items(BambooWorks.WINE, -1)
	summer.works.offered = true
	return true


func buy_bamboo_workshop() -> bool:
	if not summer_available(BambooWorks.RESTORE_DAY) or area != Area.BAMBOO_WORKS or (
		not summer.works.offered or summer.works.repair_step != 0 or coins < BambooWorks.WORKS_PRICE
	):
		return false
	coins -= BambooWorks.WORKS_PRICE
	summer.works.repair_step = 1
	return true


func restore_bamboo_workshop() -> bool:
	if area != Area.BAMBOO_WORKS or summer.works.repair_step not in [1, 2, 3] or not arrival.spend_stamina(10):
		return false
	summer.works.repair_step += 1
	return true


func gather_workshop_bamboo(index: int) -> bool:
	if not summer_available(BambooWorks.RESTORE_DAY) or area != Area.VILLAGE or not arrival.tools_taken or index < 0 or index >= 4:
		return false
	var state := summer.works
	var bit := 1 << index
	if (state.grove_day == day and state.grove_mask & bit) or not _spend_outdoor_stamina(10):
		return false
	if state.grove_day != day:
		state.grove_day = day
		state.grove_mask = 0
	state.grove_mask |= bit
	_add_items(LateSummer.STEM, 5)
	if index == 0 and summer_available(AutumnWork.CRAFT_DAY):
		_add_items(LateSummer.RATTAN, 1)
	return true


func batch_limit(product: int) -> int:
	var length := BambooWorks.PRODUCTS.size() if summer.autumn.weave2 else 3
	if product < 0 or product >= length:
		return 0
	var resource := AutumnWork.FINE if product >= 4 else LateSummer.STEM
	var count := floori(float(quantity(resource)) / BambooWorks.MATERIALS[product])
	if product == 5:
		count = mini(count, quantity(LateSummer.RATTAN))
	return mini(BambooWorks.MAX_BATCH, count)


func queue_bamboo_batch(product: int, count: int) -> bool:
	if not can_queue_bamboo() or count < 1 or count > batch_limit(product):
		return false
	var needed: int = BambooWorks.MATERIALS[product] * count
	_add_items(AutumnWork.FINE if product >= 4 else LateSummer.STEM, -needed)
	if product == 5:
		_add_items(LateSummer.RATTAN, -count)
	var state := summer.works
	if state.batch_count > 0:
		state.queued_product = product + 1
		state.queued_count = count
	else:
		state.batch_product = product + 1
		state.batch_count = count
	return true


func can_use_bamboo_machine() -> bool:
	return summer != null and summer.works.ready() and (
		area == Area.BAMBOO_WORKS or (area == Area.STOREHOUSE and summer.autumn.corner_ready())
	)


func can_queue_bamboo() -> bool:
	return can_use_bamboo_machine() and (
		summer.works.batch_count == 0 or (summer.autumn.corner_ready() and summer.works.queued_count == 0)
	)


func collect_bamboo_products() -> bool:
	if not can_use_bamboo_machine():
		return false
	var collected := false
	for index in BambooWorks.PRODUCTS.size():
		var item: String = BambooWorks.PRODUCTS[index]
		var count := mini(summer.works.finished[index], MAX_SAVE_INTEGER - quantity(item))
		if count > 0:
			_add_items(item, count)
			summer.works.finished[index] -= count
			collected = true
	return collected


func manage_workshop_order(discount := false) -> int:
	if not summer_available(BambooWorks.ORDER_DAY) or (
		area != Area.BAMBOO_WORKS and (area != Area.STOREHOUSE or not summer.autumn.corner_ready())
	):
		return 0
	var state := summer.works
	if not state.ready() or not state.county_met:
		return 0
	if state.order_paid:
		return _manage_repeat_order() if not discount else 0
	if state.order_due < day:
		state.order_due = mini(MAX_SAVE_INTEGER, day + 2)
		return 1
	if day < BambooWorks.FIRST_DUE:
		return 0
	_apply_storm_damage()
	var held := quantity(BambooWorks.PRODUCTS[0])
	var state_trade := summer.autumn
	var count := BambooWorks.ORDER_SIZE
	var payout := BambooWorks.ORDER_PAY
	if discount:
		if not state.storm_damage or held < 14:
			return 0
		count = mini(held, BambooWorks.ORDER_SIZE)
		payout = BambooWorks.DAMAGED_PAY
	elif held < count or (state.storm_damage and day == BambooWorks.FIRST_DUE and minute_of_day >= AutumnWork.RUSH_CLOSE):
		return 0
	_add_items(BambooWorks.PRODUCTS[0], -count)
	_earn(payout)
	state.order_paid = true
	state_trade.first_payout = payout
	state_trade.reputation = -5 if discount else 0
	state_trade.favored = not discount and day <= state.order_due
	state_trade.damp_baskets = 0
	state_trade.set_next_order(day)
	return payout


func _manage_repeat_order() -> int:
	var trade := summer.autumn
	if day < trade.repeat_day:
		return 0
	if trade.repeat_due < day:
		trade.repeat_due = mini(MAX_SAVE_INTEGER, day + 3)
		return 1
	var kind := trade.repeat_kind()
	var item: String = AutumnWork.REPEAT_IDS[kind]
	var count: int = AutumnWork.REPEAT_AMOUNTS[kind]
	if quantity(item) < count:
		return 0
	_add_items(item, -count)
	var payout: int = AutumnWork.REPEAT_PAY[kind]
	_earn(payout)
	trade.repeat_count = mini(MAX_SAVE_INTEGER, trade.repeat_count + 1)
	trade.set_next_order(day)
	return payout


func _apply_storm_damage() -> void:
	if not summer.works.storm_damage or summer.autumn.damage_applied:
		return
	var state := summer.works
	var trade := summer.autumn
	trade.damage_applied = true
	if (state.protection & BambooWorks.RAW_TARP) == 0:
		var material := floori(quantity(LateSummer.STEM) * 0.3)
		if material > 0:
			_add_items(LateSummer.STEM, -material)
	if (state.protection & BambooWorks.GOODS_TARP) == 0:
		var item: String = BambooWorks.PRODUCTS[0]
		var spoiled := floori((state.finished[0] + quantity(item)) * 0.3)
		var from_stock := mini(spoiled, state.finished[0])
		state.finished[0] -= from_stock
		if spoiled > from_stock:
			_add_items(item, -(spoiled - from_stock))
		trade.damp_baskets = spoiled


func invest_in_autumn(index: int) -> bool:
	if not summer_available(AutumnWork.INVEST_DAY) or area != Area.HOUSE or index < 0 or index >= AutumnWork.COSTS.size():
		return false
	var state := summer.autumn
	var bit := 1 << index
	var cost: int = AutumnWork.COSTS[index]
	if ((state.pending | state.built) & bit) != 0 or coins < cost:
		return false
	coins -= cost
	state.pending |= bit
	return true


func _apply_autumn_investments() -> void:
	var state := summer.autumn
	if state.pending & 1:
		_add_western_plots()
	if state.pending & 4:
		for crop in CropCatalog.AUTUMN_CROPS:
			_add_items(CropCatalog.CROPS[crop].seed_item, 24)
	state.built |= state.pending
	state.pending = 0


func _add_western_plots() -> void:
	for cell in AutumnWork.WEST:
		plots[cell] = Plot.new()


func has_storehouse() -> bool:
	return summer_available(AutumnWork.WORKROOM_DAY) and (summer.autumn.built & 2) != 0


func build_workroom_corner() -> bool:
	if not has_storehouse() or area != Area.STOREHOUSE or not arrival.tools_taken or summer.autumn.corner_ready():
		return false
	var step := summer.autumn.corner_step
	if day < AutumnWork.WORKROOM_DAY + step:
		return false
	var item: String = AutumnWork.CORNER_ITEMS[step]
	var count: int = AutumnWork.CORNER_COUNTS[step]
	if quantity(item) < count or not arrival.spend_stamina(6):
		return false
	_add_items(item, -count)
	summer.autumn.corner_step += 1
	return true


func warehouse_move(item: String, count: int, deposit: bool) -> bool:
	if area not in [Area.GARDEN, Area.STOREHOUSE] or summer == null or (summer.autumn.built & 2) == 0 or count < 1 or not AutumnWork.can_store(item):
		return false
	var storage := summer.autumn.storage
	var stored: int = storage.get(item, 0)
	if deposit:
		if count > quantity(item) or stored > MAX_SAVE_INTEGER - count or (stored == 0 and storage.size() >= summer.autumn.storage_slots()):
			return false
		_add_items(item, -count)
		storage[item] = stored + count
	else:
		if count > stored or quantity(item) > MAX_SAVE_INTEGER - count:
			return false
		_add_items(item, count)
		if count == stored:
			storage.erase(item)
		else:
			storage[item] = stored - count
	return true


func can_receive_autumn_starter() -> bool:
	return summer_available(AutumnWork.AUTUMN_DAY) and season() == GardenCalendar.Season.AUTUMN and area == Area.VILLAGE and (
		not seed_is_unlocked(CropCatalog.SWEET_POTATO)
	)


func take_autumn_starter() -> bool:
	if not can_receive_autumn_starter():
		return false
	summer.autumn.starter_seeds = true
	for crop in CropCatalog.AUTUMN_CROPS:
		_add_items(CropCatalog.CROPS[crop].seed_item, 2)
	return true


func autumn_beds() -> Vector3i:
	var counts := Vector3i.ZERO
	for cell in plots:
		var plot := plots[cell]
		if plot.crop_id in CropCatalog.AUTUMN_CROPS:
			counts.x += 1
			if nights_until_ripe(plot) == 0:
				counts.z += 1
			elif not is_plot_wet(plot, cell) and not is_flooded(cell):
				counts.y += 1
	return counts


func monsoon_forecast() -> bool:
	return summer_available(AutumnWork.WORKROOM_FINISH) and day < AutumnWork.RAIN_START


func autumn_soil_available(cell: Vector2i) -> bool:
	return summer_available(AutumnWork.SOIL_DAY) and area == Area.GARDEN and arrival.tools_taken and plots.has(cell) and (
		cell not in SummerProgress.HEIRLOOM_PADDY and not plot_has_weeds(cell) and not summer.late.has_stubble(cell) and plots[cell].crop_id.is_empty()
	)


func prepare_autumn_soil(cell: Vector2i) -> int:
	if not autumn_soil_available(cell):
		return 0
	var plot := plots[cell]
	if not plot.loosened:
		if not _spend_outdoor_stamina(_base_action_cost(PlotAction.HOE)):
			return 0
		plot.tilled = true
		plot.loosened = true
		return 1
	if plot.fertile or quantity(LateSummer.HERBS) == 0:
		return 0
	_add_items(LateSummer.HERBS, -1)
	plot.fertile = true
	return 2


func prepared_autumn_count() -> int:
	var count := 0
	for plot in plots.values():
		if plot.loosened and plot.fertile:
			count += 1
	return count


func ripen_autumn_plot(cell: Vector2i) -> bool:
	var plot := plots[cell]
	if not plot.fertile or plot.crop_id not in CropCatalog.AUTUMN_CROPS or nights_until_ripe(plot) != 1:
		return false
	var nights: int = CropCatalog.CROPS[plot.crop_id].growth_nights
	var ready_at := GardenCalendar.START_MINUTE + 24 * 60 - nights * 144
	if minute_of_day < ready_at or has_pest(cell) or is_flooded(cell) or not is_plot_wet(plot, cell):
		return false
	plot.watered_nights = nights
	plot.watered = false
	plot.watered_twice = false
	plot.fertilized = false
	return true


func learn_fine_weaving() -> bool:
	if not summer_available(AutumnWork.CRAFT_DAY) or area != Area.BAMBOO_WORKS or not summer.works.ready() or summer.autumn.weave2:
		return false
	if day == AutumnWork.CRAFT_DAY and minute_of_day < AutumnWork.LESSON_HOUR:
		return false
	summer.autumn.weave2 = true
	_add_items(AutumnWork.FINE, 6)
	_add_items(LateSummer.RATTAN, 1)
	return true


func can_weave_fine(product: int) -> bool:
	return summer != null and area == Area.BAMBOO_WORKS and summer.autumn.weave2 and product >= 0 and product < AutumnWork.WEAVES.size() and (
		quantity(AutumnWork.FINE) >= AutumnWork.WEAVE_COST[product] and (product != 1 or quantity(LateSummer.RATTAN) >= 1)
	)


func finish_fine_weave(product: int, rank: int) -> bool:
	if not can_weave_fine(product) or rank < 0 or rank >= AutumnWork.RANKS.size():
		return false
	_add_items(AutumnWork.FINE, -AutumnWork.WEAVE_COST[product])
	if product == 1:
		_add_items(LateSummer.RATTAN, -1)
		if summer.autumn.first_bag == 0:
			summer.autumn.first_bag = rank + 1
			summer.autumn.hai_points = 20
	_add_items(AutumnWork.woven_id(product, rank), 1)
	return true


func learn_advanced_embroidery() -> bool:
	if not summer_available(AutumnWork.CRAFT_DAY) or area != Area.VILLAGE or not summer.craft.embroidery or (
		summer.social.minh_points < 45 or summer.autumn.embroidery2
	):
		return false
	summer.autumn.embroidery2 = true
	return true


func finish_advanced_embroidery(motif: int) -> bool:
	if area not in [Area.HOUSE, Area.VILLAGE] or not summer.autumn.embroidery2 or motif < 0 or motif >= AutumnWork.MOTIFS.size() or (
		quantity(SummerCraft.CLOTH) < 1 or quantity(VillageSocial.THREAD) < 1
	):
		return false
	_add_items(SummerCraft.CLOTH, -1)
	_add_items(VillageSocial.THREAD, -1)
	_add_items(AutumnWork.EMBROIDERED[motif], 1)
	return true


func start_summer_storm() -> bool:
	if not summer_available(BambooWorks.STORM_DAY) or day != BambooWorks.STORM_DAY or (
		minute_of_day < BambooWorks.STORM_HOUR or summer.works.storm_started
	):
		return false
	summer.works.storm_started = true
	summer.works.storm_left = BambooWorks.STORM_SECONDS
	return true


func storm_active() -> bool:
	return summer != null and summer.works.storm_left > 0


func advance_workshop_seconds(seconds: int) -> bool:
	if summer == null or seconds <= 0:
		return false
	var state := summer.works
	var changed := state.advance_batch(seconds, day)
	if state.storm_left > 0:
		state.storm_left = maxi(0, state.storm_left - seconds)
		if state.storm_left == 0:
			state.resolve_storm()
			_apply_storm_damage()
		changed = true
	return changed


func can_protect_from_storm(bit: int) -> bool:
	if bit == BambooWorks.DOOR:
		return day == BambooWorks.STORM_DAY and summer != null and summer.works.storm_started and (
			area == Area.HOUSE and (summer.works.protection & bit) == 0
		)
	if not storm_active() or summer.works.protection & bit:
		return false
	match bit:
		BambooWorks.RAW_TARP, BambooWorks.GOODS_TARP:
			return area == Area.BAMBOO_WORKS and summer.works.repair_step > 0
		BambooWorks.COOP_TARP:
			return area == Area.GARDEN
	return false


func protect_from_storm(bit: int) -> bool:
	if not can_protect_from_storm(bit):
		return false
	summer.works.protection |= bit
	return true


func walk_in_storm() -> bool:
	if not storm_active():
		return true
	var state := summer.works
	var next := state.wind_steps + 1
	# Exposed terrain costs three stamina per eight steps during the gusts.
	var cost := floori(next * 3 / 8.0) - floori(state.wind_steps * 3 / 8.0)
	if cost > 0 and not arrival.spend_stamina(cost):
		return false
	state.wind_steps = next % 8
	return true


func draw_recovery_water(auxiliary: bool) -> bool:
	if not summer_available(LateSummer.RECOVERY) or area != Area.GARDEN or not arrival.tools_taken:
		return false
	if auxiliary and summer.drought.well_step < 4:
		return false
	var state := summer.late
	if state.water == 6 or not _spend_outdoor_stamina(2 if auxiliary else 5):
		return false
	state.water = mini(6, state.water + (3 if auxiliary else 2))
	return true


func take_recovery_herbs() -> bool:
	if not summer_available(LateSummer.RECOVERY) or area != Area.GARDEN or summer.late.herbs_day == day:
		return false
	summer.late.herbs_day = day
	_add_items(LateSummer.HERBS, 3)
	return true


func dress_summer_plot(cell: Vector2i) -> bool:
	if not summer_available(LateSummer.RECOVERY) or area != Area.GARDEN or not plots.has(cell):
		return false
	var plot := plots[cell]
	var state := summer.late
	if plot.crop_id not in CropCatalog.SUMMER_CROPS or nights_until_ripe(plot) == 0 or is_flooded(cell) or (
		has_pest(cell) or state.water == 0 or quantity(LateSummer.HERBS) == 0 or plot.fertilized
	):
		return false
	_add_items(LateSummer.HERBS, -1)
	state.water -= 1
	state.fertilized_count = mini(3, state.fertilized_count + 1)
	plot.drought_stress = 0
	plot.watered = true
	plot.fertilized = true
	plot.watered_nights = int(CropCatalog.CROPS[plot.crop_id].growth_nights) - 1
	return true


func accept_lotus_trip() -> bool:
	if not summer_available(LateSummer.LOTUS_DAY) or area != Area.VILLAGE or summer.late.lotus_invited:
		return false
	summer.late.lotus_invited = true
	return true


func gather_lotus(index: int) -> bool:
	if area != Area.LOTUS_POND or not summer.late.lotus_invited or index < 0 or index >= 15:
		return false
	var state := summer.late
	if state.lotus_day != day:
		state.lotus_day = day
		state.lotus_mask = 0
	if state.lotus_mask & (1 << index):
		return false
	state.lotus_mask |= 1 << index
	_add_items(LateSummer.POD if index < 10 else LateSummer.LEAF, 1)
	return true


func deliver_lotus() -> bool:
	if not summer_available(LateSummer.LOTUS_DAY) or area != Area.VILLAGE or (
		not summer.late.lotus_invited or summer.late.lotus_done or quantity(LateSummer.POD) < 10 or quantity(LateSummer.LEAF) < 5
	):
		return false
	_add_items(LateSummer.POD, -10)
	_add_items(LateSummer.LEAF, -5)
	_add_items(LateSummer.TEA, 1)
	summer.late.lotus_done = true
	return true


func cook_lotus_dessert() -> bool:
	if area != Area.HOUSE or not summer.late.lotus_done or quantity(LateSummer.POD) < 2:
		return false
	_add_items(LateSummer.POD, -2)
	restore_stamina(40)
	arrival.meal_bonus = -1
	return true


func cut_river_bamboo(index: int) -> bool:
	if not summer_available(LateSummer.BASKET_DAY) or area != Area.VILLAGE or not arrival.tools_taken or index not in [0, 1]:
		return false
	var shift := index * 3
	var hits := (summer.late.bamboo_hits >> shift) & 7
	if hits >= 3 or not _spend_outdoor_stamina(10):
		return false
	summer.late.bamboo_hits += 1 << shift
	if hits == 2:
		_add_items(LateSummer.STEM, 3)
	return true


func collect_rattan(index: int) -> bool:
	if not summer_available(LateSummer.BASKET_DAY) or area != Area.VILLAGE or index < 0 or index >= 3 or (
		summer.late.rattan_mask & (1 << index)
	):
		return false
	summer.late.rattan_mask |= 1 << index
	_add_items(LateSummer.RATTAN, 1)
	return true


func can_weave_cargo_baskets() -> bool:
	return summer_available(LateSummer.BASKET_DAY) and area == Area.VILLAGE and summer.late.basket_score < 0 and (
		quantity(LateSummer.STEM) >= 6 and quantity(LateSummer.RATTAN) >= 3
	)


func weave_cargo_baskets(score: int) -> bool:
	if not can_weave_cargo_baskets() or score < 0 or score > 6:
		return false
	_add_items(LateSummer.STEM, -6)
	_add_items(LateSummer.RATTAN, -3)
	summer.late.basket_score = score
	return true


func accept_harvest_hat() -> bool:
	if not summer_available(LateSummer.HARVEST) or area != Area.GARDEN or summer.late.hat or (
		day == LateSummer.HARVEST and minute_of_day < 17 * 60
	):
		return false
	summer.late.hat = true
	return true


func pack_harvest(item: String) -> bool:
	if not summer_available(LateSummer.HARVEST) or area != Area.GARDEN or summer.late.basket_score < 0 or item not in LateSummer.GOODS:
		return false
	var state := summer.late
	var count := mini(quantity(item), LateSummer.SLOTS - state.slots_used())
	if count == 0:
		return false
	_add_items(item, -count)
	state.cargo[item] = state.cargo.get(item, 0) + count
	return true


func unpack_harvest() -> bool:
	if not summer_available(LateSummer.HARVEST) or area != Area.GARDEN or summer.late.cargo.is_empty():
		return false
	for item in summer.late.cargo:
		_add_items(item, summer.late.cargo[item])
	summer.late.cargo.clear()
	return true


func buy_ferry_trip() -> bool:
	if not summer_available(LateSummer.FIRST_FAIR) or area != Area.VILLAGE or not LateSummer.fair_day(day) or (
		minute_of_day >= GardenCalendar.MARKET_CLOSE or coins < LateSummer.FARE
	):
		return false
	var state := summer.late
	if not state.cargo.is_empty():
		if state.basket_wear >= state.basket_score + 2:
			return false
		state.basket_wear += 1
	coins -= LateSummer.FARE
	minute_of_day = maxi(minute_of_day, GardenCalendar.START_MINUTE)
	return true


func sell_county_goods(item: String) -> int:
	if area != Area.COUNTY_FAIR or not LateSummer.fair_day(day) or minute_of_day >= GardenCalendar.MARKET_CLOSE:
		return 0
	var state := summer.late
	var price := county_crop_price(item)
	var count: int = state.cargo.get(item, 0) * LateSummer.LOT_SIZE
	if price == 0 or count == 0:
		return 0
	state.cargo.erase(item)
	match item.trim_suffix(LateSummer.PREMIUM):
		"winter_melon_produce": state.melon_sold = mini(LateSummer.MELON_TARGET, state.melon_sold + count)
		"corn_produce": state.corn_sold = mini(LateSummer.CORN_TARGET, state.corn_sold + count)
	_earn(price * count)
	return price * count


func county_crop_price(item: String) -> int:
	return _preferred_price(LateSummer.fair_price(day, item))


func _preferred_price(price: int) -> int:
	return roundi(price * 1.1) if summer_available(AutumnWork.FAVOR_DAY) and summer.autumn.favored and summer.autumn.repeat_count > 0 else price


func buy_autumn_seed(crop_id: String) -> bool:
	if area != Area.COUNTY_FAIR or not LateSummer.fair_day(day) or minute_of_day >= GardenCalendar.MARKET_CLOSE or (
		crop_id not in CropCatalog.AUTUMN_CROPS or not seed_is_unlocked(crop_id)
	):
		return false
	var crop: Dictionary = CropCatalog.CROPS[crop_id]
	if coins < int(crop.buy_price):
		return false
	coins -= int(crop.buy_price)
	_add_items(crop.seed_item, 1)
	return true


func _fill_drought_well() -> void:
	var drought := summer.drought
	var daily: int = [18, 16, 15, 14, 12][day - DroughtProgress.FIRST]
	drought.supply = daily + (5 if summer.craft.jar else 0) + (8 if drought.well_step == 4 else 0)
	if drought.share_choice == 1:
		drought.supply -= 2


func choose_water_share(choice: int) -> bool:
	if not summer_available(DroughtProgress.SHARE_DAY) or area != Area.VILLAGE or not in_drought() or choice not in [1, 2]:
		return false
	var drought := summer.drought
	if drought.share_choice != 0 or (choice == 1 and drought.supply < 2):
		return false
	drought.share_choice = choice
	if choice == 1:
		drought.supply -= 2
		summer.festival.reputation += 15
	return true


func learn_auxiliary_well() -> bool:
	if not summer_available(DroughtProgress.SHARE_DAY) or area != Area.VILLAGE or summer.drought.learned_well:
		return false
	summer.drought.learned_well = true
	return true


func build_auxiliary_well() -> bool:
	if not summer_available(DroughtProgress.DIG_DAY) or area != Area.GARDEN or not arrival.tools_taken:
		return false
	var drought := summer.drought
	if not drought.learned_well or drought.well_step == 4:
		return false
	match drought.well_step:
		0, 1:
			if not _spend_outdoor_stamina(20 if drought.well_step == 0 else 30):
				return false
		2:
			if quantity(SummerProgress.WOOD) < DroughtProgress.WOOD:
				return false
			_add_items(SummerProgress.WOOD, -DroughtProgress.WOOD)
		3:
			if quantity(DroughtProgress.ROPE) == 0:
				return false
			_add_items(DroughtProgress.ROPE, -1)
			if in_drought():
				drought.supply = mini(80, drought.supply + 8)
	drought.well_step += 1
	return true


func order_drought_oil() -> bool:
	if not in_drought() or day < DroughtProgress.OIL_DAY or area != Area.HOUSE:
		return false
	var drought := summer.drought
	if drought.delivery == day or drought.oil > 0 or summer.sprinkler < 0:
		return false
	drought.delivery = day
	return true


func buy_drought_supply(item: String) -> bool:
	if not summer_available(DroughtProgress.OIL_DAY) or (item != DroughtProgress.ROPE and not in_drought()):
		return false
	var drought := summer.drought
	var price: int
	match item:
		"tuan":
			if area != Area.GARDEN or drought.delivery != day or minute_of_day < 12 * 60 or drought.oil > 0:
				return false
			price = DroughtProgress.OIL_TUAN
		"thanh":
			if area != Area.VILLAGE or not GardenCalendar.shop_is_open(minute_of_day) or drought.oil > 0:
				return false
			price = DroughtProgress.OIL_THANH
		"water":
			if area != Area.VILLAGE or not GardenCalendar.shop_is_open(minute_of_day) or drought.supply > 74:
				return false
			price = DroughtProgress.WATER_PRICE
		DroughtProgress.ROPE:
			if area != Area.VILLAGE or not GardenCalendar.shop_is_open(minute_of_day) or quantity(item) > 0 or drought.well_step == 4:
				return false
			price = DroughtProgress.ROPE_PRICE
		_:
			return false
	if coins < price:
		return false
	coins -= price
	drought.spent += price
	match item:
		"tuan", "thanh":
			drought.oil = 4
			drought.delivery = 0
		"water":
			drought.supply += 6
		DroughtProgress.ROPE:
			_add_items(item, 1)
	return true


func take_ly_water() -> bool:
	if not in_drought() or day != DroughtProgress.LAST or summer.drought.ly_help or summer.drought.well_step == 4 or area != Area.GARDEN:
		return false
	summer.drought.ly_help = true
	summer.drought.supply = mini(80, summer.drought.supply + 3)
	return true


func water_hens() -> bool:
	if not in_drought() or area != Area.GARDEN or arrival.hen < ArrivalProgress.Hen.FED:
		return false
	var drought := summer.drought
	if drought.supply == 0 or drought.chicken_water == 2 or (drought.chicken_water == 1 and minute_of_day < DroughtProgress.SECOND_PASS):
		return false
	drought.supply -= 1
	drought.chicken_water += 1
	return true


func _spend_outdoor_stamina(cost: int) -> bool:
	var discounted := _hat_discount(cost)
	if not arrival.spend_stamina(discounted):
		return false
	if summer.late.hat and not is_raining(day):
		summer.late.hat_remainder = (summer.late.hat_remainder + cost) % 10
	if in_drought():
		summer.drought.stamina_spent += discounted
	return true


func _hat_discount(cost: int) -> int:
	if summer == null or not summer.late.hat or is_raining(day):
		return cost
	return maxi(1, cost - floori((cost + summer.late.hat_remainder) / 10.0)) if cost > 0 else 0


func drought_summary() -> String:
	var drought := summer.drought
	return "Cây khô chết: %d · Cây héo nặng: %d\nĐêm gà thiếu nước: %d · %d xu · %d thể lực\n%s" % [
		drought.lost, drought.stunted, drought.dry_hen_days, drought.spent, drought.stamina_spent,
		"Giếng phụ giữ lại làm nguồn dự phòng." if drought.well_step == 4 else "Vẫn có thể đào giếng phụ sau đợt hạn.",
	]


func stamina_cap() -> int:
	return summer.social.stamina_cap(day) + (5 if summer.autumn.training_bonus else 0) if summer != null else ArrivalProgress.MAX_STAMINA


func visit_chief() -> String:
	if not summer_available(VillageSocial.AFTER_FAIR_DAY) or summer.social.chief_met:
		return ""
	summer.social.chief_met = true
	if summer.festival.contest >= 1 and summer.festival.contest_score >= 90:
		return "Bà Chín còn nhắc món cháu nấu. Bà bảo ăn là biết đồ mới hái."
	if summer.social.wrestled:
		return "Cháu dám bước vào sới với Thắng. Hôm qua cả sân vỗ tay đấy."
	if summer.festival.lantern or summer.festival.contest > 0 or summer.festival.registered:
		return "Lần đầu dự hội mà quen được đường là tốt rồi. Năm sau lại ra đình nhé."
	return "Hội năm sau ra sân chơi với mọi người nhé. Đứng xem một lát cũng vui."


func meet_minh() -> bool:
	if not summer_available(VillageSocial.NEIGHBORS_DAY) or summer.social.minh_points != 20:
		return false
	summer.social.minh_points += 10
	return true


func meet_tuan() -> bool:
	if not summer_available(VillageSocial.NEIGHBORS_DAY) or summer.social.tuan_points != 15:
		return false
	summer.social.tuan_points = 20
	return true


func book_tuan_ride(destination: Area) -> bool:
	if not summer_available(VillageSocial.NEIGHBORS_DAY) or summer.social.tuan_points < 20 or coins < VillageSocial.RIDE_PRICE:
		return false
	if not GardenCalendar.shop_is_open(minute_of_day) or not GardenCalendar.shop_is_open(minute_of_day + VillageSocial.RIDE_STEPS * GardenCalendar.STEP_MINUTES):
		return false
	if (area != Area.VILLAGE or destination != Area.DISTRICT) and (area != Area.DISTRICT or destination != Area.VILLAGE):
		return false
	if destination == Area.DISTRICT and (not can_visit_district() or not district_ride_day()):
		return false
	coins -= VillageSocial.RIDE_PRICE
	advance_clock(VillageSocial.RIDE_STEPS)
	return true


func district_ride_day() -> bool:
	return day <= SummerCraft.TRIP_DAY or summer.craft.trip_reply == 0 or GardenCalendar.weekday_index(day) in [1, 5]


func record_tuan_trip(reply: int) -> bool:
	if not summer_available(SummerCraft.TRIP_DAY) or area != Area.DISTRICT or summer.craft.trip_reply > 0 or reply not in [1, 2]:
		return false
	summer.craft.trip_reply = reply
	return true


func buy_craft_supply(item: String) -> bool:
	if not summer_available(SummerCraft.TRIP_DAY) or area != Area.DISTRICT or not GardenCalendar.shop_is_open(minute_of_day):
		return false
	var craft := summer.craft
	var price: int
	match item:
		"bun":
			if craft.bun_day == day:
				return false
			price = SummerCraft.HUNGER_PRICE
		"jar":
			if day < SummerCraft.HEAT_HINT_DAY or craft.jar:
				return false
			price = SummerCraft.JAR_PRICE
		"tank":
			if craft.tank:
				return false
			price = SummerCraft.TANK_PRICE
		SummerCraft.CLOTH:
			if day < SummerCraft.EMBROIDERY_DAY:
				return false
			price = SummerCraft.CLOTH_PRICE
		VillageSocial.THREAD:
			if day < SummerCraft.EMBROIDERY_DAY:
				return false
			price = SummerCraft.THREAD_PRICE
		_:
			return false
	if coins < price:
		return false
	coins -= price
	if item == "bun":
		craft.huong_met = true
		craft.bun_day = day
	elif item in ["jar", "tank"]:
		craft.set(item, true)
	else:
		_add_items(item, 1)
	return true


func start_embroidery() -> bool:
	if not summer_available(SummerCraft.EMBROIDERY_DAY) or summer.social.minh_points < 40 or not summer.social.scarf_found:
		return false
	if area not in [Area.HOUSE, Area.VILLAGE] or (area == Area.HOUSE and not summer.craft.needle):
		return false
	if not summer.craft.needle:
		summer.craft.needle = true
		_add_items(SummerCraft.CLOTH, 1)
	return true


func finish_embroidery(pattern: String, flower: bool) -> bool:
	if not summer_available(SummerCraft.EMBROIDERY_DAY) or not summer.craft.needle or not SummerCraft.valid_pattern(pattern):
		return false
	if area not in [Area.HOUSE, Area.VILLAGE]:
		return false
	if flower and not summer.craft.embroidery:
		return false
	if quantity(SummerCraft.CLOTH) < 1 or quantity(VillageSocial.THREAD) < 1:
		return false
	if not flower and summer.craft.embroidery:
		return false
	_add_items(SummerCraft.CLOTH, -1)
	_add_items(VillageSocial.THREAD, -1)
	if flower:
		_add_items(SummerCraft.FLOWER_SCARF, 1)
	else:
		summer.craft.first_pattern = pattern
		summer.craft.embroidery = true
		_add_items(SummerCraft.FIRST_STITCH, 1)
	return true


func record_lan_choice(choice: int) -> bool:
	if not summer_available(SummerCraft.LAN_DAY) or area != Area.HOUSE or choice < 1 or choice > 3 or summer.craft.lan_choice != 0:
		return false
	if day == SummerCraft.LAN_DAY and minute_of_day < 12 * 60 + 30:
		return false
	summer.craft.lan_choice = choice
	return true


func listen_to_lan(choice: int) -> bool:
	if not summer_available(SummerCraft.LAN_DAY) or area != Area.HOUSE or choice not in [1, 2]:
		return false
	if summer.craft.lan_choice == 0 or summer.craft.lan_reply != 0:
		return false
	summer.craft.lan_reply = choice
	return true


func embroidery_order_action() -> bool:
	if not summer_available(SummerCraft.ORDER_DAY) or area != Area.VILLAGE or not summer.craft.embroidery:
		return false
	var craft := summer.craft
	if craft.order_done:
		if day < craft.next_order_day:
			return false
		if craft.repeat_deadline == 0 or day > craft.repeat_deadline:
			craft.repeat_deadline = day + 7
			return true
		if quantity(SummerCraft.FLOWER_SCARF) < 5:
			return false
		_add_items(SummerCraft.FLOWER_SCARF, -5)
		_earn(250)
		craft.repeat_deadline = 0
		craft.next_order_day = day + 7
		return true
	if craft.order_deadline == 0:
		craft.order_deadline = day + 5
		return true
	if quantity(SummerCraft.FLOWER_SCARF) < SummerCraft.ORDER_COUNT:
		if day >= craft.order_deadline and not craft.order_extended:
			craft.order_deadline += 2
			craft.order_extended = true
			return true
		return false
	_add_items(SummerCraft.FLOWER_SCARF, -SummerCraft.ORDER_COUNT)
	_earn(SummerCraft.ORDER_REWARD)
	craft.order_done = true
	craft.next_order_day = day + 7
	return true


func introduce_buyer() -> bool:
	if not summer_available(SummerCraft.BUYER_DAY) or area != Area.DISTRICT or summer.craft.buyer_met:
		return false
	summer.craft.buyer_met = true
	_add_items(SummerCraft.BUYER_CARD, 1)
	return true


func pond_fish() -> String:
	return FishCatalog.GOLDFISH if minute_of_day >= 16 * 60 else FishCatalog.LOTUS_CARP


func finish_lotus_fishing(species: String) -> bool:
	if not summer_available(SummerCraft.LOTUS_DAY) or area != Area.GARDEN or minute_of_day >= GardenCalendar.LAST_MINUTE:
		return false
	if not species.is_empty() and species != pond_fish():
		return false
	if not species.is_empty():
		summer.craft.lotus_caught = true
		_add_items(species, 1)
	return advance_clock(FishCatalog.CAST_CLOCK_STEPS)


func stock_aquarium() -> bool:
	if summer == null or area != Area.HOUSE or not summer.craft.tank or summer.craft.tank_fish or quantity(FishCatalog.GOLDFISH) == 0:
		return false
	_add_items(FishCatalog.GOLDFISH, -1)
	summer.craft.tank_fish = true
	return true


func unlock_training() -> bool:
	if not summer_available(VillageSocial.AFTER_FAIR_DAY) or not summer.festival.wrestling or summer.social.training_invited:
		return false
	summer.social.training_invited = true
	summer.social.wake_early = true
	return true


func can_train() -> bool:
	return summer_available(VillageSocial.TRAINING_DAY) and summer.social.training_invited and (
		area == Area.VILLAGE and minute_of_day >= VillageSocial.EARLY_WAKE and minute_of_day < GardenCalendar.START_MINUTE
		and summer.social.training_day != day
	)


func finish_training() -> bool:
	if not can_train():
		return false
	var social := summer.social
	var old_cap := stamina_cap()
	if not social.training_reward:
		social.streak = social.streak + 1 if social.training_day == day - 1 else 1
		social.training_reward = social.streak == 7
	elif not summer.autumn.training_bonus:
		var state := summer.autumn
		state.second_streak = mini(7, state.second_streak + 1) if social.training_day == day - 1 else 1
		state.training_bonus = day >= AutumnWork.REST_DAY and state.second_streak == 7
	social.training_day = day
	restore_stamina(stamina_cap() - old_cap)
	return true


func boss_message_ready() -> bool:
	return summer_available(VillageSocial.MESSAGE_DAY) and (
		day > VillageSocial.MESSAGE_DAY or minute_of_day >= 12 * 60
	)


func answer_boss(reply: int) -> bool:
	if not boss_message_ready() or area != Area.HOUSE or summer.social.boss_reply != 0 or reply < 1 or reply > VillageSocial.RESPONSES.size():
		return false
	summer.social.boss_reply = reply
	return true


func hear_minh_story(choice: int) -> bool:
	if not summer_available(VillageSocial.SCARF_DAY) or area != Area.VILLAGE or summer.social.minh_story != 0 or choice not in [1, 2]:
		return false
	if day == VillageSocial.SCARF_DAY and minute_of_day < 14 * 60:
		return false
	meet_minh()
	summer.social.minh_story = choice
	summer.social.minh_points += 10 if choice == 1 else 8
	return true


func find_embroidered_scarf() -> bool:
	if not summer_available(VillageSocial.SCARF_DAY) or area != Area.HOUSE or summer.social.minh_story == 0 or summer.social.scarf_found:
		return false
	summer.social.scarf_found = true
	_add_items(VillageSocial.SCARF, 1)
	_add_items(VillageSocial.THREAD, 3)
	return true


func show_minh_scarf(reply: int) -> bool:
	if not summer_available(VillageSocial.SCARF_DAY) or area != Area.VILLAGE or quantity(VillageSocial.SCARF) == 0 or summer.social.scarf_reply != 0 or reply not in [1, 2]:
		return false
	summer.social.scarf_reply = reply
	summer.social.minh_points += 20 if reply == 1 else 15
	return true


func egg_order_action() -> bool:
	if not summer_available(VillageFestival.ORDER_DAY) or area != Area.VILLAGE or summer.festival.egg_order_done:
		return false
	var fair := summer.festival
	if fair.egg_deadline < day:
		fair.egg_deadline = day + 4
		return true
	if quantity(ArrivalProgress.EGG) < VillageFestival.EGG_ORDER_COUNT:
		return false
	_add_items(ArrivalProgress.EGG, -VillageFestival.EGG_ORDER_COUNT)
	_earn(VillageFestival.EGG_ORDER_REWARD)
	fair.egg_order_done = true
	return true


func grind_bran() -> bool:
	if not summer_available(VillageFestival.ORDER_DAY) or area != Area.HOUSE or not summer.chick:
		return false
	var fair := summer.festival
	if fair.mill_day == day or fair.chick_joined or not arrival.spend_stamina(3):
		return false
	fair.mill_day = day
	_add_items(VillageFestival.BRAN, 2)
	return true


func care_for_chick(action: String) -> bool:
	if summer == null or not summer.chick or area != Area.GARDEN:
		return false
	var fair := summer.festival
	if fair.chick_joined:
		return false
	match action:
		"divide":
			if fair.chick_divider or quantity(SummerProgress.BAMBOO) < 2:
				return false
			_add_items(SummerProgress.BAMBOO, -2)
			fair.chick_divider = true
		"straw":
			if fair.chick_straw or quantity(SummerProgress.STRAW) < 1:
				return false
			_add_items(SummerProgress.STRAW, -1)
			fair.chick_straw = true
		"feed":
			if fair.chick_fed or quantity(VillageFestival.BRAN) < 1:
				return false
			_add_items(VillageFestival.BRAN, -1)
			fair.chick_fed = true
		"join":
			if fair.chick_age < 3:
				return false
			if fair.chick_divider:
				_add_items(SummerProgress.BAMBOO, 2)
				fair.chick_divider = false
			fair.chick_joined = true
		_:
			return false
	return true


func name_chick(value: String) -> bool:
	if summer == null or not summer.chick:
		return false
	var name := value.strip_edges().left(VillageFestival.NAME_LIMIT)
	if name.is_empty():
		return false
	summer.festival.chick_named = name
	return true


func forage_festival(index: int) -> bool:
	if not summer_available(VillageFestival.PREP_DAY) or day > VillageFestival.FAIR_DAY or area != Area.GARDEN:
		return false
	var items := [VillageFestival.MUNG, VillageFestival.GINGER, VillageFestival.SNAIL, VillageFestival.MUSHROOM]
	if index < 0 or index >= items.size() or (summer.festival.gather_mask & (1 << index)) != 0:
		return false
	summer.festival.gather_mask |= 1 << index
	_add_items(items[index], 1)
	return true


func festival_ingredients(dish: int) -> Array[String]:
	var ingredients: Array[String] = []
	match dish:
		0:
			return cooking_ingredients(0)
		1:
			ingredients = ["sticky_rice_produce", VillageFestival.MUNG]
		2:
			for crop in CropCatalog.CROPS.values():
				var item: String = crop.produce_item
				if quantity(item) > int(item == FIRST_PRODUCE and not tutorial_completed):
					return [VillageFestival.SNAIL, VillageFestival.MUSHROOM, item]
		3:
			ingredients = [ArrivalProgress.EGG, SummerProgress.RICE_BAG, VillageFestival.GINGER]
	return ingredients


func prepare_festival_dish(dish: int) -> bool:
	if not summer_available(VillageFestival.PREP_DAY) or day > VillageFestival.FAIR_DAY:
		return false
	if area not in [Area.HOUSE, Area.FESTIVAL] or summer.festival.contest != 0:
		return false
	var ingredients := festival_ingredients(dish)
	if ingredients.is_empty():
		return false
	for item in ingredients:
		if quantity(item) <= 0:
			return false
	summer.festival.prepared_dish = dish
	return true


func submit_festival_dish(dish: int, plating: int) -> bool:
	if area != Area.FESTIVAL or not festival_day() or minute_of_day < VillageFestival.OPEN or minute_of_day >= VillageFestival.CLOSE:
		return false
	if plating < 0 or plating > 2 or not prepare_festival_dish(dish):
		return false
	for item in festival_ingredients(dish):
		_add_items(item, -1)
	var fair := summer.festival
	fair.contest = 1
	fair.contest_score = VillageFestival.DISH_SCORES[dish] + [3, 10, 6][plating]
	fair.judging_minute = minute_of_day + 30
	return true


func collect_festival_result() -> bool:
	if not festival_day() or summer.festival.contest != 1 or minute_of_day < summer.festival.judging_minute:
		return false
	var fair := summer.festival
	fair.contest = 2
	fair.reputation += 30 if fair.contest_score >= 90 else (15 if fair.contest_score >= 75 else 5)
	return true


func finish_wrestling(wins: int) -> bool:
	if not festival_day() or area != Area.FESTIVAL or wins != 3 or summer.festival.wrestling:
		return false
	summer.festival.wrestling = true
	summer.festival.reputation += 10
	return true


func festival_day() -> bool:
	return summer != null and day == VillageFestival.FAIR_DAY


func release_lantern() -> bool:
	if not festival_day() or area != Area.FESTIVAL or minute_of_day < VillageFestival.LANTERN_HOUR or summer.festival.lantern:
		return false
	summer.festival.lantern = true
	summer.festival.lan_points += 15
	return true


func load_cart() -> bool:
	if not summer_available(SummerProgress.FIRST_DAY) or area != Area.GARDEN or not tutorial_completed:
		return false
	if summer.cart_loaded or not has_wholesale_goods():
		return false
	for item in packed_tutorial_goods:
		_add_items(item, packed_tutorial_goods[item])
	packed_tutorial_goods.clear()
	summer.cart_loaded = true
	return true


func buy_market_supply(item: String) -> bool:
	if not summer_available(SummerProgress.FIRST_DAY) or (area != Area.DISTRICT and not village_wholesale_market()) or not GardenCalendar.shop_is_open(minute_of_day):
		return false
	var price: int
	match item:
		"iron_hoe":
			if summer.iron_hoe:
				return false
			price = SummerProgress.IRON_HOE_PRICE
		"sharp_sickle":
			if summer.sharp_sickle:
				return false
			price = SummerProgress.SICKLE_PRICE
		SummerProgress.FERTILIZER:
			if day < SummerProgress.WEAVE_DAY and not village_wholesale_market():
				return false
			price = SummerProgress.FERTILIZER_PRICE
		SummerProgress.NAIL:
			if day < SummerProgress.BUILD_DAY and not village_wholesale_market():
				return false
			price = market_nail_price()
		_:
			return false
	if coins < price:
		return false
	coins -= price
	if item in [SummerProgress.FERTILIZER, SummerProgress.NAIL]:
		_add_items(item, 1)
	else:
		summer.set(item, true)
	return true


func market_nail_price() -> int:
	return 50 if village_wholesale_market() else SummerProgress.NAIL_PRICE


func stock_story_tank() -> bool:
	if summer_story == null or not summer_story.purchases.has("tank") or summer_story.done("goby_tank") or quantity(FishCatalog.GOBY) == 0:
		return false
	_add_items(FishCatalog.GOBY, -1)
	summer_story.mark("goby_tank")
	return true


func read_heirloom_letter() -> bool:
	if not summer_available(SummerProgress.LETTER_DAY) or summer.read_letter:
		return false
	if summer_story != null and day == SummerProgress.LETTER_DAY and minute_of_day < 8 * 60:
		return false
	summer.read_letter = true
	return true


func receive_heirlooms() -> bool:
	if not summer_available(SummerProgress.LETTER_DAY) or not summer.read_letter or summer.received_heirlooms:
		return false
	if summer_story != null and day == SummerProgress.LETTER_DAY and minute_of_day < int(SummerProgress.VISIT_WINDOWS[SummerProgress.LETTER_DAY]):
		return false
	summer.received_heirlooms = true
	_add_items(CropCatalog.CROPS[CropCatalog.HEIRLOOM_CARROT].seed_item, 10)
	_add_items(CropCatalog.CROPS[CropCatalog.STICKY_RICE].seed_item, 8)
	_add_items(SummerProgress.ROOT_STOCK, 3)
	if summer_story == null:
		_add_inherited_plots()
	return true


func _add_inherited_plots() -> void:
	for cell in SummerProgress.HEIRLOOM_CELLS:
		var plot := Plot.new()
		plot.tilled = cell in SummerProgress.HEIRLOOM_PADDY
		plots[cell] = plot


func cook_family_meal(preferred := "") -> String:
	if summer == null:
		return ""
	var family := summer.parents_visited and not summer.family_meal
	var with_hai := summer.invited_hai and not summer.ate_with_hai
	if not family and not with_hai:
		return ""
	if not preferred.is_empty() and preferred != "rice_only" and quantity(preferred) <= 0:
		return ""
	var meal := "cơm trắng"
	if family and quantity(SummerProgress.RICE_BAG) > 0:
		_add_items(SummerProgress.RICE_BAG, -1)
	var ingredients := [ArrivalProgress.EGG] + FishCatalog.SPECIES + [FIRST_PRODUCE, "malabar_spinach_produce", "cabbage_produce"]
	if summer_story != null:
		ingredients.append_array([FishCatalog.GOBY, "amaranth"])
	if not preferred.is_empty():
		ingredients = [] if preferred == "rice_only" else [preferred]
	for item in ingredients:
		if quantity(item) <= 0 or (item == FIRST_PRODUCE and not tutorial_completed and quantity(item) == 1):
			continue
		_add_items(item, -1)
		meal += " và " + ("trứng rán" if item == ArrivalProgress.EGG else ("cá kho" if FishCatalog.FISH.has(item) else "rau luộc"))
		break
	if family:
		summer.family_meal = true
		summer.mom_points = 5 if meal == "cơm trắng" else 20
	else:
		summer.ate_with_hai = true
	return meal


func cook_rain_porridge() -> bool:
	if summer_story == null or day < SummerProgress.RAIN_DAY or area != Area.HOUSE or summer_story.broth_day >= day:
		return false
	var rice := "white_rice" if quantity("white_rice") > 0 else ("raw_rice" if quantity("raw_rice") > 0 else SummerProgress.RICE_BAG)
	var cost := [rice, ArrivalProgress.EGG, VillageFestival.GINGER]
	for item in cost:
		if quantity(item) < 1:
			return false
	for item in cost:
		_add_items(item, -1)
	summer_story.broth_day = day + 1
	return true


func receive_family_visit() -> bool:
	if not summer_available(SummerProgress.FAMILY_DAY) or summer.parents_visited:
		return false
	summer.parents_visited = true
	_add_items(SummerProgress.RICE_BAG, 3)
	return true


func advance_neighbor_order() -> bool:
	if not summer_available(SummerProgress.WEAVE_DAY) or summer.neighbor_order == 2:
		return false
	if summer.neighbor_order == 0:
		summer.neighbor_order = 1
		return true
	if quantity("corn_produce") < 2:
		return false
	_add_items("corn_produce", -2)
	_earn(35)
	summer.neighbor_order = 2
	return true


func finish_basket(wrong: int, solo: bool) -> String:
	if not summer_available(SummerProgress.WEAVE_DAY) or not summer.received_heirlooms or quantity(SummerProgress.BAMBOO) < 1:
		return ""
	if solo and (day < SummerProgress.SOLO_DAY or not summer.learned_weaving):
		return ""
	var tier := 0
	if wrong == 0: tier = 3
	elif wrong <= 3: tier = 2
	elif wrong <= 6: tier = 1
	var result: String = SummerProgress.BASKETS[tier]
	_add_items(SummerProgress.BAMBOO, -1)
	_add_items(result, 1)
	summer.learned_weaving = true
	summer.solo_basket = summer.solo_basket or solo
	return result


func gather_bamboo() -> bool:
	if not summer_available(SummerProgress.WEAVE_DAY) or area != Area.GARDEN or quantity(SummerProgress.BAMBOO) >= 5:
		return false
	_add_items(SummerProgress.BAMBOO, 1)
	return true


func fertilize(cell: Vector2i) -> bool:
	if not summer_available(SummerProgress.WEAVE_DAY) or area != Area.GARDEN or quantity(SummerProgress.FERTILIZER) < 1 or not plots.has(cell):
		return false
	var plot := plots[cell]
	if plot.crop_id.is_empty() or plot.fertilized or nights_until_ripe(plot) <= 1:
		return false
	plot.fertilized = true
	_add_items(SummerProgress.FERTILIZER, -1)
	summer.fertilizer_used = true
	return true


func sprinkler_covers(cell: Vector2i) -> bool:
	var center := summer_sprinkler_cell()
	if center.x < 0 or not pump_running():
		return false
	return absi(cell.x - center.x) <= 1 and absi(cell.y - center.y) <= 1


func summer_sprinkler_cell() -> Vector2i:
	if summer == null or summer.sprinkler < 0:
		return Vector2i(-9, -9)
	var positions := SummerStory.SPRINKLERS if summer_story != null else SummerProgress.SPRINKLER_CELLS
	return positions[summer.sprinkler]


func start_summer_story(land: TutorialChapter) -> void:
	summer_story = SummerStory.new()
	_add_story_plots()
	var cells := SummerStory.transferred_cells()
	for index in cells.size():
		var soil := land.plots[index]
		var plot := plots[cells[index]]
		plot.tilled = soil != TutorialChapter.Soil.BARE
		plot.prepared = index >= 5 and index < 15 and soil >= TutorialChapter.Soil.FLOODED
		if soil >= TutorialChapter.Soil.SOWN and soil < TutorialChapter.Soil.HARVESTED:
			plot.crop_id = CropCatalog.CABBAGE if index < 5 else (CropCatalog.PADDY_RICE if index < 15 else (
				CropCatalog.CORN if index < 30 else CropCatalog.AMARANTH))
			plot.watered_nights = crop_growth_nights(plot.crop_id) if soil == TutorialChapter.Soil.RIPE else int(soil >= TutorialChapter.Soil.SPROUT)


func _add_story_plots() -> void:
	for cell in SummerStory.farm_cells():
		plots[cell] = Plot.new()


func is_heirloom_dry(cell: Vector2i) -> bool:
	return SummerStory.DRY.has_point(cell) if summer_story != null else cell in SummerProgress.HEIRLOOM_DRY


func is_paddy(cell: Vector2i) -> bool:
	return SummerStory.PADDY.has_point(cell) if summer_story != null else cell in SummerProgress.HEIRLOOM_PADDY


func crop_growth_nights(crop_id: String) -> int:
	if summer_story != null:
		if crop_id == CropCatalog.HEIRLOOM_CARROT:
			return 69
		if crop_id == CropCatalog.STICKY_RICE:
			return 24
	return CropCatalog.CROPS[crop_id].growth_nights


func expand_coop() -> bool:
	if not summer_available(SummerProgress.PUMP_DAY) or summer.expanded_coop or summer.hatch_day == 0 or quantity(SummerProgress.BAMBOO) < 3:
		return false
	_add_items(SummerProgress.BAMBOO, -3)
	summer.expanded_coop = true
	return true


func collect_build_material(item: String, index := 0) -> bool:
	if not summer_available(SummerProgress.BUILD_DAY):
		return false
	match item:
		SummerProgress.WOOD:
			if area != Area.GARDEN or index < 0 or index >= 3 or not arrival.tools_taken:
				return false
			if summer.wood_day != day:
				summer.wood_day = day
				summer.wood_mask = 0
			var bit := 1 << index
			if (summer.wood_mask & bit) != 0 or not _spend_outdoor_stamina(6 if in_drought() else 4):
				return false
			summer.wood_mask |= bit
			_add_items(item, 2)
		SummerProgress.STRAW:
			if area != Area.GARDEN or summer.straw_day == day:
				return false
			summer.straw_day = day
			_add_items(item, SummerProgress.COOP_STRAW)
		SummerProgress.NAIL:
			if area != Area.HOUSE or summer.nails_found:
				return false
			summer.nails_found = true
			_add_items(item, SummerProgress.COOP_NAILS)
		_:
			return false
	return true


func coop_materials() -> String:
	return "Gỗ %d/%d · Tre %d/%d · Đinh %d/%d" % [
		quantity(SummerProgress.WOOD), SummerProgress.COOP_WOOD,
		quantity(SummerProgress.BAMBOO), coop_bamboo_cost(),
		quantity(SummerProgress.NAIL), SummerProgress.COOP_NAILS,
	]


func coop_bamboo_cost() -> int:
	if summer.expanded_coop:
		return 0
	return 3 if summer_story != null else SummerProgress.COOP_BAMBOO


func build_coop() -> bool:
	if not summer_available(SummerProgress.BUILD_DAY) or area != Area.GARDEN or summer.coop_step == 4:
		return false
	match summer.coop_step:
		0:
			var bamboo := coop_bamboo_cost()
			if quantity(SummerProgress.WOOD) < SummerProgress.COOP_WOOD or quantity(SummerProgress.NAIL) < SummerProgress.COOP_NAILS or quantity(SummerProgress.BAMBOO) < bamboo:
				return false
			_add_items(SummerProgress.WOOD, -SummerProgress.COOP_WOOD)
			_add_items(SummerProgress.NAIL, -SummerProgress.COOP_NAILS)
			if bamboo:
				_add_items(SummerProgress.BAMBOO, -bamboo)
			summer.coop_step = 1
		1, 2:
			if summer.coop_step == 1 and not arrival.spend_stamina(5):
				return false
			summer.coop_work += 1
			if summer.coop_work == 4:
				summer.coop_work = 0
				summer.coop_step += 1
		3:
			if quantity(SummerProgress.STRAW) < SummerProgress.COOP_STRAW:
				return false
			_add_items(SummerProgress.STRAW, -SummerProgress.COOP_STRAW)
			summer.coop_step = 4
			summer.expanded_coop = true
	return true


func drink_tea() -> bool:
	if not summer_available(SummerProgress.QUIET_DAY) or summer.tea_day == day or arrival.stamina >= stamina_cap():
		return false
	summer.tea_day = day
	restore_stamina(5)
	return true


func restore_stamina(amount: int) -> void:
	arrival.stamina = mini(stamina_cap(), arrival.stamina + amount)


func gather_pennywort() -> bool:
	if not summer_available(SummerProgress.QUIET_DAY) or summer.herb_day == day:
		return false
	summer.herb_day = day
	_add_items(SummerProgress.PENNYWORT, 1)
	return true


func turn_drying_rice(index: int) -> bool:
	if summer_story != null and day == SummerProgress.SOLO_DAY and area == Area.VILLAGE:
		if is_raining(day) or minute_of_day < 900 or minute_of_day >= GardenCalendar.SHOP_CLOSE or index < 0 or index >= 3:
			return false
		if not summer_story.mark("solo_rice_%d" % index):
			return false
		if summer_story.done("solo_rice_0") and summer_story.done("solo_rice_1") and summer_story.done("solo_rice_2"):
			summer.festival.lan_points += 5
		return true
	if not summer_available(SummerProgress.QUIET_DAY) or area != Area.VILLAGE or is_raining(day) or minute_of_day < 15 * 60 + 30 or minute_of_day >= GardenCalendar.SHOP_CLOSE:
		return false
	if index < 0 or index >= 3 or (summer.rice_turned & (1 << index)) != 0:
		return false
	summer.rice_turned |= 1 << index
	if summer.rice_turned == 7:
		summer.lan_helped = true
		_add_items(SummerProgress.CANE_JUICE, 1)
	return true


func drink_cane_juice() -> bool:
	if not summer_available(SummerProgress.QUIET_DAY) or quantity(SummerProgress.CANE_JUICE) == 0:
		return false
	_add_items(SummerProgress.CANE_JUICE, -1)
	restore_stamina(15)
	summer.juice_until = mini(GardenCalendar.LAST_MINUTE, minute_of_day + 10)
	return true


func cooking_ingredients(recipe: int) -> Array[String]:
	var ingredients: Array[String] = []
	match recipe:
		0:
			ingredients = [SummerProgress.RICE_BAG, SummerProgress.PENNYWORT]
			for species in FishCatalog.SPECIES:
				if quantity(species) > 0:
					ingredients.append(species)
					return ingredients
			ingredients.clear()
		1:
			ingredients = [ArrivalProgress.EGG]
		2:
			for crop in CropCatalog.CROPS.values():
				var item: String = crop.produce_item
				var reserved := item == FIRST_PRODUCE and not tutorial_completed
				if quantity(item) > int(reserved):
					ingredients.append(item)
				if ingredients.size() == 3:
					return ingredients
			ingredients.clear()
	return ingredients


func cook_quiet_meal(recipe: int) -> bool:
	if not summer_available(SummerProgress.QUIET_DAY) or area != Area.HOUSE:
		return false
	var ingredients := cooking_ingredients(recipe)
	if ingredients.is_empty():
		return false
	for item in ingredients:
		if quantity(item) == 0:
			return false
	for item in ingredients:
		_add_items(item, -1)
	var recovery: int = [70, 50, 40][recipe]
	restore_stamina(recovery)
	if recipe == 0:
		summer.broth_day = day
	return true


func place_nesting_basket() -> bool:
	if not summer_available(SummerProgress.SOLO_DAY) or summer.nest_basket or arrival.hen == ArrivalProgress.Hen.LOCKED:
		return false
	for item in SummerProgress.BASKETS:
		if quantity(item) > 0:
			_add_items(item, -1)
			summer.nest_basket = true
			return true
	return false


func install_sprinkler(index: int) -> bool:
	if not summer_available(SummerProgress.PUMP_DAY) or not summer.found_pipes or not arrival.power_on:
		return false
	if index < 0 or index >= SummerProgress.SPRINKLER_CELLS.size():
		return false
	if index >= 3 and not summer.received_heirlooms:
		return false
	summer.sprinkler = index
	return true


func start_hatching() -> bool:
	if not summer_available(SummerProgress.PUMP_DAY) or summer.hatch_day > 0 or summer.chick or arrival.hen != ArrivalProgress.Hen.EGG_READY:
		return false
	arrival.hen = ArrivalProgress.Hen.EGG_COLLECTED
	summer.hatch_day = day + 5
	return true


func wholesale_price(item: String) -> int:
	var base := SummerProgress.sale_price(item)
	if summer_story != null:
		if item in SummerProgress.BASKETS:
			base = [200, 400, 700, 1000][SummerProgress.BASKETS.find(item)]
		elif item == "drying_mat":
			base = 1400
	if base == 0 and detailed_tutorial_completed:
		base = TutorialChapter.MARKET_PRICES.get(item, 0)
	if base == 0:
		return 0
	if item == FishCatalog.LOTUS_CARP and summer_available(AutumnWork.REST_DAY):
		return _preferred_price(roundi(base * 1.4))
	if summer != null and summer.craft.trip_reply > 0 and item != SummerCraft.FLOWER_SCARF:
		return _preferred_price(floori(base * 1.5))
	var multiplier: int = [90, 100, 110, 120][(day + item.length()) % 4]
	return _preferred_price(maxi(1, floori(base * multiplier / 100.0)))


func sell_wholesale(item: String, count: int) -> bool:
	if count < 1 or count > wholesale_limit(item):
		return false
	_add_items(item, -count)
	_earn(wholesale_price(item) * count)
	if summer.cart_loaded:
		summer.cart_sale = true
		summer.cart_loaded = false
	return true


func wholesale_limit(item: String) -> int:
	if (area != Area.DISTRICT and not village_wholesale_market()) or not GardenCalendar.shop_is_open(minute_of_day) or (item == FIRST_PRODUCE and not tutorial_completed):
		return 0
	var price := wholesale_price(item)
	if price == 0:
		return 0
	@warning_ignore("integer_division")
	return mini(quantity(item), (MAX_SAVE_INTEGER - coins) / price)


func item_label(item: String) -> String:
	var label := SummerProgress.item_name(item)
	if not label.is_empty():
		return label
	for crop in CropCatalog.CROPS.values():
		if crop.seed_item == item:
			return "Hạt %s" % crop.name.to_lower()
	if TutorialChapter.ITEMS.has(item):
		return TutorialChapter.ITEMS[item]
	return VillagerCatalog.gift_name(item)


func cut_plot_weeds(cell: Vector2i) -> bool:
	if area != Area.GARDEN or not plot_has_weeds(cell) or not arrival.tools_taken or arrival.total_stamina() < weed_cost():
		return false
	if _start_sickle_cut(cell):
		return true
	var cut := arrival.cut_weeds(PLOT_CELLS.find(cell), weed_cost())
	if cut:
		_finish_sickle_cut(cell)
	return cut


func weed_cost() -> int:
	if summer != null and summer.works.forged:
		return 1
	return 3 if summer != null and (summer.sharp_sickle or double_sickle_cut()) else ArrivalProgress.WEED_COST


func sickle_half_done(cell: Vector2i) -> bool:
	var index := LateSummer.FIELD.find(cell)
	return index >= 0 and summer != null and (summer.works.sickle_hits & (1 << index)) != 0


func double_sickle_cut() -> bool:
	return summer_available(BambooWorks.FORGE_DAY) and not summer.works.forged


func _start_sickle_cut(cell: Vector2i) -> bool:
	if not double_sickle_cut() or sickle_half_done(cell):
		return false
	var index := LateSummer.FIELD.find(cell)
	if index < 0:
		return false
	summer.works.sickle_hits |= 1 << index
	return true


func _finish_sickle_cut(cell: Vector2i) -> void:
	var index := LateSummer.FIELD.find(cell)
	if index >= 0:
		summer.works.sickle_hits &= ~(1 << index)


func take_dog_food() -> bool:
	if not yard_open() or area != Area.HOUSE or arrival.dog_food != ArrivalProgress.DogFood.PANTRY:
		return false
	arrival.dog_food = ArrivalProgress.DogFood.BAG
	return true


func feed_dog() -> bool:
	if not yard_open() or area != Area.GARDEN or arrival.dog_food != ArrivalProgress.DogFood.BAG:
		return false
	arrival.dog_food = ArrivalProgress.DogFood.FED
	return true


func take_starter_greens() -> bool:
	if arrival == null or day < 3 or area != Area.GARDEN or arrival.seeds_taken:
		return false
	_add_items(CropCatalog.CROPS[CropCatalog.WATER_SPINACH].seed_item, 4)
	_add_items(CropCatalog.CROPS[CropCatalog.MALABAR_SPINACH].seed_item, 2)
	selected_crop = CropCatalog.WATER_SPINACH
	arrival.seeds_taken = true
	return true


func meet_lan() -> bool:
	if arrival == null or day < 3 or area != Area.VILLAGE or arrival.lan_met:
		return false
	arrival.lan_met = true
	_add_items(ArrivalProgress.WELCOME_GIFT, 1)
	return true


func receive_cat() -> bool:
	if arrival == null or day < 4 or area != Area.GARDEN or arrival.cat_home:
		return false
	arrival.cat_home = true
	return true


func has_pest(cell: Vector2i) -> bool:
	return arrival != null and arrival.pest_plot >= 0 and PLOT_CELLS[arrival.pest_plot] == cell


func open_coop() -> bool:
	if arrival == null or day < ArrivalProgress.COOP_DAY or arrival.hen != ArrivalProgress.Hen.LOCKED:
		return false
	arrival.hen = ArrivalProgress.Hen.RATION
	return true


func feed_hen() -> bool:
	if arrival == null or (arrival.hen != ArrivalProgress.Hen.RATION and not can_feed_again()):
		return false
	arrival.hen = ArrivalProgress.Hen.FED
	if summer.coop_step == 4:
		summer.feeder_days = 2
	return true


func can_feed_again() -> bool:
	return summer_available(SummerProgress.FIRST_DAY) and arrival.hen == ArrivalProgress.Hen.EGG_COLLECTED


func collect_egg() -> bool:
	if arrival == null or arrival.hen != ArrivalProgress.Hen.EGG_READY:
		return false
	arrival.hen = ArrivalProgress.Hen.EGG_COLLECTED
	_add_items(ArrivalProgress.EGG, 1)
	if summer.nest_basket or summer.feeder_days > 0:
		arrival.hen = ArrivalProgress.Hen.FED
	return true


func cook_meal() -> bool:
	if arrival == null or day < ArrivalProgress.COOKING_DAY or arrival.cooked_meal:
		return false
	for species in FishCatalog.SPECIES:
		if quantity(species) > 0:
			_add_items(species, -1)
			break
	arrival.cooked_meal = true
	arrival.meal_bonus = -1
	return true


func fence_cell() -> Vector2i:
	if arrival == null or arrival.fence_index < 0:
		return Vector2i(-1, -1)
	var index := arrival.fence_index
	return FENCE_AREA.position + Vector2i(index % FENCE_AREA.size.x, index / FENCE_AREA.size.x)


func change_fence(cell: Vector2i) -> bool:
	if arrival == null or day < ArrivalProgress.FENCE_DAY or not FENCE_AREA.has_point(cell):
		return false
	var offset := cell - FENCE_AREA.position
	arrival.fence_index = -1 if fence_cell() == cell else offset.y * FENCE_AREA.size.x + offset.x
	return true


func drain_plot() -> bool:
	if arrival == null or day < ArrivalProgress.DRAIN_DAY or arrival.drained or not arrival.tools_taken:
		return false
	arrival.drained = true
	return true


func is_flooded(cell: Vector2i) -> bool:
	return cell == LOW_PLOT and arrival != null and day == ArrivalProgress.DRAIN_DAY and not arrival.drained


func _place_first_pest() -> void:
	if arrival == null or day < 4 or arrival.pest_plot != ArrivalProgress.PEST_PENDING:
		return
	var nights: int = CropCatalog.CROPS[CropCatalog.WATER_SPINACH].growth_nights
	for index in range(PLOT_CELLS.size()):
		var plot := plots[PLOT_CELLS[index]]
		if plot.crop_id == CropCatalog.WATER_SPINACH and plot.watered_nights > 0 and plot.watered_nights < nights:
			arrival.pest_plot = index
			return


func shop_crop_ids() -> Array:
	if arrival == null:
		return CropCatalog.CROP_IDS
	if tutorial_completed and day >= ArrivalProgress.BOARD_DAY:
		var seeds := CropCatalog.GREENS + [CropCatalog.CABBAGE, CropCatalog.RADISH]
		if summer_story != null:
			seeds.append_array([CropCatalog.CORN, CropCatalog.AMARANTH, CropCatalog.PADDY_RICE, CropCatalog.PUMPKIN])
		return seeds
	return CropCatalog.GREENS


func market_crop_ids() -> Array:
	var seeds := shop_crop_ids()
	for crop_id in CropCatalog.SUMMER_CROPS:
		if crop_id not in seeds:
			seeds.append(crop_id)
	return seeds


func bag_crop_ids() -> Array:
	var ids := shop_crop_ids().duplicate()
	if arrival != null:
		for crop_id in CropCatalog.CROPS:
			var crop: Dictionary = CropCatalog.CROPS[crop_id]
			if crop_id not in ids and (
				quantity(crop.seed_item) > 0 or quantity(crop.produce_item) > 0 or quantity(crop.produce_item + LateSummer.PREMIUM) > 0
			):
				ids.append(crop_id)
	return ids


func seed_shortcut(crop_id: String) -> int:
	return shop_crop_ids().find(crop_id) + 1


func quantity(item_id: String) -> int:
	return inventory.get(item_id, 0)


func available_gifts() -> Array[String]:
	var gifts: Array[String] = []
	for item_id in inventory:
		if can_gift(item_id):
			gifts.append(item_id)
	gifts.sort()
	return gifts


func can_gift(item_id: String) -> bool:
	var reserved := arrival != null and not tutorial_completed and item_id == FIRST_PRODUCE
	return quantity(item_id) > int(reserved) and not VillagerCatalog.gift_name(item_id).is_empty()


func give_gift(villager_id: String, item_id: String) -> int:
	var relationship := relationships.get(villager_id) as Relationship
	if relationship == null or relationship.last_gift_day == day:
		return 0
	if not can_gift(item_id):
		return 0
	var earned := VillagerCatalog.gift_points(villager_id, item_id)
	_add_items(item_id, -1)
	relationship.points = mini(relationship.points + earned, MAX_SAVE_INTEGER)
	relationship.last_gift_day = day
	return earned


func can_view_villager_event(villager_id: String) -> bool:
	var relationship := relationships.get(villager_id) as Relationship
	return relationship != null and relationship.points >= VillagerCatalog.EVENT_POINTS and not relationship.event_seen


func view_villager_event(villager_id: String) -> bool:
	if not can_view_villager_event(villager_id):
		return false
	relationships[villager_id].event_seen = true
	return true


func select_crop(crop_id: String) -> bool:
	if not bag_crop_ids().has(crop_id) or not seed_is_unlocked(crop_id) or selected_crop == crop_id:
		return false
	selected_crop = crop_id
	return true


func buy_seed(crop_id: String) -> bool:
	var shop := market_crop_ids() if area == Area.DISTRICT else shop_crop_ids()
	if not shop.has(crop_id) or not seed_is_unlocked(crop_id) or (not can_sow(crop_id) and not (village_wholesale_market() and crop_id == CropCatalog.PUMPKIN)):
		return false
	var crop: Dictionary = CropCatalog.CROPS[crop_id]
	if coins < crop.buy_price:
		return false
	coins -= crop.buy_price
	_add_items(crop.seed_item, 1)
	return true


func can_sow(crop_id: String) -> bool:
	if crop_id in CropCatalog.AUTUMN_CROPS:
		return season() == GardenCalendar.Season.AUTUMN
	return (crop_id != CropCatalog.CUCUMBER and crop_id not in CropCatalog.SUMMER_CROPS) or season() == GardenCalendar.Season.SUMMER


func plot_action(cell: Vector2i) -> PlotAction:
	if has_pest(cell):
		return PlotAction.REMOVE_PEST
	var plot := plots[cell]
	if not plot.tilled:
		return PlotAction.HOE
	if plot.crop_id.is_empty():
		if summer != null and summer.late.has_stubble(cell):
			return PlotAction.CUT_STUBBLE
		var seed_item: String = CropCatalog.CROPS[selected_crop].seed_item
		if is_paddy(cell) and not plot.prepared:
			return PlotAction.FLOOD_PADDY
		if is_heirloom_dry(cell) and not plot.prepared and selected_crop == CropCatalog.HEIRLOOM_CARROT:
			return PlotAction.DEEP_HOE
		if (selected_crop in [CropCatalog.STICKY_RICE, CropCatalog.PADDY_RICE]) != is_paddy(cell) or (
			selected_crop == CropCatalog.HEIRLOOM_CARROT and not is_heirloom_dry(cell)
		):
			return PlotAction.WRONG_SOIL
		if not can_sow(selected_crop):
			return PlotAction.OUT_OF_SEASON
		return PlotAction.SOW if quantity(seed_item) > 0 else PlotAction.NO_SEEDS
	if nights_until_ripe(plot) == 0:
		return PlotAction.HARVEST
	if is_flooded(cell):
		return PlotAction.FLOODED
	if is_plot_wet(plot, cell):
		return PlotAction.ALREADY_WATERED
	if in_drought():
		if plot.watered and minute_of_day < DroughtProgress.SECOND_PASS:
			return PlotAction.WAIT_FOR_WATER
		if drought_water_left() == 0:
			return PlotAction.WELL_EMPTY
	return PlotAction.WATER


func nights_until_ripe(plot: Plot) -> int:
	return crop_growth_nights(plot.crop_id) - plot.watered_nights


func earliest_harvest_nights(crop_id: String) -> int:
	var earliest := -1
	for plot in plots.values():
		if plot.crop_id == crop_id:
			var remaining := nights_until_ripe(plot)
			if earliest < 0 or remaining < earliest:
				earliest = remaining
	return earliest


func is_plot_wet(plot: Plot, cell := Vector2i(-1, -1)) -> bool:
	var hand_watered := plot.watered_twice if needs_extra_water(cell) else plot.watered
	return plot.tilled and (hand_watered or is_raining(day) or sprinkler_covers(cell))


func needs_extra_water(cell: Vector2i) -> bool:
	var heat_on_heirloom := summer_story != null and day == SummerProgress.PUMP_DAY and (is_heirloom_dry(cell) or is_paddy(cell))
	return summer != null and (heat_on_heirloom or day == SummerCraft.HEAT_HINT_DAY or in_drought()) and not sprinkler_covers(cell)


func work_plot(cell: Vector2i) -> bool:
	if arrival != null and (day < 3 or not arrival.tools_taken or plot_has_weeds(cell)):
		return false
	var plot := plots[cell]
	var action := plot_action(cell)
	if arrival != null:
		if action == PlotAction.CUT_STUBBLE and arrival.total_stamina() >= action_cost(action) and _start_sickle_cut(cell):
			return true
		if not _spend_outdoor_stamina(_base_action_cost(action)):
			return false
	match action:
		PlotAction.HOE:
			plot.tilled = true
		PlotAction.DEEP_HOE, PlotAction.FLOOD_PADDY:
			plot.prepared = true
		PlotAction.SOW:
			plot.crop_id = selected_crop
			if selected_crop in CropCatalog.AUTUMN_CROPS:
				summer.autumn.sown |= 1 << CropCatalog.AUTUMN_CROPS.find(selected_crop)
			plot.loosened = false
			if selected_crop not in CropCatalog.AUTUMN_CROPS:
				plot.fertile = false
			_add_items(CropCatalog.CROPS[selected_crop].seed_item, -1)
			if plot.crop_id in [CropCatalog.STICKY_RICE, CropCatalog.PADDY_RICE]:
				plot.watered = true
			if arrival != null and plot.crop_id == CropCatalog.WATER_SPINACH and is_plot_wet(plot, cell):
				arrival.first_crop_watered = true
		PlotAction.WATER:
			if in_drought():
				summer.drought.supply -= 1
			if plot.watered and needs_extra_water(cell):
				plot.watered_twice = true
			plot.watered = true
			if arrival != null and plot.crop_id == CropCatalog.WATER_SPINACH:
				arrival.first_crop_watered = true
			ripen_autumn_plot(cell)
		PlotAction.HARVEST:
			var item := LateSummer.crop_goods(plot.crop_id)
			if summer_available(LateSummer.HARVEST) and plot.crop_id in CropCatalog.SUMMER_CROPS and cell in LateSummer.FIELD:
				summer.late.stubble |= 1 << LateSummer.FIELD.find(cell)
				if plot.drought_stress == 0 and posmod(day * 11 + cell.x * 7 + cell.y * 13, 5) == 0:
					item += LateSummer.PREMIUM
			if plot.drought_stress < 2 or (cell.x + cell.y) % 3 != 0:
				_add_items(item, 1)
			plot.crop_id = ""
			plot.watered_nights = 0
			plot.watered = false
			plot.watered_twice = false
			plot.fertilized = false
			plot.drought_stress = 0
			plot.fertile = false
		PlotAction.REMOVE_PEST:
			arrival.pest_plot = ArrivalProgress.PEST_REMOVED
		PlotAction.CUT_STUBBLE:
			summer.late.stubble &= ~(1 << LateSummer.FIELD.find(cell))
			_finish_sickle_cut(cell)
		_:
			return false
	return true


static func plot_stamina_cost(action: PlotAction) -> int:
	match action:
		PlotAction.HOE, PlotAction.SOW, PlotAction.DEEP_HOE:
			return 5
		PlotAction.WATER, PlotAction.FLOOD_PADDY, PlotAction.CUT_STUBBLE:
			return 3
	return 0


func action_cost(action: PlotAction) -> int:
	return _hat_discount(_base_action_cost(action))


func _base_action_cost(action: PlotAction) -> int:
	if action == PlotAction.CUT_STUBBLE and summer != null and summer.works.forged:
		return 1
	var cost := plot_stamina_cost(action)
	if action == PlotAction.DEEP_HOE and summer_story != null:
		cost *= 2
	if summer != null and summer.iron_hoe and action in [PlotAction.HOE, PlotAction.DEEP_HOE]:
		cost = 3
	if cost > 0 and summer != null and summer.craft.bun_day == day:
		cost = maxi(1, floori(cost * 0.8))
	if cost > 0 and summer != null and summer.broth_day == day:
		cost = maxi(1, floori(cost * 0.9))
	if cost > 0 and summer_story != null and summer_story.broth_day == day:
		cost = maxi(1, floori(cost * 0.85))
	if cost > 0 and in_drought():
		cost = ceili(cost * 1.3)
		if action == PlotAction.WATER and (summer.craft.jar or summer.drought.well_step == 4):
			cost = maxi(1, cost - 1)
	return cost


func advance_day() -> bool:
	if not can_sleep():
		return false
	var storm_night := summer != null and day == BambooWorks.STORM_DAY
	if summer != null:
		if storm_night:
			minute_of_day = maxi(minute_of_day, BambooWorks.STORM_HOUR)
			start_summer_storm()
			if storm_active():
				summer.works.resolve_storm()
			_apply_storm_damage()
		summer.works.advance_batch(summer.works.batch_seconds(day, true), day)
	var dry := in_drought()
	for cell in plots:
		var plot := plots[cell]
		if not plot.crop_id.is_empty() and nights_until_ripe(plot) > 0:
			if is_plot_wet(plot, cell):
				if not has_pest(cell) and not is_flooded(cell):
					plot.watered_nights += mini(nights_until_ripe(plot), 2 if plot.fertilized else 1)
					plot.fertilized = false
					if arrival != null and plot.crop_id == CropCatalog.WATER_SPINACH:
						arrival.first_crop_watered = true
			elif dry:
				plot.drought_stress += 1
				if plot.drought_stress == 2:
					summer.drought.stunted += 1
				elif plot.drought_stress == 3:
					plot.crop_id = ""
					plot.watered_nights = 0
					plot.fertilized = false
					plot.drought_stress = 0
					summer.drought.lost += 1
					if has_pest(cell):
						arrival.pest_plot = ArrivalProgress.PEST_REMOVED
		plot.watered = false
		plot.watered_twice = false
	day += 1
	minute_of_day = GardenCalendar.START_MINUTE
	if arrival != null:
		_apply_autumn_investments()
		var fair := summer.festival
		if summer.chick and not fair.chick_joined:
			if fair.chick_fed and (fair.chick_divider or fair.chick_straw or (summer.expanded_coop and not is_raining(day - 1))):
				fair.chick_age = mini(3, fair.chick_age + 1)
			fair.chick_fed = false
		if day <= VillageFestival.FAIR_DAY:
			fair.gather_mask = 0
		var was_fed := arrival.hen == ArrivalProgress.Hen.FED
		var had_egg := arrival.hen == ArrivalProgress.Hen.EGG_READY
		var social := summer.social
		if not social.training_reward and social.training_day < day - 1:
			social.streak = 0
		arrival.rest(stamina_cap())
		if day == VillageSocial.AFTER_FAIR_DAY:
			minute_of_day = VillageSocial.RECOVERY_WAKE
			arrival.stamina = 70
		elif day >= VillageSocial.TRAINING_DAY and social.wake_early:
			minute_of_day = VillageSocial.EARLY_WAKE
		if summer.feeder_days > 0:
			summer.feeder_days -= 1
			if not was_fed and arrival.hen == ArrivalProgress.Hen.EGG_COLLECTED:
				arrival.hen = ArrivalProgress.Hen.EGG_READY
		if storm_night and not had_egg and arrival.hen == ArrivalProgress.Hen.EGG_READY and (
			(summer.works.protection & BambooWorks.COOP_TARP) == 0
		):
			arrival.hen = ArrivalProgress.Hen.EGG_COLLECTED
		if dry:
			var drought := summer.drought
			if summer.sprinkler >= 0 and arrival.power_on and drought.oil > 0:
				drought.oil -= 1
			if not had_egg and arrival.hen == ArrivalProgress.Hen.EGG_READY and drought.chicken_water < 2:
				arrival.hen = ArrivalProgress.Hen.EGG_COLLECTED
				drought.dry_hen_days += 1
				summer.feeder_days = 0
			drought.chicken_water = 0
		if summer_story != null and summer.coop_step == 4 and not had_egg and arrival.hen == ArrivalProgress.Hen.EGG_READY:
			summer_story.nest_mornings = (summer_story.nest_mornings + 1) % 5
			if summer_story.nest_mornings == 0:
				_add_items(ArrivalProgress.EGG, 1)
		if in_drought():
			_fill_drought_well()
		elif day == DroughtProgress.RAIN:
			minute_of_day = VillageSocial.EARLY_WAKE
		elif day == LateSummer.FIRST_FAIR:
			minute_of_day = LateSummer.FERRY_WAKE
		summer.juice_until = 0
		_place_first_pest()
		if summer.hatch_day > 0 and day >= summer.hatch_day:
			summer.hatch_day = 0
			summer.chick = true
	return true


func advance_clock(steps := 1) -> bool:
	if minute_of_day >= GardenCalendar.LAST_MINUTE:
		return false
	minute_of_day = mini(minute_of_day + GardenCalendar.STEP_MINUTES * steps, GardenCalendar.LAST_MINUTE)
	start_summer_storm()
	if summer_available(AutumnWork.AUTUMN_DAY):
		for cell in plots:
			ripen_autumn_plot(cell)
	return true


func sale_value() -> int:
	var total := 0
	for crop in CropCatalog.CROPS.values():
		total += quantity(crop.produce_item) * int(crop.sell_price)
	for species in FishCatalog.ALL_FISH:
		total += quantity(species) * int(FishCatalog.FISH[species].sell_price)
	return total


func has_wholesale_goods() -> bool:
	if not packed_tutorial_goods.is_empty():
		return true
	for item in inventory:
		if wholesale_price(item) > 0:
			return true
	return false


func bin_open() -> bool:
	return arrival == null or (day >= ArrivalProgress.BOARD_DAY and tutorial_completed)


func produce_stall_open() -> bool:
	return arrival != null and day >= ArrivalProgress.PRODUCE_DAY and GardenCalendar.shop_is_open(minute_of_day)


func produce_sale_limit(crop_id: String) -> int:
	if not produce_stall_open() or not CropCatalog.CROPS.has(crop_id):
		return 0
	var crop: Dictionary = CropCatalog.CROPS[crop_id]
	@warning_ignore("integer_division")
	return mini(quantity(crop.produce_item), (MAX_SAVE_INTEGER - coins) / int(crop.sell_price))


func sell_produce(crop_id: String, count: int) -> bool:
	if count <= 0 or count > produce_sale_limit(crop_id):
		return false
	var crop: Dictionary = CropCatalog.CROPS[crop_id]
	_add_items(crop.produce_item, -count)
	_earn(count * int(crop.sell_price))
	if crop_id == CropCatalog.WATER_SPINACH:
		tutorial_completed = true
	return true


func sell_crops() -> bool:
	if not bin_open():
		return false
	var total := sale_value()
	if total == 0:
		return false
	for crop in CropCatalog.CROPS.values():
		inventory.erase(crop.produce_item)
	for species in FishCatalog.ALL_FISH:
		if FishCatalog.FISH[species].sell_price > 0:
			inventory.erase(species)
	_earn(total)
	return true


func finish_fishing(species: String) -> bool:
	if minute_of_day >= GardenCalendar.LAST_MINUTE or (arrival != null and day < ArrivalProgress.FISHING_DAY):
		return false
	if not species.is_empty() and species != fishing_species():
		return false
	if not species.is_empty():
		_add_items(species, 1)
		if arrival != null:
			arrival.caught_fish = true
	return advance_clock(FishCatalog.CAST_CLOCK_STEPS)


func finish_story_fishing(species: String) -> bool:
	if summer_story == null or area != Area.GARDEN or minute_of_day >= GardenCalendar.LAST_MINUTE:
		return false
	if species == FishCatalog.GOBY:
		_add_items(species, 1)
	return advance_clock(FishCatalog.CAST_CLOCK_STEPS)


func fishing_species() -> String:
	return FishCatalog.species_at(minute_of_day, _season_day(day))


func can_deliver_fish_order() -> bool:
	return fish_order_state == FishOrder.State.ACCEPTED and quantity(FishCatalog.CATFISH) >= FishOrder.QUANTITY


func advance_fish_order() -> bool:
	if fish_order_state == FishOrder.State.AVAILABLE:
		fish_order_state = FishOrder.State.ACCEPTED
		return true
	if not can_deliver_fish_order():
		return false
	_add_items(FishCatalog.CATFISH, -FishOrder.QUANTITY)
	_earn(FishOrder.REWARD)
	fish_order_state = FishOrder.State.COMPLETED
	return true


func can_deliver_order() -> bool:
	return order_state == VillageOrder.State.ACCEPTED and quantity(VillageOrder.ITEM_ID) >= VillageOrder.QUANTITY


func market_open() -> bool:
	return (arrival == null or day >= ArrivalProgress.FAIR_DAY) and GardenCalendar.market_is_open(day, minute_of_day)


func can_deliver_market_order() -> bool:
	return market_open() and market_delivery_day == 0 and quantity(MarketOrder.ITEM_ID) >= MarketOrder.QUANTITY


func deliver_market_order() -> bool:
	if not can_deliver_market_order():
		return false
	_add_items(MarketOrder.ITEM_ID, -MarketOrder.QUANTITY)
	_earn(MarketOrder.REWARD)
	market_delivery_day = day
	return true


func radish_unlock_day() -> int:
	return market_delivery_day + 1 if market_delivery_day > 0 else 0


func seed_is_unlocked(crop_id: String) -> bool:
	if crop_id in [CropCatalog.AMARANTH, CropCatalog.PADDY_RICE]:
		return summer_story != null
	if crop_id == CropCatalog.CORN and summer_story != null:
		return true
	if crop_id == CropCatalog.PUMPKIN and summer_story != null:
		return true
	if crop_id in CropCatalog.GREENS:
		return arrival != null and day >= 3
	if crop_id == CropCatalog.RADISH:
		return market_delivery_day > 0 and day >= radish_unlock_day()
	if crop_id in CropCatalog.HEIRLOOMS:
		return summer != null and summer.received_heirlooms
	if crop_id in CropCatalog.SUMMER_CROPS:
		return summer_available(SummerProgress.WEAVE_DAY)
	if crop_id in CropCatalog.AUTUMN_CROPS:
		return summer != null and (summer.late.seeds_unlocked() or (summer.autumn.built & 4) != 0 or summer.autumn.starter_seeds)
	return CropCatalog.CROPS.has(crop_id)


func advance_order() -> bool:
	match order_state:
		VillageOrder.State.AVAILABLE:
			order_state = VillageOrder.State.ACCEPTED
		VillageOrder.State.ACCEPTED:
			if not can_deliver_order():
				return false
			_add_items(VillageOrder.ITEM_ID, -VillageOrder.QUANTITY)
			order_state = VillageOrder.State.DELIVERED
		VillageOrder.State.DELIVERED:
			_earn(VillageOrder.REWARD)
			order_state = VillageOrder.State.REWARDED
		_:
			return false
	return true


func _earn(amount: int) -> void:
	coins = mini(MAX_SAVE_INTEGER, coins + amount)
	if arrival == null:
		tutorial_completed = tutorial_completed or coins >= GOAL_COINS


func _add_items(item_id: String, amount: int) -> void:
	var count := quantity(item_id) + amount
	if count == 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = count


func to_data() -> Dictionary:
	var saved_plots: Array[Dictionary] = []
	for cell in _plot_save_cells():
		var plot := plots[cell]
		saved_plots.append({
			"tilled": plot.tilled,
			"crop_id": plot.crop_id,
			"watered_nights": plot.watered_nights,
			"watered": plot.watered,
			"watered_twice": plot.watered_twice,
			"drought_stress": plot.drought_stress,
			"prepared": plot.prepared,
			"fertilized": plot.fertilized,
			"loosened": plot.loosened, "fertile": plot.fertile,
		})
	var saved_relationships := {}
	for villager_id in relationships:
		var relationship := relationships[villager_id]
		saved_relationships[villager_id] = {
			"points": relationship.points,
			"last_gift_day": relationship.last_gift_day,
			"event_seen": relationship.event_seen,
		}
	return {
		"version": SAVE_VERSION,
		"day": day,
		"minute_of_day": minute_of_day,
		"coins": coins,
		"inventory": inventory.duplicate(),
		"selected_crop": selected_crop,
		"tutorial_completed": tutorial_completed,
		"area": area,
		"order_state": order_state,
		"market_delivery_day": market_delivery_day,
		"fish_order_state": fish_order_state,
		"relationships": saved_relationships,
		"plots": saved_plots,
		"arrival": arrival.to_data() if arrival != null else null,
		"summer": summer.to_data() if summer != null else null,
		"chapter": chapter.to_data() if chapter != null else null,
		"detailed_tutorial_completed": detailed_tutorial_completed,
		"packed_tutorial_goods": packed_tutorial_goods.duplicate(),
		"summer_story": summer_story.to_data() if summer_story != null else null,
	}


func _plot_save_cells() -> Array:
	var cells := PLOT_CELLS.duplicate()
	if summer != null:
		if summer.received_heirlooms and summer_story == null:
			cells.append_array(SummerProgress.HEIRLOOM_CELLS)
		if summer.autumn.built & 1:
			cells.append_array(AutumnWork.WEST)
	if summer_story != null:
		cells.append_array(SummerStory.farm_cells())
	return cells


static func from_data(data: Dictionary) -> GardenProgress:
	var version := read_integer(data.get("version"), 1, SAVE_VERSION)
	if version < 1:
		return null
	if version == 1:
		data = _migrate_prototype(data)
		if data.is_empty():
			return null

	var progress := GardenProgress.new()
	progress.day = read_integer(data.get("day"), 1, MAX_SAVE_INTEGER)
	progress.coins = read_integer(data.get("coins"), 0, MAX_SAVE_INTEGER)
	if progress.day < 1 or progress.coins < 0:
		return null
	if version >= 24 and data.get("summer_story") != null:
		if data.get("detailed_tutorial_completed") != true:
			return null
		progress.summer_story = SummerStory.from_data(data.summer_story, progress.day)
		if progress.summer_story == null:
			return null
		progress._add_story_plots()
	var chapter_data: Variant = data.get("chapter") if version >= 23 else null
	if chapter_data != null:
		if not chapter_data is Dictionary or data.get("tutorial_completed") != false or data.get("arrival") == null:
			return null
		progress.chapter = TutorialChapter.from_data(chapter_data, progress.day)
		if progress.chapter == null:
			return null
	if version >= 9:
		if not data.has("arrival"):
			return null
		var arrival_data: Variant = data.get("arrival")
		if arrival_data != null:
			if not arrival_data is Dictionary:
				return null
			progress.arrival = ArrivalProgress.from_data(arrival_data, PLOT_CELLS.size(), version)
			if progress.arrival == null or (progress.day > 1 and not progress.can_sleep()):
				return null
			if progress.chapter != null and (progress.chapter.fuse_solved() != progress.arrival.power_on or (progress.day > 1 and not progress.arrival.power_on)):
				return null
			progress.summer = SummerProgress.from_data(data.get("summer"), progress.day, version) if version >= 13 else SummerProgress.new()
			if progress.summer == null:
				return null
			if version < 18 and progress.in_drought():
				progress._fill_drought_well()
				if progress.day >= DroughtProgress.OIL_DAY and progress.summer.sprinkler >= 0:
					progress.summer.drought.oil = 0
			if progress.arrival.stamina > progress.stamina_cap():
				return null
			if progress.summer.received_heirlooms and progress.summer_story == null:
				progress._add_inherited_plots()
			if progress.summer.autumn.built & 1:
				progress._add_western_plots()
			if progress.day == 1 and (
				progress.arrival.cleared_weeds != 0 or progress.arrival.dog_food != ArrivalProgress.DogFood.PANTRY
			):
				return null
			if (progress.day < 3 and (progress.arrival.seeds_taken or progress.arrival.lan_met or progress.arrival.first_crop_watered)) or (
				progress.day < 4 and (progress.arrival.cat_home or progress.arrival.pest_plot != ArrivalProgress.PEST_PENDING)
			):
				return null
	if version >= 3:
		var early_day := progress.summer_available(VillageSocial.TRAINING_DAY) and progress.summer.social.training_invited
		var rain_day := progress.summer != null and progress.day == DroughtProgress.RAIN
		var earliest := VillageSocial.EARLY_WAKE if early_day or rain_day else GardenCalendar.START_MINUTE
		if progress.chapter != null and progress.day == 2:
			earliest = 5 * 60
		if progress.summer_available(LateSummer.FIRST_FAIR) and progress.day == LateSummer.FIRST_FAIR:
			earliest = LateSummer.FERRY_WAKE
		progress.minute_of_day = read_integer(
			data.get("minute_of_day"), earliest, GardenCalendar.LAST_MINUTE
		)
		if progress.minute_of_day < 0 or progress.minute_of_day % GardenCalendar.STEP_MINUTES != 0:
			return null
	if version >= 4:
		var last_area := Area.FESTIVAL if progress.summer_available(VillageFestival.FAIR_DAY) else (Area.DISTRICT if progress.summer_available(SummerProgress.FIRST_DAY) else (
			Area.HOUSE if progress.arrival != null else Area.VILLAGE
		))
		if version >= 19 and progress.summer_available(LateSummer.LOTUS_DAY) and progress.summer.late.lotus_invited:
			last_area = Area.LOTUS_POND
		if version >= 19 and progress.summer_available(LateSummer.FIRST_FAIR) and LateSummer.fair_day(progress.day):
			last_area = Area.COUNTY_FAIR
		if version >= 20 and progress.summer_available(BambooWorks.FORGE_DAY):
			last_area = Area.BAMBOO_WORKS if progress.summer_available(BambooWorks.OFFER_DAY) else Area.FORGE
		if version >= 22 and progress.has_storehouse():
			last_area = Area.STOREHOUSE
		var area_id := read_integer(data.get("area"), Area.GARDEN, last_area)
		var order_id := read_integer(data.get("order_state"), VillageOrder.State.AVAILABLE, VillageOrder.State.REWARDED)
		if area_id < 0 or order_id < 0:
			return null
		progress.area = area_id as Area
		if progress.area == Area.FESTIVAL and progress.day != VillageFestival.FAIR_DAY:
			return null
		if progress.area == Area.LOTUS_POND and not progress.summer.late.lotus_invited:
			return null
		if progress.area == Area.COUNTY_FAIR:
			if not LateSummer.fair_day(progress.day):
				return null
			if version == 19:
				progress.summer.works.county_met = true
		if progress.area == Area.VILLAGE and not progress.can_visit_village():
			return null
		progress.order_state = order_id as VillageOrder.State
	if version >= 5:
		progress.market_delivery_day = read_integer(data.get("market_delivery_day"), 0, progress.day)
		if progress.market_delivery_day < 0:
			return null
		if progress.market_delivery_day > 0 and not GardenCalendar.is_market_day(progress.market_delivery_day):
			return null
	if version >= 6:
		var fish_order_id := read_integer(
			data.get("fish_order_state"), FishOrder.State.AVAILABLE, FishOrder.State.COMPLETED
		)
		if fish_order_id < 0:
			return null
		progress.fish_order_state = fish_order_id as FishOrder.State
	if version >= 8 and not progress._read_relationships(data.get("relationships")):
		return null

	var selection: Variant = data.get("selected_crop")
	var tutorial: Variant = data.get("tutorial_completed")
	if not selection is String or not tutorial is bool:
		return null
	if version < 11 and progress.arrival != null and progress.day < 3:
		selection = CropCatalog.WATER_SPINACH
	var early_selection: bool = progress.arrival != null and progress.day < 3 and selection == CropCatalog.WATER_SPINACH
	if not early_selection and not progress.seed_is_unlocked(selection):
		return null
	if progress.arrival == null and progress.coins >= GOAL_COINS and not tutorial:
		return null
	progress.selected_crop = selection
	progress.tutorial_completed = tutorial and (progress.arrival == null or version >= 12)
	if version >= 23:
		var detailed: Variant = data.get("detailed_tutorial_completed", false)
		if not detailed is bool:
			return null
		if detailed and (progress.arrival == null or progress.day <= TutorialChapter.LAST_DAY or not progress.tutorial_completed):
			return null
		progress.detailed_tutorial_completed = detailed
		var packed: Variant = data.get("packed_tutorial_goods", {})
		if not packed is Dictionary:
			return null
		if not packed.is_empty() and (not progress.detailed_tutorial_completed or progress.summer.cart_loaded):
			return null
		for item in packed:
			var amount := read_integer(packed[item], 1, 1000000)
			if not TutorialChapter.MARKET_PRICES.has(item) or amount < 1:
				return null
			progress.packed_tutorial_goods[item] = amount
	if progress.arrival != null:
		var arrival_state := progress.arrival
		if (progress.day < ArrivalProgress.COOP_DAY and arrival_state.hen != ArrivalProgress.Hen.LOCKED) or (
			progress.day == ArrivalProgress.COOP_DAY and arrival_state.hen >= ArrivalProgress.Hen.EGG_READY
		) or (progress.day < ArrivalProgress.FISHING_DAY and arrival_state.caught_fish) or (
			progress.day < ArrivalProgress.COOKING_DAY and arrival_state.cooked_meal
		) or (progress.day < ArrivalProgress.FENCE_DAY and arrival_state.fence_index >= 0) or (
			progress.day < ArrivalProgress.DRAIN_DAY and arrival_state.drained
		) or (progress.day < ArrivalProgress.PRODUCE_DAY and progress.tutorial_completed):
			return null

	var saved_inventory: Variant = data.get("inventory")
	if not saved_inventory is Dictionary:
		return null
	progress.inventory.clear()
	for item_id in saved_inventory:
		if not item_id is String:
			return null
		if progress.arrival == null and item_id in [
			"water_spinach_seed", "water_spinach_produce", "malabar_spinach_seed", "malabar_spinach_produce",
		]:
			return null
		var is_gift: bool = item_id == ArrivalProgress.WELCOME_GIFT and progress.arrival != null and progress.arrival.lan_met
		var is_egg: bool = item_id == ArrivalProgress.EGG and progress.arrival != null
		var summer_item := progress.summer != null and version >= 13 and not SummerProgress.item_name(item_id).is_empty()
		var tutorial_item: bool = progress.detailed_tutorial_completed and (
			TutorialChapter.MARKET_PRICES.has(item_id) or item_id in TutorialChapter.CARRY_ITEMS
		)
		if not (CropCatalog.has_item(item_id) or (version >= 6 and FishCatalog.FISH.has(item_id)) or is_gift or is_egg or summer_item or tutorial_item):
			return null
		var count := read_integer(saved_inventory[item_id], 1, MAX_SAVE_INTEGER)
		if count < 1 or ((is_gift or (is_egg and version < 13)) and count != 1):
			return null
		progress.inventory[item_id] = count
	for crop_id in CropCatalog.HEIRLOOMS + CropCatalog.SUMMER_CROPS + CropCatalog.AUTUMN_CROPS:
		if not progress.seed_is_unlocked(crop_id):
			var crop: Dictionary = CropCatalog.CROPS[crop_id]
			if progress.quantity(crop.seed_item) > 0 or progress.quantity(crop.produce_item) > 0:
				return null
	var radish: Dictionary = CropCatalog.CROPS[CropCatalog.RADISH]
	if not progress.seed_is_unlocked(CropCatalog.RADISH) and (
		progress.quantity(radish.seed_item) > 0 or progress.quantity(radish.produce_item) > 0
	):
		return null

	var saved_plots: Variant = data.get("plots")
	if not saved_plots is Array or saved_plots.size() != progress.plots.size():
		return null
	var cells := progress._plot_save_cells()
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		var plot := progress.plots[cell]
		if not progress._read_plot(saved_plots[index], plot, version):
			return null
		if not plot.crop_id.is_empty() and not progress.seed_is_unlocked(plot.crop_id):
			return null
		if version < 22 and plot.crop_id in CropCatalog.AUTUMN_CROPS:
			progress.summer.autumn.sown |= 1 << CropCatalog.AUTUMN_CROPS.find(plot.crop_id)
		if plot.crop_id in [CropCatalog.STICKY_RICE, CropCatalog.PADDY_RICE] and (not progress.is_paddy(cell) or not plot.prepared):
			return null
		if plot.crop_id == CropCatalog.HEIRLOOM_CARROT and (not progress.is_heirloom_dry(cell) or not plot.prepared):
			return null
		if progress.arrival != null and index < PLOT_CELLS.size() and plot.tilled and progress.arrival.has_weeds(index):
			if version >= 10:
				return null
			progress.arrival.cleared_weeds |= 1 << index
		if progress.has_pest(cell):
			if plot.crop_id != CropCatalog.WATER_SPINACH or plot.watered_nights < 1 or (
				plot.watered_nights >= CropCatalog.CROPS[CropCatalog.WATER_SPINACH].growth_nights
			):
				return null
	if progress.arrival != null:
		if version < 13 and progress.arrival.hen == ArrivalProgress.Hen.EGG_COLLECTED and progress.quantity(ArrivalProgress.EGG) != 1:
			return null
		for crop_id in CropCatalog.GREENS:
			var crop: Dictionary = CropCatalog.CROPS[crop_id]
			if progress.day < 3 and (progress.quantity(crop.seed_item) > 0 or progress.quantity(crop.produce_item) > 0):
				return null
		# A v11 garden could sell or give away its entire first harvest before the stall existed.
		var starter: Dictionary = CropCatalog.CROPS[CropCatalog.WATER_SPINACH]
		if version == 11 and progress.arrival.seeds_taken and progress.coins < int(starter.buy_price) and (
			progress.quantity(starter.seed_item) == 0 and progress.quantity(starter.produce_item) == 0
		):
			var has_water_spinach := false
			for plot in progress.plots.values():
				if plot.crop_id == CropCatalog.WATER_SPINACH:
					has_water_spinach = true
					break
			if not has_water_spinach:
				progress.inventory[starter.seed_item] = 1
	if progress.summer != null and version < 21:
		progress._apply_storm_damage()
	return progress


func _read_relationships(saved: Variant) -> bool:
	if not saved is Dictionary or saved.size() != VillagerCatalog.IDS.size():
		return false
	for villager_id in VillagerCatalog.IDS:
		var entry: Variant = saved.get(villager_id)
		if not entry is Dictionary or not entry.get("event_seen") is bool:
			return false
		var points := read_integer(entry.get("points"), 0, MAX_SAVE_INTEGER)
		var last_gift_day := read_integer(entry.get("last_gift_day"), 0, day)
		if points < 0 or last_gift_day < 0 or (points == 0) != (last_gift_day == 0):
			return false
		if points > last_gift_day * VillagerCatalog.FAVORITE_POINTS:
			return false
		if entry.event_seen and points < VillagerCatalog.EVENT_POINTS:
			return false
		var relationship := relationships[villager_id]
		relationship.points = points
		relationship.last_gift_day = last_gift_day
		relationship.event_seen = entry.event_seen
	return true


func _read_plot(saved: Variant, plot: Plot, version: int) -> bool:
	if not saved is Dictionary or not saved.get("tilled") is bool or not saved.get("watered") is bool:
		return false
	var crop_id: Variant = saved.get("crop_id")
	if not crop_id is String:
		return false
	var nights := read_integer(saved.get("watered_nights"), 0, MAX_SAVE_INTEGER)
	if nights < 0:
		return false
	if crop_id.is_empty():
		if nights != 0 or saved.watered:
			return false
	else:
		if not saved.tilled or not CropCatalog.CROPS.has(crop_id):
			return false
		var growth_nights := crop_growth_nights(crop_id)
		if nights > growth_nights or (nights == growth_nights and saved.watered):
			return false
	plot.tilled = saved.tilled
	plot.crop_id = crop_id
	plot.watered_nights = nights
	plot.watered = saved.watered
	if version >= 21:
		if not saved.get("loosened") is bool or not saved.get("fertile") is bool:
			return false
		plot.loosened = saved.loosened
		plot.fertile = saved.fertile
		if (plot.loosened and (not plot.tilled or not plot.crop_id.is_empty())) or (plot.fertile and not plot.loosened and plot.crop_id not in CropCatalog.AUTUMN_CROPS):
			return false
	if version >= 17:
		if not saved.get("watered_twice") is bool or (saved.watered_twice and not plot.watered):
			return false
		plot.watered_twice = saved.watered_twice
	if version >= 18:
		plot.drought_stress = read_integer(saved.get("drought_stress"), 0, 2)
		if plot.drought_stress < 0 or (plot.crop_id.is_empty() and plot.drought_stress > 0):
			return false
	if version >= 13:
		if not saved.get("prepared") is bool or not saved.get("fertilized") is bool:
			return false
		if (saved.prepared and not plot.tilled) or (saved.fertilized and plot.crop_id.is_empty()):
			return false
		plot.prepared = saved.prepared
		plot.fertilized = saved.fertilized
	return true


static func _migrate_prototype(data: Dictionary) -> Dictionary:
	var prototype_goal := PROTOTYPE_SEED_COUNT * PROTOTYPE_SALE_PRICE
	var seeds := read_integer(data.get("seeds"), 0, PROTOTYPE_SEED_COUNT)
	var crops := read_integer(data.get("crops"), 0, PROTOTYPE_SEED_COUNT)
	var coins := read_integer(data.get("coins"), 0, prototype_goal)
	var old_plots: Variant = data.get("plots")
	if seeds < 0 or crops < 0 or coins < 0 or not old_plots is Array or old_plots.size() != PLOT_CELLS.size():
		return {}

	var planted := 0
	var saved_plots: Array[Dictionary] = []
	for old_plot in old_plots:
		if not old_plot is Dictionary or not old_plot.get("watered") is bool:
			return {}
		var stage := read_integer(old_plot.get("stage"), PrototypeStage.UNTILLED, PrototypeStage.RIPE)
		if stage < 0:
			return {}
		var has_crop := stage >= PrototypeStage.SEED
		planted += int(has_crop)
		saved_plots.append({
			"tilled": stage != PrototypeStage.UNTILLED,
			"crop_id": CropCatalog.CABBAGE if has_crop else "",
			"watered_nights": maxi(0, stage - PrototypeStage.SEED),
			"watered": old_plot.watered,
		})
	var cabbage: Dictionary = CropCatalog.CROPS[CropCatalog.CABBAGE]
	if (seeds + crops + planted) * PROTOTYPE_SALE_PRICE + coins != prototype_goal:
		return {}
	var inventory_data := {}
	if seeds > 0:
		inventory_data[cabbage.seed_item] = seeds
	if crops > 0:
		inventory_data[cabbage.produce_item] = crops
	return {
		"version": SAVE_VERSION,
		"day": data.get("day"),
		"coins": coins,
		"inventory": inventory_data,
		"selected_crop": CropCatalog.CABBAGE,
		"tutorial_completed": coins >= prototype_goal,
		"plots": saved_plots,
	}


static func read_integer(value: Variant, minimum: int, maximum: int) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return -1
	if not (value >= minimum and value <= maximum) or value != floor(value):
		return -1
	return int(value)
