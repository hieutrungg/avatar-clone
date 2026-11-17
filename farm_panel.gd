class_name FarmPanel
extends Control

signal item_pressed(crop_id: String)
signal close_requested

enum Mode { BAG, SHOP, FISH }

class ItemRow:
	var container: HBoxContainer
	var title: Label
	var detail: Label
	var action: Button

@onready var heading: Label = $Card/Heading
@onready var summary: Label = $Card/Summary
@onready var crop_list: ScrollContainer = $Card/CropList
@onready var rows: VBoxContainer = $Card/CropList/Rows
@onready var feedback: Label = $Card/Feedback
@onready var fish_rows: VBoxContainer = $Card/FishRows
@onready var switch_bag: Button = $Card/SwitchBag
@onready var close_button: Button = $Card/Close
@onready var tools_label: Label = $Card/Tools

var mode: Mode = Mode.BAG
var item_rows: Dictionary[String, ItemRow] = {}
var fish_quantities: Dictionary[String, Label] = {}


func setup(icons: Dictionary[String, Texture2D]) -> void:
	for crop_id in CropCatalog.CROPS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 64
		row.add_theme_constant_override("separation", 16)
		rows.add_child(row)

		var icon := TextureRect.new()
		icon.texture = icons[crop_id]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var description := VBoxContainer.new()
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		description.add_theme_constant_override("separation", 0)
		row.add_child(description)

		var item := ItemRow.new()
		item.container = row
		item.title = Label.new()
		item.detail = Label.new()
		item.detail.add_theme_font_size_override("font_size", 20)
		item.detail.add_theme_color_override("font_color", Color("#c6d6bb"))
		description.add_child(item.title)
		description.add_child(item.detail)

		item.action = Button.new()
		item.action.custom_minimum_size = Vector2(198, 50)
		item.action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.action.pressed.connect(item_pressed.emit.bind(crop_id))
		row.add_child(item.action)
		item_rows[crop_id] = item
	for species in FishCatalog.ALL_FISH:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 55
		row.add_theme_constant_override("separation", 16)
		fish_rows.add_child(row)

		var icon := TextureRect.new()
		icon.texture = FishCatalog.icon(species)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(48, 48)
		row.add_child(icon)

		var count := Label.new()
		fish_quantities[species] = count
		row.add_child(count)


func open(view: Mode, progress: GardenProgress) -> void:
	mode = view
	heading.text = "Cửa hàng hạt giống" if mode == Mode.SHOP else ("Túi cá" if mode == Mode.FISH else "Túi đồ")
	feedback.text = ""
	refresh(progress)
	show()
	if not rows.visible and mode == Mode.BAG:
		close_button.grab_focus()
		return
	if mode == Mode.FISH:
		switch_bag.grab_focus()
		return
	var first: String = _shop_ids(progress)[0] if mode == Mode.SHOP else progress.selected_crop
	var button: Button = item_rows[first].action
	if button.is_visible_in_tree() and not button.disabled:
		button.grab_focus()
	else:
		close_button.grab_focus()


func refresh(progress: GardenProgress) -> void:
	summary.text = "%d xu" % progress.coins
	if mode == Mode.BAG and progress.arrival != null and progress.day <= 2:
		crop_list.hide()
		fish_rows.hide()
		switch_bag.hide()
		summary.text = "Vật dụng · %d xu" % progress.coins
		tools_label.text = "Cuốc · Bình tưới · Liềm" if progress.arrival.tools_taken else "Đồ nghề ở cạnh cửa trong nhà."
		if progress.arrival.dog_food == ArrivalProgress.DogFood.BAG:
			tools_label.text += "\nGói thức ăn cho Cậu Vàng ×1"
		tools_label.show()
		return
	tools_label.hide()
	if mode == Mode.BAG and progress.arrival != null:
		var extras := PackedStringArray()
		if progress.arrival.dog_food == ArrivalProgress.DogFood.BAG:
			extras.append("Thức ăn Cậu Vàng ×1")
		if progress.quantity(ArrivalProgress.WELCOME_GIFT) > 0:
			extras.append("Bánh đa ×1")
		if progress.arrival.hen == ArrivalProgress.Hen.RATION:
			extras.append("Thức ăn gà ×1")
		if progress.quantity(ArrivalProgress.EGG) > 0:
			extras.append("Trứng ×%d" % progress.quantity(ArrivalProgress.EGG))
		for item in [BambooWorks.PRODUCTS[0], BambooWorks.PRODUCTS[1], BambooWorks.PRODUCTS[2], AutumnWork.FINE] + AutumnWork.WOVEN + AutumnWork.EMBROIDERED + [BambooWorks.IRON, BambooWorks.WINE,
			LateSummer.HERBS, LateSummer.STEM, LateSummer.RATTAN, LateSummer.POD, LateSummer.LEAF, LateSummer.TEA,
			DroughtProgress.ROPE, SummerCraft.CLOTH, SummerCraft.FIRST_STITCH, SummerCraft.FLOWER_SCARF, SummerCraft.BUYER_CARD,
			VillageSocial.SCARF, VillageSocial.THREAD, VillageFestival.BRAN, VillageFestival.MUNG, VillageFestival.GINGER, VillageFestival.SNAIL, VillageFestival.MUSHROOM,
			SummerProgress.BAMBOO, SummerProgress.WOOD, SummerProgress.NAIL, SummerProgress.STRAW, SummerProgress.PENNYWORT,
			SummerProgress.CANE_JUICE, SummerProgress.FERTILIZER, SummerProgress.RICE_BAG, SummerProgress.ROOT_STOCK]:
			if progress.quantity(item) > 0:
				extras.append("%s ×%d" % [SummerProgress.item_name(item), progress.quantity(item)])
		for item: String in ["early_corn", "amaranth", "paddy", "white_rice", "snail", "frog"] + TutorialChapter.CARRY_ITEMS:
			if progress.quantity(item) > 0:
				extras.append("%s ×%d" % [progress.item_label(item), progress.quantity(item)])
		var basket_count := 0
		for item in SummerProgress.BASKETS:
			basket_count += progress.quantity(item)
		if basket_count > 0:
			extras.append("Rổ ×%d" % basket_count)
		if progress.summer.works.forged:
			extras.append("Liềm Sắt Bén")
		if progress.summer.late.basket_score >= 0:
			extras.append("Hai sọt tre · %d/10 ô" % progress.summer.late.slots_used())
		feedback.text = " · ".join(extras)
	switch_bag.visible = mode != Mode.SHOP
	switch_bag.text = "Cây trồng" if mode == Mode.FISH else "Túi cá"
	crop_list.visible = mode != Mode.FISH
	fish_rows.visible = mode == Mode.FISH
	if mode == Mode.FISH:
		for species in FishCatalog.ALL_FISH:
			var label := fish_quantities[species]
			var fish: Dictionary = FishCatalog.FISH[species]
			(label.get_parent() as Control).visible = species in FishCatalog.SPECIES or progress.quantity(species) > 0
			var price := "%d xu/con" % fish.sell_price if fish.sell_price > 0 else "Cá cảnh"
			label.text = "%s ×%d · %s" % [fish.name, progress.quantity(species), price]
		return
	var crop_ids := _shop_ids(progress) if mode == Mode.SHOP else progress.bag_crop_ids()
	for crop_id in CropCatalog.CROPS:
		var crop: Dictionary = CropCatalog.CROPS[crop_id]
		var row := item_rows[crop_id]
		var unlocked := progress.seed_is_unlocked(crop_id)
		row.container.visible = crop_id in crop_ids and (mode == Mode.SHOP or unlocked)
		if crop_id in CropCatalog.SUMMER_CROPS and not unlocked:
			row.container.hide()
		row.action.disabled = not unlocked or (mode == Mode.SHOP and not progress.can_sow(crop_id))
		if not unlocked:
			row.title.text = "Hạt %s" % crop.name.to_lower()
			var unlock_day := progress.radish_unlock_day()
			row.detail.text = "Mở ngày %d" % unlock_day if unlock_day > 0 else "Giao đơn chợ để mở"
			row.action.text = "Chưa mở"
			continue
		row.title.text = "Hạt %s ×%d" % [crop.name.to_lower(), progress.quantity(crop.seed_item)]
		if mode == Mode.SHOP:
			row.detail.text = "%d đêm tưới · Bán %d xu" % [crop.growth_nights, crop.sell_price]
			row.action.text = "Mua 1 · %d xu" % crop.buy_price
			if crop_id == CropCatalog.CUCUMBER and row.action.disabled:
				row.action.text = "Chỉ bán mùa hè"
		else:
			row.detail.text = "Nông sản ×%d" % progress.quantity(crop.produce_item)
			var premium := progress.quantity(crop.produce_item + LateSummer.PREMIUM)
			if premium > 0:
				row.detail.text += " · Thượng hạng ×%d" % premium
			var action_name := "Đang chọn" if crop_id == progress.selected_crop else "Chọn"
			var shortcut := progress.seed_shortcut(crop_id)
			row.action.text = "%s [%d]" % [action_name, shortcut] if shortcut > 0 else action_name


func _shop_ids(progress: GardenProgress) -> Array:
	return progress.market_crop_ids() if progress.area == GardenProgress.Area.DISTRICT else progress.shop_crop_ids()


func _close() -> void:
	close_requested.emit()
