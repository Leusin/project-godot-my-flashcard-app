class_name DeckContextMenuView
extends "res://src/main/anchored_popup_menu.gd"

signal rename_requested(deck_file: String)
signal duplicate_requested(deck_file: String)
signal export_requested(deck_file: String)
signal delete_requested(deck_file: String)

@onready var rename_button: Button = %RenameDeckButton
@onready var duplicate_button: Button = %DuplicateDeckButton
@onready var export_button: Button = %ExportDeckButton
@onready var delete_button: Button = %DeleteDeckButton

var _deck_file := ""


func _ready() -> void:
	super()
	rename_button.pressed.connect(_on_rename_button_pressed)
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	export_button.pressed.connect(_on_export_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)


func open_for(deck_file: String, anchor: Control) -> void:
	_deck_file = deck_file
	open_at(anchor)


func dismiss() -> void:
	super()
	_deck_file = ""


func _on_rename_button_pressed() -> void:
	var deck_file := _deck_file
	dismiss()
	rename_requested.emit(deck_file)


func _on_duplicate_button_pressed() -> void:
	var deck_file := _deck_file
	dismiss()
	duplicate_requested.emit(deck_file)


func _on_export_button_pressed() -> void:
	var deck_file := _deck_file
	dismiss()
	export_requested.emit(deck_file)


func _on_delete_button_pressed() -> void:
	var deck_file := _deck_file
	dismiss()
	delete_requested.emit(deck_file)
