class_name Opening
extends Control

signal finished

const FRAME_SIZE := Vector2i(256, 128)
const FRAMES_PER_SHOT := 4
const FRAME_SECONDS := 0.22
const SHOT_SECONDS := 4.4
const TITLES := ["Hà Nội · 22:43", "Ngày cuối ở công ty", "Đường về Bắc Ninh", "Về tới quê"]
const CAPTIONS := [
	"Bảy năm làm IT. Hoàng vẫn là người tắt đèn cuối cùng.",
	"Sau khi mất việc, Hoàng ôm thùng đồ bước ra phố mưa.",
	"Qua ô kính xe, những mái nhà nhường chỗ cho đồng lúa.",
	"Căn nhà cũ vẫn còn đó. Hoàng đẩy cổng bước vào.",
]
const TUTORIAL_CAPTIONS := [
	"Bảy năm ở Hà Nội. Tiếng gõ phím vẫn đều, còn Hoàng thì đã mệt.",
	"Hoàng thu dọn đồ và quyết định về căn nhà của ông ngoại.",
	"Tiếng máy xe xa dần. Qua cửa kính là ruộng lúa và những mái ngói.",
	"15:00. Hoàng xuống xe với chiếc ba lô vải. Trong sân, Trưởng thôn đang đợi.",
]

@onready var picture: TextureRect = $Picture
@onready var chapter: Label = $Chapter
@onready var caption: Label = $Caption

var atlas := AtlasTexture.new()
var shot := 0
var elapsed := 0.0
var frame := -1
var detailed_tutorial := false


func _ready() -> void:
	atlas.atlas = preload("res://assets/art/32/opening.png")
	atlas.filter_clip = true
	picture.texture = atlas
	_show_shot()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= SHOT_SECONDS:
		_next_shot()
	else:
		_update_frame()


func _input(event: InputEvent) -> void:
	if not (event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel")):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		_finish()
	else:
		_next_shot()


func _next_shot() -> void:
	shot += 1
	if shot >= TITLES.size():
		_finish()
		return
	_show_shot()


func _show_shot() -> void:
	elapsed = 0.0
	frame = -1
	chapter.text = TITLES[shot]
	caption.text = TUTORIAL_CAPTIONS[shot] if detailed_tutorial else CAPTIONS[shot]
	_update_frame()


func _update_frame() -> void:
	var next_frame := int(elapsed / FRAME_SECONDS) % FRAMES_PER_SHOT
	if next_frame != frame:
		frame = next_frame
		atlas.region = Rect2(Vector2i(frame, shot) * FRAME_SIZE, FRAME_SIZE)


func _finish() -> void:
	set_process(false)
	set_process_input(false)
	finished.emit()
