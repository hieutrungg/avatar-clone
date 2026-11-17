class_name GardenSave
extends RefCounted

const SLOT_PATHS := ["user://garden.json", "user://garden-backup.json"]
const MAX_SAVE_BYTES := 65536

enum Status { MISSING, READY, INVALID, UNAVAILABLE }

class Result:
	var status: Status = Status.MISSING
	var progress: GardenProgress
	var slot := -1
	var revision := 0
	var recovered := false


static func read() -> Result:
	var first := _read_slot(0)
	var second := _read_slot(1)
	var latest := first if first.revision >= second.revision else second
	var other := second if latest == first else first
	if latest.status == Status.READY:
		latest.recovered = other.status == Status.INVALID or other.status == Status.UNAVAILABLE
		return latest
	if second.status == Status.UNAVAILABLE or first.status == Status.UNAVAILABLE:
		latest.status = Status.UNAVAILABLE
	elif second.status == Status.INVALID or first.status == Status.INVALID:
		latest.status = Status.INVALID
	return latest


static func write(progress: GardenProgress, replace_garden: bool = false) -> Error:
	var current := read()
	# Keep the newest valid slot intact while replacing the other one.
	var slot := 1 if current.status == Status.READY and current.slot == 0 else 0
	var path: String = SLOT_PATHS[slot]
	var temporary := "%s.%d.tmp" % [path, OS.get_process_id()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	var data := progress.to_data()
	data["revision"] = current.revision + 1
	var written := file.store_string(JSON.stringify(data, "\t", true, true) + "\n")
	file.flush()
	var error := file.get_error() if written else ERR_FILE_CANT_WRITE
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		DirAccess.remove_absolute(temporary)
	elif replace_garden and FileAccess.file_exists(SLOT_PATHS[1 - slot]):
		DirAccess.remove_absolute(SLOT_PATHS[1 - slot])
	return error


static func _read_slot(slot: int) -> Result:
	var result := Result.new()
	result.slot = slot
	var file := FileAccess.open(SLOT_PATHS[slot], FileAccess.READ)
	if file == null:
		if FileAccess.get_open_error() != ERR_FILE_NOT_FOUND:
			result.status = Status.UNAVAILABLE
		return result

	result.status = Status.INVALID
	if file.get_length() > MAX_SAVE_BYTES:
		return result
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return result
	var data: Variant = json.data
	if not data is Dictionary:
		return result
	var revision := GardenProgress.read_integer(data.get("revision"), 1, GardenProgress.MAX_SAVE_INTEGER)
	if revision < 1:
		return result

	result.progress = GardenProgress.from_data(data)
	if result.progress != null:
		result.status = Status.READY
		result.revision = revision
	return result
