class_name TutorialFusePanel
extends Control

signal moved
signal closed

const PANEL := Rect2(136, 68, 496, 344)
const PEG_X := [239, 384, 529]
const BASE := 325
const COLORS := [Color("83bca2"), Color("ebc387"), Color("d7865b")]

var chapter: TutorialChapter
var selected := -1
var pressed_peg := -1
var was_selected := false
var feedback := "Chọn trục có lõi sứ, rồi chọn trục đích."


func _ready() -> void:
	size = Vector2(768, 480)
	mouse_filter = MOUSE_FILTER_STOP
	hide()


func open(state: TutorialChapter) -> void:
	chapter = state
	selected = -1
	pressed_peg = -1
	feedback = "Chọn trục có lõi sứ, rồi chọn trục đích."
	show()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		hide()
		closed.emit()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
		_choose(event.physical_keycode - KEY_1)
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var peg := _peg_at(event.position)
	if event.pressed:
		pressed_peg = peg
		was_selected = selected >= 0
		if peg >= 0 and not was_selected:
			_choose(peg)
	elif peg >= 0 and pressed_peg >= 0 and (peg != pressed_peg or was_selected):
		_choose(peg)
		pressed_peg = -1
	accept_event()


func _peg_at(point: Vector2) -> int:
	if point.y < 171 or point.y > 347:
		return -1
	for index in PEG_X.size():
		if absf(point.x - PEG_X[index]) < 67:
			return index
	return -1


func _choose(peg: int) -> void:
	if selected == -1:
		if chapter.top_fuse(peg) < 0:
			feedback = "Trục này đang trống."
		else:
			selected = peg
			feedback = "Chọn trục đích cho lõi trên cùng."
	elif selected == peg:
		selected = -1
		feedback = "Đã đặt lõi xuống."
	elif chapter.move_fuse(selected, peg):
		selected = -1
		feedback = "Đã chuyển lõi."
		if chapter.fuse_solved():
			hide()
		moved.emit()
	else:
		feedback = "Lõi lớn không thể đặt lên lõi nhỏ."
	queue_redraw()


func _draw() -> void:
	if chapter == null:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.07, 0.06, 0.77))
	draw_rect(PANEL, Color("3e2e25"))
	draw_rect(PANEL.grow(-4), Color("a4794f"), false, 2)
	draw_string(font, Vector2(158, 108), "THÁP CẦU CHÌ SỨ", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ffe0a3"))
	draw_string(font, Vector2(158, 134), "Chuyển cả ba lõi sang trục C để đóng mạch.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f1dec4"))
	draw_string(font, Vector2(158, 157), "Chỉ chuyển lõi trên cùng. Lõi nhỏ phải ở trên lõi lớn.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d9bb98"))
	for peg in PEG_X.size():
		var x: int = PEG_X[peg]
		var ink := Color("edbc79") if peg == selected else Color("aa704a")
		draw_rect(Rect2(x - 64, 173, 128, 173), Color("60432d") if peg == selected else Color("352720"))
		draw_rect(Rect2(x - 3, 202, 6, BASE - 202), ink)
		draw_rect(Rect2(x - 52, BASE, 104, 4), ink)
		var level := 0
		for disk in [2, 1, 0]:
			if chapter.fuses[disk] != peg:
				continue
			var width: int = [36, 64, 94][disk]
			var y := BASE - 23 - level * 24
			var lifted: bool = selected == peg and chapter.top_fuse(peg) == disk
			if lifted:
				y -= 7
			var ceramic := Rect2(x - width / 2.0, y, width, 21)
			var color := COLORS[disk] as Color
			draw_rect(ceramic, color.darkened(0.22))
			draw_rect(ceramic.grow(-3), color)
			draw_rect(Rect2(ceramic.position + Vector2(4, 3), Vector2(width - 8, 3)), color.lightened(0.35))
			level += 1
		var peg_label: String = ["A · 1", "B · 2", "C · 3"][peg]
		draw_string(font, Vector2(x - 19, 193), peg_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffdb9c"))
	draw_string(font, Vector2(158, 368), feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffda99"))
	draw_string(font, Vector2(158, 394), "Tháp Hà Nội · Bấm hoặc kéo thả · Esc để rời", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d9bb98"))
	draw_string(font, Vector2(548, 394), "%d lượt" % chapter.fuse_moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d9bb98"))
