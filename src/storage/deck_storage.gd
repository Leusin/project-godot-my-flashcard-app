class_name DeckStorage
extends RefCounted

const DEFAULT_DECKS_DIR := "user://decks"
const PROGRESS_DIR := "user://progress"
const SETTINGS_PATH := "user://settings.json"
const SAMPLE_DECK_PATH := "res://sample_deck.md"

static var _decks_dir := DEFAULT_DECKS_DIR


static func decks_dir() -> String:
	return _decks_dir


static func set_decks_dir(dir: String) -> void:
	_decks_dir = DEFAULT_DECKS_DIR if dir.is_empty() else dir


static func deck_path(deck_file: String) -> String:
	return "%s/%s" % [_decks_dir.trim_suffix("/"), deck_file]


static func deck_exists(deck_file: String) -> bool:
	return not deck_file.is_empty() and FileAccess.file_exists(deck_path(deck_file))


static func list_deck_files() -> Array[String]:
	var decks: Array[String] = []
	if not DirAccess.dir_exists_absolute(_decks_dir):
		return decks
	
	for file_name in DirAccess.get_files_at(_decks_dir):
		if DeckNaming.is_deck_file(file_name):
			decks.append(file_name)
	
	decks.sort()
	return decks


static func read_deck(deck_file: String) -> String:
	return FileAccess.get_file_as_string(deck_path(deck_file))


static func import_deck(source_path: String) -> Variant:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return null
	
	var file_name := DeckNaming.unique_file_name(
		source_path.get_file(),
		list_deck_files()
	)
	if not write_deck(file_name, source.get_as_text()):
		return null
	
	return file_name


static func export_deck(deck_file: String, target_path: String) -> bool:
	if not deck_exists(deck_file):
		return false
	
	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		return false
	
	target.store_string(read_deck(deck_file))
	return true


static func write_deck(deck_file: String, content: String) -> bool:
	_ensure_dir(_decks_dir)
	var file := FileAccess.open(deck_path(deck_file), FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(content)
	return true


static func rename_deck(old_file: String, new_file: String) -> bool:
	if old_file == new_file or not deck_exists(old_file):
		return false
	
	if DirAccess.rename_absolute(deck_path(old_file), deck_path(new_file)) != OK:
		return false
	
	var old_progress := progress_path(old_file)
	if FileAccess.file_exists(old_progress):
		DirAccess.rename_absolute(old_progress, progress_path(new_file))
	
	return true


static func duplicate_deck(deck_file: String) -> Variant:
	if not deck_exists(deck_file):
		return null
	
	var new_file := DeckNaming.unique_file_name(deck_file, list_deck_files())
	if not write_deck(new_file, read_deck(deck_file)):
		return null
	
	if FileAccess.file_exists(progress_path(deck_file)):
		save_progress(new_file, load_progress(deck_file))
	
	return new_file


static func delete_deck(deck_file: String) -> bool:
	if not deck_exists(deck_file):
		return false
	
	if DirAccess.remove_absolute(deck_path(deck_file)) != OK:
		return false
	
	var progress := progress_path(deck_file)
	if FileAccess.file_exists(progress):
		DirAccess.remove_absolute(progress)
	
	return true


static func seed_sample_if_empty() -> void:
	if _decks_dir != DEFAULT_DECKS_DIR or not list_deck_files().is_empty():
		return

	write_deck(
		SAMPLE_DECK_PATH.get_file(),
		FileAccess.get_file_as_string(SAMPLE_DECK_PATH)
	)


static func progress_path(deck_file: String) -> String:
	return "%s/%s" % [PROGRESS_DIR, DeckNaming.progress_file_name(deck_file)]


static func load_progress(deck_file: String) -> Progress:
	var path := progress_path(deck_file)
	if not FileAccess.file_exists(path):
		return Progress.new()
	
	return Progress.from_json(FileAccess.get_file_as_string(path))


static func save_progress(deck_file: String, progress: Progress) -> bool:
	_ensure_dir(PROGRESS_DIR)
	var file := FileAccess.open(progress_path(deck_file), FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(progress.to_json())
	return true


static func load_settings() -> AppSettings:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return AppSettings.new()
	
	return AppSettings.from_json(FileAccess.get_file_as_string(SETTINGS_PATH))


static func save_settings(settings: AppSettings) -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(settings.to_json())
	return true


static func _ensure_dir(dir: String) -> bool:
	if DirAccess.dir_exists_absolute(dir):
		return true
	
	return DirAccess.make_dir_recursive_absolute(dir) == OK
