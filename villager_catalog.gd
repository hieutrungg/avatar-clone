class_name VillagerCatalog
extends RefCounted

const HUE := "hue"
const BAY := "bay"
const IDS := [HUE, BAY]
const EVENT_POINTS := 6
const FAVORITE_POINTS := 3
const OTHER_GIFT_POINTS := 1
const VILLAGERS := {
	HUE: {
		"name": "Cô Huệ",
		"favorite": "carrot_produce",
		"favorite_hint": "Cô thích cà rốt mới nhổ.",
		"thanks": "Cảm ơn cháu. Cô để dành món này cho bữa tối.",
		"favorite_thanks": "Cà rốt mới nhổ à? Cô sẽ nấu một nồi canh ngọt cho nhà.",
		"event_title": "Những gói hạt bên hiên",
		"event": "Cô Huệ mở hộp hạt của mẹ cô. Trên mỗi gói đều có ngày gieo. Cô đưa cháu một tờ giấy.\n«Mùa tới, cháu ghi ngày gieo của vườn mình nhé.»",
	},
	BAY: {
		"name": "Bác Bảy",
		"favorite": FishCatalog.CATFISH,
		"favorite_hint": "Bác thích cá trê câu ở bến.",
		"thanks": "Bác cảm ơn. Có thêm món này, bữa cơm làng sẽ vui hơn.",
		"favorite_thanks": "Cá trê này kho với tiêu là ngon lắm. Cảm ơn cháu!",
		"event_title": "Bữa cơm bên bến",
		"event": "Bác Bảy xới thêm một bát cơm. Ngày mới đến làng, bác cũng được mời ăn ở bến này.\n«Từ nay cháu ghé thì cứ ngồi xuống ăn với bác.»",
	},
}


static func gift_points(villager_id: String, item_id: String) -> int:
	return FAVORITE_POINTS if VILLAGERS[villager_id].favorite == item_id else OTHER_GIFT_POINTS


static func gift_name(item_id: String) -> String:
	if FishCatalog.FISH.has(item_id):
		if item_id == FishCatalog.GOLDFISH:
			return ""
		return FishCatalog.FISH[item_id].name
	for crop in CropCatalog.CROPS.values():
		if crop.produce_item == item_id:
			return crop.name
	return ""
