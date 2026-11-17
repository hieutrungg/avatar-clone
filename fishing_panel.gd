class_name FishingPanel
extends Control

signal cast_finished(species: String)

const BITE_WAIT := 1.25
const REEL_WINDOW := 1.5

enum Phase { WAITING, BITING, RESULT }

@onready var message: Label = $Card/Message
@onready var controls: Label = $Card/Controls
@onready var fish_icon: TextureRect = $Card/Fish
@onready var meter: ProgressBar = $Card/Meter

var phase := Phase.RESULT
var remaining := 0.0
var target_species := ""
var bite_window := REEL_WINDOW


func _ready() -> void:
	set_process(false)


func cast(species: String, wait := BITE_WAIT, window := REEL_WINDOW) -> void:
	target_species = species
	phase = Phase.WAITING
	remaining = wait
	bite_window = window
	fish_icon.hide()
	meter.hide()
	message.text = "Đã thả câu. Chờ phao động."
	controls.text = "Esc · Thu cần"
	show()
	set_process(true)


func cancel() -> void:
	set_process(false)
	hide()


func reel() -> void:
	match phase:
		Phase.WAITING:
			_finish("", "Kéo sớm quá. Cá chưa cắn câu.")
		Phase.BITING:
			_finish(target_species, "Câu được %s!" % FishCatalog.FISH[target_species].name.to_lower())
		Phase.RESULT:
			hide()


func _process(delta: float) -> void:
	remaining -= delta
	if phase == Phase.WAITING:
		if remaining <= 0.0:
			phase = Phase.BITING
			remaining = bite_window
			message.text = "Cá cắn câu! Nhấn E ngay."
			meter.value = 1.0
			meter.show()
		return

	meter.value = remaining / bite_window
	if remaining <= 0.0:
		_finish("", "Cá thoát rồi. Thử lại nhé.")


func _finish(species: String, result: String) -> void:
	phase = Phase.RESULT
	set_process(false)
	message.text = result
	controls.text = "E / Esc · Đóng"
	meter.hide()
	if not species.is_empty():
		fish_icon.texture = FishCatalog.icon(species)
		fish_icon.show()
	cast_finished.emit(species)
