class_name SummerMap
extends RefCounted

const EXIT := Vector2i(0, 6)
const GATE := Vector2i(10, 0)
const WHOLESALER := Vector2i(5, 4)
const SEED_SHOP := Vector2i(10, 4)
const TOOL_SHOP := Vector2i(15, 4)
const HAI := Vector2i(11, 2)
const MAI := Vector2i(7, 7)
const BAMBOO := Vector2i(17, 2)
const POND := Rect2i(16, 10, 3, 1)
const PARENTS := Vector2i(2, 6)
const PUMP := Vector2i(8, 9)
const CART := Vector2i(7, 3)
const HAI_YARD := Vector2i(4, 5)
const ATTRACTORS := [WHOLESALER, SEED_SHOP, TOOL_SHOP]
const TREES := [Vector2i(2, 1), Vector2i(18, 2), Vector2i(17, 9), Vector2i(7, 9)]
const WOOD_TREES := [Vector2i(6, 1), Vector2i(11, 1), Vector2i(15, 1)]
const STRAW := Vector2i(8, 10)
const HERBS := Vector2i(8, 8)
const LOTUS := Vector2i(18, 1)
const DRYING_RICE := [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7)]
const HUONG := Vector2i(8, 8)
const CRAFT_STALL := Vector2i(12, 8)
const BINH := Vector2i(5, 6)
const LY := Vector2i(1, 7)
const LAN_VISIT := Vector2i(4, 4)
const JAR := Vector2i(7, 9)
const EMBROIDERY := Vector2i(12, 2)
const AQUARIUM := Vector2i(5, 7)
const LAN_INSIDE := Vector2i(13, 4)


static func paint_district(ground: TileMapLayer, size: Vector2i) -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = preload("res://assets/art/32/village_terrain.png")
	atlas.texture_region_size = Vector2i(32, 32)
	for index in 8:
		atlas.create_tile(Vector2i(index, 0))
	ground.tile_set.add_source(atlas, 1)
	for y in size.y:
		for x in size.x:
			var plaza := y >= 3 and y <= 8 and (x > 2 or y == 6)
			ground.set_cell(Vector2i(x, y), 1, Vector2i(3 if plaza else (x * 7 + y * 11 + x * y) % 3, 0))
