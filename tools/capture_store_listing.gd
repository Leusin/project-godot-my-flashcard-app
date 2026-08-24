extends SceneTree

const MAIN_SCENE := preload("res://src/main/main.tscn")
const CAPTURE_DECKS_DIR := "user://store_capture_decks"
const CAPTURE_DECK := "영어 단어 복습.md"
const CAPTURE_TEXT := """# resilient
회복력이 있는

# concise
간결한

# momentum
추진력

# deliberate
신중한
"""
const OUTPUT_ROOT := "res://store-listing/ko-KR"
const OUTPUT_DIR := OUTPUT_ROOT + "/phone"
const FEATURE_SOURCE := "res://store-listing/sources/feature-graphic-generated.png"

var app: MainApp
var settings_existed := false
var settings_backup := PackedByteArray()


func _initialize() -> void:
	call_deferred("_capture_store_listing")


func _capture_store_listing() -> void:
	DisplayServer.window_set_size(Vector2i(540, 960))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_prepare_static_assets()
	_backup_user_settings()
	DeckStorage.set_decks_dir(CAPTURE_DECKS_DIR)
	if not DeckStorage.write_deck(CAPTURE_DECK, CAPTURE_TEXT):
		push_error("Store capture deck could not be written")
		quit(1)
		return

	var progress := Progress.new()
	progress.set_status("resilient", CardStatus.Value.MASTERED)
	progress.set_status("concise", CardStatus.Value.LEARNING)
	progress.add_wrong("concise")
	progress.set_favorite("momentum", true)
	DeckStorage.save_progress(CAPTURE_DECK, progress)

	app = MAIN_SCENE.instantiate() as MainApp
	app.auto_start = false
	root.add_child(app)
	app.study_gesture_surface.animations_enabled = false
	app.show_library()
	await _save_screenshot("01-deck-library.png")

	app.show_study_ready(CAPTURE_DECK)
	await _save_screenshot("02-study-ready.png")

	app.start_deck(CAPTURE_DECK)
	app.call("_on_card_tapped")
	await _save_screenshot("03-card-answer.png")

	app.call("_on_again_pressed")
	app.call("_reset_study_input_lock")
	app.call("_on_good_pressed")
	app.call("_reset_study_input_lock")
	app.call("_on_skip_requested")
	app.call("_reset_study_input_lock")
	app.call("_on_good_pressed")
	await _save_screenshot("04-study-result.png")

	_cleanup_capture_data()
	_restore_user_settings()
	print("STORE_CAPTURE_COMPLETE: %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit()


func _prepare_static_assets() -> void:
	var icon := Image.load_from_file("res://assets/branding/play_store_icon_512.png")
	icon.convert(Image.FORMAT_RGBA8)
	icon.save_png(OUTPUT_ROOT + "/app-icon-512.png")

	var feature := Image.load_from_file(FEATURE_SOURCE)
	var target_ratio := 1024.0 / 500.0
	var source_ratio := float(feature.get_width()) / float(feature.get_height())
	if source_ratio > target_ratio:
		var crop_width := roundi(feature.get_height() * target_ratio)
		var crop_x := (feature.get_width() - crop_width) / 2
		feature = feature.get_region(
			Rect2i(crop_x, 0, crop_width, feature.get_height())
		)
	elif source_ratio < target_ratio:
		var crop_height := roundi(feature.get_width() / target_ratio)
		var crop_y := (feature.get_height() - crop_height) / 2
		feature = feature.get_region(
			Rect2i(0, crop_y, feature.get_width(), crop_height)
		)
	feature.resize(1024, 500, Image.INTERPOLATE_LANCZOS)
	feature.convert(Image.FORMAT_RGB8)
	feature.save_png(OUTPUT_ROOT + "/feature-graphic-1024x500.png")


func _backup_user_settings() -> void:
	settings_existed = FileAccess.file_exists(DeckStorage.SETTINGS_PATH)
	if settings_existed:
		settings_backup = FileAccess.get_file_as_bytes(DeckStorage.SETTINGS_PATH)


func _restore_user_settings() -> void:
	if not settings_existed:
		if FileAccess.file_exists(DeckStorage.SETTINGS_PATH):
			DirAccess.remove_absolute(DeckStorage.SETTINGS_PATH)
		return
	var file := FileAccess.open(DeckStorage.SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_buffer(settings_backup)


func _cleanup_capture_data() -> void:
	DeckStorage.delete_deck(CAPTURE_DECK)
	if DirAccess.dir_exists_absolute(CAPTURE_DECKS_DIR):
		DirAccess.remove_absolute(CAPTURE_DECKS_DIR)
	DeckStorage.set_decks_dir("")


func _save_screenshot(file_name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	screenshot.resize(1080, 1920, Image.INTERPOLATE_LANCZOS)
	screenshot.convert(Image.FORMAT_RGB8)
	var output_path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := screenshot.save_png(output_path)
	if error != OK:
		push_error("Store screenshot save failed: %s" % output_path)
		quit(1)
