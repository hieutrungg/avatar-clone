class_name BambooWorksMap
extends RefCounted

const FORGE_GATE := Vector2i(7, 0)
const WORKS_GATE := Vector2i(15, 9)
const EXIT := Vector2i(0, 6)
const SPAWN := Vector2i(1, 6)
const SMITH := Vector2i(9, 5)
const HEARTH := Vector2i(9, 3)
const ANVIL := Vector2i(11, 4)
const QUENCH := Vector2i(13, 4)
const SCRAP := [Vector2i(5, 4), Vector2i(15, 5), Vector2i(12, 8)]
const HAI := Vector2i(6, 5)
const MACHINE := Vector2i(9, 4)
const SIGN := Vector2i(5, 3)
const BOARD := Vector2i(10, 7)
const RAW := Vector2i(13, 5)
const GOODS := Vector2i(16, 8)
const GROVE := [Vector2i(13, 3), Vector2i(15, 4), Vector2i(14, 7), Vector2i(11, 10)]
const FORGE_INSIDE := Rect2i(2, 2, 16, 8)
const WORKS_INSIDE := Rect2i(2, 2, 10, 8)
const ART_COLUMNS := 20


static func indoors(forge: bool, cell: Vector2i) -> bool:
	return (FORGE_INSIDE if forge else WORKS_INSIDE).has_point(cell)


static func rear_wall(forge: bool, cell: Vector2i) -> bool:
	return cell.y == FORGE_INSIDE.position.y and indoors(forge, cell)


static func paint(ground: TileMapLayer, size: Vector2i, art: Texture2D, forge: bool, storehouse := false) -> void:
	VillageMap.paint_ground(ground, size)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = art
	atlas.texture_region_size = Vector2i(32, 32)
	for frame in [0, 1, 2, 3, 18, 19]:
		atlas.create_tile(Vector2i(frame, 0))
	ground.tile_set.add_source(atlas, 2)
	for cell in ground.get_used_cells():
		var room := StorehouseMap.FLOOR.has_point(cell) if storehouse else indoors(forge, cell)
		if room and cell.y == FORGE_INSIDE.position.y:
			ground.set_cell(cell, 2, Vector2i(18 if forge else 19, 0))
		elif room:
			var frame := 0 if forge else 2
			if (cell.x * 11 + cell.y * 7 + cell.x * cell.y) % 5 == 0:
				frame += 1
			ground.set_cell(cell, 2, Vector2i(frame, 0))
		elif storehouse and cell.y != StorehouseMap.DOORWAY.y:
			ground.set_cell(cell, 2, Vector2i(0, 0))
		else:
			var path := cell.y == 6 or (not forge and cell.y in [5, 7, 8] and cell.x > 10)
			ground.set_cell(cell, 1, Vector2i(3 if path else (cell.x + cell.y * 2) % 3, 0))
