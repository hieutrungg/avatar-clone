class_name VillagePanel
extends Control

signal action_requested

enum Mode { DIALOGUE, VILLAGE_ORDER, MARKET, FISH_ORDER, VILLAGER, GIFT, PRODUCE, COOKING, WHOLESALE, SUPPLY, STORY, SUMMER_ORDER, RECIPES, EGG_ORDER, CRAFT_SHOP, SCARF_ORDER, DROUGHT_SHOP, CARGO, COUNTY_SALE, AUTUMN_SEEDS, BAMBOO_MACHINE, BAMBOO_ORDER, INVEST, WAREHOUSE, FINE_WEAVE }
const RECIPE_NAMES := ["Cháo cá rau má", "Trứng chiên", "Canh ba loại rau"]

@onready var heading: Label = $Card/Heading
@onready var body: Label = $Card/Body
@onready var action: Button = $Card/Action
@onready var close_button: Button = $Card/Close
@onready var switch_order: Button = $Card/SwitchOrder
@onready var gift_picker: OptionButton = $Card/GiftPicker
@onready var sale_quantity: SpinBox = $Card/SaleQuantity

var mode := Mode.DIALOGUE
var villager_id := ""
var villager_line := ""
var sale_limits: Array[int] = []
var wholesale_progress: GardenProgress
var machine_progress: GardenProgress
var restoration := ProgressBar.new()
var half_quantity := Button.new()
var warehouse_put := true
var warehouse_progress: GardenProgress


func _ready() -> void:
	action.pressed.connect(action_requested.emit)
	close_button.pressed.connect(hide)
	gift_picker.item_selected.connect(_update_sale_quantity)
	sale_quantity.value_changed.connect(_update_sale_total)
	restoration.position = Vector2(28, 156)
	restoration.size = Vector2(556, 27)
	restoration.max_value = 3
	restoration.show_percentage = false
	restoration.hide()
	heading.get_parent().add_child(restoration)
	half_quantity.text = "Chọn nửa"
	half_quantity.position = Vector2(481, 116)
	half_quantity.size = Vector2(103, 32)
	half_quantity.pressed.connect(_select_half_quantity)
	heading.get_parent().add_child(half_quantity)
	half_quantity.hide()


func open_confirmation(speaker: String, line: String, label: String, view: Mode) -> void:
	open_dialogue(speaker, line)
	mode = view
	action.text = label
	action.disabled = false
	action.show()
	action.grab_focus()


func open_recipes() -> void:
	open_confirmation("Bếp nhà", "Cháo cần cá, gạo và rau má. Trứng chiên cần trứng. Canh cần ba loại rau khác nhau.", "Nấu", Mode.RECIPES)
	gift_picker.clear()
	gift_picker.offset_right = 584
	for name in RECIPE_NAMES:
		gift_picker.add_item(name)
	gift_picker.select(0)
	gift_picker.show()
	switch_order.text = "Pha trà"
	switch_order.disabled = false
	switch_order.show()
	gift_picker.grab_focus()


func open_dialogue(speaker: String, line: String) -> void:
	mode = Mode.DIALOGUE
	gift_picker.hide()
	sale_quantity.hide()
	switch_order.hide()
	restoration.hide()
	half_quantity.hide()
	heading.text = speaker
	body.text = line
	action.hide()
	show()
	close_button.grab_focus()


func open_cargo(progress: GardenProgress, message := "") -> void:
	var state := progress.summer.late
	var used := state.slots_used()
	var counts := "Sọt %d/10 ô · Độ bền %d/%d." % [used, state.basket_score + 2 - state.basket_wear, state.basket_score + 2]
	open_confirmation("Hai sọt tre", counts + "\n" + ("Mỗi ô chở một lô 10 đơn vị." if message.is_empty() else message), "Xếp mặt hàng", Mode.CARGO)
	_clear_late_picker()
	var options := false
	for item in LateSummer.GOODS:
		var count := progress.quantity(item)
		if count > 0:
			_add_late_option(item, "%s · Túi ×%d" % [progress.item_label(item), count])
			options = true
	for item in state.cargo:
		_add_late_option(item, "Trong sọt · %s ×%d" % [progress.item_label(item), state.cargo[item]], true)
	_show_late_picker()
	action.disabled = not options or used >= LateSummer.SLOTS
	switch_order.text = "Dỡ hết"
	switch_order.disabled = false
	switch_order.visible = used > 0


func show_works_restoration(step: int) -> void:
	restoration.value = step - 1
	restoration.show()


func open_bamboo_machine(progress: GardenProgress) -> void:
	open_confirmation("Máy chẻ lạt", "", "Chạy máy", Mode.BAMBOO_MACHINE)
	machine_progress = progress
	gift_picker.clear()
	gift_picker.offset_right = 448
	for index in (BambooWorks.NAMES.size() if progress.summer.autumn.weave2 else 3):
		var unit := "nan" if index >= 4 else "tre"
		var extra := " + 1 mây" if index == 5 else ""
		gift_picker.add_item("%s · %d %s%s" % [BambooWorks.NAMES[index], BambooWorks.MATERIALS[index], unit, extra])
	gift_picker.select(0)
	gift_picker.show()
	sale_quantity.show()
	sale_quantity.set_value_no_signal(1)
	switch_order.text = "Lấy hàng"
	switch_order.show()
	refresh_bamboo_machine()
	if action.disabled:
		close_button.grab_focus()
	else:
		gift_picker.grab_focus()


func refresh_bamboo_machine() -> void:
	var progress := machine_progress
	var state := progress.summer.works
	var running := state.batch_count > 0
	var tre := progress.quantity(LateSummer.STEM)
	var product := gift_picker.selected
	var limit := progress.batch_limit(product)
	sale_quantity.set_value_no_signal(clampf(sale_quantity.value, 1, maxi(1, limit)))
	sale_quantity.max_value = maxi(1, limit)
	action.text = "Xếp mẻ chờ" if running else "Chạy máy"
	action.disabled = not progress.can_queue_bamboo() or limit == 0
	switch_order.disabled = not state.finished.any(func(count: int) -> bool: return count > 0)
	var stock := "Kho xưởng · Sọt %d / Nong %d / Rổ %d" % state.finished.slice(0, 3)
	var extra := 0
	for count in state.finished.slice(3):
		extra += count
	if extra > 0:
		stock += " · Khác %d" % extra
	if running:
		var queue_line := "Chờ %d · %s" % [state.queued_count, BambooWorks.NAMES[state.queued_product - 1]] if state.queued_count > 0 else stock
		body.text = "%s · %d món / %d giây\n%s" % [
			BambooWorks.NAMES[state.batch_product - 1], state.batch_count, state.batch_seconds(progress.day), queue_line,
		]
	else:
		var details := "Nan Tinh ×%d · Mây ×%d" % [progress.quantity(AutumnWork.FINE), progress.quantity(LateSummer.RATTAN)] if progress.summer.autumn.weave2 else (
			"Cụ Hai tăng tốc 20%" if state.has_advisor(progress.day) else "Chọn món và số lượng"
		)
		body.text = "Tre ống ×%d · %s\n%s" % [tre, details, stock]


func open_bamboo_order(progress: GardenProgress, message := "") -> void:
	var state := progress.summer.works
	if not state.ready() or not progress.summer_available(BambooWorks.ORDER_DAY):
		open_dialogue("Bảng đơn xưởng", "Đơn sỉ mở từ ngày 59 sau khi sửa xong xưởng.")
		return
	if not state.county_met:
		open_dialogue("Bảng đơn xưởng", "Ghé phiên Chợ Huyện gặp Lái Buôn Lớn để mở đơn sỉ.")
		return
	if state.order_paid:
		_open_repeat_bamboo_order(progress)
		return
	var trade := progress.summer.autumn
	var accepting := state.order_due < progress.day
	var due := progress.day + 2 if accepting else state.order_due
	var held := progress.quantity(BambooWorks.PRODUCTS[0])
	var line := "20 sọt tre lớn · Hạn ngày %d · 4.000 xu\nĐang mang %d/20 sọt đạt chuẩn." % [due, held]
	if state.storm_damage and progress.day >= BambooWorks.FIRST_DUE:
		line += "\nSọt mốc %d · Đan bù trước 11:00 hoặc nhận 2.800 xu." % trade.damp_baskets
	if not message.is_empty():
		line = message + "\n" + line
	open_confirmation("Đơn sỉ Chợ Huyện", line, ("Xin hẹn lại" if state.order_due > 0 else "Nhận đơn") if accepting else "Giao 20 sọt", Mode.BAMBOO_ORDER)
	action.disabled = not accepting and (held < BambooWorks.ORDER_SIZE or progress.day < BambooWorks.FIRST_DUE or (
		state.storm_damage and progress.day == BambooWorks.FIRST_DUE and progress.minute_of_day >= AutumnWork.RUSH_CLOSE
	))
	switch_order.text = "Giao giảm giá"
	switch_order.disabled = held < 14
	switch_order.visible = state.storm_damage and not accepting and progress.day >= BambooWorks.FIRST_DUE
	if action.disabled:
		close_button.grab_focus()


func _open_repeat_bamboo_order(progress: GardenProgress) -> void:
	var trade := progress.summer.autumn
	if progress.day < trade.repeat_day:
		open_dialogue("Bảng đơn xưởng", "Đơn đầu đã thanh toán %d xu. Đơn mới dự kiến ngày %d." % [trade.first_payout, trade.repeat_day])
		return
	var kind := trade.repeat_kind()
	var accepting := trade.repeat_due < progress.day
	var held := progress.quantity(AutumnWork.REPEAT_IDS[kind])
	var line := "%d %s · %d xu\nĐang mang %d · Hạn ngày %d." % [
		AutumnWork.REPEAT_AMOUNTS[kind], BambooWorks.NAMES[kind].to_lower(),
		AutumnWork.REPEAT_PAY[kind], held, progress.day + 3 if accepting else trade.repeat_due,
	]
	open_confirmation("Đơn sỉ định kỳ", line, "Nhận đơn" if accepting else "Giao hàng", Mode.BAMBOO_ORDER)
	action.disabled = not accepting and held < AutumnWork.REPEAT_AMOUNTS[kind]
	if action.disabled:
		close_button.grab_focus()


func open_autumn_ledger(progress: GardenProgress, message := "") -> void:
	var state := progress.summer.autumn
	open_confirmation("Sổ Chi Tiêu", "Vốn %d xu · Nhận vào sáng mai.\n%s" % [
		progress.coins, message if not message.is_empty() else "Đóng sổ để giữ vốn.",
	], "Đầu tư", Mode.INVEST)
	_clear_late_picker()
	for index in AutumnWork.INVESTMENTS.size():
		var bit := 1 << index
		var label := "%s · %d xu" % [AutumnWork.INVESTMENTS[index], AutumnWork.COSTS[index]]
		if state.built & bit:
			label += " · Xong"
		elif state.pending & bit:
			label += " · Chờ sáng mai"
		_add_late_option(str(index), label, ((state.built | state.pending) & bit) != 0)
	_show_late_picker()
	action.disabled = gift_picker.selected < 0 or gift_picker.is_item_disabled(gift_picker.selected)


func open_warehouse(progress: GardenProgress, deposit: bool, message := "") -> void:
	warehouse_put = deposit
	warehouse_progress = progress
	var storage := progress.summer.autumn.storage
	var slots := progress.summer.autumn.storage_slots()
	open_confirmation("Kho cấp 2", "Đã dùng %d/%d ô.\n%s" % [storage.size(), slots,
		message if not message.is_empty() else ("Gửi vật tư khỏi túi." if deposit else "Lấy vật tư từ kho."),
	], "Gửi vào kho" if deposit else "Lấy từ kho", Mode.WAREHOUSE)
	_clear_late_picker()
	gift_picker.offset_right = 448
	var source := progress.inventory if deposit else storage
	sale_limits.clear()
	for item in source:
		if not AutumnWork.can_store(item):
			continue
		_add_late_option(item, "%s ×%d" % [progress.item_label(item), source[item]], deposit and storage.size() >= slots and not storage.has(item))
		sale_limits.append(source[item])
	_show_late_picker()
	_refresh_warehouse_quantity()
	switch_order.text = "Lấy hàng" if deposit else "Gửi hàng"
	switch_order.disabled = false
	switch_order.show()


func _refresh_warehouse_quantity() -> void:
	var index := gift_picker.selected
	var available := index >= 0 and index < sale_limits.size() and not gift_picker.is_item_disabled(index)
	action.disabled = not available
	sale_quantity.visible = available
	if available:
		sale_quantity.max_value = sale_limits[index]
		sale_quantity.set_value_no_signal(1)


func open_fine_products(progress: GardenProgress) -> void:
	open_confirmation("Đan Lát Cấp 2", "Nan Tinh ×%d · Dây mây ×%d\nĐan tay có thể đạt phẩm Tinh Xảo." % [
		progress.quantity(AutumnWork.FINE), progress.quantity(LateSummer.RATTAN),
	], "Bắt đầu đan", Mode.FINE_WEAVE)
	_clear_late_picker()
	for index in AutumnWork.WEAVES.size():
		_add_late_option(str(index), "%s · %d nan%s" % [AutumnWork.WEAVES[index], AutumnWork.WEAVE_COST[index],
			" + 1 mây" if index == 1 else "",
		], not progress.can_weave_fine(index))
	_show_late_picker()
	action.disabled = gift_picker.selected < 0 or not progress.can_weave_fine(gift_picker.selected)


func open_county_sale(progress: GardenProgress, message := "") -> void:
	var state := progress.summer.late
	if progress.minute_of_day >= GardenCalendar.MARKET_CLOSE:
		open_dialogue("Lái Buôn Lớn", "Phiên đã tan. Vé khứ hồi vẫn dùng được.")
		return
	var quota := "Bí đao %d/30 · Ngô %d/50." % [state.melon_sold, state.corn_sold]
	open_confirmation("Lái Buôn Lớn", quota + "\n" + ("Chọn một mặt hàng trong sọt để bán." if message.is_empty() else message),
		"Bán mặt hàng", Mode.COUNTY_SALE)
	_clear_late_picker()
	for item in LateSummer.GOODS:
		var lots: int = state.cargo.get(item, 0)
		var price := progress.county_crop_price(item)
		_add_late_option(item, "%s ×%d · %d xu/đv" % [progress.item_label(item), lots * LateSummer.LOT_SIZE, price], lots == 0)
	_show_late_picker()
	action.disabled = state.cargo.is_empty()
	switch_order.text = "Bán hết"
	switch_order.disabled = false
	switch_order.visible = not state.cargo.is_empty()


func open_autumn_seeds(progress: GardenProgress, message := "") -> void:
	if progress.minute_of_day >= GardenCalendar.MARKET_CLOSE:
		open_dialogue("Sạp hạt vụ thu", "Phiên đã tan. Sạp mở lại ở phiên sau.")
		return
	if not progress.summer.late.seeds_unlocked():
		open_dialogue("Sạp hạt vụ thu", "Mở bán trong phiên sau khi cháu giao 30 bí đao và 50 bắp ngô cho Lái Buôn Lớn.")
		return
	open_confirmation("Sạp hạt vụ thu", "Có khoai lang, lạc và bí ngô cho vụ tới." if message.is_empty() else message, "Mua một hạt", Mode.AUTUMN_SEEDS)
	_clear_late_picker()
	for crop_id in CropCatalog.AUTUMN_CROPS:
		var crop: Dictionary = CropCatalog.CROPS[crop_id]
		_add_late_option(crop_id, "%s · %d xu" % [crop.name, crop.buy_price])
	_show_late_picker()


func _clear_late_picker() -> void:
	gift_picker.clear()
	gift_picker.offset_right = 584


func _add_late_option(item: String, label: String, disabled := false) -> void:
	gift_picker.add_item(label)
	var index := gift_picker.item_count - 1
	gift_picker.set_item_metadata(index, item)
	gift_picker.set_item_disabled(index, disabled)


func _show_late_picker() -> void:
	gift_picker.visible = gift_picker.item_count > 0
	for index in gift_picker.item_count:
		if not gift_picker.is_item_disabled(index):
			gift_picker.select(index)
			gift_picker.grab_focus()
			return


func open_produce(progress: GardenProgress, message := "", previous_item := "") -> void:
	mode = Mode.PRODUCE
	switch_order.visible = progress.market_open()
	switch_order.text = "Chợ phiên"
	switch_order.disabled = false
	heading.text = "Quầy mua nông sản"
	gift_picker.clear()
	sale_limits.clear()
	var selected := 0
	var preferred_item := previous_item
	if preferred_item.is_empty() and not progress.tutorial_completed:
		preferred_item = CropCatalog.WATER_SPINACH
	var has_inventory := false
	for crop_id in CropCatalog.CROPS:
		var crop: Dictionary = CropCatalog.CROPS[crop_id]
		var count := progress.quantity(crop.produce_item)
		has_inventory = has_inventory or count > 0
		var limit := progress.produce_sale_limit(crop_id)
		if limit == 0:
			continue
		var index := gift_picker.item_count
		gift_picker.add_item("%s ×%d · %d xu/món" % [crop.name, count, crop.sell_price])
		gift_picker.set_item_metadata(index, crop_id)
		sale_limits.append(limit)
		if crop_id == preferred_item:
			selected = index
	var stocked := gift_picker.item_count > 0
	body.text = message
	if message.is_empty() and not stocked:
		body.text = "Đã đạt giới hạn xu." if has_inventory else "Thu hoạch rau ở vườn rồi mang đến quầy."
	elif message.is_empty() and not progress.tutorial_completed:
		body.text = "Bán bó rau muống đầu tiên để hoàn thành hướng dẫn."
	gift_picker.visible = stocked
	gift_picker.offset_right = 448
	sale_quantity.visible = stocked
	action.visible = stocked
	action.disabled = false
	action.text = "Bán"
	if stocked:
		gift_picker.select(selected)
		_update_sale_quantity(selected)
	show()
	if stocked:
		gift_picker.grab_focus()
	elif switch_order.visible:
		switch_order.grab_focus()
	else:
		close_button.grab_focus()


func _update_sale_quantity(index: int) -> void:
	if mode == Mode.WAREHOUSE:
		_refresh_warehouse_quantity()
		return
	if mode == Mode.BAMBOO_MACHINE:
		refresh_bamboo_machine()
		return
	if mode in [Mode.PRODUCE, Mode.WHOLESALE] and index >= 0 and index < sale_limits.size():
		sale_quantity.max_value = sale_limits[index]
		sale_quantity.set_value_no_signal(1)
		_update_sale_total(1)


func _update_sale_total(value: float) -> void:
	if mode == Mode.PRODUCE and gift_picker.selected >= 0:
		var crop: Dictionary = CropCatalog.CROPS[selected_item()]
		action.text = "Bán · +%d xu" % (int(value) * int(crop.sell_price))
	elif mode == Mode.WHOLESALE and gift_picker.selected >= 0:
		action.text = "Bán · +%d xu" % (int(value) * wholesale_progress.wholesale_price(selected_item()))


func open_wholesale(progress: GardenProgress, message := "") -> void:
	open_dialogue("Lão Lái Buôn", message)
	if not GardenCalendar.shop_is_open(progress.minute_of_day):
		body.text = "Lão mua hàng từ %s." % GardenCalendar.shop_hours()
		return
	mode = Mode.WHOLESALE
	wholesale_progress = progress
	sale_limits.clear()
	gift_picker.clear()
	for item in progress.inventory:
		var limit := progress.wholesale_limit(item)
		if limit <= 0:
			continue
		gift_picker.add_item("%s ×%d · %d xu" % [progress.item_label(item), limit, progress.wholesale_price(item)])
		gift_picker.set_item_metadata(gift_picker.item_count - 1, item)
		sale_limits.append(limit)
	if gift_picker.item_count == 0:
		if message.is_empty():
			body.text = "Lão mua rau, cá và rổ tre. Đơn giá đổi theo ngày."
		return
	if message.is_empty():
		body.text = "Đơn giá hôm nay. Chọn mặt hàng và số lượng."
	gift_picker.offset_right = 448
	gift_picker.show()
	gift_picker.select(0)
	sale_quantity.show()
	action.disabled = false
	action.show()
	switch_order.text = "Chọn hết"
	switch_order.show()
	half_quantity.visible = progress.village_wholesale_market()
	_update_sale_quantity(0)
	gift_picker.grab_focus()


func _select_half_quantity() -> void:
	sale_quantity.value = maxi(1, floori(sale_quantity.max_value * 0.5))


func open_supplies(progress: GardenProgress, message := "") -> void:
	open_dialogue("Sạp đồ nghề", message)
	if not GardenCalendar.shop_is_open(progress.minute_of_day):
		body.text = "Sạp mở từ %s." % GardenCalendar.shop_hours()
		return
	mode = Mode.SUPPLY
	gift_picker.clear()
	var items := [
		["iron_hoe", "Cuốc sắt", SummerProgress.IRON_HOE_PRICE, not progress.summer.iron_hoe],
		["sharp_sickle", "Liềm mới", SummerProgress.SICKLE_PRICE, not progress.summer.sharp_sickle],
		[SummerProgress.FERTILIZER, "Phân bón", SummerProgress.FERTILIZER_PRICE, progress.day >= SummerProgress.WEAVE_DAY or progress.village_wholesale_market()],
		[SummerProgress.NAIL, "Đinh sắt", progress.market_nail_price(), progress.day >= SummerProgress.BUILD_DAY or progress.village_wholesale_market()],
	]
	for item in items:
		if item[3]:
			gift_picker.add_item("%s · %d xu" % [item[1], item[2]])
			gift_picker.set_item_metadata(gift_picker.item_count - 1, item[0])
	if message.is_empty():
		body.text = "Cuốc sắt giảm thể lực khi cuốc. Liềm mới giúp phát cỏ nhẹ tay hơn."
	if gift_picker.item_count > 0:
		gift_picker.offset_right = 584
		gift_picker.select(0)
		gift_picker.show()
		action.text = "Mua"
		action.disabled = false
		action.show()
		gift_picker.grab_focus()


func open_order(progress: GardenProgress) -> void:
	mode = Mode.VILLAGE_ORDER
	gift_picker.hide()
	sale_quantity.hide()
	switch_order.text = "Việc vụ hè" if progress.summer_available(SummerProgress.WEAVE_DAY) else "Đơn cá"
	switch_order.disabled = false
	switch_order.show()
	heading.text = VillageOrder.TITLE
	refresh_order(progress)
	show()
	if action.visible and not action.disabled:
		action.grab_focus()
	else:
		close_button.grab_focus()


func refresh_order(progress: GardenProgress) -> void:
	action.show()
	action.disabled = false
	match progress.order_state:
		VillageOrder.State.AVAILABLE:
			body.text = "Bác Bảy cần %d cây cải cho bếp làng.\nThưởng %d xu." % [VillageOrder.QUANTITY, VillageOrder.REWARD]
			action.text = "Nhận đơn"
		VillageOrder.State.ACCEPTED:
			body.text = "Đã nhận đơn · Cải trong túi %d/%d\nMang đủ cải tới đây để giao." % [
				progress.quantity(VillageOrder.ITEM_ID), VillageOrder.QUANTITY,
			]
			action.text = "Giao %d cải" % VillageOrder.QUANTITY
			action.disabled = not progress.can_deliver_order()
		VillageOrder.State.DELIVERED:
			body.text = "Bếp làng đã nhận đủ cải. Bạn có thể lĩnh %d xu." % VillageOrder.REWARD
			action.text = "Lĩnh %d xu" % VillageOrder.REWARD
		VillageOrder.State.REWARDED:
			body.text = "Đã giao %d cải và lĩnh %d xu. Bác Bảy gửi lời cảm ơn!" % [
				VillageOrder.QUANTITY, VillageOrder.REWARD,
			]
			action.hide()
	if visible:
		close_button.grab_focus()


func open_summer_order(progress: GardenProgress) -> void:
	open_dialogue("Ngô cho bếp làng", "")
	mode = Mode.SUMMER_ORDER
	switch_order.text = "Đơn trứng" if progress.summer_available(VillageFestival.ORDER_DAY) else "Đơn cá"
	switch_order.disabled = false
	switch_order.show()
	var state := progress.summer.neighbor_order
	if state == 2:
		body.text = "Đã giao đủ ngô. Mai gửi lời cảm ơn."
		switch_order.grab_focus()
		return
	var count := progress.quantity("corn_produce")
	body.text = "Mai cần 2 bắp ngô cho bếp làng · Thưởng 35 xu.\nTrong túi %d/2. Hạt bán ở chợ huyện." % count
	action.text = "Nhận đơn" if state == 0 else "Giao 2 ngô"
	action.disabled = state == 1 and count < 2
	action.show()
	if not action.disabled:
		action.grab_focus()


func open_egg_order(progress: GardenProgress) -> void:
	var state := progress.summer.festival
	var count := progress.quantity(ArrivalProgress.EGG)
	var active := state.egg_deadline >= progress.day
	var line := "Bà Chín cần 10 trứng trong 5 ngày · Thưởng %d xu.\nTrong túi %d/10." % [VillageFestival.EGG_ORDER_REWARD, count]
	if active:
		line += " Hạn ngày %d." % state.egg_deadline
	elif state.egg_deadline > 0:
		line += " Có thể nhận lại."
	if state.egg_order_done:
		open_dialogue("Trứng cho Bà Chín", "Đã giao đủ 10 trứng.")
		mode = Mode.EGG_ORDER
	else:
		open_confirmation("Trứng cho Bà Chín", line, "Giao trứng" if active else "Nhận đơn", Mode.EGG_ORDER)
		action.disabled = active and count < VillageFestival.EGG_ORDER_COUNT
	switch_order.text = "Đơn thêu" if progress.summer_available(SummerCraft.ORDER_DAY) and progress.summer.craft.embroidery else "Đơn cá"
	switch_order.disabled = false
	switch_order.show()
	if not action.visible or action.disabled:
		switch_order.grab_focus()


func open_scarf_order(progress: GardenProgress) -> void:
	var state := progress.summer.craft
	var count := progress.quantity(SummerCraft.FLOWER_SCARF)
	var line := "Bà Chín cần 3 khăn thêu hoa · %d/3 trong túi.\nThưởng %d xu." % [count, SummerCraft.ORDER_REWARD]
	if state.order_deadline > 0:
		line += " Hạn ngày %d." % state.order_deadline
		if progress.day > state.order_deadline:
			line += " Bà vẫn nhận hàng muộn."
	if state.order_done:
		if progress.day < state.next_order_day:
			open_dialogue("Khăn cho Bà Chín", "Đã giao đủ khăn. Đơn tiếp theo mở ngày %d." % state.next_order_day)
			mode = Mode.SCARF_ORDER
		else:
			var active := state.repeat_deadline >= progress.day
			var repeat_line := "Bà Chín cần 5 khăn · %d/5 trong túi. Thưởng 250 xu." % count
			if active:
				repeat_line += " Hạn ngày %d." % state.repeat_deadline
			open_confirmation("Đơn khăn hằng tuần", repeat_line, "Giao 5 khăn" if active else "Nhận đơn", Mode.SCARF_ORDER)
			action.disabled = active and count < 5
	else:
		var can_extend := state.order_deadline > 0 and progress.day >= state.order_deadline and not state.order_extended and count < SummerCraft.ORDER_COUNT
		var button := "Nhận đơn" if state.order_deadline == 0 else ("Xin thêm 2 ngày" if can_extend else "Giao 3 khăn")
		open_confirmation("Khăn cho Bà Chín", line, button, Mode.SCARF_ORDER)
		action.disabled = state.order_deadline > 0 and count < SummerCraft.ORDER_COUNT and not can_extend
	switch_order.text = "Đơn cá"
	switch_order.disabled = false
	switch_order.show()
	if action.disabled or not action.visible:
		switch_order.grab_focus()


func open_drought_shop(progress: GardenProgress, message := "") -> void:
	open_dialogue("Chú Thành", message)
	if not GardenCalendar.shop_is_open(progress.minute_of_day):
		body.text = "Chú mở sạp từ 06:00 đến trước 18:00."
		return
	mode = Mode.DROUGHT_SHOP
	var drought := progress.summer.drought
	body.text = "Dầu cho máy bơm, nước chở từ huyện và dây thừng đào giếng." if message.is_empty() else message
	gift_picker.clear()
	var items := [
		["thanh", "Can dầu", DroughtProgress.OIL_THANH, progress.in_drought() and drought.oil == 0],
		["water", "Sáu gàu nước", DroughtProgress.WATER_PRICE, progress.in_drought() and drought.supply <= 74],
		[DroughtProgress.ROPE, "Dây thừng", DroughtProgress.ROPE_PRICE, progress.quantity(DroughtProgress.ROPE) == 0 and drought.well_step < 4],
	]
	for item in items:
		if item[3]:
			gift_picker.add_item("%s · %d xu" % [item[1], item[2]])
			gift_picker.set_item_metadata(gift_picker.item_count - 1, item[0])
	if gift_picker.item_count > 0:
		gift_picker.offset_right = 584
		gift_picker.select(0)
		gift_picker.show()
		action.text = "Mua"
		action.disabled = false
		action.show()
		gift_picker.grab_focus()


func open_craft_shop(progress: GardenProgress, message := "") -> void:
	open_dialogue("Sạp vật dụng", message)
	if not GardenCalendar.shop_is_open(progress.minute_of_day):
		body.text = "Sạp mở từ %s." % GardenCalendar.shop_hours()
		return
	var craft := progress.summer.craft
	mode = Mode.CRAFT_SHOP
	body.text = message if not message.is_empty() else "Vải, chỉ và vật dụng mang về nhà."
	gift_picker.clear()
	var items := [
		[SummerCraft.CLOTH, "Vải trắng", SummerCraft.CLOTH_PRICE, progress.day >= SummerCraft.EMBROIDERY_DAY],
		[VillageSocial.THREAD, "Chỉ màu", SummerCraft.THREAD_PRICE, progress.day >= SummerCraft.EMBROIDERY_DAY],
		["jar", "Chum nước", SummerCraft.JAR_PRICE, progress.day >= SummerCraft.HEAT_HINT_DAY and not craft.jar],
		["tank", "Bể cá mini", SummerCraft.TANK_PRICE, not craft.tank],
	]
	for item in items:
		if item[3]:
			gift_picker.add_item("%s · %d xu" % [item[1], item[2]])
			gift_picker.set_item_metadata(gift_picker.item_count - 1, item[0])
	if gift_picker.item_count > 0:
		gift_picker.offset_right = 584
		gift_picker.select(0)
		gift_picker.show()
		action.text = "Mua"
		action.disabled = false
		action.show()
		gift_picker.grab_focus()


func open_market(progress: GardenProgress) -> void:
	mode = Mode.MARKET
	gift_picker.hide()
	sale_quantity.hide()
	switch_order.visible = progress.produce_stall_open()
	switch_order.text = "Bán rau"
	switch_order.disabled = false
	heading.text = MarketOrder.TITLE
	refresh_market(progress)
	show()
	if action.visible and not action.disabled:
		action.grab_focus()
	elif switch_order.visible:
		switch_order.grab_focus()
	else:
		close_button.grab_focus()


func refresh_market(progress: GardenProgress) -> void:
	action.visible = progress.market_delivery_day == 0
	action.disabled = not progress.can_deliver_market_order()
	action.text = "Giao %d cải" % MarketOrder.QUANTITY
	if progress.market_delivery_day == 0:
		body.text = "Đơn chợ · Cải %d/%d · Thưởng %d xu\nGiao đủ để mở hạt củ cải trắng vào tuần sau." % [
			progress.quantity(MarketOrder.ITEM_ID), MarketOrder.QUANTITY, MarketOrder.REWARD,
		]
	elif progress.seed_is_unlocked(CropCatalog.RADISH):
		body.text = "Đơn chợ đã giao. Cô Huệ đang bán hạt củ cải trắng."
	else:
		body.text = "Đã giao cải và nhận %d xu.\nHạt củ cải trắng mở bán từ ngày %d." % [
			MarketOrder.REWARD, progress.radish_unlock_day(),
		]
	if visible:
		close_button.grab_focus()


func open_fish_order(progress: GardenProgress) -> void:
	mode = Mode.FISH_ORDER
	gift_picker.hide()
	sale_quantity.hide()
	heading.text = FishOrder.TITLE
	switch_order.text = "Đơn cải"
	switch_order.disabled = false
	switch_order.show()
	refresh_fish_order(progress)
	show()
	if action.visible and not action.disabled:
		action.grab_focus()
	else:
		switch_order.grab_focus()


func refresh_fish_order(progress: GardenProgress) -> void:
	action.show()
	action.disabled = false
	match progress.fish_order_state:
		FishOrder.State.AVAILABLE:
			body.text = "Bác Bảy cần %d con cá trê. Thưởng %d xu.\nCâu cá trê ở bến từ 12:00 đến 18:00." % [FishOrder.QUANTITY, FishOrder.REWARD]
			action.text = "Nhận đơn"
		FishOrder.State.ACCEPTED:
			body.text = "Cá trê trong túi %d/%d. Giao đủ để nhận %d xu." % [
				progress.quantity(FishCatalog.CATFISH), FishOrder.QUANTITY, FishOrder.REWARD,
			]
			action.text = "Giao cá trê"
			action.disabled = not progress.can_deliver_fish_order()
		FishOrder.State.COMPLETED:
			body.text = "Đã giao %d cá trê và nhận %d xu." % [FishOrder.QUANTITY, FishOrder.REWARD]
			action.hide()
	if visible:
		close_button.grab_focus()


func open_villager(id: String, line: String, progress: GardenProgress) -> void:
	mode = Mode.VILLAGER
	villager_id = id
	villager_line = line
	var relationship := progress.relationships[id]
	var villager: Dictionary = VillagerCatalog.VILLAGERS[id]
	var has_gifts := not progress.available_gifts().is_empty()
	var gift_status: String = villager.favorite_hint
	if relationship.last_gift_day == progress.day:
		gift_status = "Đã tặng quà hôm nay."
	elif not has_gifts:
		gift_status = "Có thể tặng nông sản hoặc cá."
	heading.text = "%s · Thân thiết %d" % [villager.name, relationship.points]
	body.text = "%s\n%s" % [line, gift_status]
	gift_picker.hide()
	sale_quantity.hide()
	action.text = "Tặng quà"
	action.disabled = relationship.last_gift_day == progress.day or not has_gifts
	action.show()
	switch_order.text = "Sự kiện"
	switch_order.disabled = false
	switch_order.visible = progress.can_view_villager_event(id)
	show()
	close_button.grab_focus()


func open_gifts(progress: GardenProgress) -> void:
	var gifts := progress.available_gifts()
	if gifts.is_empty() or progress.relationships[villager_id].last_gift_day == progress.day:
		return
	mode = Mode.GIFT
	var villager: Dictionary = VillagerCatalog.VILLAGERS[villager_id]
	heading.text = "Tặng quà · %s" % villager.name
	body.text = "Chọn một món trong túi.\n%s" % villager.favorite_hint
	gift_picker.clear()
	for item_id in gifts:
		gift_picker.add_item("%s ×%d  ·  +%d thân thiết" % [
			VillagerCatalog.gift_name(item_id), progress.quantity(item_id),
			VillagerCatalog.gift_points(villager_id, item_id),
		])
		gift_picker.set_item_metadata(gift_picker.item_count - 1, item_id)
	gift_picker.select(0)
	gift_picker.offset_right = 584
	gift_picker.show()
	gift_picker.grab_focus()
	action.text = "Trao quà"
	switch_order.text = "Quay lại"
	switch_order.disabled = false
	switch_order.show()


func selected_item() -> String:
	if gift_picker.selected < 0:
		return ""
	return gift_picker.get_item_metadata(gift_picker.selected)
