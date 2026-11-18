extends Node2D

const TILE_SIZE := PixelArt.CELL
const MAP_SIZE := Vector2i(20, 12)
const WALKABLE_AREA := Rect2i(1, 1, 18, 10)
const HOUSE := Rect2i(3, 2, 3, 2)
const BIN := Rect2i(7, 2, 2, 2)
const TREE := Rect2i(15, 2, 2, 2)
const DOOR_CELL := Vector2i(4, 3)
const VILLAGE_GATE := Vector2i(19, 6)
const ARRIVAL_GATE := Vector2i(18, 6)
const STRAY_DOG := Vector2i(8, 7)
const DOG_HOME := Vector2i(5, 5)
const SEED_BOX := Vector2i(8, 5)
const DAD_CELL := Vector2i(6, 4)
const CAT_CELL := Vector2i(3, 5)
const COOP := Vector2i(10, 10)
const TROUGH := Vector2i(11, 10)
const FENCE_SIGN := Vector2i(12, 9)
const DITCH := GardenProgress.DITCH_CELL
const FARMHOUSE_ART := preload("res://assets/art/32/farmhouse.png")
const TUTORIAL_ART := preload("res://assets/art/32/tutorial_props.png")
const SUMMER_ART := preload("res://assets/art/32/summer_props.png")
const QUIET_FARM_ART := preload("res://assets/art/32/quiet_farm.png")
const FESTIVAL_ART := preload("res://assets/art/32/village_festival.png")
const SOCIAL_ART := preload("res://assets/art/32/village_social.png")
const CRAFT_ART := preload("res://assets/art/32/summer_craft.png")
const DROUGHT_ART := preload("res://assets/art/32/drought.png")
const LATE_SUMMER_ART := preload("res://assets/art/32/late_summer.png")
const BAMBOO_WORKS_ART := preload("res://assets/art/32/bamboo_works.png")
const AUTUMN_WORK_ART := preload("res://assets/art/32/autumn_work.png")
const STOREHOUSE_ART := preload("res://assets/art/32/storehouse.png")
const DROUGHT_SOIL := Vector2i(0, 0)
const TUAN_DISTRICT := Vector2i(2, 6)
const COOP_EXTENSION := Vector2i(12, 10)
const OUTLINE_COLOR := Color("#fff1bd")
const SOIL_UNTILLED := Vector2i(2, 0)
const SOIL_DRY := Vector2i(3, 0)
const SOIL_WET := Vector2i(4, 0)
const DEMO_CLOCK_STEP_SECONDS := 4.0
const ARRIVAL_CLOCK_STEP_SECONDS := 6.25
const SEED_ACTIONS := [&"select_cabbage", &"select_carrot", &"select_radish", &"select_cucumber"]

const PlotAction := GardenProgress.PlotAction

@onready var ground: TileMapLayer = $Ground
@onready var features: Node2D = $Ground/Features
@onready var player: Sprite2D = $Ground/Features/Player
@onready var overlay: Node2D = $Ground/Overlay
@onready var status: Label = $HUD/Status
@onready var hint: Label = $HUD/Hint
@onready var tutorial: Label = $HUD/Tutorial
@onready var seed_icon: TextureRect = $HUD/SeedIcon
@onready var seed_selection: Label = $HUD/SeedSelection
@onready var save_warning: Label = $HUD/SaveWarning
@onready var farm_panel: FarmPanel = $HUD/FarmPanel
@onready var journal: JournalPanel = $HUD/Journal
@onready var village_panel: VillagePanel = $HUD/VillagePanel
@onready var fishing_panel: FishingPanel = $HUD/FishingPanel
@onready var area_label: Label = $HUD/Area
@onready var weather_label: Label = $HUD/Weather
@onready var rain: ColorRect = $Ground/Rain
@onready var daylight: CanvasModulate = $Daylight
@onready var farmhouse: Farmhouse = $Ground/Farmhouse
@onready var sickle_cut: Sprite2D = $Ground/Overlay/SickleCut

var progress: GardenProgress
var opening_finished := false
var tutorial_handoff := false
var player_cell := Vector2i(5, 6)
var facing := Vector2i.RIGHT
var crop_sprites: Dictionary[Vector2i, Sprite2D] = {}
var weed_sprites: Dictionary[Vector2i, Sprite2D] = {}
var pest_sprites: Dictionary[Vector2i, Sprite2D] = {}
var seed_box: Sprite2D
var dad: Sprite2D
var cat: Sprite2D
var dog: Sprite2D
var dog_walk: Tween
var cut_animation: Tween
var crop_atlases: Dictionary[String, Texture2D] = {}
var seed_icons: Dictionary[String, Texture2D] = {}
var step: Tween
var left_step := false
var clock_elapsed := 0.0
var map_props: Array[Sprite2D] = []
var plot_page_edges: Array[ColorRect] = []
var story_shirt_texture: ImageTexture
var npc_sprites: Array[Sprite2D] = []
var npc_cells: Array[Vector2i] = []
var event_people: Dictionary[Vector2i, Sprite2D] = {}
var move_destination := Vector2i(-1, -1)
var market_booth: Sprite2D
var activity_marker: Tween
var activity_cell := Vector2i.ZERO
var activity_alpha := 0.0
var fence_editing := false
var coop_sprite: Sprite2D
var trough_sprite: Sprite2D
var fence_sprite: Sprite2D
var ditch_sprite: Sprite2D
var workshop: SummerWorkshop
var story_action := Callable()
var alternative_story_action := Callable()
var cart_sprite: Sprite2D
var drying_sprites: Array[Sprite2D] = []
var festival_panel: FestivalPanel
var embroidery_panel: EmbroideryPanel
var fine_weave_panel: FineWeavePanel
var lotus_cast := false
var story_cast := false
var lantern_tween: Tween
var lantern_offset := 0.0
var boat: Sprite2D
var drift := Vector2i.ZERO
var paddle_time := 0.0
var harvest_hold := -1.0
var interact_held := false
var weaving := false
var weave_score := 0
var weave_round := 0
var weave_timer := 0.0
var weave_meter: ProgressBar
var late_audio := LateSummerAudio.new()
var works_elapsed := 0.0
var works_save_seconds := 0
var storm_status := Label.new()
var storm_hold_target := Vector2i(-1, -1)
var storm_hold_time := 0.0


func _ready() -> void:
	if progress == null:
		progress = GardenSave.read().progress
		if progress == null:
			progress = GardenProgress.new()
	_load_crop_art()
	_apply_work_shirt()
	if progress.summer_story != null:
		for x in [0, 704]:
			var edge := ColorRect.new()
			edge.position = Vector2(x, 80)
			edge.size = Vector2(64, 384)
			edge.color = Color("19271e")
			edge.z_index = 12
			edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(edge)
			plot_page_edges.append(edge)
	overlay.draw.connect(_draw_overlay)
	farm_panel.setup(seed_icons)
	farm_panel.item_pressed.connect(_on_panel_item)
	farm_panel.close_requested.connect(farm_panel.hide)
	farm_panel.switch_bag.pressed.connect(_switch_inventory)
	village_panel.action_requested.connect(_on_village_action)
	village_panel.switch_order.pressed.connect(_switch_order)
	fishing_panel.cast_finished.connect(_on_cast_finished)
	journal.note_changed.connect(_save_field_note)
	workshop = SummerWorkshop.new()
	$HUD.add_child(workshop)
	workshop.basket_finished.connect(_basket_finished)
	workshop.sprinkler_finished.connect(_sprinkler_finished)
	workshop.construction_requested.connect(_construction_requested)
	workshop.bamboo_split.connect(_finish_bamboo_split)
	workshop.mat_finished.connect(_finish_drying_mat)
	festival_panel = FestivalPanel.new()
	$HUD.add_child(festival_panel)
	festival_panel.name_saved.connect(_name_chick)
	festival_panel.mill_done.connect(_mill_done)
	festival_panel.dish_chosen.connect(_dish_chosen)
	festival_panel.match_finished.connect(_wrestling_finished)
	festival_panel.training_finished.connect(_complete_training)
	festival_panel.reply_chosen.connect(_boss_reply)
	festival_panel.lan_choice_chosen.connect(_lan_choice)
	embroidery_panel = EmbroideryPanel.new()
	$HUD.add_child(embroidery_panel)
	embroidery_panel.finished.connect(_embroidery_finished)
	embroidery_panel.advanced_finished.connect(_advanced_embroidery_finished)
	fine_weave_panel = FineWeavePanel.new()
	$HUD.add_child(fine_weave_panel)
	fine_weave_panel.finished.connect(_finish_fine_weave)
	add_child(late_audio)
	storm_status.position = Vector2(64, 53)
	storm_status.add_theme_font_size_override("font_size", 17)
	storm_status.add_theme_color_override("font_color", Color("#ffcf8d"))
	storm_status.hide()
	$HUD.add_child(storm_status)
	boat = Sprite2D.new()
	boat.texture = PixelArt.atlas_frame(LATE_SUMMER_ART, 5)
	boat.offset.y = -TILE_SIZE * 0.5
	boat.show_behind_parent = true
	player.add_child(boat)
	weave_meter = ProgressBar.new()
	weave_meter.position = Vector2(28, 156)
	weave_meter.size = Vector2(556, 30)
	weave_meter.show_percentage = false
	var target_mark := ColorRect.new()
	target_mark.position = Vector2(276, 0)
	target_mark.size = Vector2(4, 30)
	target_mark.color = Color("#ebd99b")
	target_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weave_meter.add_child(target_mark)
	village_panel.heading.get_parent().add_child(weave_meter)
	weave_meter.hide()
	village_panel.visibility_changed.connect(_close_cargo_weaving)
	if progress.area == GardenProgress.Area.LOTUS_POND:
		player_cell = LateSummerMap.POND_SPAWN
	elif _in_works_site():
		player_cell = BambooWorksMap.SPAWN
	elif _in_festival():
		player_cell = FestivalMap.EXIT + Vector2i.RIGHT
	elif _in_district() or progress.area == GardenProgress.Area.COUNTY_FAIR:
		player_cell = SummerMap.EXIT + Vector2i.RIGHT
	elif _in_village():
		player_cell = VillageMap.EXIT_CELL + Vector2i.RIGHT
	elif _in_house():
		player_cell = Farmhouse.ENTRANCE
		facing = Vector2i.UP
	elif progress.day == 11 and progress.detailed_tutorial_completed and not progress.summer.cart_sale:
		player_cell = Vector2i(7, 4)
		facing = Vector2i.UP
	elif progress.arrival != null:
		player_cell = ARRIVAL_GATE
		facing = Vector2i.LEFT
	_rebuild_map()
	progress.start_summer_storm()
	_sync_storm_status()
	_update_weather()
	_update_status()
	_update_feedback()
	if tutorial_handoff:
		village_panel.open_dialogue("Ngày 11 · Chuyến hàng đầu tiên", "Trưởng thôn cho mượn xe thồ. Chất hàng ở thùng rồi gặp Lão Lái Buôn tại chợ làng, gần bến sông. Ruộng cũ vẫn ở sau cổng tre phía đông vườn.")
	if opening_finished:
		_save_progress()


func _physics_process(delta: float) -> void:
	var held := Input.is_action_pressed("interact")
	var interact_pressed := (held and not interact_held) or (not held and Input.is_action_just_pressed("interact"))
	interact_held = held
	_tick_works(delta)
	if fine_weave_panel.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			fine_weave_panel.hide()
		else:
			fine_weave_panel.tick(delta)
		return
	if weaving and village_panel.visible:
		weave_timer += delta
		weave_meter.value = fposmod(weave_timer, 1.5) / 1.5 * 100.0
		if interact_pressed:
			_weave_cargo_beat()
	if embroidery_panel.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			embroidery_panel.hide()
		return
	if festival_panel.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			festival_panel.hide()
		return
	if workshop.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			workshop.hide()
		return
	if fishing_panel.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			fishing_panel.cancel()
			lotus_cast = false
			story_cast = false
		elif interact_pressed:
			fishing_panel.reel()
		return

	if Input.is_action_just_pressed("ui_cancel"):
		if village_panel.visible:
			village_panel.hide()
			return
		if journal.visible:
			journal.hide()
			return
		if farm_panel.visible:
			farm_panel.hide()
			return
		if fence_editing:
			fence_editing = false
			_update_feedback()
			return
		if (save_warning.visible or progress.storm_active() or (progress.summer != null and progress.summer.works.batch_count > 0)) and not _save_progress():
			return
		get_tree().change_scene_to_file("res://title.tscn")
		return

	if step and step.is_running():
		_tick_clock(delta)
		return

	if village_panel.visible:
		return

	if Input.is_action_just_pressed("journal"):
		if journal.visible:
			journal.hide()
		elif not farm_panel.visible:
			journal.open(progress)
		return

	if journal.visible:
		return

	if Input.is_action_just_pressed("inventory"):
		if not farm_panel.visible:
			farm_panel.open(FarmPanel.Mode.BAG, progress)
		elif farm_panel.mode != FarmPanel.Mode.SHOP:
			farm_panel.hide()
		return

	if not farm_panel.visible or farm_panel.mode == FarmPanel.Mode.BAG:
		var shortcuts := progress.shop_crop_ids()
		for index in range(mini(shortcuts.size(), SEED_ACTIONS.size())):
			if Input.is_action_just_pressed(SEED_ACTIONS[index]):
				_select_seed(shortcuts[index])
				return

	if farm_panel.visible:
		return

	if _hold_storm_tarp(delta):
		_tick_clock(delta)
		return
	if interact_pressed:
		harvest_hold = 0.0 if _can_bulk_harvest(player_cell + facing) else -1.0
		drift = Vector2i.ZERO
		paddle_time = 0.0
		_interact()
		return
	if harvest_hold >= 0.0:
		if not held or _move_direction() != Vector2i.ZERO:
			harvest_hold = -1.0
		else:
			harvest_hold += delta
			if harvest_hold >= 0.6:
				harvest_hold = -1.0
				_harvest_summer_field()
	if Input.is_action_just_pressed("fertilize") and progress.area == GardenProgress.Area.GARDEN:
		var target := player_cell + facing
		if progress.autumn_soil_available(target):
			var prepared := progress.prepare_autumn_soil(target)
			_update_plot(target)
			if prepared > 0:
				_commit_progress()
				_flash_interaction(target)
				hint.text = "Đất đã tơi · F để bón lót" if prepared == 1 else "Đã bón lót · Cây vụ thu lớn nhanh hơn 10%"
			else:
				hint.text = "Luống đã bón lót" if progress.plots[target].fertile else "Cần thêm phân thảo mộc hoặc thể lực"
			return
		var dressed := progress.dress_summer_plot(target)
		if dressed or progress.fertilize(target):
			_update_plot(target)
			_commit_progress()
			_flash_interaction(target)
			hint.text = "Đã tưới thúc · Cây sắp chín" if dressed else "Đã bón phân · Có tác dụng sau đêm đủ ẩm"
		return
	if Input.is_action_just_pressed("drink") and progress.drink_cane_juice():
		_commit_progress()
		hint.text = "Nước mía · +15 thể lực"
		return

	_tick_clock(delta)
	var direction := _move_direction()
	if progress.area == GardenProgress.Area.LOTUS_POND:
		if direction == Vector2i.ZERO:
			var pads := Input.get_connected_joypads()
			if not pads.is_empty():
				var stick := Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X), Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_Y))
				if stick.length() > 0.5:
					direction = Vector2i(signf(stick.x), 0) if absf(stick.x) > absf(stick.y) else Vector2i(0, signf(stick.y))
		if direction == Vector2i.ZERO:
			direction = drift
			drift = Vector2i.ZERO
			paddle_time = 0.0
		else:
			paddle_time += 0.13
			drift = direction if paddle_time > 0.15 else Vector2i.ZERO
	if direction == Vector2i.ZERO:
		return

	facing = direction
	var destination := player_cell + facing
	if _can_walk(destination):
		_move(destination)
	else:
		_update_feedback()


func _tick_clock(delta: float) -> void:
	if progress.minute_of_day >= GardenCalendar.LAST_MINUTE:
		return
	clock_elapsed += delta
	var interval := DEMO_CLOCK_STEP_SECONDS if progress.arrival == null else ARRIVAL_CLOCK_STEP_SECONDS
	if clock_elapsed < interval:
		return
	clock_elapsed -= interval
	if progress.advance_clock():
		if progress.summer_story != null and progress.day == SummerProgress.CITY_LETTER_DAY and progress.minute_of_day == 720 and not progress.summer.read_city_letter:
			if _in_house():
				_deliver_city_letter()
		_sync_event_people()
		_update_feedback()
		if progress.storm_active() and not storm_status.visible:
			_announce_storm()
		_update_clock()
		if progress.day in [AutumnWork.SOIL_DAY, AutumnWork.REST_DAY] and progress.minute_of_day == 16 * 60:
			_update_weather()
		if progress.area == GardenProgress.Area.GARDEN and progress.summer_available(AutumnWork.AUTUMN_DAY):
			for cell in progress.plots:
				if progress.plots[cell].fertile and progress.plots[cell].crop_id in CropCatalog.AUTUMN_CROPS:
					_update_plot(cell)
		_save_progress()
		if progress.minute_of_day == GardenCalendar.START_MINUTE and progress.summer_available(VillageSocial.TRAINING_DAY):
			_update_weather()
		var stationary := not step or not step.is_running()
		if _in_village():
			_sync_npcs()
			_update_market()
			_refresh_drying_rice()
		if progress.area == GardenProgress.Area.GARDEN and progress.summer_available(SummerProgress.QUIET_DAY):
			overlay.queue_redraw()
		if _in_festival():
			_update_weather()
			_update_feedback()
		if stationary and (_in_village() or progress.minute_of_day == GardenCalendar.LAST_MINUTE):
			_update_feedback()
		elif stationary and progress.in_drought() and progress.minute_of_day in [12 * 60, DroughtProgress.SECOND_PASS]:
			_update_feedback()
		if progress.summer_available(LateSummer.HARVEST) and progress.day == LateSummer.HARVEST and progress.minute_of_day == 17 * 60:
			if stationary and progress.area == GardenProgress.Area.GARDEN and not progress.summer.late.hat:
				_offer_harvest_hat()


func _tick_works(delta: float) -> void:
	if progress.area == GardenProgress.Area.FORGE:
		overlay.queue_redraw()
	if not progress.summer_available(BambooWorks.RESTORE_DAY):
		return
	if progress.start_summer_storm() or (progress.storm_active() and not storm_status.visible):
		_announce_storm()
	var state := progress.summer.works
	if state.batch_count == 0 and not progress.storm_active():
		works_elapsed = 0
		return
	works_elapsed += delta
	if works_elapsed < 1.0:
		return
	var seconds := floori(works_elapsed)
	works_elapsed -= seconds
	var was_storm := progress.storm_active()
	var old_count := state.batch_count
	var old_product := state.batch_product
	progress.advance_workshop_seconds(seconds)
	works_save_seconds += seconds
	_sync_storm_status()
	if village_panel.visible and village_panel.mode == VillagePanel.Mode.BAMBOO_MACHINE:
		village_panel.refresh_bamboo_machine()
	var batch_changed := old_count != state.batch_count or old_product != state.batch_product
	if batch_changed and progress.can_use_bamboo_machine():
		late_audio.play_effect(&"splitter")
	if was_storm and not progress.storm_active():
		_update_status()
		if state.repair_step > 0:
			hint.text = "Kho bị ướt · Giá đơn giảm 30%" if state.storm_damage else "Tre và sọt trong kho đã an toàn"
		_update_weather()
	if works_save_seconds >= 5 or batch_changed or was_storm != progress.storm_active():
		works_save_seconds = 0
		_save_progress()


func _announce_storm() -> void:
	_sync_storm_status()
	_update_weather()
	late_audio.play_effect(&"thunder")
	_update_feedback()
	hint.text = "Giông đến · Giữ E để che kho và chuồng"


func _sync_storm_status() -> void:
	storm_status.visible = progress.storm_active()
	if not storm_status.visible:
		return
	var state := progress.summer.works
	var count := int((state.protection & BambooWorks.RAW_TARP) != 0) + int((state.protection & BambooWorks.GOODS_TARP) != 0)
	var timer := GardenCalendar.format_time(state.storm_left)
	var tasks := "Kho %d/2 · " % count if state.repair_step > 0 else ""
	storm_status.text = "GIÔNG %s · %sChuồng %s" % [timer, tasks, "đã che" if state.protection & BambooWorks.COOP_TARP else "chưa che"]
	seed_icon.hide()
	seed_selection.hide()


func _draw_overlay() -> void:
	if progress.area == GardenProgress.Area.FORGE:
		var hearth := _feet_position(BambooWorksMap.HEARTH) - Vector2(0, 13)
		overlay.draw_circle(hearth, 24, Color(0.98, 0.49, 0.21, 0.10))
		var frame := floori(Time.get_ticks_msec() / 65.0)
		for index in 5:
			var age := (frame + 7 * index) % 23
			var point := hearth + Vector2((index - 2) * (2 + age / 8.0), -age)
			overlay.draw_rect(Rect2(point, Vector2(2, 2)), Color(1.0, 0.65, 0.19, 1.0 - age / 24.0))
	if _in_festival():
		_draw_festival()
	elif _in_village() and progress.summer_available(VillageFestival.NOTICE_DAY) and progress.day <= VillageFestival.FAIR_DAY:
		for cell in FestivalMap.LIGHTS:
			_draw_light(Vector2(cell * TILE_SIZE) + Vector2(10, 8), Color("#c3503d"))
	if progress.summer_available(LateSummer.FIRST_FAIR) and progress.day == LateSummer.FIRST_FAIR and (
		not _in_house() and progress.minute_of_day < GardenCalendar.START_MINUTE
	):
		overlay.draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE * TILE_SIZE)), Color("#c5d8de44"))
		for index in 5:
			overlay.draw_rect(Rect2(0, 45 + index * 68, MAP_SIZE.x * TILE_SIZE, 14 + index * 2), Color("#e6eecb24"))
		var flame := player.position + Vector2(9, -10)
		overlay.draw_rect(Rect2(flame - Vector2(5, 5), Vector2(12, 12)), Color("#f4bc6250"))
		overlay.draw_rect(Rect2(flame, Vector2(3, 4)), Color("#ffdb9c"))
	if progress.area == GardenProgress.Area.GARDEN:
		for cell in progress.plots:
			var plot := progress.plots[cell]
			if plot.loosened and plot.crop_id.is_empty():
				var base := Vector2(cell * TILE_SIZE)
				var color := Color("#d6dc8b") if plot.fertile else Color("#bdb188")
				for side in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
					var start := base + Vector2(2, 2)
					if side in [Vector2.DOWN, Vector2.LEFT]:
						start.x += 28
					if side in [Vector2.LEFT, Vector2.UP]:
						start.y += 28
					overlay.draw_dashed_line(start, start + side * 28, color, 1.0, 4.0)
		if progress.in_drought():
			var drought := progress.summer.drought
			if progress.summer.sprinkler >= 0 and drought.oil == 0:
				var pump_point := _feet_position(SummerMap.PUMP) + Vector2(-3, -28)
				overlay.draw_rect(Rect2(pump_point, Vector2(5, 4)), Color("#db6950"))
		const FENCE_INSET := 14
		var right := float(MAP_SIZE.x * TILE_SIZE - FENCE_INSET)
		var bottom := float(MAP_SIZE.y * TILE_SIZE - FENCE_INSET)
		var top_gate := float(VILLAGE_GATE.y * TILE_SIZE)
		var points := PackedVector2Array([
			Vector2(right, top_gate), Vector2(right, FENCE_INSET), Vector2(FENCE_INSET, FENCE_INSET),
			Vector2(FENCE_INSET, bottom), Vector2(right, bottom), Vector2(right, top_gate + TILE_SIZE),
		])
		overlay.draw_polyline(points, Color("#563e2b"), 6.0)
		overlay.draw_polyline(points, Color("#a57a50"), 2.0)
		if (progress.summer_available(SummerProgress.QUIET_DAY) and progress.minute_of_day >= 18 * 60 + 30) or (
			progress.summer_story != null and progress.day == SummerProgress.SOLO_DAY and progress.minute_of_day >= 17 * 60 + 30
		):
			for index in 7:
				var point := Vector2(SummerMap.BAMBOO * TILE_SIZE) + Vector2((index * 13) % 59 - 24, (index * 17) % 50 - 9)
				overlay.draw_rect(Rect2(point, Vector2(2, 2)), Color("#e8d38b"))
		if progress.is_flooded(GardenProgress.LOW_PLOT):
			var origin := Vector2(GardenProgress.LOW_PLOT * TILE_SIZE)
			var water := Color("#73b5baac")
			var gleam := Color("#b7d5cae0")
			overlay.draw_rect(Rect2(origin + Vector2(3, 4), Vector2(10, 3)), water)
			overlay.draw_rect(Rect2(origin + Vector2(19, 8), Vector2(10, 3)), water)
			overlay.draw_rect(Rect2(origin + Vector2(3, 25), Vector2(25, 4)), water)
			overlay.draw_rect(Rect2(origin + Vector2(7, 26), Vector2(10, 1)), gleam)
			overlay.draw_rect(Rect2(origin + Vector2(22, 9), Vector2(5, 1)), gleam)
	var target := player_cell + facing
	if fence_editing:
		var area := GardenProgress.FENCE_AREA
		for y in range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				var color := Color("#c99768") if Vector2i(x, y) == progress.fence_cell() else Color("#bada91")
				overlay.draw_rect(Rect2(x * TILE_SIZE + 1, y * TILE_SIZE + 1, 30, 30), color, false, 1)
	if _is_interactive(target):
		var corner := Vector2(target * TILE_SIZE)
		overlay.draw_rect(Rect2(corner + Vector2(2, 2), Vector2(28, 28)), OUTLINE_COLOR, false, 2.0)
	if activity_alpha > 0.0:
		var corner := Vector2(activity_cell * TILE_SIZE) + Vector2(4, 4)
		overlay.draw_rect(Rect2(corner, Vector2(24, 24)), Color(1.0, 0.88, 0.58, activity_alpha))


func _rebuild_map() -> void:
	_show_farm_page(progress.area == GardenProgress.Area.GARDEN and player_cell.x >= 20)
	drift = Vector2i.ZERO
	paddle_time = 0.0
	harvest_hold = -1.0
	storm_hold_target = Vector2i(-1, -1)
	storm_hold_time = 0.0
	boat.visible = progress.area == GardenProgress.Area.LOTUS_POND
	if lantern_tween and lantern_tween.is_running():
		lantern_tween.kill()
	lantern_offset = 0.0
	for prop in map_props:
		prop.queue_free()
	for sprite in crop_sprites.values():
		sprite.queue_free()
	map_props.clear()
	crop_sprites.clear()
	weed_sprites.clear()
	pest_sprites.clear()
	seed_box = null
	dad = null
	cat = null
	dog = null
	dog_walk = null
	if cut_animation and cut_animation.is_running():
		cut_animation.kill()
	sickle_cut.hide()
	npc_sprites.clear()
	npc_cells.clear()
	event_people.clear()
	market_booth = null
	cart_sprite = null
	drying_sprites.clear()
	fence_editing = false
	coop_sprite = null
	trough_sprite = null
	fence_sprite = null
	ditch_sprite = null
	activity_alpha = 0.0
	if activity_marker and activity_marker.is_running():
		activity_marker.kill()
	ground.clear()
	farmhouse.hide()
	if _in_house():
		farmhouse.summer_story = progress.summer_story
		farmhouse.refresh(progress.arrival, progress.yard_open(), progress.day, progress.summer.craft)
		player.position = _feet_position(player_cell)
		area_label.text = "Nhà cũ"
		_sync_event_people()
		return
	_build_ground()
	if _in_works_site():
		_place_works_site()
		player.position = _feet_position(player_cell)
		area_label.text = "Lò rèn đầu làng" if progress.area == GardenProgress.Area.FORGE else "Xưởng tre Cụ Hai"
		if progress.area == GardenProgress.Area.STOREHOUSE:
			area_label.text = "Nhà kho · Góc xưởng"
		return
	if boat.visible or progress.area == GardenProgress.Area.COUNTY_FAIR:
		_place_late_summer_features()
		player.position = _feet_position(player_cell)
		area_label.text = "Đầm sen làng" if boat.visible else "Phiên Chợ Huyện"
		return
	_place_features()
	if progress.area == GardenProgress.Area.GARDEN:
		_place_plots()
		_place_yard()
		_place_tutorial_props()
	_place_summer_features()
	_place_craft_features()
	_place_drought_features()
	_place_late_summer_features()
	_place_works_outdoors()
	if progress.area == GardenProgress.Area.GARDEN and progress.summer_available(AutumnWork.INVEST_DAY):
		if progress.summer.autumn.built & 2:
			_add_prop(AUTUMN_WORK_ART, _feet_position(AutumnWork.WAREHOUSE), TILE_SIZE, 6, 3)
		if progress.has_storehouse():
			_storehouse_prop(StorehouseMap.ENTRY, 0)
		if progress.day in [AutumnWork.SOIL_DAY, AutumnWork.WORKROOM_FINISH]:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.LY), TILE_SIZE, 8, 5)
	player.position = _feet_position(player_cell)
	area_label.text = "Làng ven sông" if _in_village() else (
		"Đình làng · Sông Cầu" if _in_festival() else ("Chợ huyện" if _in_district() else ("Vườn nhỏ · Làng →" if progress.can_visit_village() else "Vườn nhỏ"))
	)
	if progress.area == GardenProgress.Area.GARDEN and player_cell.x >= 20:
		area_label.text = "Vườn sau · Góc ao của ông"
	_sync_event_people()


func _show_farm_page(back_field: bool) -> void:
	ground.position = Vector2(64 - (640 if back_field else 0), 80)
	rain.position.x = 640 if back_field else 0
	for edge in plot_page_edges:
		edge.visible = progress.area == GardenProgress.Area.GARDEN


func _cross_farm_gate() -> void:
	var arriving := player_cell.x < 20
	player_cell = Vector2i(21, 4) if arriving else Vector2i(18, 4)
	facing = Vector2i.RIGHT if arriving else Vector2i.LEFT
	player.position = _feet_position(player_cell)
	_show_farm_page(arriving)
	if progress.day == SummerProgress.MAI_DAY and is_instance_valid(dog):
		dog.position = player.position - Vector2(14, 4)
	area_label.text = "Vườn sau · Góc ao của ông" if arriving else "Vườn nhỏ · Làng →"
	_update_feedback()


func _story_farm_hint(cell: Vector2i) -> String:
	if progress.summer_story == null:
		return ""
	match cell:
		SummerStory.FARM_GATE: return "E · Qua cổng tre tới vườn sau"
		SummerStory.FARM_EXIT: return "E · Về sân gạch"
		SummerStory.FISHING: return "E · Câu cá bống trong ao"
		SummerStory.MAI:
			if _event_npc_present(cell):
				return "[E] Trò chuyện với Mai"
		SummerStory.POSTMAN:
			if _event_npc_present(cell):
				return "[E] Nhận thư từ bưu tá"
		SummerStory.GINGER:
			if progress.day == SummerProgress.RAIN_DAY and not progress.summer_story.done("picked_ginger"):
				return "E · Hái gừng rừng để nấu cháo"
		SummerStory.FAMILY_VIEW:
			if _event_npc_present(cell):
				return "[E] Cùng bố mẹ xem đất của ông"
		SummerStory.PUMP, SummerStory.WELL:
			if progress.summer_available(SummerProgress.PUMP_DAY) and progress.summer.parents_visited:
				return "E · Kiểm tra máy bơm" if cell == SummerStory.PUMP else "E · Nối ống ra luống"
	return ""


func _interact_story_farm(cell: Vector2i) -> void:
	match cell:
		SummerStory.FARM_GATE, SummerStory.FARM_EXIT:
			_cross_farm_gate()
		SummerStory.MAI:
			progress.summer.met_mai = true
			_rebuild_map()
			_commit_progress()
			village_panel.open_dialogue("Mai ngoài hàng rào", "Hôm qua thấy anh ra cổng tre sau vườn. Ông ngoại anh hay trồng cà rốt cạnh ao, năm nào cũng đem cho nhà em một mớ.")
		SummerStory.POSTMAN:
			_deliver_city_letter()
		SummerStory.GINGER:
			progress.summer_story.mark("picked_ginger")
			progress._add_items(VillageFestival.GINGER, 1)
			_rebuild_map()
			_commit_progress()
			village_panel.open_dialogue("Gừng rừng", "Có thể dùng gừng, trứng và gạo để nấu cháo ở nhà.")
		SummerStory.FAMILY_VIEW:
			progress.summer_story.mark("family_walk")
			_rebuild_map()
			_commit_progress()
			village_panel.open_dialogue("Mẹ ở bờ ao", "Mẹ chưa ra đây từ hồi ông mất. Luống cà rốt của ông cũng ở ngay chỗ này. Trồng lên được như con là ông mừng lắm.")
		SummerStory.FISHING:
			if progress.minute_of_day < GardenCalendar.LAST_MINUTE:
				story_cast = true
				fishing_panel.cast(FishCatalog.GOBY, 2.0)
		SummerStory.PUMP:
			_interact_summer(SummerMap.PUMP)
		SummerStory.WELL:
			_interact_summer(SummerProgress.WELL_CELL)


func _story_tank_at(cell: Vector2i) -> bool:
	return progress.summer_story != null and progress.summer_story.purchases.has("tank") and cell == SummerMap.AQUARIUM


func _deliver_city_letter() -> void:
	progress.summer_story.mark("post")
	progress.summer.read_city_letter = true
	if not _in_house():
		_rebuild_map()
	_commit_progress()
	village_panel.open_dialogue("Thư từ thành phố", "Bưu tá đưa Hoàng một phong bì. Đồng nghiệp cũ hỏi thăm và nhắn rằng dự án mới ở Hà Nội đang cần người. Hoàng cất thư cạnh lá thư của ông trong tủ chè.")


func _build_ground() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ground.tile_set = tiles
	if _in_works_site():
		BambooWorksMap.paint(ground, MAP_SIZE, BAMBOO_WORKS_ART, progress.area == GardenProgress.Area.FORGE,
			progress.area == GardenProgress.Area.STOREHOUSE)
		return
	if progress.area == GardenProgress.Area.LOTUS_POND:
		LateSummerMap.paint_pond(ground, MAP_SIZE, LATE_SUMMER_ART)
		return
	if _in_festival():
		FestivalMap.paint(ground, MAP_SIZE)
		return
	if _in_district() or progress.area == GardenProgress.Area.COUNTY_FAIR:
		SummerMap.paint_district(ground, MAP_SIZE)
		return
	if _in_village():
		VillageMap.paint_ground(ground, MAP_SIZE)
		return

	var atlas := TileSetAtlasSource.new()
	atlas.texture = preload("res://assets/art/32/terrain.png")
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for column in range(9):
		atlas.create_tile(Vector2i(column, 0))

	tiles.add_source(atlas, 0)
	if progress.in_drought():
		var dry_atlas := TileSetAtlasSource.new()
		dry_atlas.texture = DROUGHT_ART
		dry_atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		dry_atlas.create_tile(DROUGHT_SOIL)
		tiles.add_source(dry_atlas, 2)

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var path := (y == 6 and x >= 3) or (x == 4 and y >= 4 and y <= 6)
			var variant := (x * 23 + y * 41 + x * y * 7) % 19
			var tile := 0
			if path:
				tile = 8 if variant < 6 else 1
			elif variant < 9:
				tile = 5 + variant % 3
			ground.set_cell(Vector2i(x, y), 0, Vector2i(tile, 0))
	if progress.summer_story != null:
		var brick := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
		brick.fill(Color("ab6e53"))
		for brick_y in [0, 8, 16, 24]:
			brick.fill_rect(Rect2i(0, brick_y, 32, 1), Color("7e4e42"))
			for brick_x in range(8 if brick_y % 16 == 0 else 0, 32, 16):
				brick.fill_rect(Rect2i(brick_x, brick_y, 1, 8), Color("865141"))
		var paving := TileSetAtlasSource.new()
		paving.texture = ImageTexture.create_from_image(brick)
		paving.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		paving.create_tile(Vector2i.ZERO)
		tiles.add_source(paving, 4)
		for yard_y in range(4, 7):
			for yard_x in range(2, 8):
				ground.set_cell(Vector2i(yard_x, yard_y), 4, Vector2i.ZERO)
		var water := TileSetAtlasSource.new()
		water.texture = preload("res://assets/art/32/village_terrain.png")
		water.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		for column in [5, 6]:
			water.create_tile(Vector2i(column, 0))
		tiles.add_source(water, 3)
		for y in MAP_SIZE.y:
			for x in range(20, SummerStory.FARM_RIGHT + 1):
				var cell := Vector2i(x, y)
				var tile := 1 if (y == 4 and x < 29) or (x == 28 and y >= 4) else 5 + (x + y * 2) % 3
				if SummerStory.POND.has_point(cell):
					ground.set_cell(cell, 3, Vector2i(6 if x == SummerStory.POND.position.x else 5, 0))
				else:
					ground.set_cell(cell, 0, Vector2i(tile, 0))


func _place_features() -> void:
	if _in_festival():
		_place_festival()
		return
	if _in_district():
		return
	var texture := preload("res://assets/art/32/props.png")
	var wayfinding := preload("res://assets/art/32/wayfinding.png")
	if not _in_village():
		_add_prop(FARMHOUSE_ART, _feet_position(DOOR_CELL), FARMHOUSE_ART.get_height())
		_place_building(texture, BIN, 3, 1)
		_place_building(texture, TREE, 3, 2)
		_add_prop(wayfinding, _feet_position(VILLAGE_GATE), TILE_SIZE, 2)
		if progress.summer_story != null:
			for gate in [SummerStory.FARM_GATE, SummerStory.FARM_EXIT]:
				_add_prop(wayfinding, _feet_position(gate), TILE_SIZE, 2, int(gate.x == 20))
			for tree in [Vector2i(23, 2), Vector2i(25, 8), Vector2i(37, 2), Vector2i(22, 10)]:
				_add_prop(texture, _feet_position(tree), 64, 3, 2)
			_add_prop(preload("res://assets/art/32/fishing_spot.png"), _feet_position(SummerStory.FISHING), TILE_SIZE)
			_summer_prop(SummerStory.WELL, 2)
			if progress.summer_available(SummerProgress.PUMP_DAY):
				_summer_prop(SummerStory.PUMP, 3)
			if not _story_farm_hint(SummerStory.GINGER).is_empty():
				_add_prop(FESTIVAL_ART, _feet_position(SummerStory.GINGER), TILE_SIZE, 6, 2)
		return

	for footprint in VillageMap.COTTAGES:
		_place_building(texture, footprint, 3, 0)
	for footprint in VillageMap.TREES:
		_place_building(texture, footprint, 3, 2)
	_place_building(preload("res://assets/art/32/village_stall.png"), VillageMap.STALL, 1, 0)
	_add_prop(preload("res://assets/art/32/shop_sign.png"), _feet_position(VillageMap.SHOP_SIGN), TILE_SIZE)
	_add_prop(preload("res://assets/art/32/village_board.png"), _feet_position(VillageMap.ORDER_BOARD), TILE_SIZE)
	_add_prop(preload("res://assets/art/32/fishing_spot.png"), _feet_position(VillageMap.FISHING_SPOT), TILE_SIZE)
	_add_prop(wayfinding, _feet_position(VillageMap.EXIT_CELL), TILE_SIZE, 2, 1)
	market_booth = _place_building(
		preload("res://assets/art/32/market_booth.png"), VillageMap.MARKET_STALL, 1, 0
	)
	_update_market()

	var people := preload("res://assets/art/32/village_people.png")
	for index in range(VillagerCatalog.IDS.size()):
		var npc := _add_prop(people, Vector2.ZERO, PixelArt.CHARACTER_HEIGHT, 2, index)
		npc_sprites.append(npc)
		npc_cells.append(Vector2i(-1, -1))
	_sync_npcs()
	if progress.arrival != null:
		_add_prop(preload("res://assets/art/32/nguoi_hang_xom.png"), _feet_position(VillageMap.LAN_CELL), PixelArt.CHARACTER_HEIGHT, 2)
	if progress.village_wholesale_market():
		for cell in SummerStory.MARKET_STALLS:
			_add_prop(preload("res://assets/art/32/market_booth.png"), _feet_position(cell), 64)
		if progress.summer.cart_loaded:
			cart_sprite = _summer_prop(Vector2i(11, 7), 0)


func _place_building(texture: Texture2D, footprint: Rect2i, columns: int, frame: int) -> Sprite2D:
	var width := footprint.size.x * TILE_SIZE
	var height := footprint.size.y * TILE_SIZE
	var position := Vector2(footprint.position * TILE_SIZE) + Vector2(width * 0.5, height)
	return _add_prop(texture, position, height, columns, frame)


func _update_market() -> void:
	market_booth.self_modulate = Color.WHITE if progress.market_open() or progress.produce_stall_open() else Color("#81918b")


func _add_prop(texture: Texture2D, position: Vector2, height: int, columns := 1, frame := 0) -> Sprite2D:
	var prop := Sprite2D.new()
	prop.texture = texture
	prop.hframes = columns
	prop.frame = frame
	prop.position = position
	prop.offset.y = -height * 0.5
	features.add_child(prop)
	map_props.append(prop)
	return prop


func _sync_npcs() -> void:
	for index in range(npc_sprites.size()):
		var cell := VillageMap.npc_position(index, progress.minute_of_day)
		if cell == player_cell or cell == move_destination:
			continue
		npc_cells[index] = cell
		npc_sprites[index].position = _feet_position(cell)


func _load_crop_art() -> void:
	var bag_atlases := {
		"seed_bags.png": preload("res://assets/art/32/seed_bags.png"),
		"radish_seed.png": preload("res://assets/art/32/radish_seed.png"),
		"cucumber_seed.png": preload("res://assets/art/32/cucumber_seed.png"),
		"greens_seeds.png": preload("res://assets/art/32/greens_seeds.png"),
		"summer_seeds.png": preload("res://assets/art/32/summer_seeds.png"),
		"late_summer.png": LATE_SUMMER_ART,
	}
	for crop_id in CropCatalog.CROPS:
		var crop: Dictionary = CropCatalog.CROPS[crop_id]
		crop_atlases[crop_id] = load(PixelArt.PATH + crop.atlas) as Texture2D
		seed_icons[crop_id] = PixelArt.atlas_frame(bag_atlases[crop.seed_atlas], crop.seed_icon)


func _place_plots() -> void:
	for cell in progress.plots:
		var sprite := Sprite2D.new()
		sprite.texture = crop_atlases[CropCatalog.CABBAGE]
		sprite.hframes = 3
		sprite.position = _feet_position(cell)
		sprite.offset.y = -TILE_SIZE * 0.5
		features.add_child(sprite)
		crop_sprites[cell] = sprite
		if progress.arrival != null and cell in GardenProgress.PLOT_CELLS:
			var pest := _add_prop(preload("res://assets/art/32/sau_rau.png"), _feet_position(cell), TILE_SIZE, 2)
			pest.z_index = 1
			pest_sprites[cell] = pest
			_animate_idle(pest, 0.36)
		_update_plot(cell)


func _place_yard() -> void:
	if not progress.yard_open():
		return
	var weeds := preload("res://assets/art/32/weeds.png")
	for index in range(GardenProgress.PLOT_CELLS.size()):
		var cell: Vector2i = GardenProgress.PLOT_CELLS[index]
		if progress.plot_has_weeds(cell):
			weed_sprites[cell] = _add_prop(weeds, _feet_position(cell), TILE_SIZE, 3, index % 3)
	dog = _add_prop(
		preload("res://assets/art/32/cau_vang.png"), _feet_position(_dog_cell()), TILE_SIZE, 4
	)
	_update_dog()
	var animation := dog.create_tween().set_loops()
	animation.tween_callback(_update_dog.bind(true)).set_delay(0.48)
	animation.tween_callback(_update_dog).set_delay(0.34)
	if progress.day >= 3 and not progress.arrival.seeds_taken:
		seed_box = _add_prop(preload("res://assets/art/32/greens_seeds.png"), _feet_position(SEED_BOX), TILE_SIZE, 2)
	if progress.arrival.cat_home:
		_place_cat()
	elif progress.day >= 4:
		dad = _add_prop(preload("res://assets/art/32/nguoi_hang_xom.png"), _feet_position(DAD_CELL), PixelArt.CHARACTER_HEIGHT, 2, 1)


func _place_cat() -> void:
	cat = _add_prop(preload("res://assets/art/32/hoang_thuong.png"), _feet_position(CAT_CELL), TILE_SIZE, 2)
	_animate_idle(cat, 0.55)


func _place_tutorial_props() -> void:
	if progress.arrival == null:
		return
	coop_sprite = _add_prop(TUTORIAL_ART, _feet_position(COOP), TILE_SIZE, 9)
	trough_sprite = _add_prop(TUTORIAL_ART, _feet_position(TROUGH), TILE_SIZE, 9, 1)
	if progress.day >= ArrivalProgress.FENCE_DAY:
		_add_prop(TUTORIAL_ART, _feet_position(FENCE_SIGN), TILE_SIZE, 9, 6)
		fence_sprite = _add_prop(TUTORIAL_ART, Vector2.ZERO, TILE_SIZE, 9, 4)
	if progress.day >= ArrivalProgress.DRAIN_DAY:
		ditch_sprite = _add_prop(TUTORIAL_ART, _feet_position(DITCH), TILE_SIZE, 9, 5)
	_refresh_tutorial_props()


func _district_footprint(cell: Vector2i) -> bool:
	return Rect2i(3, 2, 4, 2).has_point(cell) or Rect2i(8, 2, 4, 2).has_point(cell) or Rect2i(13, 2, 4, 2).has_point(cell)


func _summer_prop(cell: Vector2i, frame: int) -> Sprite2D:
	return _add_prop(SUMMER_ART, _feet_position(cell), TILE_SIZE, 12, frame)


func _summer_person(cell: Vector2i, frame: int, tint: Color = Color.WHITE) -> void:
	var person := _add_prop(preload("res://assets/art/32/nguoi_hang_xom.png"), _feet_position(cell), PixelArt.CHARACTER_HEIGHT, 2, frame)
	person.self_modulate = tint


func _event_npc_specs() -> Dictionary:
	var people := {}
	if not progress.summer_available(SummerProgress.FIRST_DAY):
		return people
	var day := progress.day
	var minute := progress.minute_of_day
	var summer := progress.summer
	var story := progress.summer_story
	var teaching := story != null and day == SummerProgress.WEAVE_DAY and summer.received_heirlooms and not summer.learned_weaving
	if _in_village():
		if not teaching and (day > SummerProgress.LETTER_DAY or (day == SummerProgress.LETTER_DAY and (
			story == null or (summer.read_letter and minute >= int(SummerProgress.VISIT_WINDOWS[SummerProgress.LETTER_DAY]))
		))):
			people[SummerMap.HAI] = [1, Color("#c6b499")]
		if day >= SummerProgress.MAI_DAY and not (story != null and day == SummerProgress.MAI_DAY and not summer.met_mai and (
			minute >= int(SummerProgress.VISIT_WINDOWS[SummerProgress.MAI_DAY])
		)):
			people[SummerMap.MAI] = [0, Color("#e8c59d")]
	elif progress.area == GardenProgress.Area.GARDEN:
		if story != null:
			if day == SummerProgress.MAI_DAY and not summer.met_mai and minute >= int(SummerProgress.VISIT_WINDOWS[SummerProgress.MAI_DAY]):
				people[SummerStory.MAI] = [0, Color.WHITE]
			if day == SummerProgress.CITY_LETTER_DAY and not summer.read_city_letter and minute >= int(SummerProgress.VISIT_WINDOWS[SummerProgress.CITY_LETTER_DAY]):
				people[SummerStory.POSTMAN] = [1, Color.WHITE]
			if teaching:
				people[SummerMap.HAI_YARD] = [0, Color.WHITE]
			if day == SummerProgress.FAMILY_DAY and summer.family_meal and not summer.family_replied and not story.done("family_walk") and minute >= 900:
				people[SummerStory.FAMILY_VIEW] = [0, Color.WHITE]
		if _family_available():
			people[SummerMap.PARENTS] = [0, Color("#f1c0a4")]
			people[SummerMap.PARENTS + Vector2i.UP] = [1, Color.WHITE]
		if _lan_visit_available():
			people[SummerMap.LAN_VISIT] = [0, Color("#e9c2ac")]
	elif _in_house() and _lan_visit_available():
		people[SummerMap.LAN_INSIDE] = [0, Color.WHITE]
	return people


func _event_npc_present(cell: Vector2i) -> bool:
	return cell != player_cell and cell != move_destination and _event_npc_specs().has(cell)


func _sync_event_people() -> void:
	var wanted := _event_npc_specs()
	for cell: Vector2i in event_people.keys():
		if not wanted.has(cell) or cell == player_cell or cell == move_destination:
			var person := event_people[cell]
			map_props.erase(person)
			person.queue_free()
			event_people.erase(cell)
	for cell: Vector2i in wanted:
		if event_people.has(cell) or cell == player_cell or cell == move_destination:
			continue
		var spec: Array = wanted[cell]
		var person := _add_prop(preload("res://assets/art/32/nguoi_hang_xom.png"), _feet_position(cell), PixelArt.CHARACTER_HEIGHT, 2, spec[0])
		person.self_modulate = spec[1]
		event_people[cell] = person


func _family_available() -> bool:
	return progress.summer_available(SummerProgress.FAMILY_DAY) and not progress.summer.family_replied and (
		progress.day > SummerProgress.FAMILY_DAY or progress.minute_of_day >= int(SummerProgress.VISIT_WINDOWS[SummerProgress.FAMILY_DAY])
	)


func _place_summer_features() -> void:
	if not progress.summer_available(SummerProgress.FIRST_DAY):
		return
	var summer := progress.summer
	if _in_festival():
		return
	if _in_district():
		_place_building(preload("res://assets/art/32/market_booth.png"), Rect2i(4, 2, 3, 2), 1, 0)
		_place_building(preload("res://assets/art/32/village_stall.png"), Rect2i(8, 1, 4, 3), 1, 0)
		_place_building(preload("res://assets/art/32/village_stall.png"), Rect2i(13, 1, 4, 3), 1, 0).self_modulate = Color("#d6b99f")
		for cell in SummerMap.ATTRACTORS:
			_summer_prop(cell + Vector2i(-1, 1), 10)
		for cell in SummerMap.TREES:
			_add_prop(preload("res://assets/art/32/props.png"), _feet_position(cell), 64, 3, 2)
		_summer_person(SummerMap.WHOLESALER, 1, Color("#b3b1ae"))
		_summer_person(SummerMap.SEED_SHOP, 0, Color("#b8cf9e"))
		_summer_person(SummerMap.TOOL_SHOP, 1)
		_summer_prop(SummerMap.EXIT, 10)
		cart_sprite = _summer_prop(SummerMap.EXIT + Vector2i(2, 1), 0)
		_refresh_summer_cart()
		_place_social()
		return
	if _in_village():
		_summer_prop(SummerMap.GATE, 10)
		if progress.summer_available(VillageFestival.NOTICE_DAY) and progress.day <= VillageFestival.FAIR_DAY:
			_summer_prop(FestivalMap.GATE, 10)
		if progress.day > VillageFestival.FAIR_DAY and summer.festival.wrestling:
			_summer_person(FestivalMap.THANG, 1, Color("#f0bd83"))
		if progress.day >= SummerProgress.QUIET_DAY or (progress.summer_story != null and progress.day == SummerProgress.SOLO_DAY):
			for cell in SummerMap.DRYING_RICE:
				var rice := _add_prop(QUIET_FARM_ART, _feet_position(cell), TILE_SIZE, 6, 3)
				drying_sprites.append(rice)
			_refresh_drying_rice()
		_place_social()
		return
	cart_sprite = _summer_prop(SummerMap.CART, 0)
	_refresh_summer_cart()
	for x in range(SummerMap.POND.position.x, SummerMap.POND.end.x):
		_summer_prop(Vector2i(x, SummerMap.POND.position.y), 11)
	if progress.day >= SummerProgress.WEAVE_DAY:
		_summer_prop(SummerMap.BAMBOO, 1)
		_summer_prop(SummerMap.HAI_YARD, 8)
	if summer.nest_basket:
		_summer_prop(COOP + Vector2i.UP, 8)
	if progress.day >= SummerProgress.PUMP_DAY:
		_summer_prop(SummerProgress.WELL_CELL, 2)
		if summer.parents_visited:
			_summer_prop(SummerMap.PUMP, 3)
		if summer.sprinkler >= 0:
			_summer_prop(progress.summer_sprinkler_cell(), 4)
		if summer.chick:
			_add_prop(FESTIVAL_ART, _feet_position(_chick_cell()), TILE_SIZE, 6, 5)
			if summer.festival.chick_divider:
				_add_prop(FESTIVAL_ART, _feet_position(FestivalMap.CHICK) + Vector2(5, -4), TILE_SIZE, 6, 4)
	if progress.summer_available(VillageFestival.PREP_DAY) and progress.day <= VillageFestival.FAIR_DAY:
		for cell in FestivalMap.FORAGE:
			var index := FestivalMap.FORAGE.find(cell)
			var art_frame: int = [4, 4, 5, 2][index]
			var prop := _add_prop(QUIET_FARM_ART, _feet_position(cell), TILE_SIZE, 6, art_frame)
			prop.visible = (summer.festival.gather_mask & (1 << index)) == 0
	if progress.day >= SummerProgress.BUILD_DAY:
		for cell in SummerMap.WOOD_TREES:
			_add_prop(preload("res://assets/art/32/props.png"), _feet_position(cell), 64, 3, 2)
		_add_prop(QUIET_FARM_ART, _feet_position(SummerMap.STRAW), TILE_SIZE, 6, 2)
		if summer.coop_step > 0:
			_add_prop(QUIET_FARM_ART, _feet_position(COOP_EXTENSION), TILE_SIZE, 6, int(summer.coop_step == 4))
	if progress.day >= SummerProgress.QUIET_DAY:
		_add_prop(QUIET_FARM_ART, _feet_position(SummerMap.LOTUS), TILE_SIZE, 6, 5)
		_add_prop(QUIET_FARM_ART, _feet_position(SummerMap.HERBS), TILE_SIZE, 6, 4)
	_place_social()


func _place_social() -> void:
	if not progress.summer_available(VillageSocial.AFTER_FAIR_DAY):
		return
	var social := progress.summer.social
	if _in_village():
		if progress.day >= VillageSocial.NEIGHBORS_DAY:
			_add_social_prop(VillageSocial.MINH, 1)
			_add_social_prop(VillageSocial.TUAN, 2)
			_add_social_prop(VillageSocial.TUAN + Vector2i.UP, 3)
		if social.training_invited:
			_add_social_prop(FestivalMap.THANG + Vector2i.RIGHT, 4)
		if progress.day == VillageSocial.AFTER_FAIR_DAY:
			_add_prop(FESTIVAL_ART, _feet_position(FestivalMap.GATE), TILE_SIZE, 6, 2)
	elif _in_district() and social.tuan_points == 20:
		_add_social_prop(TUAN_DISTRICT, 2)
	elif progress.area == GardenProgress.Area.GARDEN and not social.chief_met and not (
		progress.in_drought() and progress.summer.drought.delivery == progress.day and progress.summer.drought.oil == 0
	):
		_add_social_prop(VillageSocial.CHIEF, 0)


func _add_social_prop(cell: Vector2i, frame: int) -> Sprite2D:
	return _add_prop(SOCIAL_ART, _feet_position(cell), TILE_SIZE, 6, frame)


func _is_social_cell(cell: Vector2i) -> bool:
	if not progress.summer_available(VillageSocial.AFTER_FAIR_DAY):
		return false
	if _in_village() and progress.day >= VillageSocial.NEIGHBORS_DAY:
		return cell in [VillageSocial.MINH, VillageSocial.TUAN]
	if _in_house():
		return cell == VillageSocial.PHONE and progress.day >= VillageSocial.MESSAGE_DAY
	if _in_district():
		return cell == TUAN_DISTRICT and progress.summer.social.tuan_points == 20
	return progress.area == GardenProgress.Area.GARDEN and cell == VillageSocial.CHIEF and not progress.summer.social.chief_met


func _social_hint(cell: Vector2i) -> String:
	if _in_house():
		return "E · Xem điện thoại"
	if cell in [VillageSocial.TUAN, TUAN_DISTRICT]:
		return "E · Nói với Tuấn"
	if cell == VillageSocial.MINH:
		return "E · Nói với Bà Minh"
	return "E · Nói với Trưởng thôn"


func _interact_social(cell: Vector2i) -> void:
	var social := progress.summer.social
	if _in_house():
		if not progress.boss_message_ready():
			village_panel.open_dialogue("Điện thoại", "Chưa có tin nhắn mới.")
		elif social.boss_reply > 0:
			village_panel.open_dialogue("Tin nhắn đã gửi", VillageSocial.RESPONSES[social.boss_reply - 1])
		else:
			festival_panel.open_phone()
	elif cell in [VillageSocial.TUAN, TUAN_DISTRICT]:
		_offer_ride()
	elif cell == VillageSocial.MINH:
		_talk_minh()
	else:
		var line := progress.visit_chief()
		if not line.is_empty():
			_rebuild_map()
			_commit_progress()
			village_panel.open_dialogue("Trưởng thôn · Thân thiết 5", line)


func _offer_ride() -> void:
	if not _in_district() and not progress.can_visit_district():
		village_panel.open_dialogue("Tuấn", "Ngày 36 tao chạy chuyến đầu ra chợ huyện. Nếu có hàng bán trước đó thì qua chợ làng nhé.")
		return
	if progress.meet_tuan():
		_commit_progress()
		village_panel.open_dialogue("Tuấn", "Tao cũng từng làm ở Hà Nội. Giờ tao chạy xe ra huyện. Khi cần đi, cứ ghé gọi tao.")
		return
	var destination := GardenProgress.Area.VILLAGE if _in_district() else GardenProgress.Area.DISTRICT
	var place := "về làng" if _in_district() else "ra chợ huyện"
	_open_story("Tuấn xe ôm", "Một chuyến %s mất 20 phút và %d xu." % [place, VillageSocial.RIDE_PRICE],
		"Đi %s" % place, _take_ride.bind(destination))


func _take_ride(destination: GardenProgress.Area) -> void:
	if progress.book_tuan_ride(destination):
		village_panel.hide()
		_travel(destination)
		if destination == GardenProgress.Area.DISTRICT and progress.summer_available(SummerCraft.TRIP_DAY) and progress.summer.craft.trip_reply == 0:
			_open_story("Đường ra huyện", "Tuấn kể từng làm công trình ở Hà Nội. Giờ về làng, anh hỏi Hoàng muốn sống ở đâu.", "Cháu chưa biết", _record_trip.bind(1), "Cháu muốn ở lại", _record_trip.bind(2))
	else:
		var line := "Tao chạy chuyến ra huyện vào thứ Ba và thứ Bảy." if destination == GardenProgress.Area.DISTRICT and not progress.district_ride_day() else (
			"Cần %d xu. Chuyến cuối đến nơi trước 18:00." % VillageSocial.RIDE_PRICE
		)
		village_panel.open_dialogue("Tuấn", line)


func _record_trip(reply: int) -> void:
	if progress.record_tuan_trip(reply):
		_commit_progress()
		var line := "Chưa biết cũng được. Cứ bình tĩnh mà nghĩ." if reply == 1 else "Muốn ở thì ở. Khi nào cần ra huyện, cứ gọi tao thứ Ba hoặc thứ Bảy."
		village_panel.open_dialogue("Tuấn", line + "\nTừ giờ bán nông sản qua tuyến của Tuấn được giá gấp rưỡi.")


func _talk_minh() -> void:
	var social := progress.summer.social
	var heading := "Bà Minh · Thân thiết %d" % social.minh_points
	if social.scarf_found and social.scarf_reply == 0:
		_open_story(heading, "Bà nhận ra chiếc khăn thêu chim hạc. Bà tặng ông ngoại năm 1987, hồi ông lấy vợ.", "Mời bà giữ", _show_scarf.bind(1), "Cất lại vào tủ", _show_scarf.bind(2))
	elif progress.day >= VillageSocial.SCARF_DAY and (progress.day > VillageSocial.SCARF_DAY or progress.minute_of_day >= 14 * 60) and social.minh_story == 0:
		_open_story(heading, "Bà và ông ngoại từng học chung ở đình. Trong lớp ông hay nhìn qua cửa sổ ra ruộng.", "Ông trồng gì ạ?", _hear_minh.bind(1), "Ông có nhắc bà?", _hear_minh.bind(2))
	elif progress.meet_minh():
		_commit_progress()
		village_panel.open_dialogue("Bà Minh · Thân thiết %d" % social.minh_points, "Ông ngoại cháu hay đem rau sang. Bà từng thêu tặng ông một chiếc khăn. Không biết ông còn cất không.")
	elif social.scarf_reply > 0:
		if progress.summer_available(SummerCraft.EMBROIDERY_DAY) and social.minh_points >= 40:
			if progress.summer.craft.embroidery:
				if progress.summer_available(AutumnWork.CRAFT_DAY) and social.minh_points >= 45:
					var advanced := progress.summer.autumn.embroidery2
					_open_story(heading, "Thêu khăn hoa hoặc tập mũi chéo và mũi vòng với bà.", "Thêu khăn hoa", _open_embroidery.bind(true),
						"Thêu cấp 2" if advanced else "Học cấp 2", _choose_advanced_embroidery if advanced else _learn_advanced_embroidery)
				else:
					_open_story(heading, "Cháu có thể thêu khăn hoa ở đây hoặc bên khung thêu trong nhà.", "Thêu khăn hoa", _open_embroidery.bind(true))
			else:
				_open_story(heading, "Bà cho cháu một tấm vải và kim. Vẽ một mẫu rồi tập mũi thẳng nhé.", "Học thêu", _open_embroidery.bind(false))
		else:
			village_panel.open_dialogue(heading, "Chỉ màu còn tốt thì cứ giữ. Khi rảnh, cháu mang qua đây.")
	elif social.minh_story > 0:
		village_panel.open_dialogue(heading, "Cháu xem thử ngăn dưới cùng của tủ chè nhé.")
	else:
		village_panel.open_dialogue(heading, "Chiều ghé hiên uống trà với bà nhé.")


func _hear_minh(choice: int) -> void:
	if progress.hear_minh_story(choice):
		_commit_progress()
		var story := "Ông trồng cà rốt Thuận Thành cạnh giếng. Bà nhớ năm được mùa, ông đem chia cả xóm." if choice == 1 else "Bà không biết ông có nhắc không. Người ta sống tốt với nhau là được rồi."
		village_panel.open_dialogue("Bà Minh", story + "\nThử tìm chiếc khăn ở ngăn dưới tủ chè.")


func _show_scarf(reply: int) -> void:
	if progress.show_minh_scarf(reply):
		_commit_progress()
		var line := "Của nhà cháu thì cháu giữ. Bà nhìn thấy là được rồi." if reply == 1 else "Ừ, cất lại chỗ ông để. Vậy là tốt."
		village_panel.open_dialogue("Bà Minh", line)


func _boss_reply(reply: int) -> void:
	if progress.answer_boss(reply):
		_commit_progress()
		var responses := ["Ừ, em cứ từ từ. Anh chờ.", "Khi nào sẵn sàng thì nhắn anh.", "Anh hiểu. Giữ gìn sức khỏe nhé."]
		village_panel.open_dialogue("Sếp cũ", responses[reply - 1])


func _talk_thang() -> void:
	var social := progress.summer.social
	if progress.unlock_training():
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Chú Thắng", "Từ ngày 33 chú tập ở đây lúc 05:00. Chú đã chỉ cháu đặt giờ dậy sớm. Ghé trước 06:00 nếu muốn tập.")
	elif progress.can_train():
		festival_panel.open_training()
	elif social.training_day == progress.day:
		village_panel.open_dialogue("Chú Thắng", "Đã tập hôm nay · Chuỗi %d/7 buổi." % social.streak)
	else:
		var change := "Dậy lúc 06:00" if social.wake_early else "Dậy lúc 05:00"
		_open_story("Chú Thắng", "Chú tập từ 05:00 đến trước 06:00. Đủ 7 buổi liền sẽ tăng 10 thể lực tối đa.", change, _toggle_early_wake)


func _toggle_early_wake() -> void:
	var social := progress.summer.social
	social.wake_early = not social.wake_early
	_commit_progress()
	village_panel.open_dialogue("Giờ thức dậy", "Từ sáng mai · %s" % ("05:00" if social.wake_early else "06:00"))


func _complete_training() -> void:
	var had_reward := progress.summer.social.training_reward
	var had_bonus := progress.summer.autumn.training_bonus
	if progress.finish_training():
		_commit_progress()
		var social := progress.summer.social
		var message := "Buổi sáng sảng khoái · +2 thể lực tối đa hôm nay. Chuỗi %d/7." % social.streak
		if social.training_reward and not had_reward:
			message = "Đã đủ bảy buổi liên tiếp. Thể lực tối đa tăng vĩnh viễn 10 điểm."
		elif progress.summer.autumn.training_bonus and not had_bonus:
			message = "Thêm một chuỗi bảy buổi. Thể lực tối đa tăng vĩnh viễn 5 điểm."
		village_panel.open_dialogue("Chú Thắng", message)


func _refresh_summer_cart() -> void:
	if is_instance_valid(cart_sprite):
		cart_sprite.visible = progress.summer.cart_loaded or (not _in_district() and not progress.village_wholesale_market())
		cart_sprite.self_modulate = Color("#f0c17f") if progress.summer.cart_loaded else Color.WHITE


func _place_craft_features() -> void:
	if not progress.summer_available(SummerCraft.TRIP_DAY):
		return
	if _in_district():
		_add_prop(CRAFT_ART, _feet_position(SummerMap.HUONG), TILE_SIZE, 8, 0)
		_summer_person(SummerMap.HUONG + Vector2i.UP, 0, Color("#e8caab"))
		_add_prop(CRAFT_ART, _feet_position(SummerMap.CRAFT_STALL), TILE_SIZE, 8, 7)
		if progress.day >= SummerCraft.BUYER_DAY:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.BINH), TILE_SIZE, 8, 6)
	elif progress.area == GardenProgress.Area.GARDEN:
		if _ly_available() and progress.day not in [DroughtProgress.LAST, DroughtProgress.RAIN]:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.LY), TILE_SIZE, 8, 5)
		if progress.summer.craft.jar:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.JAR), TILE_SIZE, 8, 1)


func _place_drought_features() -> void:
	if not progress.summer_available(DroughtProgress.FIRST):
		return
	var state := progress.summer.drought
	if _in_village():
		if progress.day >= DroughtProgress.OIL_DAY:
			_summer_person(DroughtProgress.THANH, 1, Color("#b3b9ad"))
		if progress.day >= DroughtProgress.SHARE_DAY and (state.share_choice == 1 or (progress.in_drought() and state.share_choice == 0)):
			_add_social_prop(DroughtProgress.TAM, 0 if state.share_choice == 0 else 1)
	elif progress.area == GardenProgress.Area.GARDEN:
		if state.learned_well:
			_add_prop(DROUGHT_ART, _feet_position(DroughtProgress.WELL_SITE), TILE_SIZE, 4, 2 if state.well_step == 4 else 1)
		if progress.day == DroughtProgress.LAST and not state.ly_help and state.well_step < 4:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.LY), TILE_SIZE, 8, 5)
		if progress.in_drought() and state.delivery == progress.day and state.oil == 0:
			_add_social_prop(VillageSocial.CHIEF, 2)
		if progress.day == DroughtProgress.RAIN:
			_add_prop(CRAFT_ART, _feet_position(SummerMap.LY), TILE_SIZE, 8, 5)


func _place_late_summer_features() -> void:
	if not progress.summer_available(LateSummer.RECOVERY):
		return
	var state := progress.summer.late
	match progress.area:
		GardenProgress.Area.LOTUS_POND:
			_summer_prop(LateSummerMap.POND_EXIT, 10)
			for index in LateSummerMap.LOTUS.size():
				if state.lotus_day != progress.day or (state.lotus_mask & (1 << index)) == 0:
					_add_prop(LATE_SUMMER_ART, _feet_position(LateSummerMap.LOTUS[index]), TILE_SIZE, 10, 3 if index < 10 else 4)
		GardenProgress.Area.COUNTY_FAIR:
			for index in LateSummerMap.STALLS.size():
				var texture := preload("res://assets/art/32/village_stall.png") if index < 3 else preload("res://assets/art/32/market_booth.png")
				var stall := _place_building(texture, LateSummerMap.STALLS[index], 1, 0)
				stall.self_modulate = [Color("#fffbd6"), Color("#f2c8a7"), Color("#e6ecca")][index % 3]
			_summer_prop(SummerMap.EXIT, 10)
			_summer_person(LateSummerMap.BUYER, 1, Color("#e5d2b3"))
			_summer_person(LateSummerMap.SEEDS, 0, Color("#cee4bb"))
			_summer_person(Vector2i(6, 5), 0, Color("#d5bfde"))
			_summer_person(Vector2i(12, 6), 1, Color("#e9bb9e"))
			_summer_prop(Vector2i(17, 8), 0)
		GardenProgress.Area.VILLAGE:
			if progress.day >= LateSummer.LOTUS_DAY:
				_summer_prop(LateSummerMap.POND_GATE, 10)
			if progress.day >= LateSummer.BASKET_DAY:
				for index in LateSummerMap.BAMBOO.size():
					if ((state.bamboo_hits >> (index * 3)) & 7) < 3:
						_summer_prop(LateSummerMap.BAMBOO[index], 1)
				for index in LateSummerMap.RATTAN.size():
					if (state.rattan_mask & (1 << index)) == 0:
						_add_prop(QUIET_FARM_ART, _feet_position(LateSummerMap.RATTAN[index]), TILE_SIZE, 6, 4)
			if progress.day >= LateSummer.FIRST_FAIR:
				_summer_person(LateSummerMap.FERRY, 1, Color("#d1b9a2"))
		GardenProgress.Area.GARDEN:
			_add_prop(QUIET_FARM_ART, _feet_position(LateSummerMap.COMPOST), TILE_SIZE, 6, 4)
			if state.basket_score >= 0:
				_summer_prop(LateSummerMap.PACKING, 8)
			if _harvest_lan_available():
				_summer_person(LateSummerMap.LAN, 0, Color("#e9c2ac"))


func _in_works_site() -> bool:
	return progress.area in [GardenProgress.Area.FORGE, GardenProgress.Area.BAMBOO_WORKS, GardenProgress.Area.STOREHOUSE]


func _works_prop(cell: Vector2i, art_frame: int) -> void:
	_add_prop(BAMBOO_WORKS_ART, _feet_position(cell), TILE_SIZE, BambooWorksMap.ART_COLUMNS, art_frame)


func _storehouse_prop(cell: Vector2i, frame: int) -> void:
	_add_prop(STOREHOUSE_ART, _feet_position(cell), TILE_SIZE, StorehouseMap.ART_COLUMNS, frame)


func _place_works_site() -> void:
	var state := progress.summer.works
	_summer_prop(BambooWorksMap.EXIT, 10)
	if progress.area == GardenProgress.Area.STOREHOUSE:
		var corner := progress.summer.autumn.corner_step
		_storehouse_prop(StorehouseMap.STOCK, 3)
		_storehouse_prop(StorehouseMap.BENCH, 1 if corner == 0 else 2)
		if corner >= 2:
			_storehouse_prop(StorehouseMap.SIDE, 3)
		if corner == 3:
			_works_prop(StorehouseMap.BOARD, 11)
			_storehouse_prop(StorehouseMap.SIDE + Vector2i.RIGHT, 4)
		return
	if progress.area == GardenProgress.Area.FORGE:
		_summer_person(BambooWorksMap.SMITH, 1, Color("#efb49c"))
		_works_prop(BambooWorksMap.HEARTH, 4)
		_works_prop(BambooWorksMap.ANVIL, 5)
		_works_prop(BambooWorksMap.QUENCH, 6)
		for index in BambooWorksMap.SCRAP.size():
			if (state.iron_mask & (1 << index)) == 0:
				_works_prop(BambooWorksMap.SCRAP[index], 7)
		return
	_summer_person(BambooWorksMap.HAI, 1, Color("#d9bd9a"))
	_works_prop(BambooWorksMap.MACHINE, 9 if state.repair_step >= 3 else 8)
	_works_prop(BambooWorksMap.SIGN, 10 if state.ready() else 17)
	if state.repair_step < 2:
		for cell in [Vector2i(5, 5), Vector2i(8, 3), Vector2i(9, 8), Vector2i(4, 7)]:
			_works_prop(cell, 16)
	if progress.day >= BambooWorks.ORDER_DAY:
		_works_prop(BambooWorksMap.BOARD, 11)
	var covers := state.protection if progress.day == BambooWorks.STORM_DAY else 0
	_works_prop(BambooWorksMap.RAW, 14 if covers & BambooWorks.RAW_TARP else 12)
	_works_prop(BambooWorksMap.GOODS, 15 if covers & BambooWorks.GOODS_TARP else 13)
	if progress.day == BambooWorks.FIRST_DUE:
		for cell in [Vector2i(12, 8), Vector2i(14, 4), Vector2i(17, 6)]:
			_add_prop(AUTUMN_WORK_ART, _feet_position(cell), TILE_SIZE, 6, 0)
		_add_prop(AUTUMN_WORK_ART, _feet_position(Vector2i(15, 9)), TILE_SIZE, 6, 1)
		if progress.summer.autumn.damp_baskets > 0:
			_add_prop(AUTUMN_WORK_ART, _feet_position(BambooWorksMap.GOODS + Vector2i.LEFT), TILE_SIZE, 6, 4)
		if state.county_met and state.order_due > 0:
			_summer_person(AutumnWork.BUYER, 1, Color("#e5d2b3"))
			_summer_prop(AutumnWork.BUYER + Vector2i.RIGHT, 0)
	if progress.day >= AutumnWork.CRAFT_DAY and state.ready():
		_add_prop(AUTUMN_WORK_ART, _feet_position(BambooWorksMap.HAI + Vector2i.UP), TILE_SIZE, 6, 5)


func _place_works_outdoors() -> void:
	if not progress.summer_available(BambooWorks.FORGE_DAY):
		return
	var state := progress.summer.works
	if _in_village():
		_works_prop(BambooWorksMap.FORGE_GATE, 10)
		if progress.day >= BambooWorks.OFFER_DAY:
			_works_prop(BambooWorksMap.WORKS_GATE, 10)
		if progress.day >= BambooWorks.RESTORE_DAY:
			for index in BambooWorksMap.GROVE.size():
				if state.grove_day != progress.day or (state.grove_mask & (1 << index)) == 0:
					_summer_prop(BambooWorksMap.GROVE[index], 1)
	elif progress.area == GardenProgress.Area.GARDEN and progress.day == BambooWorks.STORM_DAY and state.protection & BambooWorks.COOP_TARP:
		_works_prop(COOP, 15)


func _works_hint(cell: Vector2i) -> String:
	if not progress.summer_available(BambooWorks.FORGE_DAY):
		return ""
	var day := progress.day
	var state := progress.summer.works
	match progress.area:
		GardenProgress.Area.STOREHOUSE:
			match cell:
				BambooWorksMap.EXIT: return "E · Về sân"
				StorehouseMap.STOCK: return "E · Mở kho"
				StorehouseMap.BENCH: return "E · Dùng góc xưởng" if progress.summer.autumn.corner_ready() else "E · Lắp góc xưởng"
				StorehouseMap.BOARD: return "E · Xem đơn sỉ" if progress.summer.autumn.corner_ready() else ""
		GardenProgress.Area.FORGE:
			if cell == BambooWorksMap.EXIT:
				return "E · Về đầu làng"
			if cell == BambooWorksMap.SMITH:
				return "E · Gặp Bác Thợ Rèn"
			var index := BambooWorksMap.SCRAP.find(cell)
			if index >= 0 and (state.iron_mask & (1 << index)) == 0:
				return "E · Nhặt sắt vụn"
		GardenProgress.Area.BAMBOO_WORKS:
			match cell:
				BambooWorksMap.EXIT: return "E · Về bến sông"
				BambooWorksMap.HAI: return "E · Nói chuyện với Cụ Hai"
				BambooWorksMap.SIGN: return "E · Xem biển xưởng"
				BambooWorksMap.MACHINE: return "E · Xem máy chẻ lạt"
				BambooWorksMap.BOARD: return "E · Xem đơn sỉ" if day >= BambooWorks.ORDER_DAY else ""
				BambooWorksMap.RAW: return _works_tarp_hint(BambooWorks.RAW_TARP, "kho tre")
				BambooWorksMap.GOODS: return _works_tarp_hint(BambooWorks.GOODS_TARP, "kho sọt")
				AutumnWork.BUYER:
					return "E · Gặp Lái Buôn" if day == BambooWorks.FIRST_DUE and state.county_met and state.order_due > 0 else ""
		GardenProgress.Area.VILLAGE:
			if cell == BambooWorksMap.FORGE_GATE:
				return "E · Vào lò rèn"
			if day >= BambooWorks.OFFER_DAY and cell == BambooWorksMap.WORKS_GATE:
				return "E · Vào xưởng tre"
			if day >= BambooWorks.RESTORE_DAY:
				var index := BambooWorksMap.GROVE.find(cell)
				if index >= 0 and (state.grove_day != day or (state.grove_mask & (1 << index)) == 0):
					return "E · Chặt tre ống"
		GardenProgress.Area.GARDEN:
			if cell == StorehouseMap.ENTRY and progress.has_storehouse():
				return "E · Vào nhà kho"
			if cell == AutumnWork.WAREHOUSE and progress.summer.autumn.built & 2:
				return "E · Mở kho cấp 2"
			if cell == SummerMap.LY and day in [AutumnWork.SOIL_DAY, AutumnWork.WORKROOM_FINISH]:
				return "E · Hỏi Bác Lý về mưa" if day == AutumnWork.WORKROOM_FINISH else "E · Gặp Bác Lý"
			if cell == COOP and progress.can_protect_from_storm(BambooWorks.COOP_TARP):
				return "Giữ E · Che chuồng gà"
		GardenProgress.Area.HOUSE:
			if day >= AutumnWork.INVEST_DAY and cell == AutumnWork.LEDGER:
				return "E · Mở Sổ Chi Tiêu"
			if day >= BambooWorks.OFFER_DAY and cell == Farmhouse.PANTRY and not state.wine_taken and progress.arrival.dog_food != ArrivalProgress.DogFood.PANTRY:
				return "E · Lấy bình rượu nếp"
			if cell == Farmhouse.EXIT and progress.can_protect_from_storm(BambooWorks.DOOR):
				return "E · Đóng cửa nhà hoặc ra sân"
	return ""


func _works_tarp_hint(bit: int, label: String) -> String:
	return "Giữ E · Che %s" % label if progress.can_protect_from_storm(bit) else "E · Kiểm tra %s" % label


func _interact_works_site(cell: Vector2i) -> void:
	var state := progress.summer.works
	match progress.area:
		GardenProgress.Area.STOREHOUSE:
			match cell:
				BambooWorksMap.EXIT: _travel(GardenProgress.Area.GARDEN)
				StorehouseMap.STOCK: village_panel.open_warehouse(progress, true)
				StorehouseMap.BOARD: village_panel.open_bamboo_order(progress)
				StorehouseMap.BENCH: _open_workroom_corner()
		GardenProgress.Area.FORGE:
			if cell == BambooWorksMap.EXIT:
				_travel(GardenProgress.Area.VILLAGE)
			elif cell == BambooWorksMap.SMITH:
				if state.forged:
					village_panel.open_dialogue("Bác Thợ Rèn", "Liềm sắt bén dọn gốc rạ và phát cỏ trong một nhát.")
				else:
					_open_story("Bác Thợ Rèn", "Rèn liềm hết 500 xu và 3 thỏi sắt vụn. Sắt có trong các đống quanh lò.", "Rèn liềm", _forge_sickle)
			elif progress.collect_scrap_iron(BambooWorksMap.SCRAP.find(cell)):
				_rebuild_map()
				_commit_progress()
				late_audio.play_effect(&"anvil")
				hint.text = "Sắt vụn %d/3" % progress.quantity(BambooWorks.IRON)
		GardenProgress.Area.BAMBOO_WORKS:
			match cell:
				BambooWorksMap.EXIT: _travel(GardenProgress.Area.VILLAGE)
				BambooWorksMap.HAI: _talk_workshop_hai()
				BambooWorksMap.MACHINE:
					if state.ready():
						village_panel.open_bamboo_machine(progress)
					else:
						village_panel.open_dialogue("Máy chẻ lạt", "Gặp Cụ Hai để tiếp quản và sửa lại máy.")
				BambooWorksMap.SIGN:
					var title := "Xưởng Tre Thủ Công · Huy Hoàng" if state.ready() else "Tấm biển cũ"
					village_panel.open_dialogue(title, "Sọt tre, nong phơi lúa và rổ tre xuất khẩu." if state.ready() else "Nét chữ trên biển đã bạc màu.")
				BambooWorksMap.BOARD: village_panel.open_bamboo_order(progress)
				AutumnWork.BUYER: village_panel.open_bamboo_order(progress)
				BambooWorksMap.RAW, BambooWorksMap.GOODS:
					var bit := BambooWorks.RAW_TARP if cell == BambooWorksMap.RAW else BambooWorks.GOODS_TARP
					if progress.can_protect_from_storm(bit):
						_begin_storm_tarp(cell)
					else:
						var covered := progress.day == BambooWorks.STORM_DAY and (state.protection & bit) != 0
						village_panel.open_dialogue("Kho xưởng", "Bạt đã phủ kín." if covered else "Tre và sọt để trên sân kho.")
		GardenProgress.Area.VILLAGE:
			if cell == BambooWorksMap.FORGE_GATE:
				_travel(GardenProgress.Area.FORGE)
			elif cell == BambooWorksMap.WORKS_GATE:
				_travel(GardenProgress.Area.BAMBOO_WORKS)
			elif progress.gather_workshop_bamboo(BambooWorksMap.GROVE.find(cell)):
				_rebuild_map()
				_commit_progress()
				late_audio.play_effect(&"bamboo")
				hint.text = "Đã lấy 5 tre ống · Túi ×%d" % progress.quantity(LateSummer.STEM)
			else:
				hint.text = "Cần đồ nghề và đủ thể lực để chặt tre"
		GardenProgress.Area.GARDEN:
			if cell == StorehouseMap.ENTRY:
				_travel(GardenProgress.Area.STOREHOUSE)
			elif cell == AutumnWork.WAREHOUSE:
				village_panel.open_warehouse(progress, true)
			elif cell == SummerMap.LY:
				village_panel.open_dialogue("Bác Lý", "Từ ngày 75 có mưa ngâu bảy ngày. Cháu cất tre và Nan Tinh vào kho để dành làm hàng." if progress.monsoon_forecast() else (
					"Lật đất sớm là phải. Đất nghỉ được vài hôm thì vụ sau mới khỏe."
				))
			else:
				_begin_storm_tarp(cell)
		GardenProgress.Area.HOUSE:
			if cell == AutumnWork.LEDGER:
				village_panel.open_autumn_ledger(progress)
			elif cell == Farmhouse.PANTRY and progress.take_workshop_wine():
				_commit_progress()
				village_panel.open_dialogue("Tủ đồ", "Một bình rượu nếp đem sang biếu Cụ Hai ở xưởng cạnh bến.")
			elif cell == Farmhouse.EXIT:
				_open_story("Cửa nhà", "Chốt cửa để chắn gió. Sáng mai có thể mở cửa như thường.", "Chốt cửa", _shut_storm_door, "Ra sân",
					_leave_storm_house)


func _open_workroom_corner() -> void:
	var step := progress.summer.autumn.corner_step
	if progress.can_use_bamboo_machine():
		village_panel.open_bamboo_machine(progress)
	elif progress.summer.autumn.corner_ready():
		village_panel.open_dialogue("Góc xưởng", "Bàn, giá và chỗ chờ đã sẵn sàng. Sửa máy ở xưởng Cụ Hai để chạy mẻ tại đây.")
	elif progress.day < AutumnWork.WORKROOM_DAY + step:
		village_panel.open_dialogue("Góc xưởng", "Đã làm %d/3 bước. Quay lại từ ngày %d." % [step, AutumnWork.WORKROOM_DAY + step])
	else:
		var item: String = AutumnWork.CORNER_ITEMS[step]
		var needed: int = AutumnWork.CORNER_COUNTS[step]
		_open_story("Lắp góc xưởng", "%d/3 · %s.\nCần %d %s và 6 thể lực." % [
			step, AutumnWork.CORNER_TASKS[step], needed, progress.item_label(item).to_lower(),
		], "Lắp đặt", _build_workroom_corner)
		village_panel.show_works_restoration(step + 1)


func _build_workroom_corner() -> void:
	if progress.build_workroom_corner():
		_rebuild_map()
		_commit_progress()
		late_audio.play_effect(&"anvil")
		if progress.summer.autumn.corner_ready():
			village_panel.open_dialogue("Góc xưởng", "Đã xong. Kho có 28 ô. Có thể đặt một mẻ chờ và xem đơn ngay tại đây.")
		else:
			_open_workroom_corner()
	else:
		village_panel.body.text = "Chưa đủ vật liệu, đồ nghề hoặc thể lực. Xem lại túi trước khi lắp."


func _forge_sickle() -> void:
	if progress.forge_sickle():
		_commit_progress()
		late_audio.play_effect(&"anvil")
		village_panel.open_dialogue("Liềm Sắt Bén", "Đã rèn xong. Dọn gốc và phát cỏ bằng một nhát, tốn 1 thể lực mỗi ô.")
	else:
		village_panel.body.text = "Cần 500 xu, 3 thỏi sắt vụn và liềm cũ."


func _talk_workshop_hai() -> void:
	var state := progress.summer.works
	if not progress.summer.learned_weaving:
		village_panel.open_dialogue("Cụ Hai", "Cháu thử học đan ở sân nhà trước. Ta gặp lại ở đây khi cháu đã quen tay.")
	elif not state.offered:
		if progress.quantity(BambooWorks.WINE) == 0:
			village_panel.open_dialogue("Cụ Hai", "Cụ vẫn cất ít rượu nếp trong tủ cạnh cửa bếp nhà cháu. Mang sang uống với cụ nhé.")
		else:
			_open_story("Cụ Hai", "Có rượu nếp à? Ta ngồi xuống nói chuyện xưởng tre một lát.", "Biếu rượu", _offer_workshop)
	elif state.repair_step == 0:
		if progress.day < BambooWorks.RESTORE_DAY:
			village_panel.open_dialogue("Thương Vụ Đầu Đời", "Ngày mai, mang 1.500 xu sang ký giao kèo nếu cháu muốn tiếp quản xưởng.")
		else:
			_open_story("Thương Vụ Đầu Đời", "Tiếp quản xưởng tre với giá 1.500 xu.", "Ký giao kèo", _buy_workshop)
	elif not state.ready():
		var tasks := ["Quét dọn sàn", "Tra dầu máy chẻ lạt", "Dựng biển hiệu"]
		_open_story("Khôi phục xưởng tre", "%d/3 việc đã xong. %s · 10 thể lực." % [state.repair_step - 1, tasks[state.repair_step - 1]],
			"Làm việc này", _repair_workshop)
		village_panel.show_works_restoration(state.repair_step)
	elif progress.day == AutumnWork.REST_DAY:
		village_panel.open_dialogue("Cụ Hai", "Sọt với rổ thì mày làm được rồi. Mai qua đây từ 07:30. Tao dạy mày đan khít, cái nghề ông ngoại mày học dở.")
	elif progress.day >= AutumnWork.CRAFT_DAY:
		_offer_fine_workshop()
	else:
		village_panel.open_dialogue("Cụ Hai", "Cụ sẽ coi máy giúp. Từ ngày 59, mẻ tre chạy nhanh hơn 20%.")


func _offer_fine_workshop() -> void:
	var state := progress.summer.autumn
	if not state.weave2:
		if progress.day == AutumnWork.CRAFT_DAY and progress.minute_of_day < AutumnWork.LESSON_HOUR:
			village_panel.open_dialogue("Cụ Hai", "Đợi ta chuẩn bị bó nan, từ 07:30 nhé.")
		else:
			_open_story("Cụ Hai", "Nan càng mỏng thì càng phải đều tay. Luồn cho đúng nhịp, rồi nén nan để mặt đan khít lại.", "Học đan khít", _learn_fine_weaving)
	elif state.first_bag > 0 and not state.old_story:
		_open_story("Cụ Hai", "Ông ngoại mày cũng từng đan đến đây.", "Chọn món đan", village_panel.open_fine_products.bind(progress),
			"Hỏi chuyện ông", _listen_to_old_workshop)
	else:
		village_panel.open_fine_products(progress)


func _learn_fine_weaving() -> void:
	if progress.learn_fine_weaving():
		_commit_progress()
		_open_story("Cụ Hai", "Cụ để sẵn 6 Nan Tinh và 1 dây mây cho chiếc giỏ đầu tiên. Muốn chẻ thêm nan, dùng chế độ Lạt mỏng ở máy.", "Chọn món đan",
			village_panel.open_fine_products.bind(progress))


func _finish_fine_weave(product: int, rank: int) -> void:
	var first := product == 1 and progress.summer.autumn.first_bag == 0
	if progress.finish_fine_weave(product, rank):
		_commit_progress()
		late_audio.play_effect(&"weave")
		var line := "%s · %s." % [AutumnWork.WEAVES[product], AutumnWork.RANKS[rank]]
		if first:
			line += "\nTay mày có nghề rồi. Ông ngoại mày học đến đây thì lên Hà Nội." if rank == 2 else (
				"\nNan còn chỗ chưa đều, nhưng lần đầu vậy là khá. Ông ngoại mày cũng từng học đến đây."
			)
			_open_story("Cụ Hai", line, "Hỏi chuyện ông", _listen_to_old_workshop)
		else:
			village_panel.open_dialogue("Đan khít", line)


func _listen_to_old_workshop() -> void:
	if progress.summer.autumn.first_bag > 0:
		progress.summer.autumn.old_story = true
		_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Tao cứ tưởng nghề này chôn theo tao. Giờ có đứa học lại, vậy là còn. Cháu ghi câu chuyện vào Sổ Tay Ông Ngoại nhé.")


func _offer_workshop() -> void:
	if progress.discuss_workshop():
		_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Cụ muốn giao xưởng lại cho cháu. Từ ngày 58, mang 1.500 xu sang để ký giao kèo.")


func _buy_workshop() -> void:
	if progress.buy_bamboo_workshop():
		_commit_progress()
		_talk_workshop_hai()
	else:
		village_panel.body.text = "Chưa đủ 1.500 xu để ký giao kèo."


func _repair_workshop() -> void:
	if progress.restore_bamboo_workshop():
		_rebuild_map()
		_commit_progress()
		late_audio.play_effect(&"splitter" if progress.summer.works.repair_step == 3 else &"anvil")
		_talk_workshop_hai()
	else:
		village_panel.body.text = "Chưa đủ 10 thể lực. Tiến độ xưởng đã được lưu."


func _open_county_buyer() -> void:
	if not progress.summer.works.county_met:
		progress.summer.works.county_met = true
		_commit_progress()
	village_panel.open_county_sale(progress)


func _begin_storm_tarp(cell: Vector2i) -> void:
	storm_hold_target = cell
	storm_hold_time = 0.0


func _hold_storm_tarp(delta: float) -> bool:
	if storm_hold_target.x < 0:
		return false
	if not Input.is_action_pressed("interact") or _move_direction() != Vector2i.ZERO or not progress.storm_active():
		storm_hold_target = Vector2i(-1, -1)
		storm_hold_time = 0.0
		_update_feedback()
		return false
	storm_hold_time += delta
	if storm_hold_time < 1.25:
		hint.text = "Đang kéo bạt · %d%%" % floori(storm_hold_time / 1.25 * 100.0)
		return true
	var bit := BambooWorks.COOP_TARP
	if progress.area == GardenProgress.Area.BAMBOO_WORKS:
		bit = BambooWorks.RAW_TARP if storm_hold_target == BambooWorksMap.RAW else BambooWorks.GOODS_TARP
	var covered := progress.protect_from_storm(bit)
	storm_hold_target = Vector2i(-1, -1)
	if covered:
		_rebuild_map()
		_commit_progress()
		_sync_storm_status()
		late_audio.play_effect(&"tarp")
		hint.text = "Đã buộc chặt bạt"
	return true


func _shut_storm_door() -> void:
	if progress.protect_from_storm(BambooWorks.DOOR):
		_commit_progress()
		village_panel.open_dialogue("Cửa nhà", "Cửa đã chốt. Ngủ để hồi đầy thể lực.")


func _leave_storm_house() -> void:
	village_panel.hide()
	_travel(GardenProgress.Area.GARDEN)


func _harvest_lan_available() -> bool:
	return progress.summer_available(LateSummer.HARVEST) and not progress.summer.late.hat and (
		progress.day > LateSummer.HARVEST or progress.minute_of_day >= 17 * 60
	)


func _late_summer_hint(cell: Vector2i) -> String:
	if not progress.summer_available(LateSummer.RECOVERY):
		return ""
	var day := progress.day
	match progress.area:
		GardenProgress.Area.LOTUS_POND:
			if cell == LateSummerMap.POND_EXIT:
				return "E · Lên bờ"
			var index := LateSummerMap.LOTUS.find(cell)
			var state := progress.summer.late
			if index >= 0 and (state.lotus_day != day or (state.lotus_mask & (1 << index)) == 0):
				return "E · Hái đài sen" if index < 10 else "E · Hái lá sen"
		GardenProgress.Area.COUNTY_FAIR:
			match cell:
				SummerMap.EXIT: return "E · Về bến sông Cầu"
				LateSummerMap.BUYER: return "E · Xem giá phiên hôm nay"
				LateSummerMap.SEEDS: return "E · Hỏi giống vụ thu"
		GardenProgress.Area.VILLAGE:
			if day >= LateSummer.LOTUS_DAY and cell == LateSummerMap.POND_GATE:
				return "E · Ra đầm sen"
			if day >= LateSummer.LOTUS_DAY and cell == SummerMap.HAI and (
				not progress.summer.late.lotus_done or day >= LateSummer.BASKET_DAY
			):
				return "E · Gặp Cụ Hai"
			if day >= LateSummer.BASKET_DAY:
				var bamboo := LateSummerMap.BAMBOO.find(cell)
				var rattan := LateSummerMap.RATTAN.find(cell)
				if bamboo >= 0 and ((progress.summer.late.bamboo_hits >> (bamboo * 3)) & 7) < 3:
					return "E · Chặt tre (−10 thể lực)"
				if rattan >= 0 and (progress.summer.late.rattan_mask & (1 << rattan)) == 0:
					return "E · Nhặt dây mây"
			if day >= LateSummer.FIRST_FAIR and cell == LateSummerMap.FERRY:
				return "E · Gặp Ông Lái Đò"
		GardenProgress.Area.GARDEN:
			match cell:
				LateSummerMap.COMPOST: return "E · Lấy phân thảo mộc"
				LateSummerMap.LAN: return "E · Gặp Chị Lan" if _harvest_lan_available() else ""
				LateSummerMap.PACKING: return "E · Xếp hàng vào sọt" if day >= LateSummer.HARVEST and progress.summer.late.basket_score >= 0 else ""
				DroughtProgress.WELL_SITE: return "E · Múc nước giếng phụ" if progress.summer.drought.well_step == 4 else ""
				SummerProgress.WELL_CELL: return "E · Múc nước giếng"
	return ""


func _interact_late_summer(cell: Vector2i) -> void:
	match progress.area:
		GardenProgress.Area.LOTUS_POND:
			if cell == LateSummerMap.POND_EXIT:
				_travel(GardenProgress.Area.VILLAGE)
			elif progress.gather_lotus(LateSummerMap.LOTUS.find(cell)):
				_rebuild_map()
				_commit_progress()
				_flash_interaction(cell)
				hint.text = "Đài sen %d/10 · Lá sen %d/5" % [progress.quantity(LateSummer.POD), progress.quantity(LateSummer.LEAF)]
		GardenProgress.Area.COUNTY_FAIR:
			match cell:
				SummerMap.EXIT: _travel(GardenProgress.Area.VILLAGE)
				LateSummerMap.BUYER: _open_county_buyer()
				LateSummerMap.SEEDS: village_panel.open_autumn_seeds(progress)
		GardenProgress.Area.VILLAGE:
			_interact_river(cell)
		GardenProgress.Area.GARDEN:
			match cell:
				DroughtProgress.WELL_SITE, SummerProgress.WELL_CELL:
					var auxiliary := cell == DroughtProgress.WELL_SITE
					if not auxiliary and progress.summer.parents_visited and progress.summer.sprinkler < 0:
						_open_story("Giếng", "Múc hai lượt nước cho bình hoặc lắp ống máy bơm.", "Múc nước", _draw_recovery_water.bind(false),
							"Nối ống", _interact_summer.bind(cell))
					else:
						_draw_recovery_water(auxiliary)
				LateSummerMap.COMPOST:
					var taken := progress.take_recovery_herbs()
					if taken:
						_commit_progress()
					village_panel.open_dialogue("Phân thảo mộc", "Đã lấy 3 phần. Múc nước rồi đứng trước luống ngô, bí đao hoặc đậu đũa và nhấn F để tưới thúc." if taken else "Hôm nay đã lấy phân. Sáng mai có thêm.")
				LateSummerMap.LAN: _offer_harvest_hat()
				LateSummerMap.PACKING: village_panel.open_cargo(progress)


func _draw_recovery_water(auxiliary: bool) -> void:
	var before := progress.arrival.total_stamina()
	var drawn := progress.draw_recovery_water(auxiliary)
	if drawn:
		late_audio.play_effect(&"water")
		_commit_progress()
	var line := "Bình tưới %d/6 · −%d thể lực. Nhấn F trước luống vụ hè để tưới thúc cùng phân thảo mộc." % [
		progress.summer.late.water, before - progress.arrival.total_stamina(),
	]
	if not drawn:
		line = "Bình đã đầy hoặc bạn cần lấy đồ nghề và nghỉ thêm."
	village_panel.open_dialogue("Giếng phụ" if auxiliary else "Giếng", line)


func _interact_river(cell: Vector2i) -> void:
	match cell:
		LateSummerMap.POND_GATE:
			if progress.summer.late.lotus_invited:
				_travel(GardenProgress.Area.LOTUS_POND)
			else:
				village_panel.open_dialogue("Đầm sen", "Gặp Cụ Hai ở phía bắc làng để mượn thuyền thúng.")
		SummerMap.HAI:
			if progress.can_receive_autumn_starter():
				_open_story("Cụ Hai", "Vụ thu bắt đầu rồi. Cụ có hai hạt mỗi loại khoai lang, lạc và bí ngô để cháu xuống giống.", "Nhận hạt",
					_take_autumn_starter, "Chuyện khác", _open_late_hai)
			else:
				_open_late_hai()
		LateSummerMap.FERRY: _offer_ferry()
		_:
			var bamboo := LateSummerMap.BAMBOO.find(cell)
			var gathered := progress.cut_river_bamboo(bamboo) if bamboo >= 0 else progress.collect_rattan(LateSummerMap.RATTAN.find(cell))
			if not gathered:
				return
			if bamboo >= 0:
				late_audio.play_effect(&"bamboo")
			var depleted := bamboo < 0 or ((progress.summer.late.bamboo_hits >> (bamboo * 3)) & 7) == 3
			if depleted:
				_rebuild_map()
			_commit_progress()
			_flash_interaction(cell)
			hint.text = "Tre ống %d/6 · Dây mây %d/3" % [progress.quantity(LateSummer.STEM), progress.quantity(LateSummer.RATTAN)]


func _open_late_hai() -> void:
	var state := progress.summer.late
	var legacy := _interact_summer.bind(SummerMap.HAI)
	if not state.lotus_invited:
		_open_story("Cụ Hai", "Cụ để thuyền thúng ở đầm phía đông bắc. Cháu hái giúp 10 đài sen và 5 lá to nhé.", "Nhận lời", _accept_lotus_trip, "Chuyện cũ", legacy)
	elif not state.lotus_done and progress.quantity(LateSummer.POD) >= 10 and progress.quantity(LateSummer.LEAF) >= 5:
		_open_story("Cụ Hai", "Đủ sen rồi. Cụ có một hũ trà và công thức chè hạt sen long nhãn cho cháu.", "Giao sen", _deliver_lotus)
	elif progress.can_weave_cargo_baskets():
		_open_story("Xưởng Cụ Hai", "Hai sọt cần 6 tre ống và 3 dây mây. Nhấn E lúc vạch chạy đến giữa để luồn nan chắc tay.", "Tập đan sọt", _start_cargo_weaving, "Chuyện cũ", legacy)
	elif state.basket_wear > 0:
		_open_story("Xưởng Cụ Hai", "Nan đã lỏng sau chuyến đò. Cụ có thể siết lại hai sọt.", "Siết nan", _repair_cargo_baskets, "Chuyện cũ", legacy)
	else:
		var line := "Đài sen %d/10 · Lá sen %d/5." % [progress.quantity(LateSummer.POD), progress.quantity(LateSummer.LEAF)]
		if progress.day >= LateSummer.BASKET_DAY and state.basket_score < 0:
			line += " Đan sọt cần 6 tre ống và 3 dây mây dọc bờ sông."
		_open_story("Cụ Hai", line, "Chuyện cũ", legacy)


func _take_autumn_starter() -> void:
	if progress.take_autumn_starter():
		_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Mở túi bằng I để chọn giống, rồi gieo lên đất đã cuốc. Tưới để cây lớn qua đêm.")


func _accept_lotus_trip() -> void:
	if progress.accept_lotus_trip():
		_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Ra lối phía đông bắc. Dùng phím di chuyển để chèo, nhấn E cạnh sen để hái.")


func _deliver_lotus() -> void:
	if progress.deliver_lotus():
		_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Cháu nhận một hũ trà sen. Công thức chè hạt sen long nhãn đã có ở bếp.")


func _start_cargo_weaving() -> void:
	if not progress.can_weave_cargo_baskets():
		return
	weaving = true
	weave_score = 0
	weave_round = 0
	weave_timer = 0.0
	weave_meter.value = 0
	weave_meter.show()
	_open_story("Luồn nan tre", "Nan 1/6 · Nhấn E khi thanh đi qua chính giữa.", "Luồn nan", _weave_cargo_beat)


func _close_cargo_weaving() -> void:
	if not village_panel.visible:
		weaving = false
		weave_meter.hide()


func _weave_cargo_beat() -> void:
	if not weaving:
		return
	late_audio.play_effect(&"weave")
	var perfect := absf(fposmod(weave_timer, 1.5) - 0.75) <= 0.22
	if perfect:
		weave_score += 1
	weave_round += 1
	weave_timer = 0.0
	weave_meter.value = 0
	if weave_round < 6:
		village_panel.body.text = "%s · Nan %d/6 · Nhấn E khi thanh qua giữa." % ["Chuẩn" if perfect else "Lệch nhịp", weave_round + 1]
		return
	weaving = false
	weave_meter.hide()
	if progress.weave_cargo_baskets(weave_score):
		_commit_progress()
		village_panel.open_dialogue("Xưởng Cụ Hai", "Đã đan hai sọt. %d/6 nhịp chuẩn · Độ bền %d · 10 ô xếp hàng." % [weave_score, weave_score + 2])


func _repair_cargo_baskets() -> void:
	progress.summer.late.basket_wear = 0
	_commit_progress()
	village_panel.open_dialogue("Cụ Hai", "Cụ đã siết lại nan. Sọt có thể gánh tiếp.")


func _offer_harvest_hat() -> void:
	_open_story("Chị Lan", "Mai có phiên Chợ Huyện. Chị gửi em chiếc nón lá mới, đội khi làm vườn và ra bến.", "Nhận nón", _accept_harvest_hat)


func _accept_harvest_hat() -> void:
	if progress.accept_harvest_hat():
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Chị Lan", "Nón đã đội. Làm vườn khi trời nắng hao ít thể lực hơn.")


func _offer_ferry() -> void:
	if not LateSummer.fair_day(progress.day) or progress.minute_of_day >= GardenCalendar.MARKET_CLOSE:
		var days := posmod(LateSummer.FIRST_FAIR - progress.day, 7)
		village_panel.open_dialogue("Ông Lái Đò", "Phiên kế tiếp ngày %d. Đò đưa khách sang chợ trước 16:00." % (progress.day + (7 if days == 0 else days)))
		return
	_open_story("Ông Lái Đò", "Vé khứ hồi 50 xu. Phiên Chợ Huyện mở từ 06:00 đến 16:00.", "Lên đò · 50 xu", _board_county_ferry)


func _board_county_ferry() -> void:
	if progress.buy_ferry_trip():
		village_panel.hide()
		_travel(GardenProgress.Area.COUNTY_FAIR)
	else:
		village_panel.open_dialogue("Ông Lái Đò", "Cần 50 xu và sọt còn bền nếu có chở hàng. Cụ Hai có thể siết lại nan.")


func _can_bulk_harvest(cell: Vector2i) -> bool:
	return progress.summer_available(LateSummer.HARVEST) and progress.area == GardenProgress.Area.GARDEN and (
		progress.plots.has(cell) and progress.plots[cell].crop_id in CropCatalog.SUMMER_CROPS and progress.plot_action(cell) == PlotAction.HARVEST
	)


func _harvest_summer_field() -> void:
	var count := 0
	for cell in progress.plots:
		if _can_bulk_harvest(cell) and progress.work_plot(cell):
			_update_plot(cell)
			count += 1
	if count > 0:
		late_audio.play_effect(&"harvest")
		_commit_progress()
		hint.text = "Đã thu hoạch thêm %d luống vụ hè." % count


func _is_drought_cell(cell: Vector2i) -> bool:
	if not progress.summer_available(DroughtProgress.FIRST):
		return false
	var state := progress.summer.drought
	if _in_house():
		return cell == VillageSocial.PHONE and progress.in_drought() and progress.day >= DroughtProgress.OIL_DAY
	if _in_village():
		return (cell == DroughtProgress.THANH and progress.day >= DroughtProgress.OIL_DAY) or (
			cell == DroughtProgress.TAM and progress.day >= DroughtProgress.SHARE_DAY and (
				state.share_choice == 1 or (progress.in_drought() and state.share_choice == 0)
			)
		)
	if progress.area != GardenProgress.Area.GARDEN:
		return false
	if progress.day == DroughtProgress.RAIN and cell == SummerMap.LY:
		return true
	return (cell == DroughtProgress.WELL_SITE and state.learned_well) or (progress.in_drought() and (
		cell == SummerMap.PUMP and progress.summer.parents_visited or cell == SummerProgress.WELL_CELL or cell == TROUGH or (
			cell == VillageSocial.CHIEF and state.delivery == progress.day and state.oil == 0
		) or (cell == SummerMap.LY and progress.day == DroughtProgress.LAST and not state.ly_help and state.well_step < 4)
	))


func _drought_hint(cell: Vector2i) -> String:
	match cell:
		DroughtProgress.THANH: return "E · Hỏi Chú Thành"
		DroughtProgress.TAM: return "E · Chuyện nước giếng"
		DroughtProgress.WELL_SITE: return "E · Xem giếng phụ"
		SummerProgress.WELL_CELL: return "E · Xem mực nước giếng"
		SummerMap.PUMP: return "E · Kiểm tra dầu máy bơm"
		VillageSocial.PHONE: return "E · Xem điện thoại"
		TROUGH: return "E · Máng ăn và nước uống"
		SummerMap.LY: return "E · Tổng kết đợt hạn" if progress.day == DroughtProgress.RAIN else "E · Nhận nước của Bác Lý"
		VillageSocial.CHIEF: return "E · Nhận dầu của Tuấn"
	return ""


func _interact_drought(cell: Vector2i) -> void:
	var state := progress.summer.drought
	match cell:
		VillageSocial.PHONE:
			if state.oil == 0 and progress.summer.sprinkler >= 0:
				if state.delivery == progress.day:
					village_panel.open_dialogue("Tuấn", "Từ 12:00 tao đem can dầu tới sân. Giá %d xu." % DroughtProgress.OIL_TUAN)
				else:
					_open_story("Điện thoại", "Nhờ Tuấn đem dầu tới sân lúc 12:00.", "Nhắn Tuấn", _order_oil,
						"Tin nhắn cũ", _interact_social.bind(cell))
			else:
				_interact_social(cell)
		DroughtProgress.THANH:
			village_panel.open_drought_shop(progress)
		DroughtProgress.TAM:
			if state.share_choice == 0:
				_open_story("Trưởng thôn", "Giếng nhà bà Tám cạn. Cho bà múc nhờ hai gàu mỗi ngày đến hết hạn được không?", "Mời bà sang", _share_well.bind(1), "Giếng cũng cạn", _share_well.bind(2))
			else:
				village_panel.open_dialogue("Bà Tám", "Cảm ơn cháu đã san sẻ nước giếng.")
		VillageSocial.CHIEF:
			if progress.minute_of_day < 12 * 60:
				village_panel.open_dialogue("Tuấn", "Tao giao dầu từ 12:00.")
			else:
				_open_story("Tuấn", "Can dầu %d xu. Đổ vào máy bơm rồi dùng ngay." % DroughtProgress.OIL_TUAN, "Nhận can dầu", _drought_buy.bind("tuan"))
		SummerMap.PUMP:
			var line := "Còn dầu cho %d ngày hạn." % state.oil if state.oil > 0 else "Hết dầu. Hỏi Chú Thành ở làng hoặc nhắn Tuấn."
			village_panel.open_dialogue("Máy bơm", line)
		SummerProgress.WELL_CELL:
			_open_story("Giếng chính", "Hôm nay còn %d gàu nước." % state.supply, "Xem vòi tưới", _open_drought_pipes)
		DroughtProgress.WELL_SITE:
			_open_auxiliary_well()
		TROUGH:
			_open_story("Máng gà", "Đã cho uống %d/2 lượt. Cho uống lần hai sau 15:00." % state.chicken_water,
				"Thêm nước", _water_hens, "Thêm thức ăn", _feed_drought_hens)
		SummerMap.LY:
			if progress.day == DroughtProgress.RAIN:
				state.review_seen = true
				_commit_progress()
				village_panel.open_dialogue("Sau cơn mưa", progress.drought_summary())
			elif progress.take_ly_water():
				_rebuild_map()
				_commit_progress()
				village_panel.open_dialogue("Bác Lý", "Bác để ba gàu nước ở giếng. Cháu tưới mấy luống cần cứu trước.")


func _share_well(choice: int) -> void:
	if progress.choose_water_share(choice):
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Trưởng thôn", "Bà Tám sẽ qua múc. Cháu được thêm 15 uy tín." if choice == 1 else "Ừ, để bác hỏi nhà khác.")
	else:
		village_panel.open_dialogue("Trưởng thôn", "Giếng còn ít nước quá. Bác sẽ quay lại sau.")


func _order_oil() -> void:
	if progress.order_drought_oil():
		_commit_progress()
		village_panel.open_dialogue("Tuấn", "Từ 12:00 tao ghé sân đem dầu tới.")


func _drought_buy(item: String) -> void:
	if progress.buy_drought_supply(item):
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Đã nhận", "Đã bổ sung nước hoặc vật tư cho vườn.")
	else:
		village_panel.open_dialogue("Chưa mua được", "Kiểm tra số xu, giờ bán và vật tư đang có.")


func _open_auxiliary_well() -> void:
	var state := progress.summer.drought
	if state.well_step == 4:
		village_panel.open_dialogue("Giếng phụ", "Giếng cũ của ông đã có nước. Nguồn này giữ lại cho các mùa sau.")
		return
	if progress.day < DroughtProgress.DIG_DAY:
		village_panel.open_dialogue("Dấu giếng cũ", "Có thể bắt đầu đào từ ngày 48.")
		return
	var steps := ["Dọn đất · 20 thể lực", "Đào sâu · 30 thể lực", "Chắn vách · 8 gỗ tạp", "Thả dây · 1 dây thừng"]
	_open_story("Đào giếng phụ", "Bước %d/4. %s." % [state.well_step + 1, steps[state.well_step]], "Làm bước này", _build_auxiliary_well)


func _build_auxiliary_well() -> void:
	if progress.build_auxiliary_well():
		_rebuild_map()
		_commit_progress()
		_open_auxiliary_well()
	else:
		village_panel.open_dialogue("Giếng phụ", "Chưa đủ thể lực hoặc vật liệu. Tiến độ hiện tại đã lưu.")


func _open_drought_pipes() -> void:
	village_panel.hide()
	if progress.summer.found_pipes and progress.arrival.power_on:
		workshop.open_pipes(progress.summer.sprinkler, progress.summer.received_heirlooms, progress.summer_story != null)
	else:
		village_panel.open_dialogue("Giếng chính", "Lấy ống ở kệ và bật cầu dao trước khi nối vòi.")


func _water_hens() -> void:
	if progress.water_hens():
		_commit_progress()
		village_panel.open_dialogue("Máng nước", "Đã cho gà uống %d/2 lượt." % progress.summer.drought.chicken_water)
	else:
		village_panel.open_dialogue("Máng nước", "Máng đủ nước, giếng cạn hoặc chưa đến lượt chiều.")


func _feed_drought_hens() -> void:
	if progress.feed_hen():
		_refresh_tutorial_props()
		_commit_progress()
		village_panel.open_dialogue("Máng ăn", "Đã thêm thức ăn.")
	else:
		village_panel.open_dialogue("Máng ăn", "Mở chuồng lấy phần thức ăn đầu hoặc chờ gà ăn hết.")


func _ly_available() -> bool:
	return progress.day == SummerCraft.FORECAST_DAY or (
		progress.summer_available(SummerCraft.HEAT_HINT_DAY) and not progress.summer.craft.ly_warned
	)


func _lan_visit_available() -> bool:
	return progress.summer_available(SummerCraft.LAN_DAY) and progress.summer.craft.lan_reply == 0 and (
		progress.day > SummerCraft.LAN_DAY or progress.minute_of_day >= SummerCraft.LAN_VISIT_HOUR
	)


func _is_craft_cell(cell: Vector2i) -> bool:
	if not progress.summer_available(SummerCraft.TRIP_DAY):
		return false
	var craft := progress.summer.craft
	if _in_district():
		return cell in [SummerMap.HUONG, SummerMap.CRAFT_STALL] or (progress.day >= SummerCraft.BUYER_DAY and cell == SummerMap.BINH)
	if _in_house():
		return (cell == SummerMap.EMBROIDERY and craft.needle) or (cell == SummerMap.AQUARIUM and craft.tank) or (
			cell == SummerMap.LAN_INSIDE and _event_npc_present(cell)
		)
	if progress.area == GardenProgress.Area.GARDEN:
		return (cell == SummerMap.LY and _ly_available()) or (cell == SummerMap.LAN_VISIT and _event_npc_present(cell)) or (
			cell == SummerMap.JAR and craft.jar
		)
	return false


func _craft_hint(cell: Vector2i) -> String:
	match cell:
		SummerMap.HUONG: return "E · Ghé quán bún Cô Hương"
		SummerMap.CRAFT_STALL: return "E · Mua vải và vật dụng"
		SummerMap.BINH: return "E · Nói với Chú Bình"
		SummerMap.LY: return "E · Nói với Bác Lý"
		SummerMap.LAN_VISIT, SummerMap.LAN_INSIDE: return "E · Nói chuyện với Chị Lan"
		SummerMap.JAR: return "E · Xem chum nước"
		SummerMap.EMBROIDERY: return "E · Ngồi vào khung thêu"
		SummerMap.AQUARIUM: return "E · Xem bể cá"
	return ""


func _interact_craft(cell: Vector2i) -> void:
	match cell:
		SummerMap.HUONG:
			_open_story("Quán bún Cô Hương", "Một bát %d xu. Ăn xong, công việc ở luống tốn ít thể lực hơn trong ngày." % SummerCraft.HUNGER_PRICE, "Ăn bún", _buy_bun)
		SummerMap.CRAFT_STALL:
			village_panel.open_craft_shop(progress)
		SummerMap.BINH:
			if progress.introduce_buyer():
				_commit_progress()
			village_panel.open_dialogue("Chú Bình", "Chú mua lô hàng từ 50 kg, giá cao hơn 20%. Khi nào thu đủ, cứ liên hệ. Cháu giữ danh thiếp nhé.")
		SummerMap.LY:
			if not progress.summer.craft.ly_warned:
				progress.summer.craft.ly_warned = true
				_commit_progress()
			if progress.day >= SummerCraft.FORECAST_DAY:
				village_panel.open_dialogue("Bác Lý", "Mai bắt đầu năm ngày nắng hạn. Chuẩn bị nước và kiểm tra dầu máy bơm trước khi ngủ.")
			else:
				_rebuild_map()
				village_panel.open_dialogue("Bác Lý", "Đất khô nhanh. Luống ngoài vòi cần tưới hai lượt hôm nay. Ra chợ huyện sắm chum để dành nước.")
		SummerMap.JAR:
			village_panel.open_dialogue("Chum nước", "Chum đã đặt cạnh sân. Nước dự trữ sẽ dùng khi đợt hạn bắt đầu.")
		SummerMap.LAN_VISIT, SummerMap.LAN_INSIDE:
			if not _in_house():
				village_panel.open_dialogue("Chị Lan", "Em muốn ngồi nói chuyện một chút. Mình vào nhà nhé.")
			else:
				_open_lan_visit()
		SummerMap.EMBROIDERY:
			if progress.summer.autumn.embroidery2:
				_open_story("Khung thêu", "Chọn khăn hoa hoặc mẫu cấp 2.", "Thêu khăn hoa", _open_embroidery.bind(true),
					"Thêu cấp 2", _choose_advanced_embroidery)
			else:
				_open_embroidery(progress.summer.craft.embroidery)
		SummerMap.AQUARIUM:
			if progress.stock_aquarium():
				farmhouse.queue_redraw()
				_commit_progress()
			var line := "Cá vàng đang bơi quanh chiếc bể." if progress.summer.craft.tank_fish else "Có thể thả cá vàng câu ở ao sen vào đây."
			village_panel.open_dialogue("Bể cá mini", line)


func _buy_bun() -> void:
	if progress.buy_craft_supply("bun"):
		_commit_progress()
		village_panel.open_dialogue("Cô Hương", "Ăn nóng nhé. Hôm nay làm việc ngoài luống đỡ tốn sức.")
	else:
		village_panel.open_dialogue("Cô Hương", "Mỗi ngày một bát. Quán mở 06:00–18:00, giá %d xu." % SummerCraft.HUNGER_PRICE)


func _open_embroidery(flower: bool) -> void:
	village_panel.hide()
	if not progress.start_embroidery():
		village_panel.open_dialogue("Khung thêu", "Gặp Bà Minh và xem lại chiếc khăn cũ trước.")
		return
	_commit_progress()
	if progress.quantity(SummerCraft.CLOTH) == 0 or progress.quantity(VillageSocial.THREAD) == 0:
		village_panel.open_dialogue("Khung thêu", "Cần một tấm vải trắng và một cuộn chỉ màu. Sạp vật dụng ở chợ huyện có bán.")
		return
	embroidery_panel.open_project(flower)


func _embroidery_finished(pattern: String, flower: bool) -> void:
	if progress.finish_embroidery(pattern, flower):
		_commit_progress()
		var line := "Đã thêu một chiếc khăn hoa." if flower else "Mũi đầu còn vụng, nhưng do chính tay cháu làm. Giữ miếng thêu này làm kỷ niệm nhé."
		village_panel.open_dialogue("Bà Minh", line)


func _learn_advanced_embroidery() -> void:
	if progress.learn_advanced_embroidery():
		_commit_progress()
		_choose_advanced_embroidery()


func _choose_advanced_embroidery() -> void:
	if progress.quantity(SummerCraft.CLOTH) < 1 or progress.quantity(VillageSocial.THREAD) < 1:
		village_panel.open_dialogue("Thêu Cấp 2", "Mỗi mẫu cần một tấm vải trắng và một cuộn chỉ màu.")
		return
	_open_story("Thêu Cấp 2", "Dùng mũi thẳng, mũi chéo và mũi vòng. Chọn một mẫu để thêu.", "Chim hạc",
		_open_advanced_embroidery.bind(0), "Hoa sen", _open_advanced_embroidery.bind(1))


func _open_advanced_embroidery(motif: int) -> void:
	village_panel.hide()
	embroidery_panel.open_advanced(motif)


func _advanced_embroidery_finished(motif: int) -> void:
	if progress.finish_advanced_embroidery(motif):
		_commit_progress()
		village_panel.open_dialogue("Bà Minh", "Đã thêu xong mẫu %s. Có thể bán ở chợ huyện." % AutumnWork.MOTIFS[motif].to_lower())


func _open_lan_visit() -> void:
	if progress.day == SummerCraft.LAN_DAY and progress.minute_of_day < 12 * 60 + 30:
		village_panel.open_dialogue("Lời nhắn", "Chị Lan sẽ ghé sau 12:30.")
	elif progress.summer.craft.lan_choice == 0:
		festival_panel.open_lan()
	else:
		_lan_question()


func _lan_choice(choice: int) -> void:
	if progress.record_lan_choice(choice):
		_commit_progress()
		_lan_question()


func _lan_question() -> void:
	var opening := ["Em chỉ hỏi để biết thôi.", "Em cũng chưa quyết định được.", "Em hiểu vì sao anh muốn ở lại."]
	_open_story("Chị Lan", "%s Có người hỏi cưới em, nhưng anh ấy muốn em lên huyện ở. Em đang phân vân." % opening[progress.summer.craft.lan_choice - 1],
		"Chị thấy sao?", _listen_to_lan.bind(1), "Chị muốn ở lại?", _listen_to_lan.bind(2))


func _listen_to_lan(reply: int) -> void:
	if progress.listen_to_lan(reply):
		farmhouse.queue_redraw()
		_commit_progress()
		var response := "Anh ấy tốt, nhưng em chưa biết mình muốn gì." if reply == 1 else "Em chưa biết mình có muốn rời làng không."
		village_panel.open_dialogue("Chị Lan", response + "\nCảm ơn anh đã nghe em.")


func _summer_cell(cell: Vector2i) -> bool:
	if not progress.summer_available(SummerProgress.FIRST_DAY):
		return false
	if _in_village():
		return (_rice_available() and cell in SummerMap.DRYING_RICE) or cell == SummerMap.GATE or (
			cell in [SummerMap.HAI, SummerMap.MAI] and _event_npc_present(cell)
		)
	if progress.area != GardenProgress.Area.GARDEN:
		return false
	if progress.day >= SummerProgress.BUILD_DAY and (cell in SummerMap.WOOD_TREES or cell == SummerMap.STRAW):
		return true
	if progress.day >= SummerProgress.QUIET_DAY and cell in [SummerMap.LOTUS, SummerMap.HERBS]:
		return true
	return SummerMap.POND.has_point(cell) or (
		progress.day >= SummerProgress.WEAVE_DAY and cell in [SummerMap.BAMBOO, SummerMap.HAI_YARD]
	) or (cell in [SummerMap.PARENTS, SummerMap.PARENTS + Vector2i.UP] and _event_npc_present(cell)) or (
		progress.day >= SummerProgress.PUMP_DAY and (cell == SummerProgress.WELL_CELL or (
			cell == SummerMap.PUMP and progress.summer.parents_visited
		))
	)


func _summer_hint(cell: Vector2i) -> String:
	if _in_district():
		match cell:
			SummerMap.EXIT: return "E · Về làng"
			SummerMap.WHOLESALER: return "E · Xem giá và bán buôn"
			SummerMap.SEED_SHOP: return "E · Mua hạt ở chợ huyện"
			SummerMap.TOOL_SHOP: return "E · Xem đồ nghề"
		return "I · Túi đồ    J · Nhật ký"
	match cell:
		SummerMap.GATE: return "E · Đi chợ huyện"
		SummerMap.HAI: return "E · Nói với Cụ Hai"
		SummerMap.MAI: return "E · Nói với Mai"
		SummerMap.BAMBOO: return "E · Lấy tre"
		SummerMap.HAI_YARD: return "E · Đan rổ tre"
		SummerMap.PUMP: return "E · Kiểm tra máy bơm"
		SummerProgress.WELL_CELL: return "E · Nối ống tưới"
	if cell in SummerMap.WOOD_TREES:
		return "E · Lấy gỗ (−4 thể lực)"
	if cell in SummerMap.DRYING_RICE and _in_village():
		return "E · Lật thóc trên phên"
	if not _in_village():
		match cell:
			SummerMap.STRAW: return "E · Nhặt rơm khô"
			SummerMap.HERBS: return "E · Hái rau má"
			SummerMap.LOTUS: return "E · Câu cá ao sen" if progress.summer_available(SummerCraft.LOTUS_DAY) else "E · Ngắm ao sen"
		if SummerMap.POND.has_point(cell) and progress.summer_available(SummerProgress.QUIET_DAY):
			return "E · Câu cá ven ao"
	return "E · Nói với bố mẹ" if cell in [SummerMap.PARENTS, SummerMap.PARENTS + Vector2i.UP] else "Bờ ao"


func _interact_district(cell: Vector2i) -> void:
	match cell:
		SummerMap.EXIT: _travel(GardenProgress.Area.VILLAGE)
		SummerMap.WHOLESALER: village_panel.open_wholesale(progress)
		SummerMap.SEED_SHOP:
			if GardenCalendar.shop_is_open(progress.minute_of_day):
				farm_panel.open(FarmPanel.Mode.SHOP, progress)
			else:
				village_panel.open_dialogue("Sạp hạt", "Sạp mở từ %s." % GardenCalendar.shop_hours())
		SummerMap.TOOL_SHOP: village_panel.open_supplies(progress)


func _interact_summer(cell: Vector2i) -> void:
	var summer := progress.summer
	if _in_village() and cell in SummerMap.DRYING_RICE:
		if progress.turn_drying_rice(SummerMap.DRYING_RICE.find(cell)):
			_refresh_drying_rice()
			_commit_progress()
			if summer.lan_helped:
				village_panel.open_dialogue("Chị Lan", "Cảm ơn anh lật giúp mấy phên thóc. Em gửi ly nước mía. Nhấn H khi muốn uống.")
			elif progress.summer_story != null and progress.day == SummerProgress.SOLO_DAY and progress.summer_story.done("solo_rice_0") and progress.summer_story.done("solo_rice_1") and progress.summer_story.done("solo_rice_2"):
				village_panel.open_dialogue("Chị Lan", "Cảm ơn anh lật giúp ba phên thóc. +5 thân thiết.")
			else:
				hint.text = "Đã lật thóc"
		return
	if not _in_village():
		if cell in SummerMap.WOOD_TREES:
			_collect_material(SummerProgress.WOOD, SummerMap.WOOD_TREES.find(cell))
			return
		if cell == SummerMap.STRAW:
			_collect_material(SummerProgress.STRAW)
			return
		if cell == SummerMap.LOTUS:
			if progress.summer_available(SummerCraft.LOTUS_DAY) and progress.minute_of_day < GardenCalendar.LAST_MINUTE:
				lotus_cast = true
				fishing_panel.cast(progress.pond_fish(), 3.0, 4.0)
				return
			summer.lotus_seen = true
			_commit_progress()
			village_panel.open_dialogue("Ao sen", "Sau bụi tre có một ao nhỏ. Lá sen nằm im trên mặt nước.")
			return
		if cell == SummerMap.HERBS:
			if progress.gather_pennywort():
				_commit_progress()
				hint.text = "Đã hái rau má"
			else:
				hint.text = "Rau má mọc lại vào ngày mai"
			return
		if SummerMap.POND.has_point(cell) and progress.summer_available(SummerProgress.QUIET_DAY):
			if progress.minute_of_day < GardenCalendar.LAST_MINUTE:
				fishing_panel.cast(progress.fishing_species(), 22.0, 4.0)
			return
	match cell:
		SummerMap.GATE:
			if progress.can_visit_district():
				_travel(GardenProgress.Area.DISTRICT)
			else:
				village_panel.open_dialogue("Đường ra huyện", "Tuấn sẽ dẫn đi chợ huyện từ ngày 36. Lão Lái Buôn đang ở chợ làng, gần bến sông.")
		SummerMap.HAI:
			if progress.learn_auxiliary_well():
				_commit_progress()
				village_panel.open_dialogue("Cụ Hai", "Đợt hạn năm 88, ông ngoại cháu còn giữ được rau nhờ giếng phụ. Giếng bị lấp ở góc đông vườn. Từ ngày 48 cháu có thể đào lại.")
				return
			if progress.day >= SummerProgress.QUIET_DAY and progress.minute_of_day >= 14 * 60 and summer.received_heirlooms and not summer.hai_chat:
				summer.hai_chat = true
				_commit_progress()
				village_panel.open_dialogue("Cụ Hai", "Hôm nay cháu trông thong thả hơn. Ngồi đây với cụ một lúc.")
				return
			if not summer.read_letter:
				village_panel.open_dialogue("Cụ Hai", "Về xem ngăn kéo tủ chè nhà cháu. Ông để lại đôi lời ở đấy.")
			elif progress.receive_heirlooms():
				_commit_progress()
				_open_story("Giống cũ của ông", "Cụ Hai trao 10 hạt cà rốt Thuận Thành, 3 củ giống và 8 thóc nếp. Cuốc sâu ô khô và dẫn nước vào ô lúa ở ven ao.", "Mời cụ ăn cơm", _invite_hai, "Để lần khác", _decline_hai)
			elif not summer.invited_hai and not summer.ate_with_hai:
				_open_story("Cụ Hai", "Ngày trước ông cháu trồng cà rốt với nếp ở góc ao.", "Mời cụ ăn cơm", _invite_hai)
			else:
				village_panel.open_dialogue("Cụ Hai", "Cà rốt phải cuốc hai lớp. Thóc nếp gieo ở ô đã dẫn nước.")
		SummerMap.MAI:
			if progress.summer_story != null and progress.day == SummerProgress.MAI_DAY and not summer.met_mai:
				village_panel.open_dialogue("Mai", "Lát em ghé hàng rào vườn anh nhé.")
				return
			if not summer.met_mai:
				summer.met_mai = true
				_commit_progress()
			village_panel.open_dialogue("Mai", "Ông ngoại anh hay trồng cà rốt ven ao. Năm nào ông cũng cho nhà em một mớ.")
		SummerMap.HAI_YARD:
			_open_weaving()
		SummerMap.BAMBOO:
			if progress.gather_bamboo():
				_commit_progress()
				_flash_interaction(cell)
				hint.text = "Tre ×%d · Đến sân trước nhà để đan" % progress.quantity(SummerProgress.BAMBOO)
			else:
				village_panel.open_dialogue("Bụi tre", "Đã có 5 bó tre. Dùng bớt rồi quay lại.")
		SummerMap.PUMP:
			if not summer.inspected_pump:
				summer.inspected_pump = true
				_commit_progress()
			village_panel.open_dialogue("Máy bơm của bố", "Tìm ống nhựa xanh và đầu nối ở kệ trong nhà. Bật cầu dao trước khi chạy máy.")
		SummerProgress.WELL_CELL:
			if not summer.found_pipes or not progress.arrival.power_on:
				village_panel.open_dialogue("Giếng", "Kiểm tra máy bơm, lấy ống ở kệ trong nhà và bật cầu dao.")
			else:
				workshop.open_pipes(summer.sprinkler, summer.received_heirlooms, progress.summer_story != null)
		_:
			if cell in [SummerMap.PARENTS, SummerMap.PARENTS + Vector2i.UP]:
				_family_visit()


func _open_story(title: String, line: String, label: String, primary: Callable, other := "", secondary := Callable()) -> void:
	story_action = primary
	alternative_story_action = secondary
	village_panel.open_confirmation(title, line, label, VillagePanel.Mode.STORY)
	village_panel.switch_order.visible = secondary.is_valid()
	village_panel.switch_order.disabled = false
	village_panel.switch_order.text = other


func _invite_hai() -> void:
	progress.summer.invited_hai = true
	_commit_progress()
	village_panel.open_dialogue("Cụ Hai", "Ừ, tao ngồi chờ. Cháu qua bếp dọn mâm nhé.")


func _decline_hai() -> void:
	if progress.summer_story != null and progress.summer_story.hai_points == 0:
		progress.summer_story.hai_points = 5
		progress.summer_story.mark("hai_declined")
		_commit_progress()
	village_panel.hide()


func _serve_story_meal(preferred := "") -> void:
	var family := progress.summer.parents_visited and not progress.summer.family_meal
	if progress.summer_story != null and not family and progress.day == SummerProgress.LETTER_DAY:
		if progress.minute_of_day >= 900:
			village_panel.open_dialogue("Cụ Hai", "Qua giờ cơm rồi, hẹn dịp khác cháu nhé.")
			return
		if progress.quantity(FishCatalog.GOBY) == 0 and progress.quantity("cabbage_produce") == 0 and progress.quantity("amaranth") == 0 and progress.quantity(ArrivalProgress.EGG) == 0:
			village_panel.open_dialogue("Bếp nhà", "Cụ Hai đang chờ. Chuẩn bị cơm và thêm một món cá, trứng hoặc rau trước 15:00.")
			return
	var meal := progress.cook_family_meal(preferred)
	if meal.is_empty():
		return
	_commit_progress()
	if family:
		if progress.summer_story != null:
			_open_story("Bữa cơm gia đình", "Dọn %s. Buổi chiều có thể dẫn bố mẹ tới góc ven ao của ông." % meal,
				"Ra vườn sau", _start_family_walk, "Để bố mẹ nghỉ", village_panel.hide)
		else:
			_open_story("Bữa cơm gia đình", "Dọn %s. Mẹ dặn Hoàng nhớ ăn uống đàng hoàng." % meal, "Con ổn mà", _family_reply.bind(5), "Con nhớ nhà", _family_reply.bind(10))
	else:
		if progress.summer_story != null:
			progress.summer_story.hai_points = 30
			progress.summer_story.mark("hai_hint")
			_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Ăn %s xong, cụ nhắc lại chuyện ông ngoại học đan rổ. Hôm nào rảnh ra sân, cụ chỉ cho." % meal)


func _choose_family_dishes() -> void:
	if progress.day == SummerProgress.FAMILY_DAY and progress.minute_of_day < 780:
		village_panel.open_dialogue("Bếp nhà", "Mẹ đang nghỉ sau chuyến đi. Dọn bữa cơm từ 13:00.")
		return
	var ingredients: Array[String] = []
	for item in [FishCatalog.GOBY, FishCatalog.PERCH, FishCatalog.CATFISH, FishCatalog.CARP, ArrivalProgress.EGG, "amaranth", "cabbage_produce", GardenProgress.FIRST_PRODUCE]:
		if progress.quantity(item) > 0:
			ingredients.append(item)
	var first := ingredients[0] if not ingredients.is_empty() else "rice_only"
	var second := ingredients[1] if ingredients.size() > 1 else "rice_only"
	_open_story("Dọn cơm cho bố mẹ", "Chọn món từ nguyên liệu còn trong túi. Mẹ mang gạo quê đủ cho vài bữa.",
		"Cơm và " + progress.item_label(first).to_lower() if first != "rice_only" else "Nấu cơm trắng", _serve_story_meal.bind(first),
		"Cơm và " + progress.item_label(second).to_lower() if second != "rice_only" else "", _serve_story_meal.bind(second))


func _start_family_walk() -> void:
	village_panel.hide()
	if progress.day == SummerProgress.FAMILY_DAY:
		progress.minute_of_day = maxi(progress.minute_of_day, 900)
	_travel(GardenProgress.Area.GARDEN)
	_cross_farm_gate()


func _family_reply(points: int) -> void:
	if progress.summer.family_replied:
		return
	progress.summer.family_replied = true
	progress.summer.mom_points += points
	_rebuild_map()
	_commit_progress()
	village_panel.open_dialogue("Mẹ", "Có gì thì cứ gọi. Từ đây về nhà cũng gần thôi.")


func _family_visit() -> void:
	if not _family_available():
		return
	if progress.summer.family_meal and not progress.summer.family_replied:
		_open_story("Bố mẹ chuẩn bị về", "Mẹ dặn Hoàng nhớ ăn uống đàng hoàng.", "Con ổn mà", _family_reply.bind(5), "Con nhớ nhà", _family_reply.bind(10))
	elif progress.day == SummerProgress.FAMILY_DAY and progress.minute_of_day < int(SummerProgress.VISIT_WINDOWS[SummerProgress.FAMILY_DAY]):
		village_panel.open_dialogue("Lời nhắn của mẹ", "Trưa nay từ 11:30 bố mẹ qua. Con cứ làm việc của con nhé.")
	elif progress.receive_family_visit():
		_commit_progress()
		_rebuild_map()
		village_panel.open_dialogue("Bố mẹ ghé thăm", "Mẹ mang gạo quê. Bố để máy bơm cũ cạnh giếng. Vào bếp nấu một bữa cơm cùng bố mẹ.")
	else:
		village_panel.open_dialogue("Bố mẹ", "Mẹ nhìn mấy luống ven ao lại nhớ ông. Bố dặn con xem máy bơm khi rảnh.")


func _interact_house_story(cell: Vector2i) -> void:
	var summer := progress.summer
	match cell:
		Farmhouse.CUPBOARD:
			if progress.read_heirloom_letter():
				_commit_progress()
				village_panel.open_dialogue("Thư ông ngoại", "Góc đất bên ao từng trồng cà rốt Thuận Thành và nếp cái hoa vàng. Nếu muốn trồng lại giống cũ, sang hỏi Cụ Hai.")
			elif progress.day >= SummerProgress.CITY_LETTER_DAY and not summer.read_city_letter:
				if progress.day == SummerProgress.CITY_LETTER_DAY and progress.minute_of_day < 12 * 60:
					village_panel.open_dialogue("Tủ chè", "Bưu tá thường ghé lúc 12:00.")
					return
				if progress.summer_story != null:
					_deliver_city_letter()
					return
				summer.read_city_letter = true
				_commit_progress()
				village_panel.open_dialogue("Thư từ Hà Nội", "Đồng nghiệp cũ nhắn dự án mới đang cần người. Hoàng cất thư vào ngăn tủ, cạnh lá thư của ông.")
			elif progress.find_embroidered_scarf():
				_commit_progress()
				village_panel.open_dialogue("Ngăn dưới tủ chè", "Một chiếc khăn thêu chim hạc, ký tên Minh năm 1987. Bên dưới còn ba cuộn chỉ màu. Mang khăn sang cho bà xem.")
			elif summer.social.scarf_found:
				village_panel.open_dialogue("Tủ chè", "Chiếc khăn thêu của Bà Minh được cất ở ngăn dưới.")
			else:
				village_panel.open_dialogue("Tủ chè", "Lá thư của ông vẫn nằm trong ngăn kéo.")
		Farmhouse.CHEST:
			if not summer.read_notebook:
				summer.read_notebook = true
				_commit_progress()
			if summer.social.minh_story == 1:
				_open_story("Sổ tay ông ngoại", "Trang về giống Thuận Thành kể chuyện ông trồng cạnh giếng và chia củ cho cả xóm.", "Nghe bố kể", _hear_dad)
			else:
				_open_story("Sổ tay ông ngoại", "Ông ghi mùa vụ và những ngày mưa. Nhấn J để mở sổ và ghi chú.", "Nghe bố kể", _hear_dad)
		Farmhouse.RADIO:
			var weather := "mưa" if progress.is_raining(progress.day + 1) else "nắng"
			var forecast := "Bản tin báo ngày mai trời %s. Sau bản tin là chương trình quan họ Bắc Ninh." % weather
			if progress.summer_story != null:
				_open_story("Radio cũ", forecast, "Nghe radio", _listen_to_story_radio, "Tắt radio", village_panel.hide)
			else:
				village_panel.open_dialogue("Radio cũ", forecast)
		Farmhouse.PIPE_SHELF:
			if progress.collect_build_material(SummerProgress.NAIL):
				_commit_progress()
				village_panel.open_dialogue("Ngăn dưới kệ", "Đã tìm thấy 2 đinh sắt để đóng khung chuồng. Xem kệ lần nữa nếu cần lấy ống.")
			elif not summer.inspected_pump:
				village_panel.open_dialogue("Kệ gỗ", "Ra sân xem chiếc máy bơm bố mang tới trước.")
			else:
				summer.found_pipes = true
				_commit_progress()
				village_panel.open_dialogue("Ống nhựa xanh", "Đã lấy 3 đoạn ống dài 2 ô và 4 đầu nối. Ra giếng để lắp vòi.")


func _listen_to_story_radio() -> void:
	progress.summer_story.mark("radio_song")
	_commit_progress()
	late_audio.play_area(&"pond")
	village_panel.open_dialogue("Radio cũ", "Tiếng nhạc từ chiếc đài cũ lẫn với tiếng mưa ngoài hiên.")


func _hear_dad() -> void:
	progress.summer.heard_dad = true
	_commit_progress()
	village_panel.open_dialogue("Bố Đức", "Hồi trẻ ông cũng từng lên Hà Nội làm công nhân. Sau lại về vì nhớ ruộng. Cái sổ này giờ con giữ nhé.")


func _open_weaving() -> void:
	var summer := progress.summer
	if progress.summer_story != null:
		if not summer.received_heirlooms:
			village_panel.open_dialogue("Cụ Hai", "Đọc thư ông rồi sang nhà cụ nhận giống trước nhé.")
			return
		if not progress.summer_story.done("reed_cut"):
			var material := progress.quantity(SummerProgress.BAMBOO)
			if material == 0 or (material < 5 and not progress.summer_story.done("bamboo_ready")):
				village_panel.open_dialogue("Cụ Hai", "Cụ từng dạy ông cháu đan trên sân này. Chặt đủ năm thân tre ở góc vườn, rồi mang lại đây thử chẻ nan.")
			else:
				if progress.summer_story.mark("bamboo_ready"):
					_commit_progress()
				workshop.open_split()
			return
		if progress.day >= SummerProgress.SOLO_DAY and summer.learned_weaving:
			_open_story("Tự đan trên sân", "Dùng trí nhớ và ba ô gợi ý. Nếu muốn thử khó hơn, có thể đan nong phơi.",
				"Tự đan rổ", _start_weaving.bind(true), "Đan nong phơi", _start_drying_mat)
			return
	if not summer.received_heirlooms or progress.quantity(SummerProgress.BAMBOO) == 0:
		village_panel.open_dialogue("Sân đan tre", "Gặp Cụ Hai ở làng và lấy tre ở góc đông bắc vườn trước.")
		return
	if progress.day >= SummerProgress.SOLO_DAY and summer.learned_weaving:
		_open_story("Sân đan tre", "Tự nhớ mẫu đáy rổ. Có thể xem lại bài của Cụ Hai nếu muốn.", "Tự đan", _start_weaving.bind(true), "Xem mẫu cụ", _start_weaving.bind(false))
	else:
		_start_weaving(false)


func _start_weaving(solo: bool) -> void:
	village_panel.hide()
	workshop.open_basket(solo)


func _finish_bamboo_split(value: int) -> void:
	if value < 20 or value > 60:
		if progress.quantity(SummerProgress.BAMBOO) > 0:
			progress._add_items(SummerProgress.BAMBOO, -1)
			_commit_progress()
		village_panel.open_dialogue("Cụ Hai", "Nan dày quá, dễ gãy." if value > 60 else "Nan mỏng quá, không chịu được sức nặng.")
		return
	progress.summer_story.mark("reed_cut")
	_commit_progress()
	_start_weaving(false)


func _start_drying_mat() -> void:
	if progress.quantity(SummerProgress.BAMBOO) < 2:
		village_panel.open_dialogue("Nong phơi", "Cần hai bó tre để đan nong.")
		return
	village_panel.hide()
	workshop.open_mat()


func _finish_drying_mat(errors: int) -> void:
	if progress.quantity(SummerProgress.BAMBOO) < 2:
		return
	progress._add_items(SummerProgress.BAMBOO, -2 if errors <= 8 else -1)
	if errors <= 8:
		progress._add_items("drying_mat", 1)
	_commit_progress()
	village_panel.open_dialogue("Nong phơi", "Nong tre đã hoàn thành." if errors <= 8 else "Nong còn lệch nan. Mất một bó tre, có thể thử lại.")


func _place_kitchen_basket() -> void:
	for item in SummerProgress.BASKETS:
		if progress.quantity(item) > 0 and progress.summer_story.mark("kitchen_basket"):
			progress._add_items(item, -1)
			farmhouse.queue_redraw()
			_commit_progress()
			village_panel.open_dialogue("Rổ ở bếp", "Hoàng đặt rổ tre cạnh bếp để đựng rau củ.")
			return
	village_panel.open_dialogue("Rổ ở bếp", "Đan một chiếc rổ rồi mang vào đây.")


func _rain_porridge() -> void:
	if progress.cook_rain_porridge():
		_commit_progress()
		village_panel.open_dialogue("Cháo gà gừng", "Đã nấu cháo từ gạo, trứng và gừng. Ngày mai, làm luống hao ít thể lực hơn.")
	else:
		village_panel.open_dialogue("Cháo gà gừng", "Cần một phần gạo, một quả trứng và một phần gừng. Gừng mọc ở mép lối vào vườn sau ngày mưa.")


func _save_field_note(note: String) -> void:
	if progress.summer != null and progress.summer.read_notebook:
		progress.summer.farm_note = note
		_save_progress()


func _basket_finished(wrong: int, solo: bool) -> void:
	var item := progress.finish_basket(wrong, solo)
	if item.is_empty():
		return
	_commit_progress()
	if progress.summer_story != null and not solo and not progress.summer_story.done("tea_hai"):
		_open_story("Cụ Hai", "Cụ lật chiếc rổ xem rồi nhắc chuyện ông ngoại học đan ngay trên sân gạch. Cụ muốn ngồi lại uống chén trà.", "Mời trà", _tea_with_hai, "Lát nữa", village_panel.hide)
	else:
		village_panel.open_dialogue("Rổ tre", "Đã đan %s. Có thể đem bán ở chợ." % SummerProgress.item_name(item).to_lower())


func _tea_with_hai() -> void:
	progress.summer_story.mark("tea_hai")
	_commit_progress()
	village_panel.open_dialogue("Chén trà ngoài sân", "Ông cháu từng trồng cà rốt, mồng tơi và chuối quanh ao. Hè tới, sân này râm mát lắm.")


func _sprinkler_finished(index: int) -> void:
	if progress.install_sprinkler(index):
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Vòi tưới", "Nước đã tới vòi. Các luống trong vùng 3 × 3 quanh vòi sẽ tự đủ ẩm.")


func _start_hatching() -> void:
	if progress.start_hatching():
		_refresh_tutorial_props()
		_commit_progress()
		village_panel.open_dialogue("Ổ trứng", "Để gà mái ấp đến ngày %d. Mang 3 bó tre nếu muốn nới chuồng." % progress.summer.hatch_day)


func _collect_summer_egg() -> void:
	if progress.collect_egg():
		_refresh_tutorial_props()
		_commit_progress()
		village_panel.open_dialogue("Chuồng gà", "Đã nhặt một quả trứng.")


func _expand_coop() -> void:
	if progress.expand_coop():
		_commit_progress()
		village_panel.open_dialogue("Chuồng gà", "Đã nới chuồng cho gà con.")
	else:
		village_panel.open_dialogue("Chuồng gà", "Cần 3 bó tre để nới chuồng.")


func _place_nesting_basket() -> void:
	if progress.place_nesting_basket():
		_rebuild_map()
		_commit_progress()
		village_panel.open_dialogue("Ổ rổ tre", "Đã đặt rổ vào chuồng. Khi nhặt trứng ở ổ này, bạn sẽ cho gà ăn luôn.")
	else:
		village_panel.open_dialogue("Chuồng gà", "Cần có một chiếc rổ tre trong túi.")


func _construction_requested() -> void:
	if not progress.build_coop():
		var message := progress.coop_materials()
		if progress.summer.coop_step == 1:
			message = "Cần 5 thể lực để dựng khung. Có thể nghỉ rồi xây tiếp."
		elif progress.summer.coop_step == 3:
			message = "Cần đủ 7 bó rơm. Tìm đống rơm phía tây chuồng."
		workshop.open_construction(progress, message)
		return
	if progress.summer.coop_step == 4:
		_rebuild_map()
	_commit_progress()
	workshop.open_construction(progress)


func _open_coop_construction() -> void:
	village_panel.hide()
	workshop.open_construction(progress)


func _collect_material(item: String, index := 0) -> void:
	if progress.collect_build_material(item, index):
		_commit_progress()
		hint.text = "%s ×%d" % [SummerProgress.item_name(item), progress.quantity(item)]
	else:
		hint.text = "Đã lấy hôm nay hoặc thiếu đồ nghề, thể lực"


func _rice_available() -> bool:
	if progress.summer_story != null and progress.day == SummerProgress.SOLO_DAY:
		return not progress.is_raining(progress.day) and progress.minute_of_day >= 900 and progress.minute_of_day < GardenCalendar.SHOP_CLOSE
	return progress.summer_available(SummerProgress.QUIET_DAY) and not progress.is_raining(progress.day) and (
		progress.minute_of_day >= 15 * 60 + 30 and progress.minute_of_day < GardenCalendar.SHOP_CLOSE
	)


func _refresh_drying_rice() -> void:
	for index in drying_sprites.size():
		var sprite := drying_sprites[index]
		sprite.visible = _rice_available()
		var turned := (progress.summer.rice_turned & (1 << index)) != 0
		if progress.summer_story != null and progress.day == SummerProgress.SOLO_DAY:
			turned = progress.summer_story.done("solo_rice_%d" % index)
		sprite.self_modulate = Color("#e9d08d") if turned else Color("#ad853e")


func _refresh_tutorial_props() -> void:
	var hen := progress.arrival.hen
	coop_sprite.frame = 8 if hen == ArrivalProgress.Hen.EGG_READY else (0 if hen == ArrivalProgress.Hen.LOCKED else 7)
	trough_sprite.frame = 2 if hen == ArrivalProgress.Hen.FED else 1
	if fence_sprite:
		fence_sprite.visible = progress.arrival.fence_index >= 0
		fence_sprite.position = _feet_position(progress.fence_cell())
	if ditch_sprite:
		ditch_sprite.modulate = Color("#85b9cf") if progress.is_flooded(GardenProgress.LOW_PLOT) else Color.WHITE


func _animate_idle(sprite: Sprite2D, interval: float) -> void:
	var animation := sprite.create_tween().set_loops()
	animation.tween_callback(sprite.set_frame.bind(1)).set_delay(interval)
	animation.tween_callback(sprite.set_frame.bind(0)).set_delay(interval)


func _dog_cell() -> Vector2i:
	return DOG_HOME if progress.arrival.dog_food == ArrivalProgress.DogFood.FED else STRAY_DOG


func _update_dog(alternate := false) -> void:
	if not is_instance_valid(dog):
		return
	var sitting := progress.arrival.dog_food == ArrivalProgress.DogFood.FED and (
		dog_walk == null or not dog_walk.is_running()
	)
	dog.frame = (2 if sitting else 0) + int(alternate)


func _move_direction() -> Vector2i:
	var horizontal := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if horizontal != 0:
		return Vector2i(horizontal, 0)
	var vertical := int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	return Vector2i(0, vertical)


func _can_walk(cell: Vector2i) -> bool:
	if progress.village_wholesale_market() and cell in SummerStory.MARKET_STALLS:
		return false
	if progress.area == GardenProgress.Area.GARDEN and progress.summer_story != null:
		if cell.x >= 20:
			return Rect2i(21, 1, 18, 10).has_point(cell) and not SummerStory.POND.has_point(cell) and _story_farm_hint(cell).is_empty()
		if not _story_farm_hint(cell).is_empty():
			return false
	if progress.area == GardenProgress.Area.STOREHOUSE:
		return cell == StorehouseMap.DOORWAY or (
			StorehouseMap.FLOOR.has_point(cell) and cell.y > StorehouseMap.FLOOR.position.y and _works_hint(cell).is_empty() and (
				not progress.summer.autumn.corner_ready() or cell not in [StorehouseMap.SIDE, StorehouseMap.SIDE + Vector2i.RIGHT]
			)
		)
	if _in_works_site():
		if not WALKABLE_AREA.has_point(cell) or not _works_hint(cell).is_empty():
			return false
		var forge := progress.area == GardenProgress.Area.FORGE
		return not BambooWorksMap.rear_wall(forge, cell) and (not forge or cell not in [BambooWorksMap.HEARTH, BambooWorksMap.ANVIL, BambooWorksMap.QUENCH])
	if not _works_hint(cell).is_empty():
		return false
	if progress.area == GardenProgress.Area.LOTUS_POND:
		return LateSummerMap.pond_walkable(cell)
	if progress.area == GardenProgress.Area.COUNTY_FAIR:
		return WALKABLE_AREA.has_point(cell) and LateSummerMap.fair_walkable(cell)
	if not _late_summer_hint(cell).is_empty() and cell != LateSummerMap.FERRY:
		return false
	if _is_drought_cell(cell) and cell != VillageSocial.PHONE:
		return false
	if _is_craft_cell(cell):
		return false
	if _in_house():
		if cell == FestivalMap.MILL and farmhouse.mill_visible():
			return false
		return farmhouse.can_walk(cell)
	if not WALKABLE_AREA.has_point(cell):
		return false
	if _is_social_cell(cell):
		return false
	if _in_festival():
		return FestivalMap.can_walk(cell) and not _is_wrestler(cell)
	if _in_district():
		return cell not in SummerMap.ATTRACTORS and cell not in SummerMap.TREES and not _district_footprint(cell)
	if _in_village():
		return not VillageMap.is_blocked(cell) and cell not in npc_cells and not _summer_cell(cell) and not _is_wrestler(cell) and (
			progress.arrival == null or cell != VillageMap.LAN_CELL
		)
	if progress.yard_open() and (progress.plot_has_weeds(cell) or cell == _dog_cell()):
		return false
	if progress.summer != null and progress.summer.chick and cell == _chick_cell():
		return false
	if _is_yard_visitor(cell):
		return false
	if _summer_cell(cell) and cell != progress.summer_sprinkler_cell():
		return false
	if progress.arrival != null and (cell in [COOP, TROUGH] or cell == progress.fence_cell()
		or (cell == COOP_EXTENSION and progress.summer.coop_step > 0)
		or (cell == FENCE_SIGN and progress.day >= ArrivalProgress.FENCE_DAY)):
		return false
	return not (HOUSE.has_point(cell) or BIN.has_point(cell) or TREE.has_point(cell))


func _move(destination: Vector2i) -> void:
	if progress.storm_active() and _outdoors_at(destination) and not progress.walk_in_storm():
		hint.text = "Đã cạn thể lực · Chờ gió dịu"
		return
	move_destination = destination
	left_step = not left_step
	player.frame_coords = Vector2i(1 if left_step else 2, _direction_row())
	step = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var pace := 0.17 if boat.visible else (0.11 if progress.summer != null and progress.summer.juice_until > progress.minute_of_day else 0.13)
	if boat.visible and left_step:
		late_audio.play_effect(&"paddle")
	step.tween_method(_set_player_position, player.position, _feet_position(destination), pace)
	step.tween_callback(_finish_step.bind(destination))


func _set_player_position(position_in_map: Vector2) -> void:
	player.position = position_in_map.round()


func _finish_step(destination: Vector2i) -> void:
	player_cell = destination
	move_destination = Vector2i(-1, -1)
	_sync_event_people()
	if progress.summer_story != null and progress.day == SummerProgress.MAI_DAY and progress.area == GardenProgress.Area.GARDEN and is_instance_valid(dog):
		if dog_walk and dog_walk.is_running():
			dog_walk.kill()
		dog_walk = dog.create_tween()
		dog_walk.tween_property(dog, "position", player.position - Vector2(facing) * 18 + Vector2(7, -3), 0.19)
	if _in_village():
		_sync_npcs()
	if _in_works_site():
		rain.visible = progress.is_raining(progress.day) and _outdoors_at(destination)
	_update_feedback()


func _feet_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE)


func _direction_row() -> int:
	match facing:
		Vector2i.LEFT:
			return 1
		Vector2i.RIGHT:
			return 2
		Vector2i.UP:
			return 3
	return 0


func _is_interactive(cell: Vector2i) -> bool:
	if progress.village_wholesale_market() and cell in SummerStory.MARKET_STALLS:
		return true
	if _in_house() and _story_tank_at(cell):
		return true
	if progress.area == GardenProgress.Area.GARDEN and not _story_farm_hint(cell).is_empty():
		return true
	if not _works_hint(cell).is_empty():
		return true
	if _in_works_site():
		return false
	if not _late_summer_hint(cell).is_empty():
		return true
	if progress.area in [GardenProgress.Area.LOTUS_POND, GardenProgress.Area.COUNTY_FAIR]:
		return false
	if _is_drought_cell(cell):
		return true
	if _is_craft_cell(cell):
		return true
	if _is_social_cell(cell):
		return true
	if _in_house():
		if cell == FestivalMap.MILL and farmhouse.mill_visible():
			return true
		return farmhouse.is_interactive(cell)
	if _in_festival():
		return FestivalMap.is_interactive(cell) or _is_wrestler(cell)
	if _is_festival_cell(cell):
		return true
	if _in_district():
		return cell == SummerMap.EXIT or cell in SummerMap.ATTRACTORS
	if _summer_cell(cell):
		return true
	if _in_village():
		return cell in [
			VillageMap.EXIT_CELL, VillageMap.SHOP_SIGN, VillageMap.ORDER_BOARD,
			VillageMap.MARKET_CELL, VillageMap.FISHING_SPOT,
		] or cell in npc_cells or (progress.arrival != null and cell == VillageMap.LAN_CELL)
	return progress.plots.has(cell) or cell == DOOR_CELL or cell == VILLAGE_GATE or BIN.has_point(cell) or (
		progress.yard_open() and cell == _dog_cell()
	) or _is_yard_visitor(cell) or _is_tutorial_yard_cell(cell)


func _is_tutorial_yard_cell(cell: Vector2i) -> bool:
	return progress.arrival != null and (cell in [COOP, TROUGH]
		or (progress.day >= ArrivalProgress.FENCE_DAY and cell == FENCE_SIGN)
		or (fence_editing and GardenProgress.FENCE_AREA.has_point(cell))
		or (progress.day >= ArrivalProgress.DRAIN_DAY and cell == DITCH))


func _is_yard_visitor(cell: Vector2i) -> bool:
	return (cell == SEED_BOX and is_instance_valid(seed_box)) or (cell == DAD_CELL and is_instance_valid(dad)) or (
		cell == CAT_CELL and is_instance_valid(cat)
	)


func _interact() -> void:
	var target := player_cell + facing
	if progress.area == GardenProgress.Area.GARDEN and not _story_farm_hint(target).is_empty():
		_interact_story_farm(target)
		return
	if _in_house() and _story_tank_at(target):
		if progress.stock_story_tank():
			_commit_progress()
			farmhouse.queue_redraw()
		village_panel.open_dialogue("Bể cá mini", "Cá bống đang bơi trong bể." if progress.summer_story.done("goby_tank") else "Ra ao vườn sau câu cá bống để thả vào bể.")
		return
	if not _works_hint(target).is_empty():
		_interact_works_site(target)
		return
	if _in_works_site():
		return
	if not _late_summer_hint(target).is_empty():
		_interact_late_summer(target)
		return
	if progress.area in [GardenProgress.Area.LOTUS_POND, GardenProgress.Area.COUNTY_FAIR]:
		return
	if _is_drought_cell(target):
		_interact_drought(target)
		return
	if _is_craft_cell(target):
		_interact_craft(target)
		return
	if _is_social_cell(target):
		_interact_social(target)
		return
	if _in_house():
		if target == FestivalMap.MILL and farmhouse.mill_visible():
			_open_mill()
			return
		_interact_house(target)
		return
	if _in_festival() or _is_festival_cell(target):
		_interact_festival(target)
		return
	if _in_district():
		_interact_district(target)
		return
	if _summer_cell(target):
		_interact_summer(target)
		return
	if _in_village():
		_interact_village(target)
		return
	if target == VILLAGE_GATE:
		if progress.can_visit_village():
			_travel(GardenProgress.Area.VILLAGE)
		return
	if target == DOOR_CELL and progress.arrival != null:
		_travel(GardenProgress.Area.HOUSE)
		return
	if progress.yard_open() and target == _dog_cell():
		_interact_dog()
		return
	if _is_yard_visitor(target):
		_interact_yard_visitor(target)
		return
	if _is_tutorial_yard_cell(target):
		_interact_tutorial_yard(target)
		return

	var tutorial_was_completed := progress.tutorial_completed
	if progress.plots.has(target):
		if progress.plot_has_weeds(target):
			if progress.cut_plot_weeds(target):
				weed_sprites[target].visible = progress.plot_has_weeds(target)
				_commit_progress()
				_play_sickle_cut(target)
				if not weed_sprites[target].visible:
					hint.text = "Đã phát cỏ · %d/%d luống" % [progress.cleared_plot_count(), GardenProgress.PLOT_CELLS.size()]
			return
		var caught_pest := progress.has_pest(target)
		var cleared_stubble := progress.plot_action(target) == PlotAction.CUT_STUBBLE
		if not progress.work_plot(target):
			return
		_update_plot(target)
		if harvest_hold >= 0.0:
			late_audio.play_effect(&"harvest")
		if cleared_stubble:
			_play_sickle_cut(target)
		if caught_pest:
			_commit_progress()
			_flash_interaction(target)
			hint.text = "Đã bắt sâu · Có thể tưới luống"
			return
	elif target == DOOR_CELL:
		_sleep()
		return
	elif BIN.has_point(target):
		if progress.load_cart():
			_commit_progress()
			_refresh_summer_cart()
			village_panel.open_dialogue("Xe thồ", "Đã chất hàng. Qua cổng bắc làng để tới chợ huyện bán cho Lão Lái Buôn.")
			return
		if progress.summer != null and progress.summer.cart_loaded:
			village_panel.open_dialogue("Xe thồ", "Hàng đang trên xe. Đưa xe qua cổng bắc làng tới chợ huyện.")
			return
		if progress.summer_available(SummerProgress.FIRST_DAY):
			village_panel.open_dialogue("Xe thồ", "Thùng chưa có hàng." if progress.tutorial_completed else "Bán bó rau muống đầu tiên ở quầy ven sông để dùng xe thồ.")
			return
		if not progress.sell_crops():
			return
	else:
		return

	_commit_progress()
	_flash_interaction(target)
	if not tutorial_was_completed and progress.tutorial_completed:
		hint.text = "60 xu! Ghé mua hạt để trồng tiếp."


func _interact_yard_visitor(target: Vector2i) -> void:
	match target:
		SEED_BOX:
			if progress.take_starter_greens():
				map_props.erase(seed_box)
				seed_box.queue_free()
				seed_box = null
				_commit_progress()
				village_panel.open_dialogue("Hạt giống đầu vụ", "Nhận 4 hạt rau muống và 2 hạt mồng tơi.\nPhím 1 chọn rau muống, phím 2 chọn mồng tơi.")
		DAD_CELL:
			if progress.receive_cat():
				map_props.erase(dad)
				dad.queue_free()
				dad = null
				_place_cat()
				_commit_progress()
				village_panel.open_dialogue("Bố Đức", "Bố mang Hoàng Thượng sang bầu bạn với con.\nNó hay ngồi đợi ở bên trái cửa nhà.")
		CAT_CELL:
			village_panel.open_dialogue("Hoàng Thượng", "Hoàng Thượng dụi đầu vào tay bạn.")


func _interact_tutorial_yard(target: Vector2i) -> void:
	var message := ""
	match target:
		COOP:
			if progress.open_coop():
				message = "Đã mở chuồng và lấy một phần thức ăn. Đổ vào máng cạnh chuồng."
			elif progress.summer_available(SummerProgress.PUMP_DAY) and progress.arrival.hen == ArrivalProgress.Hen.EGG_READY and (
				not progress.summer.chick and progress.summer.hatch_day == 0
			):
				_open_story("Một quả trứng dưới cánh", "Để gà mái ấp 5 đêm, hoặc nhặt trứng dùng như thường.", "Để gà ấp", _start_hatching, "Nhặt trứng", _collect_summer_egg)
				return
			elif progress.collect_egg():
				message = "Đã nhặt một quả trứng gà."
			elif progress.summer_available(SummerProgress.BUILD_DAY) and progress.summer.coop_step < 4:
				var days_left := progress.summer.hatch_day - progress.day
				var status_line := "Gà mái đang ấp. Còn %d đêm." % days_left if days_left > 0 else "Có thể mở rộng chuồng để có thêm chỗ."
				_open_story("Chuồng gà", status_line, "Xây chuồng", _open_coop_construction)
				return
			elif progress.summer != null and progress.summer.hatch_day > 0 and not progress.summer.expanded_coop:
				_open_story("Mở rộng chuồng", "Cần 3 bó tre để nới vách trước khi gà con nở.", "Nới chuồng", _expand_coop)
				return
			elif progress.summer.hatch_day > 0:
				var left := progress.summer.hatch_day - progress.day
				message = "Trứng sắp nở." if left == 1 else "Gà mái đang ấp · Còn %d đêm." % left
			elif progress.summer.coop_step == 4:
				message = "Chuồng cấp 2 · Máng còn thức ăn cho %d đêm." % progress.summer.feeder_days
			else:
				message = "Chuồng gà mở từ ngày 5." if progress.day < ArrivalProgress.COOP_DAY else "Gà ở trong chuồng. Xem máng ăn bên cạnh."
		TROUGH:
			if progress.summer_available(SummerProgress.SOLO_DAY) and not progress.summer.nest_basket and (
				not progress.can_feed_again() and progress.arrival.hen != ArrivalProgress.Hen.RATION
			):
				for item in SummerProgress.BASKETS:
					if progress.quantity(item) > 0:
						_open_story("Đặt rổ làm ổ", "Gà sẽ đẻ vào rổ. Lần sau có thể nhặt trứng và cho ăn cùng lúc.", "Đặt rổ", _place_nesting_basket)
						return
			if progress.feed_hen():
				message = "Máng đầy, đủ cho hai đêm." if progress.summer.coop_step == 4 else "Máng đã có thức ăn. Sáng mai quay lại nhặt trứng."
			else:
				message = _tutorial_yard_hint(target)
		FENCE_SIGN:
			fence_editing = not fence_editing
			_update_feedback()
			return
		DITCH:
			var was_flooded := progress.is_flooded(GardenProgress.LOW_PLOT)
			if progress.drain_plot():
				message = "Đã khơi rãnh. Luống thấp vẫn đủ ẩm để cây lớn đêm nay." if was_flooded else "Đã khơi rãnh thoát nước cạnh luống thấp."
			else:
				return
		_:
			if not _can_walk(target) and target != progress.fence_cell():
				return
			if not progress.change_fence(target):
				return
	_refresh_tutorial_props()
	_commit_progress()
	_flash_interaction(target)
	if not message.is_empty():
		village_panel.open_dialogue("Việc ở vườn", message)


func _interact_house(target: Vector2i) -> void:
	if not farmhouse.is_interactive(target):
		return
	var arrival := progress.arrival
	match target:
		Farmhouse.EXIT:
			_travel(GardenProgress.Area.GARDEN)
			return
		Farmhouse.TOOLS:
			arrival.tools_taken = true
		Farmhouse.CLUTTER:
			if not arrival.clear_floor():
				return
		Farmhouse.PANTRY:
			if not progress.take_dog_food():
				return
		Farmhouse.SWITCH:
			if arrival.power_on:
				return
			arrival.power_on = true
		Farmhouse.STOVE:
			if progress.summer_story != null:
				if progress.summer.parents_visited and not progress.summer.family_meal:
					_choose_family_dishes()
					return
				if progress.day == SummerProgress.RAIN_DAY:
					_open_story("Bếp ngày mưa", "Có thể nấu cháo gà gừng để ngày mai đỡ mệt khi làm vườn.", "Nấu cháo", _rain_porridge)
					return
				if progress.day == SummerProgress.SOLO_DAY and not progress.summer_story.done("kitchen_basket"):
					_open_story("Rổ ở bếp", "Có thể giữ một chiếc rổ ở bếp để đựng rau, hoặc dành cho chuồng gà.", "Đặt rổ ở bếp", _place_kitchen_basket)
					return
			if progress.day in [VillageFestival.PREP_DAY, VillageFestival.FAIR_DAY] and progress.summer.festival.contest == 0:
				_open_story("Bếp nhà", "Có thể chọn trước món để mang ra đình, hoặc nấu bữa ở nhà.", "Chọn món thi", _open_festival_prep, "Nấu ở nhà", village_panel.open_recipes)
				return
			if progress.summer.parents_visited and not progress.summer.family_meal or progress.summer.invited_hai and not progress.summer.ate_with_hai:
				_open_story("Mâm cơm ở nhà", "Nấu cơm và dùng thêm trứng, cá hoặc rau nếu trong túi có sẵn.", "Dọn cơm", _serve_story_meal,
					"Nấu chè sen", _open_lotus_recipe if progress.summer.late.lotus_done else Callable())
				return
			if progress.summer.late.lotus_done:
				_open_lotus_recipe()
				return
			if progress.summer_available(SummerProgress.QUIET_DAY):
				village_panel.open_recipes()
				return
			if arrival.cooked_meal:
				village_panel.open_dialogue("Bếp lửa", "Bạn đã học nấu bữa cơm đầu tiên.")
			else:
				village_panel.open_confirmation("Bếp lửa", "Bác Bảy để gạo và rau bên bếp. Dùng một con cá trong túi hoặc phần cá bác để sẵn để nấu cơm, kho cá và luộc rau.", "Nấu và ăn", VillagePanel.Mode.COOKING)
			return
		Farmhouse.CUPBOARD, Farmhouse.CHEST, Farmhouse.RADIO, Farmhouse.PIPE_SHELF:
			_interact_house_story(target)
			return
		Farmhouse.BED:
			if arrival.bed_ready:
				if progress.summer_available(VillageSocial.TRAINING_DAY - 1) and progress.summer.social.training_invited:
					_bedtime()
					return
				_sleep()
				return
			arrival.bed_ready = true
	farmhouse.refresh(arrival, progress.yard_open(), progress.day, progress.summer.craft)
	_commit_progress()
	_flash_interaction(target)


func _open_lotus_recipe() -> void:
	_open_story("Bếp nhà", "Chè hạt sen long nhãn cần hai đài sen. Ăn chè hồi 40 thể lực và cộng 20 thể lực cho sáng mai.",
		"Nấu chè sen", _cook_lotus_dessert, "Món khác", village_panel.open_recipes)


func _cook_lotus_dessert() -> void:
	if progress.cook_lotus_dessert():
		_commit_progress()
		village_panel.open_dialogue("Chè hạt sen long nhãn", "Hồi 40 thể lực. Sáng mai có thêm 20 thể lực.")
	else:
		village_panel.body.text = "Cần hai đài sen mới. Đầm sen có thể hái lại vào sáng hôm sau."


func _bedtime() -> void:
	var early := progress.summer.social.wake_early
	var line := "Chọn giờ thức dậy sáng mai."
	if progress.day == BambooWorks.STORM_DAY and progress.summer.works.repair_step > 0 and (
		(progress.summer.works.protection & BambooWorks.YARD_TARPS) != BambooWorks.YARD_TARPS
	):
		line = "Kho còn thiếu bạt che. Nếu ngủ lúc này, giá đơn sẽ giảm 30%."
	_open_story("Đi ngủ", line, "Dậy %s" % ("05:00" if early else "06:00"), _sleep_at.bind(early),
		"Dậy %s" % ("06:00" if early else "05:00"), _sleep_at.bind(not early))


func _sleep_at(early: bool) -> void:
	progress.summer.social.wake_early = early
	village_panel.hide()
	_sleep()


func _sleep() -> void:
	if progress.festival_day() and progress.summer.festival.contest == 1:
		progress.minute_of_day = maxi(progress.minute_of_day, progress.summer.festival.judging_minute)
		progress.collect_festival_result()
	if not progress.advance_day():
		return
	clock_elapsed = 0.0
	_sync_storm_status()
	_update_weather()
	if _in_house():
		farmhouse.refresh(progress.arrival, progress.yard_open(), progress.day, progress.summer.craft)
	else:
		for cell in GardenProgress.PLOT_CELLS:
			_update_plot(cell)
	_commit_progress()
	_flash_interaction(player_cell + facing)
	if progress.summer_story != null and progress.day == SummerProgress.FAMILY_DAY:
		village_panel.open_dialogue("Tin nhắn của mẹ", "Trưa nay bố mẹ ghé lúc 11:30. Nếu có trứng, rau hoặc cá thì giữ lại để trưa cả nhà nấu cơm nhé.")
	elif progress.day == VillageFestival.NOTICE_DAY and progress.summer != null:
		hint.text = "Ngày 30 có hội làng · Xem cổng đình"
	elif progress.day == VillageSocial.AFTER_FAIR_DAY and progress.summer != null:
		hint.text = "Sáng sau hội · Thể lực 70/%d" % progress.stamina_cap()
	elif progress.summer_available(DroughtProgress.RAIN) and progress.day == DroughtProgress.RAIN:
		hint.text = "Mưa rồi."


func _interact_dog() -> void:
	if progress.feed_dog():
		dog_walk = dog.create_tween()
		var turn := _feet_position(Vector2i(DOG_HOME.x, STRAY_DOG.y))
		dog_walk.tween_method(_set_dog_position, dog.position, turn, 0.38)
		dog_walk.tween_method(_set_dog_position, turn, _feet_position(DOG_HOME), 0.28)
		_commit_progress()
		_flash_interaction(STRAY_DOG)
		hint.text = "Cậu Vàng đã ở lại sân"
	elif progress.arrival.dog_food == ArrivalProgress.DogFood.PANTRY:
		hint.text = "Tìm gói thức ăn trên kệ trong nhà"
	else:
		hint.text = "Cậu Vàng vẫy đuôi chào bạn"


func _set_dog_position(position_in_map: Vector2) -> void:
	if is_instance_valid(dog):
		dog.position = position_in_map.round()


func _play_sickle_cut(target: Vector2i) -> void:
	if cut_animation and cut_animation.is_running():
		cut_animation.kill()
	sickle_cut.position = _feet_position(target) - Vector2(0, 16)
	sickle_cut.frame = 0
	sickle_cut.show()
	cut_animation = create_tween()
	cut_animation.tween_property(sickle_cut, "frame", 2, 0.23)
	cut_animation.tween_callback(sickle_cut.hide).set_delay(0.08)


func _in_village() -> bool:
	return progress.area == GardenProgress.Area.VILLAGE


func _in_house() -> bool:
	return progress.area == GardenProgress.Area.HOUSE


func _in_district() -> bool:
	return progress.area == GardenProgress.Area.DISTRICT


func _in_festival() -> bool:
	return progress.area == GardenProgress.Area.FESTIVAL


func _is_festival_cell(cell: Vector2i) -> bool:
	if _in_village():
		return _is_wrestler(cell) or (
			cell == FestivalMap.GATE and progress.summer_available(VillageFestival.NOTICE_DAY) and progress.day <= VillageFestival.FAIR_DAY
		)
	if progress.area != GardenProgress.Area.GARDEN or progress.summer == null:
		return false
	return (cell == _chick_cell() and progress.summer.chick) or (
		cell in FestivalMap.FORAGE and progress.day in [VillageFestival.PREP_DAY, VillageFestival.FAIR_DAY]
	)


func _chick_cell() -> Vector2i:
	return TROUGH + Vector2i(1, -2) if progress.summer.festival.chick_joined else FestivalMap.CHICK


func _is_wrestler(cell: Vector2i) -> bool:
	if progress.summer == null or not progress.summer.festival.wrestling:
		return false
	return (cell == Vector2i(12, 4) and _in_festival()) or (
		cell == FestivalMap.THANG and _in_village() and progress.day > VillageFestival.FAIR_DAY
	)


func _festival_hint(cell: Vector2i) -> String:
	if _is_wrestler(cell):
		return "E · Nói với Chú Thắng"
	match cell:
		FestivalMap.EXIT: return "E · Về làng"
		FestivalMap.GATE: return "E · Xem hội làng"
		FestivalMap.KITCHEN: return "E · Thi nấu ăn"
		FestivalMap.WRESTLING: return "E · Đấu vật"
		FestivalMap.SIGNUP: return "E · Gặp Trưởng thôn"
		FestivalMap.LANTERN: return "E · Thả đèn sông Cầu"
	if not _in_festival() and not _in_village() and progress.summer.chick and cell == _chick_cell():
		return "E · Thăm gà con"
	if _in_festival():
		return "J · Lịch hội làng"
	return "E · Hái nguyên liệu"


func _interact_festival(cell: Vector2i) -> void:
	if _is_wrestler(cell):
		if _in_village():
			_talk_thang()
			return
		progress.summer.festival.wrestler_met = true
		_commit_progress()
		village_panel.open_dialogue("Chú Thắng", "Cháu trụ vững cả ba hiệp. Hôm nào rảnh chú chỉ thêm cách lấy thế.")
		return
	if _in_village():
		if progress.festival_day() and progress.minute_of_day >= VillageFestival.OPEN:
			_travel(GardenProgress.Area.FESTIVAL)
		else:
			_festival_signup()
		return
	if not _in_festival():
		if progress.summer.chick and cell == _chick_cell():
			_open_chick_menu()
		else:
			var index := FestivalMap.FORAGE.find(cell)
			if progress.forage_festival(index):
				_rebuild_map()
				_commit_progress()
				var item: String = [VillageFestival.MUNG, VillageFestival.GINGER, VillageFestival.SNAIL, VillageFestival.MUSHROOM][index]
				hint.text = "Đã lấy " + VillageFestival.item_name(item).to_lower()
		return
	match cell:
		FestivalMap.EXIT:
			_travel(GardenProgress.Area.VILLAGE)
		FestivalMap.SIGNUP:
			_festival_signup()
		FestivalMap.KITCHEN:
			_festival_kitchen()
		FestivalMap.WRESTLING:
			if progress.minute_of_day >= VillageFestival.CLOSE:
				village_panel.open_dialogue("Sới vật", "Sới đã đóng. Hoa đăng thả từ 19:00.")
			else:
				festival_panel.open_wrestling()
		FestivalMap.LANTERN:
			if progress.release_lantern():
				_commit_progress()
				lantern_tween = create_tween()
				lantern_tween.tween_method(_move_lantern, 0.0, 51.0, 5.0)
				lantern_tween.tween_callback(func() -> void:
					if _in_festival():
						village_panel.open_dialogue("Chị Lan", "Ông ngoại anh năm nào cũng thả đèn chỗ này.")
				)
			elif progress.minute_of_day < VillageFestival.LANTERN_HOUR:
				village_panel.open_dialogue("Bến thả đèn", "Mọi người sẽ thả đèn lúc 19:00.")


func _festival_signup() -> void:
	if progress.summer.festival.registered:
		village_panel.open_dialogue("Trưởng thôn", "Đã ghi tên cháu. Hội ngày 30, từ 08:00. Buổi tối ra sông thả đèn.")
	else:
		_open_story("Hội làng đình hè", "Hội mở ngày 30 lúc 08:00. Có thi nấu ăn, đấu vật và thả đèn lúc 19:00.", "Ghi tên", _register_festival)


func _register_festival() -> void:
	progress.summer.festival.registered = true
	_commit_progress()
	_festival_signup()


func _festival_kitchen() -> void:
	var fair := progress.summer.festival
	if fair.contest == 0:
		if progress.minute_of_day < VillageFestival.CLOSE:
			festival_panel.open_cooking(fair.prepared_dish, true)
		else:
			village_panel.open_dialogue("Bếp hội", "Đã hết giờ nộp món.")
	elif fair.contest == 1 and not progress.collect_festival_result():
		village_panel.open_dialogue("Bếp hội", "Ban giám khảo đang thử món. Quay lại lúc %s." % GardenCalendar.format_time(fair.judging_minute))
	else:
		_commit_progress()
		var award := "Bàn Tay Vàng" if fair.contest_score >= 90 else ("Món được khen" if fair.contest_score >= 75 else "Đã dự thi")
		village_panel.open_dialogue("Ban giám khảo", "%s · %d điểm. Cảm ơn cháu đã góp món cho hội." % [award, fair.contest_score])


func _dish_chosen(dish: int, plating: int) -> void:
	var success := progress.prepare_festival_dish(dish) if plating == -1 else progress.submit_festival_dish(dish, plating)
	if not success:
		festival_panel.instructions.text = "Chưa đủ nguyên liệu cho món này."
		return
	festival_panel.hide()
	_commit_progress()
	if plating == -1:
		village_panel.open_dialogue("Bếp nhà", "Đã chọn %s. Giữ nguyên liệu trong túi tới ngày hội." % VillageFestival.DISH_NAMES[dish].to_lower())
	else:
		_festival_kitchen()


func _wrestling_finished(wins: int) -> void:
	progress.summer.social.wrestled = true
	if progress.finish_wrestling(wins):
		_rebuild_map()
	_commit_progress()
	var line := "Thắng %d/3 hiệp. Cả sân vỗ tay." % wins
	if wins == 3:
		line += " Chú Thắng đang đứng cạnh sới."
	village_panel.open_dialogue("Sới vật", line)


func _open_mill() -> void:
	if progress.summer.chick and not progress.summer.festival.chick_joined and progress.summer.festival.mill_day != progress.day:
		festival_panel.open_mill()
	else:
		village_panel.open_dialogue("Cối đá", "Dùng cối để giã cám mịn khi chăm gà con.")


func _mill_done() -> void:
	if progress.grind_bran():
		_commit_progress()
		village_panel.open_dialogue("Cối đá", "Đã giã hai phần cám mịn.")
	else:
		village_panel.open_dialogue("Cối đá", "Cần 3 thể lực để giã cám.")


func _name_chick(value: String) -> void:
	if progress.name_chick(value):
		_commit_progress()
		_open_chick_menu()


func _open_chick_menu() -> void:
	var fair := progress.summer.festival
	var name := fair.chick_named if not fair.chick_named.is_empty() else "Gà con"
	if fair.chick_joined:
		village_panel.open_dialogue(name, "Gà con chạy theo gà mái ra sân bới đất.")
		return
	if not fair.chick_seen_hai:
		fair.chick_seen_hai = true
		_commit_progress()
		_open_story("Cụ Hai ghé chuồng", "Gà con nở rồi. Cụ Hai dặn giã cám mịn ở cối đá và giữ ổ ấm ba đêm đầu.", "Xem ổ", _open_chick_menu)
		return
	var warm := fair.chick_divider or fair.chick_straw or (progress.summer.expanded_coop and not progress.is_raining(progress.day))
	var body := "Đã chăm đủ %d/3 đêm · %s.\n%s." % [
		fair.chick_age, "Đã cho ăn" if fair.chick_fed else "Chưa có cám hôm nay",
		"Ổ đủ ấm" if warm else "Ổ hơi lạnh",
	]
	var next := "feed"
	var button := "Cho ăn"
	if fair.chick_age == 3:
		next = "join"
		button = "Cho nhập đàn"
	elif not fair.chick_divider and progress.quantity(SummerProgress.BAMBOO) >= 2:
		next = "divide"
		button = "Đặt vách tre"
	elif not fair.chick_straw and not fair.chick_divider and progress.quantity(SummerProgress.STRAW) > 0:
		next = "straw"
		button = "Lót rơm"
	elif fair.chick_fed and fair.chick_age >= 1 and fair.chick_play_day != progress.day:
		next = "play"
		button = "Thả sâu"
	_open_story(name, body, button, _chick_action.bind(next), "Đặt tên", _open_chick_name)


func _open_chick_name() -> void:
	village_panel.hide()
	festival_panel.open_name(progress.summer.festival.chick_named)


func _open_festival_prep() -> void:
	village_panel.hide()
	festival_panel.open_cooking(progress.summer.festival.prepared_dish, false)


func _chick_action(action: String) -> void:
	if action == "play":
		var fair := progress.summer.festival
		if fair.chick_play_day == progress.day:
			return
		fair.chick_play_day = progress.day
		_commit_progress()
		_flash_interaction(FestivalMap.CHICK)
		village_panel.open_dialogue("Gà con", "Gà con chạy mấy vòng theo con sâu rồi nép lại bên mẹ.")
	elif progress.care_for_chick(action):
		_rebuild_map()
		_commit_progress()
		_open_chick_menu()
	else:
		village_panel.open_dialogue("Gà con", "Giã cám mịn ở cối đá trong nhà. Dùng tre ngăn chuồng hoặc lót rơm để giữ ấm.")


func _place_festival() -> void:
	_place_building(preload("res://assets/art/32/village_stall.png"), FestivalMap.TEMPLE, 1, 0)
	for cell in FestivalMap.FOREST:
		_add_prop(preload("res://assets/art/32/props.png"), _feet_position(cell), 64, 3, 2)
	_summer_prop(FestivalMap.EXIT, 10)
	_add_prop(FESTIVAL_ART, _feet_position(FestivalMap.KITCHEN), TILE_SIZE, 6, 0)
	_add_prop(FESTIVAL_ART, _feet_position(FestivalMap.LANTERN), TILE_SIZE, 6, 3)
	for cell in FestivalMap.FLAGS:
		_add_prop(FESTIVAL_ART, _feet_position(cell), TILE_SIZE, 6, 1)
	_summer_person(FestivalMap.SIGNUP, 1)
	_summer_person(Vector2i(15, 8), 0, Color("#edd4a1"))
	if progress.summer.festival.wrestling:
		_summer_person(Vector2i(12, 4), 1, Color("#f0bd83"))


func _draw_light(point: Vector2, color: Color) -> void:
	overlay.draw_texture_rect_region(FESTIVAL_ART, Rect2(point - Vector2(8, 10), Vector2(24, 24)), Rect2(64, 0, 32, 32), color)


func _draw_festival() -> void:
	var ring := _feet_position(FestivalMap.WRESTLING) + Vector2(0, -15)
	overlay.draw_arc(ring, 31, 0, TAU, 24, Color("#aa6954"), 3)
	for cell in FestivalMap.LIGHTS:
		_draw_light(Vector2(cell * TILE_SIZE) + Vector2(12, 9), Color("#c3503d"))
	if progress.minute_of_day >= VillageFestival.LANTERN_HOUR:
		for index in 9:
			var point := Vector2(516 + (index * 23) % 109, 42 + index * 33)
			overlay.draw_texture_rect_region(FESTIVAL_ART, Rect2(point, Vector2(24, 24)), Rect2(96, 0, 32, 32))
		if progress.summer.festival.lantern:
			var point := _feet_position(FestivalMap.LANTERN) + Vector2(lantern_offset, lantern_offset / 2 - 10)
			overlay.draw_texture_rect_region(FESTIVAL_ART, Rect2(point, Vector2(28, 28)), Rect2(96, 0, 32, 32))


func _move_lantern(offset: float) -> void:
	lantern_offset = offset
	overlay.queue_redraw()


func _travel(area: GardenProgress.Area) -> void:
	var previous := progress.area
	var leaving_house := _in_house()
	var leaving_district := _in_district()
	var leaving_festival := _in_festival()
	progress.area = area
	if area == GardenProgress.Area.LOTUS_POND:
		player_cell = LateSummerMap.POND_SPAWN
		facing = Vector2i.RIGHT
	elif area == GardenProgress.Area.COUNTY_FAIR:
		player_cell = SummerMap.EXIT + Vector2i.RIGHT
		facing = Vector2i.RIGHT
	elif _in_works_site():
		player_cell = BambooWorksMap.SPAWN
		facing = Vector2i.RIGHT
	elif _in_festival():
		player_cell = FestivalMap.EXIT + Vector2i.RIGHT
		facing = Vector2i.RIGHT
	elif _in_district():
		progress.summer.visited_market = true
		player_cell = SummerMap.EXIT + Vector2i.RIGHT
		facing = Vector2i.RIGHT
	elif _in_village():
		player_cell = SummerMap.GATE + Vector2i.DOWN if leaving_district else VillageMap.EXIT_CELL + Vector2i.RIGHT
		if leaving_festival:
			player_cell = FestivalMap.GATE + Vector2i.DOWN
		facing = Vector2i.DOWN if leaving_district else Vector2i.RIGHT
		if previous == GardenProgress.Area.LOTUS_POND:
			player_cell = LateSummerMap.POND_GATE + Vector2i.DOWN
			facing = Vector2i.UP
		elif previous == GardenProgress.Area.COUNTY_FAIR:
			player_cell = LateSummerMap.FERRY + Vector2i.LEFT
		elif previous == GardenProgress.Area.FORGE:
			player_cell = BambooWorksMap.FORGE_GATE + Vector2i.DOWN
			facing = Vector2i.UP
		elif previous == GardenProgress.Area.BAMBOO_WORKS:
			player_cell = BambooWorksMap.WORKS_GATE + Vector2i.UP
			facing = Vector2i.DOWN
	elif _in_house():
		player_cell = Farmhouse.ENTRANCE
		facing = Vector2i.UP
	elif previous == GardenProgress.Area.STOREHOUSE:
		player_cell = StorehouseMap.ENTRY + Vector2i.DOWN
		facing = Vector2i.UP
	elif leaving_house:
		player_cell = DOOR_CELL + Vector2i.DOWN
		facing = Vector2i.DOWN
	else:
		player_cell = VILLAGE_GATE + Vector2i.LEFT
		facing = Vector2i.LEFT
	_rebuild_map()
	_update_weather()
	_commit_progress()


func _interact_village(target: Vector2i) -> void:
	if progress.village_wholesale_market():
		match target:
			VillageMap.MARKET_CELL:
				village_panel.open_wholesale(progress, "Chợ làng · Chọn hàng và số lượng. Giá đổi theo ngày.")
				return
			VillageMap.ORDER_BOARD:
				if progress.summer_story.order < 2:
					_open_local_order()
					return
			SummerStory.CLOTHES:
				_open_local_stock("Tiệm đồ si Bà Tám", "work_shirt")
				return
			SummerStory.DECOR:
				_open_local_stock("Đồ kiểng chợ làng", "tank")
				return
			SummerStory.CARPENTER:
				_open_story("Sạp bác thợ mộc", "Bác có dụng cụ, đinh và bản vẽ.", "Xem dụng cụ", village_panel.open_supplies.bind(progress),
					"Xem bản vẽ", _open_local_stock.bind("Bản vẽ", "coop_plan", "dog_plan"))
				return
	if target == VillageMap.EXIT_CELL:
		_travel(GardenProgress.Area.GARDEN)
	elif target == VillageMap.SHOP_SIGN:
		if GardenCalendar.shop_is_open(progress.minute_of_day):
			if progress.village_wholesale_market():
				_open_story("Cô Lan Tạp Hóa", "Có giống ngô, rau dền, bí ngô và đồ dùng làm vườn.", "Mua giống", _open_local_seeds,
					"Xem đồ dùng", _open_local_stock.bind("Cô Lan Tạp Hóa", "backpack", "spray"))
			else:
				farm_panel.open(FarmPanel.Mode.SHOP, progress)
	elif target == VillageMap.ORDER_BOARD:
		if progress.arrival != null and progress.day < ArrivalProgress.BOARD_DAY:
			village_panel.open_dialogue("Bảng cáo thị", "Bảng đơn mở từ ngày 11.\n← Về vườn · → Ra bến sông Cầu")
		else:
			village_panel.open_order(progress)
	elif target == VillageMap.FISHING_SPOT:
		if (progress.arrival == null or progress.day >= ArrivalProgress.FISHING_DAY) and progress.minute_of_day < GardenCalendar.LAST_MINUTE:
			fishing_panel.cast(progress.fishing_species())
	elif target == VillageMap.MARKET_CELL:
		if progress.produce_stall_open():
			village_panel.open_produce(progress)
		elif progress.market_open():
			village_panel.open_market(progress)
		elif progress.arrival != null:
			village_panel.open_dialogue("Chợ ven sông", "Quầy rau mở hằng ngày %s từ ngày %d.\nChợ phiên vào Chủ nhật từ ngày %d." % [
				GardenCalendar.shop_hours(), ArrivalProgress.PRODUCE_DAY, ArrivalProgress.FAIR_DAY,
			])
		else:
			village_panel.open_dialogue(MarketOrder.TITLE, "Chợ mở Chủ nhật, ngày %d · %s.\nGiữ 3 cây cải để giao tại quầy." % [
				GardenCalendar.next_market_day(progress.day, progress.minute_of_day), GardenCalendar.market_hours(),
			])
	elif target == VillageMap.LAN_CELL and progress.arrival != null:
		if progress.meet_lan():
			_commit_progress()
			village_panel.open_dialogue("Chị Lan", "Hoàng về rồi à? Chị gửi em một chiếc bánh đa.\nChợ ở phía đông quảng trường. Qua chợ, rẽ xuống là tới bến sông Cầu.")
		else:
			village_panel.open_dialogue("Chị Lan", "Qua quảng trường là quầy chợ.\nĐường về vườn ở phía tây, ngay chỗ em vừa vào.")
	else:
		var index := npc_cells.find(target)
		if index >= 0:
			village_panel.open_villager(VillagerCatalog.IDS[index], VillageMap.npc_dialogue(index, progress), progress)


func _open_local_seeds() -> void:
	village_panel.hide()
	farm_panel.open(FarmPanel.Mode.SHOP, progress)


func _open_local_stock(title: String, item: String, second := "") -> void:
	var offer: Array = SummerStory.STOCK[item]
	var label := "%s · %d xu" % [offer[0], offer[1]]
	var other := ""
	var alternative := Callable()
	if not second.is_empty():
		other = "%s · %d xu" % [SummerStory.STOCK[second][0], SummerStory.STOCK[second][1]]
		alternative = _buy_local_stock.bind(title, second)
	if item == "work_shirt" and progress.summer_story.purchases.has(item):
		_open_story(title, "Hoàng đã có áo làm vườn màu tím than.", "Đổi áo", _toggle_work_shirt)
		return
	_open_story(title, "Chọn món muốn mua. Sạp mở từ %s." % GardenCalendar.shop_hours(), label, _buy_local_stock.bind(title, item), other, alternative)


func _buy_local_stock(title: String, item: String) -> void:
	if not progress.buy_story_stock(item):
		village_panel.open_dialogue(title, "Kiểm tra giờ mở chợ, số xu và món đã mua.")
		return
	if item == "work_shirt":
		_apply_work_shirt()
	_commit_progress()
	village_panel.open_dialogue(title, "Đã mua %s." % str(SummerStory.STOCK[item][0]).to_lower())


func _toggle_work_shirt() -> void:
	progress.summer_story.wearing_shirt = not progress.summer_story.wearing_shirt
	_apply_work_shirt()
	_commit_progress()
	village_panel.hide()


func _apply_work_shirt() -> void:
	var original := preload("res://assets/art/32/hoang.png")
	if progress.summer_story == null or not progress.summer_story.wearing_shirt:
		player.texture = original
		return
	if story_shirt_texture == null:
		var image := original.get_image()
		var palette := {Color("344852").to_rgba32(): Color("413c53"), Color("3e6170").to_rgba32(): Color("574864"),
			Color("507f87").to_rgba32(): Color("766486"), Color("73a1a0").to_rgba32(): Color("9280a0")}
		for y in image.get_height():
			for x in image.get_width():
				var ink := image.get_pixel(x, y).to_rgba32()
				if palette.has(ink):
					image.set_pixel(x, y, palette[ink])
		story_shirt_texture = ImageTexture.create_from_image(image)
	player.texture = story_shirt_texture


func _open_local_order() -> void:
	var accepted := progress.summer_story.order == 1
	var body := "Trưởng thôn cần 5 bó rau dền và 2 cá bống cho mâm cơm khách. Thưởng gấp ba giá Lão Lái Buôn."
	if accepted:
		body += "\nTrong túi: rau dền %d/5 · cá bống %d/2." % [progress.quantity("amaranth"), progress.quantity(FishCatalog.GOBY)]
	_open_story("Đơn của Trưởng thôn", body, "Giao hàng" if accepted else "Nhận đơn", _submit_local_order,
		"Đơn khác", village_panel.open_order.bind(progress))


func _submit_local_order() -> void:
	if not progress.story_order():
		_open_local_order()
		return
	_commit_progress()
	if progress.summer_story.order == 2:
		village_panel.open_dialogue("Đơn của Trưởng thôn", "Đủ rau dền và cá bống cho mâm cơm khách. Đã nhận tiền thưởng.")
	else:
		_open_local_order()


func _on_village_action() -> void:
	match village_panel.mode:
		VillagePanel.Mode.INVEST:
			if progress.invest_in_autumn(village_panel.gift_picker.selected):
				_commit_progress()
				village_panel.open_autumn_ledger(progress, "Đã ghi khoản đầu tư vào sổ.")
			else:
				village_panel.open_autumn_ledger(progress, "Xem số xu và các khoản đã đăng ký.")
		VillagePanel.Mode.WAREHOUSE:
			if progress.warehouse_move(village_panel.selected_item(), int(village_panel.sale_quantity.value), village_panel.warehouse_put):
				_commit_progress()
				village_panel.open_warehouse(progress, village_panel.warehouse_put)
		VillagePanel.Mode.FINE_WEAVE:
			var product := village_panel.gift_picker.selected
			if progress.can_weave_fine(product):
				village_panel.hide()
				fine_weave_panel.open(product)
		VillagePanel.Mode.BAMBOO_MACHINE:
			if progress.queue_bamboo_batch(village_panel.gift_picker.selected, int(village_panel.sale_quantity.value)):
				_commit_progress()
				village_panel.refresh_bamboo_machine()
				late_audio.play_effect(&"splitter")
		VillagePanel.Mode.BAMBOO_ORDER:
			if progress.manage_workshop_order() > 0:
				_commit_progress()
				village_panel.open_bamboo_order(progress)
		VillagePanel.Mode.CARGO:
			var packed := progress.pack_harvest(village_panel.selected_item())
			if packed:
				_commit_progress()
			village_panel.open_cargo(progress, "Đã xếp mặt hàng." if packed else "Sọt đã đầy hoặc túi hết hàng.")
		VillagePanel.Mode.COUNTY_SALE:
			_sell_county_cargo(false)
		VillagePanel.Mode.AUTUMN_SEEDS:
			var bought := progress.buy_autumn_seed(village_panel.selected_item())
			if bought:
				_commit_progress()
			village_panel.open_autumn_seeds(progress, "Đã mua một hạt." if bought else "Chưa mua được. Xem lại số xu.")
		VillagePanel.Mode.DROUGHT_SHOP:
			var bought := progress.buy_drought_supply(village_panel.selected_item())
			if bought:
				_commit_progress()
			village_panel.open_drought_shop(progress, "Đã nhận vật tư." if bought else "Chưa mua được. Xem số xu và giờ bán.")
		VillagePanel.Mode.CRAFT_SHOP:
			var bought := progress.buy_craft_supply(village_panel.selected_item())
			if bought:
				_commit_progress()
			village_panel.open_craft_shop(progress, "Đã mua." if bought else "Chưa đủ xu hoặc sạp đã đóng.")
		VillagePanel.Mode.SCARF_ORDER:
			if progress.embroidery_order_action():
				_commit_progress()
				village_panel.open_scarf_order(progress)
		VillagePanel.Mode.EGG_ORDER:
			if progress.egg_order_action():
				_commit_progress()
				village_panel.open_egg_order(progress)
		VillagePanel.Mode.STORY:
			if story_action.is_valid():
				story_action.call()
		VillagePanel.Mode.RECIPES:
			var recipe := village_panel.gift_picker.selected
			if progress.cook_quiet_meal(recipe):
				_commit_progress()
				village_panel.open_dialogue("Bếp nhà", "Đã ăn %s và hồi thể lực." % VillagePanel.RECIPE_NAMES[recipe].to_lower())
			else:
				village_panel.body.text = "Chưa đủ nguyên liệu cho món này. Chọn món khác hoặc pha trà."
		VillagePanel.Mode.WHOLESALE:
			var item := village_panel.selected_item()
			var count := int(village_panel.sale_quantity.value)
			var price := progress.wholesale_price(item)
			if progress.sell_wholesale(item, count):
				_commit_progress()
				_refresh_summer_cart()
				village_panel.open_wholesale(progress, "Đã bán %d %s · +%d xu." % [count, progress.item_label(item).to_lower(), count * price])
		VillagePanel.Mode.SUPPLY:
			var bought := progress.buy_market_supply(village_panel.selected_item())
			if bought:
				_commit_progress()
			village_panel.open_supplies(progress, "Đã mua." if bought else "Chưa đủ xu.")
		VillagePanel.Mode.SUMMER_ORDER:
			if progress.advance_neighbor_order():
				_commit_progress()
				village_panel.open_summer_order(progress)
		VillagePanel.Mode.PRODUCE:
			var crop_id := village_panel.selected_item()
			var count := int(village_panel.sale_quantity.value)
			var was_complete := progress.tutorial_completed
			if progress.sell_produce(crop_id, count):
				var crop: Dictionary = CropCatalog.CROPS[crop_id]
				var message := "Đã bán %d %s · +%d xu." % [count, crop.name.to_lower(), count * int(crop.sell_price)]
				if not was_complete and progress.tutorial_completed:
					message += "\nĐã hoàn thành hướng dẫn! "
					message += "Có thể dùng thùng bán ở vườn." if progress.bin_open() else "Thùng bán mở từ ngày 11."
				_commit_progress()
				village_panel.open_produce(progress, message, crop_id)
			else:
				village_panel.open_produce(progress, "Không thể bán số lượng đã chọn.", crop_id)
		VillagePanel.Mode.COOKING:
			if progress.cook_meal():
				_commit_progress()
				village_panel.open_dialogue("Bữa cơm đầu tiên", "Cơm, cá kho và rau luộc đã sẵn sàng.\nBạn đã ăn và sẽ có thêm 20 thể lực vào sáng mai.")
		VillagePanel.Mode.MARKET:
			if progress.deliver_market_order():
				_commit_progress()
				village_panel.refresh_market(progress)
		VillagePanel.Mode.VILLAGE_ORDER:
			if progress.advance_order():
				_commit_progress()
				village_panel.refresh_order(progress)
		VillagePanel.Mode.FISH_ORDER:
			if progress.advance_fish_order():
				_commit_progress()
				village_panel.refresh_fish_order(progress)
		VillagePanel.Mode.VILLAGER:
			village_panel.open_gifts(progress)
		VillagePanel.Mode.GIFT:
			_give_selected_gift()


func _switch_order() -> void:
	match village_panel.mode:
		VillagePanel.Mode.WAREHOUSE:
			village_panel.open_warehouse(progress, not village_panel.warehouse_put)
		VillagePanel.Mode.BAMBOO_ORDER:
			if progress.manage_workshop_order(true) > 0:
				_commit_progress()
				_rebuild_map()
				village_panel.open_bamboo_order(progress)
		VillagePanel.Mode.BAMBOO_MACHINE:
			if progress.collect_bamboo_products():
				_commit_progress()
				village_panel.refresh_bamboo_machine()
				late_audio.play_effect(&"tarp")
		VillagePanel.Mode.CARGO:
			if progress.unpack_harvest():
				_commit_progress()
			village_panel.open_cargo(progress, "Đã dỡ hàng vào túi.")
		VillagePanel.Mode.COUNTY_SALE:
			_sell_county_cargo(true)
		VillagePanel.Mode.RECIPES:
			if progress.drink_tea():
				_commit_progress()
				village_panel.open_dialogue("Trà xanh", "Một ấm trà bên hiên. Hồi 5 thể lực.")
			else:
				village_panel.body.text = "Bạn đã uống trà hôm nay hoặc đang đầy thể lực."
		VillagePanel.Mode.STORY:
			if alternative_story_action.is_valid():
				alternative_story_action.call()
		VillagePanel.Mode.WHOLESALE:
			village_panel.sale_quantity.value = village_panel.sale_quantity.max_value
		VillagePanel.Mode.PRODUCE:
			if progress.market_open():
				village_panel.open_market(progress)
		VillagePanel.Mode.MARKET:
			if progress.produce_stall_open():
				village_panel.open_produce(progress)
		VillagePanel.Mode.FISH_ORDER:
			village_panel.open_order(progress)
		VillagePanel.Mode.VILLAGE_ORDER:
			if progress.summer_available(SummerProgress.WEAVE_DAY):
				village_panel.open_summer_order(progress)
			else:
				village_panel.open_fish_order(progress)
		VillagePanel.Mode.SUMMER_ORDER:
			if progress.summer_available(VillageFestival.ORDER_DAY):
				village_panel.open_egg_order(progress)
			else:
				village_panel.open_fish_order(progress)
		VillagePanel.Mode.EGG_ORDER:
			if progress.summer_available(SummerCraft.ORDER_DAY) and progress.summer.craft.embroidery:
				village_panel.open_scarf_order(progress)
			else:
				village_panel.open_fish_order(progress)
		VillagePanel.Mode.SCARF_ORDER:
			village_panel.open_fish_order(progress)
		VillagePanel.Mode.GIFT:
			village_panel.open_villager(village_panel.villager_id, village_panel.villager_line, progress)
		VillagePanel.Mode.VILLAGER:
			var id := village_panel.villager_id
			if progress.view_villager_event(id):
				_commit_progress()
				var villager: Dictionary = VillagerCatalog.VILLAGERS[id]
				village_panel.open_dialogue(villager.event_title, villager.event)


func _sell_county_cargo(all_goods: bool) -> void:
	var earned := 0
	var was_unlocked := progress.summer.late.seeds_unlocked()
	var goods := LateSummer.GOODS if all_goods else [village_panel.selected_item()]
	for item in goods:
		earned += progress.sell_county_goods(item)
	if earned > 0:
		_commit_progress()
	var line := "Bán được %d xu." % earned if earned > 0 else "Sọt chưa có mặt hàng này."
	if not was_unlocked and progress.summer.late.seeds_unlocked():
		line += " Đã mở sạp hạt vụ thu."
	village_panel.open_county_sale(progress, line)


func _give_selected_gift() -> void:
	var id := village_panel.villager_id
	var item_id := village_panel.selected_item()
	var points := progress.give_gift(id, item_id)
	if points == 0:
		return
	_commit_progress()
	var villager: Dictionary = VillagerCatalog.VILLAGERS[id]
	var line: String = villager.favorite_thanks if item_id == villager.favorite else villager.thanks
	village_panel.open_villager(id, "%s\n+%d thân thiết" % [line, points], progress)


func _switch_inventory() -> void:
	var view := FarmPanel.Mode.BAG if farm_panel.mode == FarmPanel.Mode.FISH else FarmPanel.Mode.FISH
	farm_panel.open(view, progress)


func _on_cast_finished(species: String) -> void:
	var completed := progress.finish_story_fishing(species) if story_cast else (progress.finish_lotus_fishing(species) if lotus_cast else progress.finish_fishing(species))
	story_cast = false
	lotus_cast = false
	if completed:
		clock_elapsed = 0.0
		if _in_village():
			_sync_npcs()
			_update_market()
			_refresh_drying_rice()
		_commit_progress()


func _flash_interaction(target: Vector2i) -> void:
	if activity_marker and activity_marker.is_running():
		activity_marker.kill()
	activity_cell = target
	activity_marker = create_tween()
	activity_marker.tween_method(_set_activity_alpha, 0.38, 0.0, 0.24)


func _set_activity_alpha(value: float) -> void:
	activity_alpha = value
	overlay.queue_redraw()


func _select_seed(crop_id: String) -> void:
	if progress.select_crop(crop_id):
		_commit_progress()


func _on_panel_item(crop_id: String) -> void:
	if farm_panel.mode == FarmPanel.Mode.BAG:
		_select_seed(crop_id)
		return
	if farm_panel.mode != FarmPanel.Mode.SHOP:
		return

	var crop: Dictionary = CropCatalog.CROPS[crop_id]
	if not progress.buy_seed(crop_id):
		farm_panel.feedback.text = "Cần %d xu, hiện có %d xu." % [crop.buy_price, progress.coins]
		return
	var saved := _commit_progress()
	farm_panel.feedback.text = "Đã mua 1 hạt %s." % crop.name.to_lower()
	if not saved:
		farm_panel.feedback.text += " Chưa lưu được."


func _commit_progress() -> bool:
	_sync_event_people()
	_update_status()
	_update_feedback()
	return _save_progress()


func _save_progress() -> bool:
	var saved := GardenSave.write(progress) == OK
	save_warning.visible = not saved
	tutorial.visible = saved
	return saved


func _update_plot(cell: Vector2i) -> void:
	var plot := progress.plots[cell]
	var soil_tile := SOIL_UNTILLED
	var source := 0
	if plot.tilled:
		soil_tile = SOIL_WET if progress.is_plot_wet(plot, cell) or (plot.prepared and progress.is_paddy(cell)) else SOIL_DRY
	if progress.in_drought() and plot.tilled and not progress.is_plot_wet(plot, cell) and not plot.watered:
		source = 2
		soil_tile = DROUGHT_SOIL
	ground.set_cell(cell, source, soil_tile)

	var sprite := crop_sprites[cell]
	var stubble := progress.summer != null and progress.summer.late.has_stubble(cell)
	sprite.visible = stubble or not plot.crop_id.is_empty()
	if stubble:
		sprite.hframes = 1
		sprite.texture = PixelArt.atlas_frame(LATE_SUMMER_ART, 6)
		sprite.modulate = Color.WHITE
	elif sprite.visible:
		sprite.texture = crop_atlases[plot.crop_id]
		sprite.hframes = 3
		sprite.frame = 2 if progress.nights_until_ripe(plot) <= 0 else int(plot.watered_nights > 0)
		sprite.modulate = Color("#c2ad70") if plot.drought_stress > 0 else (Color("#e5e7ac") if plot.fertilized else Color.WHITE)
	if pest_sprites.has(cell):
		pest_sprites[cell].visible = progress.has_pest(cell)


func _update_status() -> void:
	_update_clock()
	tutorial.text = "Đã xong hướng dẫn" if progress.tutorial_completed else (
		"Hướng dẫn %d/%d xu" % [progress.coins, GardenProgress.GOAL_COINS]
	)
	var crop: Dictionary = CropCatalog.CROPS[progress.selected_crop]
	seed_icon.texture = seed_icons[progress.selected_crop]
	var shortcut := progress.seed_shortcut(progress.selected_crop)
	var prefix := "[%d] " % shortcut if shortcut > 0 else ""
	seed_selection.text = "%s%s ×%d" % [prefix, crop.name, progress.quantity(crop.seed_item)]
	if progress.arrival != null:
		tutorial.text = "Thể lực %d/%d" % [progress.arrival.stamina, progress.stamina_cap()]
		if progress.arrival.meal_bonus > 0:
			tutorial.text += " +%d" % progress.arrival.meal_bonus
		seed_icon.visible = not _in_house() and progress.day >= 3 and progress.area not in [
			GardenProgress.Area.LOTUS_POND, GardenProgress.Area.COUNTY_FAIR, GardenProgress.Area.FORGE, GardenProgress.Area.BAMBOO_WORKS, GardenProgress.Area.STOREHOUSE,
		] and not progress.storm_active()
		seed_selection.visible = seed_icon.visible
	if farm_panel.visible:
		farm_panel.refresh(progress)


func _update_weather() -> void:
	if progress.storm_active():
		late_audio.play_area(&"storm")
	elif progress.area == GardenProgress.Area.FORGE:
		late_audio.play_area(&"recovery")
	elif progress.area in [GardenProgress.Area.BAMBOO_WORKS, GardenProgress.Area.STOREHOUSE]:
		late_audio.play_area(&"workshop")
	elif progress.area == GardenProgress.Area.LOTUS_POND:
		late_audio.play_area(&"pond")
	elif progress.area == GardenProgress.Area.COUNTY_FAIR:
		late_audio.play_area(&"fair")
	elif progress.area == GardenProgress.Area.GARDEN and progress.summer_available(LateSummer.RECOVERY) and (
		progress.day <= LateSummer.FIRST_FAIR or progress.day in [AutumnWork.INVEST_DAY, AutumnWork.REST_DAY]
	):
		late_audio.play_area(&"recovery")
	else:
		late_audio.play_area(&"")
	var rainy := progress.is_raining(progress.day)
	var storm_evening := rainy and progress.summer_available(BambooWorks.STORM_DAY) and progress.day == BambooWorks.STORM_DAY
	weather_label.text = "%s %d · %s" % [
		progress.season_name(), progress.season_date(),
		"Nắng hạn %d/5" % (progress.day - DroughtProgress.FIRST + 1) if progress.in_drought() else ("Giông" if storm_evening else ("Mưa" if rainy else "Nắng")),
	]
	rain.visible = rainy and _outdoors_at(player_cell)
	(rain.material as ShaderMaterial).set_shader_parameter("storm", 1.0 if progress.storm_active() else 0.0)
	if _in_house() or progress.area == GardenProgress.Area.STOREHOUSE:
		daylight.color = Color.WHITE
	elif progress.area == GardenProgress.Area.FORGE:
		daylight.color = Color("#f7dfc2")
	elif progress.minute_of_day < GardenCalendar.START_MINUTE:
		daylight.color = Color("#9a9cb7")
	elif _in_festival() and progress.minute_of_day >= VillageFestival.LANTERN_HOUR:
		daylight.color = Color("#818bb7")
	elif storm_evening:
		daylight.color = Color("#909cb8")
	elif progress.summer_available(AutumnWork.SOIL_DAY) and progress.day in [AutumnWork.SOIL_DAY, AutumnWork.REST_DAY] and progress.minute_of_day >= 16 * 60:
		daylight.color = Color("#f5d298")
	elif rainy:
		daylight.color = Color("#c5d5e6")
	elif progress.summer_available(LateSummer.RECOVERY) and progress.day <= LateSummer.FIRST_FAIR:
		daylight.color = Color("#edf9ec")
	elif progress.in_drought():
		daylight.color = Color("#ffe2b9")
	elif progress.summer_available(SummerCraft.HEAT_HINT_DAY) and progress.day in [SummerCraft.HEAT_HINT_DAY, SummerCraft.FORECAST_DAY]:
		daylight.color = Color("#fff1cf")
	else:
		daylight.color = Color("#fff4dc") if progress.season() == GardenCalendar.Season.SUMMER else Color.WHITE


func _outdoors_at(cell: Vector2i) -> bool:
	if _in_house() or progress.area in [GardenProgress.Area.FORGE, GardenProgress.Area.STOREHOUSE]:
		return false
	return progress.area != GardenProgress.Area.BAMBOO_WORKS or not BambooWorksMap.indoors(false, cell)


func _update_clock() -> void:
	var weekday: String = GardenCalendar.WEEKDAYS[GardenCalendar.weekday_index(progress.day)]
	status.text = "%s · Ngày %d · %s    %d xu" % [
		weekday, progress.day, GardenCalendar.format_time(progress.minute_of_day), progress.coins,
	]


func _plot_hint(cell: Vector2i) -> String:
	if progress.plot_has_weeds(cell):
		if not progress.arrival.tools_taken:
			return "Lấy liềm trong nhà trước"
		if progress.arrival.total_stamina() < progress.weed_cost():
			return "Mệt rồi · Ngủ để hồi thể lực"
		if progress.double_sickle_cut():
			return "E · Phát cỏ · Nhát %d/2" % (2 if progress.sickle_half_done(cell) else 1)
		return "E · Phát cỏ (−%d thể lực)" % progress.weed_cost()
	if progress.arrival != null:
		if progress.day < 3:
			return "Luống rau · Gieo từ ngày 3"
		if not progress.arrival.tools_taken:
			return "Nhặt đồ nghề trong nhà trước"
	var plot := progress.plots[cell]
	if progress.autumn_soil_available(cell) and not plot.fertile and progress.day <= AutumnWork.CRAFT_DAY:
		return "F · Bón lót phân thảo mộc" if plot.loosened else "F · Xới đất vụ thu"
	var crop: Dictionary = CropCatalog.CROPS[progress.selected_crop if plot.crop_id.is_empty() else plot.crop_id]
	var crop_name: String = crop.name.to_lower()
	var action := progress.plot_action(cell)
	if progress.arrival != null and progress.arrival.total_stamina() < progress.action_cost(action):
		return "Mệt rồi · Ngủ để hồi thể lực"
	match action:
		PlotAction.REMOVE_PEST:
			return "E · Bắt sâu"
		PlotAction.HOE:
			return "E · Cuốc đất"
		PlotAction.SOW:
			return "E · Gieo hạt %s" % crop_name
		PlotAction.WATER:
			if progress.needs_extra_water(cell):
				return "E · Tưới lượt %d/2" % (2 if plot.watered else 1)
			return "E · Tưới %s (%d/%d)" % [crop_name, plot.watered_nights, crop.growth_nights]
		PlotAction.WAIT_FOR_WATER:
			return "Đã tưới lượt 1 · Tưới tiếp từ 15:00"
		PlotAction.WELL_EMPTY:
			return "Hết nước · Hỏi Chú Thành hoặc đào giếng phụ"
		PlotAction.HARVEST:
			return ("E · Thu %s · Giữ E thu cả vụ hè" if _can_bulk_harvest(cell) else "E · Thu hoạch %s") % crop_name
		PlotAction.NO_SEEDS:
			return "Hết hạt %s · Đổi hạt" % crop_name
		PlotAction.OUT_OF_SEASON:
			return "Hạt dành cho vụ thu" if progress.selected_crop in CropCatalog.AUTUMN_CROPS else "Hạt dành cho vụ hè"
		PlotAction.CUT_STUBBLE:
			if progress.double_sickle_cut():
				return "E · Dọn gốc khô · Nhát %d/2" % (2 if progress.sickle_half_done(cell) else 1)
			return "E · Dọn gốc khô (−%d thể lực)" % progress.action_cost(action)
		PlotAction.FLOODED:
			return "Luống úng · Khơi rãnh ở ô bên dưới"
		PlotAction.DEEP_HOE:
			return "E · Cuốc sâu lớp thứ hai"
		PlotAction.FLOOD_PADDY:
			return "E · Dẫn nước ao vào ô lúa"
		PlotAction.WRONG_SOIL:
			return "Nếp gieo ở ô ven ao đã dẫn nước" if progress.selected_crop == CropCatalog.STICKY_RICE else (
				"Cà rốt Thuận Thành gieo trên đất cuốc sâu" if progress.selected_crop == CropCatalog.HEIRLOOM_CARROT else "Ô này dành cho lúa nếp"
			)
	if progress.sprinkler_covers(cell):
		return "Vòi tưới đã làm ẩm luống"
	if progress.is_raining(progress.day):
		return "Mưa đã tưới luống"
	return "Đã tưới hôm nay (%d/%d)" % [plot.watered_nights, crop.growth_nights]


func _update_feedback() -> void:
	player.frame_coords = Vector2i(0, _direction_row())
	if progress.village_wholesale_market():
		var stall_hint: String = {SummerStory.CLOTHES: "E · Tiệm đồ si Bà Tám", SummerStory.DECOR: "E · Đồ kiểng",
			SummerStory.CARPENTER: "E · Sạp bác thợ mộc", VillageMap.MARKET_CELL: "E · Bán buôn tại Chợ Làng"}.get(player_cell + facing, "")
		if not stall_hint.is_empty():
			hint.text = stall_hint
			overlay.queue_redraw()
			return
	var story_hint := _story_farm_hint(player_cell + facing) if progress.area == GardenProgress.Area.GARDEN else ""
	if not story_hint.is_empty():
		hint.text = story_hint
		overlay.queue_redraw()
		return
	var target := player_cell + facing
	var works_hint := _works_hint(target)
	var late_hint := _late_summer_hint(target)
	if not works_hint.is_empty():
		hint.text = works_hint
	elif _in_works_site():
		hint.text = "Sắt vụn quanh lò · Bác thợ rèn cạnh bếp" if progress.area == GardenProgress.Area.FORGE else "Máy chẻ lạt · Kho tre · Bảng đơn"
	elif not late_hint.is_empty():
		hint.text = late_hint
	elif progress.area in [GardenProgress.Area.LOTUS_POND, GardenProgress.Area.COUNTY_FAIR]:
		hint.text = "WASD · Chèo thuyền thúng" if boat.visible else "Lái Buôn giữa chợ · Sạp hạt ở phía đông"
	elif _is_drought_cell(target):
		hint.text = _drought_hint(target)
	elif _is_craft_cell(target):
		hint.text = _craft_hint(target)
	elif _is_social_cell(target):
		hint.text = _social_hint(target)
	elif _in_house():
		hint.text = "E · Giã cám mịn" if farmhouse.mill_visible() and target == FestivalMap.MILL else _house_hint(target)
	elif _in_festival() or _is_festival_cell(target):
		hint.text = _festival_hint(target)
	elif _in_district() or _summer_cell(target):
		hint.text = _summer_hint(target)
	elif _in_village():
		hint.text = _village_hint(target)
	elif progress.plots.has(target):
		hint.text = _plot_hint(target)
	elif target == DOOR_CELL:
		hint.text = "E · Vào nhà" if progress.arrival != null else "E · Ngủ sang ngày %d" % (progress.day + 1)
	elif target == VILLAGE_GATE:
		hint.text = "E · Sang làng ven sông" if progress.can_visit_village() else "Cổng làng mở ngày 3"
	elif BIN.has_point(target):
		var total := progress.sale_value()
		hint.text = "E · Bán hàng (+%d xu)" % total if total > 0 else "Thùng bán · Trống"
		if progress.summer_available(SummerProgress.FIRST_DAY) and progress.bin_open():
			hint.text = "Xe đã chất hàng · Ra chợ huyện" if progress.summer.cart_loaded else (
				"E · Chất hàng lên xe thồ" if progress.has_wholesale_goods() else "Xe thồ · Chưa có hàng"
			)
		elif not progress.bin_open():
			hint.text = "Thùng bán mở từ ngày 11 sau lần bán rau đầu"
	elif progress.yard_open() and target == _dog_cell():
		match progress.arrival.dog_food:
			ArrivalProgress.DogFood.PANTRY:
				hint.text = "E · Làm quen Cậu Vàng"
			ArrivalProgress.DogFood.BAG:
				hint.text = "E · Cho Cậu Vàng ăn"
			ArrivalProgress.DogFood.FED:
				hint.text = "E · Chào Cậu Vàng"
	elif _is_yard_visitor(target):
		match target:
			SEED_BOX:
				hint.text = "E · Nhận hạt giống"
			DAD_CELL:
				hint.text = "E · Nói với Bố Đức"
			CAT_CELL:
				hint.text = "E · Vuốt ve Hoàng Thượng"
	elif _is_tutorial_yard_cell(target):
		hint.text = _tutorial_yard_hint(target)
	elif fence_editing:
		hint.text = "Chọn ô trong lưới · Esc thoát"
	elif progress.arrival != null and progress.day == 1:
		hint.text = "Đi theo đường đất về nhà · J"
	elif progress.arrival != null and progress.day == 2:
		hint.text = "Về giường ngủ · J" if progress.cleared_plot_count() == GardenProgress.PLOT_CELLS.size() else (
			"Phát cỏ quanh luống · J"
		)
	else:
		hint.text = "Muộn rồi · Về cửa nhà ngủ" if progress.minute_of_day >= GardenCalendar.LAST_MINUTE else (
			"I · Túi đồ    J · Lịch"
		)
	overlay.queue_redraw()


func _house_hint(target: Vector2i) -> String:
	var arrival := progress.arrival
	if farmhouse.is_interactive(target):
		match target:
			Farmhouse.EXIT:
				return "E · Ra vườn"
			Farmhouse.TOOLS:
				return "E · Nhặt đồ nghề"
			Farmhouse.CLUTTER:
				return "E · Dọn đống đồ (−5 thể lực)"
			Farmhouse.PANTRY:
				return "E · Nhặt gói thức ăn"
			Farmhouse.SWITCH:
				return "Đèn đã sáng" if arrival.power_on else "E · Bật cầu dao"
			Farmhouse.STOVE:
				if progress.summer.parents_visited and not progress.summer.family_meal or progress.summer.invited_hai and not progress.summer.ate_with_hai:
					return "E · Nấu cơm mời khách"
				if progress.summer_available(SummerProgress.QUIET_DAY):
					return "E · Xem món ăn và pha trà"
				return "E · Xem bếp" if arrival.cooked_meal else "E · Nấu bữa cơm đầu tiên"
			Farmhouse.CUPBOARD:
				return "E · Mở tủ chè"
			Farmhouse.CHEST:
				return "E · Mở rương gỗ"
			Farmhouse.RADIO:
				return "E · Bật radio"
			Farmhouse.PIPE_SHELF:
				return "E · Xem kệ trong kho"
			Farmhouse.BED:
				return "E · Ngủ sang ngày %d" % (progress.day + 1) if arrival.bed_ready else "E · Đặt lại giường"
	if progress.day == 2:
		return "J · Tay liềm đầu tiên"
	return "I · Túi đồ    J · Việc cần làm"


func _tutorial_yard_hint(target: Vector2i) -> String:
	match target:
		COOP:
			if progress.day < ArrivalProgress.COOP_DAY:
				return "Chuồng gà mở ngày 5"
			match progress.arrival.hen:
				ArrivalProgress.Hen.LOCKED:
					return "E · Mở chuồng và lấy thức ăn"
				ArrivalProgress.Hen.EGG_READY:
					return "E · Nhặt trứng"
			if progress.summer_available(SummerProgress.BUILD_DAY) and progress.summer.coop_step < 4:
				return "E · Mở rộng chuồng"
			return "E · Xem chuồng gà"
		TROUGH:
			match progress.arrival.hen:
				ArrivalProgress.Hen.LOCKED:
					return "Mở chuồng để lấy thức ăn"
				ArrivalProgress.Hen.RATION:
					return "E · Cho gà ăn"
				ArrivalProgress.Hen.FED:
					return "Máng đã có thức ăn"
			if progress.can_feed_again():
				return "E · Thêm thức ăn cho gà"
			return "Gà đã ăn phần đầu tiên"
		FENCE_SIGN:
			return "E · Tắt lưới hàng rào" if fence_editing else "E · Bật lưới hàng rào"
		DITCH:
			if progress.arrival.drained:
				return "Rãnh đã thông"
			return "E · Khơi rãnh" if progress.arrival.tools_taken else "Nhặt cuốc trong nhà trước"
	if target == progress.fence_cell():
		return "E · Thu hồi hàng rào · Esc thoát"
	if not _can_walk(target):
		return "Ô đã có vật cản"
	return ("E · Dời hàng rào" if progress.arrival.fence_index >= 0 else "E · Đặt hàng rào") + " · Esc thoát"


func _village_hint(target: Vector2i) -> String:
	match target:
		VillageMap.EXIT_CELL:
			return "E · Về vườn"
		VillageMap.SHOP_SIGN:
			if GardenCalendar.shop_is_open(progress.minute_of_day):
				return "E · Cửa hàng hạt giống"
			return "Cửa hàng đóng · %s" % GardenCalendar.shop_hours()
		VillageMap.ORDER_BOARD:
			return "E · Xem bảng chỉ đường" if progress.arrival != null and progress.day < ArrivalProgress.BOARD_DAY else "E · Bảng đơn nông sản"
		VillageMap.MARKET_CELL:
			if progress.produce_stall_open():
				return "E · Bán nông sản"
			if progress.arrival != null:
				return "E · Xem giờ quầy mua nông sản"
			return "E · Chợ phiên" if progress.market_open() else "E · Xem lịch chợ phiên"
		VillageMap.LAN_CELL:
			if progress.arrival != null:
				return "E · Nói với Chị Lan"
		VillageMap.FISHING_SPOT:
			if progress.arrival != null and progress.day < ArrivalProgress.FISHING_DAY:
				return "Bến câu mở ngày 6"
			return "E · Thả câu" if progress.minute_of_day < GardenCalendar.LAST_MINUTE else "Muộn rồi · Mai câu tiếp"
	var index := npc_cells.find(target)
	if index >= 0:
		var id: String = VillagerCatalog.IDS[index]
		return "E · Nói với %s" % VillagerCatalog.VILLAGERS[id].name
	return "I · Túi đồ    J · Lịch"
