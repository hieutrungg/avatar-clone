class_name TutorialFarmMap
extends Node2D

const CELL := 32
const ORIGIN := Vector2(64, 80)
const FIELD := Rect2i(9, 4, 5, 5)
const RICE := Rect2i(13, 9, 5, 2)
const POND := Rect2i(15, 4, 4, 4)
const HOUSE := Rect2i(3, 2, 3, 2)
const DOOR := Vector2i(4, 3)
const VISITOR := Vector2i(7, 4)
const GATE := Vector2i(8, 5)
const SIGN := Vector2i(9, 2)
const WELL := Vector2i(13, 1)
const SHED := Vector2i(10, 1)
const COOP := Vector2i(6, 9)
const TROUGH := Vector2i(7, 9)
const CAT := Vector2i(2, 7)
const BIN := Vector2i(7, 6)
const DOG := Vector2i(7, 5)
const MILL := Vector2i(2, 4)
const WOODPILE := Vector2i(2, 9)
const FISHING := Vector2i(18, 7)
const COURT_GRASS := [Vector2i(2, 5), Vector2i(3, 5), Vector2i(5, 5), Vector2i(6, 5),
	Vector2i(2, 6), Vector2i(3, 6), Vector2i(5, 6), Vector2i(6, 6), Vector2i(3, 7), Vector2i(6, 7)]
const GARDEN_GRASS := [Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3),
	Vector2i(10, 4), Vector2i(14, 3), Vector2i(14, 4), Vector2i(14, 7), Vector2i(12, 9)]
const LOGS := [Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8)]
const ROCKS := [Vector2i(14, 2), Vector2i(16, 2), Vector2i(17, 3), Vector2i(16, 8), Vector2i(11, 9)]
const REEDS := [Vector2i(15, 4), Vector2i(16, 4), Vector2i(17, 4), Vector2i(15, 5), Vector2i(15, 6)]
const FORAGE := [Vector2i(12, 1), Vector2i(17, 8), Vector2i(2, 3)]
const SNAILS := [Vector2i(9, 8), Vector2i(11, 8), Vector2i(13, 8), Vector2i(9, 7), Vector2i(10, 8)]
const FROGS := [Vector2i(13, 2), Vector2i(14, 6), Vector2i(17, 8)]

const TERRAIN := preload("res://assets/art/32/terrain.png")
const HOUSE_ART := preload("res://assets/art/32/farmhouse.png")
const TREES := preload("res://assets/art/32/props.png")
const CROPS := preload("res://assets/art/32/crops.png")
const RICE_ART := preload("res://assets/art/32/sticky_rice.png")
const CORN := preload("res://assets/art/32/corn.png")
const GREENS := preload("res://assets/art/32/rau_muong.png")
const PROPS := preload("res://assets/art/32/tutorial_props.png")
const TOOLS := preload("res://assets/art/32/quiet_farm.png")
const PEOPLE := preload("res://assets/art/32/nguoi_hang_xom.png")
const VILLAGERS := preload("res://assets/art/32/village_people.png")
const DOG_ART := preload("res://assets/art/32/cau_vang.png")
const CAT_ART := preload("res://assets/art/32/hoang_thuong.png")

var progress: GardenProgress
var target := Vector2i(-1, -1)
var active := Vector2i(-1, -1)
var visitor_visible := false


static func feet(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell * CELL) + Vector2(16, 32)


static func plot_at(cell: Vector2i) -> int:
	if cell.y == 3 and cell.x >= 9 and cell.x <= 13:
		return cell.x - 9
	if RICE.has_point(cell):
		return 5 + cell.x - RICE.position.x + (cell.y - RICE.position.y) * RICE.size.x
	if FIELD.has_point(cell):
		return 15 + cell.x - FIELD.position.x + (cell.y - FIELD.position.y) * FIELD.size.x
	return -1


func _draw() -> void:
	if progress == null or progress.chapter == null or progress.area == GardenProgress.Area.HOUSE:
		return
	var state := progress.chapter
	for y in 12:
		for x in 20:
			var cell := Vector2i(x, y)
			var tile := Rect2(ORIGIN + Vector2(cell * CELL), Vector2(32, 32))
			if POND.has_point(cell):
				_draw_pond(tile, cell)
			elif x >= 2 and x <= 7 and y >= 4 and y <= 7:
				_draw_brick(tile, cell)
			else:
				var variant := (y * 19 + x * 13) % 11
				var path := x == 4 and y > 7 or y == 5 and x in [8, 9]
				var frame := 1 if path else (5 + variant % 3 if variant < 5 else 0)
				_tile(TERRAIN, frame, tile.position)
			var index := plot_at(cell)
			if index >= 0:
				_draw_plot(tile.position, index, state.plots[index])
	for y in range(1, 11):
		if y == GATE.y and state.count("gate") > 0:
			continue
		var point := ORIGIN + Vector2(8 * CELL, y * CELL)
		draw_rect(Rect2(point + Vector2(12, 1), Vector2(5, 31)), Color("8f6c46"))
		draw_rect(Rect2(point + Vector2(17, 0), Vector2(2, 32)), Color("564632"))
		draw_rect(Rect2(point + Vector2(9, 4), Vector2(11, 4)), Color("c79a5a"))
	draw_texture(HOUSE_ART, feet(DOOR) - Vector2(56, 63))
	_building(SHED, Color("866043"), Color("4b3d33"))
	_building(COOP, Color("ac784a") if state.count("coop") > 0 else Color("71654e"), Color("6b4935"))
	_tile(PROPS, 1, feet(TROUGH) - Vector2(16, 32))
	_tile(PROPS, 6, feet(SIGN) - Vector2(16, 32))
	for tree in [Vector2i(1, 2), Vector2i(18, 2), Vector2i(1, 10)]:
		draw_texture_rect_region(TREES, Rect2(feet(tree) - Vector2(32, 64), Vector2(64, 64)), Rect2(128, 0, 64, 64))
	var well := feet(WELL) - Vector2(0, 12)
	draw_circle(well, 12, Color("434843"))
	draw_circle(well - Vector2(0, 3), 11, Color("9d9c86"))
	draw_circle(well - Vector2(0, 3), 7, Color("497582"))
	_objects(COURT_GRASS, "yard", 0, progress.day <= 1)
	_objects(GARDEN_GRASS, "garden", 0, state.count("gate") > 0)
	_objects(LOGS, "log", 1, progress.day > 1)
	_objects(ROCKS, "rock", 2, state.count("gate") > 0, 3)
	_objects(REEDS, "reed", 3, state.count("gate") > 0)
	if progress.day == 7 and state.phase in [1, 2]:
		_objects(FORAGE, "forage", 4, true)
	if progress.day == 8:
		_objects(SNAILS, "snail", 5, state.phase >= 3)
		_objects(FROGS, "frog", 6, state.phase >= 3)
	if visitor_visible:
		var sheet := VILLAGERS if progress.day in [2, 7] else PEOPLE
		var frame := 0 if progress.day in [2, 7] else 1
		_character(sheet, frame, VISITOR, 48)
	if state.cat_present(progress.day):
		_character(CAT_ART, 0, CAT, 32)
	if state.count("dog") > 0:
		if state.count("shelter") > 0:
			_building(DOG, Color("9f654c"), Color("654537"), 19)
		_character(DOG_ART, 0, DOG, 32)
	if state.count("bin") > 0:
		draw_texture_rect_region(TREES, Rect2(feet(BIN) - Vector2(23, 46), Vector2(46, 46)), Rect2(64, 0, 64, 64))
	if state.count("chickens") > 0:
		for p in [Vector2i(5, 9), Vector2i(5, 10)]:
			var point := feet(p) - Vector2(0, 7)
			draw_rect(Rect2(point - Vector2(7, 3), Vector2(11, 8)), Color("e8c289"))
			draw_rect(Rect2(point + Vector2(2, -7), Vector2(6, 7)), Color("fff0cd"))
			draw_rect(Rect2(point + Vector2(5, -9), Vector2(3, 3)), Color("b84e39"))
	if state.count("mill") > 0 or state.count("moss") > 0:
		draw_rect(Rect2(feet(MILL) - Vector2(11, 16), Vector2(22, 13)), Color("64736a"))
		draw_rect(Rect2(feet(MILL) - Vector2(13, 20), Vector2(26, 5)), Color("a7a991"))
		if state.count("mill") > 0:
			draw_line(feet(MILL) - Vector2(14, 28), feet(MILL) - Vector2(-9, 18), Color("ab7d4e"), 4)
	if progress.is_raining(progress.day):
		draw_rect(Rect2(ORIGIN, Vector2(640, 384)), Color(0.21, 0.32, 0.45, 0.22))
	elif progress.minute_of_day >= 18 * 60:
		draw_rect(Rect2(ORIGIN, Vector2(640, 384)), Color(0.18, 0.12, 0.31, 0.21))
	if target.x >= 0:
		draw_rect(Rect2(ORIGIN + Vector2(target * CELL) + Vector2(1, 1), Vector2(30, 30)), Color("ffe3a4"), false, 2)
	if active.x >= 0 and active != target:
		var point := feet(active) - Vector2(0, 30)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-5, -5), point + Vector2(5, -5), point + Vector2(0, 2)]), Color("ffd480"))


func _draw_brick(tile: Rect2, cell: Vector2i) -> void:
	draw_rect(tile, Color("9e634d" if (cell.x + cell.y) % 3 == 0 else "ab6e53"))
	for y in [0, 8, 16, 24]:
		draw_rect(Rect2(tile.position + Vector2(0, y), Vector2(32, 1)), Color("7e4e42"))
		var inset := 8 if y % 16 == 0 else 0
		for x in range(inset, 32, 16):
			draw_rect(Rect2(tile.position + Vector2(x, y), Vector2(1, 8)), Color("865141"))


func _draw_pond(tile: Rect2, cell: Vector2i) -> void:
	draw_rect(tile, Color("376970"))
	if cell.x == POND.position.x:
		draw_rect(Rect2(tile.position, Vector2(3, 32)), Color("8e8054"))
	if cell.y == POND.position.y:
		draw_rect(Rect2(tile.position, Vector2(32, 3)), Color("9c8961"))
	if cell.y == POND.end.y - 1:
		draw_rect(Rect2(tile.position + Vector2(0, 29), Vector2(32, 3)), Color("80734d"))
	var ripple := (cell.x * 19 + cell.y * 11) % 14
	draw_rect(Rect2(tile.position + Vector2(5 + ripple, 6 + ripple), Vector2(9, 1)), Color("6e9b97"))


func _draw_plot(point: Vector2, index: int, soil: int) -> void:
	const S = TutorialChapter.Soil
	if soil in [S.BARE, S.HARVESTED]:
		return
	var wet := soil in [S.DAMP, S.FLOODED, S.WET] or (progress.day == 8 and soil == S.SPROUT)
	_tile(TERRAIN, 4 if wet else 3, point)
	if index in range(5, 15) and soil >= S.FLOODED:
		draw_rect(Rect2(point + Vector2(2, 9), Vector2(28, 21)), Color(0.28, 0.50, 0.49, 0.55))
	if soil >= S.SOWN:
		var sprite := CROPS if index < 5 else (RICE_ART if index < 15 else (CORN if index < 30 else GREENS))
		var frame := 2 if soil == S.RIPE else (1 if soil >= S.SPROUT else 0)
		_tile(sprite, frame, point)
	if soil == S.PEST:
		_tile(preload("res://assets/art/32/sau_rau.png"), 0, point - Vector2(0, 7))
	elif soil == S.WEEDS:
		_tile(TERRAIN, 5, point - Vector2(0, 4))


func _objects(cells: Array, key: String, kind: int, shown: bool, required := 1) -> void:
	if not shown:
		return
	for index in cells.size():
		if progress.chapter.count(key + str(index)) >= required:
			continue
		var point := feet(cells[index]) - Vector2(0, 9)
		match kind:
			0:
				draw_rect(Rect2(point - Vector2(9, 1), Vector2(18, 4)), Color("566542"))
				for offset in [-7, -3, 0, 3, 7]:
					var end := point + Vector2(offset * 1.55, -13 + abs(offset) * 0.50)
					draw_line(point + Vector2(offset * 0.7, 2), end, Color("3c6339"), 3)
					draw_line(point + Vector2(offset * 0.7 - 1, 0), end - Vector2(1, 0), Color("a5b865"), 1)
			1:
				draw_rect(Rect2(point - Vector2(10, 8), Vector2(22, 11)), Color("654431"))
				draw_rect(Rect2(point - Vector2(7, 7), Vector2(17, 5)), Color("a47549"))
			2:
				draw_rect(Rect2(point - Vector2(10, 8), Vector2(21, 12)), Color("555c53"))
				draw_rect(Rect2(point - Vector2(7, 10), Vector2(14, 7)), Color("8c9280"))
			3, 4, 5, 6:
				var color := [Color("93ae5e"), Color("e7a450"), Color("af996b"), Color("91bf52")][kind - 3] as Color
				draw_rect(Rect2(point - Vector2(7, 6), Vector2(15, 8)), color.darkened(0.3))
				draw_rect(Rect2(point - Vector2(5, 7), Vector2(9, 5)), color)


func _building(cell: Vector2i, wall: Color, roof: Color, width := 30) -> void:
	var point := feet(cell)
	draw_rect(Rect2(point + Vector2(-width * 0.5, -21), Vector2(width, 20)), wall)
	draw_rect(Rect2(point + Vector2(-5, -16), Vector2(10, 15)), wall.darkened(0.4))
	draw_rect(Rect2(point + Vector2(-width * 0.5 - 2, -25), Vector2(width + 4, 7)), roof)
	draw_rect(Rect2(point + Vector2(-width * 0.5 + 2, -28), Vector2(width - 4, 4)), roof.lightened(0.14))


func _character(texture: Texture2D, frame: int, cell: Vector2i, height: int) -> void:
	draw_texture_rect_region(texture, Rect2(feet(cell) - Vector2(16, height), Vector2(32, height)), Rect2(frame * 32, 0, 32, height))


func _tile(texture: Texture2D, frame: int, point: Vector2) -> void:
	draw_texture_rect_region(texture, Rect2(point, Vector2(32, 32)), Rect2(frame * 32, 0, 32, 32))
