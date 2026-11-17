class_name FestivalPanel
extends Panel

signal name_saved(value: String)
signal mill_done
signal dish_chosen(dish: int, plating: int)
signal match_finished(wins: int)
signal training_finished
signal reply_chosen(reply: int)
signal lan_choice_chosen(reply: int)

enum Mode { NAME, MILL, COOKING, WRESTLING, TRAINING, PHONE, LAN }
const EXERCISES := ["Đứng lên ngồi xuống", "Xách nước", "Đẩy xe cút kít"]
const ROUND_TARGETS := [4, 5, 5]
const ROUND_LIMITS := [6, 7, 7]
const GUARD := ["LRRLLR", "RLLRRLR", "LRLRRLL"]

var mode := Mode.NAME
var title: Label
var instructions: Label
var entry: LineEdit
var choices: OptionButton
var styles: OptionButton
var main: Button
var left: Button
var right: Button
var meter: ProgressBar
var rounds := 0
var wins := 0
var moves := 0
var push := 0


func _ready() -> void:
	theme = preload("res://farm_ui.tres")
	position = Vector2(103, 63)
	size = Vector2(562, 352)
	var layout := VBoxContainer.new()
	layout.position = Vector2(24, 15)
	layout.size.x = 514
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	title = Label.new()
	title.add_theme_font_size_override("font_size", 31)
	layout.add_child(title)
	instructions = Label.new()
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size.y = 52
	instructions.add_theme_font_size_override("font_size", 20)
	layout.add_child(instructions)
	entry = LineEdit.new()
	entry.max_length = VillageFestival.NAME_LIMIT
	entry.placeholder_text = "Tên gà con"
	entry.text_submitted.connect(func(_value: String) -> void: _submit())
	layout.add_child(entry)
	choices = OptionButton.new()
	choices.item_selected.connect(_dish_changed)
	layout.add_child(choices)
	styles = OptionButton.new()
	for style in ["Bày giản dị", "Xếp cân đối", "Trang trí quanh đĩa"]:
		styles.add_item(style)
	layout.add_child(styles)
	meter = ProgressBar.new()
	meter.show_percentage = false
	meter.custom_minimum_size.y = 20
	layout.add_child(meter)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)
	main = _button(buttons, "Xác nhận", _submit)
	left = _button(buttons, "Đẩy trái", _wrestle.bind("L"))
	right = _button(buttons, "Đẩy phải", _wrestle.bind("R"))
	_button(buttons, "Đóng", hide)
	hide()


func _button(parent: Node, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(106, 42)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _open(view: Mode, heading: String, body: String, label: String) -> void:
	mode = view
	title.text = heading
	instructions.text = body
	entry.visible = view == Mode.NAME
	choices.visible = view in [Mode.COOKING, Mode.PHONE, Mode.LAN]
	styles.hide()
	meter.visible = view in [Mode.MILL, Mode.WRESTLING, Mode.TRAINING]
	main.visible = view != Mode.WRESTLING
	left.visible = view == Mode.WRESTLING
	right.visible = view == Mode.WRESTLING
	main.text = label
	show()


func open_name(current: String) -> void:
	_open(Mode.NAME, "Đặt tên gà con", "Chị Lan muốn biết bạn sẽ gọi gà con là gì.", "Lưu tên")
	entry.text = current
	entry.grab_focus()


func open_mill() -> void:
	_open(Mode.MILL, "Giã cám bằng cối đá", "Giã đủ 5 nhịp để lấy hai phần cám mịn.", "Giã cám")
	meter.max_value = 5
	meter.value = 0
	main.grab_focus()


func open_cooking(current: int, at_festival: bool) -> void:
	_open(Mode.COOKING, "Món thi hội làng" if at_festival else "Chuẩn bị món thi", "", "Nộp món" if at_festival else "Chọn món")
	styles.visible = at_festival
	styles.select(0)
	choices.clear()
	for dish in VillageFestival.DISH_NAMES:
		choices.add_item(dish)
	choices.select(maxi(0,current))
	_dish_changed(choices.selected)
	choices.grab_focus()


func _dish_changed(index: int) -> void:
	if mode != Mode.COOKING:
		return
	instructions.text = "Nguyên liệu · %s. %s" % [
		VillageFestival.DISH_HINTS[index], "Chọn cách bày rồi nộp món." if styles.visible else "Nguyên liệu được dùng khi nộp món ở đình.",
	]


func open_training() -> void:
	_open(Mode.TRAINING, "Buổi tập với Chú Thắng", "", "Tập")
	rounds = 0
	meter.max_value = 10
	meter.value = 0
	_show_exercise()
	main.grab_focus()


func _show_exercise() -> void:
	instructions.text = "%s · Bài %d/3\nHoàn thành 10 nhịp rồi đổi bài." % [EXERCISES[rounds], rounds + 1]


func open_phone() -> void:
	_open(Mode.PHONE, "Tin nhắn từ sếp cũ", "Hoàng, dự án mới bắt đầu tháng tới. Em có về nghe một buổi được không?", "Gửi trả lời")
	choices.clear()
	for reply in VillageSocial.RESPONSES:
		choices.add_item(reply)
	choices.select(0)
	choices.grab_focus()


func open_lan() -> void:
	_open(Mode.LAN, "Chị Lan ghé nhà", "Anh tính ở đây lâu không?", "Trả lời")
	choices.clear()
	for reply in ["Chị hỏi thế là sao?", "Anh chưa quyết định.", "Anh muốn ở lại lâu."]:
		choices.add_item(reply)
	choices.select(0)
	choices.grab_focus()


func open_wrestling() -> void:
	_open(Mode.WRESTLING, "Đấu vật sân đình", "", "")
	rounds = 0
	wins = 0
	moves = 0
	push = 0
	_show_guard()
	left.grab_focus()


func _show_guard() -> void:
	var guard: String = GUARD[rounds]
	var exposed := "trái" if guard[moves] == "L" else "phải"
	instructions.text = "Hiệp %d/3 · Thắng %d hiệp\nĐối thủ hở bên %s. Đẩy về phía đó." % [rounds + 1, wins, exposed]
	meter.max_value = ROUND_TARGETS[rounds]
	meter.value = push


func _wrestle(direction: String) -> void:
	if mode != Mode.WRESTLING or not visible:
		return
	var guard: String = GUARD[rounds]
	push = maxi(0, push + (1 if direction == guard[moves] else -1))
	moves += 1
	if push == int(ROUND_TARGETS[rounds]) or moves == int(ROUND_LIMITS[rounds]):
		wins += int(push == int(ROUND_TARGETS[rounds]))
		rounds += 1
		if rounds == 3:
			hide()
			match_finished.emit(wins)
			return
		moves = 0
		push = 0
	_show_guard()


func _submit() -> void:
	match mode:
		Mode.NAME:
			if entry.text.strip_edges().is_empty():
				return
			hide()
			name_saved.emit(entry.text)
		Mode.MILL:
			meter.value += 1
			if meter.value == meter.max_value:
				hide()
				mill_done.emit()
		Mode.COOKING:
			dish_chosen.emit(choices.selected, styles.selected if styles.visible else -1)
		Mode.TRAINING:
			if not visible:
				return
			meter.value += 1
			if meter.value == meter.max_value:
				rounds += 1
				if rounds == EXERCISES.size():
					hide()
					training_finished.emit()
				else:
					meter.value = 0
					_show_exercise()
		Mode.PHONE:
			if choices.selected >= 0:
				hide()
				reply_chosen.emit(choices.selected + 1)
		Mode.LAN:
			if choices.selected >= 0:
				hide()
				lan_choice_chosen.emit(choices.selected + 1)
