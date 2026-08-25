class_name AppBackup
extends RefCounted

enum Result {
	OK,
	SOURCE_OPEN_FAILED,
	TARGET_OPEN_FAILED,
	INVALID_ARCHIVE,
	UNSUPPORTED_VERSION,
	WRITE_FAILED,
}

const FORMAT_VERSION := 1
const MAX_FILE_BYTES := 10 * 1024 * 1024
const MAX_TOTAL_BYTES := 50 * 1024 * 1024
const TEMP_EXPORT_PATH := "user://.my_flashcard_backup_export.zip"
const TEMP_IMPORT_PATH := "user://.my_flashcard_backup_import.zip"


static func create_backup(target_path: String) -> Result:
	var payload := _collect_current_files()
	var archive_result := _write_archive(TEMP_EXPORT_PATH, payload)
	if archive_result != Result.OK:
		return archive_result

	var archive_bytes := FileAccess.get_file_as_bytes(TEMP_EXPORT_PATH)
	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		_remove_file(TEMP_EXPORT_PATH)
		return Result.TARGET_OPEN_FAILED

	target.store_buffer(archive_bytes)
	target.flush()
	var write_error := target.get_error()
	target.close()
	_remove_file(TEMP_EXPORT_PATH)
	return Result.OK if write_error == OK else Result.WRITE_FAILED


static func restore_backup(source_path: String) -> Result:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return Result.SOURCE_OPEN_FAILED

	var temp := FileAccess.open(TEMP_IMPORT_PATH, FileAccess.WRITE)
	if temp == null:
		source.close()
		return Result.WRITE_FAILED
	temp.store_buffer(source.get_buffer(source.get_length()))
	temp.close()
	source.close()

	var archive := _read_archive(TEMP_IMPORT_PATH)
	_remove_file(TEMP_IMPORT_PATH)
	var archive_result: Result = archive.result
	if archive_result != Result.OK:
		return archive_result

	var restored_files: Dictionary = archive.files
	var previous_files := _collect_current_files()
	if _replace_current_files(restored_files):
		return Result.OK

	_replace_current_files(previous_files)
	return Result.WRITE_FAILED


static func result_message(result: Result) -> String:
	match result:
		Result.OK:
			return "완료"
		Result.SOURCE_OPEN_FAILED:
			return "백업 파일을 열 수 없습니다."
		Result.TARGET_OPEN_FAILED:
			return "선택한 위치에 백업을 저장할 수 없습니다."
		Result.INVALID_ARCHIVE:
			return "올바른 My Simple Flash Card 백업 파일이 아닙니다."
		Result.UNSUPPORTED_VERSION:
			return "이 앱에서 지원하지 않는 백업 버전입니다."
		_:
			return "데이터를 저장하지 못했습니다."


static func _write_archive(path: String, payload: Dictionary) -> Result:
	_remove_file(path)
	var packer := ZIPPacker.new()
	if packer.open(path) != OK:
		return Result.WRITE_FAILED

	var file_names: Array[String] = []
	for file_name: String in payload:
		file_names.append(file_name)
	file_names.sort()
	var manifest := {
		"format": "my-simple-flash-card-backup",
		"format_version": FORMAT_VERSION,
		"app_version": ProjectSettings.get_setting("application/config/version", ""),
		"created_at": Time.get_datetime_string_from_system(),
		"files": file_names,
	}
	if not _write_zip_entry(
		packer,
		"manifest.json",
		JSON.stringify(manifest, "\t").to_utf8_buffer()
	):
		packer.close()
		_remove_file(path)
		return Result.WRITE_FAILED

	for file_name in file_names:
		if not _write_zip_entry(packer, file_name, payload[file_name]):
			packer.close()
			_remove_file(path)
			return Result.WRITE_FAILED

	return Result.OK if packer.close() == OK else Result.WRITE_FAILED


static func _write_zip_entry(
	packer: ZIPPacker,
	path: String,
	content: PackedByteArray
) -> bool:
	if packer.start_file(path) != OK:
		return false
	if packer.write_file(content) != OK:
		return false
	return packer.close_file() == OK


static func _read_archive(path: String) -> Dictionary:
	var reader := ZIPReader.new()
	if reader.open(path) != OK:
		return {"result": Result.INVALID_ARCHIVE, "files": {}}
	if not reader.file_exists("manifest.json"):
		reader.close()
		return {"result": Result.INVALID_ARCHIVE, "files": {}}

	var manifest_text := reader.read_file("manifest.json").get_string_from_utf8()
	var parser := JSON.new()
	if parser.parse(manifest_text) != OK or parser.data is not Dictionary:
		reader.close()
		return {"result": Result.INVALID_ARCHIVE, "files": {}}
	var manifest := parser.data as Dictionary
	if manifest.get("format", "") != "my-simple-flash-card-backup":
		reader.close()
		return {"result": Result.INVALID_ARCHIVE, "files": {}}
	if int(manifest.get("format_version", -1)) != FORMAT_VERSION:
		reader.close()
		return {"result": Result.UNSUPPORTED_VERSION, "files": {}}

	var payload: Dictionary = {}
	var total_bytes := 0
	for entry_path in reader.get_files():
		if entry_path == "manifest.json" or entry_path.ends_with("/"):
			continue
		if payload.has(entry_path) or not _is_allowed_archive_path(entry_path):
			reader.close()
			return {"result": Result.INVALID_ARCHIVE, "files": {}}
		var content := reader.read_file(entry_path)
		total_bytes += content.size()
		if content.size() > MAX_FILE_BYTES or total_bytes > MAX_TOTAL_BYTES:
			reader.close()
			return {"result": Result.INVALID_ARCHIVE, "files": {}}
		if not _is_valid_content(entry_path, content):
			reader.close()
			return {"result": Result.INVALID_ARCHIVE, "files": {}}
		payload[entry_path] = content

	var listed_files: Array[String] = []
	var manifest_files: Variant = manifest.get("files", [])
	if manifest_files is not Array:
		reader.close()
		return {"result": Result.INVALID_ARCHIVE, "files": {}}
	for file_name: Variant in manifest_files:
		if file_name is not String:
			reader.close()
			return {"result": Result.INVALID_ARCHIVE, "files": {}}
		listed_files.append(file_name)
	listed_files.sort()
	var actual_files: Array[String] = []
	for file_name: String in payload:
		actual_files.append(file_name)
	actual_files.sort()
	reader.close()
	if listed_files != actual_files:
		return {"result": Result.INVALID_ARCHIVE, "files": {}}
	return {"result": Result.OK, "files": payload}


static func _is_allowed_archive_path(path: String) -> bool:
	if path.is_empty() or path.begins_with("/") or path.contains("\\"):
		return false
	if ".." in path.split("/"):
		return false
	if path == "settings.json":
		return true
	for prefix in ["decks/", "progress/", "study_resume/"]:
		if not path.begins_with(prefix):
			continue
		var file_name := path.trim_prefix(prefix)
		if file_name.is_empty() or file_name.get_file() != file_name:
			return false
		if prefix == "decks/":
			return DeckNaming.is_deck_file(file_name)
		return file_name.get_extension().to_lower() == "json"
	return false


static func _is_valid_content(path: String, content: PackedByteArray) -> bool:
	var text := content.get_string_from_utf8()
	if path.begins_with("decks/"):
		return text.strip_edges().is_empty() or not DeckParser.parse(text).is_empty()
	var parser := JSON.new()
	return parser.parse(text) == OK and parser.data is Dictionary


static func _collect_current_files() -> Dictionary:
	var files: Dictionary = {}
	_collect_directory(files, DeckStorage.decks_dir(), "decks/", "md")
	_collect_directory(files, DeckStorage.PROGRESS_DIR, "progress/", "json")
	_collect_directory(files, DeckStorage.STUDY_RESUME_DIR, "study_resume/", "json")
	if FileAccess.file_exists(DeckStorage.SETTINGS_PATH):
		files["settings.json"] = FileAccess.get_file_as_bytes(DeckStorage.SETTINGS_PATH)
	return files


static func _collect_directory(
	result: Dictionary,
	directory: String,
	prefix: String,
	extension: String
) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for file_name in DirAccess.get_files_at(directory):
		if file_name.get_extension().to_lower() != extension:
			continue
		result["%s%s" % [prefix, file_name]] = FileAccess.get_file_as_bytes(
			"%s/%s" % [directory.trim_suffix("/"), file_name]
		)


static func _replace_current_files(files: Dictionary) -> bool:
	for directory in [
		DeckStorage.decks_dir(),
		DeckStorage.PROGRESS_DIR,
		DeckStorage.STUDY_RESUME_DIR,
	]:
		if not _clear_directory_files(directory):
			return false
	_remove_file(DeckStorage.SETTINGS_PATH)

	for archive_path: String in files:
		var target_path := _target_path(archive_path)
		if target_path.is_empty():
			return false
		var target_directory := target_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(target_directory):
			if DirAccess.make_dir_recursive_absolute(target_directory) != OK:
				return false
		var target := FileAccess.open(target_path, FileAccess.WRITE)
		if target == null:
			return false
		target.store_buffer(files[archive_path])
		target.flush()
		var write_error := target.get_error()
		target.close()
		if write_error != OK:
			return false
	return true


static func _target_path(archive_path: String) -> String:
	if archive_path == "settings.json":
		return DeckStorage.SETTINGS_PATH
	if archive_path.begins_with("decks/"):
		return "%s/%s" % [
			DeckStorage.decks_dir().trim_suffix("/"),
			archive_path.trim_prefix("decks/"),
		]
	if archive_path.begins_with("progress/"):
		return "%s/%s" % [
			DeckStorage.PROGRESS_DIR.trim_suffix("/"),
			archive_path.trim_prefix("progress/"),
		]
	if archive_path.begins_with("study_resume/"):
		return "%s/%s" % [
			DeckStorage.STUDY_RESUME_DIR.trim_suffix("/"),
			archive_path.trim_prefix("study_resume/"),
		]
	return ""


static func _clear_directory_files(directory: String) -> bool:
	if not DirAccess.dir_exists_absolute(directory):
		return true
	for file_name in DirAccess.get_files_at(directory):
		if DirAccess.remove_absolute(
			"%s/%s" % [directory.trim_suffix("/"), file_name]
		) != OK:
			return false
	return true


static func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
