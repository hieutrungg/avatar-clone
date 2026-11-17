class_name FishCatalog
extends RefCounted

const PERCH := "perch"
const CATFISH := "catfish"
const CARP := "carp"
const LOTUS_CARP := "lotus_crucian"
const GOLDFISH := "longtail_goldfish"
const GOBY := "goby"
const CAST_CLOCK_STEPS := 3
const SPECIES := [PERCH, CATFISH, CARP]
const ALL_FISH := [PERCH, CATFISH, CARP, LOTUS_CARP, GOLDFISH, GOBY]
const FISH := {
	PERCH: {"name": "Cá rô", "sell_price": 5, "frame": 0},
	CATFISH: {"name": "Cá trê", "sell_price": 7, "frame": 1},
	CARP: {"name": "Cá chép", "sell_price": 9, "frame": 2},
	LOTUS_CARP: {"name": "Cá diếc sen", "sell_price": 13, "frame": 3},
	GOLDFISH: {"name": "Cá vàng đuôi dài", "sell_price": 0, "frame": 4},
	GOBY: {"name": "Cá bống", "sell_price": 8, "frame": 0},
}


static func species_at(minute: int, day := 1) -> String:
	var summer := GardenCalendar.season(day) == GardenCalendar.Season.SUMMER
	if minute < 12 * 60:
		return CARP if summer else PERCH
	if minute < 18 * 60:
		return CATFISH
	return PERCH if summer else CARP


static func icon(species: String) -> AtlasTexture:
	if species in [LOTUS_CARP, GOLDFISH]:
		return PixelArt.atlas_frame(preload("res://assets/art/32/summer_craft.png"), FISH[species].frame)
	return PixelArt.atlas_frame(preload("res://assets/art/32/fish.png"), FISH[species].frame)
