class_name FestivalMap
extends RefCounted

const GATE := Vector2i(7, 0)
const EXIT := Vector2i(0, 6)
const KITCHEN := Vector2i(4, 4)
const WRESTLING := Vector2i(10, 4)
const SIGNUP := Vector2i(13, 5)
const LANTERN := Vector2i(17, 8)
const FOREST := [Vector2i(13, 2), Vector2i(14, 9), Vector2i(2, 8), Vector2i(2, 2)]
const FLAGS := [Vector2i(7, 4), Vector2i(11, 4), Vector2i(14, 5)]
const TEMPLE := Rect2i(8, 1, 4, 2)
const CHICK := Vector2i(10, 9)
const THANG := Vector2i(10, 7)
const MILL := Vector2i(8, 2)
const FORAGE := [Vector2i(17, 3), Vector2i(18, 4), Vector2i(18, 10), Vector2i(15, 1)]
const LIGHTS := [Vector2i(2, 3), Vector2i(7, 4), Vector2i(11, 4), Vector2i(14, 5)]


static func is_interactive(cell: Vector2i) -> bool:
	return cell in [EXIT, KITCHEN, WRESTLING, SIGNUP, LANTERN]


static func can_walk(cell: Vector2i) -> bool:
	return not is_interactive(cell) and not TEMPLE.has_point(cell) and cell not in FOREST and (cell.x < 16 or cell.y == 8)


static func paint(ground: TileMapLayer, size: Vector2i) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = preload("res://assets/art/32/village_terrain.png")
	atlas.texture_region_size = Vector2i(32, 32)
	for index in 8:
		atlas.create_tile(Vector2i(index, 0))
	ground.tile_set.add_source(atlas, 1)
	for y in size.y:
		for x in size.x:
			var plaza := (y == 6 and x < 15) or Rect2i(3, 3, 11, 5).has_point(Vector2i(x,y))
			var tile := 3 if plaza else (x * 7 + y * 11 + x * y) % 3
			if y == 8 and x >= 15:
				tile = 7
			elif x == 15:
				tile = 6
			elif x > 15:
				tile = 4 + (x + y) % 2
			ground.set_cell(Vector2i(x,y), 1, Vector2i(tile,0))
