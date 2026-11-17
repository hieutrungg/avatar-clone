class_name JournalPanel
extends Control

class CalendarCell:
	var date_label: Label
	var background: StyleBoxFlat

@onready var summary: Label = $Card/Summary
@onready var week_row: HBoxContainer = $Card/Week
@onready var market: Label = $Card/Market
@onready var shop: Label = $Card/Shop
@onready var tasks: Label = $Card/Tasks
@onready var sleep: Label = $Card/Sleep
@onready var close_button: Button = $Card/Close

var week_cells: Array[CalendarCell] = []
var field_note: LineEdit
var notebook_button := Button.new()
var notebook_page := Label.new()
var has_field_note := false
signal note_changed(note: String)


func _ready() -> void:
	for index in range(GardenCalendar.WEEKDAYS.size()):
		var cell := CalendarCell.new()
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.background = StyleBoxFlat.new()
		tile.add_theme_stylebox_override("panel", cell.background)
		week_row.add_child(tile)

		var stack := VBoxContainer.new()
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation", 0)
		tile.add_child(stack)

		var weekday := Label.new()
		weekday.text = GardenCalendar.WEEKDAYS[index]
		weekday.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weekday.add_theme_font_size_override("font_size", 20)
		if index == GardenCalendar.WEEKDAYS.size() - 1:
			weekday.add_theme_color_override("font_color", Color("#f4d99d"))
		stack.add_child(weekday)

		cell.date_label = Label.new()
		cell.date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(cell.date_label)
		week_cells.append(cell)
	close_button.pressed.connect(hide)
	field_note = LineEdit.new()
	field_note.position = Vector2(28, 336)
	field_note.size = Vector2(584, 37)
	field_note.placeholder_text = "Ghi vào sổ mùa vụ · Enter để lưu"
	field_note.max_length = 160
	field_note.text_submitted.connect(_save_note)
	$Card.add_child(field_note)
	field_note.hide()
	notebook_button.position = Vector2(401, 18)
	notebook_button.size = Vector2(95, 44)
	notebook_button.text = "Sổ tay"
	notebook_button.pressed.connect(_toggle_notebook)
	$Card.add_child(notebook_button)
	notebook_button.hide()
	notebook_page.position = Vector2(28, 87)
	notebook_page.size = Vector2(584, 258)
	notebook_page.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_page.add_theme_font_size_override("font_size", 23)
	notebook_page.text = "Sổ Tay Ông Ngoại\n\nCụ Hai kể ông từng học đan khít ở xưởng. Ông học dở rồi lên Hà Nội. Hôm nay mình đan được chiếc giỏ đầu tiên bằng bó nan cụ chẻ."
	$Card.add_child(notebook_page)
	notebook_page.hide()


func _save_note(note: String) -> void:
	note_changed.emit(note.strip_edges())
	close_button.grab_focus()


func open(progress: GardenProgress) -> void:
	field_note.hide()
	has_field_note = progress.summer != null and progress.summer.read_notebook and progress.tutorial_completed
	notebook_button.visible = progress.summer != null and progress.summer.autumn.old_story
	_show_notebook(false)
	var start_day := GardenCalendar.week_start(progress.day)
	var today := GardenCalendar.weekday_index(progress.day)
	summary.text = "%s %d · Tuần %d · %s · Mai %s" % [
		progress.season_name(), progress.season_date(),
		GardenCalendar.week_number(progress.day), "Mưa" if progress.is_raining(progress.day) else "Nắng",
		"mưa" if progress.is_raining(progress.day + 1) else "nắng",
	]
	for index in range(week_cells.size()):
		var cell := week_cells[index]
		cell.date_label.text = str(start_day + index)
		cell.background.bg_color = Color("#637142") if index == today else Color("#304a39")
	if progress.arrival != null and progress.day == 1:
		market.text = "Về tới quê"
		shop.text = "Đi theo đường đất từ cổng về nhà."
		tasks.text = progress.arrival.house_tasks()
		sleep.text = "Cổng làng mở ngày 3 · E ở cạnh giường để ngủ"
		show()
		close_button.grab_focus()
		return
	if progress.arrival != null and progress.day == 2:
		market.text = "Tay liềm đầu tiên"
		shop.text = "Phát cỏ ở từng luống · 5 thể lực mỗi ô"
		tasks.text = _yard_tasks(progress)
		sleep.text = "E ở cạnh giường · Ngủ"
		show()
		close_button.grab_focus()
		return
	if progress.arrival != null and progress.day >= 3:
		var chapters := ["Cuốc đất & gieo hạt", "Bắt sâu & chăm cây", "Nuôi gà đầu tiên",
			"Câu cá chiều hè", "Bếp lửa", "Quy hoạch vườn", "Mưa đầu mùa", "Thu hoạch đầu tiên"]
		market.text = chapters[progress.day - 3] if progress.day <= ArrivalProgress.PRODUCE_DAY else "Việc ở vườn"
		shop.text = "1 · Rau muống    2 · Mồng tơi"
		if progress.day == ArrivalProgress.DRAIN_DAY:
			shop.text = "Mưa đã tưới vườn · Rãnh đã thông" if progress.arrival.drained else "Mưa tưới các luống · Nước đọng ở luống thấp"
		elif progress.day >= ArrivalProgress.PRODUCE_DAY:
			var stall := "đang mở" if progress.produce_stall_open() else "đã đóng"
			shop.text = "Quầy rau %s · %s" % [GardenCalendar.shop_hours(), stall]
			if progress.day >= ArrivalProgress.BOARD_DAY and progress.tutorial_completed:
				shop.text = "Bảng đơn ở quảng trường · Chợ phiên từ ngày 14"
		if progress.summer_available(SummerProgress.FIRST_DAY) and progress.tutorial_completed:
			_summer_tasks(progress)
		elif progress.day <= 4:
			tasks.text = _greens_tasks(progress)
		else:
			tasks.text = _arrival_tasks(progress)
		sleep.text = "E ở cạnh giường · Ngủ"
		show()
		close_button.grab_focus()
		return
	if progress.market_open():
		market.text = "Chợ phiên đang mở · Đến %s" % GardenCalendar.format_time(GardenCalendar.MARKET_CLOSE)
	else:
		market.text = "Chợ phiên · Ngày %d · %s" % [
			GardenCalendar.next_market_day(progress.day, progress.minute_of_day), GardenCalendar.market_hours(),
		]
	var shop_state := "đang mở" if GardenCalendar.shop_is_open(progress.minute_of_day) else "đã đóng"
	shop.text = "Cửa hàng %s · %s" % [GardenCalendar.shop_hours(), shop_state]
	tasks.text = _today_tasks(progress)
	sleep.text = "E ở cạnh giường · Ngủ" if progress.arrival != null else "E ở cửa nhà · Ngủ bất cứ lúc nào"
	show()
	close_button.grab_focus()


func _toggle_notebook() -> void:
	_show_notebook(not notebook_page.visible)


func _show_notebook(show_page: bool) -> void:
	notebook_page.visible = show_page
	notebook_button.text = "Lịch" if show_page else "Sổ tay"
	for section in [summary, week_row, market, shop, tasks, sleep]:
		section.visible = not show_page
	field_note.visible = not show_page and has_field_note


func _summer_tasks(progress: GardenProgress) -> void:
	var state := progress.summer
	var chapters := [
		"Chuyến hàng đầu tiên", "Giống cũ của ông", "Ngày đầu tiên của thói quen",
		"Thư từ thành phố", "Tay học nghề", "Tự đan rổ", "Mưa và sổ tay của ông",
		"Bố mẹ ghé thăm", "Cái máy bơm của bố",
		"Xây nhà cho gà", "Ngày đầu tiên mọi thứ tự chạy",
		"Ngày thứ hai vào nhịp", "Trứng sắp nở", "Tiếng kêu mới ở chuồng", "Giữ ấm cho gà con",
		"Gà con chạy quanh ổ", "Nhập đàn", "Làng treo đèn", "Chuẩn bị món thi", "Hội làng đình hè",
		"Sáng sau hội", "Hai người hàng xóm", "Buổi tập lúc trời chưa sáng",
		"Tin nhắn từ thành phố", "Chiếc khăn trong tủ",
		"Chuyến xe ra huyện", "Mũi thêu đầu tiên", "Đất mau khô", "Buổi tập thứ bảy",
		"Chuyện của Chị Lan", "Đơn khăn hoa", "Câu ở ao sen", "Danh thiếp Chú Bình", "Đêm trước nắng hạn",
		"Ngày đầu nắng hạn", "Máy bơm hết dầu", "Làng chia nước", "Giếng của ông", "Ngày khô nhất", "Mưa rồi",
		"Sau cơn nắng hạn", "Bí ẩn đầm sen", "Đôi tay khéo léo", "Vụ hè chín rộ", "Chuyến đò sông Cầu",
		"Rèn lại lưỡi liềm", "Thương Vụ Đầu Đời", "Khôi phục xưởng tre", "Đơn sỉ đầu tiên", "Giữ Kho Ngày Bão",
		"Chữ Tín Đầu Tiên", "Ngồi tính lại sổ", "Đón Đất Mới", "Một chiều rảnh", "Bàn Tay Cụ Hai",
		"Xuống giống vụ thu", "Thăm luống mới", "Lắp bàn đan", "Đóng giá kho", "Vào guồng",
	]
	market.text = chapters[progress.day - SummerProgress.FIRST_DAY] if progress.day <= AutumnWork.WORKROOM_FINISH else "Việc ở vườn"
	shop.text = "Chợ huyện %s · Cổng bắc làng" % GardenCalendar.shop_hours()
	if progress.summer_story != null and not progress.can_visit_district():
		shop.text = "Chợ Làng %s · Vườn sau qua cổng tre" % GardenCalendar.shop_hours()
	var lines := PackedStringArray()
	var late := state.late
	var works := state.works
	var autumn := state.autumn
	match progress.day:
		AutumnWork.AUTUMN_DAY:
			if not progress.seed_is_unlocked(CropCatalog.SWEET_POTATO):
				lines.append("•  Gặp Cụ Hai ở làng để nhận hạt vụ thu.")
			else:
				var sown := int((autumn.sown & 1) != 0) + int((autumn.sown & 2) != 0) + int((autumn.sown & 4) != 0)
				lines.append(_task_mark(sown == 3, "Gieo khoai lang, lạc và bí ngô · %d/3 loại." % sown))
			lines.append(_autumn_beds_line(progress))
		AutumnWork.CARE_DAY:
			lines.append(_autumn_beds_line(progress))
			lines.append("•  Tưới luống khô bằng E để cây lớn qua đêm.")
		AutumnWork.WORKROOM_DAY, AutumnWork.WORKROOM_SHELF, AutumnWork.WORKROOM_FINISH:
			if not progress.has_storehouse():
				lines.append("•  Xây kho cấp 2 từ Sổ Chi Tiêu để có góc xưởng.")
			else:
				lines.append(_task_mark(autumn.corner_ready(), "Lắp bàn, giá và chỗ chờ trong nhà kho · %d/3." % autumn.corner_step))
			if progress.day == AutumnWork.WORKROOM_FINISH and works.order_paid:
				var line := "Đã giao đơn sỉ thứ hai." if autumn.repeat_count > 0 else "Xem đơn sỉ thứ hai ở bảng xưởng."
				lines.append(_task_mark(autumn.repeat_count > 0, line))
		BambooWorks.FORGE_DAY:
			lines.append(_task_mark(works.forged, "Lò rèn ở đầu làng · 500 xu và 3 sắt vụn quanh lò."))
			lines.append(_task_mark(late.stubble == 0, "Dọn gốc rạ để chuẩn bị đất cho vụ sau."))
		BambooWorks.OFFER_DAY:
			lines.append(_task_mark(works.offered, "Lấy rượu nếp ở tủ trong nhà, rồi gặp Cụ Hai tại xưởng cạnh bến."))
			lines.append("•  Học đan ở sân nhà và dành 1.500 xu cho giao kèo.")
		BambooWorks.RESTORE_DAY:
			lines.append(_task_mark(works.repair_step > 0, "Tiếp quản xưởng với 1.500 xu."))
			lines.append(_task_mark(works.ready(), "Quét sàn, tra dầu máy, dựng biển · %d/3." % maxi(0, works.repair_step - 1)))
		BambooWorks.ORDER_DAY:
			lines.append(_task_mark(works.order_due > 0, "Xem bảng đơn trong xưởng · 20 sọt tre, hạn ngày 61."))
			lines.append("•  Chặt tre dọc làng, chạy máy và lấy hàng khi xong.")
		BambooWorks.STORM_DAY:
			shop.text = "Giông từ 17:00 · 3 phút để che chắn"
			lines.append(_task_mark((works.protection & BambooWorks.YARD_TARPS) == BambooWorks.YARD_TARPS, "Giữ E để che cả kho tre và kho sọt."))
			lines.append(_task_mark((works.protection & BambooWorks.COOP_TARP) != 0, "Che chuồng gà, về nhà chốt cửa rồi ngủ."))
			if works.storm_damage:
				lines.append("•  Kho ướt, giá đơn còn 2.800 xu.")
		BambooWorks.FIRST_DUE:
			if works.order_due > 0:
				lines.append(_task_mark(works.order_paid, "Gặp Lái Buôn tại sân xưởng để giao 20 sọt."))
				if works.storm_damage and not works.order_paid:
					lines.append("•  Đan bù trước 11:00 hoặc giao lô giảm giá.")
		AutumnWork.INVEST_DAY:
			lines.append("Sổ Chi Tiêu ở bàn trong nhà. Có thể dùng vốn hoặc giữ lại.")
		AutumnWork.SOIL_DAY:
			lines.append(_task_mark(late.stubble == 0, "Dọn hết gốc rạ."))
			lines.append(_task_mark(progress.prepared_autumn_count() >= 6, "Nhấn F để xới đất, rồi bón lót · %d/6 luống." % progress.prepared_autumn_count()))
			shop.text = "Gieo hạt vụ thu từ ngày 66"
		AutumnWork.REST_DAY:
			lines.append("Hôm nay có thể câu ở ao sen, làm hàng hoặc ghé xưởng thăm Cụ Hai.")
		AutumnWork.CRAFT_DAY:
			lines.append(_task_mark(autumn.weave2, "Gặp Cụ Hai tại xưởng từ 07:30 để học đan khít."))
			lines.append(_task_mark(autumn.first_bag > 0, "Đan chiếc giỏ đầu tiên."))
			if state.craft.embroidery and state.social.minh_points >= 45:
				lines.append(_task_mark(autumn.embroidery2, "Ghé Bà Minh học thêu cấp 2."))
		LateSummer.RECOVERY:
			lines.append("•  Múc nước ở giếng và lấy phân thảo mộc cạnh thùng bán.")
			lines.append("•  Nhấn F trước luống vụ hè để tưới thúc · %d/3 luống." % late.fertilized_count)
		LateSummer.LOTUS_DAY:
			lines.append(_task_mark(late.lotus_invited, "Gặp Cụ Hai và ra đầm phía đông bắc làng."))
			lines.append(_task_mark(late.lotus_done, "Giao 10 đài sen và 5 lá · Đang có %d đài, %d lá." % [
				progress.quantity(LateSummer.POD), progress.quantity(LateSummer.LEAF),
			]))
		LateSummer.BASKET_DAY:
			lines.append(_task_mark(late.basket_score >= 0, "Chặt tre và nhặt dây mây ở làng · %d/6 tre, %d/3 dây." % [
				progress.quantity(LateSummer.STEM), progress.quantity(LateSummer.RATTAN),
			]))
			lines.append("•  Mang vật liệu tới Cụ Hai để đan hai sọt.")
		LateSummer.HARVEST:
			lines.append("•  Giữ E trước cây chín để thu các luống vụ hè. Xếp hàng ở sân.")
			lines.append(_task_mark(late.hat, "Chị Lan ghé lúc 17:00."))
		LateSummer.FIRST_FAIR:
			shop.text = "Đò sông Cầu 50 xu · Chợ 06:00–16:00"
			lines.append("•  Ra bến gặp Ông Lái Đò. Hàng đem bán nằm trong sọt.")
			lines.append(_task_mark(late.seeds_unlocked(), "Giao bí đao %d/30 và ngô %d/50 để mở hạt vụ thu." % [late.melon_sold, late.corn_sold]))
		SummerProgress.FIRST_DAY:
			if progress.summer_story != null:
				lines.append("•  Tới Chợ Làng, gần bến sông.")
			else:
				lines.append(_task_mark(state.visited_market, "Ra chợ huyện qua cổng bắc làng."))
			lines.append(_task_mark(state.cart_sale, "Chất hàng ở thùng rồi bán cho Lão Lái Buôn."))
			lines.append("•  Xem đồ nghề và Bảng Cáo Thị.")
		SummerProgress.LETTER_DAY:
			lines.append(_task_mark(state.received_heirlooms, "Đọc thư trong tủ chè rồi gặp Cụ Hai ở làng."))
			lines.append("•  Vườn sau: cuốc sâu góc ao, gieo nếp trên ruộng nước." if progress.summer_story != null else "•  Cuốc sâu cà rốt, dẫn nước trước khi gieo nếp.")
		SummerProgress.MAI_DAY:
			lines.append(_task_mark(state.met_mai, "Trò chuyện với Mai bên hàng rào." if progress.summer_story != null else "Trò chuyện với Mai gần quảng trường."))
		SummerProgress.CITY_LETTER_DAY:
			lines.append(_task_mark(state.read_city_letter, "Nhận thư từ bưu tá sau 12:00." if progress.summer_story != null else "Sau 12:00, xem thư từ Hà Nội trong tủ chè."))
		SummerProgress.WEAVE_DAY:
			lines.append(_task_mark(state.learned_weaving, "Lấy tre phía đông bắc vườn, đan rổ trước nhà."))
			lines.append("•  Thử chẻ nan ở mức 20–60% trước khi đan." if progress.summer_story != null else "•  Chợ huyện có hạt vụ hè và phân bón. F để bón.")
		SummerProgress.SOLO_DAY:
			lines.append(_task_mark(state.solo_basket, "Thử tự đan rổ ở sân trước nhà."))
			if progress.summer_story != null:
				lines.append("•  Đan nong phơi hoặc phụ Chị Lan lật thóc từ 15:00.")
		SummerProgress.RAIN_DAY:
			lines.append("•  Mưa đã tưới cây cả ngày.")
			lines.append(_task_mark(state.read_notebook, "Tìm sổ tay trong rương và thử bật radio."))
		SummerProgress.FAMILY_DAY:
			lines.append(_task_mark(state.parents_visited, "Gặp bố mẹ ở sân từ 11:30."))
			lines.append(_task_mark(state.family_meal, "Vào bếp dọn bữa cơm gia đình."))
			if progress.summer_story != null and state.family_meal:
				lines.append(_task_mark(progress.summer_story.done("family_walk"), "Dẫn bố mẹ ra góc ao buổi chiều nếu muốn."))
		SummerProgress.PUMP_DAY:
			lines.append(_task_mark(state.sprinkler >= 0, "Xem máy bơm, lấy ống ở kệ rồi nối tại giếng."))
			if progress.summer_story != null:
				lines.append("•  Góc ao cần tưới hai lượt. Mỗi cụm vòi phủ 9 ô.")
			lines.append("•  Có trứng thì chọn ở chuồng để cho gà ấp.")
		SummerProgress.BUILD_DAY:
			lines.append(_task_mark(state.coop_step == 4, "Xem bản vẽ mở rộng ở chuồng gà."))
			if state.coop_step == 0:
				lines.append("•  Gỗ ở hàng rào bắc. Đinh ở kệ trong nhà.")
			elif state.coop_step == 3:
				lines.append("•  Nhặt rơm ở phía tây chuồng để lợp mái.")
		SummerProgress.QUIET_DAY:
			lines.append("Hôm nay không có gì cần làm gấp.")
			lines.append("•  Câu ở ao, nấu ở bếp, hoặc ghé làng buổi chiều.")
		VillageFestival.ORDER_DAY:
			lines.append("•  Bà Chín đăng đơn 10 trứng ở Bảng Cáo Thị.")
		VillageFestival.NOTICE_DAY:
			lines.append("•  Đọc thông báo hội ở cổng đình phía bắc làng.")
		VillageFestival.PREP_DAY:
			lines.append("•  Tìm nguyên liệu rồi chọn món thi ở bếp.")
		VillageFestival.FAIR_DAY:
			shop.text = "Đình mở 08:00 · Thả đèn lúc 19:00"
			lines.append("•  Thi nấu và đấu vật 08:00–17:00 · Uy tín %d." % state.festival.reputation)
			if state.festival.contest == 1:
				lines.append("•  Xem kết quả nấu ăn từ %s." % GardenCalendar.format_time(state.festival.judging_minute))
			elif state.festival.contest == 2 and state.festival.contest_score >= 90:
				lines.append("✓  Đã nhận danh hiệu Bàn Tay Vàng.")
		VillageSocial.AFTER_FAIR_DAY:
			lines.append(_task_mark(state.social.chief_met, "Gặp Trưởng thôn trước sân nhà."))
			if state.festival.wrestling:
				lines.append("•  Ghé Chú Thắng ở phía nam quảng trường.")
		VillageSocial.NEIGHBORS_DAY:
			lines.append(_task_mark(state.social.minh_points >= 30, "Gặp Bà Minh ở phía nam làng."))
			lines.append(_task_mark(state.social.tuan_points == 20, "Gặp Tuấn cạnh lối vào làng."))
		VillageSocial.TRAINING_DAY:
			if state.social.training_invited:
				lines.append("•  Tập với Chú Thắng trước 06:00, nếu muốn.")
		VillageSocial.MESSAGE_DAY:
			lines.append(_task_mark(state.social.boss_reply > 0, "Xem điện thoại trong nhà sau 12:00."))
		VillageSocial.SCARF_DAY:
			if state.social.minh_story == 0:
				lines.append("•  Ghé Bà Minh từ 14:00, nghe chuyện ông ngoại.")
			elif not state.social.scarf_found:
				lines.append("•  Mở ngăn dưới tủ chè để tìm khăn thêu.")
			else:
				lines.append(_task_mark(state.social.scarf_reply > 0, "Mang khăn sang cho Bà Minh xem."))
		SummerCraft.TRIP_DAY:
			lines.append(_task_mark(state.craft.trip_reply > 0, "Đi chợ huyện cùng Tuấn."))
		SummerCraft.EMBROIDERY_DAY:
			lines.append(_task_mark(state.craft.embroidery, "Gặp Bà Minh để học thêu sau khi đã tìm khăn."))
		SummerCraft.HEAT_HINT_DAY:
			lines.append("•  Luống ngoài vòi cần hai lượt tưới hôm nay.")
			lines.append("•  Bác Lý ở phía tây vườn.")
		SummerCraft.LAN_DAY:
			lines.append(_task_mark(state.craft.lan_reply > 0, "Chị Lan ghé nhà từ 12:30."))
		SummerCraft.ORDER_DAY:
			lines.append(_task_mark(state.craft.order_done, "Bảng Cáo Thị có đơn ba khăn hoa sau khi học thêu."))
		SummerCraft.LOTUS_DAY:
			lines.append(_task_mark(state.craft.lotus_caught, "Thử câu ở ao sen góc đông bắc vườn."))
		SummerCraft.BUYER_DAY:
			lines.append(_task_mark(state.craft.buyer_met, "Ghé Chú Bình ở khu nông sản chợ huyện."))
		SummerCraft.FORECAST_DAY:
			shop.text = "Dự báo · Nắng hạn ngày 45–49"
			lines.append("•  Chuẩn bị nước. Bác Lý đứng phía tây vườn.")
		DroughtProgress.FIRST:
			lines.append("•  Tưới lượt hai sau 15:00. Thêm nước cho gà.")
		DroughtProgress.OIL_DAY:
			lines.append("•  Hỏi Chú Thành hoặc nhắn Tuấn mua dầu.")
		DroughtProgress.SHARE_DAY:
			lines.append("•  Gặp Trưởng thôn và Cụ Hai ở làng.")
		DroughtProgress.DIG_DAY:
			lines.append("•  Có thể đào giếng phụ ở góc đông vườn.")
		DroughtProgress.LAST:
			lines.append("•  Ưu tiên luống cần cứu. Bác Lý có thể góp nước.")
		DroughtProgress.RAIN:
			shop.text = "Mưa tưới vườn · Hạn đã kết thúc"
			lines.append("•  Xem lại thiệt hại với Bác Lý ở phía tây vườn.")
	if progress.in_drought():
		shop.text = "Còn %d gàu · Máng gà %d/2 · Dầu %d" % [
			state.drought.supply, state.drought.chicken_water, state.drought.oil,
		]
	if state.craft.lan_reply > 0 and lines.size() < 3 and progress.day == SummerCraft.LAN_DAY:
		lines.append("•  Chị Lan vẫn đang cân nhắc chuyện lên huyện.")
	if state.social.training_invited and progress.day >= VillageSocial.TRAINING_DAY and lines.size() < 3:
		lines.append("•  Tập sáng · %d/7 buổi liên tiếp." % state.social.streak)
	if state.chick and not state.festival.chick_joined and lines.size() < 3:
		if state.festival.chick_age >= 3:
			lines.append("•  Gà con đủ khỏe để nhập đàn.")
		else:
			lines.append("•  Cho gà con cám mịn và giữ ấm. Đã chăm %d/3 đêm." % state.festival.chick_age)
	if state.hatch_day > 0 and lines.size() < 3:
		lines.append("•  Gà mái đang ấp · Còn %d đêm." % maxi(1, state.hatch_day - progress.day))
	if progress.day > SummerProgress.LETTER_DAY and not state.received_heirlooms and lines.size() < 3:
		lines.append("•  Đọc thư trong tủ chè rồi tìm Cụ Hai ở làng.")
	elif progress.day > SummerProgress.FAMILY_DAY and not state.parents_visited and lines.size() < 3:
		lines.append("•  Gặp bố mẹ trước sân để nhận máy bơm.")
	if lines.is_empty():
		if works.order_due > 0 and not works.order_paid:
			lines.append("•  Xem lại đơn 20 sọt ở bảng đơn xưởng tre.")
		elif works.order_paid and autumn.repeat_day > 0:
			lines.append("•  Đơn xưởng kế tiếp từ ngày %d." % autumn.repeat_day)
	if progress.monsoon_forecast():
		shop.text = "Dự báo mưa ngâu 7 ngày từ ngày %d." % AutumnWork.RAIN_START
	if autumn.old_story and lines.size() < 3:
		lines.append("Sổ Tay Ông Ngoại · Ông từng học đan khít với Cụ Hai rồi lên Hà Nội.")
	if lines.is_empty():
		lines.append("•  Chăm vườn, bán ở chợ huyện hoặc xem bảng đơn.")
	tasks.text = "\n".join(lines)
	if state.read_notebook:
		field_note.text = state.farm_note
		field_note.show()


func _autumn_beds_line(progress: GardenProgress) -> String:
	var beds := progress.autumn_beds()
	return "•  Vụ thu · %d luống có cây / %d khô / %d chín." % [beds.x, beds.y, beds.z]


func _arrival_tasks(progress: GardenProgress) -> String:
	var arrival := progress.arrival
	var lines := PackedStringArray()
	if progress.day >= ArrivalProgress.PRODUCE_DAY:
		if progress.tutorial_completed:
			lines.append(_task_mark(true, "Đã bán bó rau muống đầu tiên."))
			lines.append("•  Mua hạt ở làng và gieo vụ tiếp theo.")
		elif progress.quantity(GardenProgress.FIRST_PRODUCE) > 0:
			if progress.produce_stall_open():
				lines.append("○  Bán rau muống tại quầy mái xanh ven sông.")
			else:
				lines.append("○  Mang rau muống ra quầy sáng mai từ 06:00.")
		else:
			var nights := progress.earliest_harvest_nights(CropCatalog.WATER_SPINACH)
			if nights == 0:
				lines.append("○  Thu hoạch rau muống chín rồi mang ra quầy.")
			elif nights > 0:
				lines.append("○  Rau muống còn ít nhất %d đêm đủ ẩm." % nights)
			else:
				var crop: Dictionary = CropCatalog.CROPS[CropCatalog.WATER_SPINACH]
				if not arrival.seeds_taken or progress.quantity(crop.seed_item) > 0:
					lines.append("○  Gieo rau muống để có rau bán ở quầy.")
				else:
					lines.append("○  Mua hạt rau muống ở quầy Cô Huệ.")
	var day_task := _day_task(progress)
	if not day_task.is_empty():
		lines.append(day_task)
	if arrival.pest_plot >= 0:
		lines.append("○  Bắt sâu trên luống rau muống.")
	elif not arrival.seeds_taken:
		lines.append("○  Nhận hạt cạnh thùng bán ở vườn.")
	elif not arrival.first_crop_watered:
		lines.append("○  Phát cỏ, cuốc, gieo và tưới rau muống.")
	var thirsty := 0
	for cell in GardenProgress.PLOT_CELLS:
		if progress.plot_action(cell) == GardenProgress.PlotAction.WATER:
			thirsty += 1
	if thirsty > 0:
		lines.append("•  Tưới %d luống đang lớn." % thirsty)
	if arrival.hen == ArrivalProgress.Hen.EGG_READY:
		lines.append("•  Nhặt trứng ở chuồng gà.")
	elif progress.day > ArrivalProgress.COOP_DAY and arrival.hen < ArrivalProgress.Hen.FED:
		lines.append("•  Mở chuồng và cho gà ăn ở phía nam vườn.")
	if progress.day > ArrivalProgress.FISHING_DAY and not arrival.caught_fish:
		lines.append("•  Gặp Bác Bảy và câu cá tại bến sông Cầu.")
	if progress.day > ArrivalProgress.COOKING_DAY and not arrival.cooked_meal:
		lines.append("•  Nấu bữa đầu tiên ở bếp trong nhà.")
	if progress.day > ArrivalProgress.FENCE_DAY and arrival.fence_index < 0:
		lines.append("•  Thử hàng rào ở khu chuồng.")
	if progress.day > ArrivalProgress.DRAIN_DAY and not arrival.drained:
		lines.append("•  Khơi rãnh cạnh luống thấp.")
	return "\n".join(lines.slice(0, 5))


func _day_task(progress: GardenProgress) -> String:
	var arrival := progress.arrival
	match progress.day:
		ArrivalProgress.COOP_DAY:
			return _task_mark(arrival.hen >= ArrivalProgress.Hen.FED, "Mở chuồng phía nam vườn và cho gà ăn.")
		ArrivalProgress.FISHING_DAY:
			return _task_mark(arrival.caught_fish, "Gặp Bác Bảy và câu một con cá ở bến sông Cầu.")
		ArrivalProgress.COOKING_DAY:
			return _task_mark(arrival.cooked_meal, "Nấu và ăn bữa cơm đầu tiên tại bếp trong nhà.")
		ArrivalProgress.FENCE_DAY:
			return _task_mark(arrival.fence_index >= 0, "Bật lưới ở biển khu chuồng và đặt hàng rào.")
		ArrivalProgress.DRAIN_DAY:
			return "✓  Đã thông rãnh. Luống thấp đủ ẩm đêm nay." if arrival.drained else "○  Khơi rãnh dưới luống thấp để cây lớn đêm nay."
	return ""


func _yard_tasks(progress: GardenProgress) -> String:
	var arrival := progress.arrival
	var total := GardenProgress.PLOT_CELLS.size()
	var cleared := progress.cleared_plot_count()
	var lines := PackedStringArray([
		"%s  Phát cỏ quanh các luống (%d/%d)." % ["✓" if cleared == total else "○", cleared, total],
	])
	if not arrival.tools_taken:
		lines.append("○  Lấy liềm trong túi đồ nghề cạnh cửa nhà.")
	match arrival.dog_food:
		ArrivalProgress.DogFood.PANTRY:
			lines.append("•  Gặp Cậu Vàng ở vườn. Thức ăn ở kệ trong nhà.")
		ArrivalProgress.DogFood.BAG:
			lines.append("•  Mang gói thức ăn tới cho Cậu Vàng.")
		ArrivalProgress.DogFood.FED:
			lines.append("✓  Cậu Vàng đã ở lại sân.")
	return "\n".join(lines)


func _greens_tasks(progress: GardenProgress) -> String:
	var arrival := progress.arrival
	var lines := PackedStringArray()
	if progress.day == 3 or not arrival.seeds_taken:
		lines.append(_task_mark(arrival.seeds_taken, "Nhận hạt cạnh thùng bán ở vườn."))
	if progress.day == 3 or not arrival.first_crop_watered:
		var preparation := "Cuốc, gieo và tưới ít nhất một luống rau muống."
		if not arrival.tools_taken:
			preparation = "Lấy đồ nghề cạnh cửa trong nhà."
		elif progress.cleared_plot_count() == 0:
			preparation = "Phát cỏ để có chỗ gieo rau muống."
		lines.append(_task_mark(arrival.first_crop_watered, preparation))
	if progress.day == 3 or not arrival.lan_met:
		lines.append(_task_mark(arrival.lan_met, "Gặp Chị Lan gần lối vào làng."))
	if progress.day >= 4:
		if arrival.pest_plot >= 0:
			lines.insert(0, "○  Bắt sâu trên luống rau muống, rồi tưới.")
		elif progress.day == 4:
			var pest_task := "Bắt sâu ở luống rau muống."
			if arrival.pest_plot == ArrivalProgress.PEST_PENDING:
				pest_task = "Tưới rau muống để cây nảy mầm."
			lines.insert(0, _task_mark(arrival.pest_plot == ArrivalProgress.PEST_REMOVED, pest_task))
		if progress.day == 4 or not arrival.cat_home:
			lines.append(_task_mark(arrival.cat_home, "Gặp Bố Đức trước sân để đón mèo."))
	var to_water := 0
	for cell in GardenProgress.PLOT_CELLS:
		if progress.plot_action(cell) == GardenProgress.PlotAction.WATER:
			to_water += 1
	if to_water > 0:
		lines.append("•  Tưới %d luống đang lớn." % to_water)
	if lines.is_empty():
		lines.append("Đã xong việc hướng dẫn ở vườn.")
	return "\n".join(lines.slice(0, 5))


func _task_mark(done: bool, task: String) -> String:
	return "%s  %s" % ["✓" if done else "○", task]


func _today_tasks(progress: GardenProgress) -> String:
	var to_water := 0
	var to_harvest := 0
	var empty_plots := 0
	for cell in GardenProgress.PLOT_CELLS:
		match progress.plot_action(cell):
			GardenProgress.PlotAction.WATER:
				to_water += 1
			GardenProgress.PlotAction.HARVEST:
				to_harvest += 1
			GardenProgress.PlotAction.HOE, GardenProgress.PlotAction.SOW, GardenProgress.PlotAction.NO_SEEDS, GardenProgress.PlotAction.OUT_OF_SEASON:
				empty_plots += 1

	var seeds := 0
	var cheapest_seed := GardenProgress.MAX_SAVE_INTEGER
	for crop_id in CropCatalog.CROP_IDS:
		if not progress.seed_is_unlocked(crop_id) or not progress.can_sow(crop_id):
			continue
		var crop: Dictionary = CropCatalog.CROPS[crop_id]
		seeds += progress.quantity(crop.seed_item)
		cheapest_seed = mini(cheapest_seed, crop.buy_price)

	var lines := PackedStringArray()
	if progress.is_raining(progress.day):
		lines.append("•  Mưa tưới các luống trong vườn.")
	if progress.market_delivery_day == 0:
		var produce := progress.quantity(MarketOrder.ITEM_ID)
		if progress.market_open() and produce >= MarketOrder.QUANTITY:
			lines.append("•  Giao 3 cây cải ở quầy chợ ven sông.")
		else:
			lines.append("•  Giữ 3 cây cải cho chợ Chủ nhật (%d/3)." % mini(produce, MarketOrder.QUANTITY))
	elif progress.day < progress.radish_unlock_day():
		lines.append("•  Hạt củ cải trắng mở bán ngày %d." % progress.radish_unlock_day())
	if progress.order_state == VillageOrder.State.DELIVERED:
		lines.append("•  Lĩnh 20 xu ở bảng đơn trong làng.")
	elif progress.can_deliver_order():
		lines.append("•  Giao 3 cây cải tại bảng đơn trong làng.")
	if progress.can_deliver_fish_order():
		lines.append("•  Giao 2 cá trê ở mục Đơn cá trong làng.")
	elif progress.fish_order_state == FishOrder.State.ACCEPTED:
		lines.append("•  Câu cá trê ở bến (12:00–18:00).")
	if to_harvest > 0:
		lines.append("•  Thu hoạch %d luống đã chín." % to_harvest)
	if to_water > 0:
		lines.append("•  Tưới %d luống đang lớn." % to_water)
	if empty_plots > 0 and seeds > 0:
		lines.append("•  Gieo %d luống. Cuốc đất trước nếu cần." % mini(empty_plots, seeds))
	var sale := progress.sale_value()
	var saving_for_market := progress.market_delivery_day == 0 and progress.quantity(MarketOrder.ITEM_ID) > 0
	if sale > 0 and not saving_for_market:
		lines.append("•  Bán hàng ở thùng để nhận %d xu." % sale)
	elif empty_plots > 0 and seeds == 0 and progress.coins >= cheapest_seed:
		lines.append("•  Sang làng mua hạt để gieo lại.")
	if lines.is_empty():
		lines.append("Đã xong việc ở vườn hôm nay.")
	return "\n".join(lines.slice(0, 4))
