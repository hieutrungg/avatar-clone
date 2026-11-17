class_name EmbroideryPanel
extends Panel

signal finished(pattern: String, flower: bool)
signal advanced_finished(motif: int)

const PALETTE := [Color("#ede5cc"), Color("#ae5563"), Color("#55786d"), Color("#c88e4b")]
const FLOWER := "00000000" + "00110000" + "01331000" + "00111000" + "00200000" + "02220000" + "00200000" + "00000000"
const ADVANCED := [
	"00000220" + "00002300" + "00002000" + "02022000" + "00221200" + "00011100" + "00001020" + "00001100",
	"00020000" + "00212000" + "02131200" + "23111320" + "02212200" + "00020000" + "00222000" + "00020000",
]
const STITCH_GLYPHS := ["", "━", "╱", "○"]

var heading: Label
var summary: Label
var grid: GridContainer
var colors: OptionButton
var stitches: OptionButton
var action: Button
var flower := false
var stitching := false
var pattern: Array[int] = []
var sewn: Array[bool] = []
var press_cell := -1
var motif := -1


func _ready() -> void:
	theme = preload("res://farm_ui.tres")
	position = Vector2(96, 21)
	size = Vector2(576, 438)
	var layout := VBoxContainer.new()
	layout.position = Vector2(20, 8)
	layout.size.x = 536
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 27)
	layout.add_child(heading)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 17)
	summary.custom_minimum_size.y = 43
	layout.add_child(summary)
	colors = OptionButton.new()
	colors.add_theme_font_size_override("font_size", 17)
	for name in ["Tẩy ô", "Chỉ đỏ", "Chỉ xanh", "Chỉ vàng"]:
		colors.add_item(name)
	layout.add_child(colors)
	stitches = OptionButton.new()
	stitches.add_theme_font_size_override("font_size", 17)
	for name in ["━ Mũi thẳng", "╱ Mũi chéo", "○ Mũi vòng"]:
		stitches.add_item(name)
	layout.add_child(stitches)
	var center := CenterContainer.new()
	layout.add_child(center)
	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	center.add_child(grid)
	for index in 64:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(32, 30)
		tile.add_theme_font_size_override("font_size", 17)
		tile.pressed.connect(_press_tile.bind(index))
		tile.gui_input.connect(_tile_input.bind(index))
		grid.add_child(tile)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	layout.add_child(buttons)
	action = Button.new()
	action.pressed.connect(_next)
	buttons.add_child(action)
	var close := Button.new()
	close.text = "Đóng"
	close.pressed.connect(hide)
	buttons.add_child(close)
	hide()


func open_project(make_flower: bool) -> void:
	motif = -1
	flower = make_flower
	stitching = flower
	press_cell = -1
	colors.select(1)
	pattern.resize(64)
	pattern.fill(0)
	sewn.resize(64)
	sewn.fill(false)
	if flower:
		for i in 64:
			pattern[i] = int(FLOWER[i])
	_refresh()
	show()
	if stitching:
		(grid.get_child(pattern.find(1)) as Button).grab_focus()
	else:
		colors.grab_focus()


func open_advanced(index: int) -> void:
	motif = index
	stitching = true
	flower = false
	stitches.select(0)
	pattern.resize(64)
	sewn.resize(64)
	sewn.fill(false)
	for cell in 64:
		pattern[cell] = int(ADVANCED[index][cell])
	_refresh()
	show()
	stitches.grab_focus()


func _press_tile(index: int) -> void:
	if stitching:
		if pattern[index] != 0 and (motif < 0 or pattern[index] == stitches.selected + 1):
			sewn[index] = true
	else:
		pattern[index] = colors.selected
	_refresh()


func _tile_input(event: InputEvent, index: int) -> void:
	if motif >= 0 or not stitching or not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		press_cell = index
	elif press_cell == index and pattern[index] != 0:
		var tile := grid.get_child(index) as Button
		var local_position: Vector2 = event.position
		var horizontal := local_position.x < -3 or local_position.x > tile.size.x + 3
		var vertical := local_position.y < -3 or local_position.y > tile.size.y + 3
		if horizontal != vertical:
			sewn[index] = true
		press_cell = -1
		_refresh()


func _refresh() -> void:
	heading.text = "Thêu %s" % AutumnWork.MOTIFS[motif].to_lower() if motif >= 0 else (
		"Khăn thêu hoa" if flower else ("Thêu mũi thẳng" if stitching else "Vẽ mẫu miếng thêu đầu tiên")
	)
	colors.visible = not stitching
	stitches.visible = motif >= 0
	var total := 0
	var count := 0
	for index in 64:
		var tile := grid.get_child(index) as Button
		var color := pattern[index]
		if color != 0:
			total += 1
			count += int(sewn[index])
		var ink: Color = PALETTE[color]
		var pending := stitching and not sewn[index] and color != 0
		tile.text = STITCH_GLYPHS[color] if motif >= 0 else ("·" if pending else ("━" if color != 0 else ""))
		tile.disabled = stitching and color == 0
		var fill := ink.lerp(PALETTE[0], 0.68) if pending else ink
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		tile.add_theme_stylebox_override("normal", style)
		tile.add_theme_color_override("font_color", Color("#493b39") if pending else Color("#f5e9cc"))
	summary.text = "Chọn màu rồi tô ô. Có thể tẩy trước khi thêu." if not stitching else "Chọn lần lượt các ô đánh dấu để kéo mũi thêu. %d/%d mũi." % [count, total]
	if motif >= 0:
		summary.text = "Chọn mũi thêu rồi chọn các ô cùng ký hiệu. %d/%d mũi." % [count, total]
	action.text = "Hoàn thành" if stitching else "Sang bước thêu"
	action.disabled = total == 0 or (stitching and count != total)


func _next() -> void:
	if action.disabled or not visible:
		return
	if not stitching:
		stitching = true
		_refresh()
		return
	if motif >= 0:
		hide()
		advanced_finished.emit(motif)
		return
	var output := ""
	for color in pattern:
		output += str(color)
	hide()
	finished.emit(output, flower)
