class_name TutorialGarden
extends Node2D

const MAP := preload("res://tutorial_farm_map.gd")
const Soil = TutorialChapter.Soil
enum PlotWork { NONE, HOE, SOW, WATER, FLOOD_FIRST, FLOOD_SECOND, SPRAY, WEED, FERTILIZE, HARVEST }
const VEGETABLE_WORK := {Soil.BARE: PlotWork.HOE, Soil.TILLED: PlotWork.SOW, Soil.SOWN: PlotWork.WATER}
const RICE_WORK := {
	Soil.BARE: PlotWork.HOE, Soil.TILLED: PlotWork.FLOOD_FIRST,
	Soil.DAMP: PlotWork.FLOOD_SECOND, Soil.FLOODED: PlotWork.SOW,
}
const CABBAGE_CARE := {
	Soil.PEST: PlotWork.SPRAY, Soil.WEEDS: PlotWork.WEED,
	Soil.SPROUT: PlotWork.FERTILIZE, Soil.RIPE: PlotWork.HARVEST,
}
const PLAYER := preload("res://assets/art/32/hoang.png")
const FISHING_SCENE := preload("res://fishing_panel.tscn")
const GARDEN_SCENE := "res://garden.tscn"
const FEED := ["worm", "duckweed", "rice_bran", "raw_rice"]
const RECIPES := {
	"cabbage_soup": {"cabbage_produce": 2, "goby": 1, "wood": 1},
	"sour_soup": {"ground_cherry": 1, "goby": 1},
	"frog_porridge": {"frog": 1, "raw_rice": 1},
	"snail_dish": {"snail": 2, "wood_ear": 1, "wood": 1},
	"rice_meal": {"white_rice": 1, "goby": 1},
	"frog_rice": {"white_rice": 1, "frog": 1},
}

var progress: GardenProgress
var state: TutorialChapter
var field := TutorialFarmMap.new()
var house := Farmhouse.new()
var character := Sprite2D.new()
var sound := LateSummerAudio.new()
var facing := Vector2i.UP
var walking: Tween
var walk_destination := Vector2i(-1, -1)
var walk_step := 0
var tick := 0.0
var message := ""
var status := Label.new()
var goals := Label.new()
var feedback := Label.new()
var target_prompt := PanelContainer.new()
var target_label := Label.new()
var card := PanelContainer.new()
var menu_title := Label.new()
var menu_text := Label.new()
var choices := VBoxContainer.new()
var close_button := Button.new()
var fuses := TutorialFusePanel.new()
var arcade := TutorialArcade.new()
var fishing: FishingPanel
var rain := ColorRect.new()
var darkness := ColorRect.new()
var indoor_pointer := Node2D.new()


func _ready() -> void:
	state = progress.chapter
	field.progress = progress
	add_child(field)
	house.position = MAP.ORIGIN
	add_child(house)
	character.texture = PLAYER
	character.hframes = 3
	character.vframes = 4
	character.offset = Vector2(0, -24)
	character.position = MAP.feet(state.cell)
	add_child(character)
	darkness.size = Vector2(768, 480)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lamp := Shader.new()
	lamp.code = """shader_type canvas_item;
uniform vec2 focus;
void fragment() {
    float distance_to_player = length(UV * vec2(768.0, 480.0) - focus);
    COLOR = vec4(0.045, 0.035, 0.05, mix(0.13, 0.64, smoothstep(40.0, 125.0, distance_to_player)));
}"""
	var shadow := ShaderMaterial.new()
	shadow.shader = lamp
	darkness.material = shadow
	add_child(darkness)
	indoor_pointer.draw.connect(_draw_indoor_pointer)
	add_child(indoor_pointer)
	rain.position = MAP.ORIGIN
	rain.size = Vector2(640, 384)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://rain.gdshader")
	rain.material = material
	add_child(rain)
	add_child(sound)
	_setup_hud()
	_refresh_region()
	_record()
	if progress.day == 1 and state.phase == 0:
		_show_notice("15:00 · Về tới quê", "Hoàng bước xuống xe với chiếc ba lô vải. Trưởng thôn đang đợi ở sân gạch.\nWASD hoặc phím mũi tên để đi. Quay mặt về vật muốn dùng rồi nhấn E.")


func _setup_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	for pair in [[status, Vector2(64, 8), 22], [goals, Vector2(64, 38), 18], [feedback, Vector2(64, 62), 14]]:
		var label := pair[0] as Label
		label.position = pair[1]
		label.size.x = 640
		label.add_theme_font_size_override("font_size", pair[2])
		label.add_theme_color_override("font_color", Color("fff0cc"))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hud.add_child(label)
	var controls := Label.new()
	controls.position = Vector2(64, 461)
	controls.text = "WASD · Đi    E · Tương tác    I · Túi    J · Việc hôm nay    R · Ăn    Shift · Đi khẽ"
	controls.add_theme_color_override("font_color", Color("e4dfb5"))
	hud.add_child(controls)

	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color("222e25")
	prompt_style.border_color = Color("b69762")
	prompt_style.set_border_width_all(1)
	prompt_style.set_corner_radius_all(4)
	prompt_style.content_margin_left = 8
	prompt_style.content_margin_right = 8
	prompt_style.content_margin_top = 3
	prompt_style.content_margin_bottom = 3
	target_prompt.add_theme_stylebox_override("panel", prompt_style)
	target_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_label.add_theme_font_size_override("font_size", 16)
	target_label.add_theme_color_override("font_color", Color("fff0cc"))
	target_prompt.add_child(target_label)
	hud.add_child(target_prompt)
	target_prompt.hide()

	var shade := ColorRect.new()
	shade.size = Vector2(768, 480)
	shade.color = Color(0.06, 0.09, 0.07, 0.64)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(shade)
	card.position = Vector2(126, 64)
	card.size = Vector2(516, 350)
	card.theme = preload("res://farm_ui.tres")
	shade.add_child(card)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 17)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	menu_title.add_theme_font_size_override("font_size", 24)
	menu_title.add_theme_color_override("font_color", Color("ffdc9b"))
	box.add_child(menu_title)
	menu_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_text.custom_minimum_size.x = 456
	box.add_child(menu_text)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	box.add_child(scroll)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 5)
	scroll.add_child(choices)
	close_button.text = "Quay lại · Esc"
	close_button.pressed.connect(_close_card)
	box.add_child(close_button)
	shade.hide()
	hud.add_child(fuses)
	fuses.moved.connect(_fuse_moved)
	hud.add_child(arcade)
	arcade.milled.connect(_finish_mill)
	arcade.defended.connect(_finish_defense)
	fishing = FISHING_SCENE.instantiate() as FishingPanel
	hud.add_child(fishing)
	fishing.hide()
	fishing.cast_finished.connect(_catch_fish)
	for modal in [shade, fuses, arcade, fishing]:
		modal.visibility_changed.connect(_update_target_prompt)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if fishing.visible:
		if event.is_action_pressed("interact"):
			fishing.reel()
		elif event.is_action_pressed("ui_cancel"):
			fishing.cancel()
		return
	if fuses.visible or arcade.visible:
		return
	if card.is_visible_in_tree():
		if event.is_action_pressed("ui_cancel"):
			_close_card()
		elif event.is_action_pressed("interact"):
			var focused := get_viewport().gui_get_focus_owner() as Button
			if focused != null and not focused.disabled:
				focused.pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if walking and walking.is_running():
		return
	if event.is_action_pressed("interact"):
		_interact(state.cell + facing)
	elif event.is_action_pressed("inventory"):
		_open_bag(false)
	elif event.is_action_pressed("journal"):
		_open_journal()
	elif event.physical_keycode == KEY_R:
		_open_bag(true)
	elif event.is_action_pressed("ui_cancel"):
		_open_card("Tạm dừng", "Tiến độ được lưu sau mỗi thao tác. Bạn có thể tiếp tục từ màn hình chính.")
		_option("Lưu và về màn hình chính", _return_to_title)
	else:
		return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _modal() or (walking and walking.is_running()):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var delta: Vector2 = (event.position - MAP.ORIGIN) / MAP.CELL
		var target := Vector2i(floori(delta.x), floori(delta.y))
		var distance := target - state.cell
		if absi(distance.x) + absi(distance.y) == 1:
			facing = distance
			_interact(target)


func _physics_process(delta: float) -> void:
	if _modal():
		return
	_clock(delta)
	if walking and walking.is_running():
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement == Vector2.ZERO:
		return
	var direction := Vector2i(int(signf(movement.x)), 0) if absf(movement.x) > absf(movement.y) else Vector2i(0, int(signf(movement.y)))
	facing = direction
	var next := state.cell + direction
	if _can_walk(next):
		_walk(next)
	else:
		_update_hud()


func _clock(delta: float) -> void:
	tick += delta
	if tick < 6.25 or progress.minute_of_day >= GardenCalendar.LAST_MINUTE:
		return
	tick -= 6.25
	progress.minute_of_day += GardenCalendar.STEP_MINUTES
	if progress.minute_of_day % 60 == 0:
		progress.arrival.stamina = mini(100, progress.arrival.stamina + 20)
	_update_hud()


func _walk(next: Vector2i) -> void:
	walk_destination = next
	walk_step = 1 if walk_step != 1 else 2
	character.frame_coords = Vector2i(walk_step, _pose())
	var duration := 0.13
	if Input.is_physical_key_pressed(KEY_SHIFT):
		duration = 0.23
	elif progress.arrival.stamina <= 10:
		duration = 0.28
	elif rain.visible and state.count("warm") == 0:
		duration = 0.18
	walking = create_tween()
	walking.tween_method(_place_character, character.position, MAP.feet(next), duration)
	walking.tween_callback(_end_walk.bind(next))


func _place_character(point: Vector2) -> void:
	character.position = point.round()
	if darkness.visible:
		_show_darkness()


func _end_walk(next: Vector2i) -> void:
	state.cell = next
	walk_destination = Vector2i(-1, -1)
	if not _inside() and Input.is_action_pressed("interact"):
		if (progress.day == 7 and state.phase == 3) or (progress.day == 9 and state.phase == 0):
			_work_plot(MAP.plot_at(next))
	_update_hud()


func _pose() -> int:
	return [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP].find(facing)


func _can_walk(cell: Vector2i) -> bool:
	if _inside():
		return house.can_walk(cell)
	if not Rect2i(1, 1, 18, 10).has_point(cell) or MAP.HOUSE.has_point(cell) or MAP.POND.has_point(cell):
		return false
	if cell.x == MAP.GATE.x:
		return cell == MAP.GATE and state.count("gate") > 0
	if cell == MAP.VISITOR:
		return not _visitor_present()
	return cell not in [MAP.SIGN, MAP.SHED, MAP.WELL, MAP.BIN, MAP.COOP, MAP.TROUGH]


func _inside() -> bool:
	return progress.area == GardenProgress.Area.HOUSE


func _modal() -> bool:
	return card.is_visible_in_tree() or arcade.visible or fuses.visible or fishing.visible


func _interact(target: Vector2i) -> void:
	if _inside():
		_interact_house(target)
	else:
		_interact_outside(target)
	_update_hud()


func _interact_house(target: Vector2i) -> void:
	match target:
		Farmhouse.EXIT:
			_travel(false)
		Farmhouse.SWITCH:
			if progress.day == 1 and state.phase == 3:
				fuses.open(state)
			else:
				_note("Cầu dao đã đóng." if progress.arrival.power_on else "Cầu dao đang mất điện.")
		Farmhouse.CLUTTER:
			if not progress.arrival.floor_cleared and _spend(2):
				progress.arrival.floor_cleared = true
				_changed("Đã dọn lối đi trong nhà.")
		Farmhouse.BED:
			_offer_sleep()
		Farmhouse.CHEST:
			if progress.day == 2 and state.phase == 5:
				_reward({"noodles": 4, "sweet_root": 4, "potato": 3, "raw_rice": 2})
				_advance("Nhặt lương thực trong rương.")
				_show_notice("Rương lương thực", "Có 4 gói mì, 4 củ khoai lang, 3 củ khoai tây và 2 phần gạo. Nhấn R để chọn đồ ăn.")
			elif progress.day >= 2:
				_open_storage()
		Farmhouse.STOVE:
			_stove()


func _interact_outside(target: Vector2i) -> void:
	match target:
		MAP.DOOR:
			if progress.day == 1 and state.phase < 2:
				_note("Cần gặp Trưởng thôn và dọn sạch cỏ trước cửa.")
				return
			if progress.day == 1 and state.phase == 2:
				progress.minute_of_day = maxi(progress.minute_of_day, 18 * 60 + 30)
				state.phase += 1
			_travel(true)
		MAP.VISITOR:
			_visitor()
		MAP.GATE:
			if progress.day == 2 and state.phase == 0:
				state.advance("gate")
				_advance("Đã mở cổng tre sang vườn.")
		MAP.SIGN:
			if progress.day == 2 and state.phase == 1:
				_advance("Tấm biển của ông ghi: Đất không phụ người chăm.")
				_show_notice("Lời ông để lại", "Đất không phụ người chăm.\nCó tiếng còi xe ngoài sân. Quay lại sân gạch và nhấn E để gặp Cô Lan.")
		MAP.WELL:
			if state.quantity("can") > 0:
				state.water = 10
				_changed("Đã múc đầy bình tưới.")
		MAP.SHED:
			_shed()
		MAP.COOP:
			_coop()
		MAP.TROUGH:
			_feed_hen()
		MAP.CAT:
			_cat()
		MAP.DOG:
			_dog()
		MAP.BIN:
			_shipping_bin()
		MAP.MILL:
			_mill()
		MAP.WOODPILE:
			if progress.day >= 3 and state.quantity("hammer") > 0 and _spend(3):
				state.give("wood", 3)
				_changed("Đã gom 3 gỗ tạp ở rìa vườn.")
		MAP.FISHING:
			_start_fishing()
		_:
			if not _gather(target):
				_work_plot(MAP.plot_at(target))


func _visitor_present() -> bool:
	return state.visitor_present(progress.day, progress.minute_of_day) and MAP.VISITOR not in [state.cell, walk_destination]


func _visitor() -> void:
	if not _visitor_present():
		return
	var phase := state.phase
	match progress.day:
		1:
			if phase == 0:
				_reward({"old_key": 1, "sickle": 1, "phu_the": 2})
				_advance("Nhận chìa khóa, liềm cùn và 2 bánh phu thê.")
				_show_notice("Trưởng thôn", "Hoàng về rồi à? Bác giữ hộ chìa khóa nhà ông ngoại cháu. Cầm liềm dọn mười bụi cỏ lấy lối đi. Mệt thì mở túi ăn bánh, rồi vào nhà sửa cầu dao.")
			else:
				_show_notice("Trưởng thôn", "Dọn lối qua sân rồi dùng chìa khóa vào nhà ông nhé.")
		2:
			if phase == 2:
				_reward({"hoe": 1, "can": 1, "cabbage_seed": 5})
				_advance("Nhận cuốc, bình tưới và 5 hạt cải ngọt.")
				_show_notice("Cô Lan Tạp Hóa", "Dọn 10 bụi cỏ trước nhé. Đứng cạnh ô có viền vàng và nhấn E để cuốc rồi gieo. Nhấn E cạnh giếng để múc nước, sau đó quay lại luống vừa gieo để tưới.")
		4:
			if phase == 0:
				_reward({"hot_lunch": 1, "chicken_pair": 1, "rice_seed": 10})
				_advance("Bác Lý gửi cơm nóng, đôi gà và 10 thóc giống.")
				_show_notice("Bác Lý", "Ăn phần cơm này cho lại sức. Bác mang một đôi gà và thóc giống. Sửa chuồng bằng gỗ hôm qua, rồi cuốc đất cạnh ao làm ruộng nước.")
		6:
			if phase == 0:
				_advance("Dùng búa tạ đập đá để sửa bếp.")
				_show_notice("Bác thợ mộc", "Bếp của ông long gạch hết rồi. Dùng búa đập đá quanh vườn, mang 5 đá cuội với 3 gỗ tới bếp. Gõ ba lượt là trát xong.")
		7:
			if phase == 0:
				_advance("Tìm rau má, mộc nhĩ và tầm bóp ở rìa vườn.")
				_show_notice("Chị Thảo bán rong", "Chưa có tiền thì đổi hàng. Đi quanh giếng, bờ ao và bờ rào tìm đồ hái lượm. Mang lại đây chị đổi cho giống ngô, rau dền.")
			elif phase == 2:
				_open_barter()
			else:
				_show_notice("Chị Thảo bán rong", "Tìm rau má, mộc nhĩ và tầm bóp quanh vườn rồi quay lại đổi giống nhé.")
		8:
			if phase == 0:
				state.advance("dog")
				_advance("Đã đón Cậu Vàng. Dựng mái che cạnh thùng.")
				_show_notice("Trưởng thôn", "Mưa thế này cứ để trời tưới vườn. Bác đem Cậu Vàng sang cho cháu. Dựng mái khô cạnh thùng rồi cho nó một quả trứng, nó sẽ ở lại canh hàng.")
		10:
			if phase == 0:
				_advance("Mở thùng để chọn nông sản mang đi.")
				_show_notice("Trưởng thôn", "Sáng mai mở chợ. Cháu đóng hàng vào thùng, giữ lại phần để ăn và làm giống. Chuột đồng hay mò tới lúc 18:00, chuẩn bị búa tạ với bình xịt để canh thùng nhé.")


func _reward(items: Dictionary) -> void:
	for item: String in items:
		state.give(item, items[item])


func _serve_food(item: String) -> void:
	if not state.pay({item: 1}):
		return
	var gained: int = TutorialChapter.FOOD[item]
	progress.arrival.stamina = mini(100, progress.arrival.stamina + gained)
	if progress.day >= 9 and item in ["rice_meal", "frog_rice"]:
		progress.arrival.cooked_meal = true
		progress.arrival.meal_bonus = 20
	if (progress.day == 2 and state.phase == 6) or (progress.day == 4 and state.phase == 1 and item == "hot_lunch") or (
		progress.day == 6 and state.phase == 4 and item == "cabbage_soup"
	):
		_advance("Đã ăn %s. Thể lực hồi lại." % _item(item).to_lower())
	else:
		if progress.day == 8 and item in ["frog_porridge", "snail_dish"]:
			state.advance("warm")
		var energy := "20 thể lực thưởng cho hôm nay" if item in ["rice_meal", "frog_rice"] else "hồi tối đa %d thể lực" % gained
		_changed("Đã ăn %s · %s" % [_item(item).to_lower(), energy])
	_close_card()


func _spend(cost: int) -> bool:
	if progress.day == 4 and state.phase >= 2:
		cost = ceili(cost / 2.0)
	if progress.arrival.spend_stamina(cost):
		return true
	_note("Thiếu thể lực. Nhấn R để ăn, hoặc nghỉ cho qua một giờ.")
	return false


func _shed() -> void:
	if progress.day == 3 and state.phase == 0:
		_advance("Dùng liềm phá ổ khóa gỉ. Kiểm tra kệ phía trong.")
	elif progress.day == 3 and state.phase == 1:
		_reward({"sprayer": 1, "npk": 5, "hammer": 1})
		_advance("Đã nhận bình xịt, 5 NPK và búa tạ.")
		_show_notice("Ghi chú của ông", "Nhổ cỏ tận gốc và xịt sâu trước. Mỗi ô cải có thể dùng một phần NPK để chín ngay trong lứa hướng dẫn này.")
	elif progress.day == 5 and state.phase == 0:
		state.give("net", 1)
		_advance("Có vợt lưới. Vớt 5 mảng bèo quanh bờ ao.")
	elif progress.day >= 3:
		if (progress.day == 8 and state.phase == 4) or (progress.day == 9 and state.phase == 3):
			_advance("Đã kiểm kê kho. Chọn món để cất hoặc lấy lại.")
		_open_storage()


func _coop() -> void:
	if progress.day == 4 and state.phase == 2:
		if state.pay({"wood": 3}):
			state.advance("coop")
			_advance("Chuồng đã sửa. Tương tác lần nữa để thả đôi gà.")
	elif progress.day == 4 and state.phase == 3:
		if state.pay({"chicken_pair": 1}):
			state.advance("chickens")
			_advance("Đã thả đôi gà. Cho ăn ở máng bên cạnh.")
	elif state.count("eggs") > 0:
		state.give("trung_ga", state.count("eggs"))
		state.counts.erase("eggs")
		_changed("Đã nhặt trứng ở ổ rơm.")
	else:
		_note("Cho gà ăn ở máng rồi quay lại nhặt trứng sáng sau.")


func _feed_hen() -> void:
	if state.count("chickens") == 0 or state.count("fed_today") > 0:
		return
	for item: String in FEED:
		if state.pay({item: 1}):
			state.advance("fed_today")
			if progress.day == 4 and state.phase == 4:
				_advance("Gà đã ăn. Tới ruộng cạnh ao để gieo thóc.")
			else:
				_changed("Gà đã ăn. Sáng mai có trứng.")
			return
	_note("Máng dùng sâu béo, bèo vụn, cám gạo hoặc gạo.")


func _cat() -> void:
	if not state.cat_present(progress.day):
		return
	if progress.day == 4 and state.phase == 6:
		_advance("Chú mèo đói nằm ngoài hiên. Sáng mai tìm cá cho nó.")
	elif progress.day == 5 and state.phase == 3:
		if not state.pay({"goby": 1}):
			_note("Mèo cần cá bống. Ra ao câu thêm.")
			return
		state.advance("cat")
		state.give("collar", 1)
		_advance("Mèo đã làm bạn và đem về một vòng cổ.")
		_open_card("Đặt tên cho mèo", "Chú mèo cọ chân Hoàng rồi ngậm về một chiếc vòng chuông.")
		var entry := LineEdit.new()
		entry.text = state.cat_name
		entry.max_length = 24
		choices.add_child(entry)
		_option("Lưu tên", _name_cat.bind(entry))
		entry.grab_focus()
	elif progress.day == 5 and state.phase == 4:
		if state.pay({"collar": 1}):
			state.advance("collared")
			_advance("Đã đeo chuông cho %s." % state.cat_name)
	else:
		_note("%s dụi đầu vào chân Hoàng." % state.cat_name if state.count("cat") else "Mèo nhìn về phía ao. Nó muốn ăn cá.")


func _name_cat(entry: LineEdit) -> void:
	var chosen := entry.text.strip_edges()
	if not chosen.is_empty():
		state.cat_name = chosen
	_changed()
	_close_card()


func _dog() -> void:
	if progress.day == 8 and state.phase == 1:
		if state.pay({"wood": 2}):
			state.advance("shelter")
			_advance("Mái che đã dựng. Thu trứng ở chuồng rồi cho Cậu Vàng ăn.")
		else:
			_note("Cần 2 gỗ. Có thể gom ở đống gỗ phía tây nam.")
	elif progress.day == 8 and state.phase == 2:
		if state.pay({"trung_ga": 1}):
			state.advance("dog_fed")
			_advance("Cậu Vàng đã chịu ở lại canh thùng.")
		else:
			_note("Nhặt một quả trứng trong chuồng. Nếu đã cất, lấy ở nhà kho.")
	elif state.count("dog_fed") > 0:
		_note("Cậu Vàng nằm gác cạnh thùng hàng.")


func _start_fishing() -> void:
	if state.quantity("rod") > 0:
		fishing.cast(FishCatalog.GOBY, 1.25, 1.65)
	else:
		_note("Vớt hết bèo để tìm cần câu ở bờ ao.")


func _catch_fish(species: String) -> void:
	if species.is_empty():
		return
	state.give("goby", 1)
	state.advance("caught")
	if progress.day == 5 and state.phase == 2:
		_advance("Đã câu được cá bống. Mang cho mèo ngoài hiên.")
	else:
		_changed("Đã cất cá bống vào túi.")


func _gather(cell: Vector2i) -> bool:
	var phase := state.phase
	match progress.day:
		1:
			if phase == 1:
				return _collect_group(cell, MAP.COURT_GRASS, "yard", "weed", 1, 12)
		2:
			if phase == 3:
				return _collect_group(cell, MAP.GARDEN_GRASS, "garden", "weed", 1, 2)
		3:
			if phase == 3:
				return _collect_group(cell, MAP.LOGS, "log", "wood", 3, 5)
		5:
			if phase == 1:
				return _collect_group(cell, MAP.REEDS, "reed", "duckweed", 1, 3)
		6:
			if phase == 1:
				return _collect_group(cell, MAP.ROCKS, "rock", "stone", 1, 4, 3)
		7:
			if phase in [1, 2]:
				var index := MAP.FORAGE.find(cell)
				if index >= 0:
					return _collect_group(cell, MAP.FORAGE, "forage", ["pennywort", "wood_ear", "ground_cherry"][index], 5, 1)
		8:
			if phase == 3:
				if _collect_group(cell, MAP.SNAILS, "snail", "snail", 2, 1):
					return true
				if cell in MAP.FROGS:
					if not Input.is_physical_key_pressed(KEY_SHIFT):
						_note("Giữ Shift để đi khẽ, rồi bấm E khi đứng cạnh ếch.")
						return true
					return _collect_group(cell, MAP.FROGS, "frog", "frog", 1, 1)
	return false


func _collect_group(cell: Vector2i, cells: Array, key: String, item: String, amount: int, cost: int, hits := 1) -> bool:
	var index := cells.find(cell)
	if index < 0:
		return false
	var key_at := key + str(index)
	if state.count(key_at) >= hits:
		return false
	if not _spend(cost):
		return true
	if state.advance(key_at) < hits:
		sound.play_effect(&"anvil")
		_changed("Tảng đá còn %d nhát búa." % (hits - state.count(key_at)))
		return true
	state.give(item, amount)
	var total := state.advance(key)
	var complete := total == cells.size()
	if key in ["snail", "frog"]:
		complete = state.count("snail") == MAP.SNAILS.size() and state.count("frog") == MAP.FROGS.size()
	if key == "reed" and complete:
		state.give("rod", 1)
		_advance("Nước ao đã trong. Tìm thấy cần câu trúc ở bờ đông nam.")
	elif complete:
		if key == "yard":
			progress.minute_of_day = maxi(progress.minute_of_day, 18 * 60 + 30)
		_advance("Đã xong. %s." % TutorialChapter.GOALS[progress.day - 1][state.phase + 1])
	else:
		if key == "yard" and total == 7:
			_note("Thể lực đã xuống thấp. Nhấn R để ăn bánh phu thê.")
		else:
			_note("%s · %d/%d" % [_item(item), total, cells.size()])
		_changed()
	return true


func _plot_work(index: int) -> PlotWork:
	if index < 0:
		return PlotWork.NONE
	var soil := state.plots[index]
	var day := progress.day
	if day == 2 and state.phase == 4 and index < 5:
		return VEGETABLE_WORK.get(soil, PlotWork.NONE)
	if day == 3 and state.phase == 2 and index < 5:
		return CABBAGE_CARE.get(soil, PlotWork.NONE)
	if day == 4 and state.phase == 5 and index >= 5 and index < 15:
		return RICE_WORK.get(soil, PlotWork.NONE)
	if day == 7 and state.phase == 3 and index >= 15:
		return VEGETABLE_WORK.get(soil, PlotWork.NONE)
	if day == 9 and state.phase == 0 and index >= 5 and soil == Soil.RIPE:
		return PlotWork.HARVEST
	if day in [5, 6, 7] and index >= 5 and index < 15 and soil == Soil.SPROUT:
		return PlotWork.WATER
	return PlotWork.NONE


func _plot_seed(index: int) -> String:
	if index < 5: return "cabbage_seed"
	if index < 15: return "rice_seed"
	if index < 30: return "corn_seed"
	return "amaranth_seed"


func _plot_produce(index: int) -> String:
	if index < 5: return "cabbage_produce"
	if index < 15: return "paddy"
	if index < 30: return "early_corn"
	return "amaranth"


func _work_plot(index: int) -> void:
	var day := progress.day
	var work := _plot_work(index)
	match work:
		PlotWork.HOE:
			var cost := 6 if day == 2 else (4 if day == 4 else 1)
			_till(index, cost)
		PlotWork.SOW:
			var cost := 5 if day == 2 else (2 if day == 4 else 1)
			if not _sow(index, _plot_seed(index), cost, Soil.WET if day == 4 else Soil.SOWN):
				return
			if day == 4:
				_plot_milestone("rice_sown", 10, "Đã gieo đủ 10 ô mạ. Có tiếng mèo ngoài hiên.")
			else:
				_changed()
		PlotWork.WATER:
			if not _water(index, 5 if day == 2 else 1, Soil.WET):
				return
			if day == 2 and state.advance("cabbage_wet") == 5:
				progress.arrival.stamina = 0
				_advance("Đã tưới 5 ô. Hoàng đói lả. Rương cứu trợ ở trong nhà.")
			elif day == 7 and index >= 15:
				_plot_milestone("field_wet", 25, "Đã gieo và tưới 25 ô. Gom 10 gỗ rồi đóng thùng cạnh cổng.")
			else:
				_changed()
		PlotWork.FLOOD_FIRST, PlotWork.FLOOD_SECOND:
			if _water(index, 2, Soil.DAMP if work == PlotWork.FLOOD_FIRST else Soil.FLOODED):
				_changed()
		PlotWork.SPRAY, PlotWork.WEED:
			if _spend(5):
				if work == PlotWork.SPRAY:
					state.give("worm", 1)
				state.plots[index] = Soil.SPROUT
				_changed("Đã xịt sâu và nhặt sâu béo." if work == PlotWork.SPRAY else "Đã nhổ cỏ tận gốc.")
		PlotWork.FERTILIZE:
			if state.quantity("npk") > 0 and _spend(4):
				state.give("npk", -1)
				state.plots[index] = Soil.RIPE
				_changed("NPK làm cải lớn ngay. Nhấn E để thu hoạch.")
		PlotWork.HARVEST:
			if not _harvest(index, _plot_produce(index), 1 if day == 3 else 2, 2):
				return
			if day == 3:
				_plot_milestone("cabbage_cut", 5, "Đã thu 5 cải ngọt. Dọn ba khúc gỗ trước chuồng.")
			else:
				_plot_milestone("harvest", 35, "Đã thu vụ lớn. Tìm hòn đá phủ rêu ở góc sân phía tây.")


func _plot_milestone(key: String, total: int, text: String) -> void:
	if state.advance(key) == total:
		_advance(text)
	else:
		_changed()


func _till(index: int, cost: int) -> void:
	if _spend(cost):
		state.plots[index] = Soil.TILLED
		_changed("Đã cuốc tơi đất.")


func _sow(index: int, item: String, cost: int, result: int) -> bool:
	if state.quantity(item) == 0 or not _spend(cost):
		return false
	state.give(item, -1)
	state.plots[index] = result
	_note("Đã gieo %s." % _item(item).to_lower())
	return true


func _water(index: int, cost: int, result: int) -> bool:
	if state.water == 0:
		_note("Bình hết nước. Múc tại giếng ở cuối vườn.")
		return false
	if not _spend(cost):
		return false
	state.water -= 1
	state.plots[index] = result
	sound.play_effect(&"water")
	_note("Đã tưới. Bình còn %d/10." % state.water)
	return true


func _harvest(index: int, item: String, amount: int, cost: int) -> bool:
	if not _spend(cost):
		return false
	state.plots[index] = Soil.HARVESTED
	state.give(item, amount)
	sound.play_effect(&"harvest")
	_note("Thu %s ×%d." % [_item(item), amount])
	return true


func _stove() -> void:
	if progress.day == 6 and state.phase == 2:
		const COST := {"stone": 5, "wood": 3}
		if not state.has_cost(COST):
			_note("Cần 5 đá cuội và 3 gỗ tạp. Gỗ có ở rìa vườn.")
			return
		var taps := state.advance("stove_taps")
		sound.play_effect(&"anvil")
		if taps == 3:
			state.pay(COST)
			state.advance("stove")
			_advance("Đã sửa bếp. Mở bếp để xem nguyên liệu nấu canh.")
		else:
			_changed("Đã trát bếp %d/3 lượt." % taps)
	elif state.count("stove") > 0:
		_open_recipes()
	else:
		_note("Bếp củi cũ đã long gạch. Chờ bác thợ mộc tới chỉ cách sửa.")


func _open_recipes() -> void:
	_open_card("Sổ tay nội trợ", "Chọn món ở bếp củi. Sau khi nấu, nhấn R để ăn. Thóc còn vỏ cần giã trước khi nấu cơm.")
	for item: String in RECIPES:
		var cost: Dictionary = RECIPES[item]
		var ingredients: Array[String] = []
		for ingredient: String in cost:
			ingredients.append("%s %d/%d" % [_item(ingredient), state.quantity(ingredient), cost[ingredient]])
		_option("%s · %s" % [_item(item), ", ".join(ingredients)], _cook.bind(item), state.has_cost(cost))


func _cook(item: String) -> void:
	if not state.pay(RECIPES[item]):
		return
	state.give(item, 1)
	if progress.day == 6 and state.phase == 3 and item == "cabbage_soup":
		_advance("Canh cá cải ngọt đã chín. Nhấn R để ăn.")
	else:
		_changed("Đã nấu %s." % _item(item).to_lower())
	_close_card()


func _open_barter() -> void:
	_open_card("Đổi hàng với Chị Thảo", "Mỗi phần đổi được 15 hạt ngô và 10 hạt rau dền. Xem phần hàng của mình trước khi chốt.")
	var offers := [{"pennywort": 4, "wood_ear": 3, "ground_cherry": 3}, {"pennywort": 3, "goby": 2, "wood_ear": 1}]
	for offer: Dictionary in offers:
		var details: Array[String] = []
		for item: String in offer:
			details.append("%s ×%d" % [_item(item), offer[item]])
		_option("Đổi " + " + ".join(details), _barter.bind(offer), state.has_cost(offer))


func _barter(offer: Dictionary) -> void:
	if state.phase != 2 or not state.pay(offer):
		return
	_reward({"corn_seed": 15, "amaranth_seed": 10})
	_close_card()
	_advance("Đã có giống. Giữ E khi đi qua luống để cuốc, gieo hoặc tưới dọc hàng.")


func _mill() -> void:
	if progress.day < 9:
		_note("Một hòn đá lớn phủ rêu.")
		return
	if progress.day == 9 and state.phase == 1:
		if state.count("moss") == 0:
			state.advance("moss")
			_changed("Lộ ra cối đá. Cần 2 gỗ để lắp chày.")
		elif state.pay({"wood": 2}):
			state.advance("mill")
			_advance("Cối hoạt động. Dùng 10 thóc và đạp chày đúng nhịp.")
		else:
			_note("Cần 2 gỗ để lắp chày.")
		return
	if state.count("mill") > 0 and state.has_cost({"paddy": 10}):
		arcade.open_mill()
	else:
		_note("Để giã một mẻ cần 10 thóc vàng trong túi.")


func _finish_mill() -> void:
	if not state.pay({"paddy": 10}):
		return
	_reward({"white_rice": 10, "rice_bran": 5})
	if progress.day == 9 and state.phase == 2:
		_advance("Giã được 10 gạo trắng và 5 cám. Kiểm kê kho trước khi ngủ.")
	else:
		_changed("Một mẻ cho 10 gạo trắng và 5 cám.")


func _shipping_bin() -> void:
	if progress.day == 7 and state.phase == 4:
		if state.pay({"wood": 10}):
			state.advance("bin")
			_advance("Đã đóng thùng. Đợi Trưởng thôn cho phép mới đưa hàng vào.")
			_show_notice("Thùng giao hàng", "Trưởng thôn dặn che thùng trước mưa. Giữ nông sản trong rương cho đến ngày đóng hàng.")
		else:
			_note("Cần 10 gỗ tạp. Gom thêm ở đống gỗ phía tây nam.")
	elif progress.day == 10 and state.phase in [1, 2]:
		_open_shipping()
	elif progress.day < 10:
		_note("Giữ nông sản trong nhà kho. Ngày 10 mới đóng hàng.")
	else:
		_note("Hàng đã giữ an toàn. Về nhà nghỉ để sáng mai kéo xe đi chợ.")


func _open_shipping() -> void:
	_open_card("Đóng hàng", "Dự kiến thu %d xu. Nhấn món để thêm một, hoặc gom hết hàng đủ điều kiện. Hàng cất trong kho có thể lấy lại trước khi canh thùng." % state.estimated_value())
	if state.estimated_value() > 0:
		_option("Chốt hàng và đợi tới 18:00", _prepare_defense)
	for item: String in TutorialChapter.MARKET_PRICES:
		var owned := state.quantity(item)
		if owned > 0:
			_option("Thêm 1 %s · Có %d" % [_item(item), owned], _pack.bind(item, 1))
	for item: String in state.crate:
		_option("Lấy lại 1 %s · Thùng có %d" % [_item(item), state.crate[item]], _unpack.bind(item))
	_option("Đưa tất cả hàng trong túi vào thùng", _pack_all)


func _pack(item: String, amount: int) -> void:
	state.transfer(item, state.bag, state.crate, amount)
	_changed()
	_open_shipping()


func _unpack(item: String) -> void:
	state.transfer(item, state.crate, state.bag, 1)
	_changed()
	_open_shipping()


func _pack_all() -> void:
	for item: String in TutorialChapter.MARKET_PRICES:
		state.transfer(item, state.bag, state.crate, state.quantity(item))
	_changed()
	_open_shipping()


func _prepare_defense() -> void:
	if state.estimated_value() == 0:
		return
	_close_card()
	state.phase = 2
	progress.minute_of_day = maxi(progress.minute_of_day, 18 * 60)
	_changed("Cậu Vàng sủa vang. Đàn chuột tiến tới thùng!")
	sound.play_effect(&"thunder")
	arcade.open_defense(state.count("dog_fed") > 0, state.count("cat") > 0)


func _finish_defense(won: bool) -> void:
	if not won:
		for item: String in state.crate:
			@warning_ignore("integer_division")
			state.crate[item] -= state.crate[item] / 2
		_changed("Thùng bị hỏng, mất một nửa mỗi chồng hàng. Có thể chuẩn bị và canh lại.")
		_show_notice("Thùng bị chuột phá", "Hàng còn lại vẫn ở thùng. Bổ sung từ kho nếu cần, rồi tương tác thùng để canh lại. Dùng F làm chậm trùm trước khi đánh búa.")
		return
	state.advance("defended")
	state.give("golden_rat_tooth", 1)
	progress.minute_of_day = maxi(progress.minute_of_day, 21 * 60)
	_advance("Đã hạ Chuột Cống Chúa. Nhặt Răng Chuột Vàng và về nghỉ.")
	_show_notice("Giữ được thùng hàng", "Lũ chuột bỏ chạy. Cậu Vàng nằm cạnh thùng, mèo cuộn mình trên nắp. Về giường ngủ để sáng mai kéo xe ra chợ.")


func _fuse_moved() -> void:
	if state.fuse_solved() and state.phase == 3 and not progress.arrival.power_on:
		progress.arrival.power_on = true
		progress.minute_of_day = maxi(progress.minute_of_day, 20 * 60)
		sound.play_effect(&"anvil")
		_advance("Mạch đã nối. Bóng đèn sáng sau %d lượt chuyển." % state.fuse_moves)
		_show_notice("Điện đã sáng", "Cạch! Bóng đèn phủ ánh vàng lên gian nhà. Đặt lại giường và ngủ để kết thúc ngày đầu.")
	else:
		_record()


func _offer_sleep() -> void:
	if not state.ready_to_sleep(progress.day):
		_note("Còn việc hôm nay: %s." % state.goal(progress.day).to_lower())
		return
	if progress.day == 1 and not progress.arrival.bed_ready:
		progress.arrival.bed_ready = true
		_changed("Đã đặt lại giường.")
	var ending := progress.day == TutorialChapter.LAST_DAY
	var body := "Hoàng đã giữ được thùng hàng. Ngủ để hoàn thành tutorial và kéo xe tới chợ vào sáng ngày 11." if ending else "Nghỉ để hồi thể lực và lưu tiến độ sang sáng mai."
	_open_card("Tổng kết ngày %d" % progress.day, body)
	_option("Ngủ và lưu", _sleep)


func _sleep() -> void:
	if not state.ready_to_sleep(progress.day) or not progress.arrival.bed_ready:
		return
	if progress.day == TutorialChapter.LAST_DAY:
		_finish_tutorial()
		return
	if state.count("fed_today") > 0:
		state.advance("eggs")
		state.counts.erase("fed_today")
	state.counts.erase("warm")
	progress.day += 1
	progress.minute_of_day = 300 if progress.day == 2 else 360
	progress.arrival.stamina = 10 if progress.day == 4 else 100
	progress.arrival.meal_bonus = 0
	state.phase = 0
	state.cell = Farmhouse.BED + Vector2i.DOWN
	character.position = MAP.feet(state.cell)
	if progress.day == 3:
		for index in 5:
			state.plots[index] = [Soil.PEST, Soil.PEST, Soil.WEEDS, Soil.WEEDS, Soil.SPROUT][index]
	if progress.day in [5, 6, 7, 8]:
		for index in range(5, 15):
			state.plots[index] = Soil.SPROUT
	if progress.day == 8:
		for index in range(15, 40):
			state.plots[index] = Soil.SPROUT
	if progress.day == 9:
		for index in range(5, 40):
			state.plots[index] = Soil.RIPE
	_close_card()
	_changed("Sáng ngày %d · %s" % [progress.day, TutorialChapter.TITLES[progress.day - 1]])
	_show_notice("Ngày %d · %s" % [progress.day, TutorialChapter.TITLES[progress.day - 1]], state.goal(progress.day) + ".")


func _finish_tutorial() -> void:
	if state.count("defended") == 0:
		return
	var next := GardenProgress.from_data(progress.to_data())
	if next == null:
		_note("Không đọc được tiến độ để sang ngày 11.")
		return
	next.chapter = null
	next.day = 11
	next.minute_of_day = GardenCalendar.START_MINUTE
	next.area = GardenProgress.Area.GARDEN
	next.tutorial_completed = true
	next.detailed_tutorial_completed = true
	next.arrival.rest()
	next.arrival.floor_cleared = true
	next.arrival.tools_taken = true
	next.arrival.cleared_weeds = (1 << GardenProgress.PLOT_CELLS.size()) - 1
	next.arrival.cat_home = state.count("cat") > 0
	next.arrival.dog_food = ArrivalProgress.DogFood.FED
	next.arrival.hen = ArrivalProgress.Hen.EGG_READY if state.count("eggs") > 0 or state.count("fed_today") > 0 else ArrivalProgress.Hen.EGG_COLLECTED
	next.arrival.caught_fish = state.count("caught") > 0
	next.arrival.cooked_meal = state.count("stove") > 0
	next.packed_tutorial_goods = state.crate.duplicate()
	next.start_summer_story(state)
	for source in [state.storage, state.bag]:
		for item: String in source:
			if TutorialChapter.MARKET_PRICES.has(item) or item in TutorialChapter.CARRY_ITEMS or item in ["wood", "pennywort"]:
				var target := SummerProgress.WOOD if item == "wood" else item
				next.inventory[target] = next.quantity(target) + int(source[item])
	if GardenProgress.from_data(next.to_data()) == null or GardenSave.write(next) != OK:
		_close_card()
		_note("Không lưu được ngày 11. Thử lại ở giường.")
		return
	var packed := load(GARDEN_SCENE) as PackedScene
	var garden := packed.instantiate()
	garden.progress = next
	garden.set("tutorial_handoff", true)
	get_tree().change_scene_to_node(garden)


func _travel(inside: bool) -> void:
	progress.area = GardenProgress.Area.HOUSE if inside else GardenProgress.Area.GARDEN
	state.cell = Farmhouse.ENTRANCE if inside else MAP.DOOR + Vector2i.DOWN
	facing = Vector2i.UP if inside else Vector2i.DOWN
	character.position = MAP.feet(state.cell)
	_changed()


func _refresh_region() -> void:
	if _inside():
		house.refresh(progress.arrival, false, progress.day, progress.summer.craft)
		house.stove_available = state.count("stove") > 0
		house.queue_redraw()
	else:
		house.hide()
	darkness.visible = _inside() and not progress.arrival.power_on
	if darkness.visible:
		_show_darkness()
	rain.visible = not _inside() and progress.is_raining(progress.day)
	sound.play_area(&"storm" if rain.visible else (&"recovery" if not _inside() else &""))
	_update_hud()


func _show_darkness() -> void:
	var shadow := darkness.material as ShaderMaterial
	shadow.set_shader_parameter("focus", character.position - Vector2(0, 20))


func _changed(text := "") -> void:
	if not text.is_empty():
		message = text
	_refresh_region()
	_record()


func _advance(text: String) -> void:
	state.phase += 1
	_changed(text)


func _record() -> void:
	if GardenSave.write(progress) != OK:
		_note("Không lưu được tiến độ. Thử lưu lại trước khi thoát.")


func _note(text: String) -> void:
	message = text
	_update_hud()


func _update_hud() -> void:
	status.text = "%s · Ngày %d · %d/100 thể lực%s%s" % [GardenCalendar.format_time(progress.minute_of_day), progress.day,
		progress.arrival.stamina, " (+%d)" % progress.arrival.meal_bonus if progress.arrival.meal_bonus > 0 else "",
		"   ·   Bình %d/10" % state.water if state.quantity("can") > 0 else ""]
	goals.text = state.goal(progress.day)
	var visitor_time: int = TutorialChapter.VISITOR_START.get(progress.day, 0)
	if state.phase == 0 and progress.minute_of_day < visitor_time:
		goals.text = "%s ghé sân lúc %s" % [TutorialChapter.VISITOR_NAMES[progress.day], GardenCalendar.format_time(visitor_time)]
	feedback.text = message
	if not walking or not walking.is_running():
		character.frame_coords = Vector2i(0, _pose())
	var target := state.cell + facing
	field.visitor_visible = _visitor_present()
	field.target = target if not _inside() and not _interaction_hint(target).is_empty() else Vector2i(-1, -1)
	field.active = _active_marker() if not _inside() else Vector2i(-1, -1)
	field.queue_redraw()
	indoor_pointer.queue_redraw()
	_update_target_prompt()


func _update_target_prompt() -> void:
	if _modal():
		target_prompt.hide()
		return
	var target := state.cell + facing
	var prompt := _interaction_hint(target)
	if prompt.is_empty():
		target_prompt.hide()
		return
	target_label.text = prompt
	target_prompt.reset_size()
	var extent := target_prompt.get_combined_minimum_size()
	var point := MAP.feet(target)
	target_prompt.position = Vector2(
		clampf(point.x - extent.x * 0.5, MAP.ORIGIN.x, MAP.ORIGIN.x + 640.0 - extent.x),
		maxf(MAP.ORIGIN.y, point.y - 56.0 - extent.y)
	).round()
	target_prompt.show()


func _interaction_hint(target: Vector2i) -> String:
	var day := progress.day
	var phase := state.phase
	if _inside():
		match target:
			Farmhouse.EXIT: return "[E] Ra sân"
			Farmhouse.SWITCH: return "[E] Sửa cầu dao" if day == 1 and phase == 3 else ""
			Farmhouse.BED:
				if state.ready_to_sleep(day):
					return "[E] Đặt lại giường" if not progress.arrival.bed_ready else "[E] Ngủ sang ngày mới"
				return "Hoàn tất việc hôm nay để ngủ"
			Farmhouse.CHEST: return "[E] Mở rương" if day >= 2 else ""
			Farmhouse.CLUTTER: return "[E] Dọn lối" if not progress.arrival.floor_cleared else ""
			Farmhouse.STOVE:
				if state.count("stove") > 0: return "[E] Mở sổ nấu ăn"
				return "[E] Sửa bếp" if day == 6 and phase == 2 else ""
		return ""
	match target:
		MAP.DOOR:
			return "Dọn cỏ sân trước khi vào nhà" if day == 1 and phase < 2 else "[E] Vào nhà"
		MAP.VISITOR:
			if not _visitor_present(): return ""
			return "[E] Đổi hàng với Chị Thảo" if day == 7 and phase == 2 else "[E] Trò chuyện với %s" % TutorialChapter.VISITOR_NAMES[day]
		MAP.GATE: return "[E] Mở cổng tre" if day == 2 and phase == 0 else ""
		MAP.SIGN: return "[E] Đọc biển của ông" if day == 2 and phase == 1 else ""
		MAP.WELL: return "[E] Múc nước" if state.quantity("can") > 0 else ""
		MAP.SHED: return _shed_hint()
		MAP.BIN:
			if day == 7 and phase == 4: return "[E] Đóng thùng hàng"
			return "[E] Kiểm hàng trong thùng" if day == 10 and phase in [1, 2] else ""
		MAP.FISHING: return "[E] Câu cá" if state.quantity("rod") > 0 else ""
		MAP.CAT:
			if not state.cat_present(day): return ""
			if day == 5 and phase == 3: return "[E] Cho mèo ăn cá"
			return "[E] Đeo vòng cổ" if day == 5 and phase == 4 else "[E] Gặp mèo"
		MAP.DOG:
			if day == 8 and phase == 1: return "[E] Dựng mái cho Cậu Vàng"
			if day == 8 and phase == 2: return "[E] Cho Cậu Vàng ăn"
			return "[E] Chào Cậu Vàng" if state.count("dog_fed") > 0 else ""
		MAP.COOP:
			if day == 4 and phase == 2: return "[E] Sửa chuồng gà"
			if day == 4 and phase == 3: return "[E] Thả đôi gà"
			return "[E] Nhặt trứng" if state.count("eggs") > 0 else ""
		MAP.TROUGH:
			return "[E] Cho gà ăn" if state.count("chickens") > 0 and state.count("fed_today") == 0 else ""
		MAP.WOODPILE: return "[E] Gom gỗ tạp" if day >= 3 and state.quantity("hammer") > 0 else ""
		MAP.MILL:
			if day == 9 and phase == 1:
				return "[E] Phát rêu trên cối" if state.count("moss") == 0 else "[E] Lắp chày"
			if state.count("mill") > 0:
				return "[E] Giã gạo" if state.quantity("paddy") >= 10 else "Cần 10 thóc để giã gạo"
	var gather := _gather_hint(target)
	return gather if not gather.is_empty() else _plot_hint(MAP.plot_at(target))


func _shed_hint() -> String:
	match [progress.day, state.phase]:
		[3, 0]: return "[E] Phá khóa nhà kho"
		[3, 1]: return "[E] Kiểm tra kệ đồ"
		[5, 0]: return "[E] Lấy vợt"
	return "[E] Mở kho" if progress.day >= 3 else ""


func _gather_hint(cell: Vector2i) -> String:
	match [progress.day, state.phase]:
		[1, 1]: return _uncollected_at(cell, MAP.COURT_GRASS, "yard", "[E] Phát cỏ")
		[2, 3]: return _uncollected_at(cell, MAP.GARDEN_GRASS, "garden", "[E] Phát cỏ")
		[3, 3]: return _uncollected_at(cell, MAP.LOGS, "log", "[E] Dọn gỗ mục")
		[5, 1]: return _uncollected_at(cell, MAP.REEDS, "reed", "[E] Vớt bèo")
		[6, 1]: return _uncollected_at(cell, MAP.ROCKS, "rock", "[E] Đập đá", 3)
		[7, 1], [7, 2]: return _uncollected_at(cell, MAP.FORAGE, "forage", "[E] Hái đồ ven vườn")
		[8, 3]:
			var snail := _uncollected_at(cell, MAP.SNAILS, "snail", "[E] Bắt ốc")
			return snail if not snail.is_empty() else _uncollected_at(cell, MAP.FROGS, "frog", "[Shift + E] Bắt ếch")
	return ""


func _uncollected_at(cell: Vector2i, cells: Array, key: String, prompt: String, hits := 1) -> String:
	var index := cells.find(cell)
	return prompt if index >= 0 and state.count(key + str(index)) < hits else ""


func _plot_hint(index: int) -> String:
	var work := _plot_work(index)
	if work in [PlotWork.WATER, PlotWork.FLOOD_FIRST, PlotWork.FLOOD_SECOND] and state.water == 0:
		return "Bình rỗng · Múc nước ở giếng"
	match work:
		PlotWork.HOE: return "[E] Cuốc đất"
		PlotWork.SOW:
			var seed := _plot_seed(index)
			return "[E] Gieo %s" % _item(seed).to_lower() if state.quantity(seed) > 0 else "Đã hết hạt giống"
		PlotWork.WATER: return "[E] Tưới nước"
		PlotWork.FLOOD_FIRST: return "[E] Tưới ruộng · Lượt 1/2"
		PlotWork.FLOOD_SECOND: return "[E] Tưới ruộng · Lượt 2/2"
		PlotWork.SPRAY: return "[E] Xịt sâu"
		PlotWork.WEED: return "[E] Nhổ cỏ"
		PlotWork.FERTILIZE:
			return "[E] Bón phân NPK" if state.quantity("npk") > 0 else "Đã hết phân NPK"
		PlotWork.HARVEST:
			return "[E] Gặt lúa" if _plot_produce(index) == "paddy" else "[E] Thu hoạch"
	return ""


func _active_marker() -> Vector2i:
	if state.phase == 0 and TutorialChapter.VISITOR_START.has(progress.day) and not _visitor_present():
		return Vector2i(-1, -1)
	match [progress.day, state.phase]:
		[1, 1]: return _uncollected(MAP.COURT_GRASS, "yard")
		[2, 3]: return _uncollected(MAP.GARDEN_GRASS, "garden")
		[2, 4]:
			var plot := _incomplete_plot(Vector2i(9, 3), Vector2i(5, 1), Soil.WET)
			return MAP.WELL if state.water == 0 and _plot_work(MAP.plot_at(plot)) == PlotWork.WATER else plot
		[3, 2]: return _incomplete_plot(Vector2i(9, 3), Vector2i(5, 1), Soil.HARVESTED)
		[3, 3]: return _uncollected(MAP.LOGS, "log")
		[4, 5]: return _incomplete_plot(MAP.RICE.position, MAP.RICE.size, Soil.WET)
		[5, 1]: return _uncollected(MAP.REEDS, "reed")
		[6, 1]: return _uncollected(MAP.ROCKS, "rock", 3)
		[7, 1]: return _uncollected(MAP.FORAGE, "forage")
		[7, 3]: return _incomplete_plot(MAP.FIELD.position, MAP.FIELD.size, Soil.WET)
		[8, 3]: return _uncollected(MAP.SNAILS, "snail") if state.count("snail") < MAP.SNAILS.size() else _uncollected(MAP.FROGS, "frog")
		[9, 0]:
			var rice := _incomplete_plot(MAP.RICE.position, MAP.RICE.size, Soil.HARVESTED)
			return rice if rice.x >= 0 else _incomplete_plot(MAP.FIELD.position, MAP.FIELD.size, Soil.HARVESTED)
	var markers := [
		[MAP.VISITOR, MAP.COURT_GRASS[0], MAP.DOOR, MAP.DOOR, MAP.DOOR],
		[MAP.GATE, MAP.SIGN, MAP.VISITOR, MAP.GARDEN_GRASS[0], MAP.WELL, MAP.DOOR, MAP.DOOR, MAP.DOOR],
		[MAP.SHED, MAP.SHED, MAP.GARDEN_GRASS[0], MAP.LOGS[0], MAP.DOOR],
		[MAP.VISITOR, MAP.VISITOR, MAP.COOP, MAP.COOP, MAP.TROUGH, MAP.RICE.position, MAP.CAT, MAP.DOOR],
		[MAP.SHED, MAP.REEDS[0], MAP.FISHING, MAP.CAT, MAP.CAT, MAP.DOOR],
		[MAP.VISITOR, MAP.ROCKS[0], MAP.DOOR, MAP.DOOR, MAP.DOOR, MAP.DOOR],
		[MAP.VISITOR, MAP.FORAGE[0], MAP.VISITOR, MAP.FIELD.position, MAP.BIN, MAP.DOOR],
		[MAP.VISITOR, MAP.DOG, MAP.DOG, MAP.SNAILS[0], MAP.SHED, MAP.DOOR],
		[MAP.RICE.position, MAP.MILL, MAP.MILL, MAP.SHED, MAP.DOOR],
		[MAP.VISITOR, MAP.BIN, MAP.BIN, MAP.DOOR],
	]
	return markers[progress.day - 1][state.phase]


func _uncollected(cells: Array, key: String, hits := 1) -> Vector2i:
	for index in cells.size():
		if state.count(key + str(index)) < hits:
			return cells[index]
	return Vector2i(-1, -1)


func _incomplete_plot(top: Vector2i, size: Vector2i, done: int) -> Vector2i:
	for y in size.y:
		for x in size.x:
			var cell := top + Vector2i(x, y)
			if state.plots[MAP.plot_at(cell)] != done:
				return cell
	return Vector2i(-1, -1)


func _draw_indoor_pointer() -> void:
	if not _inside():
		return
	var point := MAP.ORIGIN + Vector2((state.cell + facing) * MAP.CELL)
	if progress.day >= 2:
		var chest := MAP.feet(Farmhouse.CHEST) - Vector2(11, 21)
		indoor_pointer.draw_rect(Rect2(chest, Vector2(22, 16)), Color("694937"))
		indoor_pointer.draw_rect(Rect2(chest + Vector2(1, 1), Vector2(20, 6)), Color("9f6e49"))
		indoor_pointer.draw_rect(Rect2(chest + Vector2(9, 6), Vector2(4, 5)), Color("d8aa6d"))
	if not _interaction_hint(state.cell + facing).is_empty():
		indoor_pointer.draw_rect(Rect2(point + Vector2(1, 1), Vector2(30, 30)), Color("ffe3a4"), false, 2)
	var marker := Farmhouse.BED if state.ready_to_sleep(progress.day) else Farmhouse.EXIT
	if progress.day == 1 and state.phase == 3:
		marker = Farmhouse.SWITCH
	elif progress.day == 2 and state.phase == 5:
		marker = Farmhouse.CHEST
	elif progress.day == 6 and state.phase in [2, 3]:
		marker = Farmhouse.STOVE
	var arrow := MAP.feet(marker) - Vector2(0, 30)
	indoor_pointer.draw_colored_polygon(PackedVector2Array([arrow + Vector2(-5, -5), arrow + Vector2(5, -5), arrow + Vector2(0, 2)]), Color("ffd480"))


func _item(item: String) -> String:
	return TutorialChapter.ITEMS.get(item, item)


func _open_card(title: String, body: String) -> void:
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	menu_title.text = title
	menu_text.text = body
	card.get_parent().show()
	close_button.grab_focus()


func _option(text: String, action: Callable, enabled := true) -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 30
	button.disabled = not enabled
	choices.add_child(button)
	if action.is_valid():
		button.pressed.connect(action)
	if choices.get_child_count() == 1 and enabled:
		button.grab_focus()


func _show_notice(title: String, body: String) -> void:
	_open_card(title, body)
	_option("Tiếp tục", _close_card)


func _close_card() -> void:
	card.get_parent().hide()
	_update_hud()


func _open_bag(food_only: bool) -> void:
	_open_card("Đồ ăn" if food_only else "Túi của Hoàng", "Chọn món để hồi thể lực." if food_only else "Đồ nghề tự dùng khi tương tác đúng đối tượng. Chọn đồ ăn để hồi thể lực.")
	for item: String in state.bag:
		if not TutorialChapter.FOOD.has(item):
			if not food_only:
				_option("%s ×%d" % [_item(item), state.quantity(item)], Callable(), false)
			continue
		_option("Ăn %s ×%d · +%d thể lực" % [_item(item), state.quantity(item), TutorialChapter.FOOD[item]], _serve_food.bind(item))


func _open_storage() -> void:
	_open_card("Rương đồ", "Cất cả chồng từ túi hoặc lấy lại từ kho. Tới ngày 10 mới chuyển hàng sang thùng.")
	for item: String in state.storage:
		_option("Lấy %s ×%d" % [_item(item), state.storage[item]], _storage_move.bind(item, false))
	for item: String in state.bag:
		if TutorialChapter.MARKET_PRICES.has(item) or item in TutorialChapter.CARRY_ITEMS or item == "wood":
			_option("Cất %s ×%d" % [_item(item), state.quantity(item)], _storage_move.bind(item, true))


func _storage_move(item: String, store: bool) -> void:
	var source := state.bag if store else state.storage
	var destination := state.storage if store else state.bag
	state.transfer(item, source, destination, source.get(item, 0))
	_changed()
	_open_storage()


func _open_journal() -> void:
	_open_card("Ngày %d · %s" % [progress.day, TutorialChapter.TITLES[progress.day - 1]], "Dùng mũi tên vàng để tìm việc tiếp theo trên bản đồ.")
	var daily: Array = TutorialChapter.GOALS[progress.day - 1]
	for index in daily.size():
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = ("✓  " if index < state.phase else ("›  " if index == state.phase else "○  ")) + daily[index]
		choices.add_child(line)


func _return_to_title() -> void:
	_record()
	get_tree().change_scene_to_file("res://title.tscn")
