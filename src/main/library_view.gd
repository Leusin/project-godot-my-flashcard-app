class_name LibraryView
extends VBoxContainer

# 덱 목록 화면의 골격. 받은 목록을 그리고 입력을 사실 그대로 올린다.
# 어떤 덱을 열지, 상태 문구를 언제 지울지 같은 해석은 main.gd가 맡는다.

signal deck_selected(deck_file: String)
signal deck_order_changed(order: Array[String])
signal add_pressed(anchor: Control)
signal settings_pressed(anchor: Control)
signal import_file_selected(path: String)
signal export_file_selected(path: String)
signal export_canceled

const DECK_TILE_SCENE := preload("res://src/main/deck_tile.tscn")

var _dragging_tile := false
var _layout_settled := true

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
		deck_tile.reorder_started.connect(_on_tile_reorder_started)
		deck_tile.reorder_moved.connect(_on_tile_reorder_moved)
		deck_tile.reorder_ended.connect(_on_tile_reorder_ended)


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


func _on_tile_reorder_started(_deck_file: String) -> void:
	_dragging_tile = true
	_layout_settled = true


func _on_tile_reorder_moved(deck_file: String, pointer: Vector2) -> void:
	if not _dragging_tile:
		return

	# 옮긴 직후에는 격자 배치가 아직 그대로라, 그 좌표로 또 옮기면 자리가 튄다.
	if not _layout_settled:
		return

	var moving := _tile_of(deck_file)
	var target := _tile_index_at(pointer)
	if moving == null or target < 0 or target == moving.get_index():
		return

	deck_list.move_child(moving, target)
	_layout_settled = false
	_settle_layout()


func _on_tile_reorder_ended(_deck_file: String) -> void:
	if not _dragging_tile:
		return
	_dragging_tile = false
	deck_order_changed.emit(current_order())


func _settle_layout() -> void:
	await get_tree().process_frame
	_layout_settled = true


func current_order() -> Array[String]:
	var order: Array[String] = []
	for child in deck_list.get_children():
		order.append((child as DeckTileView).deck_file())
	return order


func _tile_of(deck_file: String) -> DeckTileView:
	for child in deck_list.get_children():
		var tile := child as DeckTileView
		if tile.deck_file() == deck_file:
			return tile
	return null


func _tile_index_at(pointer: Vector2) -> int:
	for index in deck_list.get_child_count():
		if (deck_list.get_child(index) as Control).get_global_rect().has_point(pointer):
			return index
	return -1


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
