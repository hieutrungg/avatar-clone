class_name TutorialArcade
extends Control

signal milled
signal defended(won: bool)

const ARENA := Rect2(132, 153, 504, 234)
const BIN := Vector2(384, 261)
const SPAWNS := [Vector2(154, 193), Vector2(614, 205), Vector2(160, 354), Vector2(608, 358)]
const WAVES := [[0, 2, 1], [3, 0, 1, 2], [1, 3, 2]]
const PLAYER := preload("res://assets/art/32/hoang.png")

class Rat:
	var position: Vector2
	var hp: int
	var boss: bool
	var slowed := 0.0

	func _init(spot: Vector2, strong: bool) -> void:
		position = spot
		boss = strong
		hp = 5 if boss else 1

enum Mode { NONE, MILL, DEFENSE }
var mode := Mode.NONE
var beat := 0.0
var rhythm_hits := 0
var rhythm_message := ""
var player := BIN + Vector2(0, 64)
var rats: Array[Rat] = []
var wave := 0
var wave_index := 0
var next_spawn := 0.0
var bin_hp := 8
var swing := 0.0
var spray := 0.0
var support := 0.0
var guard_dog := false
var guard_cat := false


func _ready() -> void:
	size = Vector2(768, 480)
	mouse_filter = MOUSE_FILTER_STOP
	set_process(false)
	hide()


func open_mill() -> void:
	mode = Mode.MILL
	beat = 0.0
	rhythm_hits = 0
	rhythm_message = "Bấm E hoặc nhấp thanh đo khi chày vào vùng xanh."
	show()
	set_process(true)


func open_defense(dog: bool, cat: bool) -> void:
	mode = Mode.DEFENSE
	guard_dog = dog
	guard_cat = cat
	player = BIN + Vector2(0, 64)
	rats.clear()
	wave = 0
	wave_index = 0
	bin_hp = 8
	next_spawn = 0.85
	swing = 0.0
	spray = 0.0
	support = 4.0
	show()
	set_process(true)


func _input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == Mode.MILL:
			_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if mode == Mode.MILL:
			_strike_mill()
		else:
			_hammer()
		get_viewport().set_input_as_handled()
	elif mode == Mode.DEFENSE and event.is_action_pressed("fertilize"):
		_spray_rats()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mode == Mode.MILL and Rect2(172, 216, 424, 55).has_point(event.position):
			_strike_mill()
		elif mode == Mode.DEFENSE and ARENA.has_point(event.position):
			_hammer()
		accept_event()


func _process(delta: float) -> void:
	if mode == Mode.MILL:
		beat = fposmod(beat + delta * 0.84, 2.0)
	else:
		_update_defense(delta)
	queue_redraw()


func _cursor() -> float:
	return 1.0 - absf(beat - 1.0)


func _strike_mill() -> void:
	var distance := absf(_cursor() - 0.5)
	if distance > 0.20:
		rhythm_message = "Lệch nhịp. Canh lúc vạch trắng qua giữa."
		return
	if distance > 0.11:
		rhythm_message = "Gần đúng. Đợi vạch vào vùng xanh."
		return
	rhythm_hits += 1
	rhythm_message = "Thịch! Đúng nhịp."
	beat = 0.0
	if rhythm_hits >= 5:
		_close()
		milled.emit()


func _update_defense(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player = (player + movement * delta * 175.0).clamp(ARENA.position + Vector2(18, 21), ARENA.end - Vector2(18, 10))
	swing = maxf(0.0, swing - delta)
	spray = maxf(0.0, spray - delta)
	next_spawn -= delta
	if wave < WAVES.size() and wave_index < WAVES[wave].size() and next_spawn <= 0.0:
		var spawn: int = WAVES[wave][wave_index]
		rats.append(Rat.new(SPAWNS[spawn], wave == WAVES.size() - 1 and wave_index == WAVES[wave].size() - 1))
		wave_index += 1
		next_spawn = 0.65
	for index in range(rats.size() - 1, -1, -1):
		var rat := rats[index]
		rat.slowed = maxf(0.0, rat.slowed - delta)
		var speed := (31.0 if rat.boss else 47.0) * (0.32 if rat.slowed > 0 else 1.0)
		rat.position = rat.position.move_toward(BIN, speed * delta)
		if rat.position.distance_to(BIN) < 14.0:
			bin_hp -= 3 if rat.boss else 1
			if rat.boss:
				rat.position = BIN.lerp(SPAWNS[2], 0.40)
			else:
				rats.remove_at(index)
			if bin_hp <= 0:
				_close()
				defended.emit(false)
				return
	support -= delta
	if support <= 0.0 and not rats.is_empty():
		support = 3.8
		for index in rats.size():
			if rats[index].position.distance_to(BIN) <= 71.0:
				if guard_cat:
					rats[index].slowed = maxf(rats[index].slowed, 1.1)
				if guard_dog and not rats[index].boss:
					rats.remove_at(index)
				break
	if rats.is_empty() and wave_index == WAVES[wave].size():
		wave += 1
		wave_index = 0
		next_spawn = 0.9
		if wave == WAVES.size():
			_close()
			defended.emit(true)


func _hammer() -> void:
	if swing > 0.0:
		return
	swing = 0.34
	for index in range(rats.size() - 1, -1, -1):
		var rat := rats[index]
		if player.distance_to(rat.position) > 56.0:
			continue
		rat.hp -= 1
		if rat.hp == 0:
			rats.remove_at(index)


func _spray_rats() -> void:
	if spray > 0.0:
		return
	spray = 2.6
	for rat in rats:
		if player.distance_to(rat.position) < 100.0:
			rat.slowed = 2.0


func _close() -> void:
	mode = Mode.NONE
	set_process(false)
	hide()


func _draw() -> void:
	if mode == Mode.NONE:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.07, 0.88))
	draw_rect(Rect2(115, 82, 538, 350), Color("3d332a"))
	draw_rect(Rect2(117, 84, 534, 346), Color("a37a55"), false, 2)
	if mode == Mode.MILL:
		draw_string(font, Vector2(150, 122), "NHỊP CHÀY QUÊ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f5d08b"))
		draw_string(font, Vector2(150, 160), "10 thóc vàng → 10 gạo trắng và 5 cám gạo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e7d1ae"))
		draw_rect(Rect2(174, 225, 420, 23), Color("8d493b"))
		draw_rect(Rect2(300, 225, 168, 23), Color("c29653"))
		draw_rect(Rect2(338, 225, 92, 23), Color("6a9c66"))
		draw_rect(Rect2(172 + 420 * _cursor(), 219, 4, 35), Color("fff5da"))
		draw_string(font, Vector2(150, 299), "%d / 5 nhịp đúng" % rhythm_hits, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("f5d08b"))
		draw_string(font, Vector2(150, 331), rhythm_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7d1ae"))
		draw_string(font, Vector2(150, 402), "E · Đạp chày    Esc · Quay lại", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e7d1ae"))
		return
	draw_string(font, Vector2(142, 118), "BẢO VỆ THÙNG HÀNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("f5d08b"))
	draw_string(font, Vector2(142, 141), "Đợt %d / %d    ·    Độ bền thùng %d / 8" % [wave + 1, WAVES.size(), bin_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f0dec3"))
	draw_rect(ARENA, Color("313c36"))
	var paving := Rect2(240, 189, 288, 170)
	draw_rect(paving, Color("54403b"))
	for y in range(190, 355, 11):
		draw_line(Vector2(240, y), Vector2(527, y), Color("4b3935"))
		for x in range(248 + (y % 2) * 9, 526, 20):
			draw_line(Vector2(x, y), Vector2(x, y + 10), Color("4b3935"))
	draw_circle(Vector2(600, 178), 13, Color("dc9c76"))
	draw_circle(Vector2(597, 177), 9, Color("e5ac86"))
	draw_rect(Rect2(BIN - Vector2(15, 14), Vector2(30, 28)), Color("bd8951"))
	draw_rect(Rect2(BIN - Vector2(12, 4), Vector2(24, 3)), Color("604c36"))
	if swing > 0.19:
		draw_arc(player, 54, 0, TAU, 30, Color("f6bf79"), 2)
	if spray > 2.35:
		draw_arc(player, 96, 0, TAU, 36, Color("a6c9a8"), 2)
	draw_texture_rect_region(PLAYER, Rect2(player - Vector2(16, 36), Vector2(32, 48)), Rect2(0, 0, 32, 48))
	for rat in rats:
		var radius := 14.0 if rat.boss else 8.0
		var color := Color("cb7c63") if rat.boss else Color("a6a098")
		if rat.slowed > 0.0:
			color = color.lerp(Color("97ba8a"), 0.55)
		var center := rat.position
		var tail := (center - BIN).normalized()
		draw_line(center, center + tail * (radius + 7), color.darkened(0.24), 2)
		draw_circle(center, radius, color)
		draw_circle(center - Vector2(radius * 0.4, radius * 0.7), radius * 0.4, color.lightened(0.15))
		draw_circle(center + Vector2(radius * 0.4, -radius * 0.7), radius * 0.4, color.lightened(0.15))
		draw_rect(Rect2(center - Vector2(4, 1), Vector2(2, 2)), Color("382b2c"))
		draw_rect(Rect2(center + Vector2(3, -1), Vector2(2, 2)), Color("382b2c"))
		if rat.boss:
			draw_rect(Rect2(center - Vector2(14, 22), Vector2(rat.hp * 5, 3)), Color("f3b77b"))
	draw_string(font, Vector2(142, 409), "WASD · Di chuyển    E · Búa tạ    F · Xịt chậm", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f0dec3"))
