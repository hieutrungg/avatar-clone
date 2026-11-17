class_name CropCatalog
extends RefCounted

const CABBAGE := "cabbage"
const CARROT := "carrot"
const RADISH := "radish"
const CUCUMBER := "cucumber"
const WATER_SPINACH := "water_spinach"
const MALABAR_SPINACH := "malabar_spinach"
const HEIRLOOM_CARROT := "thuan_thanh"
const STICKY_RICE := "sticky_rice"
const CORN := "corn"
const AMARANTH := "amaranth"
const PADDY_RICE := "paddy_rice"
const WINTER_MELON := "winter_melon"
const YARDLONG_BEAN := "yardlong_bean"
const SWEET_POTATO := "sweet_potato"
const PEANUT := "peanut"
const PUMPKIN := "pumpkin"
const AUTUMN_CROPS := [SWEET_POTATO, PEANUT, PUMPKIN]
const HEIRLOOMS := [HEIRLOOM_CARROT, STICKY_RICE]
const SUMMER_CROPS := [CORN, WINTER_MELON, YARDLONG_BEAN]
const CROP_IDS := [CABBAGE, CARROT, RADISH, CUCUMBER]
const GREENS := [WATER_SPINACH, MALABAR_SPINACH]
const CROPS := {
	CABBAGE: {
		"name": "Cải",
		"seed_item": "cabbage_seed",
		"produce_item": "cabbage_produce",
		"buy_price": 4,
		"sell_price": 10,
		"growth_nights": 2,
		"atlas": "crops.png",
		"seed_atlas": "seed_bags.png",
		"seed_icon": 0,
	},
	CARROT: {
		"name": "Cà rốt",
		"seed_item": "carrot_seed",
		"produce_item": "carrot_produce",
		"buy_price": 8,
		"sell_price": 18,
		"growth_nights": 3,
		"atlas": "carrots.png",
		"seed_atlas": "seed_bags.png",
		"seed_icon": 1,
	},
	RADISH: {
		"name": "Củ cải trắng",
		"seed_item": "radish_seed",
		"produce_item": "radish_produce",
		"buy_price": 12,
		"sell_price": 26,
		"growth_nights": 3,
		"atlas": "radishes.png",
		"seed_atlas": "radish_seed.png",
		"seed_icon": 0,
	},
	CUCUMBER: {
		"name": "Dưa leo",
		"seed_item": "cucumber_seed",
		"produce_item": "cucumber_produce",
		"buy_price": 10,
		"sell_price": 24,
		"growth_nights": 3,
		"atlas": "cucumbers.png",
		"seed_atlas": "cucumber_seed.png",
		"seed_icon": 0,
	},
	WATER_SPINACH: {
		"name": "Rau muống",
		"seed_item": "water_spinach_seed",
		"produce_item": "water_spinach_produce",
		"buy_price": 4,
		"sell_price": 10,
		"growth_nights": 7,
		"atlas": "rau_muong.png",
		"seed_atlas": "greens_seeds.png",
		"seed_icon": 0,
	},
	MALABAR_SPINACH: {
		"name": "Mồng tơi",
		"seed_item": "malabar_spinach_seed",
		"produce_item": "malabar_spinach_produce",
		"buy_price": 8,
		"sell_price": 18,
		"growth_nights": 8,
		"atlas": "mong_toi.png",
		"seed_atlas": "greens_seeds.png",
		"seed_icon": 1,
	},
	HEIRLOOM_CARROT: {
		"name": "Cà rốt Thuận Thành", "seed_item": "thuan_thanh_seed", "produce_item": "thuan_thanh_produce",
		"buy_price": 8, "sell_price": 24, "growth_nights": 10, "atlas": "carrots.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 0,
	},
	STICKY_RICE: {
		"name": "Nếp cái hoa vàng", "seed_item": "sticky_rice_seed", "produce_item": "sticky_rice_produce",
		"buy_price": 8, "sell_price": 24, "growth_nights": 10, "atlas": "sticky_rice.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 1,
	},
	CORN: {
		"name": "Ngô", "seed_item": "corn_seed", "produce_item": "corn_produce",
		"buy_price": 8, "sell_price": 20, "growth_nights": 4, "atlas": "corn.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 2,
	},
	AMARANTH: {
		"name": "Rau dền", "seed_item": "amaranth_seed", "produce_item": "amaranth",
		"buy_price": 5, "sell_price": 7, "growth_nights": 3, "atlas": "rau_muong.png",
		"seed_atlas": "greens_seeds.png", "seed_icon": 0,
	},
	PADDY_RICE: {
		"name": "Lúa nước", "seed_item": "paddy_seed", "produce_item": "paddy",
		"buy_price": 5, "sell_price": 6, "growth_nights": 5, "atlas": "sticky_rice.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 1,
	},
	WINTER_MELON: {
		"name": "Bí đao", "seed_item": "winter_melon_seed", "produce_item": "winter_melon_produce",
		"buy_price": 10, "sell_price": 25, "growth_nights": 5, "atlas": "winter_melon.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 3,
	},
	YARDLONG_BEAN: {
		"name": "Đậu đũa", "seed_item": "yardlong_bean_seed", "produce_item": "yardlong_bean_produce",
		"buy_price": 7, "sell_price": 17, "growth_nights": 3, "atlas": "yardlong_bean.png",
		"seed_atlas": "summer_seeds.png", "seed_icon": 4,
	},
	SWEET_POTATO: {
		"name": "Khoai lang", "seed_item": "sweet_potato_seed", "produce_item": "sweet_potato_produce",
		"buy_price": 12, "sell_price": 28, "growth_nights": 5, "atlas": "sweet_potato.png",
		"seed_atlas": "late_summer.png", "seed_icon": 7,
	},
	PEANUT: {
		"name": "Lạc", "seed_item": "peanut_seed", "produce_item": "peanut_produce",
		"buy_price": 10, "sell_price": 23, "growth_nights": 4, "atlas": "peanut.png",
		"seed_atlas": "late_summer.png", "seed_icon": 8,
	},
	PUMPKIN: {
		"name": "Bí ngô", "seed_item": "pumpkin_seed", "produce_item": "pumpkin_produce",
		"buy_price": 14, "sell_price": 34, "growth_nights": 6, "atlas": "pumpkin.png",
		"seed_atlas": "late_summer.png", "seed_icon": 9,
	},
}


static func has_item(item_id: String) -> bool:
	for crop in CROPS.values():
		if item_id == crop.seed_item or item_id == crop.produce_item:
			return true
	return false


static func crop_frame(crop_id: String, watered_nights: int) -> int:
	if watered_nights == 0:
		return 0
	return 2 if watered_nights >= CROPS[crop_id].growth_nights else 1
