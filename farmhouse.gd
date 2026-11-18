class_name Farmhouse
extends Node2D

const FLOOR := Rect2i(5, 3, 10, 6)
const ENTRANCE := Vector2i(10, 8)
const EXIT := Vector2i(10, 9)
const TOOLS := Vector2i(8, 8)
const CLUTTER := Vector2i(10, 5)
const SWITCH := Vector2i(13, 2)
const PANTRY := Vector2i(11, 2)
const BED := Vector2i(6, 4)
const STOVE := Vector2i(14, 2)
const CUPBOARD := Vector2i(7, 2)
const CHEST := Vector2i(6, 2)
const RADIO := Vector2i(10, 2)
const PIPE_SHELF := Vector2i(5, 3)
const SUMMER_ART := preload("res://assets/art/32/summer_props.png")
const AUTUMN_ART := preload("res://assets/art/32/autumn_work.png")

var arrival: ArrivalProgress
var pantry_available := false
var stove_available := false
var day := 1
var craft: SummerCraft
var summer_story: SummerStory


func refresh(state: ArrivalProgress, yard_open: bool, current_day: int, craft_state: SummerCraft = null) -> void:
	arrival = state
	pantry_available = yard_open and state.dog_food == ArrivalProgress.DogFood.PANTRY
	day = current_day
	craft = craft_state
	stove_available = day >= ArrivalProgress.COOKING_DAY
	show()
	queue_redraw()


func can_walk(cell: Vector2i) -> bool:
	return FLOOR.has_point(cell) and cell != BED and (
		cell != CLUTTER or arrival.floor_cleared
	) and (cell != TOOLS or arrival.tools_taken) and (day < SummerProgress.PUMP_DAY or cell != PIPE_SHELF)


func is_interactive(cell: Vector2i) -> bool:
	return cell in [SWITCH, BED, EXIT] or (
		cell == CLUTTER and not arrival.floor_cleared
	) or (cell == TOOLS and not arrival.tools_taken) or (cell == PANTRY and pantry_available) or (
		cell == STOVE and stove_available
	) or (cell == CUPBOARD and day >= SummerProgress.LETTER_DAY) or (
		cell in [CHEST, RADIO] and day >= SummerProgress.RAIN_DAY
	) or (cell == PIPE_SHELF and day >= SummerProgress.PUMP_DAY) or (cell == VillageSocial.PHONE and day >= VillageSocial.MESSAGE_DAY)


func mill_visible() -> bool:
	return day >= VillageFestival.ORDER_DAY


func _draw() -> void:
	if arrival == null:
		return
	var corner := FLOOR.position * PixelArt.CELL
	var size_px := FLOOR.size * PixelArt.CELL
	var wood := ["#9f704b", "#ab7a52", "#b78558", "#a87650"] if arrival.power_on else [
		"#755741", "#806044", "#88684a", "#7b5b43",
	]
	_paint(corner.x - 6, corner.y - 38, size_px.x + 12, size_px.y + 44, "#2f2926")
	_paint(corner.x, corner.y - 32, size_px.x, 32, "#bc986c" if arrival.power_on else "#82745e")
	_paint(corner.x, corner.y - 12, size_px.x, 12, "#624534")
	for row in range(floori(size_px.y / 8.0)):
		var y := corner.y + row * 8
		_paint(corner.x, y, size_px.x, 7, wood[row % wood.size()])
		_paint(corner.x, y + 7, size_px.x, 1, "#503c31")
		for x in range(corner.x + 18 + (row % 3) * 15, corner.x + size_px.x, 52):
			_paint(x, y, 1, 7, "#674935")

	# Window, sunlight, and the wall lamp run along the north wall.
	_paint(230, 68, 47, 28, "#5a4234")
	_paint(234, 71, 39, 20, "#89bac1")
	_paint(234, 84, 39, 7, "#729b56")
	_paint(253, 71, 2, 20, "#5a4234")
	draw_colored_polygon(PackedVector2Array([
		Vector2(234, 96), Vector2(273, 96), Vector2(302, 155), Vector2(243, 155),
	]), Color(Color("#fff2b3"), 0.15))
	if arrival.power_on:
		draw_circle(Vector2(344, 78), 18.0, Color(Color("#ffeaa0"), 0.18))
	_paint(337, 70, 14, 4, "#71513a")
	_paint(335, 74, 18, 7, "#ffe49d" if arrival.power_on else "#a68f67")
	_paint(422, 72, 19, 19, "#514737")
	_paint(425, 74, 13, 15, "#bdac8d")
	_paint(429, 76 if arrival.power_on else 82, 5, 5, "#598253" if arrival.power_on else "#824d3f")
	_paint(355, 84, 26, 9, "#513a2e")
	_paint(356, 84, 24, 4, "#a87950")
	if pantry_available:
		draw_texture(preload("res://assets/art/32/dog_food.png"), Vector2(352, 56))
	if stove_available:
		draw_texture_rect_region(preload("res://assets/art/32/tutorial_props.png"),
			Rect2(Vector2(STOVE * PixelArt.CELL), Vector2(32, 32)), Rect2(96, 0, 32, 32))
	if summer_story != null and summer_story.done("kitchen_basket"):
		draw_texture_rect_region(SUMMER_ART, Rect2(Vector2(445, 90), Vector2(22, 22)), Rect2(128, 0, 32, 32))
	if day >= SummerProgress.LETTER_DAY:
		_draw_prop(CUPBOARD, 5)
	if day >= SummerProgress.RAIN_DAY:
		_draw_prop(CHEST, 5)
		_draw_prop(RADIO, 7)
	if day >= SummerProgress.PUMP_DAY:
		_draw_prop(PIPE_SHELF, 5)
	if mill_visible():
		var mill := FestivalMap.MILL * PixelArt.CELL
		_paint(mill.x + 6, mill.y + 16, 21, 11, "#686e64")
		_paint(mill.x + 8, mill.y + 12, 17, 6, "#a1ab96")
		_paint(mill.x + 15, mill.y + 5, 4, 11, "#986947")
	if day >= VillageSocial.MESSAGE_DAY:
		var phone := VillageSocial.PHONE * PixelArt.CELL
		_paint(phone.x + 4, phone.y + 20, 24, 7, "#956347")
		_paint(phone.x + 11, phone.y + 9, 10, 15, "#373a42")
		_paint(phone.x + 12, phone.y + 11, 8, 10, "#9ab5a9")
	if craft != null:
		var atlas := preload("res://assets/art/32/summer_craft.png")
		if craft.needle:
			draw_texture_rect_region(atlas, Rect2(Vector2(SummerMap.EMBROIDERY * 32), Vector2(32, 32)), Rect2(224, 0, 32, 32))
		if craft.tank:
			draw_texture_rect_region(atlas, Rect2(Vector2(SummerMap.AQUARIUM * 32), Vector2(32, 32)), Rect2(64, 0, 32, 32))
			if craft.tank_fish:
				var point := Vector2(SummerMap.AQUARIUM * 32) + Vector2(7, 6)
				draw_texture_rect_region(atlas, Rect2(point, Vector2(18, 18)), Rect2(128, 0, 32, 32))
		elif summer_story != null and summer_story.purchases.has("tank"):
			var tank := Vector2(SummerMap.AQUARIUM * 32)
			draw_texture_rect_region(atlas, Rect2(tank, Vector2(32, 32)), Rect2(64, 0, 32, 32))
			if summer_story.done("goby_tank"):
				draw_texture_rect_region(preload("res://assets/art/32/fish.png"), Rect2(tank + Vector2(7, 6), Vector2(18, 18)), Rect2(0, 0, 32, 32))

	# Rug and door mat.
	_paint(295, 185, 83, 50, "#684137")
	_paint(298, 188, 77, 44, "#9d5e45" if arrival.power_on else "#855544")
	for y in [192, 198, 221, 227]:
		_paint(302, y, 69, 2, "#d09a60")
	_paint(320, 271, 32, 20, "#503c31")
	_paint(322, 273, 28, 15, "#987452")
	for x in range(325, 350, 5):
		_paint(x, 274, 1, 13, "#cfaa72")

	_draw_bed()
	if not arrival.tools_taken:
		_paint(260, 273, 23, 11, "#624333")
		_paint(262, 268, 19, 12, "#a17149")
		_paint(267, 263, 8, 7, "#704933")
		_paint(269, 265, 4, 4, "#c28c58")
		_paint(262, 273, 19, 2, "#d6a065")
	if not arrival.floor_cleared:
		_paint(323, 176, 26, 12, "#70523d")
		_paint(327, 163, 17, 18, "#9a7650")
		_paint(330, 162, 12, 3, "#caa175")
		_paint(326, 169, 20, 2, "#523e33")
		_paint(345, 174, 7, 8, "#b4aa87")
	if day >= AutumnWork.INVEST_DAY:
		var origin := Vector2(AutumnWork.LEDGER * 32)
		_paint(int(origin.x) + 1, int(origin.y) + 16, 30, 15, "#785438")
		draw_texture_rect_region(AUTUMN_ART, Rect2(origin, Vector2(32, 32)), Rect2(64, 0, 32, 32))


func _draw_bed() -> void:
	_paint(193, 119, 31, 41, "#594034")
	_paint(196, 120, 25, 37, "#86603e")
	_paint(196, 126, 25, 25, "#638369" if arrival.bed_ready else "#77694f")
	if arrival.bed_ready:
		_paint(200, 123, 17, 10, "#e7d9b7")
		for y in [139, 144, 149]:
			_paint(196, y, 25, 1, "#a6b38b")
	else:
		_paint(199, 135, 20, 4, "#b4a181")
		_paint(202, 140, 17, 5, "#96826a")
	_paint(194, 153, 29, 4, "#a87d54")


func _paint(x: int, y: int, width: int, height: int, hex: String) -> void:
	draw_rect(Rect2(x, y, width, height), Color(hex))


func _draw_prop(cell: Vector2i, frame: int) -> void:
	draw_texture_rect_region(SUMMER_ART, Rect2(Vector2(cell * 32), Vector2(32, 32)), Rect2(frame * 32, 0, 32, 32))
