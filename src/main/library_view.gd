class_name LibraryView
extends VBoxContainer

# 덱 목록 화면의 골격. 받은 목록을 그리고 입력을 사실 그대로 올린다.
# 어떤 덱을 열지, 상태 문구를 언제 지울지 같은 해석은 main.gd가 맡는다.

signal deck_selected(deck_file: String)
signal add_pressed(anchor: Control)
signal settings_pressed(anchor: Control)
signal import_file_selected(path: String)
signal export_file_selected(path: String)
signal export_canceled

const DECK_TILE_SCENE := preload("res://src/main/deck_tile.tscn")

@onready var deck_list: HFlowContainer = $DeckListScroll/DeckList
@onready var empty_decks_label: Label = $EmptyDecksLabel
@onready var status_label: Label = $LibraryStatusLabel
@onready var add_button: Button = $Header/RightActions/LibraryAddButton
@onready var settings_button: Button = $Header/RightActions/LibrarySettingsButton
@onready var import_dialog: FileDialog = $ImportDialog
@onready var export_dialog: FileDialog = $ExportDialog


func _ready() -> void:
	add_button.pressed.connect(_on_add_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_configure_markdown_dialog(import_dialog, FileDialog.FILE_MODE_OPEN_FILE)
	_configure_markdown_dialog(export_dialog, FileDialog.FILE_MODE_SAVE_FILE)
	import_dialog.file_selected.connect(_on_import_file_selected)
	export_dialog.file_selected.connect(_on_export_file_selected)
	export_dialog.canceled.connect(_on_export_canceled)


func render(decks: Array[DeckInfo]) -> void:
	for child in deck_list.get_children():
		child.free()

	empty_decks_label.visible = decks.is_empty()

	for deck in decks:
		var deck_tile := DECK_TILE_SCENE.instantiate() as DeckTileView
		deck_tile.name = "Deck_%s" % deck.file_name.validate_node_name()
		deck_list.add_child(deck_tile)
		deck_tile.setup(deck.file_name, deck.display_name, deck.card_count)
		deck_tile.selected.connect(_on_deck_tile_selected)


func show_status(message: String) -> void:
	status_label.text = message
	status_label.visible = true


func hide_status() -> void:
	status_label.visible = false


func popup_import() -> void:
	import_dialog.popup_file_dialog()


func popup_export(file_name: String) -> void:
	export_dialog.current_file = file_name
	export_dialog.popup_file_dialog()


func _configure_markdown_dialog(dialog: FileDialog, file_mode: int) -> void:
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = file_mode
	dialog.use_native_dialog = true
	dialog.clear_filters()
	dialog.add_filter("*.md", "Markdown", "text/markdown,text/plain")


func _on_deck_tile_selected(deck_file: String) -> void:
	deck_selected.emit(deck_file)


func _on_add_pressed() -> void:
	add_pressed.emit(add_button)


func _on_settings_pressed() -> void:
	settings_pressed.emit(settings_button)


func _on_import_file_selected(path: String) -> void:
	import_file_selected.emit(path)


func _on_export_file_selected(path: String) -> void:
	export_file_selected.emit(path)


func _on_export_canceled() -> void:
	export_canceled.emit()
