class_name SummerWorkshop
extends Panel

signal basket_finished(errors: int, solo: bool)
signal sprinkler_finished(index: int)
signal construction_requested
signal bamboo_split(thickness: int)
signal mat_finished(errors: int)

const SIDE := 4
const PATTERNS := [
	"1010010110100101",
	"1001011010010110",
	"1100101001010011",
]
const PIPE_START := Vector2i(0, 2)
const PIPE_END := Vector2i(6, 2)
const OBSTACLES := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3)]
const PIPE_BUDGET := 8
const MAT_PATTERN := "1100110011001100001100110011001111001100110011000011001100110011"

var heading: Label
var instructions: Label
var sample: GridContainer
var board: GridContainer
var submit: Button
var help_button: Button
var placement: OptionButton
var thickness: HSlider
var pipe_mode := false
var build_mode := false
var solo := false
var mat := false
var story_pipes := false
var stage := 0
var hints := 0
var total_errors := 0
var weave: Array[int] = []
var pipe_cells: Dictionary[Vector2i, bool] = {}


func _ready() -> void:
	theme = preload("res://farm_ui.tres")
	position = Vector2(62, 24)
	size = Vector2(644, 432)
	var content := VBoxContainer.new()
	content.position = Vector2(20, 10)
	content.size.x = 604
	add_child(content)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 29)
	content.add_child(heading)
	instructions = Label.new()
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.custom_minimum_size.y = 51
	content.add_child(instructions)
	thickness = HSlider.new()
	thickness.min_value = 0
	thickness.max_value = 100
	thickness.step = 5
	thickness.custom_minimum_size.y = 36
	thickness.value_changed.connect(_show_thickness)
	content.add_child(thickness)
	thickness.hide()
	placement = OptionButton.new()
	placement.add_theme_font_size_override("font_size", 18)
	for name in ["Vườn · Luống trái", "Vườn · Luống giữa", "Vườn · Luống phải", "Ven ao · Dãy trái", "Ven ao · Dãy phải"]:
		placement.add_item(name)
	content.add_child(placement)
	var tables := HBoxContainer.new()
	tables.alignment = BoxContainer.ALIGNMENT_CENTER
	tables.add_theme_constant_override("separation", 30)
	content.add_child(tables)
	sample = GridContainer.new()
	board = GridContainer.new()
	tables.add_child(sample)
	tables.add_child(board)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	content.add_child(controls)
	help_button = Button.new()
	help_button.custom_minimum_size.x = 105
	help_button.pressed.connect(_help)
	controls.add_child(help_button)
	submit = Button.new()
	submit.custom_minimum_size.x = 137
	submit.pressed.connect(_submit)
	controls.add_child(submit)
	var close := Button.new()
	close.text = "Đóng"
	close.custom_minimum_size.x = 78
	close.pressed.connect(hide)
	controls.add_child(close)
	hide()


func open_basket(alone: bool) -> void:
	thickness.hide()
	mat = false
	build_mode = false
	pipe_mode = false
	solo = alone
	stage = 0
	total_errors = 0
	_reset_weave()
	show()
	(board.get_child(0) as Button).grab_focus()


func open_split() -> void:
	build_mode = false
	pipe_mode = false
	mat = false
	placement.hide()
	sample.hide()
	board.hide()
	help_button.hide()
	heading.text = "Chẻ nan tre"
	thickness.value = 70
	_show_thickness(thickness.value)
	thickness.show()
	submit.disabled = false
	submit.text = "Chẻ tre"
	submit.show()
	show()
	thickness.grab_focus()


func _show_thickness(value: float) -> void:
	instructions.text = "Độ dày %d%% · Cụ Hai khuyên giữ từ 20%% đến 60%% để nan vừa tay." % int(value)


func open_mat() -> void:
	open_basket(true)
	mat = true
	_reset_weave()
	(board.get_child(0) as Button).grab_focus()


func open_pipes(current: int, heirloom_plots: bool, detailed := false) -> void:
	thickness.hide()
	board.show()
	build_mode = false
	pipe_mode = true
	story_pipes = detailed
	pipe_cells.clear()
	for index in placement.item_count:
		placement.set_item_text(index, "Vườn sau · Cụm 9 ô số %d" % (index + 1) if detailed else ["Vườn · Luống trái", "Vườn · Luống giữa", "Vườn · Luống phải", "Ven ao · Dãy trái", "Ven ao · Dãy phải"][index])
	placement.set_item_disabled(3, not (heirloom_plots or detailed))
	placement.set_item_disabled(4, not (heirloom_plots or detailed))
	placement.select(maxi(0, current))
	heading.text = "Nối ống ra vòi tưới"
	instructions.text = "Dùng 3 đoạn ống, mỗi đoạn dài 2 ô, và 4 đầu nối. Bấm ô để đặt đường ống, rồi chạy thử." if detailed else "Nối giếng đến vòi theo bốn hướng. Chọn ô để đặt hoặc gỡ ống, tối đa 8 đoạn."
	placement.show()
	sample.hide()
	board.columns = 7
	_build_buttons(board, 35, Vector2(49, 38), true)
	help_button.text = "Chạy thử"
	help_button.show()
	_update_pipe_buttons()
	show()
	placement.grab_focus()


func open_construction(progress: GardenProgress, feedback := "") -> void:
	thickness.hide()
	board.show()
	build_mode = true
	pipe_mode = false
	placement.hide()
	help_button.hide()
	sample.hide()
	board.columns = 4
	_build_buttons(board, 12, Vector2(72, 51), true)
	var state := progress.summer
	heading.text = "Mở rộng chuồng gà"
	var titles := ["Xác nhận bản vẽ", "Đóng khung · %d/4" % state.coop_work,
		"Lắp vách · %d/4" % state.coop_work, "Lợp mái và đặt ổ", "Chuồng cấp 2"]
	instructions.text = feedback if not feedback.is_empty() else (
		progress.coop_materials() if state.coop_step == 0 else (
			"Rơm khô %d/%d · Nhặt ở đống rơm cạnh chuồng." % [progress.quantity(SummerProgress.STRAW), SummerProgress.COOP_STRAW] if state.coop_step == 3 else
			"%s · Chọn ô sáng để thi công." % titles[state.coop_step] if state.coop_step in [1, 2] else "Chuồng đã có vách tre, mái rơm và máng hai ngày."
		)
	)
	var panels := [2, 3, 6, 7]
	for index in 12:
		var tile := board.get_child(index) as Button
		var work_index := panels.find(index)
		var active := state.coop_step in [1, 2] and work_index == state.coop_work
		tile.disabled = not active
		var filled := state.coop_step >= 3 or (state.coop_step in [1, 2] and work_index < state.coop_work)
		var label := "Chuồng" if index in [0, 1, 4, 5] else ("Sân" if work_index < 0 else ("✓" if filled else "+"))
		_paint(tile, label, Color("#f4dda2") if active else Color("#a99471"))
	submit.visible = state.coop_step not in [1, 2]
	submit.disabled = state.coop_step == 4
	submit.text = titles[state.coop_step]
	show()
	if state.coop_step in [1, 2]:
		(board.get_child(panels[state.coop_work]) as Button).grab_focus()
	elif state.coop_step < 4:
		submit.grab_focus()


func _reset_weave() -> void:
	hints = 0
	weave.resize(64 if mat else 16)
	weave.fill(-1)
	heading.text = "Đan nong phơi · 8 × 8" if mat else ("Tự đan rổ tre" if solo else "Đan rổ với Cụ Hai · %d/3" % (stage + 1))
	instructions.text = "Chọn ô để đổi nan. Ngang hiện sáng, dọc hiện tối." if not solo else "Nhớ mẫu đáy rổ hôm qua. Ba ô đầu làm gợi ý."
	placement.hide()
	sample.show()
	board.show()
	sample.columns = 8 if mat else SIDE
	board.columns = sample.columns
	var tile := Vector2(28, 30) if mat else Vector2(44, 49)
	_build_buttons(sample, weave.size(), tile, false)
	_build_buttons(board, weave.size(), tile, true)
	help_button.text = "Gợi ý"
	help_button.disabled = false
	help_button.show()
	submit.text = "Hoàn thành" if solo or stage == 2 else "Qua vòng"
	submit.show()
	_update_weave_buttons()


func _build_buttons(grid: GridContainer, count: int, extent: Vector2, interactive: bool) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for index in count:
		var tile := Button.new()
		tile.custom_minimum_size = extent
		tile.focus_mode = Control.FOCUS_ALL if interactive else Control.FOCUS_NONE
		if interactive:
			tile.pressed.connect(_toggle.bind(index))
		else:
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(tile)


func _toggle(index: int) -> void:
	if build_mode:
		if not (board.get_child(index) as Button).disabled:
			construction_requested.emit()
	elif pipe_mode:
		var cell := Vector2i(index % 7, floori(index / 7.0))
		if pipe_cells.has(cell):
			pipe_cells.erase(cell)
		elif pipe_cells.size() < (6 if story_pipes else PIPE_BUDGET):
			pipe_cells[cell] = true
		_update_pipe_buttons()
	else:
		weave[index] = (weave[index] + 1) % 2
		_update_weave_buttons()


func _update_weave_buttons() -> void:
	var pattern: String = MAT_PATTERN if mat else PATTERNS[stage]
	for index in weave.size():
		var reveal: bool
		if mat:
			reveal = index < 16 or index < 16 + hints * 8
		elif solo:
			reveal = index in [0, 1, 4] or (hints > 0 and index < 3 + hints * 2)
		else:
			reveal = stage == 0 or (stage == 1 and index < 8 + hints * 2) or index in [0, 1, 4, 5] or index < hints * 3
		var symbol := "━" if pattern[index] == "1" else "┃"
		_paint(sample.get_child(index), symbol if reveal else "?", Color("#eac988") if reveal else Color("#7c8674"))
		var value := weave[index]
		_paint(board.get_child(index), "·" if value < 0 else ("━" if value == 1 else "┃"),
			Color("#eac988") if value == 1 else Color("#a68868"))
	submit.disabled = weave.has(-1)


func _paint(tile: Button, label: String, color: Color) -> void:
	tile.text = label
	tile.add_theme_color_override("font_color", color)


func _reachable() -> Array[Vector2i]:
	var queue: Array[Vector2i] = [_pipe_start()]
	var reached: Array[Vector2i] = [_pipe_start()]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if (pipe_cells.has(next) or next == _pipe_end()) and next not in reached:
				queue.append(next)
				reached.append(next)
	return reached


func _pipe_start() -> Vector2i:
	return Vector2i(0, 1) if story_pipes else PIPE_START


func _pipe_end() -> Vector2i:
	return Vector2i(5, 3) if story_pipes else PIPE_END


func _update_pipe_buttons() -> void:
	var reached := _reachable()
	for index in 35:
		var tile := board.get_child(index) as Button
		var cell := Vector2i(index % 7, floori(index / 7.0))
		var obstacles := [Vector2i(2, 1), Vector2i(4, 2), Vector2i(2, 3)] if story_pipes else OBSTACLES
		tile.disabled = cell in obstacles or cell in [_pipe_start(), _pipe_end()]
		var label := "·"
		if cell in obstacles: label = "×"
		elif cell == _pipe_start(): label = "Giếng"
		elif cell == _pipe_end(): label = "Vòi"
		elif pipe_cells.has(cell):
			var horizontal := _has_pipe(cell + Vector2i.LEFT) or _has_pipe(cell + Vector2i.RIGHT)
			var vertical := _has_pipe(cell + Vector2i.UP) or _has_pipe(cell + Vector2i.DOWN)
			label = "┼" if horizontal and vertical else ("━" if horizontal else ("┃" if vertical else "●"))
		_paint(tile, label, Color("#89d6d0") if cell in reached else Color("#b49a71"))
	submit.text = "Lắp cố định"
	submit.show()
	submit.disabled = _pipe_end() not in reached
	help_button.disabled = false


func _has_pipe(cell: Vector2i) -> bool:
	return cell == _pipe_start() or cell == _pipe_end() or pipe_cells.has(cell)


func _help() -> void:
	if pipe_mode:
		instructions.text = "Nước đã đến vòi. Có thể lắp cố định." if _pipe_end() in _reachable() else "Nước chưa đến vòi. Hãy nối liền các ô xanh từ giếng đến vòi."
	else:
		hints += 1
		help_button.disabled = hints >= 3
		_update_weave_buttons()


func _submit() -> void:
	if thickness.visible:
		hide()
		bamboo_split.emit(int(thickness.value))
		return
	if build_mode:
		if not submit.disabled:
			construction_requested.emit()
		return
	if pipe_mode:
		if _pipe_end() in _reachable():
			hide()
			sprinkler_finished.emit(placement.selected)
		return
	if weave.has(-1):
		return
	if mat:
		for i in weave.size():
			total_errors += int(str(weave[i]) != MAT_PATTERN[i])
		hide()
		mat_finished.emit(total_errors)
		return
	for i in 16:
		total_errors += int(str(weave[i]) != PATTERNS[stage][i])
	if not solo and stage < 2:
		stage += 1
		_reset_weave()
		(board.get_child(0) as Button).grab_focus()
	else:
		hide()
		basket_finished.emit(total_errors, solo)
