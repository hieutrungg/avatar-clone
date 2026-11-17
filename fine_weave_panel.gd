class_name FineWeavePanel
extends Panel

signal finished(product: int, rank: int)

const ROUNDS := 4
const CENTERS := [0.52, 0.40, 0.64, 0.51]

var title: Label
var instructions: Label
var feedback: Label
var meter: ProgressBar
var mark: ColorRect
var product := 0
var stitch := 0
var points := 0
var stage := 0
var elapsed := 0.0
var was_held := false


func _ready() -> void:
	theme = preload("res://farm_ui.tres")
	position = Vector2(78, 111)
	size = Vector2(612, 280)
	var layout := VBoxContainer.new()
	layout.position = Vector2(25, 16)
	layout.size.x = 562
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 30)
	layout.add_child(title)
	instructions = Label.new()
	instructions.add_theme_font_size_override("font_size", 22)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size.y = 54
	layout.add_child(instructions)
	meter = ProgressBar.new()
	meter.max_value = 1.0
	meter.step = 0.001
	meter.show_percentage = false
	meter.custom_minimum_size.y = 26
	layout.add_child(meter)
	mark = ColorRect.new()
	mark.color = Color("#ebd99b")
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(mark)
	feedback = Label.new()
	layout.add_child(feedback)
	var close := Button.new()
	close.text = "Dừng đan [Esc]"
	close.pressed.connect(hide)
	layout.add_child(close)
	hide()


func open(product_index: int) -> void:
	product = product_index
	stitch = 0
	points = 0
	stage = 0
	elapsed = 0
	was_held = Input.is_action_pressed("interact")
	title.text = "Đan khít · %s" % AutumnWork.WEAVES[product]
	_refresh()
	show()


func tick(delta: float) -> void:
	var held := Input.is_action_pressed("interact")
	if stage == 0:
		elapsed = fposmod(elapsed + delta / 1.4, 1.0)
		meter.value = elapsed
		if held and not was_held:
			points += int(absf(elapsed - CENTERS[stitch]) <= 0.12)
			stage = 1
			elapsed = 0.0
			_refresh()
	elif stage == 1:
		if not held:
			stage = 2
	elif held:
		elapsed += delta
		meter.value = minf(elapsed, 1.0)
	elif was_held:
		points += int(elapsed >= 0.35 and elapsed <= 0.68)
		stitch += 1
		if stitch == ROUNDS:
			hide()
			finished.emit(product, 2 if points >= 7 else (1 if points >= 4 else 0))
			return
		stage = 0
		elapsed = 0.0
		_refresh()
	was_held = held


func _refresh() -> void:
	meter.value = 0
	if stage == 0:
		instructions.text = "Nan %d/%d · Bấm E khi thanh chạm vạch để luồn nan." % [stitch + 1, ROUNDS]
		mark.position = Vector2(562 * CENTERS[stitch] - 2, 0)
		mark.size = Vector2(4, 26)
	else:
		instructions.text = "Nhả E, rồi giữ E cho đến vùng vàng và nhả để nén nan."
		mark.position = Vector2(562 * 0.35, 8)
		mark.size = Vector2(562 * (0.68 - 0.35), 10)
	feedback.text = "Nhịp chuẩn %d/%d" % [points, ROUNDS * 2]
