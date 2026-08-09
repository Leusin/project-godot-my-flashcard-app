class_name DeckTileView
extends Control

signal selected(deck_file: String)
signal menu_requested(deck_file: String, anchor: Control)

@onready var deck_button: Button = %DeckButton
@onready var menu_button: Button = %DeckMenuButton
@onready var name_label: Label = %DeckNameLabel
@onready var count_label: Label = %DeckCountLabel

var _deck_file := ""


func _ready() -> void:
	deck_button.pressed.connect(_on_deck_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func setup(deck_file: String, display_name: String, card_count: int) -> void:
	_deck_file = deck_file
	name_label.text = display_name
	count_label.text = "%d장" % card_count if card_count > 0 else "카드 없음"


func _on_deck_pressed() -> void:
	selected.emit(_deck_file)


func _on_menu_pressed() -> void:
	menu_requested.emit(_deck_file, menu_button)
