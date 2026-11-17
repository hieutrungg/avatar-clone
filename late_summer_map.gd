class_name LateSummerMap
extends RefCounted

const COMPOST := Vector2i(9, 3)
const PACKING := Vector2i(8, 4)
const LAN := Vector2i(5, 4)
const POND_GATE := Vector2i(15, 0)
const FERRY := Vector2i(17, 8)
const BAMBOO := [Vector2i(14, 1), Vector2i(15, 3)]
const RATTAN := [Vector2i(14, 3), Vector2i(2, 3), Vector2i(14, 10)]
const POND_EXIT := Vector2i(0, 6)
const POND_SPAWN := Vector2i(1, 6)
const POND_BOUNDS := Rect2i(2, 1, 16, 10)
const LOTUS := [
	Vector2i(4, 3), Vector2i(7, 2), Vector2i(11, 2), Vector2i(15, 2), Vector2i(5, 5),
	Vector2i(9, 5), Vector2i(14, 5), Vector2i(6, 8), Vector2i(10, 9), Vector2i(16, 8),
	Vector2i(3, 7), Vector2i(7, 4), Vector2i(12, 4), Vector2i(8, 9), Vector2i(13, 8),
]
const BUYER := Vector2i(10, 5)
const SEEDS := Vector2i(15, 4)
const STALLS := [Rect2i(3, 1, 4, 3), Rect2i(8, 1, 4, 3), Rect2i(13, 1, 4, 3), Rect2i(4, 8, 3, 2), Rect2i(12, 8, 3, 2)]


static func pond_walkable(cell: Vector2i) -> bool:
	return cell == POND_SPAWN or POND_BOUNDS.has_point(cell)


static func fair_walkable(cell: Vector2i) -> bool:
	if cell in [BUYER, SEEDS]:
		return false
	for stall in STALLS:
		if stall.has_point(cell):
			return false
	return true


static func paint_pond(ground: TileMapLayer, size: Vector2i, art: Texture2D) -> void:
	VillageMap.paint_ground(ground, size)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = art
	atlas.texture_region_size = Vector2i(32, 32)
	for frame in [0, 1, 2]:
		atlas.create_tile(Vector2i(frame, 0))
	ground.tile_set.add_source(atlas, 2)
	for cell in ground.get_used_cells():
		if POND_BOUNDS.has_point(cell):
			var variant := (cell.x * 11 + cell.y * 3 + cell.x * cell.y) % 7
			ground.set_cell(cell, 2, Vector2i(mini(2, variant), 0))
		else:
			ground.set_cell(cell, 1, Vector2i(7 if cell.y == 6 and cell.x <= 1 else (cell.x + cell.y * 2) % 3, 0))
