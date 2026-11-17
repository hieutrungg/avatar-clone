class_name LateSummerAudio
extends Node

const RATE := 22050
const NOTES := {
	&"pond": [67, 69, 72, 74, 72, 69, 67, 64, 67, 72, 69, 67, 64, 62, 64, 0],
	&"fair": [72, 76, 79, 76, 74, 76, 79, 81, 79, 76, 72, 74, 76, 74, 72, 0],
	&"workshop": [55, 0, 60, 62, 64, 62, 60, 0, 57, 0, 55, 60, 57, 55, 53, 0],
}
const EFFECTS := {
	&"water": [0.46, 245.0, 93.0, 0.2],
	&"paddle": [0.24, 125.0, 74.0, 0.8],
	&"bamboo": [0.17, 460.0, 190.0, 0.57],
	&"weave": [0.16, 410.0, 262.0, 0.32],
	&"harvest": [0.15, 312.0, 167.0, 0.7],
	&"anvil": [0.52, 730.0, 470.0, 0.21],
	&"splitter": [0.28, 188.0, 130.0, 0.43],
	&"thunder": [1.3, 92.0, 36.0, 0.53],
	&"tarp": [0.34, 141.0, 74.0, 0.88],
}

var music := AudioStreamPlayer.new()
var effect := AudioStreamPlayer.new()
var cache: Dictionary[StringName, AudioStreamWAV] = {}
var playing: StringName


func _ready() -> void:
	music.volume_db = -21
	effect.volume_db = -13
	add_child(music)
	add_child(effect)


func play_area(track: StringName) -> void:
	if playing == track or DisplayServer.get_name() == "headless":
		return
	playing = track
	music.stop()
	if track == &"":
		return
	if not cache.has(track):
		cache[track] = _area_loop(track)
	music.stream = cache[track]
	music.play()


func play_effect(name: StringName) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not cache.has(name):
		var definition: Array = EFFECTS[name]
		var count := int(RATE * definition[0])
		var data := PackedByteArray()
		data.resize(count * 2)
		var phase := 0.0
		for index in count:
			var fraction := float(index) / count
			phase += TAU * lerpf(definition[1], definition[2], fraction) / RATE
			var noise := sin(index * 48.331) * sin(index * 12.713)
			var gain := minf(1.0, fraction * 60.0) * (1.0 - fraction) ** 2
			var sample := lerpf(sin(phase), noise, definition[3]) * gain
			data.encode_s16(index * 2, int(sample * 22000.0))
		cache[name] = _wave(data)
	effect.stream = cache[name]
	effect.play()


func _area_loop(track: StringName) -> AudioStreamWAV:
	const CALM := &"recovery"
	const STORM := &"storm"
	var notes: Array = NOTES.get(track, [])
	var beat := 0.34 if track == &"fair" else (0.68 if track == &"workshop" else 0.53)
	var duration := 4.0 if track in [CALM, STORM] else beat * notes.size()
	var count := int(RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for index in count:
		var time := float(index) / RATE
		var sample := 0.0
		if track == STORM:
			var air := sin(time * 50.0) * sin(time * 83.7) + 0.4 * sin(time * 146.0)
			var wind := 0.4 + 0.6 * (0.5 + 0.5 * cos(TAU * time / duration))
			var rain := sin(index * 40.26) * sin(index * 25.43)
			sample = (air * wind * 0.45 + rain * 0.27) * sin(PI * time / duration) ** 2
		elif track == CALM:
			var wind := (0.6 + 0.4 * cos(TAU * time / duration)) * sin(time * 243.1) * sin(time * 56.8)
			var cicada := (0.5 + 0.5 * cos(TAU * time * 4)) * sin(TAU * time * 2130.0)
			sample = (wind * 0.09 + cicada * 0.07) * sin(PI * time / duration) ** 2
		else:
			var note: int = notes[mini(notes.size() - 1, floori(time / beat))]
			if note > 0:
				var within := fposmod(time, beat)
				var frequency := 440.0 * 2.0 ** ((note - 69) / 12.0)
				var phase := TAU * within * frequency
				var attack := minf(within * 35.0, 1.0)
				var tail := sin(PI * (1.0 - within / beat) * 0.5) ** 2
				sample = (sin(phase) + 0.18 * sin(phase * 2.0)) * attack * tail * 0.38
				if track == &"fair":
					sample += sin(phase * 0.5) * attack * tail * tail * 0.14
		data.encode_s16(index * 2, int(sample * 22000.0))
	var stream := _wave(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream


func _wave(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
