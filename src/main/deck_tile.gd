class_name DeckTileView
extends Control

signal selected(deck_file: String)
signal menu_requested(deck_file: String, anchor: Control)
signal reorder_started
signal reorder_moved(viewport_position: Vector2)
signal reorder_finished

@onready var deck_button: Button = %DeckButton
@onready var menu_button: Button = %DeckMenuButton
@onready var name_label: Label = %DeckNameLabel
@onready var count_label: Label = %DeckCountLabel
@onready var reorder_handle: Node = %ReorderHandle

var _deck_file := ""


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	reorder_handle.connect("drag_started", _on_reorder_started)
	reorder_handle.connect("drag_moved", _on_reorder_moved)
	reorder_handle.connect("drag_finished", _on_reorder_finished)


func setup(deck_file: String, display_name: String, card_count: int) -> void:
	_deck_file = deck_file
	name_label.text = display_name
	count_label.text = "%d장" % card_count if card_count > 0 else "카드 없음"


func deck_file() -> String:
	return _deck_file


func set_reordering(active: bool) -> void:
	z_index = 5 if active else 0
	self_modulate = Color(0.9, 0.9, 0.9, 1.0) if active else Color.WHITE


func _on_deck_pressed() -> void:
	selected.emit(_deck_file)


func _on_menu_pressed() -> void:
	menu_requested.emit(_deck_file, menu_button)


func _on_reorder_started() -> void:
	set_reordering(true)
	reorder_started.emit()


func _on_reorder_moved(viewport_position: Vector2) -> void:
	reorder_moved.emit(viewport_position)


func _on_reorder_finished() -> void:
	set_reordering(false)
	reorder_finished.emit()
