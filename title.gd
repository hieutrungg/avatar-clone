extends Control

const GARDEN_SCENE := preload("res://garden.tscn")
const OPENING_SCENE := preload("res://opening.tscn")

@onready var menu: VBoxContainer = $Menu
@onready var confirmation: VBoxContainer = $Confirmation
@onready var continue_button: Button = $Menu/Continue
@onready var new_button: Button = $Menu/NewGarden
@onready var back_button: Button = $Confirmation/Back
@onready var save_message: Label = $SaveMessage


func _ready() -> void:
	_show_menu(GardenSave.read())


func _unhandled_key_input(event: InputEvent) -> void:
	if confirmation.visible and event.is_action_pressed("ui_cancel"):
		_cancel_new_garden()
		get_viewport().set_input_as_handled()


func _show_menu(saved: GardenSave.Result) -> void:
	confirmation.hide()
	$Goal.show()
	menu.show()
	continue_button.visible = saved.status == GardenSave.Status.READY
	new_button.theme_type_variation = &"PrimaryButton" if not continue_button.visible else &""
	save_message.text = ""

	match saved.status:
		GardenSave.Status.READY:
			save_message.text = "Ngày %d · %s · %d xu" % [
				saved.progress.day, GardenCalendar.format_time(saved.progress.minute_of_day), saved.progress.coins,
			]
			if saved.recovered:
				save_message.text += " · Khôi phục bản lưu gần nhất"
		GardenSave.Status.INVALID:
			save_message.text = "Bản lưu bị lỗi. Bạn có thể tạo vườn mới."
		GardenSave.Status.UNAVAILABLE:
			save_message.text = "Không đọc được bản lưu."

	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_button.grab_focus()


func _continue_garden() -> void:
	var saved := GardenSave.read()
	if saved.status == GardenSave.Status.READY:
		_play_garden(saved.progress)
	else:
		_show_menu(saved)


func _request_new_garden() -> void:
	if GardenSave.read().status == GardenSave.Status.MISSING:
		_start_new_garden()
		return

	menu.hide()
	$Goal.hide()
	confirmation.show()
	back_button.grab_focus()


func _cancel_new_garden() -> void:
	_show_menu(GardenSave.read())
	new_button.grab_focus()


func _start_new_garden() -> void:
	var progress := GardenProgress.new_arrival(true)
	if GardenSave.write(progress, true) != OK:
		_show_menu(GardenSave.read())
		save_message.text = "Không lưu được vườn mới. Hãy thử lại."
		return
	_play_garden(progress)


func _play_garden(progress: GardenProgress) -> void:
	if progress.arrival == null or progress.arrival.intro_seen:
		_enter_garden(progress)
		return
	var opening := OPENING_SCENE.instantiate() as Opening
	opening.detailed_tutorial = progress.chapter != null
	menu.hide()
	confirmation.hide()
	add_child(opening)
	opening.finished.connect(_finish_opening.bind(progress), CONNECT_ONE_SHOT)


func _finish_opening(progress: GardenProgress) -> void:
	progress.arrival.intro_seen = true
	_enter_garden(progress, true)


func _enter_garden(progress: GardenProgress, opening_finished := false) -> void:
	if progress.chapter != null:
		var tutorial := preload("res://tutorial_garden.gd").new()
		tutorial.progress = progress
		get_tree().change_scene_to_node(tutorial)
		return
	var garden := GARDEN_SCENE.instantiate()
	garden.set("progress", progress)
	garden.set("opening_finished", opening_finished)
	get_tree().change_scene_to_node(garden)
